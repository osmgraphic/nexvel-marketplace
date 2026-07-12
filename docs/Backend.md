# Backend Documentation

# Overview

The Nexvel Marketplace backend is built using **TypeScript**, **Express.js**, **PostgreSQL**, **Redis**, and **Socket.IO**.

The backend acts as the central communication layer between the frontend, blockchain indexer, and smart contracts.

---

# Backend Goals

* Secure REST APIs
* Real-time Updates
* Blockchain Event Processing
* Fast Database Queries
* Modular Architecture
* Scalable Services

---

# Technology Stack

## Runtime

* Node.js

## Language

* TypeScript

## Framework

* Express.js

## Database

* PostgreSQL

## Cache

* Redis

## Blockchain

* Viem
* Ethers.js v6

## Realtime

* Socket.IO

## Validation

* Zod

## Logging

* Pino Logger

---

# Folder Structure

```text
src/

├── abi/
├── api/
├── blockchain/
├── config/
├── constants/
├── database/
├── events/
├── indexer/
├── middlewares/
├── scripts/
├── services/
├── socket/
├── utils/
└── server.ts
```

---

# API Layer

The API layer exposes REST endpoints for the frontend.

Modules include:

* Authentication
* Users
* Collections
* NFTs
* Listings
* Sales
* Search
* Notifications
* Roles
* Activity

Responsibilities:

* Request Validation
* Authentication
* Authorization
* Business Logic
* Response Formatting

---

# Service Layer

The service layer contains reusable business logic.

Current services include:

* Collection Service
* NFT Service
* Listing Service
* Sale Service

Responsibilities:

* Database Operations
* Smart Contract Integration
* Business Rules

---

# Authentication

Authentication responsibilities:

* User Login
* JWT Validation
* Protected Routes
* Role-based Access

Future Improvements:

* Wallet Authentication
* SIWE (Sign-In with Ethereum)
* Refresh Tokens

---

# Blockchain Layer

Responsible for blockchain communication.

Modules:

* RPC Client
* Block Processing
* Reorg Detection
* Rollback Handling

Responsibilities:

* Read Blockchain State
* Subscribe to Events
* Maintain Synchronization

---

# Event Indexer

The indexer listens to smart contract events and updates the backend database.

Supported modules:

* Marketplace
* NFT Factory
* ERC721
* ERC1155
* Launchpad
* Activity

Responsibilities:

* Event Processing
* Database Updates
* Real-time Notifications
* Reindex Support

---

# Database Layer

Database engine:

PostgreSQL

Responsibilities:

* Users
* Collections
* NFTs
* Listings
* Sales
* Activities
* Metadata

The backend uses:

* Connection Pool
* Transactions
* Query Helpers
* Health Checks

---

# Redis

Redis is used for:

* API Caching
* Frequently Accessed Data
* Session Support
* Performance Optimization

Future Uses:

* Queue Processing
* Background Jobs
* Rate Limiting Storage

---

# Socket.IO

Provides real-time communication.

Use cases:

* New Listings
* Sales
* Auctions
* Bids
* Notifications
* Activity Feed

---

# Middleware

Current middleware:

* Authentication
* Role Authorization
* Error Handling
* Rate Limiting

Future middleware:

* Request Logging
* API Metrics
* Audit Logs

---

# Configuration

Configuration files include:

* Environment Variables
* Contract Addresses
* RPC Configuration
* Network Settings

---

# Security

Current security mechanisms:

* JWT Authentication
* Role-Based Access
* Input Validation
* Rate Limiting
* Environment Separation
* Secure Database Connections

Future enhancements:

* CSRF Protection
* API Key Management
* Request Signing
* Audit Logging

---

# Performance Strategy

Optimization goals:

* Database Indexing
* Redis Caching
* Efficient Event Processing
* Pagination
* Optimized Queries
* Connection Pooling

---

# Error Handling

Backend follows centralized error handling.

Goals:

* Consistent Error Responses
* Structured Logging
* Developer-Friendly Debugging

---

# Backend Workflow

```text
Frontend
     │
     ▼
REST API
     │
     ▼
Service Layer
     │
     ├────────► PostgreSQL
     │
     ├────────► Redis
     │
     └────────► Blockchain Client
                     │
                     ▼
             Smart Contracts
```

---

# Development Guidelines

* Keep controllers lightweight.
* Place business logic in services.
* Validate all request data.
* Use transactions for multi-step database operations.
* Emit Socket.IO events after successful state changes.
* Keep APIs version-friendly.

---

# Future Improvements

* Swagger / OpenAPI Documentation
* Background Job Queue
* Metrics Dashboard
* Monitoring
* Docker Support
* CI/CD Integration
* Automated Testing
* Multi-network Support

---

# Current Status

Backend Architecture: Stable

Next Focus:

* Complete API Documentation
* Database Schema Documentation
* Performance Review
* Security Audit

---

Last Updated

June 2026
