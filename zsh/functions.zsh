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
    if [ $# -ne 1 ]; then
        echo "Usage: ff <input_file>"
        return 1
    fi
    
    local input="$1"
    local ext="${input##*.}"
    local base="${input%.*}"
    local output="${base}.ffmpeg.${ext}"
    
    ffmpeg -i "$input" \
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
