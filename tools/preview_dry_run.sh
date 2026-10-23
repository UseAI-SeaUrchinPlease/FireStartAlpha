#!/usr/bin/env bash
# 毎週の定例の前に、開いている PR をすべて(マージ先を問わず)preview/all-features に「試しに」マージし、
# 衝突とテストの結果を Markdown で標準出力に出す(push も公開もしない)。
# .github/workflows/preview-dry-run.yml から呼ばれる。preview/all-features をチェックアウトした状態で実行する。
# 取り込むかどうかはこの結果を見て issue #34 で決め、実際の更新は tools/update_preview.sh で行う。
set -uo pipefail

GODOT="${GODOT:-godot}"

git fetch origin --prune --quiet
echo "## 試しのマージの結果 ($(TZ=Asia/Tokyo date '+%Y-%m-%d %H:%M') JST)"
echo
echo "開いている PR をすべて \`preview/all-features\` に試しにマージした結果です(push も公開もしていません)。"
echo
echo "| PR | ブランチ | 結果 |"
echo "|---|---|---|"

trial_merge() {
  local label=$1 branch=$2
  local before
  before=$(git rev-parse HEAD)
  if git merge --no-ff --no-edit -m "Trial merge $branch" "origin/$branch" > /dev/null 2>&1; then
    if [ "$(git rev-parse HEAD)" = "$before" ]; then
      echo "| $label | \`$branch\` | 新しい変更なし(取り込み済み) |"
    else
      echo "| $label | \`$branch\` | マージできた |"
    fi
  else
    local files
    files=$(git diff --name-only --diff-filter=U | sed 's/.*/`&`/' | paste -sd ' ' -)
    git merge --abort
    echo "| $label | \`$branch\` | **衝突**: $files |"
  fi
}

trial_merge "-" dev
# マージ先が dev でない PR(例: main 向け)も候補として出し、マージ先を明記する
while IFS=$'\t' read -r number branch draft base; do
  [ -z "$number" ] && continue
  label="#$number"
  [ "$draft" = "true" ] && label="$label (draft)"
  [ "$base" != "dev" ] && label="$label (マージ先: $base)"
  trial_merge "$label" "$branch"
done < <(gh pr list --state open --json number,headRefName,isDraft,baseRefName \
  --jq 'sort_by(.number) | .[] | [.number, .headRefName, .isDraft, .baseRefName] | @tsv')

echo
echo "### テスト(衝突した PR を除いてマージした状態)"
echo
"$GODOT" --headless --path . --import > /dev/null 2>&1
"$GODOT" --headless --path . --import > /dev/null 2>&1
if output=$(GODOT="$GODOT" tools/run_tests.sh 2>&1); then
  echo "すべて通りました。"
else
  echo "**落ちたテストがあります。**"
fi
echo
echo '```'
echo "$output"
echo '```'
