# SpendMind 🧠💳

SpendMind is a smart, privacy-first, and highly automated personal finance management application built using Flutter. It helps users automatically track their expenses by parsing transaction SMS notifications, analyzing budget limits, and providing AI-powered financial coaching.

---

## 🚀 Key Features

*   **Auto-Track Expenses**: Automatically scans and parses transaction messages from popular banking channels and apps using a regex-based `SMSParserService`.
*   **Gemini Financial Coach**: An interactive AI financial coach powered by Google Gemini that analyzes your spending patterns, answers questions, and gives actionable savings recommendations.
*   **Interactive Spending Simulator**: Test "what-if" scenarios (e.g. cutting shopping by 20%) and view projected savings rates, trajectory over 12 months, and tailored recommendations.
*   **Custom Budgets & Alerts**: Set strict monthly budget limits for categories like Food, Shopping, Travel, and Subscriptions.
*   **Developer Mode & Simulator Panel**: Secure environment configurations for test seeding, SMS broadcasting emulation, and notification simulation.

---

## 📁 File Structure

The project has been cleaned up to follow a modular, single-layer architectural pattern under `lib/` for simplicity and performance:

```text
SpendMind/
├── assets/
│   └── images/
│       └── image.png             # Visual assets & screenshots
├── lib/
│   ├── models.dart               # Core data structures (Transaction, Budget, ChatMessage)
│   ├── hive_service.dart         # Local persistence layer (Hive database)
│   ├── parser_service.dart       # Local regex-based SMS parsing engine
│   ├── gemini_service.dart       # Gemini AI integration service
│   ├── theme.dart                # Premium dark-mode glassmorphic styling system
│   ├── main.dart                 # Application entry point
│   ├── main_navigation.dart      # Navigation shell and method-channel handler
│   ├── dashboard_screen.dart     # Home dashboard (Metrics, Charts, SMS Simulator)
│   ├── transactions_screen.dart  # Transaction history and manual logging dialog
│   ├── budgets_screen.dart       # Budget configuration list and progress meters
│   ├── coach_screen.dart         # Gemini AI Coach chat interface
│   ├── settings_screen.dart      # Profile, Gemini API configuration, and Developer Tools
│   └── simulator_screen.dart     # What-if scenario modeling and AI projection tool
└── test/
    ├── sms_parser_test.dart      # Unit tests verifying SMS Parsing rules
    └── widget_test.dart          # Environment verification checks
```

---

## 🛠️ Setup & Running

### Prerequisites
- Flutter SDK (v3.0.0+)
- Dart SDK (v3.0.0+)

### Installation
1.  Clone the repository and navigate to the project directory:
    ```bash
    cd SpendMind
    ```
2.  Install dependencies:
    ```bash
    flutter pub get
    ```
3.  Launch the app on an emulator or connected device:
    ```bash
    flutter run
    ```

### Running Tests
To verify SMS parsing regex and other environment components, execute:
```bash
flutter test
```

---

## 🛡️ Developer Mode Configuration

SpendMind features a built-in Developer Tools panel hidden from standard users.

1.  Navigate to **Settings**.
2.  Set the **Profile Email** to `your-email-id@gmail.com` (or any email registered in the allowed list).
3.  A **Developer Control Panel** will unlock in Settings, and a **TEST MODE** status badge will display on the Dashboard.
4.  Use the controls to generate fake transactions, broadcast simulated banking SMS texts, seed bulk mock data, and reset/clear all test transactions dynamically.
