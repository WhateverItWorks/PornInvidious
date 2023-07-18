#!/usr/bin/env sh

if [ -z "$1" ]; then
	echo 'Wrong usage'
	echo 'Do not run this file directly'
	exit 1
fi

[ -e 'input.html' ] && rm 'input.html'
[ -e 'output.html' ] && rm 'output.html'

HTML_START="$(cat 'res/html_start')"
HTML_END="$(cat 'res/html_end')"
HTML_STYLE="$(cat 'res/css.css')"
HTML_VIDEO=''

wget "https://www.xvideos.com$1" -O 'input.html'

echo "$1" | grep '^/video'

if [ $? = 0 ]; then
	str="$(grep 'video_related=' 'input.html' | sed 's/,/\n/g')"
	video="$(grep 'setVideoUrlHigh' 'input.html' | cut -d"'" -f2)"
	video_low="$(grep 'setVideoUrlLow' 'input.html' | cut -d"'" -f2)"
	if [ -z "$video" ]; then
		video="$video_low"
	fi
	grep 'video-hd-mark' 'input.html'
	if [ "$?" -eq 0 ]; then
		video_hls="$(grep 'setVideoHLS' 'input.html' | cut -d"'" -f2)"
	else
		video_hls=''
	fi
	video_thumb="$(grep 'setThumbUrl' 'input.html' | cut -d"'" -f2 | sed 1q)"
	thumbs="$(echo "$str" | grep '"i":' | sed 's/\\//g' | sed 's/"i"://g' | sed 's/"//g')"
	urls="$(echo "$str" | grep '"u":' | sed 's/\\//g' | sed 's/"u"://g' | sed 's/"//g')"
	HTML_VIDEO="<center><video poster='$video_thumb' controls autoplay loop><source src='$video'/></video></center><center id='infoblock'>"
	if [ ! -z "$video_hls" ]; then
		HTML_VIDEO="$HTML_VIDEO<h3>HD Stream: </h3><input type='text' size='50' value='$video_hls'/><br/>(use with a video player)"
	fi
	HTML_VIDEO="$HTML_VIDEO</center>"
else
	urls="$(grep -E -o '<div class="thumb"><a href="(.*)">' 'input.html' | cut -d'"' -f4)"
	thumbs="$(echo "$i" | grep -E -o 'data-src="(.*)"' 'input.html' | cut -d'"' -f2)"
fi

echo "$thumbs" > thumbs.txt
echo "$urls" > urls.txt

echo "$HTML_START" >> output.html
echo "$HTML_VIDEO" >> output.html
echo "<section>" >> output.html
for i in $(seq "$(wc -l urls.txt | cut -d' ' -f1)"); do
	url="$(tail -n "+$i" urls.txt | sed 1q)"
	title="$(echo "$url" | cut -d'/' -f5 | sed 's/_/ /g')"
	if [ -z "$title" ]; then
		title="$(echo "$url" | cut -d'/' -f3 | sed 's/_/ /g')"
	fi
	if [ "$title" = "THUMBNUM" ]; then
		title="$(echo "$url" | cut -d'/' -f4 | sed 's/_/ /g')"
	fi
	thumb="$(tail -n "+$i" thumbs.txt | sed 1q | sed 's/THUMBNUM/1/g')"
	echo "<div><a href='$url'><img src='$thumb'/><br/>$title</a></div>" >> output.html
done
echo "</section>" >> output.html

echo "<style>" >> output.html
echo "$HTML_STYLE" >> output.html
echo "</style>" >> output.html
echo "$HTML_END" >> output.html

rm 'thumbs.txt' 'urls.txt' 'input.html'
