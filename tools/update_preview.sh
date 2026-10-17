#!/usr/bin/env bash
# チームで進捗を確認するための全部入りプレビュー(preview/all-features)を更新する。
# push すると .github/workflows/deploy-preview.yml が
# https://useai-seaurchinplease.github.io/FireStartAlpha/preview/ に公開する。
#
# 使い方:
#   tools/update_preview.sh                 取り込み候補(dev 向けの開いている PR)を表示するだけ
#   tools/update_preview.sh <branch>...     dev と指定したブランチを順にマージして公開する
#
# - 取り込むブランチは毎回チームで相談して決め、引数で明示する(自動では選ばない)
# - 以前の衝突の解消は preview ブランチの履歴に残っているので、2回目以降は新しい変更だけがマージされる
# - 衝突したらそこで止まる。手で解消して git commit したあと、残りのブランチを指定してもう一度実行する
# - main への push で /preview/ が消えたときも、このスクリプトを実行し直せば公開し直す
#   (新しくマージするものがなければ、push の代わりにワークフローを手動で起動する)
# - 一度取り込んだブランチを外すには、そのマージコミットを git revert -m 1 で打ち消す。
#   あとで同じブランチを再び取り込むときは、先にその revert を revert しないと変更が戻らない
# - preview ブランチは dev にマージしない
set -euo pipefail

PREVIEW_BRANCH=preview/all-features
PREVIEW_URL=https://useai-seaurchinplease.github.io/FireStartAlpha/preview/

if [ $# -eq 0 ]; then
  echo "取り込むブランチを引数で指定してください。dev 向けの開いている PR:"
  gh pr list --base dev --json number,headRefName,title,isDraft \
    --template '{{range .}}  #{{.number}}  {{.headRefName}}{{if .isDraft}} (draft){{end}}  {{.title}}{{"\n"}}{{end}}'
  exit 1
fi

if [ "$(git rev-parse --abbrev-ref HEAD)" != "$PREVIEW_BRANCH" ]; then
  echo "$PREVIEW_BRANCH をチェックアウトしてから実行してください" >&2
  exit 1
fi
if [ -n "$(git status --porcelain)" ]; then
  echo "作業ツリーに未コミットの変更があります" >&2
  exit 1
fi

git fetch origin --prune
if git rev-parse --verify --quiet "origin/$PREVIEW_BRANCH" > /dev/null; then
  if ! git merge --ff-only "origin/$PREVIEW_BRANCH"; then
    echo "ローカルの $PREVIEW_BRANCH が origin と分岐しています。origin に合わせてからやり直してください。" >&2
    exit 1
  fi
fi

for branch in dev "$@"; do
  if ! git rev-parse --verify --quiet "origin/$branch" > /dev/null; then
    echo "origin/$branch が見つかりません。ブランチ名を確認してください。" >&2
    exit 1
  fi
done

for branch in dev "$@"; do
  echo "== merge $branch"
  if ! git merge --no-ff --no-edit -m "Merge $branch into preview" "origin/$branch"; then
    echo "衝突しました。解消して git commit したあと、残りのブランチを指定してもう一度実行してください。" >&2
    exit 1
  fi
done

ask() {
  local answer=""
  read -r -p "$1 [y/N] " answer || true
  [ "$answer" = "y" ] || [ "$answer" = "Y" ]
}

echo
if [ "$(git rev-parse HEAD)" = "$(git rev-parse "origin/$PREVIEW_BRANCH" 2>/dev/null || true)" ]; then
  echo "新しくマージするものはありませんでした。"
  if ask "公開をやり直しますか(main への push で /preview/ が消えたとき用)?"; then
    gh workflow run deploy-preview.yml --ref "$PREVIEW_BRANCH"
    echo "公開まで数分かかります: $PREVIEW_URL"
  fi
  exit 0
fi

echo "マージが終わりました。テストを実行して問題がなければ push してください。"
if ask "いま git push origin $PREVIEW_BRANCH しますか?"; then
  git push origin "$PREVIEW_BRANCH"
  echo "公開まで数分かかります: $PREVIEW_URL"
fi
