#! /bin/bash

# Script to identify and download NED tiles that intersect with input imagery

# Usage:
# ./get_NED.sh img.NTF output_directory

set -e

# Input image
img=$1
# Output products directory
out_dir=$2

cleanup=true

# Extract geographic coordinates for the input image
GCS_file=GCS_coords.txt
NED_names=NED.txt

python $HOME/git_dirs/NED_download/bin/get_NED.py -in ${img} -NED 13 2>&1 | tee ${GCS_file}

echo "Downloading DEMs..."

while read NED_filename
do
  NED=$(echo ${NED_filename} | tr "/" "\n" | tail -1)
  echo ${NED%.*} &>> ${NED_names}
  # wget ${NED_filename} -O ${out_dir}/${NED}
  # unzip -o ${out_dir}/${NED}
done < ${GCS_file}

if $cleanup ; then
    rm GCS_coords.txt
fi
