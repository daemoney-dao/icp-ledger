#!/bin/bash

# Set default identities and flags
minter_identity="icp-minter"
default_identity=$(dfx identity whoami)
force_download=false

usage() {
    echo "Usage: $(basename "$0") [OPTIONS]"
    echo ""
    echo "This script performs the following actions:"
    echo "1. Downloads the latest ICP ledger and index artifacts if the ./icp-ledger-wasm folder is empty or if forced by the --download argument."
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

# Download the latest ICP ledger and index artifacts if forced or if the directory is empty
if [ "$force_download" = true ] || [ -z "$(ls -A ./icp-ledger-wasm 2>/dev/null)" ]; then
    echo "Downloading the latest ICP ledger and index artifacts..."
    cd ./icp-ledger-wasm || { echo "Directory icp-ledger-wasm not found"; exit 1; }
    
    # Fetch list of recent commits from dfinity/ic (up to 100)
    COMMITS=$(curl -sLf -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "https://api.github.com/repos/dfinity/ic/commits?per_page=100" \
        | jq '.[].sha' | tr -d \")
    if [ "$?" -ne "0" ]; then
         echo >&2 "Unable to fetch the commits from dfinity/ic for ledger artifact. Please try again."
         exit 1
    fi

    # --- Download ledger artifacts ---
    for COMMIT in $COMMITS; do
         STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" -L --head \
            "https://download.dfinity.systems/ic/$COMMIT/canisters/ledger-canister_notify-method.wasm.gz")
         if (($STATUS_CODE >= 200)) && (($STATUS_CODE < 300)); then
              echo "Found ledger artifacts for commit $COMMIT. Downloading icp_ledger.did and icp_ledger.wasm.gz"
              curl -sLf "https://raw.githubusercontent.com/dfinity/ic/$COMMIT/rs/ledger_suite/icrc1/ledger/ledger.did" -o icp_ledger.did
              if [ "$?" -ne "0" ]; then
                   echo >&2 "Unable to download the ledger did file. Please try again."
                   exit 2
              fi
              curl -sLf "https://download.dfinity.systems/ic/$COMMIT/canisters/ledger-canister_notify-method.wasm.gz" -o icp_ledger.wasm.gz
              if [ "$?" -ne "0" ]; then
                   echo >&2 "Unable to download the ledger wasm file. Please try again."
                   exit 3
              fi
              break
         fi
    done
    if [ ! -f icp_ledger.did ] || [ ! -f icp_ledger.wasm.gz ]; then
         echo "No ledger commit with artifacts found"
         exit 4
    fi

    # --- Download index artifacts ---
    for COMMIT in $COMMITS; do
         STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" -L --head \
            "https://download.dfinity.systems/ic/$COMMIT/canisters/ic-icp-index-canister.wasm.gz")
         if (($STATUS_CODE >= 200)) && (($STATUS_CODE < 300)); then
              echo "Found index artifacts for commit $COMMIT. Downloading index.did and index.wasm.gz"
              curl -sLf "https://raw.githubusercontent.com/dfinity/ic/$COMMIT/rs/ledger_suite/icp/index/index.did" -o index.did
              if [ "$?" -ne "0" ]; then
                   echo >&2 "Unable to download the index did file. Please try again."
                   exit 5
              fi
              curl -sLf "https://download.dfinity.systems/ic/$COMMIT/canisters/ic-icp-index-canister.wasm.gz" -o index.wasm.gz
              if [ "$?" -ne "0" ]; then
                   echo >&2 "Unable to download the index wasm file. Please try again."
                   exit 6
              fi
              break
         fi
    done
    if [ ! -f index.did ] || [ ! -f index.wasm.gz ]; then
         echo "No index commit with artifacts found"
         exit 7
    fi
    
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
cp ./dfx.json ./dfx.json.bak
cp ./dfx.json.template ./dfx.json

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
echo "Deploying the ICP ledger canister..."
dfx deploy --specified-id ryjl3-tyaaa-aaaaa-aaaba-cai icp_ledger_canister

# Create, build and deploy the ICP index canister
echo "Deploying the ICP index canister..."
dfx deploy icp_index_canister --specified-id qhbym-qaaaa-aaaaa-aaafq-cai --argument '(record {ledger_id = principal "ryjl3-tyaaa-aaaaa-aaaba-cai"})'


