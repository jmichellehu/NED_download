#! /bin/bash

# Script to identify and download NED tiles that intersect with input imagery

# Usage:
# ./get_NED.sh img.NTF output_directory

set -e

# Input image
img=$1

# Output products directory (needs to include backslash)
out_dir=$2

# Check for correct number of inputs
if [ "$#" -ne 2 ] ; then
  echo "Usage is \`$(basename $0) img.ntf out_dir\`"
  exit
fi

cleanup=true

# Filenames
GCS_file=GCS_coords.txt
NED_names=NED.txt
utm_file=utm_zone.txt
dem_list=dem_list.txt

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
    if  [ -f ${standard_name} ] ; then
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
        else
            unzip -o ${out_dir}${NED} -d ${out_dir}
        fi

        if [ -e ${out_dir}img${tile}*.img ] ; then
            mv ${out_dir}img${tile}*.img ${out_dir}${standard_name}
            rm -rfv ${tile}/
        fi
        # Copy to flat file directory
        #cp ${out_dir}${standard_name} .
        
    fi

    # Extract UTM zone(s) epsg code(s) from dem
    #python $HOME/git_dirs/rs_tools/bin/utm_convert.py -in ${standard_name} | tail -n 1 | tee ${utm_file} 

    #while read z
    #do
    #  zone=${z}
    #done < ${utm_file}
    
    # This is the dem version you need
    #dem=${standard_name%.*}-adj_${zone}.tif
    dem=${standard_name%.*}-adj.tif
    echo ${dem} >> ${dem_list}
    
    if [ ! -f $dem ] ; then
        if [ ! -f ${NED%.*}-adj.img ] ; then
            dem_geoid --reverse-adjustment ${NED%.*}.img ; 
        fi
        #gdalwarp -co COMPRESS=LZW -co TILED=YES -co BIGTIFF=IF_SAFER -overwrite -r cubic -t_srs EPSG:${zone} -dstnodata -9999 -tr 10 10 ${NED%.*}-adj.tif ${dem}
    else
        echo "DEM already adjusted!"
    fi
    
done < ${GCS_file}

# Identify proper dems for imagery
dem_vrt=${img%.*}_NED_13.vrt

# Build vrt of dems if it does not exist
if [ ! -f ${dem_vrt} ]; then
    dems=$(grep '-adj' ${dem_list} | sort | uniq | wc -l)
    echo "Building vrt of dems..."
    gdalbuildvrt -input_file_list ${dem_list} ${dem_vrt}
    echo "vrt successfully built"
    
else
    echo "NED vrt already exists"
fi

if $cleanup ; then
    rm -rv *arcsec* readme.pdf *meta* *etadata* *thumb* *DataDictionary* ${NED_names} ${GCS_file} ${utm_file} ${dem_list}
fi
