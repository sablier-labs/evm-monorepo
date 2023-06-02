#!/usr/bin/env bash

# Notes:
# - There are four input arguments: progress, status, streamed amount, and duration

# Pre-requisites:
# - foundry (https://getfoundry.sh)

# Strict mode: https://gist.github.com/vncsna/64825d5609c146e80de8b1fd623011ca
set -euo pipefail

# Load the arguments while using default values
arg_progress=${1:-4235}
arg_status=${2:-"Streaming"}
arg_streamed=${3:-"1.23M"}
arg_duration=${4:-"91"}

# Run the Forge script and extract the SVG from stdout
output=$(
  forge script script/GenerateSVG.s.sol \
  --sig "run(uint256,string,string,uint256)" \
  "$arg_progress" \
  "$arg_status" \
  "$arg_streamed" \
  "$arg_duration"
)
svg=$(echo "$output" | awk -F "svg: string " '{print $2}' | awk 'NF > 0')

# Generate the file name
name="nft-${arg_progress}-${arg_status}-${arg_streamed}-${arg_duration}.svg"
sanitized="$(echo "$name" | sed "s/ //g" )" # remove whitespaces

# Put the SVG in a file
mkdir -p "out-svg"
echo $svg > "out-svg/$sanitized"
