[(Nucleomics-VIB)](https://github.com/Nucleomics-VIB)
## admin-tools 

### Content
**[pmid2bibtex.R](#pmid2bibtexr)** - **[samtools_install.sh](#samtools_installsh)** - **[gatk_install.sh](#gatk_installsh)** - **[picard_install.sh](#picard_installsh)** - **[genepattern_backup.sh](#genepattern_backupsh)** - **[filesender-cmd.sh](#filesender-cmdsh)** - **[runandlog.sh](#runandlogsh)** 

<hl>

## **Install apps from a github repository**
	
A **Github ID** and **token** are required to avoid getting a max acces limit reached error during execution of the scripts. The two strings are stored on the server (in your .bashrc for instance) as two dedicated variables that the script will use. *This is not the safest way to handle a 'secret' Token but I did not find a better way yet (suggestions are welcome)*.

```
export GITHUB_ID="your_ID"
export GITHUB_TOKEN="your_secret token"
```

These strings are used in the query function which gets the latest release version out of the github repo in order to download it

```
function latest_git_release() {
# argument is a quoted string like  "broadinstitute/picard"
ID=${GITHUB_ID}
TOKEN=${GITHUB_TOKEN}
curl --silent -u ${GITHUB_ID}:${GITHUB_TOKEN} "https://api.github.com/repos/$1/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
}
	
# the function is called with the github path (here samtools as example)
mybuild_st=$(latest_git_release "samtools/samtools")
```

* Note: in order to avoid the token exposure, you can replace the function above by:
	
```
function latest_git_release() {
# argument is a quoted string like  "broadinstitute/picard"
curl --silent "https://api.github.com/repos/$1/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
}
```

### **samtools_install.sh**

The bash script **[samtools_install.sh](samtools_install.sh)** eases the install of samtools and companion packages. Nothing very complex there but a single command for it all.

### **gatk_install.sh**

The bash script **[gatk_install.sh](gatk_install.sh)** eases the install of GATK version 4. Nothing very complex there but a single command for it all.

### **picard_install.sh**

The bash script **[picard_install.sh](picard_install.sh)** eases the install of PICARD tools version 2. Nothing very complex there but a single command for it all.

## **pmid2bibtex.R**

The standalone R script **[pmid2bibtex.R](pmid2bibtex.R)** uses the R package 'RefManageR' to converts a list of pubmed IDs to bibtex format for integration with Rmarkdown code or LaTeX.

```bash
Usage: pmid2bibtex.R [options]

Options:
	-l LIST, --list=LIST
		a comma-separated list of pmid's

	-f FILE, --file=FILE
		a text file with one pmid per line

	-o OUTFILE, --outfile=OUTFILE
		base name for the output bib file (default to stdout)

	-a, --append
		append content to existing bib file (default overwrite)

	-x OUTFORMAT, --outformat=OUTFORMAT
		outout format (bibtex, biblatex) (default bibtex)

	-h, --help
```

## **genepattern_backup.sh**

This more elaborated tar wrapper make a backup of the **GenePatternServer** and/or **GenePatternUploads** folders on your server. Please edit the variables on the top of the script before running it.

```bash
## Usage: genepattern_backup.sh
# -s <backup GenePatternServer folder (default off)>
# -u <backup GenePatternUploads folder (default off)>
# -h <show this help>
```

## **filesender-cmd.sh**

Share big data with colleagues or collaborators using the [BELNET Filesender](https://www.belnet.be/en/services/identity-mobility-federation/filesender) system from command line

<img src="https://federation.belnet.be/images/belnetlogo.png" alt="BELNET LOGO" style="width: 100px;"/>

**[filesender-cmd.sh](filesender-cmd.sh)** uses an existing access to **Filesender** (user account, login, password) to establish secure connection witht the **Filesender** server, it then uploads your file (single file or ZIP of files-and-folders), finally it sends an email to your chosen recipient with a title and a text as well as a link to the uploaded file.
```bash
# Usage: filesender-cmd.sh 
# script version 1.1.1, 2016_08_18
# -i <file-to-send (folders will be zipped first)> 
# -r <recipient-email>
# -s <message-subject>
# -m <message-Text [alt: -m "$(< somefile.txt)"]>
# -z (no-arg, create a zip archive 1st)
#
# the following parameters can be set as default in the code
# [optional]: -f <sender-email>
# [optional]: -l <sender-login>
# [optional]: -p <sender-password|(not safe to set this in the code!)>
# [optional]: -g <sender-IDP>
# [optional]: -v <verbose output (default to silent)>
```

The files remain up to 7 days on the BELNET server then are removed. The size limit is set to 100GB, alllowing sharing large projects at very high speed.

## **runandlog.sh**

Monitor somme script over time with **[runandlog.sh](runandlog.sh)**.

```bash
# usage: runandlog <command> <parameters>
```

*[[back-to-top](#top)]*  

<hr>

<h4>Please send comments and feedback to <a href="mailto:nucleomics.bioinformatics@vib.be">nucleomics.bioinformatics@vib.be</a></h4>

<hr>

![Creative Commons License](http://i.creativecommons.org/l/by-sa/3.0/88x31.png?raw=true)

This work is licensed under a [Creative Commons Attribution-ShareAlike 3.0 Unported License](http://creativecommons.org/licenses/by-sa/3.0/).
