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

#### CONFIGURABLE VARIABLES ####
# internal resolution/size
singleRes=`disper -l | grep DFP-0 -A 1 | awk '/resolutions/ { print $NF }'`
# Current screen resolution/size
currentRes=`xrandr | head -n 1 | awk '{ split($N0, a, ","); split(a[2], b, " "); print b[2]"x"b[4]; }'`
# Default name of external monitor when it's not plugged in (disper output)
DefaultExternalName="CRT-0"
# Name of the external monitor
ExternalName=`disper -l | grep "${DefaultExternalName}" | awk '{ print $NF }'`
# version
VERSION="0.2"
# Internal Variables
NO_ARGS=0 
E_OPTERROR=85
E_GENERROR=25
OLD_IFS="$IFS"
IFS=','
# Command basename
cmd=${0##*/}
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
# default direction
defaultDirection="left"
# the settings file name
fileName=""

#### DEFINED FUNCTIONS ####
# XOSD display of 3 rows, call it with:
# displayText row1 color1 row2 color2 row3 color3
function displayText() {
	echo -e $1 | osd_cat $XosdOpts -c $2 -o 50 &
	echo -e $3 | osd_cat $XosdOpts -c $4 &
	echo -e $5 | osd_cat $XosdOpts -c $6 -o -50 &
}

# converts the input in uppercase
function toUpper() {
	echo $1 | tr [:lower:] [:upper:]
}

# checks if a list $1 contains an item $2
function contains() {
    [[ $1 =~ $2 ]] && exit 0 || exit 1
}

# prints the usage message
function usage() {
	echo -e "$cmd is a simple script for using the dual head on laptops
\tCalled with no arguments will cycle through single, extended and
\texternal Monitor. Use with -check to auto-enable the external one
\t(e.g. on startup)\n
Syntax: $cmd [-h|-v|-c|-t left|right|top|bottom]
\t-h: shows this help
\t-v: be verbose
\t-c: Check presence of external display and enable/disable it accordingly
\t-t: direction, where to extend displays: 
\t\t'left', 'right', 'top', 'bottom', defaults to 'left'
\n"
}

# prints the version
function version() {
    echo -e "${cmd} - External monitor detect - version $VERSION\n"
}

# displays the version, the error and then the usage message
function error() {
    version
    echo -e "Error: $1\n"
    usage
}

# quits with the given output status
function quit {
    IFS=$OLD_IFS
    exit $1
}

# The expected flags are
#  h v c
while getopts ":hvct:" Option
do
    case $Option in
        h ) version
            usage
            quit 0;;
        v ) BE_VERBOSE=true;;
        c ) CHECK=true;;
        t ) DIRECTION=$OPTARG;;
    esac
done

# Decrements the argument pointer so it points to next argument.
# $1 now references the first non-option item supplied on the command-line
# if one exists.
shift $(($OPTIND - 1))

[[ -z "${DIRECTION}" ]] && DIRECTION=$defaultDirection

# no arguments, cycle through modes
if [[ -z $CHECK ]]; then
		[[ -n "${BE_VERBOSE}" ]] && echo ">> No arguments"

	if [ -e "${DefaultSavePath}${DefaultFilePrefix}single" ]; then
		# from single to extended
		[[ -n "${BE_VERBOSE}" ]] && echo ">> Switching from single to double"

		rm "${DefaultSavePath}${DefaultFilePrefix}single"
		displayText "$laptop" $defaultColor "`toUpper $extended`" $selectedColor "$external" $defaultColor
		disper -e -t ${defaultDirection}
		
		fileName="${DefaultSavePath}${DefaultFilePrefix}double"

	elif [ -e "${DefaultSavePath}${DefaultFilePrefix}double" ]; then
		# from extended to external
		[[ -n "${BE_VERBOSE}" ]] && echo ">> Switching from double to external only"

		rm "${DefaultSavePath}${DefaultFilePrefix}double"
		displayText "$laptop" $defaultColor "$extended" $defaultColor "`toUpper $external`" $selectedColor
		disper -S
		
		fileName="${DefaultSavePath}${DefaultFilePrefix}external"

	elif [ -e "${DefaultSavePath}${DefaultFilePrefix}external" ]; then
		# from external to single
		[[ -n "${BE_VERBOSE}" ]] && echo ">> Switching from external to single"
		
		rm "${DefaultSavePath}${DefaultFilePrefix}external"
		displayText "`toUpper $laptop`" $selectedColor "$extended" $defaultColor "$external" $defaultColor
		disper -s

		fileName="${DefaultSavePath}${DefaultFilePrefix}single"

	else
		# no previous configuration found
		[[ -n "${BE_VERBOSE}" ]] && echo ">> No previously set configuration found"
		[[ -n "${BE_VERBOSE}" ]] && echo ">> Checking the current situation..."

		# find out if we are in single monitor mode
		if [[ -n "${ExternalName}" ]]; then
			[[ -n "${BE_VERBOSE}" ]] && echo ">> Found external monitor attached"

			if [ "${currentRes}" = "${singleRes}" ]; then
				[[ -n "${BE_VERBOSE}" ]] && echo ">> Extending to external monitor"
				displayText "$laptop" $defaultColor "`toUpper $extended`" $selectedColor "$external" $defaultColor
				disper -e -t $DIRECTION

				fileName="${DefaultSavePath}${DefaultFilePrefix}double"
			fi

		else # reset it to single
			[[ -n "${BE_VERBOSE}" ]] && echo ">> No external monitor found"

			if [ "${currentRes}" != "${singleRes}" ]; then
				[[ -n "${BE_VERBOSE}" ]] && echo ">> Resetting to single monitor"
				displayText "`toUpper $laptop`" $selectedColor "$extended" $defaultColor "$external" $defaultColor
				disper -s

				fileName="${DefaultSavePath}${DefaultFilePrefix}single"
			fi
		fi
	fi

elif [[ -n $CHECK ]]; then
	# remove any file was previously created
	[[ -n "${BE_VERBOSE}" ]] && echo ">> Removing any previously created file..."
	rm "${DefaultSavePath}${DefaultFilePrefix}"*

	# see if there's no external monitor connected
	
	[[ -n "${BE_VERBOSE}" ]] && echo ">> Checking the current situation..."

	# see if the external monitor is connected
	if [[ -n "${ExternalName}" ]]; then
		fileName="${DefaultSavePath}${DefaultFilePrefix}double"

		[[ -n "${BE_VERBOSE}" ]] && echo ">> Found external monitor attached"

		# TODO check if external is attached with wrong direction
		#      and restore original direcion if needed
		if [ "${currentRes}" = "${singleRes}" ]; then
			[[ -n "${BE_VERBOSE}" ]] && echo ">> Extending to external monitor"
			displayText "$laptop" $defaultColor "`toUpper $extended`" $selectedColor "$external" $defaultColor
			disper -e -t $DIRECTION

		fi


	# we are in single monitor mode
	else 
		fileName="${DefaultSavePath}${DefaultFilePrefix}single"

		[[ -n "${BE_VERBOSE}" ]] && echo ">> Single monitor mode"

		if [ "${currentRes}" != "${singleRes}" ]; then
			[[ -n "${BE_VERBOSE}" ]] && echo ">> Resetting to single monitor"
			displayText "`toUpper $laptop`" $selectedColor "$extended" $defaultColor "$external" $defaultColor
			disper -s
		fi
	fi

fi

if [ ! -e $fileName ]; then
	[[ -n "${BE_VERBOSE}" ]] && echo ">> Creating ${fileName}"
	touch $fileName;
fi

[[ -n "${BE_VERBOSE}" ]] && echo ">> Setting permissions on ${fileName}"
chmod g+w $fileName

quit 0
