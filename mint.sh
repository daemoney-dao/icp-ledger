#!/bin/bash
set -e

# Set default identities and flags
MINTER_IDENTITY="icp-minter"

usage() {
  echo "Mints local ICP to the ledger account of the current identity, or to a specified account-id."
  echo ""
  echo "Usage: $0 <ICP amount> [account-id]"
  echo ""
  echo "Requires the account 'minter' to be configured as the ICP ledger minter."
}

# Check if --help is provided in any argument and display usage if so.
for arg in "$@"; do
  if [ "$arg" = "--help" ]; then
    usage
    exit 0
  fi
done

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  usage
  exit 1
fi

ICP_AMOUNT="$1"

# Record the current identity.
CURRENT_IDENTITY=$(dfx identity whoami)
echo "Current identity: $CURRENT_IDENTITY"

# Determine the destination account id.
if [ "$#" -eq 2 ]; then
  DEST_ACCOUNT_ID="$2"
  echo "Using override account id: $DEST_ACCOUNT_ID"
else
  DEST_ACCOUNT_ID=$(dfx ledger account-id)
  echo "Current account id: $DEST_ACCOUNT_ID"
fi

# Switch to the minter identity.
dfx identity use $MINTER_IDENTITY
echo "Switched to minter identity."

# Execute the transfer command from minter to the destination account.
echo "Transferring $ICP_AMOUNT ICP to account id: $DEST_ACCOUNT_ID"
dfx ledger transfer --icp "$ICP_AMOUNT" --fee 0 --memo 1 "$DEST_ACCOUNT_ID"
echo "Transfer executed."

# Switch back to the original identity.
dfx identity use "$CURRENT_IDENTITY"
echo "Switched back to identity: $CURRENT_IDENTITY"
