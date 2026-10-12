-------------------------------------------------------------------------
README.txt
-------------------------------------------------------------------------

Data provided by the VIB Nucleomics core (nucleomics@vib.be).

DOWNLOAD USING CURL COMMAND LINE

The shared link would be like this https://nextnuc.gbiomed.kuleuven.be/index.php/s/XZYXZYXZY
where you could identify the token (e.g. XZYXZYXZY) and you should have received a password (e.g. we call it here l_connect_pwd) to access to it.

	token=XZYXZYXZY
	l_connect_pwd=XXXX 

You need also to specify which file you want to download. Usually the data are in archive format (e.g. exp0000.tar.gz).
	FILENAME=exp0000.tar.gz 

    curl -f -C - \
      -u "${token}:${l_connect_pwd}" \
      -o "${FILENAME}" \
      "https://nextnuc.gbiomed.kuleuven.be/public.php/webdav/${FILENAME}"

notes:
-f   stop on an HTTP error instead of writing the server's error page into
       ${FILENAME} (a wrong password otherwise leaves you with a small
       corrupt "tar")
-C - resume an interrupted download; re-run the same command to continue.


DOWNLOAD USING WRAPPER SCRIPT

You can use a wrapper script available at https://github.com/aertslab/nextcloud_share_url_downloader
The tool only requires the link and password.
Then it lists the content of the share and allows you to select which files you want to download.


DOWNLOAD USING CURL COMMAND LINE (Windows)

The easiest route is the real curl that ships with Windows 10 and later. Your Linux command works almost as-is: curl.exe -C - -u "token:pwd" -o outputfile webdavpath/inputfile. Type curl.exe and not curl, because in 5.1 curl is an alias for Invoke-WebRequest.
If you don't have curl.exe, use the following lines for Invoke-WebRequest commands.

# set up variables
$FILENAME=exp0000.tar
$token=XZYXZYXZY
$l_connect_pwd=XXXX 

# using powershell 5.1

$pair  = "$token:$l_connect_pwd"
$b64   = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($pair))
$headers = @{ Authorization = "Basic $b64" }
Invoke-WebRequest -Uri "https://nextnuc.gbiomed.kuleuven.be/public.php/webdav/$FILENAME" -OutFile "$FILENAME" -Headers $headers

# PowerShell 7+ (supports resume, like curl -C -):

$cred = New-Object System.Management.Automation.PSCredential("$token", (ConvertTo-SecureString "$l_connect_pwd" -AsPlainText -Force))
Invoke-WebRequest -Uri "https://nextnuc.gbiomed.kuleuven.be/public.php/webdav/$FILENAME" `
  -OutFile "$FILENAME" `
  -Credential $cred `
  -Authentication Basic `
  -Resume

Notes:
Speed on 5.1: for large files, put $ProgressPreference = 'SilentlyContinue' before the command. The progress bar can make the download much slower.


CHECK TRANSFER

If you want to check whether you downloaded the large .tar.gz file correctly, you can use the MD5-checksum (see file ending with md5sum.txt). 
The checksum can be obtained with software such as http://winmd5.com.

UNPACK COMPRESSED ARCHIVE

To save disk space and bandwidth over the network all files are saved using compression program. 
To decompress the tar.gz file on a Linux/MacOSX system, you can use use the command tar -xzvf file.tar.gz
To decompress the tar.gz file on a Windows system, you can use 7zip (www.7-zip.org/).

------
Keep in mind that we will store your data on our servers only up to three months (starting from the delivery date).
If you have any questions, just contact us. 

The VIB Nucleomics BioIT team.

-------------------------------------------------------------------------
VIB Nucleomics Core - delivery README v1.1 (2026-10-02)
-------------------------------------------------------------------------
