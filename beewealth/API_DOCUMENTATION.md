# BeeWealth Mobile API Documentation (v1.0)

This document provides a detailed technical reference for the BeeWealth backend API, specifically tailored for the Flutter mobile application development.

## 📡 Core Configuration

### Base URL
- **Production**: `https://api.beewealth.kalique.xyz/api`
- **Development**: `http://localhost:8000/api`

### Security & Authentication
The API uses **JWT (JSON Web Tokens)** for authorization.
- **Header**: `Authorization: Bearer <access_token>`
- **Token Type**: Bearer
- **Exempt Endpoints**: `/login/`, `/register/`, `/verify-otp/`

---

## 🔐 1. Authentication Lifecycle

### A. Request Login OTP
Initiates a login sequence. If the user and password are valid, a 6-digit OTP is sent via email.
- **Endpoint**: `POST /login/`
- **Payload**:
  ```json
  {
    "email": "user@example.com",
    "password": "user_password"
  }
  ```
- **Responses**:
  - `200 OK`: `{"status": "otp_sent", "email": "..."}`
  - `401 Unauthorized`: `{"error": "Invalid email or password"}`

### B. Register New Account
Creates a new user profile. Automatically triggers a verification OTP.
- **Endpoint**: `POST /register/`
- **Payload**:
  ```json
  {
    "name": "Full Name",
    "email": "email@example.com",
    "mobile": "9876543210"
  }
  ```
- **Responses**:
  - `201 Created`: `{"status": "otp_sent", "email": "..."}`
  - `400 Bad Request`: `{"error": "Email already registered"}`

### C. Verify OTP (Token Retrieval)
Exchange the OTP code for access and refresh tokens.
- **Endpoint**: `POST /verify-otp/`
- **Payload**:
  ```json
  {
    "email": "email@example.com",
    "code": "123456"
  }
  ```
- **Success Response (200 OK)**:
  ```json
  {
    "access": "eyJ0eXAi...",
    "refresh": "eyJ0eXAi...",
    "user": {
      "email": "...",
      "name": "...",
      "role": "user"
    }
  }
  ```

---

## 👤 2. User Profile & Wallet

### A. Fetch Dashboard Data
Returns personal portfolio stats, bank details, and wallet balance.
- **Endpoint**: `GET /me/`
- **Auth Required**: Yes
- **Fields Reference**:
  - `total_investment`: Principal capital invested.
  - `total_profit_loss`: Accumulated gains/losses.
  - `current_value`: Total wallet balance (`investment + profit_loss`).
  - `total_withdrawn`: Lifetime total payouts processed.

### B. Update Profile/Bank Info
Modify personal details or payout information.
- **Endpoint**: `PATCH /me/`
- **Payload (Partial)**:
  ```json
  {
    "bank_name": "Axis Bank",
    "account_number": "1234567890",
    "ifsc_code": "UTIB0001",
    "upi_id": "user@upi",
    "upi_number": "9876543210"
  }
  ```

---

## 📊 3. Financial History & Charting

### A. Passbook (Ledger History)
Returns a list of all transactions associated with the user account.
- **Endpoint**: `GET /ledger/`
- **Filtering**: Defaults to the logged-in user. Admins can view all via `?all=true`.
- **Response**:
  ```json
  [
    {
      "id": 105,
      "date": "2024-04-21",
      "entry_type": "profit",
      "amount": "1250.00",
      "units_delta": "0.0000",
      "description": "Daily profit credit"
    }
  ]
  ```

### B. Performance Chart (P/L Timeline)
Historical daily P/L values for line charts.
- **Endpoint**: `GET /pl/`
- **Response**:
  ```json
  [
    {
      "date": "2024-04-20",
      "amount": "500.00",
      "per_unit_change": "0.0150",
      "percentage": 1.5
    }
  ]
  ```

---

## 💸 4. Fund Requests

### A. Investment Request
Request to add funds to the portfolio. Must specify the amount.
- **Endpoint**: `POST /investment-requests/`
- **Payload**: `{"amount": 50000.00}`
- **Note**: Status will be `pending` until an admin marks it as `completed`.

### B. Withdrawal Request
Request a payout.
- **Endpoint**: `POST /withdrawals/`
- **Validation**:
  - Regular Users: Cannot exceed `current_value`.
  - Admins: Restricted to withdrawing only `total_profit_loss`.

---

## 🛡️ 5. Error Handling Standards

All error responses follow the standard JSON error format:
```json
{
  "error": "Human readable error description",
  "detail": "Extended technical detail (optional)"
}
```

### Common Error Codes
| HTTP Code | Meaning | Context |
| :--- | :--- | :--- |
| `400` | Bad Request | Validation failures, Invalid OTP, Insufficient funds. |
| `401` | Unauthorized | Token expired or missing. |
| `403` | Forbidden | Attempting to access admin data without privilege. |
| `404` | Not Found | Profile or record does not exist. |
| `500` | Server Error | Internal crash or email service failure. |

---

## 👨‍💼 6. Administrative Oversight

For users with the `admin` role, the following management endpoints are available:

### A. Global Data Scoping
Admins can bypass personal isolation by appending `?all=true` to the following endpoints:
- `GET /ledger/?all=true` (View all transactions)
- `GET /withdrawals/?all=true` (View all payout requests)
- `GET /investment-requests/?all=true` (View all funding requests)

### B. User Management
Retrieve and manage the user database.
- **Endpoint**: `GET /users/`
- **Response**: List of all `UserProfile` objects.

### C. Post Daily Earnings
Distribute profits or losses across all active units.
- **Endpoint**: `POST /pl/`
- **Payload**:
  ```json
  {
    "date": "2024-04-21",
    "amount": 250000.00
  }
  ```
- **Action**: This automatically updates all active user balances proportionally.
