#!/bin/bash

# Script to remove build files from Git tracking
# This script removes build files from Git index without deleting them from filesystem

echo "🧹 Đang xóa các file build khỏi Git tracking..."

# Remove build directories from Git index
git rm -r --cached build/ 2>/dev/null || true
git rm -r --cached .dart_tool/ 2>/dev/null || true
git rm -r --cached ios/Pods/ 2>/dev/null || true
git rm -r --cached macos/Pods/ 2>/dev/null || true
git rm -r --cached android/.gradle/ 2>/dev/null || true
git rm -r --cached android/app/build/ 2>/dev/null || true
git rm -r --cached android/build/ 2>/dev/null || true

# Remove specific build files
git rm -r --cached "**/build/" 2>/dev/null || true
git rm -r --cached "**/.gradle/" 2>/dev/null || true
git rm -r --cached "**/Pods/" 2>/dev/null || true
git rm -r --cached "**/ephemeral/" 2>/dev/null || true

# Remove generated files
git rm --cached lib/generated_plugin_registrant.dart 2>/dev/null || true

# Remove Flutter generated files
git rm -r --cached ios/Flutter/ephemeral/ 2>/dev/null || true
git rm -r --cached macos/Flutter/ephemeral/ 2>/dev/null || true
git rm -r --cached linux/flutter/ephemeral/ 2>/dev/null || true
git rm -r --cached windows/flutter/ephemeral/ 2>/dev/null || true

# Remove build artifacts
find . -name "*.apk" -exec git rm --cached {} \; 2>/dev/null || true
find . -name "*.aab" -exec git rm --cached {} \; 2>/dev/null || true
find . -name "*.ipa" -exec git rm --cached {} \; 2>/dev/null || true
find . -name "*.app" -exec git rm --cached {} \; 2>/dev/null || true

echo "✅ Đã xóa các file build khỏi Git tracking"
echo ""
echo "📝 Các thay đổi đã được staged. Bạn có thể:"
echo "   1. Kiểm tra: git status"
echo "   2. Commit: git commit -m 'Remove build files from Git tracking'"
echo "   3. Push: git push"
echo ""
echo "⚠️  Lưu ý: Các file build vẫn tồn tại trên filesystem, chỉ bị xóa khỏi Git tracking."

