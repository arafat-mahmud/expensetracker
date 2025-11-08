# Migration Guide - Debit/Credit System

## Issue Fixed: Null Type Error

### Problem
After updating to the new debit/credit system, existing users with saved expense data encountered this error:
```
_TypeError (type 'Null' is not a subtype of type 'String' in type cast)
```

### Root Cause
The new `type` field was added to the `Expense` model to support income/credit tracking. Existing expense data in the Hive database didn't have this field, causing a null reference error when the app tried to load old data.

### Solution Applied
Made the `type` field nullable and added proper default handling:

1. **Field Declaration**: Changed from `String type` to `String? type`
2. **Constructor**: Added null coalescing: `type = type ?? 'debit'`
3. **Getters**: Safe null handling in `isDebit` and `isCredit` properties
4. **Default Behavior**: All existing expenses are automatically treated as 'debit' (expenses)

### What This Means for Users

**Backward Compatibility:**
- ✅ All your existing expense data will work perfectly
- ✅ Old expenses are automatically treated as "debit" (expense) transactions
- ✅ No data loss or corruption
- ✅ Seamless migration - no user action required

**Going Forward:**
- All new expenses will have `type = 'debit'`
- All new income entries will have `type = 'credit'`
- The app correctly distinguishes between income and expenses

### Testing the Fix

After updating, verify everything works:

1. **Open the app** - Should load without errors
2. **Check Dashboard** - Your old expenses should display correctly
3. **View History** - All previous expenses should be visible
4. **Add new expense** - Should work normally
5. **Add new income** - New feature should work
6. **Check Balance** - Should calculate correctly (may show negative if only expenses exist)

### Technical Details

**Before (Caused Error):**
```dart
@HiveField(6)
String type; // Non-nullable - crashed on null

Expense({
  required this.type, // Required but old data had null
});
```

**After (Fixed):**
```dart
@HiveField(6)
String? type; // Nullable - accepts null from old data

Expense({
  String? type, // Optional parameter
}) : type = type ?? 'debit'; // Default to 'debit' if null
```

**Safe Getters:**
```dart
bool get isDebit => (type ?? 'debit') == 'debit';
bool get isCredit => (type ?? 'debit') == 'credit';
```

### Database Schema Evolution

**Version 1 (Old):**
- Fields 0-5: id, title, category, amount, date, note
- Field 6: Not present

**Version 2 (New):**
- Fields 0-5: id, title, category, amount, date, note
- Field 6: type (nullable String, defaults to 'debit')

Hive automatically handles this schema evolution gracefully with our nullable field approach.

### Common Questions

**Q: Will my balance show negative after the update?**
A: Yes, if you only had expenses before (no income tracked). This is correct - it shows you've spent money without recording income.

**Q: How do I fix a negative balance?**
A: Add your income using the new "Add Income" button. Record your salary, business income, etc.

**Q: Are my old expenses still there?**
A: Yes! All your historical data is preserved and works exactly as before.

**Q: What if I still see errors?**
A: Try these steps:
1. Completely close and restart the app
2. Clear app cache (if possible)
3. If persists, you may need to clear app data (backup to Google Drive first!)

**Q: Should I backup my data?**
A: Always a good idea! Use Settings → "Backup to Google Drive" before major updates.

### Developer Notes

If you're maintaining this code or adding new fields:

1. **Always make new fields nullable** for Hive models with existing data
2. **Provide sensible defaults** in the constructor initializer list
3. **Use null-coalescing operators** in getters/methods that use the field
4. **Test with existing database** before releasing
5. **Regenerate adapters** after model changes: `dart run build_runner build --delete-conflicting-outputs`

### Verification Checklist

✅ Hive adapters regenerated with nullable type field  
✅ Default value handling in constructor  
✅ Null-safe getters for type checking  
✅ Backward compatible with old data  
✅ No breaking changes for existing functionality  
✅ All new features work with migrated data  

---

**Update Applied:** November 8, 2025  
**Status:** ✅ Fixed and Tested  
**Impact:** Zero data loss, full backward compatibility
