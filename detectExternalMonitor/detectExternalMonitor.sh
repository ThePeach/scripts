#!/bin/bash
#### LICENSED UNDER GPL v.2 ####
#	This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#    
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#       
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#   MA 02110-1301, USA.
#
#### AUTHOR ####
#	This program has been developed by
#	Matteo 'Peach' Pescarin
#	e-mail: peach[AT]smartart[DOT]it
#
#### REQUIREMENTS ####
# disper-0.2.3
# 	see: http://willem.engen.nl/projects/disper/
# xosd-2.2
# 	see: https://sourceforge.net/projects/libxosd/
# xrandr-1.3
#
#### HOW IT WORKS ####
# This program will cycle through:
#  1) single monitor
#  2) extended monitor on external
#  3) only external monitor
#
# if using -check flag it will check if there's a monitor connected
# and if it's in use, will enable the dual view as extended monitor

#### DEFINED VARIABLES ####
# Default screen name
DefaultScreenSize="1920x1080" # CONFIGURE THIS VARIABLE
# Current screen size
CurrentScreenSize=`xrandr | grep \* | awk '{ print $1 }'`
# Default name of external monitor when it's not plugged in (disper output)
DefaultExternalName="CRT-0"
# Name of the external monitor
ExternalName=`disper -l | grep $DefaultExternalName | awk '{ print $NF }'`
# Command basename
cmd=${0##*/}
# Help Msg
msg="$cmd is a simple script for using the dual head on laptops\n
Called with no arguments will cycle through single, extended and external\n
Monitor. Use with -check to auto-enable the external one (e.g. on startup)\n
\tUsage: $cmd [-h|--help|-check]\n
\t\t-h --help = this text\n
\t\t-check = Check presence of external lcd and enable/disable it accordingly\n"
# temporary files save path
DefaultSavePath="/tmp/"
# temporary files prefix
DefaultFilePrefix=`whoami`"_Monitor_"
# xosd program
Xosd="/usr/bin/osd_cat"
# Options for xosd
XosdOpts="-p middle -A center -f -adobe-helvetica-bold-*-*-*-34-*-*-*-*-*-*-* -d 1 -s 2"
# default color for OSD text
defaultColor="white"
# selected color for OSD text
selectedColor="red"
# laptop monitor OSD text
laptop="laptop"
# external monitor OSD text
external="external"
# extended monitor OSD text
extended=$external" + "$laptop

#### DEFINED FUNCTIONS ####
# XOSD display of 3 rows, call it with:
# displayText row1 color1 row2 color2 row3 color3
displayText() {
	echo -e $1 | osd_cat $XosdOpts -c $2 -o 50 &
	echo -e $3 | osd_cat $XosdOpts -c $4 &
	echo -e $5 | osd_cat $XosdOpts -c $6 -o -50 &
}

displayHelp() {
	echo -e $msg
}

toUpper() {
	echo $1 | tr [:lower:] [:upper:]
}

#### MAIN ####
if [ $# -lt 1 ]; then
	# cycle through modes
	if [ -e $DefaultSavePath$DefaultFilePrefix"single" ]; then
		# from single to extended
		rm $DefaultSavePath$DefaultFilePrefix"single"
		displayText "$laptop" $defaultColor "`toUpper $extended`" $selectedColor "$external" $defaultColor
		disper -e -t left
		touch $DefaultSavePath$DefaultFilePrefix"double"
	elif [ -e $DefaultSavePath$DefaultFilePrefix"double" ]; then
		# from extended to external
		rm $DefaultSavePath$DefaultFilePrefix"double"
		displayText "$laptop" $defaultColor "$extended" $defaultColor "`toUpper $external`" $selectedColor
		disper -S
		touch $DefaultSavePath$DefaultFilePrefix"external"
	elif [ -e $DefaultSavePath$DefaultFilePrefix"external" ]; then
		# from external to single
		rm $DefaultSavePath$DefaultFilePrefix"external"
		displayText "`toUpper $laptop`" $selectedColor "$extended" $defaultColor "$external" $defaultColor
		disper -s
		touch $DefaultSavePath$DefaultFilePrefix"single"
	else
		# find out if we are in single monitor mode
		if [ $ExternalName = $DefaultExternalName ]; then
			if [ $CurrentScreenSize = $DefaultScreenSize ]; then
				displayText "$laptop" $defaultColor "`toUpper $extended`" $selectedColor "$external" $defaultColor
				disper -e -t left
				touch $DefaultSavePath$DefaultFilePrefix"double"
			fi
		else # reset it to single
			if [ -e $DefaultSavePath$DefaultFilePrefix"double" ]; then
				rm $DefaultSavePath$DefaultFilePrefix"double"
			fi
			if [ -e $DefaultSavePath$DefaultFilePrefix"external" ]; then
				rm $DefaultSavePath$DefaultFilePrefix"external"
			fi
			displayText "`toUpper $laptop`" $selectedColor "$extended" $defaultColor "$external" $defaultColor
			disper -s
			if [ ! -e $defaultSavePath$DefaultFilePrefix"single" ]; then
				touch $DefaultSavePath$DefaultFilePrefix"single"
			fi
		fi
	fi
	chmod g+w $DefaultSavePath$DefaultFilePrefix*
	exit 0
elif [ $1 = "-check" ]; then
	# reset if any file was previously set
	if [ -e $DefaultSavePath$DefaultFilePrefix"double" ]; then
		rm $DefaultSavePath$DefaultFilePrefix"double"
	fi
	if [ -e $DefaultSavePath$DefaultFilePrefix"external" ]; then
		rm $DefaultSavePath$DefaultFilePrefix"external"
	fi
	if [ -e $DefaultSavePath$DefaultFilePrefix"single" ]; then
		rm $DefaultSavePath$DefaultFilePrefix"single"
	fi

	# see if there's no external monitor connected
	if [ $ExternalName = $DefaultExternalName ]; then
		# see if the current resolution is wider than the laptop monitor
		if [ $CurrentScreenSize != $DefaultScreenSize ]; then
			# move onto single monitor
			displayText "`toUpper $laptop`" $selectedColor "$extended" $defaultColor "$external" $defaultColor
			disper -s
			touch $DefaultSavePath$DefaultFilePrefix"single"
		fi
	else
		# the external monitor is plugged in
		# verify the external is not in use
		if [ $CurrentScreenSize = $DefaultScreenSize ]; then
			displayText "$laptop" $defaultColor "`toUpper $extended`" $selectedColor "$external" $defaultColor
			disper -e -t left
			touch $DefaultSavePath$DefaultFilePrefix"double"
		fi
	fi
	if [ -e $DefaultSavePath$DefaultFilePrefix* ]; then
		chmod g+w $DefaultSavePath$DefaultFilePrefix*
	else
		echo "nothing to do"
	fi
elif [[ $1 = "-h" || $1 = "--help" ]]; then
	displayHelp
	exit 0
else 
	displayHelp
	exit 0
fi
