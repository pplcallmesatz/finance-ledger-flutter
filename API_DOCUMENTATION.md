# Ledger Management System - API Documentation

## Overview

This API provides comprehensive functionality for managing a ledger system with the following modules:
- **Authentication & Users**
- **Category Management**
- **Product Management**
- **Sales Ledger**
- **Expense Ledger**
- **Transactions**
- **Payments (Razorpay Integration)**
- **Dashboard & Analytics**

## Base URL
```
https://your-domain.com/api
```

## Authentication

### Login
```http
POST /login
```

**Request Body:**
```json
{
    "email": "user@example.com",
    "password": "password"
}
```

**Response:**
```json
{
    "token": "1|abc123..."
}
```

**Usage:** Include the token in the Authorization header for all subsequent requests:
```
Authorization: Bearer 1|abc123...
```

---

## Dashboard APIs

### Overview Statistics
```http
GET /dashboard/overview
```

**Query Parameters:**
- `start_date` (optional): Start date for statistics (YYYY-MM-DD)
- `end_date` (optional): End date for statistics (YYYY-MM-DD)

**Response:**
```json
{
    "success": true,
    "data": {
        "statistics": {
            "total_expenses": 50000,
            "total_sales": 150000,
            "total_pending": 25000,
            "total_profit": 100000,
            "profit_margin": 66.67
        },
        "recent_transactions": [...],
        "payment_status_breakdown": [...]
    }
}
```

### Product Analysis
```http
GET /dashboard/product-analysis
```

**Query Parameters:**
- `start_date` (optional): Start date for analysis
- `end_date` (optional): End date for analysis

**Response:**
```json
{
    "success": true,
    "data": {
        "products_summary": [...],
        "grouped_by_category": {...},
        "overall_totals": {
            "total_product_price": 80000,
            "total_customer_price": 150000,
            "total_profit": 70000
        }
    }
}
```

### Inventory Status
```http
GET /dashboard/inventory-status
```

**Response:**
```json
{
    "success": true,
    "data": {
        "category_inventory": [...],
        "low_stock_alerts": [...],
        "expiring_products": [...]
    }
}
```

### Sales Trends
```http
GET /dashboard/sales-trends?period=month&limit=12
```

**Query Parameters:**
- `period`: week, month, year
- `limit`: number of periods to analyze

### Top Products
```http
GET /dashboard/top-products?limit=10
```

### Customer Analytics
```http
GET /dashboard/customer-analytics
```

---

## Category Management APIs

### List Categories
```http
GET /category-masters
```

**Query Parameters:**
- `search` (optional): Search term
- `per_page` (optional): Items per page

### Create Category
```http
POST /category-masters
```

**Request Body:**
```json
{
    "name": "Electronics",
    "description": "Electronic products",
    "symbol": "ELEC",
    "self_life": "365"
}
```

### Get Category
```http
GET /category-masters/{id}
```

### Update Category
```http
PUT /category-masters/{id}
```

### Delete Category
```http
DELETE /category-masters/{id}
```

---

## Product Management APIs

### List Products
```http
GET /products
```

**Query Parameters:**
- `search` (optional): Search term
- `category_id` (optional): Filter by category
- `barcode` (optional): Filter by barcode
- `per_page` (optional): Items per page

### Create Product
```http
POST /products
```

**Request Body:**
```json
{
    "name": "Laptop",
    "purchase_price": 50000,
    "packing_price": 500,
    "product_price": 50500,
    "selling_price": 60000,
    "description": "High-performance laptop",
    "category_master_id": 1,
    "barcode": "LAP001",
    "barcode_vendor": "Vendor A",
    "units": 1
}
```

### Get Product
```http
GET /products/{id}
```

### Update Product
```http
PUT /products/{id}
```

### Delete Product
```http
DELETE /products/{id}
```

### Search by Barcode
```http
GET /products/search/barcode?barcode=LAP001
```

### Get Inventory Status
```http
GET /products/{id}/inventory
```

### Get Pricing History
```http
GET /products/{id}/pricing-history
```

### Get Performance Analytics
```http
GET /products/{id}/performance
```

### Bulk Update Prices
```http
POST /products/bulk-update-prices
```

**Request Body:**
```json
{
    "products": [
        {
            "id": 1,
            "product_price": 50000,
            "packing_price": 500,
            "selling_price": 60000
        }
    ]
}
```

### Get Low Stock Products
```http
GET /products/low-stock?threshold=10
```

### Generate Barcode
```http
POST /products/{id}/generate-barcode
```

---

## Sales Ledger APIs

### List Sales Ledgers
```http
GET /sales-ledgers
```

**Query Parameters:**
- `search` (optional): Search term
- `payment_status` (optional): pending, paid, partial, cancelled
- `user_id` (optional): Filter by user
- `start_date` (optional): Start date
- `end_date` (optional): End date
- `per_page` (optional): Items per page

### Create Sales Ledger
```http
POST /sales-ledgers
```

**Request Body:**
```json
{
    "user_id": 1,
    "userCheck": "existing",
    "sales_date": "2024-01-15",
    "payment_method": "cash",
    "payment_status": "pending",
    "remarks": "Customer order",
    "products": [
        {
            "selected": true,
            "product_id": 1,
            "product_name": "Laptop",
            "product_price": 50000,
            "selling_price": 60000,
            "quantity": 1,
            "customer_price": 60000,
            "product_master_id": 1
        }
    ]
}
```

### Get Sales Ledger
```http
GET /sales-ledgers/{id}
```

### Update Sales Ledger
```http
PUT /sales-ledgers/{id}
```

### Delete Sales Ledger
```http
DELETE /sales-ledgers/{id}
```

### Update Payment Status
```http
PATCH /sales-ledgers/{id}/payment-status
```

**Request Body:**
```json
{
    "payment_status": "paid"
}
```

### Create Payment Link
```http
POST /sales-ledgers/{id}/payment-link
```

### Get Sales Summary
```http
GET /sales-ledgers/summary
```

### GET /api/sales-ledgers/pending

**Description:**
Returns a list of all sales ledger entries with payment_status 'pending' and the total sum of all pending payments.

**Note:**
This route must be defined before `Route::apiResource('sales-ledgers', ...)` in `routes/api.php` to avoid route model binding issues.

**Authentication:** Required (Bearer Token)

**Request:**
```
GET /api/sales-ledgers/pending
Headers:
  Authorization: Bearer <token>
  Accept: application/json
```

**Response Example:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "invoice_number": "INV0100001",
      "user_id": 5,
      "total_customer_price": 1500,
      "payment_status": "pending",
      "payment_method": "cash",
      // ...other fields
    },
    // ...more entries
  ],
  "total_pending": 4500
}
```

- `data`: Array of all pending sales ledger entries (full resource details).
- `total_pending`: The sum of `total_customer_price` for all pending entries.

### PATCH /api/sales-ledgers/{id}/payment-info

**Description:**
Update only the `payment_status` and/or `payment_method` fields of a sales ledger entry.

**Authentication:** Required (Bearer Token)

**Request:**
```
PATCH /api/sales-ledgers/{id}/payment-info
Headers:
  Authorization: Bearer <token>
  Accept: application/json
  Content-Type: application/json
Body (JSON):
{
  "payment_status": "paid",        // optional, string
  "payment_method": "cash"         // optional, string
}
```
- At least one of `payment_status` or `payment_method` must be provided.

**Example cURL:**
```
curl -X PATCH "http://localhost:8000/api/sales-ledgers/{id}/payment-info" \
  -H "Authorization: Bearer 116|Wv8Zhr8yr4xmk4paxuhqqqf9iOsntOIUKtLT6zac061f9d60" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d '{"payment_status":"paid","payment_method":"cash"}'
```
Replace `{id}` with the actual sales ledger ID you want to update.

**Response Example:**
```json
{
  "success": true,
  "message": "Payment info updated successfully.",
  "data": {
    "id": 1,
    "payment_status": "paid",
    "payment_method": "cash",
    // ...other fields
  }
}
```

- Returns the updated sales ledger entry.
- If neither field is provided, returns a 422 error with a message.

---

## Payment APIs

### Create Payment Order
```http
POST /payments/create-order
```

**Request Body:**
```json
{
    "sales_ledger_id": 1,
    "amount": 60000,
    "currency": "INR"
}
```

### Verify Payment
```http
POST /payments/verify
```

**Request Body:**
```json
{
    "razorpay_order_id": "order_abc123",
    "razorpay_payment_id": "pay_xyz789",
    "razorpay_signature": "signature_hash"
}
```

### Get Payment Status
```http
GET /payments/status/{salesLedgerId}
```

### Get Payment History
```http
GET /payments/history
```

**Query Parameters:**
- `start_date` (optional): Start date
- `end_date` (optional): End date
- `status` (optional): Payment status filter
- `per_page` (optional): Items per page

### Process Refund
```http
POST /payments/refund
```

**Request Body:**
```json
{
    "payment_id": "pay_xyz789",
    "amount": 60000,
    "reason": "Customer request"
}
```

### Webhook (Razorpay)
```http
POST /payments/webhook
```

---

## User Management APIs

### List Users
```http
GET /users
```

### GET /api/users

**Description:**
Get a paginated list of users, sorted alphabetically by name.

**Authentication:** Required (Bearer Token)

**Request:**
```
GET /api/users?per_page=15&page=1
Headers:
  Authorization: Bearer 132|hJRTka0Yttucg1kt0239dawDB0tJswrwjwtnVcj8753649dd
  Accept: application/json
```
- `per_page` (optional): Number of users per page (default: 15)
- `page` (optional): Page number

**Example cURL:**
```
curl -X GET "http://localhost:8000/api/users?per_page=15&page=1" \
  -H "Authorization: Bearer 132|hJRTka0Yttucg1kt0239dawDB0tJswrwjwtnVcj8753649dd" \
  -H "Accept: application/json"
```

**Response Example:**
```json
{
  "data": [
    { "id": 1, "name": "Alice", ... },
    { "id": 2, "name": "Bob", ... }
    // ...
  ],
  "links": { ... },
  "meta": { ... }
}
```

### Create User
```http
POST /api/users
```

**Description:**
Create a new user. Any authenticated user can now create users.

**Authentication:** Required (Bearer Token)

**Request:**
```
POST /api/users
Headers:
  Authorization: Bearer 132|hJRTka0Yttucg1kt0239dawDB0tJswrwjwtnVcj8753649dd
  Accept: application/json
  Content-Type: application/json
Body (JSON):
{
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "9876543210",
  "password": "your_password",
  "remarks": "Optional remarks"
}
```

**Example cURL:**
```
curl -X POST "http://localhost:8000/api/users" \
  -H "Authorization: Bearer 132|hJRTka0Yttucg1kt0239dawDB0tJswrwjwtnVcj8753649dd" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "9876543210",
    "password": "your_password",
    "remarks": "Optional remarks"
  }'
```

**Response Example:**
```json
{
  "data": {
    "id": 12,
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "9876543210",
    "remarks": "Optional remarks"
    // ...other fields
  }
}
```

### Get User
```http
GET /users/{id}
```

### Update User
```http
PUT /users/{id}
```

### Delete User
```http
DELETE /users/{id}
```

### GET /api/users/{id}/details

**Description:**
Get detailed information for a user, including:
- User name, phone, email, remarks
- Total pending and total paid (sum of total_customer_price for pending/paid sales ledgers)
- List of that user's pending sales entries and their total
- List of that user's paid sales entries and their total

**Authentication:** Required (Bearer Token)

**Request:**
```
GET /api/users/{id}/details
Headers:
  Authorization: Bearer 132|hJRTka0Yttucg1kt0239dawDB0tJswrwjwtnVcj8753649dd
  Accept: application/json
```

**Example cURL:**
```
curl -X GET "http://localhost:8000/api/users/{id}/details" \
  -H "Authorization: Bearer 132|hJRTka0Yttucg1kt0239dawDB0tJswrwjwtnVcj8753649dd" \
  -H "Accept: application/json"
```
Replace `{id}` with the user ID.

**Response Example:**
```json
{
  "user": {
    "id": 143,
    "name": "Jane Doe",
    "phone": "9876543210",
    "email": "jane@example.com",
    "remarks": "Updated remarks"
  },
  "total_pending": 5000,
  "total_paid": 12000,
  "pending_entries": [
    { /* sales ledger object */ }
    // ...
  ],
  "paid_entries": [
    { /* sales ledger object */ }
    // ...
  ]
}
```

---

## Expense Ledger APIs

### List Expense Ledgers
```http
GET /expense-ledgers
```

### Create Expense Ledger
```http
POST /expense-ledgers
```

**Request Body:**
```json
{
    "name": "Office Rent",
    "description": "Monthly office rent",
    "invoice_number": "INV001",
    "purchase_price": 50000,
    "seller": "Landlord",
    "purchase_date": "2024-01-01",
    "payment_method": "bank_transfer",
    "expense_type": "rent",
    "deduct": true
}
```

### Get Expense Ledger
```http
GET /expense-ledgers/{id}
```

### Update Expense Ledger
```http
PUT /expense-ledgers/{id}
```

### Delete Expense Ledger
```http
DELETE /expense-ledgers/{id}
```

---

## Transaction APIs

### List Transactions
```http
GET /transactions
```

### Create Transaction
```http
POST /transactions
```

**Request Body:**
```json
{
    "bank_balance": 100000,
    "cash_in_hand": 50000,
    "sales_ledger_id": 1,
    "reason": "Sales transaction"
}
```

### Get Transaction
```http
GET /transactions/{id}
```

### Update Transaction
```http
PUT /transactions/{id}
```

### Delete Transaction
```http
DELETE /transactions/{id}
```

---

## Product Master APIs

### List Product Masters
```http
GET /product-masters
```

**Query Parameters:**
- `search` (optional): Search term
- `category_id` (optional): Filter by category
- `per_page` (optional): Items per page

**Example:**
```
GET /api/product-masters?category_id=1
```

### Create Product Master
```http
POST /product-masters
```

**Request Body:**
```json
{
    "name": "Bulk Laptops",
    "category_id": 1,
    "purchase_price": 50000,
    "purchase_date": "2024-01-01",
    "manufacturing_date": "2023-12-01",
    "transportation_cost": 1000,
    "invoice_number": "INV001",
    "vendor": "Tech Supplier",
    "quantity_purchased": 10,
    "batch_number": "BATCH001",
    "expire_date": "2025-12-01",
    "total_piece": 10
}
```

### Get Product Master
```http
GET /product-masters/{id}
```

### Update Product Master
```http
PUT /product-masters/{id}
```

### Delete Product Master
```http
DELETE /product-masters/{id}
```

### POST /api/product-masters

**Description:**
Create a new product master. The following fields are required unless your database allows null/default values:
- name
- purchase_price
- purchase_date
- manufacturing_date
- transportation_cost
- invoice_number
- quantity_purchased
- vendor
- category_id
- expire_date
- total_piece (string)

**Authentication:** Required (Bearer Token)

**Request:**
```
POST /api/product-masters
Headers:
  Authorization: Bearer 132|hJRTka0Yttucg1kt0239dawDB0tJswrwjwtnVcj8753649dd
  Accept: application/json
  Content-Type: application/json
Body (JSON):
{
  "name": "Product Master A",
  "purchase_price": 100,
  "purchase_date": "2024-07-01",
  "manufacturing_date": "2024-06-01",
  "transportation_cost": 10,
  "invoice_number": "INV001",
  "quantity_purchased": 50,
  "vendor": "Vendor Name",
  "category_id": 1,
  "expire_date": "2025-07-01",
  "total_piece": "0"
}
```

**Example cURL:**
```
curl -X POST "http://localhost:8000/api/product-masters" \
  -H "Authorization: Bearer 132|hJRTka0Yttucg1kt0239dawDB0tJswrwjwtnVcj8753649dd" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Product Master A",
    "purchase_price": 100,
    "purchase_date": "2024-07-01",
    "manufacturing_date": "2024-06-01",
    "transportation_cost": 10,
    "invoice_number": "INV001",
    "quantity_purchased": 50,
    "vendor": "Vendor Name",
    "category_id": 1,
    "expire_date": "2025-07-01",
    "total_piece": "0"
  }'
```

---

## Error Responses

### Validation Error (422)
```json
{
    "success": false,
    "message": "The given data was invalid.",
    "errors": {
        "field_name": ["The field name field is required."]
    }
}
```

### Not Found Error (404)
```json
{
    "success": false,
    "message": "Resource not found"
}
```

### Unauthorized Error (401)
```json
{
    "success": false,
    "message": "Unauthenticated"
}
```

### Server Error (500)
```json
{
    "success": false,
    "message": "Internal server error"
}
```

---

## Business Logic Features

### Sales Ledger Features:
- **Automatic Invoice Generation**: Invoice numbers are auto-generated based on month and sequence
- **Inventory Management**: Automatically updates product master stock when products are sold
- **Payment Integration**: Supports Razorpay payment processing
- **Transaction Tracking**: Creates transaction records for financial tracking
- **User Management**: Can create new users during sales process

### Product Features:
- **Barcode Management**: Generate and search products by barcode
- **Pricing History**: Track price changes over time
- **Inventory Tracking**: Monitor stock levels and low stock alerts
- **Performance Analytics**: Analyze product sales performance
- **Bulk Operations**: Update multiple product prices at once

### Payment Features:
- **Razorpay Integration**: Full payment gateway integration
- **Webhook Handling**: Automatic payment status updates
- **Refund Processing**: Handle payment refunds
- **Payment History**: Track all payment transactions
- **Signature Verification**: Secure payment verification

### Dashboard Features:
- **Real-time Analytics**: Live business metrics
- **Product Analysis**: Profit/loss analysis by product and category
- **Inventory Monitoring**: Stock level tracking and alerts
- **Sales Trends**: Historical sales data analysis
- **Customer Analytics**: Customer behavior and spending patterns

---

## Rate Limiting

The API implements rate limiting to prevent abuse:
- **Authentication endpoints**: 5 requests per minute
- **Other endpoints**: 60 requests per minute per user

---

## Webhook Configuration

For Razorpay webhooks, configure the following URL in your Razorpay dashboard:
```
https://your-domain.com/api/payments/webhook
```

Supported webhook events:
- `payment.captured`
- `payment.failed`
- `order.paid`

---

## Testing

You can test the API using tools like:
- **Postman**
- **Insomnia**
- **cURL**

Example cURL request:
```bash
curl -X POST https://your-domain.com/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password"}'
```

---

## Support

For API support and questions, please contact the development team or refer to the application logs for detailed error information. 

### POST /api/products

**Description:**
Create a new product. The following fields are required unless your database allows null/default values:
- name
- product_price (auto-calculated if not provided)
- selling_price
- category_master_id
- purchase_price
- packing_price
- barcode_vendor
- units

**Authentication:** Required (Bearer Token)

**Request:**
```
POST /api/products
Headers:
  Authorization: Bearer 132|hJRTka0Yttucg1kt0239dawDB0tJswrwjwtnVcj8753649dd
  Accept: application/json
  Content-Type: application/json
Body (JSON):
{
  "name": "Product A",
  "product_price": 100,
  "selling_price": 120,
  "category_master_id": 2,
  "purchase_price": 90,
  "transport_charge": 10,
  "packing_price": 5,
  "description": "Sample product",
  "barcode": "1234547890",
  "barcode_vendor": "Vendor Name",
  "units": 1,
  "remarks": "Optional remarks"
}
```

**Example cURL:**
```
curl -X POST "http://localhost:8000/api/products" \
  -H "Authorization: Bearer 132|hJRTka0Yttucg1kt0239dawDB0tJswrwjwtnVcj8753649dd" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Product A",
    "product_price": 100,
    "selling_price": 120,
    "category_master_id": 2,
    "purchase_price": 90,
    "transport_charge": 10,
    "packing_price": 5,
    "description": "Sample product",
    "barcode": "1234547890",
    "barcode_vendor": "Vendor Name",
    "units": 1,
    "remarks": "Optional remarks"
  }'
```

**Response Example:**
```json
{
  "data": {
    "id": 12,
    "name": "Product A",
    "product_price": 100,
    "selling_price": 120,
    "category_master_id": 2,
    "purchase_price": 90,
    "transport_charge": 10,
    "packing_price": 5,
    "description": "Sample product",
    "barcode": "1234547890",
    "barcode_vendor": "Vendor Name",
    "units": 1,
    "remarks": "Optional remarks"
  }
}
``` 