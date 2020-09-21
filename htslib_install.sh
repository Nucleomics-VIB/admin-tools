#!/bin/bash

# script: samtools_install.sh
# Aim: install samtools, bcftools and htslib version 1.X in one GO
#
# Stéphane Plaisance - VIB-Nucleomics Core - 2017-09-27 v1.2
# update to samtools 1.6 2017-10-26
# updated to any new build 2018-02-12
#
# visit our Git: https://github.com/Nucleomics-VIB

######################################
## get destination folder from user ##

echo -n "Enter the build number you wish to install (eg 1.10) and press [ENTER]: "
read mybuild

echo -n "Enter the full path ending with the samtools destination folder (eg /opt/biotools/samtools-1.X) and press [ENTER]: "
read myprefix

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
exec &> >(tee -i samtools_install_${mybuild}.log)

# process one to three packages (edit these urls for future versions)
cat <<EOL |
https://github.com/samtools/htslib/releases/download/${mybuild}/htslib-${mybuild}.tar.bz2
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
echo -e "# Full Samtools install finished, check for error messages in \"samtools_install.log\""
echo
echo -e "# add: \"export PATH=\$PATH:${myprefix}/bin\" to your /etc/profile"
echo -e "# add: \"export MANPATH=${myprefix}/share/man:\$MANPATH\" to your /etc/profile"
echo
echo -e "# you may also delete the folder \"${myprefix}/src\""
