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
    
    echo "Encoding: $input -> $output"
    
    ffmpeg -i "$input" \
        -c:v libx265 \
        -preset slow \
        -crf 24 \
        -pix_fmt yuv420p \
        -profile:v main \
        -level 5.1 \
        -c:a copy \
        -tag:v hvc1 \
        -progress pipe:1 \
        "$output"
}
