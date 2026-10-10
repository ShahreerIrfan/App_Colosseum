#!/usr/bin/env bash
# ==============================================================================
# Colosseum Audio Tour Guide — Build & Distribution Script
# Path: project/ColosseumClient/sync_release.sh
# ==============================================================================
set -euo pipefail

CLIENT_DIR="/mnt/503ADFEC3ADFCD5A/code/Android/Colosseum/project/ColosseumClient"
RELEASE_DIR="/mnt/503ADFEC3ADFCD5A/code/Android/Colosseum/release"
VERSION=$(grep 'version: ' "${CLIENT_DIR}/pubspec.yaml" | awk '{print $2}' | cut -d'+' -f1)
BUILD_NUM=$(grep 'version: ' "${CLIENT_DIR}/pubspec.yaml" | awk '{print $2}' | cut -d'+' -f2)
TARGET_APK_NAME="colosseum-guide-v${VERSION}-${BUILD_NUM}-universal-release.apk"
CANONICAL_APK_NAME="colosseum-guide-v${VERSION}-universal-release.apk"

echo "========================================================"
echo " Starting Colosseum Release Pipeline v${VERSION}+${BUILD_NUM}"
echo "========================================================"

cd "${CLIENT_DIR}"

# Step 1: Pre-flight Quality Assurance
echo ">> Running Flutter Analyze..."
flutter analyze

echo ">> Running Flutter Test Suite..."
flutter test

# Step 2: Clean & Compile Universal APK
echo ">> Building Universal Release APK..."
flutter clean
flutter pub get
flutter build apk --release --no-tree-shake-icons

# Step 3: Stage Distribution Artifact to release directory
echo ">> Syncing distribution artifact to ${RELEASE_DIR}..."
mkdir -p "${RELEASE_DIR}"
rm -f "${RELEASE_DIR}"/*.apk "${RELEASE_DIR}"/SHA256SUMS.txt

cp "${CLIENT_DIR}/build/app/outputs/flutter-apk/app-release.apk" \
   "${RELEASE_DIR}/${TARGET_APK_NAME}"

cp "${CLIENT_DIR}/build/app/outputs/flutter-apk/app-release.apk" \
   "${RELEASE_DIR}/${CANONICAL_APK_NAME}"

# Step 4: Generate Checksums
cd "${RELEASE_DIR}"
sha256sum "${TARGET_APK_NAME}" "${CANONICAL_APK_NAME}" > SHA256SUMS.txt

echo "========================================================"
echo " SUCCESS! Artifact deployed to:"
echo " ${RELEASE_DIR}/${TARGET_APK_NAME}"
echo " ${RELEASE_DIR}/${CANONICAL_APK_NAME}"
echo " SHA256:"
cat SHA256SUMS.txt
echo "========================================================"
