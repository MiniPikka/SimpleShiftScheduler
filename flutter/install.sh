#!/bin/bash
# 倒班助手 CP — 编译并安装到手机
# 用法: ./install.sh
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"
export PUB_HOSTED_URL=https://pub.dev
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
echo "=== 编译 APK ==="
/home/zxl/flutter-sdk/flutter/bin/flutter build apk --debug
echo "=== 安装到手机 ==="
adb -s d4044c26 install -r build/app/outputs/flutter-apk/app-debug.apk
echo "=== 完成 ==="
