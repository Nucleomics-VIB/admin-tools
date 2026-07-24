#!/usr/bin/env bash
#
# tag-repos.sh — auto-detect tech in your GitHub repos and apply topics (tags).
#
# Created by Stephane Plaisance — VIB Nucleomics Core
# Date:    2026-07-24
# Version: 1.0.0
#
# Requires: gh CLI (https://cli.github.com), authenticated:  gh auth login
#           jq (https://jqlang.github.io/jq/)
#
# What it does:
#   For every repo it can see (public + private), it reads the file list and
#   language stats via the GitHub API, matches them against the RULES below,
#   and either prints (dry-run) or applies the matching topics.
#
# It only ADDS topics — it never removes topics you already set.
#
# ---------------------------------------------------------------------------
# USAGE
#   ./tag-repos.sh                 # dry-run over YOUR account (prints proposed tags)
#   ./tag-repos.sh --apply         # actually apply the topics
#   ./tag-repos.sh --org vib-cbd   # target an org instead of your user account
#   ./tag-repos.sh --org vib-cbd --apply
#   ./tag-repos.sh --include-archived   # also tag archived repos (skipped by default)
# ---------------------------------------------------------------------------

set -euo pipefail

# -------------------- settings --------------------
ORG=""                 # empty = your own account (owner + collaborator repos)
APPLY=false            # false = dry-run; --apply flips this
INCLUDE_ARCHIVED=false
LIMIT=1000             # max repos to scan

# Manual override: repos (SHORT name, no owner) that are bash pipelines chaining
# multiple tools into one workflow. Auto-detection can't tell these apart from
# utility/tool collections, so list them here to force the 'pipeline' tag.
# (nextflow / snakemake repos already get 'pipeline' automatically.)
PIPELINE_REPOS=(
  # NC_Shotgun_pipeline / 16S_analysis_pipeline are already caught by the name heuristic.
  # demux / decat workflows
  Kinnex_16S_decat_demux_bash
  Kinnex_16S_decat_demux_docker
  Kinnex_MASseq_decat_demux_docker
  # analysis workflows
  variant_analysis
  NC_UMI-Seq
  NC_Barcode_QC_gDNA_docker
  NC_Kinnex16S_AppNote
  # assembly / reference-building workflows
  Staphylococcus_aureus_HiFi_asm
  Create_Fungi_rDNA_database
  InSilico_PCR
)

# -------------------- RULES --------------------
# Edit this list to control your tags.
# Format:  "topic|type|pattern"
#   type = file    -> pattern is a case-insensitive regex matched against every file path in the repo
#   type = lang    -> pattern is a language name (case-insensitive) from GitHub's language stats
#   type = name    -> pattern is a case-insensitive regex matched against the repo's short name (no owner)
#   type = derived -> pattern is a '|'-separated list of OTHER topics; the topic is added when the
#                     repo already carries ANY of them. Derived rules run AFTER all direct rules, so
#                     they can build umbrella tags on top of the base tags below.
# A repo can match many rules and get many topics (e.g. nextflow AND docker).
RULES=(
  # --- base / direct rules ---
  "nextflow|file|(^|/)nextflow\.config$|(^|/)main\.nf$|\.nf$"
  "docker|file|(^|/)dockerfile$|(^|/)docker-compose\.ya?ml$|\.dockerfile$"
  "snakemake|file|(^|/)snakefile$|\.smk$"
  "singularity|file|(^|/)singularity(\..*)?$|\.def$|\.sif$"
  "conda|file|(^|/)environment\.ya?ml$|(^|/)meta\.yaml$"
  "shiny-app|file|(^|/)(app|server|ui)\.R$"
  "webtool|name|^dev_wt_"
  "webtool|file|(^|/)app\.py$|\.php$"
  "pipeline|name|[Pp]ipeline|[Ww]orkflow"
  "python|lang|python"
  "r|lang|r"
  "bash|lang|shell"
  # --- derived / umbrella rules (evaluated after the direct rules above) ---
  "pipeline|derived|nextflow|snakemake"
  "container|derived|docker|singularity"
  "webtool|derived|shiny-app"
)
# ------------------------------------------------

# parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) APPLY=true; shift ;;
    --org) ORG="$2"; shift 2 ;;
    --include-archived) INCLUDE_ARCHIVED=true; shift ;;
    -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

command -v gh >/dev/null || { echo "ERROR: gh CLI not found. Install: https://cli.github.com" >&2; exit 1; }
command -v jq >/dev/null || { echo "ERROR: jq not found. Install: https://jqlang.github.io/jq/" >&2; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "ERROR: not authenticated. Run: gh auth login" >&2; exit 1; }

echo "Mode:            $([ "$APPLY" = true ] && echo 'APPLY (writing topics)' || echo 'DRY-RUN (no changes)')"
echo "Target:          $([ -n "$ORG" ] && echo "org $ORG" || echo 'your account')"
echo "Include archived: $INCLUDE_ARCHIVED"
echo "-----------------------------------------------------------"

# build repo list as OWNER/NAME, one per line
if [[ -n "$ORG" ]]; then
  LIST_CMD=(gh repo list "$ORG" --limit "$LIMIT" --json nameWithOwner,isArchived)
else
  LIST_CMD=(gh repo list --limit "$LIMIT" --json nameWithOwner,isArchived)
fi

repos=$("${LIST_CMD[@]}" | jq -r \
  --argjson inc "$([ "$INCLUDE_ARCHIVED" = true ] && echo true || echo false)" \
  '.[] | select($inc or (.isArchived|not)) | .nameWithOwner')

total=0; changed=0

while IFS= read -r repo; do
  [[ -z "$repo" ]] && continue
  total=$((total+1))

  # default branch
  branch=$(gh api "repos/$repo" --jq '.default_branch' 2>/dev/null || echo "")
  [[ -z "$branch" ]] && { echo "SKIP  $repo (no default branch / empty repo)"; continue; }

  # full recursive file list (one API call)
  files=$(gh api "repos/$repo/git/trees/$branch?recursive=1" --jq '.tree[].path' 2>/dev/null || echo "")
  # language stats
  langs=$(gh api "repos/$repo/languages" --jq 'keys[]' 2>/dev/null || echo "")

  short="${repo#*/}"
  topics=()

  # pass 1: direct rules (file / lang / name)
  for rule in "${RULES[@]}"; do
    topic="${rule%%|*}"; rest="${rule#*|}"; rtype="${rest%%|*}"; pattern="${rest#*|}"
    case "$rtype" in
      file) if echo "$files" | grep -Eiq "$pattern"; then topics+=("$topic"); fi ;;
      lang) if echo "$langs" | grep -Eiq "^${pattern}$"; then topics+=("$topic"); fi ;;
      name) if [[ "$short" =~ $pattern ]]; then topics+=("$topic"); fi ;;
    esac
  done

  # manual override: force-listed repos into the 'pipeline' group
  for pr in "${PIPELINE_REPOS[@]:-}"; do
    if [[ -n "$pr" && "$pr" == "$short" ]]; then topics+=("pipeline"); fi
  done

  # pass 2: derived / umbrella rules (topic-of-topics) — run after all direct rules
  for rule in "${RULES[@]}"; do
    topic="${rule%%|*}"; rest="${rule#*|}"; rtype="${rest%%|*}"; pattern="${rest#*|}"
    [[ "$rtype" == "derived" ]] || continue
    ((${#topics[@]})) || continue
    IFS='|' read -ra prereqs <<< "$pattern"
    for pre in "${prereqs[@]}"; do
      if printf '%s\n' "${topics[@]}" | grep -qx -- "$pre"; then topics+=("$topic"); break; fi
    done
  done

  if [[ ${#topics[@]} -eq 0 ]]; then
    echo "----  $repo  (no matches)"
    continue
  fi

  uniq_topics=$(printf '%s\n' "${topics[@]}" | sort -u | tr '\n' ' ')
  echo "TAG   $repo  ->  $uniq_topics"
  changed=$((changed+1))

  if [[ "$APPLY" == true ]]; then
    add_args=()
    for t in $uniq_topics; do add_args+=(--add-topic "$t"); done
    gh repo edit "$repo" "${add_args[@]}" >/dev/null && echo "      applied." || echo "      FAILED to apply." >&2
  fi
done <<< "$repos"

echo "-----------------------------------------------------------"
echo "Scanned $total repos; $changed matched at least one rule."
if [[ "$APPLY" == false ]]; then
  echo "This was a DRY-RUN. Re-run with --apply to write the topics."
fi
