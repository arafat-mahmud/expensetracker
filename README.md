# 💰 Expense Tracker - Personal Expense Tracker# expensetracker



A modern, feature-rich Flutter app for tracking daily expenses with beautiful charts, category-wise analysis, and budget management.A new Flutter project.



## 📱 Features## Getting Started



### 1. **Dashboard Page**This project is a starting point for a Flutter application.

- 📊 Monthly expense overview with total amount

- 🥧 Category-wise expense breakdown (Pie Chart)A few resources to get you started if this is your first Flutter project:

- 📈 Daily expense trend visualization (Bar Chart)

- 💵 Budget progress indicator with visual feedback- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)

- 📅 Month/Year filter to view historical data- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

- Quick access to add new expenses via FAB

For help getting started with Flutter development, view the

### 2. **Add/Edit Expense**[online documentation](https://docs.flutter.dev/), which offers tutorials,

- ✏️ Add new expenses with detailed informationsamples, guidance on mobile development, and a full API reference.

- 📝 Fields: Title, Category, Amount, Date, Note
- 🏷️ 5 predefined categories:
  - ⚡ Electricity
  - 🌐 Internet
  - 🛒 Grocery
  - 🚗 Transport
  - 💰 Other
- ✅ Form validation
- 📅 Date picker integration
- 🔄 Edit existing expenses

### 3. **History Page**
- 📜 Complete list of all expenses
- 🔍 Search functionality (title, category, note)
- 🏷️ Filter by category
- ✏️ Quick edit and delete actions
- 📱 Swipe gestures for better UX

### 4. **Category Report Page**
- 📊 Detailed view of expenses per category
- 💵 Total amount spent in each category
- 📈 Transaction count
- 🎨 Color-coded for easy identification
- ✏️ Edit or delete expenses from category view

### 5. **Settings Page**
- 🌓 Light/Dark theme toggle
- 💰 Monthly budget configuration
- 🗑️ Clear all data option
- ℹ️ App information and version

### 6. **Budget Management**
- 🎯 Set monthly spending limit
- 📊 Visual progress bar showing budget usage
- ⚠️ Color-coded warnings when over budget
- 💚 Green indicator when within budget
- 🔴 Red indicator when budget exceeded

## 🏗️ Project Structure

```
lib/
├── main.dart                      # App entry point with providers setup
├── models/
│   ├── expense_model.dart         # Expense data model with Hive annotations
│   └── expense_model.g.dart       # Generated Hive adapter
├── providers/
│   ├── expense_provider.dart      # Expense state management
│   ├── theme_provider.dart        # Theme state management
│   └── budget_provider.dart       # Budget state management
├── services/
│   └── hive_service.dart          # Local database operations
├── screens/
│   ├── dashboard_page.dart        # Home screen with charts
│   ├── add_expense_page.dart      # Add/Edit expense form
│   ├── history_page.dart          # All expenses list
│   ├── category_report_page.dart  # Category-specific expenses
│   └── settings_page.dart         # App settings
└── widgets/
    ├── expense_card.dart          # Reusable expense item card
    ├── category_pie_chart.dart    # Category distribution chart
    └── daily_bar_chart.dart       # Daily expense trend chart
```

## 🛠️ Technologies Used

- **Flutter SDK**: ^3.5.4
- **State Management**: Provider (^6.1.1)
- **Local Database**: Hive (^2.2.3) + Hive Flutter (^1.1.0)
- **Charts**: FL Chart (^0.66.0)
- **Date Formatting**: Intl (^0.19.0)
- **Code Generation**: build_runner + hive_generator

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.5.4 or higher
- Dart SDK
- Android Studio / VS Code with Flutter extensions
- iOS Simulator / Android Emulator / Physical device

### Installation

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd expensetracker
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate Hive adapters**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Build for Production

**Android APK:**
```bash
flutter build apk --release
```

**iOS:**
```bash
flutter build ios --release
```

**Web:**
```bash
flutter build web --release
```

## 📊 Database Schema

### Expense Model
```dart
{
  id: String              // Unique identifier
  title: String           // Expense title
  category: String        // Category (Electricity, Internet, etc.)
  amount: double          // Expense amount
  date: DateTime          // Transaction date
  note: String            // Optional note
}
```

### Settings Storage
- `monthlyBudget`: double
- `isDarkMode`: bool

## 🎨 Design Features

- **Material 3 Design**: Modern UI with Material You principles
- **Responsive Layout**: Optimized for various screen sizes
- **Pastel Color Scheme**: Soft, eye-friendly colors
- **Dark/Light Theme**: Complete theme support
- **Smooth Animations**: Polished user experience
- **Card-based UI**: Clean, organized information display

## 📈 Data Visualization

### Pie Chart
- Shows percentage distribution of expenses across categories
- Color-coded segments with category icons
- Interactive tooltips

### Bar Chart
- Displays daily spending trends for the month
- X-axis: Days of the month
- Y-axis: Expense amount
- Interactive tooltips showing exact amounts

## 🔒 Data Persistence

All data is stored locally using **Hive**, a fast, lightweight NoSQL database:
- No internet required
- Encrypted storage support
- Fast read/write operations
- Minimal storage footprint

## 🧪 Testing

Run tests:
```bash
flutter test
```

## 📝 TODO / Future Enhancements

- [ ] Export data to CSV/Excel
- [ ] Backup and restore functionality
- [ ] Multiple currency support
- [ ] Recurring expense tracking
- [ ] Receipt photo attachment
- [ ] Cloud sync (Firebase/Google Drive)
- [ ] Budget alerts and notifications
- [ ] Weekly/Monthly expense reports
- [ ] Expense comparison charts (month-over-month)
- [ ] Custom category creation

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

## 👨‍💻 Developer

Created with ❤️ using Flutter

## 📞 Support

For issues, questions, or suggestions, please open an issue on GitHub.

---

**Happy Budgeting! 💰📊**

## 🆕 Cloud Features (NEW!)

### 🔐 Google Sign-In Authentication
- Secure login with Google account
- User profile with photo and email
- OAuth 2.0 authentication

### ☁️ Automatic Cloud Sync
- **Firestore Integration**: All expenses automatically sync to Cloud Firestore
- **Real-time Backup**: Data backed up on every change
- **Auto-Sync Toggle**: Enable/disable automatic cloud sync
- **Manual Sync**: Force sync all expenses with one tap

### 📁 Google Drive Backup
- **Automatic Backups**: Save complete data to Google Drive
- **"Expense Tracker" Folder**: Organized backup location
- **One-Click Backup**: Manual backup button in Settings
- **Easy Restore**: Recover all data from Drive backup
- **Backup Timestamps**: See when last backup was created

### 🔄 Data Synchronization
- Local-first architecture (works offline)
- Seamless cloud sync when online
- Cross-device data access
- Secure and encrypted storage

📖 **Setup Guide**: See `FIREBASE_SETUP.md` for complete Firebase configuration
📋 **New Features**: See `NEW_FEATURES.md` for detailed feature documentation
