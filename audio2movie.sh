#!/usr/local/bin/sh

# usage.
function usage() {
    cat <<EOS
Usage: sh $0 infile [outfile_ext (default: "mp4")] [bg_color (default: "black")] [resolution (default: "1024x576")] [fps (default: 30)]
EOS
}

# ensure that there are all required commands.
for CMD in ffmpeg ffprobe jq convert
do
    type $CMD >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "command not found: $CMD
please ensure that ffmpeg (with toolchain), jq and imagemagick are installed."
    fi
done

# init parameters.
OUTFILE_EXT="mp4"
BG_COLOR="black"
RESOLUTION="1024x576"
FPS="30"
if [ $# -eq 0 ]; then usage && exit 0; fi
if [ $# -ge 1 ]; then INFILE_NAME=$1; fi
if [ $# -ge 2 ]; then OUTFILE_EXT=$2; fi
if [ $# -ge 3 ]; then BG_COLOR=$3; fi
if [ $# -ge 4 ]; then RESOLUTION=$4; fi
if [ $# -ge 5 ]; then FPS=$5; fi

# get the duration of the input audio.
AUDIO_DURATION=`ffprobe -show_streams -print_format json $1 2>/dev/null | jq ".streams[0].duration" | cut -d '"' -f2`

# round the duration to integer.
AUDIO_DURATION_INT=`echo $AUDIO_DURATION | sed -E "s/\.[0-9]+$//g"`

# get the required number of images.
IMAGE_COUNT=`expr $AUDIO_DURATION_INT \* $FPS`

# create blank images.
TMP_DIR_NAME=~/tmp/audio2movie_`date +%s`
mkdir $TMP_DIR_NAME && cd $_
convert -size $RESOLUTION xc:$BG_COLOR origin.jpg
for i in `seq -f %06g 1 $IMAGE_COUNT`
do
    cp origin.jpg $i.jpg
done
cd -

OUTFILE_NAME=`echo $1 | sed -E "s/\.[^.]+$/.$OUTFILE_EXT/"`
ffmpeg -r 30 -i $TMP_DIR_NAME/%06d.jpg -i $1 -r 30 -vcodec libx264 -pix_fmt yuv420p $OUTFILE_NAME

rm -rf $TMP_DIR_NAME