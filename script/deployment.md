# Deployment

## Configuration

Before deployment needs to fill `deploymentConfig.json` file with addresses

```json
{
  "chainId:" "0x00000000000000000000000000000000",
  "childERC20Predicate:" "0x00000000000000000000000000000000",
  "childERC721Predicate:" "0x00000000000000000000000000000000",
  "childERC1155Predicate:" "0x00000000000000000000000000000000",
  "childTokenTemplate:" "0x00000000000000000000000000000000",
  "nativeTokenRoot:" "0x00000000000000000000000000000000"
}
```

## Running

Command to run deployment:

```bash
npx hardhat run ./script/deployment.ts
```
