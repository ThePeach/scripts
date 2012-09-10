#!/bin/bash
ls | awk '/.ape$/ {
	ape=$0; 
	wav=$0; 
	mp3=$0;  
	sub(/.ape$/, ".wav", wav); 
	system("mac \""ape"\" \""wav"\" -d");
	sub(/.ape$/, ".mp3", mp3); 
	system("lame -h -V 4 \""wav"\" \""mp3"\"");
	system("rm \""wav"\" \""ape"\"");
}'

#files=`ls | grep .ape$`
#echo $files
#for file in $files
#do
#	name=`basename $file .ape`
#	mac $file $name".wav" -d
#	lame -h -V 4 $name".wav" $name".mp3"
#done
#
exit 0
