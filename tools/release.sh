#!/bin/bash
# Fork release: builds the generic APK signed with this fork's key and publishes it as a GitHub release, which the
# TVs running this fork find on their own (Updates: weekly, or Home Settings > Updates).
#
#   tools/release.sh 1.5.0.1 "What changed"
#
# The key lives only on this Mac (~/.freemytv/release.keystore), its password in the login Keychain as
# freemytv-fork-release-apk. Keep a backup of both: without them no TV can take another update.
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${1:?usage: tools/release.sh <version, e.g. 1.5.0.1> [notes]}"
NOTES="${2:-}"
KEYSTORE="$HOME/.freemytv/release.keystore"
CERT="$(sed -n 's/.*RELEASE_CERT = "\([0-9a-f]*\)".*/\1/p' app/src/io/freemytv/Updates.java)"

[ -f "$KEYSTORE" ] || { echo "No release key at $KEYSTORE"; exit 1; }
[ -z "$(git status --porcelain)" ] || { echo "Commit or stash your changes first"; exit 1; }
git rev-parse -q --verify "refs/tags/v$VERSION" >/dev/null && { echo "Tag v$VERSION already exists"; exit 1; }

# versionName = the release, versionCode one above the current one (Android refuses a lower one).
CODE=$(( $(sed -n 's/.*android:versionCode="\([0-9]*\)".*/\1/p' app/AndroidManifest.xml) + 1 ))
sed -i '' -e "s/android:versionCode=\"[0-9]*\"/android:versionCode=\"$CODE\"/" \
          -e "s/android:versionName=\"[^\"]*\"/android:versionName=\"$VERSION\"/" app/AndroidManifest.xml

FREEMYTV_KEYSTORE="$KEYSTORE" FREEMYTV_KEYSTORE_PASS="$(security find-generic-password -s freemytv-fork-release-apk -w)" \
  ./build.sh --generic

BT="$(ls -d "${ANDROID_HOME:-$HOME/Library/Android/sdk}"/build-tools/* | sort -V | tail -1)"
GOT="$("$BT/apksigner" verify --print-certs FreeMyTV.apk | sed -n 's/.*SHA-256 digest: //p' | head -1)"
[ "$GOT" = "$CERT" ] || { echo "APK signed with $GOT, Updates expects $CERT"; git checkout app/AndroidManifest.xml; exit 1; }

git add app/AndroidManifest.xml
git commit -m "Release $VERSION"
git tag "v$VERSION"
git push origin HEAD "v$VERSION"
gh release create "v$VERSION" FreeMyTV.apk --repo RafaelGomes01/free-my-tv --title "$VERSION" --notes "${NOTES:-Release $VERSION}"
echo "Released $VERSION (versionCode $CODE)"
