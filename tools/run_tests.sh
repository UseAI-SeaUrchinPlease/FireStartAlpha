#!/usr/bin/env bash
# tests/ のテストをすべて実行し、1本でも落ちたら終了コード 1 を返す。
# CI(deploy-preview.yml)とローカルの両方で使う。Godot は環境変数 GODOT か PATH の godot を使う。
#   extends SceneTree のテスト → --script で実行
#   それ以外(extends Node)    → そのスクリプトを使っている tests/*.tscn を実行
# SCRIPT ERROR は "OK" と表示されても失敗として扱う(テストが途中で止まっても OK が出ることがあるため)。
set -uo pipefail

GODOT="${GODOT:-godot}"
TIMEOUT_SECONDS="${TEST_TIMEOUT_SECONDS:-120}"
cd "$(dirname "$0")/.."

failed=0
for test_script in tests/test_*.gd; do
  name=$(basename "$test_script" .gd)
  if head -1 "$test_script" | grep -q "extends SceneTree"; then
    target=(--script "res://$test_script")
  else
    scene=$(grep -l "res://$test_script\"" tests/*.tscn | head -1)
    if [ -z "$scene" ]; then
      echo "NG  $name (このテストを使う .tscn がない)"
      failed=1
      continue
    fi
    target=("res://$scene")
  fi
  output=$(perl -e 'alarm shift; exec @ARGV' "$TIMEOUT_SECONDS" "$GODOT" --headless --path . "${target[@]}" 2>&1)
  code=$?
  if [ $code -ne 0 ] || grep -q "SCRIPT ERROR\|FAIL:\|Parse Error" <<< "$output"; then
    echo "NG  $name (exit $code)"
    grep -E "SCRIPT ERROR|FAIL:|Parse Error|ERROR" <<< "$output" | head -20 | sed 's/^/    /'
    failed=1
  else
    echo "OK  $name"
  fi
done
exit $failed
