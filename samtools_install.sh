# script: samtools_install.sh
# Aim: install samtools, bcftools and htslib version 1.X in one GO
#
# Stéphane Plaisance - VIB-Nucleomics Core - 2017-09-27 v1.2
# update to samtools 1.6 2017-10-26
# updated to any new build 2018-02-12
# allow different build version for each of the three 2019-12-30 v1.3
# now finds the latest releases automatically 2020-05-04 v1.4 
#
# visit our Git: https://github.com/Nucleomics-VIB

function latest_git_release() {
# argument is a quoted string like  "broadinstitute/picard"
ID=${GITHUB_ID}
TOKEN=${GITHUB_TOKEN}
curl --silent -u ${GITHUB_ID}:${GITHUB_TOKEN} "https://api.github.com/repos/$1/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
}

############################################################
## get build automatically & destination folder from user ##

mybuild_st=$(latest_git_release "samtools/samtools")
echo "# Installing the current Samtools release : "${mybuild_st}

mybuild_bc=$(latest_git_release "samtools/bcftools")
echo "# Installing the current bcftools release : "${mybuild_bc}

mybuild_ht=$(latest_git_release "samtools/htslib")
echo "# Installing the current htslib release : "${mybuild_ht}

echo -n "# Provide a path OR type [ENTER] for '/opt/biotools/samtools-${mybuild_st}': "
read mypath 
myprefix=${mypath:-"/opt/biotools/samtools-${mybuild_st}"}

# test if exists and abort
if [ -d "${myprefix}" ]; then
        echo "# This folder already exists, change its name or move it then restart this script."
        exit 0
fi

# create destination folder
mkdir -p "${myprefix}/src"

# test for success
if [ $? -ne 0 ] ; then
        echo "# You were not allowed to create this path"
fi

######################################

# move to the place where to download and build
# work in a folder => easy to clean afterwards
cd "${myprefix}/src"

# capture all to log from here
exec &> >(tee -i samtools_install_${mybuild_st}.log)

# process three packages (edit these urls for future versions)
cat <<EOL |
https://github.com/samtools/samtools/releases/download/${mybuild_st}/samtools-${mybuild_st}.tar.bz2
https://github.com/samtools/bcftools/releases/download/${mybuild_bc}/bcftools-${mybuild_bc}.tar.bz2
https://github.com/samtools/htslib/releases/download/${mybuild_ht}/htslib-${mybuild_ht}.tar.bz2
EOL

# loop through the list
while read myurl; do

# get source
wget "${myurl}"
package=${myurl##*/}
tar -xjvf ${package}

# build and install
cd ${package%.tar.bz2}
./configure CPPFLAGS='-I /opt/local/include' --prefix="${myprefix}"
make && make install && cd -

# end loop
done

# post install steps
echo
echo
echo -e "# Full Samtools install finished, check for error messages in \"samtools_install_${mybuild_st}.log\""
echo
echo -e "# samtools version is: $(${myprefix}/bin/samtools --version)"
echo
echo -e "# bcftools version is: $(${myprefix}/bin/bcftools --version)"
echo
echo -e "# htsfile version is: $(${myprefix}/bin/htsfile --version)"
echo
echo
echo -e "# add: \"export PATH=\$PATH:${myprefix}/bin\" to your /etc/profile"
echo -e "# add: \"export MANPATH=${myprefix}/share/man:\$MANPATH\" to your /etc/profile"
echo
echo -e "# you may also delete the folder \"${myprefix}/src\""
echo -e "# with: rm -rf ${myprefix}/src"
