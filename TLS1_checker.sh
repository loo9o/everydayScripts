#!/bin/bash

# ANSI color codes
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
BLUE="\033[34m"
RESET="\033[0m"

# Function to display usage information
usage() {
    echo -e "${BLUE}Usage:${RESET} $0 [url] [-i <input_file>] [-o <output_file_offered>] [-n <output_file_not_offered>]"
    echo -e "  - If a ${YELLOW}URL${RESET} is provided directly, it is analyzed. Otherwise, use ${YELLOW}-i${RESET} with an input file."
    echo -e "  - ${YELLOW}-o${RESET} <${GREEN}output_file_offered${RESET}>: Save URLs where TLS 1 or TLS 1.1 is 'offered (deprecated)'."
    echo -e "  - ${YELLOW}-n${RESET} <${GREEN}output_file_not_offered${RESET}>: Save URLs where TLS 1 and TLS 1.1 are 'not offered'."
    echo -e "  Note: This script requires 'testssl.sh'. Install it from https://testssl.sh/."
    echo -e "  To install, download, extract, and add it to your ${YELLOW}PATH${RESET}."
    exit 1
}

# Determine if testssl.sh or testssl is installed
testssl_command=""
if command -v testssl.sh &> /dev/null; then
    testssl_command="testssl.sh"
elif command -v testssl &> /dev/null; then
    testssl_command="testssl"
else
    echo -e "${RED}Error:${RESET} 'testssl.sh' or 'testssl' is not installed."
    echo -e "Install it from https://testssl.sh/. Download, extract, and add it to your PATH."
    exit 1
fi

# Variables to store command-line arguments
input_file=""
output_file_offered=""
output_file_not_offered=""
single_url=""

# Parse command-line arguments
while getopts ":i:o:n:" opt; do
    case $opt in
        i) input_file="$OPTARG";;
        o) output_file_offered="$OPTARG";;
        n) output_file_not_offered="$OPTARG";;
        \?) echo -e "${RED}Invalid option: -$OPTARG${RESET}" >&2; usage;;
        :) echo -e "${RED}Option -$OPTARG requires an argument.${RESET}" >&2; usage;;
    esac
done

# Determine if a single URL was provided without other options
if [ $((OPTIND - 1)) -lt $# ]; then
    single_url="${@:OPTIND}"
fi

# Check that either an input file or a single URL was provided
if [ -z "$input_file" ] && [ -z "$single_url" ]; then
    usage
fi

# Function to analyze a URL
analyze_url() {
    local url="$1"
    echo -e "${BLUE}Analyzing $url...${RESET}"

    # Execute the correct testssl command and capture the output
    output=$( $testssl_command -p "$url" )

    # Remove ANSI color codes from the output
    clean_output=$(echo "$output" | sed 's/\x1B\[[0-9;]*[JKmsu]//g')

    # Check if TLS 1 or TLS 1.1 is offered (including deprecated)
    if echo "$clean_output" | grep -q -E "TLS 1(\s+)offered \(deprecated\)|TLS 1\.1(\s+)offered \(deprecated\)"; then
        echo -e "${RED}TLS 1 or TLS 1.1 offered (deprecated) at $url.${RESET}"
        if [ -n "$output_file_offered" ]; then
            echo "$url" >> "$output_file_offered"
            echo -e "${BLUE}Added to '$output_file_offered'.${RESET}"
        fi
    else
        echo -e "${GREEN}TLS 1 and TLS 1.1 not offered at $url.${RESET}"
        if [ -n "$output_file_not_offered" ]; then
            echo "$url" >> "$output_file_not_offered"
            echo -e "${BLUE}Added to '$output_file_not_offered'.${RESET}"
        fi
    fi
}

# Analyze either the single URL or the input file
if [ -n "$single_url" ]; then
    analyze_url "$single_url"
else
    # Check that the input file exists
    if [ ! -f "$input_file" ]; then
        echo -e "${RED}Error:${RESET} The input file '$input_file' does not exist."
        exit 1
    fi
    # Read each URL from the input file
    while IFS= read -r url; do
        analyze_url "$url"
    done < "$input_file"
fi

echo "Process complete."