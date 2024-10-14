#!/bin/bash

# Define source and destination directories
SOURCE_DIR="."
DEST_DIR="./out"

# Create destination directory if it doesn't exist
mkdir -p "$DEST_DIR"

# Define the target aspect ratio and tolerance
TARGET_RATIO=1.77778  	# 16:9 aspect ratio
TOLERANCE=0.01        	# Allowable tolerance for aspect ratio

# Loop through image files in the source directory
for img in "$SOURCE_DIR"/*.{jpg,jpeg,png,gif}; do
    # Check if the file exists to avoid errors
    if [[ -e $img ]]; then
        # Get the image dimensions using ImageMagick's identify
        dimensions=$(identify -format "%w %h" "$img")
        width=$(echo $dimensions | cut -d ' ' -f 1)
        height=$(echo $dimensions | cut -d ' ' -f 2)

        # Calculate the aspect ratio
        ratio=$(echo "scale=5; $width / $height" | bc -l)

        # Check if the ratio is outside the allowed range
        lower_bound=$(echo "$TARGET_RATIO - $TOLERANCE" | bc -l)
        upper_bound=$(echo "$TARGET_RATIO + $TOLERANCE" | bc -l)

        if (( $(echo "$ratio < $lower_bound" | bc -l) )) || (( $(echo "$ratio > $upper_bound" | bc -l) )); then
            echo "Moving '$img' to '$DEST_DIR'"
            mv "$img" "$DEST_DIR"
        fi
    fi
done

echo "All non-16:9 images have been moved."
