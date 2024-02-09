# BitmapUtils
[Git Source](https://github.com/cube-web3/protocol-core-solidity/blob/07ba602bddefe3eb8d740b07000837f7ec2fa9f5/src/libs/BitmapUtils.sol)


## Functions
### extractBytes16Bitmap




```solidity
function extractBytes16Bitmap(uint256 bitmap) internal pure returns (bytes16 moduleId);
```

### extractUint32FromBitmap


```solidity
function extractUint32FromBitmap(uint256 bitmap, uint8 location) internal pure returns (uint32 value);
```

### extractBytes4FromBitmap

Extracts a bytes4 from the bitmap at the specified location, converting to bytes4 from
uint32 by shifting left to the most significant bits.


```solidity
function extractBytes4FromBitmap(uint256 bitmap, uint8 location) internal pure returns (bytes4 value);
```

