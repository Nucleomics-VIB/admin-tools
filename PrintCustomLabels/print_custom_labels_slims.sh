#! /bin/bash

# script: print_custom_labels_slims.sh
# print label(s) on the "Slims" printer
# run this code on the printer host:gbw-s-nuc01
#
# Stephane Plaisance (VIB-NC) 2019/11/06; v1.0
# Thomas Standaert (VIB-NC) 2020/06/14; v2.0
# visit our Git: https://github.com/Nucleomics-VIB

# version="1.0.2, 2020_01_28"
# added ^MD30 to print darker
# version="1.0.3, 2020_11_20"
# added darkness
# version="1.0.4, 2020_11_23"
# added prefix
# version="1.0.5, 2021_05_28"
version="2.1.0, 2021_07_19"
# Changed the script to fit the "Slims" printer, with TSPL

usage=$(cat <<-END
## Usage: print_custom_labels.sh <options> -t <some text> ...
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
# -d <darkness [0,15] (default=8)>
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
# SP@NC, script version
END
)${version}

# default
type="text"

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

# default to darkness 8
darkness=${optdrk:-8}
if (("${darkness}" < 0 || "${darkness}" > 15)); then
    echo "# darkness should be between 0 and +15 (default to 8)"
    echo "${usage}"
    exit 1
fi

# Zebra label printer prefix commands to setup the printer
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

# Altec label printer prefix commands to setup the printer
prefix="SIZE 40 mm, 19 mm\n\
BLINE 3 mm, 0 mm\n\
REFERENCE 0,0\n\
SPEED 2\n\
DENSITY ${darkness}\n\
SET RIBBON ON\n\
SET PEEL OFF\n\
SET CUTTER OFF\n\
SET PARTIAL_CUTTER OFF\n\
SET TEAR ON\n\
SET REWIND OFF\n\
DIRECTION 0\n\
SHIFT 0,0\n\
OFFSET 0 mm\n\n\
CLS"

# debug code
#echo "# printing ${type} labels"
#echo "# printing ${copies} copies"
#echo "# first value of the array optrows is ${optrows[0]}"
#echo "# list of values has length ${len}"
#echo "# whole list of values is ${optrows[@]}"

# 5 lines from text file (6 columns)
function FUNC.FILE() {
file_loc='uploads/tmpprintfile'
printer='TTP345-Raw'
if [ -f "${optfile}" ]; then
  filename=$(basename ${optfile})
  fileext=${filename##*.}
  # Sanitize input file
  dos2unix ${optfile}
  sed -i '/^$/d' ${optfile}
  sed -i '/^[[:space:]]*$/d' ${optfile}
  sed -i '$a\' ${optfile}
  # Read file
  if [[ $fileext == "csv"  ]]
  then
    IFSseps=$',;'
  elif [[ $fileext == "txt"  ]]
  then
    IFSseps=$'\034'
    sed -i $'s/\t/\034/g' ${optfile}
  else
    echo "Not supported file, exiting!"
    exit 1
  fi
  while read line; do
    IFS=$IFSseps read -ra col <<< "$line"
    if (( ${#col[@]} )); then
      echo -e ${prefix} > $file_loc
      if [ -z "${col[1]}" ]; then
        echo -e '
CODEPAGE 1252
TEXT 465,191,"ROMAN.TTF",180,7,7,"'${col[0]}'"' >> $file_loc
      else
        echo -e '
CODEPAGE 1252
TEXT 465,191,"ROMAN.TTF",180,7,7,"'${col[0]}'_'${col[1]}'"' >> $file_loc
      fi
      for ((i = 2; i < ${#col[@]}; ++i)); do
      x=$((191-($i-1)*33))
      echo -e 'CODEPAGE 1252
TEXT 466,'$x',"ROMAN.TTF",180,7,7,"'${col[$i]}'"' >> $file_loc
      done
    echo -e 'PRINT '${copies}',1
    ' >> $file_loc
    lp -d $printer $file_loc
  fi
  done < ${optfile}
fi
}

# Print 1-5 lines
function FUNC.PRINTLINES() {
output_string=${prefix}
for (( i = 1; i <= $len; i++ ))
do
  y=$(( 224 - 33 * $i))
  output_string=$(echo $output_string'\nCODEPAGE 1252\nTEXT 465,'${y}',"ROMAN.TTF",180,7,7,"'"${!i}"'"')
done
echo -ne $output_string
}

# 1 line med font
function FUNC.TXTMF() {
echo -ne ${prefix}'\nCODEPAGE 1252\nTEXT 468,131,"ROMAN.TTF",180,10,10,"'${1}'"'
}

# 1 line big font
function FUNC.TXTBF() {
echo -ne ${prefix}'\nCODEPAGE 1252\nTEXT 471,136,"ROMAN.TTF",180,14,14,"'${1}'"'
}

# 1 num barcode
function FUNC.NUMBC() {
echo -ne ${prefix}'\nBARCODE 461,177,"128M",120,2,180,1,2,"!104'${1}'"'
}

# 1 txt barcode
function FUNC.TXTBC() {
echo -ne ${prefix}'\nBARCODE 463,176,"39",120,2,180,1,3,"'${1}'"'
}

# Printer vars
print_newlabel='/var/www/cgi-bin/uploads/newlabel.run'
print_name='TTP345-Raw'

# label type
case "${type}" in
    ("fromfile") FUNC.FILE ${optfile} && exit 0;;
    ("medfnt") FUNC.TXTMF ${optrows[0]:0:23} > $print_newlabel;;
    ("bigfnt") FUNC.TXTBF ${optrows[0]:0:16} > $print_newlabel;;
    ("numbc") FUNC.NUMBC ${optrows[0]:0:30} > $print_newlabel;;
    ("txtbc") FUNC.TXTBC ${optrows[0]:0:25} > $print_newlabel;;
    (*) FUNC.PRINTLINES "${optrows[@]}" > $print_newlabel;;
esac

# Adding print command
echo -ne "\nPRINT ${copies},1\n" >> $print_newlabel

# send print job
lp -d $print_name $print_newlabel

echo "Label(s) sent to the printer"

#Clean up
#rm uploads/*