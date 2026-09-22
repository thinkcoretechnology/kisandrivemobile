# Tracktor SaaS ERP - Flutter Mobile Application

A cross-platform Flutter mobile application for the **SaaS Tractor & Agricultural Equipment Management ERP** platform (`tracktor_mobile`).

## Features Included

- **Brand Theme & Styling**:
  - Material 3 design incorporating **Teal (`#008080`)**, **Metallic Gold (`#D4AF37`)**, and **Rose Gold (`#E8A598`)**.
  - Supports automatic Light & Dark themes.
- **Authentication**:
  - JWT token session management.
  - **Quick Demo Fill Buttons**: Tap to fill **Super Admin** (`9999999999` / `admin`) or **Tractor Owner** (`9952043017` / `12345`).
  - Password visibility eye toggle (`👁️` / `🙈`).
- **Mobile Field Billing (< 30s Quick Bill)**:
  - Single-screen field job entry for tractor owners and drivers on mobile fields.
- **Executive Mobile Dashboard**:
  - Real-time KPI summary cards (Active Tractors, Total Outstanding Dues, Net Fleet Profit).
  - Recent field operations list.
- **SaaS Subscriptions & Discount Calculator**:
  - 7 Days Free Trial, 15 Days, 1 Month, 3 Months, 1 Year, 3 Years, 5 Years plans with discount percentages.
- **Super Admin Mobile Control Center**:
  - Registered User Details Master Table.
  - Tenant Subscriptions Master Table (`user_id`, `user_name`, `plan_name`, `start_date`, `end_date`, `subscription_amount`).

## How to Run

1. Ensure backend Express server is running:
   ```bash
   cd /Users/riyan/tracktor/backend
   node server.js
   ```

2. Run Flutter app on Android/iOS/Web:
   ```bash
   cd /Users/riyan/tracktor/mobile
   flutter run
   ```
