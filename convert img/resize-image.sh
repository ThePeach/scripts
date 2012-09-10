#!/bin/bash
# ridimensiona tutti i file in una dir


for file in `ls`; do 
	echo "Resizing $file to 1280x1024"
	convert -resize 1280x1024 $file $file-1; 
	mv $file $file.old; 
	mv $file-1 $file;
done

