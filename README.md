# Blockchain-Enabled-QR-authentication-system-for-counterfeit-product-detection-in-online-markets
Enterprise-grade anti-counterfeiting system integrating Flask, Flutter, and Blockchain for secure product provenance.
An enterprise-grade anti-counterfeiting and provenance tracking system that integrates **Web2 infrastructure (Python/Flask, Flutter)** with **Web3 technology (Blockchain)** to prevent product forgery in e-commerce markets.

---

##  Key Features

- **Cryptographic Trust over Visual QR:** Unlike traditional QR codes that can be easily photocopied, this system signs product data using **Ed25519 Digital Signatures**.
- **Immutable Ledger Verification:** Product provenance and hash footprints are permanently anchored to the blockchain via Smart Contracts.
- **Replay Attack Prevention:** Enforces a rigid **Challenge-Response protocol** with cryptographic `nonces` during ownership transfers to ensure a QR code cannot be reused for fake products.
- **Secure Hardware Storage:** Utilizes `FlutterSecureStorage` on mobile devices to protect cryptographic private keys, ensuring they never leave the user's device.
- **Comprehensive Admin Dashboard:** Real-time system logs, dynamic statistics tracking, and interactive QR generation tools.

---

##  System Architecture & Tech Stack

The architecture is split into three main, loosely coupled components:

1. **qr_backend (Flask API):**
   - **Language:** Python
   - **Libraries:** Flask, PyNaCl (for Ed25519), Web3.py, SQLite
   - **Role:** Generates nonces, builds canonical JSON payloads, handles business logic, and communicates with the blockchain.

2. **Mobile Client (Admin App):**
   - **Framework:** Flutter & Dart
   - **Libraries:** flutter_secure_storage, http, crypto
   - **Role:** Secure identity management, secure login handling, dynamic QR code rendering, and system activity logging.

3. **Decentralized Layer (Blockchain):**
   - **Network:** Ethereum (Ganache/Dev-chain)
   - **Role:** Acts as the ultimate single source of truth for genuine product verification and history tracking.

---

##  Repository Structure

```text
├──  backend/               # Python Flask API & Blockchain Service
├──  admin_mobile_app/      # Flutter Admin Dashboard Application
├──  smart_contracts/       # Solidity Smart Contracts for product tracking
└── README.md                 # Main Documentation
