#!/usr/bin/env bash
set -euo pipefail

# パス入力のバリデーション
# 使い方: validate-path.sh <name> <value> [--allow-empty]
#
# チェック項目:
#   - パストラバーサル (..)
#   - 絶対パス (/)
#   - 不正な文字 (英数字, ハイフン, アンダースコア, ドット, スラッシュ 以外)

main() {
  local name="${1:?'name is required'}"
  local value="${2-}"
  local allow_empty="${3-}"

  if [[ -z "$value" ]]; then
    if [[ "$allow_empty" == "--allow-empty" ]]; then
      return 0
    else
      echo "::error::${name} is empty"
      exit 1
    fi
  fi

  validate "$name" "$value"
}

validate() {
  local name="$1"
  local value="$2"

  if [[ "$value" == *".."* ]]; then
    echo "::error::${name} contains '..': ${value}"
    exit 1
  fi

  if [[ "$value" == /* ]]; then
    echo "::error::${name} is an absolute path: ${value}"
    exit 1
  fi

  if [[ "$value" =~ [^a-zA-Z0-9_./-] ]]; then
    echo "::error::${name} contains invalid characters: ${value}"
    exit 1
  fi
}

# テストフレームワークから source された場合は main を実行しない
if [[ "${BATS_TEST_FILENAME:-}" == "" ]]; then
  main "$@"
fi
