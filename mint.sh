#!/bin/bash
set -e

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  echo "Usage: $0 <ICP amount> [override_account_id]"
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
dfx identity use minter
echo "Switched to minter identity."

# Execute the transfer command from minter to the destination account.
echo "Transferring $ICP_AMOUNT ICP to account id: $DEST_ACCOUNT_ID"
dfx ledger transfer --icp "$ICP_AMOUNT" --fee 0 --memo 1 "$DEST_ACCOUNT_ID"
echo "Transfer executed."

# Switch back to the original identity.
dfx identity use "$CURRENT_IDENTITY"
echo "Switched back to identity: $CURRENT_IDENTITY"
