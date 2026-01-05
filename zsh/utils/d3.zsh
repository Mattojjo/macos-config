# ============================================
# CUSTOM FUNCTIONS
# ============================================

# Unified audio metadata and artwork management function
# Supports: album art embedding, metadata standardization, batch processing
#
# Usage:
#   d3 [options] <audio_file(s)>
#
# Options:
#   -all              Process all albums in current artist directory (batch mode)
#   -force            Force standardize metadata based on majority values
#   -image <path>     Specify cover art image file
#   -artist <name>    Specify artist name
#   -album <name>     Specify album name
#
# Examples:
#   d3 -image cover.jpg song.m4a                     # Add artwork to single file
#   d3 -image cover.jpg -artist "Lee" *.m4a          # Add artwork + artist
#   d3 -artist "Lee" -album "Album" -image cover.jpg song.mp3  # Any order!
#   d3 -all                                          # Batch process all albums
#   d3 -all -force                                   # Batch + force standardize
#   d3 -force                                        # Standardize current directory
#   d3 -force ./AlbumFolder                          # Standardize specific directory
#
d3() {
  # ============================================
  # ARGUMENT PARSING
  # ============================================
  local flag_all=false
  local flag_force=false
  local arg_image=""
  local arg_artist=""
  local arg_album=""
  local positional_args=()
  
  # Show usage if no arguments
  if [ $# -eq 0 ]; then
    echo "Usage: d3 [options] <audio_file(s)>"
    echo ""
    echo "Options:"
    echo "  -all              Process all albums in current artist directory (batch mode)"
    echo "  -force            Force standardize metadata based on majority values"
    echo "  -image <path>     Specify cover art image file"
    echo "  -artist <name>    Specify artist name"
    echo "  -album <name>     Specify album name"
    echo ""
    echo "Examples:"
    echo "  d3 -image cover.jpg song.m4a                     # Add artwork to single file"
    echo "  d3 -image cover.jpg -artist \"Lee\" *.m4a          # Add artwork + artist"
    echo "  d3 -artist \"Lee\" -album \"Album\" -image cover.jpg song.mp3  # Any order!"
    echo "  d3 -all                                          # Batch process all albums"
    echo "  d3 -all -force                                   # Batch + force standardize"
    echo "  d3 -force                                        # Standardize current directory"
    echo "  d3 -force ./AlbumFolder                          # Standardize specific directory"
    return 1
  fi
  
  # Parse arguments (options with values and positional)
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -all)    flag_all=true; shift ;;
      -force)  flag_force=true; shift ;;
      -image)
        if [[ -n "$2" && ! "$2" =~ ^- ]]; then
          arg_image="$2"; shift 2
        else
          echo "Error: -image requires a file path"; return 1
        fi
        ;;
      -artist)
        if [[ -n "$2" && ! "$2" =~ ^- ]]; then
          arg_artist="$2"; shift 2
        else
          echo "Error: -artist requires a name"; return 1
        fi
        ;;
      -album)
        if [[ -n "$2" && ! "$2" =~ ^- ]]; then
          arg_album="$2"; shift 2
        else
          echo "Error: -album requires a name"; return 1
        fi
        ;;
      -*)      echo "Unknown option: $1"; return 1 ;;
      *)       positional_args+=("$1"); shift ;;
    esac
  done
  
  # Determine what to process based on what was provided
  local do_image=false
  local do_artist=false
  local do_album=false
  
  [ -n "$arg_image" ] && do_image=true
  [ -n "$arg_artist" ] && do_artist=true
  [ -n "$arg_album" ] && do_album=true
  
  # ============================================
  # MODE: BATCH PROCESSING (-all flag)
  # ============================================
  if $flag_all && [ ${#positional_args[@]} -eq 0 ]; then
    setopt localoptions nullglob
    local current_artist="${PWD##*/}"
    echo "Artist: $current_artist"
    echo "Processing albums..."
    
    for album_dir in */; do
      # Skip if not a directory
      [ -d "$album_dir" ] || continue
      
      echo "\n📁 Album: ${album_dir%/}"
      
      # Run force standardization first if -force flag is set
      if $flag_force; then
        echo "🔧 Force standardizing metadata..."
        _d3_force_internal "${album_dir%/}" "true" "true"
      fi
      
      # Look for cover.jpg specifically
      local cover="${album_dir}cover.jpg"
      if [ ! -f "$cover" ]; then
        echo "⚠️  No cover.jpg found, skipping artwork"
        if ! $flag_force; then
          continue
        fi
      else
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
        
        # Process files with internal processing function (batch mode processes all)
        _d3_process_files "$cover" "true" "true" "true" "$current_artist" "$album_name" "${found_files[@]}"
      fi
      
      echo "✓ Completed album: ${album_dir%/}"
    done
    
    echo "\n🎉 All albums processed!"
    return 0
  fi
  
  # ============================================
  # MODE: FORCE STANDARDIZATION (-force flag only)
  # ============================================
  if $flag_force && ! $flag_all; then
    local dir="${positional_args[1]:-.}"
    _d3_force_internal "$dir" "$do_artist" "$do_album"
    return $?
  fi
  
  # ============================================
  # MODE: STANDARD PROCESSING (audio files with options)
  # ============================================
  if [ ${#positional_args[@]} -lt 1 ]; then
    echo "Error: No audio files specified"
    echo "Usage: d3 [options] <audio_file(s)>"
    return 1
  fi
  
  # All positional args are audio files now
  local files=("${positional_args[@]}")
  
  # Validate: need at least image or metadata to do something
  if ! $do_image && ! $do_artist && ! $do_album; then
    echo "Error: No operation specified. Use -image, -artist, or -album"
    echo "Usage: d3 [options] <audio_file(s)>"
    return 1
  fi
  
  # Process the files
  _d3_process_files "$arg_image" "$do_image" "$do_artist" "$do_album" "$arg_artist" "$arg_album" "${files[@]}"
}

# ============================================
# INTERNAL: Process audio files with artwork and metadata
# ============================================
_d3_process_files() {
  local image="$1"
  local do_image="$2"
  local do_artist="$3"
  local do_album="$4"
  local artist="$5"
  local album="$6"
  shift 6
  local files=("$@")
  
  for file in "${files[@]}"; do
    local ext="${file##*.}"
    case "$ext" in
      m4a|mp4|m4v)
        # Use ffmpeg for M4A/MP4 files
        local temp="${file%.*}.temp.${ext}"
        echo "Processing: $file"
        
        local metadata_args=()
        if [[ "$do_artist" == "true" ]] && [ -n "$artist" ]; then
          metadata_args+=(-metadata artist="$artist")
        fi
        if [[ "$do_album" == "true" ]] && [ -n "$album" ]; then
          metadata_args+=(-metadata album="$album")
        fi
        
        if [[ "$do_image" == "true" ]] && [ -f "$image" ]; then
          # With artwork
          if ffmpeg -y -i "$file" -i "$image" -map 0:a -map 1:v -c:a copy -c:v copy "${metadata_args[@]}" -metadata:s:v title="Album cover" -metadata:s:v comment="Cover (front)" -disposition:v attached_pic "$temp" 2>/dev/null; then
            mv "$temp" "$file"
            echo "✓ Added artwork to: $file"
          else
            echo "✗ Failed: $file"
            rm -f "$temp"
          fi
        elif [ ${#metadata_args[@]} -gt 0 ]; then
          # Metadata only (no artwork)
          if ffmpeg -y -i "$file" -map 0 -c copy "${metadata_args[@]}" "$temp" 2>/dev/null; then
            mv "$temp" "$file"
            echo "✓ Updated metadata: $file"
          else
            echo "✗ Failed: $file"
            rm -f "$temp"
          fi
        fi
        ;;
      mp3)
        # Use eyeD3 for MP3 files
        local eyed3_args=()
        if [[ "$do_image" == "true" ]] && [ -f "$image" ]; then
          eyed3_args+=(--add-image "$image:FRONT_COVER")
        fi
        if [[ "$do_artist" == "true" ]] && [ -n "$artist" ]; then
          eyed3_args+=(--artist "$artist")
        fi
        if [[ "$do_album" == "true" ]] && [ -n "$album" ]; then
          eyed3_args+=(--album "$album")
        fi
        if [ ${#eyed3_args[@]} -gt 0 ]; then
          eyeD3 "${eyed3_args[@]}" "$file"
        fi
        ;;
      *)
        echo "Unsupported format: $file"
        ;;
    esac
  done
}

# ============================================
# INTERNAL: Force standardize metadata based on majority values
# ============================================
_d3_force_internal() {
  local dir="${1:-.}"
  local do_artist="${2:-true}"
  local do_album="${3:-true}"
  
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
    
    echo "Processing: ${file##*/}"
    
    case "$ext" in
      m4a|mp4|m4v)
        # Use ffmpeg to update metadata
        local temp="${file%.*}.temp.${ext}"
        local metadata_args=()
        
        if [[ "$do_album" == "true" ]] && [ -n "$max_album" ]; then
          metadata_args+=(-metadata album="$max_album")
        fi
        if [[ "$do_artist" == "true" ]] && [ -n "$max_artist" ]; then
          metadata_args+=(-metadata artist="$max_artist")
        fi
        if [[ "$do_artist" == "true" ]] && [ -n "$max_albumartist" ]; then
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
          
          if [[ "$do_album" == "true" ]] && [ -n "$max_album" ]; then
            eyed3_args+=(--album "$max_album")
          fi
          if [[ "$do_artist" == "true" ]] && [ -n "$max_artist" ]; then
            eyed3_args+=(--artist "$max_artist")
          fi
          if [[ "$do_artist" == "true" ]] && [ -n "$max_albumartist" ]; then
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
