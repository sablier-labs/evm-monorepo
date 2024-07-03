#!/usr/bin/env bash

# Pre-requisites for running this script:
#
# - bun (https://bun.sh)
# - foundry (https://getfoundry.sh)

# Strict mode
set -euo pipefail

# Path to the Base Script
BASE_SCRIPT="script/Base.s.sol"

# Compile the contracts with the optimized profile
bun run build:optimized

# Generalized function to update counts
update_counts() {
    local test_name=$1
    local map_name=$2
    echo -e "\nRunning forge test for estimating $test_name..."
    local output=$(FOUNDRY_PROFILE=benchmark forge t --mt "test_Estimate${test_name}" -vv)
    echo -e "\nParsing output for $test_name..."

    # Define a table with headers. This table is not put in the Solidity script file,
    # but is used to be displayed in the terminal.
    local table="Category,Chain ID,New Max Count"

    # Parse the output to extract counts and chain IDs
    while IFS= read -r line; do
        local count=$(echo $line | awk '{print $2}')
        local chain_id=$(echo $line | awk '{print $8}')

        # Add the data to the table
        table+="\n$map_name,$chain_id,$count"

        # Update the map for each chain ID using sd
        sd "$map_name\[$chain_id\] = [0-9]+;" "$map_name[$chain_id] = $count;" $BASE_SCRIPT
    done < <(echo "$output" | grep 'count:')

    # Print the table using the column command
    echo -e $table | column -t -s ','
}

# Call the function with specific parameters for segments and tranches
update_counts "Segments" "segmentCountMap"
update_counts "Tranches" "trancheCountMap"

# Reformat the code with Forge
forge fmt $BASE_SCRIPT

printf "\n\nAll mappings updated."
