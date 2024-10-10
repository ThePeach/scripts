#!/bin/bash
# This script just re-encodes mp4 videos via ffmpeg.
# Takes an _input_ folder and an _output_ folder as parameters.

inputDir=$1
outputDir=$2

if [ $inputDir == $outputDir ]; then
  echo "Error: same input and output directories";
  exit 2;
elif [ ! -e $inputDir ]; then
  echo "Error: input directory not found";
  exit 2;
fi

if [ ! -e $outputDir ]; then
  echo "Creating output directory";
  mkdir -p $outputDir;
fi

numFiles=`ls -l ${1}/*.mp4 | wc -l`
numProcessedFiles=0
numSkippedfiles=0

function status() {
  echo "-----"
  echo "==[ STATS ]=="
  echo -e "- Skipped ${numSkippedfiles}";
  echo -e "+ Processed ${numProcessedFiles}";
  echo -e "Done $(( $numProcessedFiles + $numSkippedfiles )) of ${numFiles}";
  echo "-----"
}

for i in `ls ${1}/*.mp4`; 
do
  fileName=`basename $i`;
  destFile="${outputDir}/${fileName}";

  if [ -s "$destFile" ];
  then
    echo -e "Skipped file ${destFile}: file exists.";
    numSkippedfiles=$(( $numSkippedfiles+1 ));
    continue;
  fi

  ffmpeg -i "${i}" "${destFile}";
  numProcessedFiles=$(( $numProcessedFiles+1 ));
  status;
done

