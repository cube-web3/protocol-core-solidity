# Resonance Audit Mitigations

## RSP01

Added the `whenNotPaused` modifier, and added the modifier to all customer-facing functions. A customer cannot change any storage data relating to their integration while the protocol is paused.

## RSP02

At this time, having one integration access the protocol via another is not deemed a security risk, albeit a violation of CUBE3's terms. Registering an integration's functions with the protocol does not mitigate this issue, as the colluding (registered) integration can construct the `msgData` passed into `routeToModule` and add any 4 byte selector to the front of the byte data. Because of this, should they wish, the colluding integration could simply register this new function signature with the protocol and enable/disable protection as they see fit. ERC165 is easily spoofed as a method of validation and adds additional gas to the call. Should additional modules be added in the future that do not require the validation of `msg.sender`, this approach can be revisited and a change made through a protocol upgrade.

## RSP03

Setting Pragma to 0.8.23; for protocol contracts. Protection contracts retain floating pragma for compatibility.

## RSP04

The custom pause functionality is implemented with gas efficiency in mind by using a single storage slot to store the pause status along with the registry, reducing `SLOADS` and warming the storage slot for future use in the transaction lifecycle. The pause functionality implementation avoids complexity and is acceptable should the audit not find any security issues with the implementation.

## RSP05

Acknowledged. The protocol contracts are all deployed by the CUBE3 team and off-chain validation, as well as fork tests, will be used to validate addresses. Should an incorrect contract be deployed, it can simply be updated via mechanisms available in the protocol.

As far as `ProtectionBase.sol`, adding ERC165Checker adds an external dependency and increases contract size, both of which are undesirable. The user of `supportsInterface` would ensure that the contract address passed as `router` is the correct address pointing to the CUBE3 Router. This functionality is achieved by the new `_assertPreRegistrationSucceeds` function used in `_baseInitProtection()`.

## RSP06

Redundant zero-address check removed.
