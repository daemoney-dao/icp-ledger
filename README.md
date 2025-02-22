# `icp-ledger`

This is a shortcut to download, configure and install the ICP ledger on a local machine.

## Prerequisites

There must be an identity named 'icp-minter'. This will be configured as the ICP ledger minter identity.

The local replica must be running
```
dfx start --clean
```

## Using the project

### Installing the ICP ledger and index canisters

To install the latest versions of the ICP ledger and index canisters to the local replica run:

```
./install.sh
```

This script will:
1. Download the latest versions of the ICP ledger and index canisters
2. Modify dfx.json (from a template) to reference the icp-minter and default account ids
3. Create, build and deploy the ICP ledger and index canisters to the local replica

### Minting ICP

Use the mint script to mint ICP:
```
./mint.sh <ICP amount> [account-id]
```

By default, the minted ICP will be transferred to the identity used to run the script. This can be overridden by providing an account ID as the second argument.

