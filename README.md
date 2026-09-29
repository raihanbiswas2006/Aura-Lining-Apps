# Aura Living — Flutter Cross-Platform Workspace

[![Flutter](https://img.shields.io/badge/Flutter-3.13+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20%2B%20Modular-1F4E43)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android%20%7C%20Web-black)](https://flutter.dev)
[![Localization](https://img.shields.io/badge/Localization-Bangladesh%20(BDT%20৳)-green)](https://flutter.dev)

A luxury minimalist e-commerce ecosystem consisting of a customer-facing Mobile Application and a Store Operations Admin App. Built with Flutter, synchronized with the [Aura Living Web Platform](https://aura-minimalist-e-commerce.vercel.app/), and localized specifically for the Bangladesh market.

---

## 🏛 Ecosystem Architecture

This monorepo workspace contains two standalone Flutter applications:

```
Aura Living Apps/
├── Aura Living Mobile App/        # Customer-facing e-commerce storefront
│   ├── lib/
│   │   ├── app/                   # App routes (GoRouter), Theme tokens & Design System
│   │   ├── core/                  # Constants, Formatters (BDT ৳), Widgets, BD Regions
│   │   ├── data/                  # Repositories & Mock data sources
│   │   ├── domain/                # Entities, Value Objects, Service Contracts
│   │   └── presentation/          # BLoC state management, screens, bottom sheets
│   └── pubspec.yaml
│
├── Aura Living Admin App/         # Merchant & operations management portal
│   ├── lib/
│   │   ├── core/                  # Theme, BDT formatters, courier partners, UI components
│   │   ├── features/              # Riverpod feature slices (Orders, Catalog, Coupons, etc.)
│   │   │   ├── auth/              # Role-Based Access Control (Super Admin, Manager, Staff)
│   │   │   ├── dashboard/         # Real-time BDT revenue & pending order metrics
│   │   │   ├── orders/            # Order fulfillment & courier tracking (Steadfast, Pathao)
│   │   │   ├── products/          # Catalog management with multi-variant stock control
│   │   │   ├── promotions/        # BDT coupons & discounts
│   │   │   └── settings/          # Shipping thresholds & store policy
│   │   └── main.dart
│   └── pubspec.yaml
│
└── README.md
```

---

## 🎨 Design & Aesthetic Alignment

Both applications reflect the high-end Scandinavian and Japanese *Kanso* minimalist aesthetic established by the live web platform:

- **Warm Alabaster Canvas**: `#FAF9F6` & `#FFFFFF`
- **Void Charcoal Typography**: `#14171A` (Primary text with Playfair Display editorial headings and Plus Jakarta Sans body)
- **Deep Forest Pine Accent**: `#1F4E43`
- **Subtle Organic Borders**: `#E4E7EB`
- **Harmonious Status Colors**: Soft badges for stock indicators, order statuses, and verified reviews.

---

## 🇧🇩 Bangladesh Localization

1. **Currency & Precision**:
   - All pricing formatted in Bangladeshi Taka (`৳` / BDT) with standard South Asian comma separators (`৳34,900`, `৳1,25,000`).
   - Complimentary courier delivery threshold set at `৳5,000`.

2. **Geographical & Shipping Hierarchy**:
   - Standardized across all 8 Divisions (Dhaka, Chattogram, Rajshahi, Khulna, Barishal, Sylhet, Rangpur, Mymensingh) and 64 Districts with Thana/Upazila selection.
   - Phone number validation supporting Bangladesh format (`+880 1X-XXXXXXXX` / `01XXXXXXXX`).

3. **Payment Infrastructure**:
   - **Cash on Delivery (COD)** with doorstep collection notes.
   - **bKash MFS** with instant TrxID confirmation placeholder.
   - **Nagad Digital Payment** with Merchant wallet validation.
   - **Rocket (Dutch-Bangla Bank)** mobile banking gateway.
   - **Visa / Mastercard / AMEX** international & local credit/debit cards.

4. **Courier Partner Integration (Admin App)**:
   - Order fulfillment pipeline supporting top Bangladesh logistics providers:
     - **Steadfast Courier**
     - **Pathao Courier**
     - **RedX Logistics**
     - **Paperfly**
     - **eCourier**
   - Quick-action courier assignment with auto-generated tracking numbers and direct customer calling intent.

---

## 🔥 Future-Proof Firebase Architecture

Both applications are architected with clean repository and service abstractions ready for plug-and-play Firebase initialization:

- **`AuthService`**: Ready for Firebase Auth with Phone OTP (`+880`) and Google Sign-In.
- **`ProductService` & `CategoryService`**: Firestore collection mapping (`/products`, `/categories`) with real-time stream subscriptions.
- **`OrderService` & `FirestoreAdminService`**: Firestore collections (`/orders`) with multi-status pipelines.
- **`StorageService`**: Firebase Cloud Storage image upload pipeline with compression and CDN token URLs.

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.13.0 or higher
- Dart 3.1.0 or higher

### Running the Customer Mobile App
```bash
cd "Aura Living Mobile App"
flutter pub get
flutter run
```

### Running the Store Operations Admin App
```bash
cd "Aura Living Admin App"
flutter pub get
flutter run
```

### Code Quality & Static Analysis
Both applications adhere to strict Dart/Flutter linting rules (`flutter_lints 6.0.0`) with 0 analyzer issues:
```bash
cd "Aura Living Mobile App" && flutter analyze
cd "../Aura Living Admin App" && flutter analyze
```

---

## 🌐 References
- **Live Web Platform**: [https://aura-minimalist-e-commerce.vercel.app/](https://aura-minimalist-e-commerce.vercel.app/)
- **Reference Web Repository**: [https://github.com/raihanbiswas2006/Aura-Minimalist-E-Commerce-Platform](https://github.com/raihanbiswas2006/Aura-Minimalist-E-Commerce-Platform)
