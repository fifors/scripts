#!/bin/bash

function usage {
	echo Usage:
	echo options...
	echo I [name]	Image name \(optional\)
	echo p		Convert to the iPhone 4 format
	echo P		Convert to the iPod 2g format
	echo d		Rip from a DVD disk
	echo n		Basename for ripped files \(mandatory\)
	echo i [file]	Use this image instead of ripping a DVD
	echo D [disk]	Use this disk device for ripping image
	echo a		Rip DVD, convert to iPhone 4 and iPod \(default\)

}

function rip_dvd {
	# unmounts and rips the dvd to an iso image

	D=$1
	N=$2

	${ECHO} diskutil unmountDisk ${D}

	${ECHO} ${DD} ${DISK} ${N}.ripping

	if [ ! $? ]
	then
		echo Errors with dd
		exit 2
	fi

	mv ${N}.ripping ${N}
}

function convert_ipod {
	I=$1
	N=$2

	${ECHO} ${HB} -i ${I} -o ${DEST}${N} --preset=\"iPhone \& iPod Touch\" ${OUT}

	echo Moving ${DEST}${N} to ${IPOD}/
	${ECHO} mv ${DEST}${N} ${IPOD}/

	if [ ! $? ]
	then
		echo Errors with HandBrake..
		exit 3
	fi

}

function convert_iphone {
	I=$1
	N=$2

	${ECHO} ${HB} -i ${I} -o ${DEST}${N} --preset=\"iPhone 4\" ${OUT}

	if [ ! $? ]
	then
		echo Errors with HandBrake..
		exit 4
	fi

	echo Moving ${DEST}${N} to ${IPHONE}
	${ECHO} mv ${DEST}${N} ${IPHONE}/

}

ECHO=""
DD="/Users/peter/ddrescue-1.15/ddrescue"
HB="/Applications/HandbrakeCLI"
MOVIES="/Users/peter/Movies"
DVDs="${MOVIES}/DVDs"
IPOD="${MOVIES}/iPod"
IPHONE="${MOVIES}/iPhone"
OUT="&> /dev/null"
#OUT=""
ALL="1"
DEST="/Users/peter/video_tmp/"

while getopts ":I:pPdn:i:D:ah" OPT
do
	case ${OPT} in
		I) 	ISO=${OPTARG}
			#echo "ISO: ${ISO}"
			;;
		p) 	ALL=""
			iPn="1"
			#echo "iPhone selected"
			;;
		P) 	ALL=""
			iPd="1"
			#echo "iPod selected"
			;;
		d) 	ALL=""
			RIP="1";
			#echo "Ripping DVD"
			;;
		n) 	NAME=${OPTARG}
			#echo Name: ${NAME}
			;;
		D)	DISK=${OPTARG}
			#echo using Disk: ${DISK}
			;;
		a)	A=1
			#echo Setting all to on
			;;
		h)	usage
			exit 1
			;;
		\?)	usage
			exit 1
			;;
		:)
			echo Unknown option
			echo ""
			usage
			exit 1
			;;
	esac
done

if [ ! -z ${A} ]
then
	ALL=1
fi
if [ -z ${NAME} ]
then
	echo You must specify the file basename
	exit 1
else
	if [ -z ${ISO} ]
	then
		IMG=${DEST}${NAME}.iso
	else
		IMG=${ISO}
	fi
fi

if [ -z ${DISK} ]
then
	DISK="/dev/disk1"
fi

if [ -z ${ISO} ]
then
	echo Ripping DVD
	rip_dvd ${DISK} ${IMG}
fi

if [ ! -z ${ALL} ] || [ ! -z ${iPd} ]
then
	echo Converting to iPod format
	echo iPd: ${iPd} ALL: ${ALL}
	convert_ipod "${IMG}" "${NAME}.mp4"
fi

if [ ! -z ${ALL} ] || [ ! -z ${iPn} ]
then
	echo Converting to iPhone format
	echo iPn: ${iPn} ALL: ${ALL}
	convert_iphone "${IMG}" "${NAME}.mp4"
fi

if [ ! -f ${ISO} ]
then
	echo Moving DVD image
	${ECHO} mv ${IMG} ${DVDs}/
fi

echo Done backing up!
