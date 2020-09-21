#!/bin/bash

# adapted from https://www.networkworld.com/article/2704414/
#   operating-systems/unix---tracking-disk-space-usage.html
# SP VIB - Nucleomics Core - 2018-03-21, v1.0.1
# cosmetic 2018-11-21

dts=$(date +%s)
dt=$(date +%D)
dulog="/var/tmp/du.log"
dflog="/var/tmp/df.log"

# SP added path as arg
rootpath=${1:-"/mnt/freenas/shared"}
depth=${2:-4}

# SP changed to du and added case 2 below
# start with du
du -xP --max-depth ${depth} ${rootpath} | tr "\t" "," > /tmp/du$$

# then do df (second line only)
#freenas:/mnt/bulk   15T 1002G   14T   7% /mnt/freenas
df -h ${rootpath} | sed -e '1d' > /tmp/df$$

# process du results and add to log
while read duline
do
    fields=$(echo ${duline} | awk 'BEGIN{FS=","}{print NF}')
    echo -n "$dts," >> ${dulog}
    echo -n "$dt," >> ${dulog}
    case ${fields} in
    2) echo ${duline} | awk 'BEGIN{FS=",";OFS=","}{print $2,$1}' >> ${dulog};;
    *) awk 'BEGIN{OFS=","}{print "na","na"}' >> ${dulog};;
    esac
done < /tmp/du$$ \
&& rm /tmp/du$$

# process df results and add to log
while read dfline
do
    fields=$(echo ${dfline} | awk '{print NF}')
    echo ${dfline}
    echo -n "$dts," >> ${dflog}
    echo -n "$dt," >> ${dflog}
    case ${fields} in
    6) echo ${dfline} | awk 'BEGIN{OFS=","}{print $3,$4,$5}' >> ${dflog};;
    *) awk 'BEGIN{OFS=","}{print "na","na","na"}' >> ${dflog};;
    esac
done < /tmp/df$$ \
&& rm /tmp/df$$

echo "# tail ${dulog}"
tail ${dulog}
echo
echo "# tail ${dflog}"
tail ${dflog}
