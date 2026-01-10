#!/bin/bash
# Flutter 运行脚本，使用自定义临时目录

# 确保临时目录存在
mkdir -p "$HOME/tmp"

# 设置临时目录环境变量
export TMPDIR="$HOME/tmp"
export DART_TMPDIR="$HOME/tmp"

# 运行 Flutter
flutter "$@"
