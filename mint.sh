#!/bin/bash
set -e

# Ensure an argument is provided for the ICP amount.
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <ICP amount>"
  exit 1
fi

ICP_AMOUNT="$1"

# Record the current identity.
CURRENT_IDENTITY=$(dfx identity whoami)
echo "Current identity: $CURRENT_IDENTITY"

# Record the current identity's account id.
CURRENT_ACCOUNT_ID=$(dfx ledger account-id)
echo "Current account id: $CURRENT_ACCOUNT_ID"

# Switch to the minter identity.
dfx identity use minter
echo "Switched to minter identity."

# Execute the transfer command with the provided ICP amount.
echo "Transferring $ICP_AMOUNT ICP to account id: $CURRENT_ACCOUNT_ID"
dfx ledger transfer --icp "$ICP_AMOUNT" --fee 0 --memo 1 "$CURRENT_ACCOUNT_ID"
echo "Transfer executed."

# Switch back to the original identity.
dfx identity use "$CURRENT_IDENTITY"
echo "Switched back to identity: $CURRENT_IDENTITY"
