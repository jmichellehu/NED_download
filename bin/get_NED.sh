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
    # Rename .img to USGS... conventional filename
    standard_name=$(echo ${NED_filename} | tr "/" "\n" | tail -n 1)
    standard_name=${standard_name%.*}.img
    echo ${standard_name}
    
    # check if you've already downloaded it
    if  [ -f ${standard_name} ] ; then
        echo "File exists, skip downloading and move to next file..."
    else
        if wget ${NED_filename} -O ${out_dir}/${NED} ; then
            echo "USGS* version exists"
            unzip -o ${out_dir}${NED} -d ${out_dir}
        else 
            echo "USGS* version doesn't exist, trying other naming scheme"
            bucket=$(echo ${NED_filename} | tr "U" "\n" | head -n 1)
            tile=$(echo ${NED_filename} | tr "_" "\n"| tail -n 2 | head -n 1)
            NED_alt_filename=${bucket}${tile}.zip

            wget ${NED_alt_filename} -O ${out_dir}${NED}
            unzip -o ${out_dir}${NED} -d ${out_dir}
            mv ${out_dir}img${tile}*.img ${out_dir}${standard_name}
        fi
        cp ${out_dir}${standard_name} .
    fi
    
done < ${GCS_file}

if $cleanup ; then
    rm GCS_coords.txt
fi
