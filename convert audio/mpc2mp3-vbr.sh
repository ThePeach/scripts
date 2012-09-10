#!/bin/bash
ls | awk '/.mpc$/ {
	mpc=$0; 
	wav=$0; 
	mp3=$0;  
	sub(/.mpc$/, ".wav", wav); 
	system("mppdec \""mpc"\" \""wav"\"");
	sub(/.mpc$/, ".mp3", mp3); 
	system("lame -h -V 3 \""wav"\" \""mp3"\"");
	system("rm \""wav"\" \""mpc"\"");
}'


exit 0
