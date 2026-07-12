# Database Documentation

# Overview

Nexvel Marketplace uses **PostgreSQL** as the primary database for storing indexed blockchain data, marketplace information, user data, and application metadata.

The database is updated through the blockchain indexer and backend services.

---

# Database Goals

* High Performance
* Scalable
* Event Driven
* ACID Compliant
* Indexed Queries
* Reliable Transactions

---

# Database Engine

* PostgreSQL

Connection Features:

* Connection Pooling
* Transactions
* Health Checks
* Graceful Shutdown

---

# Data Flow

```text
Blockchain
      │
      ▼
Blockchain Indexer
      │
      ▼
PostgreSQL
      │
      ▼
Backend API
      │
      ▼
Frontend
```

---

# Proposed Core Tables

## Users

Purpose:

Store application users.

Typical Fields:

* id
* wallet_address
* username
* avatar
* bio
* role
* created_at
* updated_at

---

## Collections

Purpose:

Store NFT collection information.

Typical Fields:

* id
* contract_address
* creator
* name
* symbol
* description
* banner
* logo
* verified
* created_at

---

## NFTs

Purpose:

Store NFT metadata.

Typical Fields:

* id
* contract_address
* token_id
* owner
* creator
* metadata_uri
* image
* name
* description
* royalty

---

## Listings

Purpose:

Store marketplace listings.

Typical Fields:

* listing_id
* contract_address
* token_id
* seller
* payment_token
* price
* listing_type
* status
* created_at

---

## Auctions

Purpose:

Store auction information.

Typical Fields:

* auction_id
* contract_address
* token_id
* seller
* highest_bid
* highest_bidder
* end_time
* status

---

## Sales

Purpose:

Store completed marketplace sales.

Typical Fields:

* sale_id
* buyer
* seller
* token_id
* collection
* price
* tx_hash
* timestamp

---

## Activities

Purpose:

Store marketplace activities.

Examples:

* Mint
* Transfer
* Listing
* Purchase
* Bid
* Auction Settlement
* Cancel Listing

---

## Notifications

Purpose:

Store user notifications.

Examples:

* NFT Sold
* New Bid
* Auction Won
* Auction Lost
* Listing Purchased

---

# Relationships

```text
Users
 │
 ├────────► Collections
 │
 ├────────► NFTs
 │
 ├────────► Listings
 │
 ├────────► Auctions
 │
 ├────────► Sales
 │
 └────────► Notifications
```

---

# Indexing Strategy

Indexes should exist on:

* wallet_address
* contract_address
* token_id
* listing_id
* auction_id
* tx_hash
* block_number
* created_at

Purpose:

* Fast Search
* Marketplace Filters
* Activity Queries
* Analytics

---

# Transactions

Database transactions should be used for:

* Purchases
* Auction Settlement
* Listing Creation
* Listing Cancellation
* Collection Creation
* Bulk Operations

---

# Event Storage

Events received from blockchain include:

* Collection Created
* NFT Minted
* Transfer
* Listing Created
* Listing Cancelled
* Sale Completed
* Bid Placed
* Auction Settled
* Launchpad Events

---

# Performance Strategy

Optimization techniques:

* Proper Indexing
* Query Optimization
* Pagination
* Connection Pooling
* Redis Caching

---

# Backup Strategy

Production recommendations:

* Daily Database Backup
* Point-in-Time Recovery
* Automated Snapshots
* Disaster Recovery Plan

---

# Security

Database security practices:

* Parameterized Queries
* Transactions
* Least Privilege Access
* Environment Variables
* Connection Encryption
* Audit Logging

---

# Future Improvements

Planned enhancements:

* Read Replicas
* Partitioning
* Materialized Views
* Full Text Search
* Analytics Tables
* Historical Event Archive

---

# Current Status

Database Connection: Implemented

Schema Documentation: In Progress

Next Tasks:

* Review Existing Tables
* Create ER Diagram
* Document Migrations
* Optimize Indexes

---

Last Updated

June 2026
