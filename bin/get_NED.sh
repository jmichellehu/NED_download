#! /bin/bash

# Script to identify and download NED tiles that intersect with input imagery

# Usage:
# ./get_NED.sh img.NTF output_directory

set -e

# Input image
img=$1

# Output products directory (needs to include backslash)
out_dir=$2

# Switch to adjust dem geoid
switch=$3

# Check for correct number of inputs
if [ "$#" -lt 2 ] ; then
  echo "Usage is \`$(basename $0) img.ntf out_dir/ dem_geoid_adjust_switch\`"
  exit 1
fi

# Correct for missing backslash
if [ ! "${out_dir: -1}" == "/" ] ; then
    out_dir=${out_dir}/
    echo $out_dir
fi

# Add switch
if [ -e ${switch} ] ; then
    switch=0
    echo ${switch}
fi

cleanup=true

# Filenames
GCS_file=${img%.*}_GCS_coords.txt
NED_names=${img%.*}_NED.txt
dem_list=${img%.*}_dem_list.txt

# Extract geographic coordinates for the input image
python $HOME/git_dirs/NED_download/bin/get_NED.py -in ${img} -NED 13 2>&1 | tee ${GCS_file}

echo "Checking for NED files..."

while read NED_filename
do
    NED=$(echo ${NED_filename} | tr "/" "\n" | tail -1)
    echo ${NED%.*} &>> ${NED_names}

    # Rename alternate .img name to conventional USGS... format
    standard_name=$(echo ${NED_filename} | tr "/" "\n" | tail -n 1)
    standard_name=${standard_name%.*}.img
    echo ${standard_name}
    
    # check if you've already downloaded it
    if  [ -e ${out_dir}${standard_name} ] ; then
        echo "File exists, skip downloading..."
    else
        if [ ! -e ${out_dir}${NED} ] ; then

            # Grab the standard version and unzip
            if wget ${NED_filename} -O ${out_dir}/${NED} ; then
                echo "USGS* version exists"
                
            # Grab the non-standard version, unzip and rename
            else 
                echo "USGS* version doesn't exist, trying other naming scheme"
                bucket=$(echo ${NED_filename} | tr "U" "\n" | head -n 1)
                tile=$(echo ${NED_filename} | tr "_" "\n"| tail -n 2 | head -n 1)
                NED_alt_filename=${bucket}${tile}.zip

                wget ${NED_alt_filename} -O ${out_dir}${NED}
            fi
        fi

        unzip -o ${out_dir}${NED} -d ${out_dir}

        # Rename unzipped DEM to standard name and remove extra directory
        if [ -e ${out_dir}img${tile}*.img ] ; then
            mv ${out_dir}img${tile}*.img ${out_dir}${standard_name}
            rm -rfv ${out_dir}${tile}/
        fi
    fi
    
    if [ "${switch}" == "0" ] ; then
        # This is the dem version you need
        dem=${standard_name%.*}-adj.tif
        echo ${dem} >> ${dem_list}
    else
        dem=${standard_name%.*}.tif
        echo ${dem} >> ${dem_list}
    fi
    
    if [ ! -e $dem ] ; then
        if [ ! -e ${NED%.*}-adj.img ] && [ "${switch}" == "0" ] ; then
            dem_geoid --reverse-adjustment ${out_dir}${NED%.*}.img ; 
            rm ${NED%.*}-log-dem_geoid*txt
        else
            gdalwarp  ${out_dir}${NED%.*}.img ${dem}
        fi
        
    else
        echo "DEM already adjusted!"
    fi
    printf "\n"
done < ${GCS_file}

# Identify proper dems for imagery
dem_vrt=${img%.*}_NED_13.vrt

# Build vrt of dems if it does not exist
if [ ! -e ${dem_vrt} ]; then
#     dems=$(grep 'adj' ${dem_list} | sort | uniq | wc -l) # Can't recall what this was for...
    echo "Building vrt of dems..."
    gdalbuildvrt -input_file_list ${dem_list} ${dem_vrt}
    echo "vrt successfully built"
    
else
    echo "NED vrt already exists"
fi

if $cleanup ; then
    if [ -e ${out_dir}readme.pdf ] ; then 
        rm -rv ${out_dir}*arcsec* ${out_dir}readme.pdf ${out_dir}*meta* ${out_dir}*etadata* ${out_dir}*thumb* ${out_dir}*DataDictionary*
    fi

    if [ -e ${NED_names} ] ; then
        rm ${NED_names} ${GCS_file} ${dem_list}
    fi
fi
