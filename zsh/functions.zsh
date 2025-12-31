# ============================================
# CUSTOM FUNCTIONS
# ============================================

# Add album art to audio files (supports MP3 and M4A)
d3() {
  if [ $# -lt 2 ]; then
    echo "Usage: d3 <image> <audio_file(s)> [artist] [album]"
    return 1
  fi
  
  local image="$1"
  shift
  
  # Check if last two arguments are metadata (if they're not files)
  local artist=""
  local album=""
  local files=("$@")
  
  # Check last argument for album
  if [ ! -f "${@: -1}" ]; then
    album="${@: -1}"
    files=("${@:1:$#-1}")
  fi
  
  # Check second to last for artist
  if [ ${#files[@]} -gt 0 ] && [ ! -f "${files[-1]}" ]; then
    artist="${files[-1]}"
    files=("${files[@]:0:${#files[@]}-1}")
  fi
  
  for file in "${files[@]}"; do
    local ext="${file##*.}"
    case "$ext" in
      m4a|mp4|m4v)
        # Use ffmpeg for M4A/MP4 files
        local temp="${file%.*}.temp.${ext}"
        echo "Processing: $file"
        
        local metadata_args=()
        if [ -n "$artist" ]; then
          metadata_args+=(-metadata artist="$artist")
        fi
        if [ -n "$album" ]; then
          metadata_args+=(-metadata album="$album")
        fi
        
        if ffmpeg -y -i "$file" -i "$image" -map 0:a -map 1:v -c:a copy -c:v copy "${metadata_args[@]}" -metadata:s:v title="Album cover" -metadata:s:v comment="Cover (front)" -disposition:v attached_pic "$temp" 2>/dev/null; then
          mv "$temp" "$file"
          echo "✓ Added artwork to: $file"
        else
          echo "✗ Failed: $file"
          rm -f "$temp"
        fi
        ;;
      mp3)
        # Use eyeD3 for MP3 files
        local eyed3_args=(--add-image "$image:FRONT_COVER")
        if [ -n "$artist" ]; then
          eyed3_args+=(--artist "$artist")
        fi
        if [ -n "$album" ]; then
          eyed3_args+=(--album "$album")
        fi
        eyeD3 "${eyed3_args[@]}" "$file"
        ;;
      *)
        echo "Unsupported format: $file"
        ;;
    esac
  done
}

# Batch add album art to all albums in artist folder
# Run from artist directory: artistName/AlbumName/song.m4a
d3top() {
  setopt localoptions nullglob
  local artist="${PWD##*/}"
  echo "Artist: $artist"
  echo "Processing albums..."
  
  for album_dir in */; do
    # Skip if not a directory
    [ -d "$album_dir" ] || continue
    
    echo "\n📁 Album: ${album_dir%/}"
    
    # Look for cover.jpg specifically
    local cover="${album_dir}cover.jpg"
    if [ ! -f "$cover" ]; then
      echo "⚠️  No cover.jpg found, skipping album"
      continue
    fi
    
    echo "🎨 Cover: cover.jpg"
    
    # Find all audio files in album directory
    local found_files=()
    for file in "$album_dir"*.m4a "$album_dir"*.mp3; do
      [ -f "$file" ] && found_files+=("$file")
    done
    
    if [ ${#found_files[@]} -eq 0 ]; then
      echo "⚠️  No audio files found"
      continue
    fi
    
    # Extract album name from directory
    local album_name="${album_dir%/}"
    
    # Process files with d3 function (passing artist and album)
    d3 "$cover" "${found_files[@]}" "$artist" "$album_name"
    echo "✓ Completed album: ${album_dir%/}"
  done
  
  echo "\n🎉 All albums processed!"
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

# Force standardize metadata in a directory based on majority values
# Useful for fixing albums with inconsistent metadata
d3force() {
  local dir="${1:-.}"
  
  if [ ! -d "$dir" ]; then
    echo "Error: Directory not found: $dir"
    return 1
  fi
  
  echo "🔍 Analyzing metadata in: $dir\n"
  
  # Arrays to store metadata from each file
  declare -A album_counts
  declare -A artist_counts
  declare -A albumartist_counts
  declare -A year_counts
  local -a files
  
  # Collect all audio files and their metadata
  for file in "$dir"/*.{m4a,mp3,mp4,m4v}(N); do
    [ -f "$file" ] || continue
    files+=("$file")
    
    local ext="${file##*.}"
    
    case "$ext" in
      m4a|mp4|m4v)
        # Use ffprobe for m4a/mp4 files
        local metadata=$(ffprobe -v quiet -show_format "$file" 2>/dev/null)
        local album=$(echo "$metadata" | grep "TAG:album=" | cut -d= -f2-)
        local artist=$(echo "$metadata" | grep "TAG:artist=" | cut -d= -f2-)
        local albumartist=$(echo "$metadata" | grep "TAG:album_artist=" | cut -d= -f2-)
        local year=$(echo "$metadata" | grep "TAG:date=" | cut -d= -f2- | cut -d- -f1)
        ;;
      mp3)
        # Use eyeD3 for mp3 files
        if command -v eyeD3 &>/dev/null; then
          local info=$(eyeD3 "$file" 2>/dev/null)
          local album=$(echo "$info" | grep "^album:" | sed 's/^album: //')
          local artist=$(echo "$info" | grep "^artist:" | sed 's/^artist: //')
          local albumartist=$(echo "$info" | grep "^album artist:" | sed 's/^album artist: //')
          local year=$(echo "$info" | grep "^recording date:" | sed 's/^recording date: //' | cut -d- -f1)
        fi
        ;;
    esac
    
    # Count occurrences
    [ -n "$album" ] && ((album_counts[$album]++))
    [ -n "$artist" ] && ((artist_counts[$artist]++))
    [ -n "$albumartist" ] && ((albumartist_counts[$albumartist]++))
    [ -n "$year" ] && ((year_counts[$year]++))
  done
  
  if [ ${#files[@]} -eq 0 ]; then
    echo "No audio files found in directory"
    return 1
  fi
  
  echo "Found ${#files[@]} audio files\n"
  
  # Find most common values
  local max_album="" max_album_count=0
  for key val in ${(kv)album_counts}; do
    if (( val > max_album_count )); then
      max_album="$key"
      max_album_count=$val
    fi
  done
  
  local max_artist="" max_artist_count=0
  for key val in ${(kv)artist_counts}; do
    if (( val > max_artist_count )); then
      max_artist="$key"
      max_artist_count=$val
    fi
  done
  
  local max_albumartist="" max_albumartist_count=0
  for key val in ${(kv)albumartist_counts}; do
    if (( val > max_albumartist_count )); then
      max_albumartist="$key"
      max_albumartist_count=$val
    fi
  done
  
  local max_year="" max_year_count=0
  for key val in ${(kv)year_counts}; do
    if (( val > max_year_count )); then
      max_year="$key"
      max_year_count=$val
    fi
  done
  
  # Display findings
  echo "📊 Most common metadata:"
  [ -n "$max_album" ] && echo "  Album: $max_album ($max_album_count/${#files[@]} files)"
  [ -n "$max_artist" ] && echo "  Artist: $max_artist ($max_artist_count/${#files[@]} files)"
  [ -n "$max_albumartist" ] && echo "  Album Artist: $max_albumartist ($max_albumartist_count/${#files[@]} files)"
  [ -n "$max_year" ] && echo "  Year: $max_year ($max_year_count/${#files[@]} files)"
  echo ""
  
  # Ask for confirmation
  echo -n "Apply these metadata values to all files? (y/N) "
  read -q REPLY
  echo ""
  
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    return 0
  fi
  
  echo "\n🔧 Updating files...\n"
  
  # Apply metadata to each file
  for file in "${files[@]}"; do
    local ext="${file##*.}"
    local needs_update=0
    
    echo "Processing: ${file##*/}"
    
    case "$ext" in
      m4a|mp4|m4v)
        # Use ffmpeg to update metadata
        local temp="${file%.*}.temp.${ext}"
        local metadata_args=()
        
        if [ -n "$max_album" ]; then
          metadata_args+=(-metadata album="$max_album")
        fi
        if [ -n "$max_artist" ]; then
          metadata_args+=(-metadata artist="$max_artist")
        fi
        if [ -n "$max_albumartist" ]; then
          metadata_args+=(-metadata album_artist="$max_albumartist")
        fi
        if [ -n "$max_year" ]; then
          metadata_args+=(-metadata date="$max_year")
        fi
        
        if [ ${#metadata_args[@]} -gt 0 ]; then
          if ffmpeg -i "$file" -map 0 -c copy "${metadata_args[@]}" "$temp" 2>/dev/null; then
            mv "$temp" "$file"
            echo "  ✓ Updated"
          else
            echo "  ✗ Failed"
            rm -f "$temp"
          fi
        fi
        ;;
      mp3)
        # Use eyeD3 for mp3 files
        if command -v eyeD3 &>/dev/null; then
          local eyed3_args=()
          
          if [ -n "$max_album" ]; then
            eyed3_args+=(--album "$max_album")
          fi
          if [ -n "$max_artist" ]; then
            eyed3_args+=(--artist "$max_artist")
          fi
          if [ -n "$max_albumartist" ]; then
            eyed3_args+=(--album-artist "$max_albumartist")
          fi
          if [ -n "$max_year" ]; then
            eyed3_args+=(--release-year "$max_year")
          fi
          
          if [ ${#eyed3_args[@]} -gt 0 ]; then
            if eyeD3 "${eyed3_args[@]}" "$file" &>/dev/null; then
              echo "  ✓ Updated"
            else
              echo "  ✗ Failed"
            fi
          fi
        fi
        ;;
    esac
  done
  
  echo "\n✅ Metadata standardization complete!"
}
