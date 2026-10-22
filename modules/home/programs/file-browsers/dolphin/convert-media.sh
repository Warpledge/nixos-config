# Converts a video or audio file to a format chosen via kdialog, invoked from
# Dolphin's right-click "Convert Media" service menu entry.
# Runs in the background so Dolphin isn't blocked; notifies via notify-send
# when done or on failure. writeShellApplication adds the shebang and set -euo.

# Dolphin runs Exec= synchronously; re-exec detached so the menu doesn't block.
if [ -z "${CONVERT_VIDEO_DETACHED:-}" ]; then
    CONVERT_VIDEO_DETACHED=1 setsid "$0" "$@" </dev/null >/dev/null 2>&1 &
    exit 0
fi

input="$1"
[ -f "$input" ] || exit 1

dir=$(dirname "$input")
base=$(basename "$input")
name="${base%.*}"

# No video stream => treat as audio-only and offer audio formats.
if ffprobe -v error -select_streams v -show_entries stream=codec_type -of csv=p=0 "$input" | grep -q .; then
    is_audio=0
else
    is_audio=1
fi

if [ "$is_audio" = 1 ]; then
    format=$(kdialog --title "Convert Audio" --menu "Convert \"$base\" to:" \
        mp3 "MP3" \
        flac "FLAC (lossless)" \
        wav "WAV (uncompressed)" \
        ogg "OGG (Vorbis)" \
        m4a "M4A (AAC)" \
    ) || exit 0
else
    format=$(kdialog --title "Convert Video" --menu "Convert \"$base\" to:" \
        mp4 "MP4 (H.264/AAC)" \
        mkv "MKV (H.264/AAC)" \
        webm "WebM (VP9/Opus)" \
        gif "GIF (animated)" \
        mp3 "MP3 (audio only)" \
    ) || exit 0
fi

[ -z "$format" ] && exit 0

output="$dir/$name.$format"
if [ -e "$output" ]; then
    output="$dir/${name}-converted.$format"
fi

convert_in_background() {
    case "$format" in
        mp4|mkv)
            ffmpeg -y -i "$input" -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" -c:v libx264 -crf 20 -preset medium -c:a aac -b:a 192k "$output"
            ;;
        webm)
            ffmpeg -y -i "$input" -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" -c:v libvpx-vp9 -crf 32 -b:v 0 -c:a libopus -b:a 128k "$output"
            ;;
        gif)
            ffmpeg -y -i "$input" -vf "fps=15,scale=480:-2:flags=lanczos" "$output"
            ;;
        mp3)
            ffmpeg -y -i "$input" -vn -c:a libmp3lame -b:a 192k "$output"
            ;;
        flac)
            ffmpeg -y -i "$input" -vn -c:a flac "$output"
            ;;
        wav)
            ffmpeg -y -i "$input" -vn -c:a pcm_s16le "$output"
            ;;
        ogg)
            ffmpeg -y -i "$input" -vn -c:a libvorbis -q:a 6 "$output"
            ;;
        m4a)
            ffmpeg -y -i "$input" -vn -c:a aac -b:a 192k "$output"
            ;;
    esac
}

title="Convert Video"
[ "$is_audio" = 1 ] && title="Convert Audio"

if convert_in_background 2>"/tmp/convert-video-$$.log"; then
    notify-send "$title" "Finished: $(basename "$output")"
    rm -f "/tmp/convert-video-$$.log"
else
    notify-send -u critical "$title failed" "$(basename "$input") — see log: /tmp/convert-video-$$.log"
fi
