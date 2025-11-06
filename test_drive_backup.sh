#!/bin/bash

# Google Drive Backup Test Script
# Run this to test if everything is working

echo "🚀 Testing Google Drive Backup Integration..."
echo ""

# Check if in correct directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: Run this script from the project root directory"
    echo "   cd /Users/sanon/expensetracker"
    exit 1
fi

echo "✅ In correct directory"
echo ""

# Check dependencies
echo "📦 Checking dependencies..."
if ! grep -q "googleapis:" pubspec.yaml; then
    echo "❌ Missing googleapis dependency"
    exit 1
fi
echo "✅ Dependencies OK"
echo ""

# Check google-services.json
echo "🔐 Checking google-services.json..."
if [ ! -f "android/app/google-services.json" ]; then
    echo "❌ Missing android/app/google-services.json"
    exit 1
fi
echo "✅ google-services.json found"
echo ""

# Get project info
PROJECT_ID=$(grep -o '"project_id": "[^"]*"' android/app/google-services.json | cut -d'"' -f4)
echo "📱 Project ID: $PROJECT_ID"
echo ""

# Check if Google Drive API is likely enabled (can't verify programmatically)
echo "⚠️  IMPORTANT: Manual Check Required"
echo ""
echo "Please verify at: https://console.cloud.google.com/apis/dashboard?project=$PROJECT_ID"
echo ""
echo "1. Is 'Google Drive API' enabled?"
echo "2. Is OAuth consent configured with Drive scope?"
echo "3. Is your SHA-1 fingerprint added to Firebase?"
echo ""

# Get SHA-1 fingerprint
echo "🔑 Your Debug SHA-1 Fingerprint:"
echo "Run this command and add it to Firebase Console:"
echo ""
echo "keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA1"
echo ""

# Clean and rebuild
echo "🧹 Would you like to clean and rebuild the project? (y/n)"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "Cleaning project..."
    flutter clean
    echo "Getting dependencies..."
    flutter pub get
    echo "✅ Clean and rebuild complete"
    echo ""
fi

echo "🎯 Next Steps:"
echo ""
echo "1. Enable Google Drive API at:"
echo "   https://console.cloud.google.com/apis/library/drive.googleapis.com?project=$PROJECT_ID"
echo ""
echo "2. Configure OAuth at:"
echo "   https://console.cloud.google.com/apis/credentials/consent?project=$PROJECT_ID"
echo ""
echo "3. Add SHA-1 to Firebase at:"
echo "   https://console.firebase.google.com/project/$PROJECT_ID/settings/general"
echo ""
echo "4. Run the app:"
echo "   flutter run"
echo ""
echo "5. Watch logs in another terminal:"
echo "   flutter logs | grep -E 'Drive|drive|Backup|backup'"
echo ""
echo "6. Test by adding an expense and checking Google Drive at:"
echo "   https://drive.google.com"
echo ""
echo "📚 For detailed instructions, read: ENABLE_GOOGLE_DRIVE.md"
echo ""
echo "✨ Your code is ready! Just complete the Google Cloud setup above."
