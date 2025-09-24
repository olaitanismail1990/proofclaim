# ProofClaim Smart Contract

A Clarity smart contract for managing proof-of-task bounties on the Stacks blockchain.

## Overview

ProofClaim enables users to create, manage, and participate in bounty-based tasks with proof verification. The contract provides a secure way to handle bounty rewards and task submissions.

## Features

- **Bounty Creation**: Create bounties with descriptions, rewards, and optional deadlines
- **Proof Submission**: Submit and update proof of task completion
- **Reward Management**: Secure handling of STX token rewards
- **Deadline Enforcement**: Optional time-based constraints for task completion
- **Administrative Controls**: Contract ownership and management functions
- **Withdrawal System**: Safe withdrawal mechanism for expired/unclaimed bounties

## Functions

### Public Functions

```clarity
post-bounty (description (buff 100)) (reward uint) (deadline (optional uint))
fund-bounty (bounty-id uint)
submit-proof (bounty-id uint) (proof (buff 100))
update-proof (bounty-id uint) (new-proof (buff 100))
approve-submission (bounty-id uint)
cancel-bounty (bounty-id uint)
withdraw-unclaimed (bounty-id uint) (to principal)
transfer-admin (new-admin principal)
```

### Read-Only Functions

```clarity
get-bounty (bounty-id uint)
get-admin ()
```

## Error Codes

- `ERR_UNAUTHORIZED (u100)`: Unauthorized access
- `ERR_ALREADY_CLAIMED (u101)`: Bounty already claimed
- `ERR_NOT_FOUND (u102)`: Bounty not found
- `ERR_INSUFFICIENT_FUNDS (u103)`: Insufficient funds
- `ERR_INVALID_APPROVAL (u104)`: Invalid approval attempt
- `ERR_EXPIRED (u105)`: Bounty expired
- `ERR_ALREADY_EXISTS (u106)`: Resource already exists

---

For more information about Clarity smart contracts, visit the [Stacks Documentation](https://docs.stacks.co).
