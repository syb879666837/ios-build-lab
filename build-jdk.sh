#!/bin/bash
set -euxo pipefail
W="$GITHUB_WORKSPACE"
brew install libffi autoconf make || true
echo "/opt/homebrew/opt/make/libexec/gnubin" >> "$GITHUB_PATH"
cd "$W"
git clone --depth 1 https://github.com/openjdk-mobile/ios-tools.git tools
gh release download libffi-build --repo openjdk-mobile/ios-tools --pattern "libffi-ios.zip"
mkdir -p support && unzip -q libffi-ios.zip -d support
ls support
git clone --depth 1 https://github.com/openjdk/mobile.git mobile
cp tools/openjdk-ext/src/hotspot/symbol_keeper.cpp mobile/src/hotspot/os/bsd/
cd "$W/mobile"
bash configure --with-conf-name=ios-aarch64-zero-release \
  --disable-warnings-as-errors \
  --openjdk-target=aarch64-macos-ios \
  --with-sysroot="$(xcrun --sdk iphoneos --show-sdk-path)" \
  --with-libffi-include="$(realpath "$W/support/include/ffi")" \
  --with-libffi-lib="$(realpath "$W/support")" \
  --with-cups-include="$(xcrun --sdk macosx --show-sdk-path)/usr/include"
make LOG=cmdlines,info CONF=ios-aarch64-zero-release static-libs-image
B="$W/mobile/build/ios-aarch64-zero-release"
mkdir -p "$W/pack"
cp -R "$B/jdk/modules" "$W/pack/modules"
cp -R "$B/jdk/include" "$W/pack/include" || true
ls "$W/pack/modules" | head -60
find "$B/images/static-libs" -name "*.a" > "$W/als.txt"
wc -l "$W/als.txt"
xcrun libtool -static -o "$W/pack/libdevice.a" $(cat "$W/als.txt")
ls -lh "$W/pack/libdevice.a"
tar czf "$W/jdk-full.tgz" -C "$W/pack" .
ls -lh "$W/jdk-full.tgz"
