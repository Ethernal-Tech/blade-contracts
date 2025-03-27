# Blade

##### Contracts providing functionality on the blade chain

This directory contains contracts meant for usage on the blade chain. A brief overview of what the contracts do and how they work is provided here. For more granular documentation, there is extensive natspec on the contracts, along with markdown docs automatically generated from the natspec in the [`docs/`](../../docs/) directory at the project root.

## Token Contracts

The `ChildERC20`, `ChildERC721`, `ChildERC1155`, and `NativeERC20` contracts represent templates for the management of bridged assets on the blade chain. The latter two represent assets which are an ERC20 on the connected chain, but used as the native asset (for the payment of gas) on the blade chain. The `NativeERC20` allows for more of the asset to be minted on the child chain directly. The other contracts assume the supply is dictated by the connected chain asset, and cannot mint more of the asset directly. Work is already underway to add Mintable templates for ERC20/721/1155 tokens.

## System

A contract template adding various blade-specific addresses, for example, to determine if a call is sent from a client (validator) as a protocol-specific tx (such as bridging data). Precompile addresses are also defined here.

## `validator/`

There is an additional subdirectory with contracts directly relating to block validation, a separate README in that directory describes the contracts there.
