#!/usr/bin/env bash
# 아카이브 → App Store용 .ipa 추출. 빌드 번호는 git 커밋 수로 자동 증가(단조 증가 보장).
# 서명: Local.xcconfig의 DEVELOPMENT_TEAM(자동 서명). 업로드는 마지막 안내 참고.
set -euo pipefail
cd "$(dirname "$0")/.."   # 저장소 루트로 이동

SCHEME="LivingRecord"
PROJECT="LivingRecord/LivingRecord.xcodeproj"
BUILD_DIR="build"
ARCHIVE="$BUILD_DIR/LivingRecord.xcarchive"
EXPORT_DIR="$BUILD_DIR/export"
BUILD_NUMBER="$(git rev-list --count HEAD)"   # 커밋 수 = 단조 증가 빌드 번호

echo "▶︎ 아카이브 (빌드 $BUILD_NUMBER)…"
xcodebuild archive \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE" \
  CURRENT_PROJECT_VERSION="$BUILD_NUMBER"

echo "▶︎ .ipa 추출…"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist scripts/exportOptions.plist

echo "✓ 완료 → $EXPORT_DIR/"
echo
echo "업로드(택1):"
echo "  • Xcode Organizer 또는 Transporter 앱에서 .ipa 업로드(가장 쉬움)"
echo "  • CLI: xcrun altool --upload-app -f \"$EXPORT_DIR/LivingRecord.ipa\" -t ios \\"
echo "         --apiKey <KEY_ID> --apiIssuer <ISSUER_ID>   # App Store Connect API 키 필요"
