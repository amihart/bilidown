#if

if which node lynx ffmpeg
then
	echo "Found necessary commands."
else
	echo "Please install nodejs lynx ffmpeg."
	exit
fi
if [[ "$1" == "" || "$2" == "" ]]
then
	echo "usage: bilidown [url] [file_name]"
	exit
fi

#Download page data.
url="$1"
data=$(lynx -source $url)
#Parse out the __playerinfo__ variable.
data=$(echo $data | grep '__playinfo__' | sed 's/.*__playinfo__\=//' | sed 's/[<][/]script.*//')
#Grab first non-error links
vidid=0
audid=0
while [[ $vidid != -1 || $audid != -1 ]]
do
	links=$(
	node << EOF
	    var playerinfo = JSON.parse('$data');
	    var vid = $vidid == -1 ? "" : playerinfo.data.dash["video"][$vidid].base_url;
	    var aud = $audid == -1 ? "" : playerinfo.data.dash["audio"][$audid].base_url;
	    console.log(vid + "###" + aud);
EOF
	)
	vid=$(echo $links | sed 's/###.*//')
	aud=$(echo $links | sed 's/.*###//')
	#Download the files
	if [[ $vidid != -1 ]]
	then
		wget -c --tries=inf "$vid" -O .tmpvid.mp4 && vidid=-1
	fi
	if [[ $audid != -1 ]]
	then
		wget -c --tries=inf "$aud" -O .tmpaud.mp4 && audid=-1
	fi
	if [[ $vidid != -1 ]]
	then
		vidid=$((vidid+1))
	fi
	if [[ $audid != -1 ]]
	then
		audid=$((audid+1))
	fi
done
#Merge audio and video streams
fname=$(echo "$2" | sed "s/\..*//").mp4
ffmpeg -i .tmpvid.mp4 -i .tmpaud.mp4 -c copy -map 0:v:0 -map 1:a:0 -shortest "$fname"
#Cleanup
rm ".tmpvid.mp4" ".tmpaud.mp4"
