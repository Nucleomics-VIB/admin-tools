#! /bin/bash

# script: filesender-cmd.sh (customised for use at VIB)
# transfer a file (or archive) to a collaborator using BelNet FileSender
# You will need to have access to FileSender (obviously)
# more info about Filesender @ https://filesender.belnet.be
# code developed by Erik De Neve (Belnet servicedesk@belnet.be)
# initial script received 2016-06-30 from Mario Vandaele (Belnet servicedesk@belnet.be)

# cosmetic changes and use of getops, Stephane Plaisance (VIB-NC+BITS) 2016/07/01; v1.0
# edits for last curl for >20MB files (thanks to Erik De Neve from Belnet) 2016/08/17; v1.1
# correct typos 2016/08/18; v1.1.1
#
# visit our Git: https://github.com/Nucleomics-VIB

version="1.1.1, 2016_08_18"

usage='## Usage: filesender-cmd.sh 
# script version '${version}'
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
# [optional]: -v <verbose output (default to silent)>'

while getopts "i:r:s:m:f:l:p:g:vzh" opt; do
  case $opt in
    i) infile=${OPTARG} ;;
    r) tomail=${OPTARG} ;;
    s) subject=${OPTARG} ;;
    m) message=${OPTARG} ;;
    f) frommail=${OPTARG} ;;
    l) fromlogin=${OPTARG} ;;
    p) fropasswd=${OPTARG} ;;
    g) group=${OPTARG} ;;
    v) verb=1 ;;
    z) zipit=1 ;;
    h) echo "${usage}" >&2; exit 0 ;;
    \?) echo "Invalid option: -${OPTARG}" >&2; exit 1 ;;
    *) echo "this command requires arguments, try -h" >&2; exit 1 ;;
  esac
done

####################### Filesender parameters ######################
IDP_TO_USE=${group:-"VIB - Vlaams Instituut voor Biotechnologie"}
IDP_USER=${fromlogin:-""}
IDP_PASSWORD=${fropasswd:-""}
FILE_FROM=${fromemail:-""}

################### DO NOT EDIT BELOW THIS LINE ####################
####################### Message parameters #########################

# recipient is mandatory
if [ -z "${tomail+x}" ]
then
	echo "# no recipient email provided!"
	echo "${usage}"
	exit 1
fi

# check if email looks normal
if [[ "$tomail" != ?*@?*.?* ]]
then
	echo "this does not look like a valid email address"
	exit 1	
fi

# accepted email string
FILE_TO=${tomail}

SUBJECT=${subject:-"File shared with you"}
MESSAGE=${message:-"Please contact us for more information about this file"}

# clear non-standard characters in message
MESSAGE=$(echo ${MESSAGE} | sed -e 's/[^[:print:][:space:]]//g';)

FILESENDER_URL="https://filesender.belnet.be"
FILE_EXPIRY_DATE=$(date --date "+7 days" +"%d-%m-%Y")
DATE_PICKER=$(date --date "+7 days" +"%d-%m-%Y")

# input file is mandatory
if [ -z "${infile+x}" ]
then
	echo "# no file provided!"
	echo "${usage}"
	exit 1
fi

if [[ ( ! -f "${infile}" ) && ( ! -d "${infile}" ) ]]; then
	echo "${infile} file not found!"
	exit 1
fi

# if input is a folder (or -z passed), first zip-it
if [[ ( -d "${infile}" ) || ( ! -z "${zipit+x}" ) ]]; then
	echo "# creating archive version of ${infile}!"
	zip -q -r ${infile}.zip ${infile}
	#gzip -c ${infile} > ${infile}.gz
	infile=${infile}.zip
fi

# valid file selected
FILE_NAME=$(printf '%q' "${infile}")
echo "# processing ${FILE_NAME}"
FILE_SIZE=$(ls -Lon ${FILE_NAME} | awk '{ print $4 }')

# report file size
echo "# ${FILE_NAME} file has size ${FILE_SIZE}"

#####################Internal Parameters#################################
TMP_FILE=$(mktemp)
TMP_HEADER=$(mktemp)
COOKIE_FILE=$(mktemp)

# choose default verbosity
if [ -z "${verb+x}" ]; then
	CURL_OPTIONS="--silent --cookie $COOKIE_FILE --cookie-jar $COOKIE_FILE"
else
	CURL_OPTIONS="--verbose --cookie $COOKIE_FILE --cookie-jar $COOKIE_FILE"
fi
#########################################################################

#######################Functions#########################################
function jsonval {
	temp=$(echo $1 | sed 's/\\\\\//\//g' | sed 's/[{}]//g' |
	awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' |
	sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w $2)
	echo ${temp##*|}
}

function decode {
	echo $(echo "$1"| perl -MHTML::Entities -le 'while(<>) {print decode_entities($_);}')
}

function encode {
	echo $(echo "$1"| perl -MURI::Escape -le 'while(<>) {print uri_escape($_);}')
}

function cleanexit {
	rm $COOKIE_FILE
	rm $TMP_HEADER
	rm $TMP_FILE
	exit 1
}
#########################################################################

#########################Actions#########################################
#Fetch filesender URL
$(curl $CURL_OPTIONS --url $FILESENDER_URL --output $TMP_FILE)

#Look for login button and get decoded login URL
LOGON_URL=$(grep btn_logon "$TMP_FILE"|grep -o -E 'href="([^"#]+)"' | cut -d'"' -f2)
LOGON_URL=$(decode "$LOGON_URL")

#Fetch login URL
$(curl $CURL_OPTIONS --url $LOGON_URL --output $TMP_FILE)
REDIRECT_LINK=$(grep id=\"redirlink\" $TMP_FILE | grep -o -E 'href="([^"#]+)"' | \
	cut -d'"' -f2)
$(curl $CURL_OPTIONS --url $REDIRECT_LINK --output $TMP_FILE)

#Choose IDP
IDP_ORIGIN=$(grep -m 1 -B 1 -i "$IDP_TO_USE" $TMP_FILE | \
	grep -o -E 'value="([^"]+)"'| cut -d'"' -f2)
REDIRECT_LINK="$REDIRECT_LINK&action=selection&origin=$IDP_ORIGIN&cache=session"
REDIRECT_LINK=$(decode "$REDIRECT_LINK")
$(curl $CURL_OPTIONS \
	--dump-header $TMP_HEADER \
	--location \
	--url $REDIRECT_LINK \
	--output $TMP_FILE)

#Get Redirect URL to IDP And send Username password
TMP_URL=$(tac $TMP_HEADER | grep -m 1 Location | awk '{print $2}'| tr -d '\n\r')
$(curl $CURL_OPTIONS \
	--location \
	--data "j_username=$IDP_USER&j_password=$IDP_PASSWORD" \
	--url $TMP_URL \
	--output $TMP_FILE)

#Do Login into Filesender, get RelayState and SAMLResponse from file retrieved above
RELAY_STATE=$(grep RelayState "$TMP_FILE" | grep -o -E 'value="([^"]+)"'| cut -d'"' -f2)
RELAY_STATE=$(decode "$RELAY_STATE")
SAML_RESPONSE=$(grep SAMLResponse $TMP_FILE | grep -o -E 'value="([^"#]+)"' | cut -d'"' -f2)
TMP_URL=$(grep action $TMP_FILE | grep -o -E 'action="([^"]+)"' | cut -d'"' -f2)
TMP_URL=$(decode "$TMP_URL")

$(curl $CURL_OPTIONS --location \
	--form "RelayState=$RELAY_STATE" \
	--form "SAMLResponse=$SAML_RESPONSE" \
	--url $TMP_URL --output $TMP_FILE)

#Login succesfull?
TITLE=$(grep "<title>" $TMP_FILE|awk '{print tolower($0)}')
if [[ "$TITLE" != "<title> belnet filesender </title>" ]]
then
	echo "# Title don't match => exiting!"
	cleanexit
fi

#fetch s-token
S_TOKEN=$(grep -i "s-token" $TMP_FILE | grep -o -E 'value="([^"]+)"' | cut -d'"' -f2)

#create filesender post
FILESENDER_POST="{\"fileto\":\"$FILE_TO\",\
	\"filefrom\":\"$FILE_FROM\",\
	\"filesubject\":\"$SUBJECT\",\
	\"filemessage\":\"$MESSAGE\",\
	\"fileexpirydate\":\"$FILE_EXPIRY_DATE\",\
	\"datepicker\":\"$DATE_PICKER\",\
	\"aup\":\"true\",\
	\"filevoucheruid\":\"\",\
	\"vid\":\"\",\
	\"total\":\"\",\
	\"n\":\"\",\
	\"filestatus\":\"Available\",\
	\"loadtype\":\"standard\",\
	\"s-token\":\"$S_TOKEN\",\
	\"fileoriginalname\":\"$FILE_NAME\",\
	\"filesize\":$FILE_SIZE}"
	
FILESENDER_POST=$(encode "$FILESENDER_POST")
FILESENDER_POST="myJson=$FILESENDER_POST"
TMP_URL="$FILESENDER_URL/fs_upload.php?type=validateupload&vid="
$(curl $CURL_OPTIONS --url $TMP_URL --data $FILESENDER_POST --output $TMP_FILE)

CAT_TMP_FILE=$(cat $TMP_FILE)

#test for connection
if [[ "$CAT_TMP_FILE" =~ "complete" ]]
then
	echo "# connection succeeded"
else
	echo "# connection failed!"
	cleanexit
fi

#initiate upload
VID=$(jsonval $CAT_TMP_FILE vid)
TMP_URL="$FILESENDER_URL/fs_upload.php?type=chunk&vid=$VID"

# show progress while uploading
echo "# uploading data to server"

# adapt verbosity with --progress-bar instead of --silent
if [ -z "${verb+x}" ]; then
	CURL_OPTIONS_UPLOAD="--progress-bar --cookie $COOKIE_FILE --cookie-jar $COOKIE_FILE"
else
	CURL_OPTIONS_UPLOAD="--verbose --cookie $COOKIE_FILE --cookie-jar $COOKIE_FILE"
fi

$(curl $CURL_OPTIONS_UPLOAD \
	--header "Content-Disposition:attachment; name='fileToUpload'" \
	--header "Content-Type:multipart/form-data" \
	--url $TMP_URL \
	--data-binary "@$FILE_NAME" \
	--output $TMP_FILE)

TMP_URL="$FILESENDER_URL/fs_upload.php?type=uploadcomplete&vid=$VID"
$(curl $CURL_OPTIONS --request post --url $TMP_URL --output $TMP_FILE)

CAT_TMP_FILE=$(cat $TMP_FILE)

# test for transfer completion
if [[ "$CAT_TMP_FILE" =~ '{"status":"complete"}' ]]
then
	echo "# transfer succeeded"
else
	echo "# transfer failed!"
	cleanexit
fi
#########################################################################

#########################Close connection and Cleanup####################
TMP_URL="$FILESENDER_URL/index.php?s=complete"
$(curl $CURL_OPTIONS --url $TMP_URL --output $TMP_FILE)

rm $COOKIE_FILE
rm $TMP_HEADER
rm $TMP_FILE
