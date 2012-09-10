#!/bin/sh
# A Kino script that tries to convert anything to raw DV

IN="$1"
OUT="$2"
normalisation="$3"
aspect="$4"
# frequency="$5"
# FFMPEG can only write 48KHz DV audio
frequency="48000"
size=`[ "$normalisation" = "pal" ] && echo "720x576" || echo "720x480"`
pixfmt=`[ "$normalisation" = "pal" ] && echo "yuv420p" || echo "yuv411p"`

sighandler()
{
    kill -KILL $FFMPEG_PID 2> /dev/null
    kill -KILL $AMENCODER_PID 2> /dev/null
    kill -KILL $VMENCODER_PID 2> /dev/null
    exit 0
}
trap sighandler TERM INT

atexit()
{
    rm -f "$AUDIO_FIFO" "$VIDEO_FIFO" 2>&1 >/dev/null
}
trap atexit EXIT

# Use local ffmpeg, if available
which ffmpeg-kino > /dev/null
[ $? -eq 0 ] && ffmpeg="ffmpeg-kino" || ffmpeg="ffmpeg"

# It appears some formats just don't work well with menoder (Ogg Theora)
mencoder_blacklist=$(echo $IN | grep -e '^.*\.\(ogg\)$')

which mencoder > /dev/null
if [ $? -eq 0 ] && [ -z $mencoder_blacklist ]; then
    AUDIO_FIFO="$1".pcm
    VIDEO_FIFO="$1".i420
    rm -f "$AUDIO_FIFO" "$VIDEO_FIFO" 2>&1 >/dev/null
    mkfifo "$AUDIO_FIFO"
    mkfifo "$VIDEO_FIFO"
    
    if [ "$normalisation" = "pal" ]; then
        width=`[ "$aspect" = "4:3" ] && echo "768" || echo "1024"`
        expand=`[ "$aspect" = "4:3" ] && echo "$width:576" || echo "$width:576"`
        ofps="25"
    else
        width=`[ "$aspect" = "4:3" ] && echo "640" || echo "852"`
        expand=`[ "$aspect" = "4:3" ] && echo "$width:480" || echo "$width:480"`
        ofps="30000/1001"
    fi

    mencoder -o "$AUDIO_FIFO" -of rawaudio -ofps $ofps -oac pcm -vf harddup \
        -af channels=2,volnorm,resample=48000:0:1 -ovc copy "$1" &
    AMENCODER_PID="$!"
    
    mencoder -o "$VIDEO_FIFO" -of rawvideo -nosound -ofps $ofps -ovc raw -xy $width -zoom \
        -vf dsize=${expand}:0,scale,expand=${expand},format=I420,harddup "$1" &
    VMENCODER_PID="$!"
    
    $ffmpeg -f s16le -ar 48000 -ac 2 -i "$AUDIO_FIFO" \
        -f rawvideo -pix_fmt yuv420p -r $normalisation -s $expand -i "$VIDEO_FIFO" \
        -s $size -r $normalisation -aspect $aspect \
        -ac 2 -ar $frequency -pix_fmt $pixfmt -y "$OUT" &
    FFMPEG_PID="$!"
    wait $AMENCODER_PID $VMENCODER_PID $FFMPEG_PID

else
    $ffmpeg -i "$IN" -s $size -r $normalisation -aspect $aspect \
        -ac 2 -ar $frequency -pix_fmt $pixfmt -y "$OUT" &
    FFMPEG_PID="$!"
    wait $FFMPEG_PID
fi
