# Finance Ledger App

## 1. About This Application
Finance Ledger App is a modern, cross-platform ledger management solution built with Flutter. It enables businesses and individuals to manage categories, products, sales, expenses, transactions, and users efficiently, with a clean and intuitive UI. The app is powered by a Laravel backend API.

## 2. Features
- User authentication (login)
- Category, product, and user management
- Sales and expense ledger tracking
- Add, edit, delete, and view details for all entities
- Pull-to-refresh and search functionality
- Responsive design for Android, iOS, web, Windows, macOS, and Linux
- Robust error handling and modern UI

## 3. Prerequisites
- [Flutter](https://flutter.dev/docs/get-started/install) (3.x recommended)
- Dart SDK (comes with Flutter)
- The required backend API is provided by the [Finance Ledger API Laravel repository](https://github.com/pplcallmesatz/finance-ledger-web-api-backend/) (replace with your actual repo URL)
- See [`API_DOCUMENTATION.md`](API_DOCUMENTATION.md) for available endpoints and usage

## 4. Setup
### 4.1 Clone the Repository
```sh
git clone https://github.com/pplcallmesatz/finance-ledger-flutter.git
cd finance-ledger-app/ledger_app
```
### 4.2 Install Dependencies
```sh
flutter pub get
```
### 4.3 Add Assets
- Ensure `assets/logo.png` exists or replace with your own logo in the `assets/` folder.

### 4.4 Running the App
- **Android/iOS:**
  ```sh
  flutter run
  ```
- **Web:**
  ```sh
  flutter run -d chrome
  ```
- **Windows/macOS/Linux:**
  ```sh
  flutter run -d windows  # or macos/linux
  ```
> **Note:** This app is developed and tested with Flutter. Platform support may depend on your Flutter version and OS setup.

+### 4.5 Building for Release
+- **Android APK:**
+  ```sh
+  flutter build apk --release
+  ```
+- **iOS IPA:**
+  ```sh
+  flutter build ios --release
+  ```
+- **Web:**
+  ```sh
+  flutter build web
+  ```

## 5. Environment & Configuration
- API base URL is set in `lib/services/api_service.dart`.
- For HTTP APIs in development, configure Android/iOS network security as needed.
- For HTTPS APIs, ensure your certificate is valid and trusted.
- Update the API base URL to match your backend server.

## 6. Folder Structure
```
ledger_app/
  lib/                # Main Flutter app code
  assets/             # App images and assets
  android/            # Android platform code
  ios/                # iOS platform code
  web/                # Web platform code
  windows/            # Windows platform code
  macos/              # macOS platform code
  linux/              # Linux platform code
  test/               # Widget and unit tests
  API_DOCUMENTATION.md# API endpoint documentation
```

## 7. Contribution
Contributions are welcome! Please open issues or submit pull requests for improvements and bug fixes.

## 8. License
[MIT](LICENSE)

---

**Made with Flutter ❤️**

---

## Developer

**Name:** Satheesh Kumar S  
**Github Profile:** [github.com/pplcallmesatz](https://github.com/pplcallmesatz/)  
**Github Repo:** [github.com/pplcallmesatz/finance-ledger-flutter](https://github.com/pplcallmesatz/finance-ledger-flutter)  
**Email:** [satheeshssk@icloud.com](mailto:satheeshssk@icloud.com)  
**Instagram:** [instagram.com/pplcallmesatz](http://instagram.com/pplcallmesatz)

---

## Support

If you find this tool useful, consider supporting me:  
[![Buy Me a Coffee](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://www.buymeacoffee.com/satheeshdesign)

---

## Disclaimer

> This tool is fully generated using AI tools. Issues may be expected.  
> Please report bugs or contribute via pull requests! 



