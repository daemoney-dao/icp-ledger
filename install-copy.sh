#!/bin/bash

# Set default identities and flags
minter_identity="minter"
default_identity="daemoney-local"
force_download=false

usage() {
    echo "Usage: $(basename "$0") [OPTIONS]"
    echo ""
    echo "This script performs the following actions:"
    echo "1. Downloads the latest ICP ledger wasm and did if the ./icp-ledger-wasm folder is empty or if forced by the --download argument."
    echo "2. Switches to the specified minter and default identities to retrieve their account IDs."
    echo "3. Backs up the original dfx.json and restores a template from dfx.json.template."
    echo "4. Replaces the placeholders MINTER_ACCOUNT_ID and DEFAULT_ACCOUNT_ID in dfx.json with the obtained account IDs."
    echo "5. Deploys the ICP ledger canister with a specified canister-id to match mainnet."
    echo ""
    echo "Ensure you have a dedicated minter identity configured."
    echo ""
    echo "Options:"
    echo "  --minter ID         Specify a different minter identity (default: 'minter')."
    echo "  --default ID        Specify a different default identity (default: 'daemoney-local')."
    echo "  --download          Force download of the latest ICP ledger even if the ./icp-ledger-wasm folder is not empty."
    echo "  --help              Display this help message and exit."
}

# Parse optional command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --minter)
            minter_identity="$2"
            shift 2
            ;;
        --default)
            default_identity="$2"
            shift 2
            ;;
        --download)
            force_download=true
            shift
            ;;
        --help)
            usage
            exit 1
            ;;
        *)
            echo "Unknown parameter passed: $1"
            exit 1
            ;;
    esac
done

# Download the latest ICP ledger wasm and did only if forced or directory is empty
if [ "$force_download" = true ] || [ -z "$(ls -A ./icp-ledger-wasm)" ]; then
    echo "Downloading the latest ICP ledger..."
    cd ./icp-ledger-wasm
    curl -o download_latest_icp_ledger.sh "https://raw.githubusercontent.com/dfinity/ic/aba60ffbc46acfc8990bf4d5685c1360bd7026b9/rs/rosetta-api/scripts/download_latest_icp_ledger.sh"
    chmod +x download_latest_icp_ledger.sh
    ./download_latest_icp_ledger.sh
    
    cd ..
else
    echo "Skipping download: ./icp-ledger-wasm is not empty and --download was not provided."
fi

# Function to strip trailing newline (if any)
trim_newline() {
  echo -n "$1"
}

# Switch to the specified minter identity and obtain its account ID
echo "Switching to '$minter_identity' identity..."
dfx identity use "$minter_identity"
minter_raw=$(dfx ledger account-id)
minter_account=$(trim_newline "$minter_raw")
echo "Minter account ID: ${minter_account}"

# Switch to the specified default identity and obtain its account ID
echo "Switching to '$default_identity' identity..."
dfx identity use "$default_identity"
default_raw=$(dfx ledger account-id)
default_account=$(trim_newline "$default_raw")
echo "Default account ID: ${default_account}"

# Backup the original dfx.json and restore from the template
cp dfx.json dfx.json.bak
cp dfx.json.template dfx.json

# Replace placeholders in dfx.json using sed.
if [[ "$OSTYPE" == "darwin"* ]]; then
  sed -i '' "s|MINTER_ACCOUNT_ID|${minter_account}|g" dfx.json
  sed -i '' "s|DEFAULT_ACCOUNT_ID|${default_account}|g" dfx.json
else
  sed -i "s|MINTER_ACCOUNT_ID|${minter_account}|g" dfx.json
  sed -i "s|DEFAULT_ACCOUNT_ID|${default_account}|g" dfx.json
fi

echo "dfx.json has been updated with the new account IDs."

# Create, build and deploy the ICP ledger canister
echo "Deploying the ICP ledger canister"
dfx deploy --specified-id ryjl3-tyaaa-aaaaa-aaaba-cai icp_ledger_canister
