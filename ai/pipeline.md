# Colosseum Audio Tour Guide Android release pipeline

Use this runbook to build, verify and distribute the Flutter Android client. Run the commands from `project/ColosseumClient` unless otherwise specified.

## Compatibility and release formats

| Item | Current project and verified release APK |
| --- | --- |
| Package ID | `com.example.colosseum_client` |
| Minimum Android | Android 7.0, API 24 |
| Compile and target SDK | API 36, supplied by the installed Flutter SDK |
| Native architectures in the Universal APK | `armeabi-v7a` (32-bit ARM), `arm64-v8a` (64-bit ARM), `x86_64` (64-bit Intel/AMD) |
| Direct distribution | Signed Universal APK |
| Google Play | Signed Android App Bundle (AAB) |

Universal means one file includes all three supported architectures. The phone still needs a compatible Android version and ABI, sufficient storage and permission to install from the chosen channel. APK installation and tour functionality are separate checks. Location, compass availability and local TTS voices affect navigation and narration after installation.

The inspected release APK passed signature verification, APK ZIP alignment and 16 KB ELF alignment for its 64-bit native libraries. Recheck the **new artifact** for every release, since a Flutter or plugin update can change its manifest and native libraries. See the [Flutter release guide](https://docs.flutter.dev/deployment/android) and [Android 16 KB compatibility guide](https://developer.android.com/guide/practices/page-sizes).

## Signing and versioning

- Use the existing production signing key for updates to the direct-distribution APK. Keep the package ID and signer stable and increase the version code for every release. Flutter reads `versionName+versionCode` from `pubspec.yaml`, for example `1.0.1+2`.
- Provision the approved keystore and `android/key.properties` through the team's secure storage or CI secret store. The Android ignore rules cover `key.properties`, `*.jks` and `*.keystore`. Keep a protected backup of the keystore and record the expected certificate SHA-256 fingerprint independently of the APK being built.
- The current Gradle release configuration falls back to debug signing when `key.properties` is absent. Confirm signing material before building and verify the signer afterwards. A future CI improvement is to make production builds fail during Gradle configuration when release signing material is missing.
- An earlier revision of this runbook contained a signing password. If it was used, change the affected password and review repository history and key access. Changing the password on an existing keystore preserves the signer. If the private key itself was exposed, coordinate a signing migration before distributing an update.

The local properties file has this shape. Supply the values through your secure provisioning process.

```properties
storeFile=../colosseum-release-key.jks
keyAlias=<approved release key alias>
storePassword=<from secure storage>
keyPassword=<from secure storage>
```

For a first-ever distribution with no existing production signer, use Android's [app signing guide](https://developer.android.com/studio/publish/app-signing) to provision a dedicated key. For Google Play, record the upload certificate and the Play app-signing certificate separately. Test switching between direct and Play distribution before offering that as an update path, because Android compares the installed and incoming app signatures.

## Build the release

1. Record the source commit, Flutter version and JDK version used for the build. Resolve dependencies against the committed `pubspec.lock`.
2. Confirm `pubspec.yaml` has the release version and a version code higher than the previously distributed APK.
3. Run analysis and tests. Resolve failures before building.
4. Verify that the build points to the intended backend. The client reads `COLOSSEUM_API_URL` as a Dart define and appends `/api/v1` itself. Supply the approved base URL if overriding the default. Set `COLOSSEUM_PRIVACY_URL` if the release should link to a published HTTPS privacy page.
5. Build a Universal APK for direct delivery. Build an AAB when publishing through Google Play, and check the [current Play target SDK requirements](https://developer.android.com/google/play/requirements/target-sdk).

```bash
set -euo pipefail
flutter --version
java -version
flutter pub get
flutter analyze
flutter test

test -r android/key.properties
flutter build apk --release
# For a Play release, use the same approved configuration:
# flutter build appbundle --release
```

The APK is at `build/app/outputs/flutter-apk/app-release.apk`. The AAB is at `build/app/outputs/bundle/release/app-release.aab`. Use the default APK architecture set for a single visitor download. ABI-specific APKs are useful for controlled distribution where the target device architecture is known.

## Verify the APK before staging

Set `ANDROID_BUILD_TOOLS` to an installed Android SDK Build Tools directory with `aapt`, `apksigner` and a 16 KB-capable `zipalign`. Set `EXPECTED_SIGNER_SHA256` to the approved release certificate fingerprint in lowercase hex without separators. Set `PREVIOUS_VERSION_CODE` from the last distributed APK and `EXPECTED_VERSION_CODE` from the intended release. For the first release, use `0` as the previous version code.

```bash
set -euo pipefail
apk=build/app/outputs/flutter-apk/app-release.apk
: "${ANDROID_BUILD_TOOLS:?Set the Android SDK Build Tools directory}"
: "${EXPECTED_SIGNER_SHA256:?Set the approved release certificate fingerprint}"
: "${EXPECTED_VERSION_CODE:?Set the intended release version code}"
: "${PREVIOUS_VERSION_CODE:?Set the previously distributed version code}"

badging=$("$ANDROID_BUILD_TOOLS/aapt" dump badging "$apk")
printf '%s\n' "$badging" | grep -F "package: name='com.example.colosseum_client' versionCode='$EXPECTED_VERSION_CODE'"
printf '%s\n' "$badging" | grep -Fx "sdkVersion:'24'"
printf '%s\n' "$badging" | grep -Fx "targetSdkVersion:'36'"
abi_line=$(printf '%s\n' "$badging" | grep '^native-code:')
for abi in armeabi-v7a arm64-v8a x86_64; do
  printf '%s\n' "$abi_line" | grep -F "'$abi'"
done
test "$EXPECTED_VERSION_CODE" -gt "$PREVIOUS_VERSION_CODE"

signature=$("$ANDROID_BUILD_TOOLS/apksigner" verify --verbose --print-certs "$apk")
actual_signer=$(printf '%s\n' "$signature" | awk '/certificate SHA-256 digest:/ {print $NF}')
test "$actual_signer" = "$EXPECTED_SIGNER_SHA256"
"$ANDROID_BUILD_TOOLS/zipalign" -c -P 16 -v 4 "$apk"
```

Review SDK expectations whenever the Flutter toolchain or product support range changes. Follow the [Android ELF alignment procedure](https://developer.android.com/guide/practices/page-sizes#check_elf_alignment) to check the native libraries in addition to ZIP alignment. For an AAB, also verify bundle alignment and test the generated APKs using Play internal testing or [bundletool](https://developer.android.com/tools/bundletool).

## Device acceptance tests

Use the exact signed file intended for distribution. Record the device model, Android version, ABI and test result alongside its version code and checksum.

| Test environment | What to verify |
| --- | --- |
| API 24 device or emulator | Fresh install, launch and access to the tour |
| 32-bit ARM device, when available | `armeabi-v7a` install and launch |
| Recent 64-bit Android phone | Fresh install and a normal download and install through the intended distribution channel |
| 16 KB Android device or emulator | Install, launch and use features that load native libraries |
| Device with the previous signed release | Install as an update and confirm existing saved tours and settings are retained |

On test devices, use `adb install <apk>` for a fresh install and `adb install -r <apk>` for an update. Exercise the live tour sync, map, precise location and compass behavior. Download a landmark and the device voice for the chosen language, then test its offline map, saved tour and narration in airplane mode. Include Italian TTS when validating a multilingual handoff.

## Stage and distribute

- Stage a versioned name such as `colosseum-guide-v1.0.1-2-universal-release.apk`. Create `SHA256SUMS.txt` in the same directory and confirm it with `sha256sum -c SHA256SUMS.txt`. Publish the APK and its checksum together.
- Keep previous verified artifacts in versioned directories. Stage the new APK and checksum in a temporary directory on the same filesystem, verify the copies, then rename the completed directory into place. Update any stable download link after this step.
- The existing [`sync_release.sh`](../sync_release.sh) builds and copies APKs into the workspace's `release/` and `project/release_apks/` directories. It uses absolute paths and clears old APKs before copying. Use the staged procedure above for a production handoff until the script incorporates these checks and keeps prior releases.

## Visitor installation and troubleshooting

Share an approved download link or use the selected Google Play track. For direct delivery, visitors may need to allow installation for the browser or file manager that opens the APK. If Play Protect or a device policy blocks the installer, confirm the file and distribution channel with the release owner. [Google Play Protect guidance](https://support.google.com/googleplay/answer/2812853)

| Symptom | Check |
| --- | --- |
| Update fails with `INSTALL_FAILED_UPDATE_INCOMPATIBLE` | Compare the installed and incoming package IDs and signing certificates. Use the update from the matching distribution channel. |
| `INSTALL_FAILED_VERSION_DOWNGRADE` | Check the installed version code and build a release with a higher version code. |
| `INSTALL_FAILED_NO_MATCHING_ABIS` | Confirm the device ABI and that the distributed file is the Universal APK. |
| `INSTALL_FAILED_OLDER_SDK` | Check the device's Android version against the APK's minimum API. |
| App opens but navigation or narration fails | Check precise location permission, available sensors, downloaded landmark content and the offline voice for the selected language. |

For an on-site visit, use Wi-Fi to download the landmark and its language voice before entering areas with weak signal. Grant precise location while using the app. If the compass direction drifts, follow the in-app calibration prompt. Phone settings for voice downloads and location vary by manufacturer.
