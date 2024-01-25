- Write down all possible user entry points. For example, "User can call deposit() to transfer his assets in exchange for..."
- Write down all possible protocol properties and invariants.
- List any user roles: admin, moderator, regular user, depositor, governor, etc. And actions they can make.
- Create a diagram of functions flows. Sometimes it can be really difficult to identify the final result
- Provide some attack considerations.

## Scoping Details

- How many contracts are in scope?
- Total SLoC for these contracts?
- How many separate interfaces and struct definitions are there for the contracts within scope?
- What is the overall line coverage percentage provided by your tests?
- Check all that apply: ERC20, Multi-Chain, Uses L2
- Is there a need to understand a separate part of the codebase / get context in order to audit this part of the protocol?
- Is this either a fork of or an alternate implementation of another project?
- Does it use a side-chain?

## Acnkolwedgements

- TODO: cucrrently, revoking the registry will prevent new users from joining, but will not prevent existing users from using the protocol. the signature module will use a backup signer (which hsould be stored separate from teh registry/kms), so TXs can still be signed. However, the registration of new contracts will be paused (should be paused on the front-end anyway).
