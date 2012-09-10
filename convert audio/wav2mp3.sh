#!/bin/bash
ls | awk '/.wav$/ {
	wav=$0; 
	mp3=$0;  
	sub(/.wav$/, ".mp3", mp3); 
	system("lame -h -b 320 \""wav"\" \""mp3"\"");
	system("rm \""wav"\"");
}'

exit 0
