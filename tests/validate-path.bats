#!/usr/bin/env bats

setup() {
  source "$BATS_TEST_DIRNAME/../scripts/ci/validate-path.sh"
}

# --- 正常系 ---

@test "通常のパスは成功する" {
  run validate "test" "docs/getting-started"
  [ "$status" -eq 0 ]
}

@test "ハイフン・アンダースコア・ドットを含むパスは成功する" {
  run validate "test" "plugins/plugin-alpha/docs/v1.0"
  [ "$status" -eq 0 ]
}

@test "単一セグメントのパスは成功する" {
  run validate "test" "docs"
  [ "$status" -eq 0 ]
}

# --- allow-empty ---

@test "空文字列は --allow-empty で成功する" {
  run main "test" "" "--allow-empty"
  [ "$status" -eq 0 ]
}

@test "空文字列は --allow-empty なしで失敗する" {
  run main "test" ""
  [ "$status" -eq 1 ]
  [[ "$output" == *"is empty"* ]]
}

# --- パストラバーサル ---

@test ".. を含むパスは失敗する" {
  run validate "test" "../etc/passwd"
  [ "$status" -eq 1 ]
  [[ "$output" == *"contains '..'"* ]]
}

@test "中間に .. を含むパスは失敗する" {
  run validate "test" "docs/../../secret"
  [ "$status" -eq 1 ]
  [[ "$output" == *"contains '..'"* ]]
}

# --- 絶対パス ---

@test "絶対パスは失敗する" {
  run validate "test" "/tmp/evil"
  [ "$status" -eq 1 ]
  [[ "$output" == *"is an absolute path"* ]]
}

# --- 不正な文字 ---

@test "スペースを含むパスは失敗する" {
  run validate "test" "docs/my file"
  [ "$status" -eq 1 ]
  [[ "$output" == *"contains invalid characters"* ]]
}

@test "セミコロンを含むパスは失敗する" {
  run validate "test" "docs; rm -rf /"
  [ "$status" -eq 1 ]
  [[ "$output" == *"contains invalid characters"* ]]
}

@test "バッククォートを含むパスは失敗する" {
  run validate "test" 'docs/`whoami`'
  [ "$status" -eq 1 ]
  [[ "$output" == *"contains invalid characters"* ]]
}

@test "ドル記号を含むパスは失敗する" {
  run validate "test" 'docs/${HOME}'
  [ "$status" -eq 1 ]
  [[ "$output" == *"contains invalid characters"* ]]
}
