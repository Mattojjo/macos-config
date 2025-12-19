# ============================================
# CUSTOM FUNCTIONS
# ============================================

# Add album art to MP3 files using eyeD3
d3() {
  if [ $# -ne 2 ]; then
    echo "Usage: d3 <image> <mp3>"
    return 1
  fi
  
  eyeD3 --add-image "$1:FRONT_COVER" "$2"
}

# Convert video to H.265/HEVC with high quality
ff() {
    if [ $# -lt 1 ] || [ $# -gt 2 ]; then
        echo "Usage: ff <input_file> [end_time]"
        echo "Example: ff movie.mkv 1:30:46"
        return 1
    fi
    
    local input="$1"
    local end_time="$2"
    local ext="${input##*.}"
    local base="${input%.*}"
    local output="${base}.ffmpeg.${ext}"
    
    local time_args=()
    if [ -n "$end_time" ]; then
        time_args=(-to "$end_time")
    fi
    
    ffmpeg -i "$input" "${time_args[@]}" \
        -map 0:v \
        -map 0:a \
        -c:v libx265 \
        -preset slow \
        -crf 24 \
        -pix_fmt yuv420p \
        -profile:v main \
        -level 5.1 \
        -x265-params "aq-mode=3:psy-rd=1.0" \
        -tag:v hvc1 \
        -c:a copy \
        "$output"
}
