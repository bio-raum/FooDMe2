#!/usr/bin/env bash
#set -e
#set -u
#set -o pipefail

# Fetch the pre-built BLAST nt database
# Author: G. Denay, gregoire.denay@cvua-rrw.de

VERSION=2.1

# URLs -------------------------------------------------------------

BLAST="https://ftp.ncbi.nlm.nih.gov/blast/db/"
TAXDUMP="https://ftp.ncbi.nlm.nih.gov/pub/taxonomy/new_taxdump/"

# Arguments parsing ------------------------------------------------

USAGE="Usage: $0 -d DIRECTORY [-v] [-h]"

while getopts :d:chvt opt
do
  case $opt in
  d ) directory=$OPTARG
      ;;
  h ) help=true
      ;;
  v ) version=true
      ;;
  : ) echo "Missing option argument for -$OPTARG" >&2
      echo $USAGE >&2
      exit 1
      ;;
  '?' ) echo "$0: invalid option -$OPTARG" >&2
      echo $USAGE >&2
      exit 1
      ;;
  esac
done

## version
if [[ $version == true ]]
then 
  echo "fetch_nt_blast.sh version: $VERSION"
fi

# help
if [[ $help == true ]]
then 
  echo "fetch_nt_blast.sh (version: $VERSION)"
  echo "Fetch the pre-built BLAST nt database and taxdump files"
  echo
  echo $USAGE
  echo
  echo "Options:"
  echo "  -d: output directory for the database"
  echo "  -v: Print version and exit"
  echo "  -h: Print this help and exit"
fi  

## Check if directory is set
if [ -v directory ]; then
  # make sure the directory exists"
  mkdir -p "$directory"
else
  # set current dir als target
  directory="$PWD"
fi

echo "[$( date -I'minutes')][INFO] Using following URLS, check if up-to-date:"
echo "[$( date -I'minutes')][INFO] BLAST: https://ftp.ncbi.nlm.nih.gov/blast/db/"

echo "[$( date -I'minutes')][INFO] Database will be created in $directory"
cd "$directory"

# Main script ------------------------------------------------------------

# Get directory listing in html format
echo "[$( date -I'minutes')][INFO] Retrieving remote directory ${BLAST}"
if curl ${BLAST} --fail --silent > ftp_dir.html; then :
else
  echo "[$( date -I'minutes')][ERROR] URL does not exist: ${BLAST}"
  exit 1
fi

# Get Readme
wget --quiet --tries 3 -O README.html ${BLAST}README

# Cleanup older links
if [ -f links ]; then
  rm links
fi


# Extract checksums and fasta links
echo "[$( date -I'minutes')][INFO] Extracting links"
paste \
  <(grep -E "\"nt\.[0-9]+\.tar\.gz\"" ftp_dir.html \
    | cut -d'"' -f2 \
    | awk  -v blast=${BLAST} '{print blast$0}' \
    | sort -d ) \
  <(grep -E "\"nt\.[0-9]+\.tar\.gz\.md5\"" ftp_dir.html \
  | cut -d'"' -f2 \
  | awk  -v blast=${BLAST} '{print blast$0}' \
  | sort -d ) \
  > links

while IFS=$'\t' read -r part md5; do
  # Getting checksum (always fresh)
  wget -N --quiet --tries 3 $md5
  
  # check if file exist
  if [ -f $(basename ${part}) ]; then
    echo "[$( date -I'minutes')][WARNING] $(basename ${part}) already exists"
    md5sum --quiet -c $(basename ${md5})
    
    # md5 exit status should be 0 if everything is ok
    if [ $? -ne 0 ]; then
      # Re download and check md5
      echo "[$( date -I'minutes')][WARNING] Checksum invalid, redownloading $(basename ${part})"
      rm $(basename ${part})
      wget --quiet --tries 3 $part
      md5sum --quiet -c $(basename ${md5})
      
      # Check md5 status and exit on error
      if [ $? -ne 0 ]; then
        echo "[$( date -I'minutes')][ERROR] md5 checksum invalid for file $(basename ${part})"
        exit 1
      else
        echo "[$( date -I'minutes')][INFO] $(basename ${part}): checksum OK"
      fi
      
    else
      echo "[$( date -I'minutes')][INFO] $(basename ${part}): checksum OK"
    fi
    
  else
    # download and check md5
    echo "[$( date -I'minutes')][INFO] Downloading $(basename ${part})"
    wget --quiet --tries 3 $part
    md5sum --quiet -c $(basename ${md5})
    
    # Check md5 status and exit on error
    if [ $? -ne 0 ]; then
      echo "[$( date -I'minutes')][ERROR] md5 checksum invalid for file $(basename ${part})"
      exit 1
    else
      echo "[$( date -I'minutes')][INFO] $(basename ${part}): checksum OK"
    fi
  
  fi
  
done < links

# Unpack and clean all
echo "[$( date -I'minutes')][INFO] Unpacking and cleaning up archives"
for f in *.tar.gz; do
	tar -xzvf $f \
	&& rm $f
done

echo "[$( date -I'minutes')][INFO] DONE"