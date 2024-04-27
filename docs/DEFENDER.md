# Protocol Management

The protocol is deployed and managed using [Openzeppelin Defender V2](https://docs.openzeppelin.com/defender/v2/).

`Relayers` are managed accounts, a public-private keypair is generated for each relayer account. OZ controls the private key, it cannot be exported. Transactions can be triggered for the relay account via an API endpoint (or SDK) using the API key generated in the dashboard.

Eg. A 'Key Manager' relayer. CUBE3 picks up event offchain, generates a signature.

- Possible uses:
  - One of the manager roles

# Notes
