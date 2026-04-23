**Note: This documentation is intended for CUBE3 internal use only.**

Managing integrations connected to the CUBE3 protocol involves observing lifecycle events emitted by both the integration and the protocol. We'll use the a proof-of-concept dApp to demonstrate the deployment, registration, and management of newly created integrations.

The following demo showcases an ERC20 token factory using the minimal proxy pattern via [Openzeppelin's Clones Lib](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/Clones.sol).

The code for this dApp is available in the [repo](https://github.com/cube-web3/cube3-v2-demo). The dApp showcases the following:

- Deployment of integration contracts via a factory
- Programmatically adding the signing authority via the OZ Defender Relayer
- Generating the registrar signature on the back-end
- Registration of an integrations
- The full lifecycle of events emitted by the protocol:
  - `Cube3IntegrationDeployed`
  - `SigningAuthorityUpdated`
  - `IntegrationRegistrationStatusUpdated`
  - `IntegrationAdminTransferred`
  - `FunctionProtectionStatusUpdated`
  - `TokenDeployed` (Exclusive to the demo)
- Generation of the CUBE3 Payload
- Calling a protected function on the integration

Our POC has a [simple indexer](https://github.com/cube-web3/cube3-v2-demo/blob/main/server/services/indexer.ts) that fetches logs on an interval and sends updates the UI with the latest events. The indexer is a simple TS/Express NodeJS app that uses the ethers.js library to interact with the Sepolia testnet.

## Integration Deployment

In this example, we're using an ERC20 Token Factory. The Factory allows the user to deploy a minimal proxy contract. Every minimal proxy points to the same ERC20 implementation contract containing the logic.

In order to detect every newly deployed integration, we listen for the topic that matches the `Cube3IntegrationDeployed` event. We won't know the address of the integration contract until the contract is deployed, so we pass `null` as the contract address on the filter.

Event:

Defined in `protection-solidity/src/ProtectionBase.sol`

```solidity
/// @notice Emitted when this integration is deployed.
/// @param integrationAdmin The account designated as the account's admin account on the router.
/// This account can complete the integration registration and update function protection status.
/// @param enabledByDefault Whether the Integration is connected to the Protocol by default.
event Cube3IntegrationDeployed(
    address indexed integrationAdmin,
    bool enabledByDefault
);
```

Indexer Event Listener:

```typescript
// ./server/index.ts

indexer.on(cube3IntegrationInterface.getEventTopic('Cube3IntegrationDeployed'), null, async (log) => {
  console.log('[Cube3IntegrationDeployed]', log);
  const parsedLog = cube3IntegrationInterface.parseLog(log);

  sendEvent('event', { ...parsedLog, block: log.blockNumber });

  // store the integration details for posterity
  await db.addIntegration({
    contractAddress: log.address,
    integrationAdmin: parsedLog.args.integrationAdmin,
    enabledByDefault: parsedLog.args.enabledByDefault,
    txHash: log.transactionHash,
    blockNumber: log.blockNumber,
    protectedFunctions: {},
  });

  // Emulate a KMS by generating and storing a signing key
  const signer = kms.generateAndStoreNewKeyPair(log.address);

  // add the signer to the registry
  await kms.addSignerToRegistry(log.address, signer);

  if (!sseClient) return;

  sendEvent('tokenCreated', { token: log.address, signingAuthority: signer });
});
```

As you can see from the above snippet, when an integration deployment is detected, we store the integration details in a database and generate a new signing key for the integration via the KMS. We'll cover the signing authority in the next section.

A new feature of the V2 protocol allows an integration to disconnect itself from the protocol. This bypasses forwarding the transaction to the CUBE3 Router where the function protection is checked and the transaction is forwarded to the designated module (if protection for the function is enabled).

The Integration contract must set whether the connection to the protocol is established by default. When the integration is deployed, the `Cube3ProtocolConnectionUpdated` event will be emitted by the contract. Although the default value is emitted as the `enabledByDefault` topic in the `Cube3IntegrationDeployed`, the update event will be emitted on any subsequent changes to this connection status.

Event:

Defined in `protocol-core-solidity/src/common/ProtocolEvents.sol`.

```solidity
/// @notice Emitted when the connection to the CUBE3 protocol is updated.
/// @param connectionEstablished When True, means the connection to the Protocol is established
/// and transaction data will be forwarded to the router and function protection status will be checked.
event Cube3ProtocolConnectionUpdated(bool connectionEstablished);
```

### Setting the Signing Authority in the Registry

Once we know an integration has been deployed, we need to create a signing authority (public-private key pair) and add the keypair's EOA to the Registry contract. This takes places inside the `./server/services/kms.ts` file's `addSignerToRegistry`. In this demo, we're using an Openzeppelin Defender relayer (managed account) that's been assigned the `CUBE3_KEY_MANAGER_ROLE`. This could just as easily be done by submitting a transaction onchain using an EOA with the same role.

We make use of the [Openzeppelin Defender SDK - @openzeppelin/defender-sdk](@openzeppelin/defender-sdk) to interact with the relayer. This is just a wrapper around the HTTP/S requests.

```typescript
import { Defender } from "@openzeppelin/defender-sdk";

// The Key Manager Relayer is an EOA managed by OZ defender that is used to relay transactions. It's
// accessed via the Defender SDK and avoids the need for managing the private key.
const keyManagerRelayer = new Defender({
    relayerApiKey: process.env.KEY_MANAGER_RELAYER_API_KEY,
    relayerApiSecret: process.env.KEY_MANAGER_RELAYER_SECRET,
});

// ./server/services/kms.ts

async addSignerToRegistry(integrationContract: string, signer: string) {
    const registryInterface = new ethers.utils.Interface(cubeRegistryABI);

    const data = registryInterface.encodeFunctionData("setClientSigningAuthority", [integrationContract, signer]);
    try {
        const tx = await keyManagerRelayer.relaySigner.sendTransaction({
            to: registryContract,
            value: 0,
            data,
            gasLimit: 100_000,
            speed: "fast",
        });
        console.log(`Added Integration signing authority (${signer}) to Registry: Transaction Hash: ${tx.hash}`);
    } catch (err) {
        console.error(err);
    }
}
```

Upon completion of the transaction, the `Cube3Registry` contract will emit the `SigningAuthorityUpdated` event, indicating that the Signing Authority has been set. This is required for both registration and the checking of payloads.

Event:

Defined in `protocol-core-solidity/src/common/ProtocolEvents.sol`.

```solidity
/// @notice Emitted when a new signing authority is set.
/// @param integration The integration contract's address.
/// @param signer The signing authority's account address.
event SigningAuthorityUpdated(address indexed integration, address indexed signer);
```

Indexer Event Listener:

```typescript
// ./server/index.ts

// Emitted by the CUBE3 registry when an integration's Signing Authority is Updated
indexer.on(cube3RegistryInterface.getEventTopic('SigningAuthorityUpdated'), registryContract, async (log) => {
  console.log('[SigningAuthorityUpdated]', log);
  const parsedLog = cube3RegistryInterface.parseLog(log);
  db.addSigningAuthorityForIntegration(parsedLog.args.integration, parsedLog.args.signer);
  sendEvent('event', { ...parsedLog, block: log.blockNumber });
});
```

### Registering an Integration

Before an Integration can start making using of the Protocol's Security Modules, it needs to complete the registration process. In order to complete the registration, the Integration's Admin must request a Registrar Signature from the API, which is then submitted as part of the registration transaction.

The POC's front-end sends a request to the `/api/v1/registration` endpoint, passing the integration's address as a query param. Next, the API's `generateRegistrarSignature` generates the `signature`, and provides the `securityAdmin` account, which are returned to the front-end.

```typescript
// ./server/services/cubeApi.ts

async generateRegistrarSignature(
    integrationAddress: string
): Promise<{ signature: string; securityAdmin: string }> {
    const routerContract = new ethers.Contract(routerProxyContract, cube3RouterABI, this.provider);
    const chainId = await this.provider.getNetwork().then((network) => network.chainId);

    const securityAdmin = await routerContract.getIntegrationAdmin(integrationAddress);

    const signature = await generateRegistrarSignature(
        this.provider,
        kms.getSignerForContract(integrationAddress)?.privateKey,
        integrationAddress,
        securityAdmin,
        chainId
    );

    return { signature, securityAdmin };
}
```

The API fetches the `securityAdmin` account for the Integration directly from the `Cube3Router` contract, which is then included in the registrar signature, which can be validate on-chain.

The `typescript` version of the `generateRegistarSignature` is presented below, which we'll compare to the `solidity` version that follows.

The steps to creating the signature are as follows:

- created a `keccak256` hash of the packed (ie no zero padding) ABI encoded signature args, which comprise:
  - The Integration's contract address
  - The Integration's admin account
  - The chain ID
- Prepend the data with the Ethereum's personal sign prefix: `"\x19Ethereum Signed Message:\n"`
- Use the Signing Authority's private key to sign it.

```typescript
// typescript

// ./server/services/cubeApi.ts
****
export const generateRegistrarSignature = async (
  provider: ethers.providers.JsonRpcProvider,
  signingAuthorityPvtKey: string,
  integrationAddress: string,
  integrationSecurityAdmin: string,
  chainId: number
): Promise<string> => {
  const argsArray = [integrationAddress, integrationSecurityAdmin, chainId];
  const wallet = new ethers.Wallet(signingAuthorityPvtKey, provider);
  const args = ethers.utils.solidityPack(['address', 'address', 'uint256'], argsArray);
  const argsBytes = ethers.utils.arrayify(args);
  const signingHash = ethers.utils.keccak256(argsBytes);
  const signingData = ethers.utils.arrayify(signingHash);
  const signature = await wallet.signMessage(signingData);
  return signature;
};
```

In the typescript version above, we need to do some manualy work to convert the digest to raw bytes before hashing it, converting to bytes again, then using the Ethers wallet's `signMessage` function, which takes care of prepending the personal sign message.

The solidity version is more succint, using Foundry's `vm.sign` to prepend the personal sign message and create the signature.

```solidity

bytes memory registrarSignature = signPayloadData(
    abi.encodePacked(integration, admin, block.chainid),
    pvtKey
);

// ...

function signPayloadData(
    bytes memory encodedSignatureData,
    uint256 pvtKeyToSignWith
) internal pure returns (bytes memory signature) {
    bytes32 signatureHash = keccak256(encodedSignatureData);
    bytes32 ethSignedHash = MessageHashUtils.toEthSignedMessageHash(signatureHash);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(pvtKeyToSignWith, ethSignedHash);

    signature = abi.encodePacked(r, s, v);
    require(signature.length == 65, "invalid signature length");

    address signedHashAddress = ECDSA.recover(ethSignedHash, signature);
    require(signedHashAddress == vm.addr(pvtKeyToSignWith), "signers dont match");
}
```

Once the signature is generated, it is returned to the front-end, where it's submitted on-chain by the Integration's security admin account.

```solidity
function registerIntegrationWithCube3(
    address integration,
    bytes calldata registrarSignature,
    bytes4[] calldata enabledByDefaultFnSelectors
) external onlyIntegrationAdmin(integration) whenNotPaused { ... }
```

The Integration admin can select which function selectors to enable by default by including them in the `enabledByDefaultFnSelectors` array.

Upon successful registration, the `IntegrationRegistrationStatusUpdated` event will be emitted by the `Cube3Router` contract.

Event:

defined in `protocol-core-solidity/src/common/ProtocolEvents.sol`

```solidity
/// @notice Emitted when the registration status of an integration is updated.
/// @dev Provides an audit trail for changes in the registration status of integrations, enhancing the protocol's
/// governance transparency.
/// @param integration The address of the integration contract.
/// @param status The new registration status, represented as an enum.
event IntegrationRegistrationStatusUpdated(address indexed integration, Structs.RegistrationStatusEnum status);
```

Where the `RegistrationStatusEnum` is defined as:

defined in `protocol-core-solidity/src/common/Structs.sol`

```solidity
/// @notice  Defines the status of the integration and its relationship with the CUBE3 Protocol.
///
/// Notes:
/// - Defines the integration's level of access to the Protocol.
/// - An integration can only attain the REGISTERED status receiving a registration signature from the CUBE3
/// service off-chain.
///
/// @param UNREGISTERED The integration technically does not exist as it has not been pre-registered with the
/// protocol.
/// @param PENDING The integration has been pre-registered with the protocol, but has not completed registration.
/// @param REGISTERED The integration has completed registration with the protocol using the signature provided by
/// the off-chain CUBE3 service and is permissioned to update the protection status of functions.
/// @param REVOKED The integration no longer has the ability to enable function protection.
enum RegistrationStatusEnum {
    UNREGISTERED,
    PENDING,
    REGISTERED,
    REVOKED
}
```

An account with the `CUBE3_PROTOCOL_ADMIN_ROLE` role can revoke an integration's registration, preventing it from making use of the security modules. This will emit the `IntegrationRegistrationStatusUpdated` event with the `RegistrationStatusEnum` value of `REVOKED`.

### Disconnecting an Integration from the Protocol

An Integration's admin has the choice, at any time, to discontinue use of the Protocol by disconnecting the integration from the `Cube3Router` contract. Note, this functionality must be explicitly implemented in the Integration contract by calling the `internal` function `_updateShouldUseProtocol()` defined in `protection-solidity/src/ProtectionBase.sol`.

```solidity
/// @notice Determines whether a call should be made to the CUBE3 Protocol to check the protection status of
/// of function of the top-level call.
/// @dev WARNING: This MUST only be called within an external/public with some form of access control.
/// If the derived contract has no access control, this function should not be exposed and the connection
/// to the protocol is locked at the time of deployment.
function _updateShouldUseProtocol(bool connectToProtocol) internal {
    _cube3Storage().shouldCheckFnProtection = connectToProtocol;
    emit Cube3ProtocolConnectionUpdated(connectToProtocol);
}
```

As previously mentioned, this emits the `Cube3ProtocolConnectionUpdated` event from the Integration contract.

### Transferring the Integration's Admin account

This feature is not yet demonstrated in the POC, but is worth mentioning.

The Integration Admin account has privileged access to the Router insofar as it's able to make changes relating to the Integration contract it is administering. Transferring these privileges is a two-step process. The admin can call `transferIntegrationAdmin(...)` on the router, nominating a new admin account. The transfer is only completed when this nominated account calls `acceptIntegrationAdmin(...)`. Upon completion of this account change, the `IntegrationAdminTransferred` event will be emitted by the `Cube3Router`.

Event

defined in `protocol-core-solidity/src/common/ProtocolEvents.sol`

```solidity
/// @notice Emitted when the admin transfer for an integration is completed.
/// @param integration The address of the integration.
/// @param oldAdmin The previous admin address before the transfer.
/// @param newAdmin The new admin address after the transfer.
event IntegrationAdminTransferred(address indexed integration, address indexed oldAdmin, address indexed newAdmin);
```

It's worth noting that this event is emitted by the Integration contract upon deployment, as the Admin account is transferred from the zero address to the initial admin.
