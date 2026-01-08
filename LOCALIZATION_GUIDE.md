# Multi-Language Support Documentation

## Overview
This expense tracker app now supports multiple languages (English and Bangla). Users can easily switch between languages from the Settings page, and all UI text and PDF statements will be displayed in the selected language.

## Features

### 1. **Language Support**
- **English** (Default)
- **বাংলা (Bangla)**
- Easy to add more languages in the future

### 2. **What Gets Localized**
- All UI text and labels
- Navigation menu items
- Button labels
- Dialog messages
- Category names
- Date formats
- Number formats (including Bangla digits: ০১২৩৪৫৬৭৮৯)
- PDF statements (complete localization including fonts)

### 3. **How to Switch Language**

**For Users:**
1. Open the app
2. Go to **Settings** page
3. Under **Appearance** section, tap on **Language**
4. Select your preferred language (English or বাংলা)
5. The app will immediately update to the selected language

**Programmatically:**
```dart
final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
await languageProvider.changeLanguage('bn'); // for Bangla
await languageProvider.changeLanguage('en'); // for English
```

### 4. **Using Localizations in Code**

**Basic Usage:**
```dart
import '../l10n/app_localizations.dart';

// In your widget
@override
Widget build(BuildContext context) {
  final localizations = AppLocalizations.of(context);
  
  return Text(localizations.dashboard); // Will show "Dashboard" or "ড্যাশবোর্ড"
}
```

**Common Examples:**
```dart
// Button text
ElevatedButton(
  onPressed: () {},
  child: Text(localizations.save), // "Save" or "সংরক্ষণ"
)

// AppBar title
AppBar(
  title: Text(localizations.settings), // "Settings" or "সেটিংস"
)

// Dialog
AlertDialog(
  title: Text(localizations.confirmClearData),
  actions: [
    TextButton(
      onPressed: () => Navigator.pop(context),
      child: Text(localizations.cancel),
    ),
    TextButton(
      onPressed: () {},
      child: Text(localizations.ok),
    ),
  ],
)
```

### 5. **Formatting Numbers and Dates**

**Using LocalizationHelper:**
```dart
import '../utils/localization_helper.dart';

// Format currency
final amount = 1234.56;
final formatted = LocalizationHelper.formatCurrency(
  amount, 
  languageProvider.languageCode
); // "1234.56" or "১২৩৪.৫৬"

// Format date
final date = DateTime.now();
final formattedDate = LocalizationHelper.formatDate(
  date,
  languageProvider.languageCode
); // "07/01/2026" or "০৭/০১/২০২৬"

// Get localized category name
final category = LocalizationHelper.getCategoryName(
  'food',
  localizations
); // "Food" or "খাবার"
```

### 6. **PDF Statement Localization**

PDF statements are fully localized:
- All text in the selected language
- Numbers in local format (Bangla digits for Bangla)
- Dates in local format
- Proper Bangla font rendering (Noto Sans Bengali)

The PDF generation automatically uses the current language setting:
```dart
await LocalizedStatementService.generateLocalizedPdfStatement(
  startDate: startDate,
  endDate: endDate,
  transactions: transactions,
  totalIncome: totalIncome,
  totalExpense: totalExpense,
  balance: balance,
  context: context,
  languageCode: languageProvider.languageCode,
);
```

## Architecture

### File Structure
```
lib/
├── l10n/
│   └── app_localizations.dart          # All translations
├── providers/
│   └── language_provider.dart          # Language state management
├── services/
│   └── localized_statement_service.dart # PDF generation with localization
├── utils/
│   └── localization_helper.dart        # Helper functions
└── main.dart                           # App setup with localization
```

### Key Components

**1. AppLocalizations**
- Abstract class defining all translatable strings
- `EnglishLocalizations` - English translations
- `BanglaLocalizations` - Bangla translations
- Easy to extend for more languages

**2. LanguageProvider**
- Manages current language state
- Persists language preference using Hive
- Notifies listeners on language change

**3. LocalizedStatementService**
- Generates PDF statements in the selected language
- Loads appropriate fonts (Noto Sans Bengali for Bangla)
- Converts numbers and dates to local format

**4. LocalizationHelper**
- Utility functions for formatting
- Number conversion (English ↔ Bangla digits)
- Date formatting
- Category name translation

## Adding a New Language

To add a new language (e.g., Hindi):

**Step 1: Create Translation Class**
```dart
// In lib/l10n/app_localizations.dart

class HindiLocalizations extends AppLocalizations {
  @override
  String get appName => 'व्यय ट्रैकर';
  
  @override
  String get dashboard => 'डैशबोर्ड';
  
  // ... implement all abstract methods
}
```

**Step 2: Update Delegate**
```dart
// In AppLocalizationsDelegate

@override
bool isSupported(Locale locale) {
  return ['en', 'bn', 'hi'].contains(locale.languageCode);
}

@override
Future<AppLocalizations> load(Locale locale) async {
  switch (locale.languageCode) {
    case 'bn':
      return BanglaLocalizations();
    case 'hi':
      return HindiLocalizations();
    default:
      return EnglishLocalizations();
  }
}
```

**Step 3: Add Font (if needed)**
```yaml
# pubspec.yaml
fonts:
  - family: NotoSansHindi
    fonts:
      - asset: assets/fonts/NotoSansHindi-Regular.ttf
```

**Step 4: Update LanguageProvider**
```dart
List<Map<String, String>> get supportedLanguages => [
  {'code': 'en', 'name': 'English'},
  {'code': 'bn', 'name': 'বাংলা'},
  {'code': 'hi', 'name': 'हिंदी'},
];
```

**Step 5: Update Main App**
```dart
// In main.dart
supportedLocales: const [
  Locale('en'),
  Locale('bn'),
  Locale('hi'),
],
```

## Best Practices

1. **Always use localizations**
   - ❌ Don't: `Text('Settings')`
   - ✅ Do: `Text(localizations.settings)`

2. **Use language provider for formatting**
   ```dart
   final languageCode = Provider.of<LanguageProvider>(context).languageCode;
   ```

3. **Keep translation strings consistent**
   - Use same keys across all language classes
   - Keep strings short and meaningful

4. **Test with both languages**
   - Check UI layout with longer text (Bangla text is often longer)
   - Verify PDF generation in both languages
   - Test all dialogs and messages

5. **Handle fonts properly**
   - Use system fonts for languages that support them
   - Load custom fonts for special scripts (like Bangla)
   - Test font rendering in PDFs

## Available Translations

The app includes translations for:
- Common actions (save, cancel, delete, etc.)
- Navigation (dashboard, history, settings, etc.)
- Expense categories
- Budget management
- Authentication
- Data management
- PDF generation
- Error messages
- Success messages
- Days and months

## Technical Details

**Localization Dependencies:**
```yaml
dependencies:
  flutter_localizations:
    sdk: flutter
  intl: ^0.20.2
```

**Font Assets:**
```yaml
fonts:
  - family: NotoSansBengali
    fonts:
      - asset: assets/fonts/NotoSansBengali-Regular.ttf
      - asset: assets/fonts/NotoSansBengali-Bold.ttf
        weight: 700
```

**Supported Locales:**
- `en` - English (United States)
- `bn` - বাংলা (Bangladesh)

## Troubleshooting

**Issue: Text not translating**
- Solution: Make sure you're using `AppLocalizations.of(context)`
- Check that the key exists in all localization classes

**Issue: Bangla text not displaying in PDF**
- Solution: Verify font files are in `assets/fonts/`
- Run `flutter pub get` after adding fonts
- Check font is loaded in `LocalizedStatementService`

**Issue: Language not persisting**
- Solution: Ensure Hive is initialized before app starts
- Check settings box is being passed to LanguageProvider

**Issue: Numbers not converting to Bangla digits**
- Solution: Use `LocalizationHelper.formatNumber()` or `formatCurrency()`
- Ensure language code is passed correctly

## Future Enhancements

Potential improvements:
1. Add more languages (Hindi, Urdu, Tamil, etc.)
2. Region-specific number formats
3. Currency symbol based on language
4. RTL support for Arabic/Urdu
5. Automatic language detection based on device settings
6. Translation validation tools
7. Crowdsourced translations

## Support

For issues or questions:
- Check this documentation first
- Review code examples in the app
- Test with provided utility functions
- Ensure all dependencies are installed

---

**Last Updated:** January 2026
**Version:** 1.0.0
