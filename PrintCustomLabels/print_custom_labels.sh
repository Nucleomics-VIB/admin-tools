#! /bin/bash

# script: print_custom_labels.sh
# print label(s) on the zebra printer
# run this code on the printer host:gbw-s-nuc01
#
# Stephane Plaisance (VIB-NC) 2019/11/06; v1.0
# visit our Git: https://github.com/Nucleomics-VIB

# version="1.0.2, 2020_01_28"
# added ^MD30 to print darker
# version="1.0.3, 2020_11_20"
# added darkness
# version="1.0.4, 2020_11_23"
# added prefix
# version="1.0.5, 2021_05_28"
# added default outfile
version="1.0.6, 2021_08_09"

usage='## Usage: print_custom_labels.sh <options> -t <some text> ...
# default is to print 1 to 5 rows of free text
# but larger font or barcodes are also possible for 1 text row
# <required either of :>
# -F <text file with 6 tab separated columns>
# -t <text to print as a row (can be repeated 1 to 5 times, max ~27char)>
# <optional>
# -M <text from -t (1 of max 23char) is printed in medium font>
# -B <text from -t (1 of max 13char) is printed in big font>
# <barcodes>
# -b <text from -t (1 of max 22 digits) encodes a numeric barcode>
# -x <text from -t (1 of max 11 char) encodes a ASCCI ([0-9][A-Z]-.$/+% ) barcode>
# <multiple copies>
# -c <# copies to print (default=1)>
# -d <darkness [-15,15] (default 0)>
#
# <examples>
# printlbl.sh -F label_file.txt
# printlbl.sh -t "first row" -t "second row" -t "third row"
# printlbl.sh -M -t "gbw-s-nuc01@luna"
# printlbl.sh -B -t "gbw-s-nuc01"
# printlbl.sh -b -t "1234567890123456789012"
# printlbl.sh -x -t "ABCDE-12345"
# printlbl.sh -t "first row" -t "second row" -t "third row"
# printlbl.sh -t "VIB - Nucleomics Core" -t "Herestraat 49, O&N4, Post Box 816" -t "Room nr. 404-24 / 08.428" -t "B-3000 Leuven - Belgium"
# printlbl.sh -t "VIB - Nucleomics Core" -t "Herestraat 49, O&N4, Post Box 816" -t "Room nr. 404-24 / 08.428" -t "B-3000 Leuven" -t "Belgium"
# add "-c 3" to print 3 identical copies
#
# SP@NC, script version '${version}

# default
type="text"

outfile="/mnt/nuc-data/AppData/BarcodeFiles/newlabel.run"

# parse optional parameters
while getopts "t:MBbxF:c:d:h" opt; do
    case $opt in
        t) optrows+=("$OPTARG") ;;
        M) type="medfnt" ;;
        B) type="bigfnt" ;;
        F) optfile=$OPTARG; type="fromfile" ;;
        b) type="numbc" ;;
        x) type="txtbc" ;;
        c) optcop=$OPTARG ;;
        d) optdrk=$OPTARG ;;
        h) echo "${usage}" >&2; exit 0 ;;
        \?) echo "Invalid option: -${OPTARG}" >&2; exit 1 ;;
        *) echo "this command requires arguments, try -h" >&2; exit 1 ;;
    esac
done

# mandatory
if [ -z "${optrows+x}" ] && [ -z "${optfile}" ]; then
    echo "# no label text (or file) was provided!"
    echo "${usage}"
    exit 1
fi

# test length of the input in 1:5
if [ "${type}" == "text" ]; then
len=${#optrows[@]}
if (( "${len}" < 1 || "${len}" > 5)); then
    echo "# 1 to 5 rows"
    exit 0
fi
fi

# default to 1 label
copies=${optcop:-1}

# default to 0 darkness
darkness=${optdrk:-15}
if (("${darkness}" < -15 || "${darkness}" > 15)); then
    echo "# darkness should be between -15 and +15"
    echo "${usage}"
    exit 1
fi

# prefix commands to setup the printer
# taken from Rudy's R code@
# ^XA     # start command block
# ^CI0    # character set 0 = Single Byte Encoding - U.S.A. 1 Character Set
# ^JMA    # 24 dots/mm
# ~JSO    # backfeed sequence. OFF
# ^JUS    # save current settings
# ^LH0,0  # set label home position
# ^LL0189 # label length in pixels
# ^LRN    # reverse label prin,ting set to NO
# ^LT12   # position of the finished label
# ^MD15   # media darkness
# ^MMT    # tear OFF label after printing
# ^MNW    # non-continuous media web sensing
# ^MTT    # thermal transfer medium
# ^PMN    # Printing Mirror Image of Labe
# ^PON    # normal orientation
# ^PR2,2  # print speed, sleep speed, backfeed speed (default A=2=50.8 mm/sec. (2 inches/sec.) 
# ^PW474  # set the print width more is cut out
# ~TA0    # after label is printed
# ^XZ     # end command block

prefix='^XA
~TA0
~JSO
^LT12
^MMT
^MNW
^MTT
^PON
^PMN
^LH0,0
^JMA
^PR2,2
^MD'${darkness}'
^LRN
^CI0
^LL189
^PW474
^JUS
^XZ'

# debug code
#echo "# printing ${type} labels"
#echo "# printing ${copies} copies"
#echo "# first value of the array optrows is ${optrows[0]}"
#echo "# list of values has length ${len}"
#echo "# whole list of values is ${optrows[@]}"

declare -a FUNCTION
FUNCTION[1]="FUNC.ONE"
FUNCTION[2]="FUNC.TWO"
FUNCTION[3]="FUNC.THREE"
FUNCTION[4]="FUNC.FOUR"
FUNCTION[5]="FUNC.FIVE"

# 5 lines from text file (6 columns)
function FUNC.FILE() {
if [ -f "${optfile}" ]; then
while IFS=$'\t\r' read -r -a col; do
if (( ${#col[@]} )); then
echo ${prefix}'^XA
^FO15,10^A0N,32,24^FD'${col[0]}'_'${col[1]}' (VIB-NC)^FS
^FO15,45^A0N,32,24^FD'${col[2]}'^FS
^FO15,80^A0N,32,24^FD'${col[3]}'^FS
^FO15,115^A0N,32,24^FD'${col[4]}'^FS
^FO15,150^A0N,32,24^FD'${col[5]}'^FS
^XZ' |lpr -# ${copies} -P zebra
fi
done < ${optfile}
fi
}

# 5 lines
function FUNC.FIVE() {
echo -n ${prefix}'^XA
^FO15,10^A0N,32,24^FD'${1}'^FS
^FO15,45^A0N,32,24^FD'${2}'^FS
^FO15,80^A0N,32,24^FD'${3}'^FS
^FO15,115^A0N,32,24^FD'${4}'^FS
^FO15,150^A0N,32,24^FD'${5}'^FS
^XZ'
}

# 4 lines
function FUNC.FOUR() {
echo -n ${prefix}'^XA
^FO15,20^A0N,36,28^FD'${1}'^FS
^FO15,60^A0N,36,28^FD'${2}'^FS
^FO15,100^A0N,36,28^FD'${3}'^FS
^FO15,140^A0N,36,28^FD'${4}'^FS
^XZ'
}

# 3 lines
function FUNC.THREE() {
echo -n ${prefix}'^XA
^FO15,20^A0N,48,30^FD'${1}'^FS
^FO15,75^A0N,48,30^FD'${2}'^FS
^FO15,130^A0N,48,30^FD'${3}'^FS
^XZ'
}

# 2 lines
function FUNC.TWO() {
echo -n ${prefix}'^XA
^FO15,50^A0N,48,30^FD'${1}'^FS
^FO15,100^A0N,48,30^FD'${2}'^FS
^XZ'
}

# 1 line
function FUNC.ONE() {
echo -n ${prefix}'^XA
^FO15,75^A0N,48,30^FD'${1}'^FS
^XZ'
}

# 1 line med font
function FUNC.TXTMF() {
echo -n ${prefix}'^XA
^FO15,80^CFT^FD'${1}'^FS
^XZ'
}

# 1 line big font
function FUNC.TXTBF() {
echo -n ${prefix}'^XA
^FO15,60^CFV^FD'${1}'^FS
^XZ'
}

# 1 num barcode
function FUNC.NUMBC() {
echo -n ${prefix}'^XA
^FO5,25^BY2
^A0N,32,20
^BCN,100,Y,N,N,N
^FD>;>8'${1}'^FS
^XZ'
}

# 1 txt barcode
function FUNC.TXTBC() {
echo -n ${prefix}'^XA
^FO5,25^BY2
^B3N,N,100,Y,N
^FD'${1}'^FS
^XZ'
}

# label type
# remove previous tr -d '[:space:]'
# replace space(s) by a single &nbsp; => sed -r 's/[[:blank:]]+/\xC2\xA0/g'
case "${type}" in
    ("fromfile") FUNC.FILE ${optfile} ;;
    ("medfnt") FUNC.TXTMF ${optrows[0]:0:23} | \
      sed -r 's/[[:blank:]]+/\xC2\xA0/g' > ${outfile};;
    ("bigfnt") FUNC.TXTBF ${optrows[0]:0:13} | \
      sed -r 's/[[:blank:]]+/\xC2\xA0/g' > ${outfile};;
    ("numbc") FUNC.NUMBC ${optrows[0]:0:22} | \
      sed -r 's/[[:blank:]]+/\xC2\xA0/g' > ${outfile};;
    ("txtbc") FUNC.TXTBC ${optrows[0]:0:11} | \
      sed -r 's/[[:blank:]]+/\xC2\xA0/g' > ${outfile};;
    (*) ${FUNCTION[${len}]} "${optrows[@]}" | \
      sed -r 's/[[:blank:]]+/\xC2\xA0/g' > ${outfile};;
esac

# send print job
lpr -# ${copies} -P zebra ${outfile}

echo "Label(s) sent to the printer"