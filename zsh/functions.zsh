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
  local output="${base}.hevc.${ext}"
  ffmpeg -i "$input" \
    -map 0 \
    -c:v libx265 \
    -preset slow \
    -crf 22 \
    -pix_fmt yuv420p \
    -tag:v hvc1 \
    -c:a copy \
    "$output"
}
