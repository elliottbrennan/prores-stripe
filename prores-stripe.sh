#!/bin/bash
echo "path to source video files"
read INPUT

cd "$INPUT"

if [ ! -d prores_timecode ]; then
	mkdir -p prores_timecode
fi

declare -i count=1
declare -i minutes=0
declare -i hours=0
newtimecode=0

for i in *.mov *.mp4 *.mkv *.m4a; do
	if [ ! -e "$i" ]; then continue; fi
	name=${i%.*}

	name=${name// /_}
	name=${name//./_}
	name=${name//-/_}
	name=${name//@/_}
	name=${name//__/_}
	name=${name//__/_}

	frame_rate=$(ffprobe -i "$i" -show_streams 2>&1|grep fps|sed "s/.*, \([0-9.]*\) fps,.*/\1/")

	time_code=$(ffprobe -i "$i" -show_streams -show_format 2>&1|grep timecode|sed "s/.*, \([0-9.]*\) timecode,.*/\1/")

#.
#. assume NDF, else use drop frame semicolon
#.
	timebase=":"
	if [[ $frame_rate == '29.97' || $frame_rate == '59.94' ]]; then
		timebase=";"
	fi

#.
#. passthru timecode metadata; otherwise add it
#.
	if [[ $time_code != "timecode=N/A" ]]; then
		ffmpeg -i $i -map 0:v -c:v prores_ks -profile:v 4 -quant_mat hq -max_muxing_queue_size 1024 -map 0:a -codec:a copy -map 0:d "prores_timecode/$name-prores.mov"
		echo $name "   " $frame_rate "   " $time_code 
	else
		minutes=$(( ( $count * 11 ) % 60))
		hours=$(( ( $count * 11 / 60 ) % 24))
		newtimecode=$(printf %02d $hours)
		newtimecode+=":"
		newtimecode+=$(printf %02d $minutes)
		newtimecode+=":00"
		newtimecode+=$timebase
		newtimecode+="00"

		echo "NO TIMECODE" $name "   " $frame_rate "   " $newtimecode
		ffmpeg -i $i -map 0:v -c:v prores_ks -profile:v 4 -quant_mat hq -max_muxing_queue_size 1024 -timecode $newtimecode -map 0:a -codec:a copy -map 0:d? "prores_timecode/$name-prores-striped.mov"
		(( count++ ))
	fi

done
