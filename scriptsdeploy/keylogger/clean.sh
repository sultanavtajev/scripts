#!/bin/bash
# Cleans up data in access.log by only keeping username and keypress
# Saves data in clean.txt

# Input file
input_file="access.log"

# Output file
output_file="clean.txt"

# Remove data before "?" and remove all data after and including "HTTP"
awk -F'\\?' '{print $2}' "$input_file" | awk '{sub(/ HTTP.*/, ""); print}' > "$output_file"

echo "Cleaned data saved to $output_file"
