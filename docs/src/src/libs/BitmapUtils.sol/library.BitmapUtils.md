# BitmapUtils
[Git Source](https://github.com/cube-web3/protocol-core-solidity/blob/c95be0ef92f4c69dc0af4db320cb041b877ea57c/src/libs/BitmapUtils.sol)

Library containing utilities to extract values packed into a uint256 Bitmap.


## Functions
### extractBytes16Bitmap

Extracts a bytes16 from the right-most (least significant) 128 bits.


```solidity
function extractBytes16Bitmap(uint256 bitmap) internal pure returns (bytes16 moduleId);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`bitmap`|`uint256`|The bitmap to extract the bytes16 from|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`moduleId`|`bytes16`|The Module ID retrieved from the bitmap.|


### extractUint32FromBitmap

Extracts a uint32 from the bitmap.


```solidity
function extractUint32FromBitmap(uint256 bitmap, uint8 location) internal pure returns (uint32 value);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`bitmap`|`uint256`|The bitmap to extract the uint32 from|
|`location`|`uint8`|The offset from the least-significant bit.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`value`|`uint32`|The uint32 value extracted from the bitmap.|


### extractBytes4FromBitmap

Extracts a bytes4 from the bitmap at the specified location.

*Converting to bytes4 from uint32 by shifting left to the most significant bit.*


```solidity
function extractBytes4FromBitmap(uint256 bitmap, uint8 location) internal pure returns (bytes4 value);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`bitmap`|`uint256`|The bitmap to extract the bytes4 from.|
|`location`|`uint8`|The offset from the least-significant bit.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`value`|`bytes4`|The bytes4 value extracted from the bitmap.|


