<p align="center">
  <img src="assets/images/nexalock-icon.png" alt="NexaLock Logo" width="120" />
</p>

<h1 align="center">NexaLock</h1>

<p align="center">
  <strong>Secure Smart Door Lock Ecosystem</strong><br/>
  A hybrid IoT + Mobile solution built for seamless physical security.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.11-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.11-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Firebase-RTDB%20%7C%20Auth%20%7C%20Firestore-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase" />
  <img src="https://img.shields.io/badge/ESP32-Arduino%20C++-E7352C?style=for-the-badge&logo=espressif&logoColor=white" alt="ESP32" />
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License" />
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-lightgrey?style=flat-square" alt="Platform" />
  <img src="https://img.shields.io/badge/Status-Production%20Ready-brightgreen?style=flat-square" alt="Status" />
  <img src="https://img.shields.io/badge/Version-1.0.0-blue?style=flat-square" alt="Version" />
</p>

---

## 📖 Overview

**NexaLock** is a full-stack smart door lock ecosystem that bridges a **Flutter mobile application** with an **ESP32 microcontroller** through **Firebase Realtime Database**. It provides dual-control access via both a premium mobile interface and a physical MFRC522 RFID module, delivering enterprise-grade security with real-time audit logging, OTA firmware updates, and robust offline failover.

The system is designed with a security-first mindset: the ESP32 firmware operates a non-blocking execution loop that guarantees physical access even during network outages, while the Flutter app provides centralized administration, user management, and secure audit trails through Cloud Firestore.

---

## ✨ Key System Features

### 🔐 Hybrid Authentication
Dual-control access combining a premium Flutter mobile interface with a physical **MFRC522 RFID** reader module. Users can unlock via the app remotely or tap an authorized RFID card at the door — both methods are logged and audited independently.

### ⚡ Instant Offline Mode
Zero-blocking hardware execution loop. If Wi-Fi connectivity drops, the ESP32 instantly boots into a localized **Offline Mode**, allowing physical Master Card bypass without system freezing or lockout. Security is never compromised by network instability.

### 📡 Asynchronous Wi-Fi Portal
Background Captive Portal execution via `WiFiManager` in **Non-Blocking** mode. On first boot or Wi-Fi credential loss, the ESP32 broadcasts a `NexaLock_Setup` configuration hotspot without interrupting local lock services — users configure Wi-Fi while the door remains fully operational.

### 💓 Real-time UTC Heartbeat
Instant device-stale detection on the Flutter dashboard using **Google server-value UTC timestamps** (`ServerValue.timestamp`) to eliminate local timezone mismatches. If the ESP32 heartbeat goes stale for >40 seconds, the app automatically enters a protected offline state, blocking remote commands to prevent ghost unlocks.

### 🛡️ Ghost Unlock Prevention
The app intercepts remote unlock attempts when the device is detected as offline. Instead of writing a stale command to RTDB (which the ESP32 would execute upon reboot), the system aborts the command entirely and logs the attempt as a system `ERROR` in the audit trail.

### 📋 Secure Audit Logging
Automatic logging of `SUCCESS`, `DENIED`, and network `ERROR` attempts synced securely with **Cloud Firestore**. Every access event captures the user identity, authentication method, timestamp, and result — providing a complete forensic trail for security review.

### 🔄 OTA Firmware Updates
Administrators can push Over-The-Air firmware updates directly from the Flutter app's Profile screen. The firmware URL and version are written to RTDB, and the ESP32 downloads and flashes the update autonomously.

---

## 🏗️ System Architecture

```
┌─────────────────────┐         ┌──────────────────────┐
│   Flutter Mobile     │◄───────►│   Firebase Cloud     │
│   Application        │  HTTPS  │                      │
│                      │         │  ┌── Auth ──────────┐ │
│  • Dashboard         │         │  │  Email/Password  │ │
│  • User Management   │         │  └──────────────────┘ │
│  • Access History    │         │  ┌── Firestore ─────┐ │
│  • Profile & OTA     │         │  │  Users, Logs     │ │
│  • Settings          │         │  └──────────────────┘ │
│  • Notifications     │         │  ┌── RTDB ──────────┐ │
└─────────────────────┘         │  │  door/, device/, │ │
                                │  │  rfid/, ota/      │ │
                                │  └──────────────────┘ │
                                └──────────┬───────────┘
                                           │ WSS
                                ┌──────────▼───────────┐
                                │   ESP32 NodeMCU      │
                                │   Firmware            │
                                │                       │
                                │  • MFRC522 RFID       │
                                │  • I2C LCD 16x2       │
                                │  • Relay Module       │
                                │  • Buzzer             │
                                │  • LittleFS Storage   │
                                │  • WiFiManager AP     │
                                └───────────────────────┘
```

---

## 🛠️ Tech Stack

### Mobile Front-end
| Technology | Purpose |
|---|---|
| **Flutter 3.11** | Cross-platform UI framework |
| **Dart 3.11** | Application language |
| **Material 3** | Design system with custom `AppTheme` tokens |
| **Google Fonts** | Hanken Grotesk (headings) + Inter (body) |
| **shadcn_ui** | Component library |
| **shared_preferences** | Local preference persistence |
| `AutomaticKeepAliveClientMixin` | Tab state preservation across navigation |

### Cloud Infrastructure
| Service | Purpose |
|---|---|
| **Firebase Authentication** | Email/password user auth with admin approval flow |
| **Firebase Realtime Database** | Bidirectional IoT device communication (door control, telemetry, RFID scanning) |
| **Cloud Firestore** | User profiles, access logs, structured data |

### Hardware & Firmware
| Component | Purpose |
|---|---|
| **ESP32 NodeMCU** | Main microcontroller |
| **Arduino C++** | Firmware language |
| **MFRC522** | RFID/NFC card reader (SPI) |
| **LiquidCrystal_I2C** | 16×2 LCD display (I2C) |
| **LittleFS** | Secure credential flash storage |
| **ArduinoJson** | JSON serialization for Firebase payloads |
| **Firebase_ESP_Client** | ESP32 Firebase RTDB integration |
| **WiFiManager** | Captive Portal for Wi-Fi configuration |

---

## 🔌 Hardware Wiring Architecture

### MFRC522 RFID Reader (SPI)
| MFRC522 Pin | ESP32 GPIO |
|---|---|
| SDA (SS) | GPIO 5 |
| SCK | GPIO 18 |
| MOSI | GPIO 23 |
| MISO | GPIO 19 |
| RST | GPIO 27 |
| 3.3V | 3.3V |
| GND | GND |

### I2C LCD 16×2
| LCD Pin | ESP32 GPIO |
|---|---|
| SDA | GPIO 21 |
| SCL | GPIO 22 |
| VCC | 5V (Vin) |
| GND | GND |

### Actuators
| Component | ESP32 GPIO | Notes |
|---|---|---|
| **Relay Module** (Door Lock) | GPIO 26 | Active LOW — controls solenoid lock |
| **Buzzer** | GPIO 25 | Access granted/denied audio feedback |
| **Onboard LED** | GPIO 2 | Heartbeat status indicator |

---

## 📱 Application Screens

| Screen | Description |
|---|---|
| **Login** | Email/password auth with registration request flow and admin approval gate |
| **Dashboard** | Live lock status indicator, remote lock/unlock, Wi-Fi & battery telemetry |
| **Access History** | Chronological audit log with search, filtering, and swipe-to-delete |
| **User Management** | RFID card assignment/replacement, user registration, access revocation |
| **Profile** | Name editing, security alerts, device firmware OTA, quick preferences |
| **Settings** | Password update, custom About dialog, sign-out with confirmation |
| **Notifications** | Activity feed with Personal and System tabs |

---

## 🚀 Installation & Setup

### Prerequisites
- **Flutter SDK** ≥ 3.11.5
- **Dart SDK** ≥ 3.11.5
- **Firebase CLI** & **FlutterFire CLI**
- **Android Studio** or **VS Code** with Flutter extension
- **Arduino IDE** or **PlatformIO** (for ESP32 firmware)

### Flutter Mobile App

```bash
# 1. Clone the repository
git clone https://github.com/<your-username>/NexaLock.git
cd NexaLock/nexalock

# 2. Install dependencies
flutter pub get

# 3. Configure Firebase (generate your own credentials)
#    Place your google-services.json in android/app/
#    Place your GoogleService-Info.plist in ios/Runner/
#    Run FlutterFire CLI to generate lib/firebase_options.dart:
flutterfire configure

# 4. Run in debug mode
flutter run

# 5. Build production APK
flutter build apk --release
```

> **⚠️ Important:** The `google-services.json`, `firebase_options.dart`, and `firebase.json` files are excluded from this repository via `.gitignore` for security. You must generate your own Firebase credentials using `flutterfire configure` after creating a Firebase project.

### ESP32 Firmware

1. **Flash the firmware** to your ESP32 using Arduino IDE or PlatformIO.
2. **First Boot:** The ESP32 will automatically broadcast a Wi-Fi hotspot named `NexaLock_Setup`.
3. **Connect** to the hotspot from your phone and configure your home Wi-Fi credentials through the Captive Portal.
4. **Automatic Reconnect:** Once configured, the ESP32 stores credentials in LittleFS flash memory and reconnects automatically on subsequent boots.
5. **Offline Fallback:** If the configured Wi-Fi is unavailable, the ESP32 operates in Offline Mode with Master Card RFID access while periodically re-broadcasting the setup portal in the background.

---

## 🔒 Security Model

| Layer | Implementation |
|---|---|
| **Authentication** | Firebase Auth with admin-gated registration (new users require approval) |
| **Registration Isolation** | Secondary `FirebaseApp` instance prevents auto-login flicker |
| **Ghost Unlock Prevention** | UTC heartbeat watchdog blocks remote commands when device is offline |
| **Credential Storage** | Firebase keys excluded from VCS; ESP32 Wi-Fi credentials stored in encrypted LittleFS |
| **Audit Trail** | Every access attempt (success, denied, error) logged to Firestore with user identity and timestamp |
| **Card Revocation** | Admin can revoke RFID cards instantly — removed from RTDB `allowed_cards` in real-time |

---

## 📂 Project Structure

```
nexalock/
├── lib/
│   ├── main.dart                    # App entry point & AuthWrapper
│   ├── firebase_options.dart        # 🔒 GITIGNORED — Firebase credentials
│   ├── models/
│   │   └── user_model.dart          # User data model
│   ├── screens/
│   │   ├── login_screen.dart        # Auth & registration
│   │   ├── home_screen.dart         # Dashboard & lock control
│   │   ├── history_screen.dart      # Access audit logs
│   │   ├── users_screen.dart        # User & RFID management
│   │   ├── profile_screen.dart      # Profile, OTA, preferences
│   │   ├── settings_screen.dart     # App settings & sign-out
│   │   ├── notifications_screen.dart # Activity feed
│   │   ├── main_nav_screen.dart     # Bottom navigation shell
│   │   └── forgot_password_screen.dart
│   ├── services/
│   │   ├── auth_service.dart        # Firebase Auth abstraction
│   │   ├── firestore_service.dart   # Firestore CRUD operations
│   │   └── realtime_db_service.dart # RTDB IoT communication
│   ├── theme/
│   │   └── app_theme.dart           # Material 3 design tokens
│   └── widgets/
│       └── custom_avatar.dart       # Reusable avatar component
├── android/
│   └── app/
│       └── google-services.json     # 🔒 GITIGNORED — Android Firebase config
├── assets/
│   └── images/
│       └── nexalock-icon.png        # App icon
├── pubspec.yaml                     # Dependencies & configuration
└── .gitignore                       # Hardened security rules
```

---

## 👥 Contributors

- **Hilma** — Full-Stack Developer (Flutter + Firebase + ESP32 Firmware)

---

## 📄 License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.

---

<p align="center">
  <sub>Built with ❤️ using Flutter, Firebase, and ESP32</sub><br/>
  <sub>© 2026 NexaLock. All rights reserved.</sub>
</p>
