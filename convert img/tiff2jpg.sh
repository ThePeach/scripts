#!/bin/bash

for img in `ls *.tif`
do
	echo "Converto $img in formato JPG - Compressione 85%"
	convert -quality 85 $img `echo $img | sed s/tif/jpg/`
done
  
