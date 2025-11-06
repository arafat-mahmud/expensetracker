# 🚀 SmartBudget Quick Start Guide

## Installation & Running

### Step 1: Install Dependencies
```bash
flutter pub get
```

### Step 2: Generate Hive Adapters (IMPORTANT!)
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```
*This generates the `expense_model.g.dart` file needed for Hive database*

### Step 3: Run the App
```bash
flutter run
```

## First Time Usage

1. **Set Your Budget**
   - Open the app
   - Go to Settings (bottom navigation)
   - Tap on "Monthly Budget" 
   - Enter your desired monthly spending limit (default: ৳10,000)

2. **Add Your First Expense**
   - Tap the "Add Expense" button (FAB) on Dashboard
   - Fill in:
     - Title (e.g., "Morning Breakfast")
     - Category (select from dropdown)
     - Amount (e.g., 250)
     - Date (tap to select)
     - Note (optional)
   - Tap "Save Expense"

3. **View Dashboard**
   - See your total monthly expense
   - View budget progress bar
   - Check category-wise breakdown
   - Analyze daily expense trends

4. **Browse History**
   - Go to History page (bottom navigation)
   - Search expenses
   - Filter by category
   - Edit or delete expenses

5. **Toggle Theme**
   - Go to Settings
   - Toggle "Dark Mode" switch
   - Theme changes instantly!

## App Navigation

```
Dashboard (Home)
   ├── Add Expense (FAB)
   ├── Category Cards → Category Report Page
   └── Month Selector (left/right arrows)

History
   ├── Search Bar
   ├── Category Filters
   └── Expense Cards → Edit/Delete

Settings
   ├── Dark Mode Toggle
   ├── Monthly Budget
   ├── Clear All Data
   └── About App
```

## Tips & Tricks

- **Month Navigation**: Use left/right arrows on Dashboard to view different months
- **Quick Edit**: Tap expense card in History to edit
- **Category Report**: Tap any category card on Dashboard for detailed breakdown
- **Search**: Use search bar in History to find expenses by title, category, or note
- **Budget Tracking**: Green = within budget, Red = over budget

## Troubleshooting

### Issue: App crashes on first run
**Solution**: Make sure you ran the build_runner command to generate Hive adapters

### Issue: Charts not showing
**Solution**: Add some expenses first! Charts need data to display

### Issue: Theme not persisting
**Solution**: Hive is automatically saving theme preference, restart app if issue persists

## Testing the App

Run unit tests:
```bash
flutter test
```

## Building for Production

### Android APK
```bash
flutter build apk --release
```
*Output: `build/app/outputs/flutter-apk/app-release.apk`*

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## Sample Data for Testing

Try adding these sample expenses:
1. **Electricity Bill**: ⚡ Electricity, ৳1500
2. **Internet**: 🌐 Internet, ৳800
3. **Grocery Shopping**: 🛒 Grocery, ৳2500
4. **Uber Ride**: 🚗 Transport, ৳350
5. **Misc Items**: 💰 Other, ৳500

## File Structure at a Glance

```
lib/
├── main.dart                     # Start here
├── models/expense_model.dart     # Data structure
├── providers/                    # State management
├── services/hive_service.dart    # Database operations
├── screens/                      # All pages
└── widgets/                      # Reusable components
```

## Need Help?

- Check the main README.md for detailed documentation
- All code is well-commented
- Feel free to modify categories, colors, or features!

---

**Enjoy tracking your expenses! 💰✨**
