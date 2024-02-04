# CUBE3 Protocol Core [![Github Actions][gha-badge]][gha] [![Coverage][codecov-badge]][codecov] [![Foundry][foundry-badge]][foundry]

[gha]: https://github.com/sablier-labs/v2-core/actions
[gha-badge]: https://github.com/sablier-labs/v2-core/actions/workflows/ci.yml/badge.svg
[codecov]: https://codecov.io/gh/sablier-labs/v2-core
[codecov-badge]: https://codecov.io/gh/sablier-labs/v2-core/branch/main/graph/badge.svg
[foundry]: https://getfoundry.sh
[foundry-badge]: https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg

This repository contains the core smart contracts of the CUBE3 Protocol. For protection-specific contracts, see the [cube-web3/protection-solidity]() repository.

In-depth documentation is available at [docs.cube3.io](https://docs.cube3.io/).

## Overview

At its core the CUBE3 Protocol is a set of smart contracts that enable on-chain RASP (Runtime Application Self-Protection) functionality for any smart contract that creates an integration. An "integration" is defined as any smart contract that inherits one of the [CUBE3 Protection abstractions](), and registers on-chain with the protocol. An integration can then protect specific functions by applying the `cube3Protected` modifier to the function. The integration administrator then has function-level control over which functions to enable/disable protection for at any given time. When used in conjunction with CUBE3's Risk API, transactions that possess a risk score above a specific threshold can have their execution blocked on-chain (ie. reverted).

CUBE3's Blockchain RASP Product, a W3AF (Web3 Application Firewall) is a security tool that protects Web3 applications and smart contracts from malicious contract interactions. It works by monitoring and filtering incoming traffic to a Web3 application (dApp) or smart contract, using a set of rules to identify and block malicious requests, while allowing legitimate traffic to pass through. The rules used by a W3AF can include filters for common attack types such as re-entrancy, unchecked low-level calls (and more), known exploits, OFAC-sanctioned addresses and more. The contracts contained in this repository enable such functionality.

## Acknowledgements

- The CUBE3 Protocol relies on the operation and availability of the off-chain CUBE3 services. The CUBE3 services are provided by [CUBE3](https://cube3.io/), a company that provides security services for smart contracts and Web3 applications. From this standpoint, the CUBE3 Protocol is not fully decentralized, and thus provides mechanisms for integrations to detach themselves from the protocol.
- The Protocol cannot intentionally revert an integration's transactions. A delinquent or malicious integration can only be denied access to the modules by having the router return early.

## Architecture

In addition to focusing on security, the protocol was designed with extendability and extensibility as core features. Additional functionality can be added to the system via the installation of application-specific smart contract modules.

![arch](./docs/images//architecture.png)

The key components of the protocol are as follows:

#### Integration

CUBE3 provides abstract contracts that can be inherited to provide protection functionality. This enables the capability to protect specific functions decorated with the `cube3Protected` modifier provided by the abstraction. Once a standalone customer contract that inherits from an abstraction has registered on-chain with the router, it is then referred to as an "integration".

### Router

The router is designed for maximum flexibility. Given that the functionality of the `cube3Protected` modifier cannot exist without the accompanying CUBE3 services, flexibility and customization take precedence over immutability. As such, the Cube3Router achieves upgradeability by conforming to the UUPS spec. An integration needs to register with the Router before it can enable any function protections. Registration is further restricted through the used of a signature, generated by CUBE3 using the private key for the integration's signing authority. In order to register on-chain, the signature needs to be retrieved from the CUBE3 dApp.

#### Registry

The registry stores the signing authority for each customer integration. A signing authority is the account derived from the private-public keypair generated for each integration and stored in CUBE3's KMS on behalf of each integration.

#### Modules

Application-specific smart contracts that provide dedicated per-contract functionality to CUBE3’s on-chain protocol. The Cube3Router is responsible for routing transactions to designated modules, which will be covered in more detail in the Payload Routing section.

## Routing

# Glossay

- Integration
- Signature Authority
- Router
-
