# Blade

##### Contracts providing functionality on the blade chain

This directory contains contracts meant for usage on the blade chain. A brief overview of what the contracts do and how they work is provided here. For more granular documentation, there is extensive natspec on the contracts, along with markdown docs automatically generated from the natspec in the [`docs/`](../../docs/) directory at the project root.

## Token Contracts

`NativeERC20` and `NativeMintableERC20` represent assets which are an ERC20 on the external chain, but used as the native asset (for the payment of gas) on the blade chain. The `NativeMintableERC20` allows for more of the asset to be minted on the child chain directly.

## System

A contract template adding various blade-specific addresses, for example, to determine if a call is sent from a client (validator) as a protocol-specific tx (such as bridging data). Precompile addresses are also defined here.

## `validator/`

There is an additional subdirectory with contracts directly relating to block validation, a separate README in that directory describes the contracts there.
