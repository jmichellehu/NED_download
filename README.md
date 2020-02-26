# NED_download
Tool to download [NED tiles]() (1/3 arc-second is default, 1 arc-second option exists) containing input imagery extents and create NED DEM vrt.  
## Requirements
gdal: `conda install gdal`  
tested on versions 2.4.1 and 2.0.2

## Installation
```
cd # change to home directory
mkdir git_dirs
cd git_dirs
git clone https://github.com/jmichellehu/NED_download.git
```
Relies on gdal utilities and uses [Ames Stereo Pipeline's](https://github.com/NeoGeographyToolkit/StereoPipeline) `dem_geoid` to adjust NED delivery's NAVD88 datum. Can optionally turn off geoid adjustment with switch

## Usage from command line
`get_NED.sh input_img.tif output_directory`
  
Example to turn off geoid adjustment
`get_NED.sh input_img.tif output_directory 1`
  
To obtain 1 arc-second NED tiles, alter line 45 in `get_NED.sh` from  
`python $HOME/git_dirs/NED_download/bin/get_NED.py -in ${img} -NED 13 2>&1 | tee ${GCS_file}`  
to  
`python $HOME/git_dirs/NED_download/bin/get_NED.py -in ${img} -NED 1 2>&1 | tee ${GCS_file}`
