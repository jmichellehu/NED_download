#! /bin/bash

# Script to convert NAVD88 to proper datums
# Switch is a boolean 0 or 1 (loop thr)

# Usage:
# ./datum_correct.sh switch dem.img epsgcode

### # TODO:
# Need to incorporate handling for multiple dems gdalwarp loop

set -e

# Toggle to handle loops
switch=$1

# Input image
ned=$2

epsg=$3

cleanup=true

if [ ${switch} == "1" ]
then
  echo "first"
  for ned in *IMG.img; do dem_geoid --reverse-adjustment $ned; done;
else
  echo "second"
  dem_geoid --reverse-adjustment $ned
  gdalwarp -t_srs EPSG:${epsg} $ned ${ned%.*}_${epsg}.tif
fi
