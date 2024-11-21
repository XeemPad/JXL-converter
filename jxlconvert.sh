#!/bin/bash
# 2024-11-21 23:39


# Default options
LOSSLESS_MODE=1 # Default to lossless
OUTPUT_DIR="./jxl-converted"
NUM_THREADS=$(nproc)  # Automatically detect the number of CPU cores
EFFORT=7  # Default effort level (1 = fastest, 10 = highest effort)

# Temporary file to store success and failure results
TEMP_FILE=$(mktemp)

# Parse flags
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --lossy) 
            LOSSLESS_MODE=0
            echo "Lossy mode enabled."
            ;;
        -e)  # Set effort level for lossy compression (1-10)
            shift
            if [[ "$1" -ge 1 && "$1" -le 10 ]]; then
                EFFORT="$1"
                echo "Using effort level: $EFFORT"
            else
                echo "Error: Effort must be between 1 and 10."
                exit 1
            fi
            ;;
        -t)  # Set number of threads
            shift
            NUM_THREADS="$1"
            echo "Using $NUM_THREADS threads."
            ;;
        *)
            echo "Unknown argument: $1"
            exit 1
            ;;
    esac
    shift
done

# Create the output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Supported file extensions for conversion (adjust as needed)
# SUCKS AT LEAST AT JPEG
SUPPORTED_EXTENSIONS="jpg jpeg png bmp gif webp tiff"

# Function to convert a single file
convert_to_jxl() {
    local input_file="$1"
    local output_file="$OUTPUT_DIR/$(basename "${input_file%.*}.jxl")"

    if [[ $LOSSLESS_MODE -eq 0 ]]; then
        echo "Converting (lossy): $input_file -> $output_file with effort $EFFORT"
        cjxl "$input_file" "$output_file" --lossless_jpeg=$LOSSLESS_MODE --effort=$EFFORT --num_threads=$NUM_THREADS --quiet
    else
        echo "Converting (lossless): $input_file -> $output_file with effort $EFFORT"
        cjxl "$input_file" "$output_file" --lossless_jpeg=$LOSSLESS_MODE --effort=$EFFORT --num_threads=$NUM_THREADS --quiet
    fi

    if [[ $? -eq 0 ]]; then
        echo -e "\e[32mSuccessfully converted: $input_file\e[0m" # Green for success
        echo "success" >> "$TEMP_FILE"  # Write success to the temporary file
    else
        echo -e "\e[31mFailed to convert: $input_file\e[0m" # Red for errors
        echo "failure" >> "$TEMP_FILE"  # Write failure to the temporary file
    fi
}

# Iterate over supported file types
for ext in $SUPPORTED_EXTENSIONS; do
    for file in *."$ext" *."${ext^^}"; do  # Match both lowercase and uppercase extensions
        [ -e "$file" ] || continue # Skip if no files are found
        convert_to_jxl "$file" &
    done
done

# Wait for all background processes to finish
wait

# Final report: count the number of successes and failures
SUCCESS_COUNT=$(grep -c "success" "$TEMP_FILE")
FAILURE_COUNT=$(grep -c "failure" "$TEMP_FILE")

# Remove the temporary file
rm "$TEMP_FILE"

echo "Conversion completed. Output saved to: $OUTPUT_DIR"
echo "Total successful conversions: $SUCCESS_COUNT"
echo "Total failed conversions: $FAILURE_COUNT"

