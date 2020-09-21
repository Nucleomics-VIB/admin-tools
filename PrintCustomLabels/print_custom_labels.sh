#! /bin/bash

# script: print_custom_labels.sh
# print label(s) on the zebra printer
# run this code on the printer host:gbw-s-nuc01
#
# Stephane Plaisance (VIB-NC) 2019/11/06; v1.0
# visit our Git: https://github.com/Nucleomics-VIB

version="1.0.2, 2020_01_28"

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

# parse optional parameters
while getopts "t:MBbxF:c:h" opt; do
    case $opt in
        t) optrows+=("$OPTARG") ;;
        M) type="medfnt" ;;
        B) type="bigfnt" ;;
        F) optfile=$OPTARG; type="fromfile" ;;
        b) type="numbc" ;;
        x) type="txtbc" ;;
        c) optcop=$OPTARG ;;
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
echo '^XA
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
echo '^XA
^FO15,10^A0N,32,24^FD'${1}'^FS
^FO15,45^A0N,32,24^FD'${2}'^FS
^FO15,80^A0N,32,24^FD'${3}'^FS
^FO15,115^A0N,32,24^FD'${4}'^FS
^FO15,150^A0N,32,24^FD'${5}'^FS
^XZ'
}

# 4 lines
function FUNC.FOUR() {
echo '^XA
^FO15,20^A0N,36,28^FD'${1}'^FS
^FO15,60^A0N,36,28^FD'${2}'^FS
^FO15,100^A0N,36,28^FD'${3}'^FS
^FO15,140^A0N,36,28^FD'${4}'^FS
^XZ'
}

# 3 lines
function FUNC.THREE() {
echo '^XA
^FO15,20^A0N,48,30^FD'${1}'^FS
^FO15,75^A0N,48,30^FD'${2}'^FS
^FO15,130^A0N,48,30^FD'${3}'^FS
^XZ'
}

# 2 lines
function FUNC.TWO() {
echo '^XA
^FO15,50^A0N,48,30^FD'${1}'^FS
^FO15,100^A0N,48,30^FD'${2}'^FS
^XZ'
}

# 1 line
function FUNC.ONE() {
echo '^XA
^FO15,75^A0N,48,30^FD'${1}'^FS
^XZ'
}

# 1 line med font
function FUNC.TXTMF() {
echo '^XA
^FO15,80^CFT^FD'${1}'^FS
^XZ'
}

# 1 line big font
function FUNC.TXTBF() {
echo '^XA
^FO15,60^CFV^FD'${1}'^FS
^XZ'
}

# 1 num barcode
function FUNC.NUMBC() {
echo '^XA
^FO5,25^BY2
^A0N,32,20
^BCN,100,Y,N,N,N
^FD>;>8'${1}'^FS
^XZ'
}

# 1 txt barcode
function FUNC.TXTBC() {
echo '^XA
^FO5,25^BY2
^B3N,N,100,Y,N
^FD'${1}'^FS
^XZ'
}

# label type
case "${type}" in
    ("fromfile") FUNC.FILE ${optfile} ;;
    ("medfnt") FUNC.TXTMF ${optrows[0]:0:23} | lpr -# ${copies} -P zebra ;;
    ("bigfnt") FUNC.TXTBF ${optrows[0]:0:13} | lpr -# ${copies} -P zebra ;;
    ("numbc") FUNC.NUMBC ${optrows[0]:0:22} | lpr -# ${copies} -P zebra ;;
    ("txtbc") FUNC.TXTBC ${optrows[0]:0:11} | lpr -# ${copies} -P zebra ;;
    (*) ${FUNCTION[${len}]} "${optrows[@]}" | lpr -# ${copies} -P zebra ;;
esac

echo "Label(s) sent to the printer"
