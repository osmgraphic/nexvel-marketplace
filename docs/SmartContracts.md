# Smart Contracts Documentation

# Overview

The Nexvel Marketplace smart contract system is built using Solidity, Foundry, and OpenZeppelin Upgradeable Contracts.

The architecture is modular, upgradeable, and designed for scalability, security, and future expansion.

---

# Directory Structure

```
contracts/src/

├── marketplace/
├── defi/
├── governance/
├── token/
├── treasury/
└── factory/
```

---

# Marketplace Module

## NexvelMarketplace

Base marketplace contract.

Responsibilities:

* Listing NFTs
* Buying NFTs
* Lazy Mint Support
* Royalty Distribution
* Marketplace Fees
* Payment Processing

---

## NexvelMarketplaceV2

Extends the base marketplace.

Features:

* English Auctions
* Bid Management
* Refund System
* Auction Settlement
* Auction Cancellation
* Anti-Sniping Auction Extension

---

## NexvelMarketplaceV3

Current production marketplace contract.

Responsibilities:

* Marketplace Logic
* Auctions
* Fixed Price Sales
* Lazy Mint
* ERC20 Payments
* Royalty Handling
* Security Controls

Current Status:

Primary marketplace contract.

---

# NFT Contracts

## NexvelERC721

Standard ERC721 NFT implementation.

Features:

* Mint
* Burn
* Royalty
* Metadata

---

## NexvelERC721A

Gas-optimized ERC721 implementation.

Best suited for batch minting.

---

## NexvelERC1155Upgradeable

Upgradeable multi-token implementation.

Supports:

* Batch Transfers
* Multiple Token Types
* Upgradeability

---

# NFT Factory

## NexvelNFTFactory

Responsible for deploying NFT collections.

Functions:

* Deploy ERC721 Collections
* Deploy ERC721A Collections
* Deploy ERC1155 Collections
* Registry Integration

---

# Launchpad

## NexvelLaunchpad

NFT Launchpad module.

Features:

* Public Sale
* Signature-Based Purchase
* Claim NFT
* Refund
* Fund Collection
* Sale Finalization

---

# Registry

## MarketplaceAddressRegistry

Central address registry.

Stores:

* Marketplace Address
* Factory Address
* Security Contract
* Treasury Address
* Launchpad Address

Purpose:

Avoid hardcoded contract addresses.

---

# Security

## NexvelSecurityUpgradeable

Responsible for platform-wide security configuration.

Features:

* Global Pause
* Blacklist
* Trade Limits
* Emergency Controls

---

## NexvelSecurityImpl

Security implementation contract.

---

# Token Module

## NexvelToken

Primary ecosystem token.

---

## NexvelTokenV2

Upgradeable token implementation.

---

# Treasury

## TreasuryWallet

Stores platform revenue.

Receives:

* Marketplace Fees
* Launchpad Fees
* Platform Revenue

---

# Governance

## GovernorNexvel

DAO Governance Contract.

Responsibilities:

* Proposal Creation
* Voting
* Proposal Execution

---

## NexvelTimelockController

Governance Timelock.

Provides delayed execution for approved proposals.

---

# DeFi Module

## StakingPool

Token staking.

Features:

* Stake
* Unstake
* Rewards

---

## MerkleAirdrop

Merkle Tree based airdrop.

Features:

* Gas Efficient
* One-Time Claim

---

## SignatureAirdrop

Backend signed airdrop system.

Features:

* Signature Verification
* Replay Protection

---

## VestingVault

Token vesting contract.

Supports:

* Cliff
* Linear Vesting
* Beneficiary Claims

---

# Upgradeability

Upgradeable contracts use:

* UUPS Upgrade Pattern
* OpenZeppelin Upgradeable Libraries
* Initializers
* Storage Gap Pattern

---

# Security Features

Current security mechanisms include:

* Reentrancy Protection
* Access Control
* Pausable
* Global Pause
* Signature Validation
* Royalty Support
* Trade Limits
* Marketplace Fees
* Safe Transfers

---

# Future Improvements

Planned enhancements:

* Dutch Auctions
* Collection Verification
* Creator Royalties Dashboard
* Multi-chain Support
* Cross-chain Marketplace
* Rental NFTs (ERC-4907)
* Account Abstraction Support
* Gasless Transactions
* Bulk Listing
* Bulk Purchase

---

# Smart Contract Relationships

```
User
 │
 ▼
Marketplace
 │
 ├────────► NFT Factory
 │
 ├────────► Registry
 │
 ├────────► Security
 │
 ├────────► Treasury
 │
 └────────► Launchpad

Factory
 │
 ├────────► ERC721
 ├────────► ERC721A
 └────────► ERC1155

Marketplace
 │
 └────────► Payment Distribution

Launchpad
 │
 └────────► NFT Contracts
```

---

# Audit Status

Current Status:

Documentation Completed

Upcoming Tasks:

* Full Smart Contract Audit
* Gas Optimization Review
* Security Review
* Storage Layout Review
* Event Review
* Test Coverage Review

---

Last Updated

June 2026
