# API Documentation

## Overview

The Nexvel Marketplace backend exposes REST APIs that allow the frontend, admin panel, and external services to interact with marketplace data.

The API is designed to be:

* RESTful
* Secure
* Version Ready
* Scalable
* Well Documented

---

## Base URL

Development

```
http://localhost:4000/api
```

Production

```
https://api.nexvelmarketplace.com/api
```

---

#### API Versioning

Current Version

```
v1
```

Future

```
/api/v2
```

---

## Authentication

Current

* JWT Authentication
* Protected Routes
* Role-Based Authorization

Future

* Wallet Authentication
* Sign-In With Ethereum (SIWE)
* Refresh Tokens

---

## API Modules

#### Authentication

Base Route

```
/api/auth
```

Endpoints

* Login
* Register
* Refresh Token
* Logout
* Wallet Login

---

#### Users

Base Route

```
/api/users
```

Endpoints

* Get Profile
* Update Profile
* User NFTs
* User Listings
* User Activity
* User Collections

---

#### Collections

Base Route

```
/api/collections
```

Endpoints

* List Collections
* Collection Details
* Trending Collections
* Verified Collections
* Creator Collections

---

#### NFTs

Base Route

```
/api/nfts
```

Endpoints

* Get NFT
* NFT Metadata
* Owner Details
* Activity
* Related NFTs

---

#### Listings

Base Route

```
/api/listings
```

Endpoints

* Create Listing
* Cancel Listing
* Update Price
* Active Listings
* Marketplace Listings

---

#### Auctions

Base Route

```
/api/auctions
```

Endpoints

* Create Auction
* Place Bid
* Cancel Auction
* Auction Details
* Live Auctions

---

#### Sales

Base Route

```
/api/sales
```

Endpoints

* Marketplace Sales
* Collection Sales
* User Sales
* Recent Sales

---

#### Activity

Base Route

```
/api/activity
```

Endpoints

* Global Activity
* NFT Activity
* User Activity
* Collection Activity

---

#### Search

Base Route

```
/api/search
```

Endpoints

* Search NFTs
* Search Collections
* Search Users
* Search Marketplace

---

#### Notifications

Base Route

```
/api/notifications
```

Endpoints

* User Notifications
* Mark as Read
* Delete Notification

---

#### Roles

Base Route

```
/api/roles
```

Endpoints

* List Roles
* Assign Role
* Remove Role
* Permissions

---

## HTTP Methods

GET

Retrieve resources.

POST

Create resources.

PUT

Replace existing resources.

PATCH

Update resources.

DELETE

Remove resources.

---

## Standard Response Format

Success

```json
{
  "success": true,
  "data": {},
  "message": "Operation completed successfully"
}
```

Error

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Validation failed"
  }
}
```

---

## Pagination

Supported Query Parameters

```
?page=1
&limit=20
```

---

## Filtering

Examples

```
?collection=...
?creator=...
?owner=...
?status=listed
?verified=true
```

---

## Sorting

Examples

```
?sort=price
?sort=createdAt
?sort=volume
```

Order

```
asc
desc
```

---

## Authentication Headers

```
Authorization: Bearer <JWT_TOKEN>
```

Future Wallet Header

```
X-Wallet-Address
```

---

## Rate Limiting

Recommended

* Public APIs
* Search APIs
* Authentication APIs

Future

Redis-backed rate limiting.

---

## Socket.IO Events

Real-time events

* listing.created
* listing.cancelled
* sale.completed
* auction.created
* auction.bid
* auction.finished
* notification.created

---

## Error Codes

Standard Codes

* VALIDATION_ERROR
* UNAUTHORIZED
* FORBIDDEN
* NOT_FOUND
* CONFLICT
* INTERNAL_SERVER_ERROR

---

## API Security

Security Practices

* JWT Validation
* Input Validation
* Rate Limiting
* Role Authorization
* Parameterized Database Queries
* HTTPS in Production

---

## Future Enhancements

* Swagger / OpenAPI
* GraphQL Gateway
* API Keys
* Webhooks
* Bulk Operations
* API Analytics

---

## API Development Rules

* Keep endpoints RESTful.
* Use consistent response formats.
* Validate every request.
* Return meaningful HTTP status codes.
* Document every endpoint.
* Version breaking changes.

---

## Current Status

API Structure: Implemented

Documentation: Initial Version

Next Tasks

* Review Existing Endpoints
* Document Request Schemas
* Document Response Schemas
* Generate Swagger Specification

---

Last Updated

June 2026
