#!/usr/bin/env python3
"""オープンな Issue の依存関係(blocked by)から、静的な依存関係ページを生成する。

使い方: GITHUB_TOKEN=... GITHUB_REPOSITORY=owner/repo python3 build.py <出力ディレクトリ>
標準ライブラリのみ。出力は <出力ディレクトリ>/index.html。
"""
import html
import json
import os
import sys
import urllib.request
from datetime import datetime, timedelta, timezone

API = "https://api.github.com"
REPO = os.environ["GITHUB_REPOSITORY"]
TOKEN = os.environ.get("GITHUB_TOKEN", "")


def get(path):
    """ページネーションをたどって全件取得する。"""
    url = f"{API}{path}{'&' if '?' in path else '?'}per_page=100"
    items = []
    while url:
        req = urllib.request.Request(url, headers={
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
            **({"Authorization": f"Bearer {TOKEN}"} if TOKEN else {}),
        })
        with urllib.request.urlopen(req) as res:
            items += json.load(res)
            url = None
            for part in res.headers.get("Link", "").split(","):
                if 'rel="next"' in part:
                    url = part[part.index("<") + 1:part.index(">")]
    return items


def collect():
    issues = {i["number"]: i for i in get(f"/repos/{REPO}/issues?state=open")
              if "pull_request" not in i and not i["title"].startswith("[管理]")}
    blockers = {}
    for n in issues:
        deps = get(f"/repos/{REPO}/issues/{n}/dependencies/blocked_by")
        # クローズ済みの先行 Issue は障害にならない
        blockers[n] = sorted(d["number"] for d in deps if d["state"] == "open")
    return issues, blockers


def waves(issues, blockers):
    """先行 Issue がすべて終わった後で着手できる順に、波(段)へ分ける。"""
    level = {}

    def depth(n, seen=()):
        if n in level:
            return level[n]
        if n in seen:  # 循環参照は 0 段扱いで打ち切る
            return 0
        bs = [b for b in blockers.get(n, []) if b in issues]
        level[n] = 0 if not bs else 1 + max(depth(b, seen + (n,)) for b in bs)
        return level[n]

    for n in issues:
        depth(n)
    result = {}
    for n, lv in level.items():
        result.setdefault(lv, []).append(n)
    return {lv: sorted(ns) for lv, ns in sorted(result.items())}


def label(issues, n):
    t = issues[n]["title"].replace('"', "'")
    return f"#{n} {t}"


def mermaid(issues, blockers, wv):
    lines = ["flowchart LR"]
    for lv, ns in wv.items():
        name = "第1波: 今すぐ着手できる" if lv == 0 else f"第{lv + 1}波"
        lines.append(f'  subgraph W{lv}["{name}"]')
        lines += [f'    i{n}["{label(issues, n)}"]' for n in ns]
        lines.append("  end")
    for n, bs in blockers.items():
        lines += [f"  i{b} --> i{n}" for b in bs if b in issues]
    for lv, ns in wv.items():
        for n in ns:
            if lv == 0:
                lines.append(f"  click i{n} href \"{issues[n]['html_url']}\" _blank")
    return "\n".join(lines)


def render(issues, blockers, wv):
    ready = wv.get(0, [])
    jst = timezone(timedelta(hours=9))
    now = datetime.now(jst).strftime("%Y-%m-%d %H:%M JST")

    def row(n, with_blockers=False):
        i = issues[n]
        assignee = ", ".join(a["login"] for a in i["assignees"]) or "—"
        extra = ""
        if with_blockers:
            extra = "<td>" + ", ".join(f"#{b}" for b in blockers[n]) + "</td>"
        return (f'<tr><td><a href="{i["html_url"]}">#{n}</a></td>'
                f'<td>{html.escape(i["title"])}</td><td>{html.escape(assignee)}</td>{extra}</tr>')

    ready_rows = "\n".join(row(n) for n in ready) or '<tr><td colspan="3">なし</td></tr>'
    waiting = [n for lv, ns in wv.items() if lv > 0 for n in ns]
    waiting_rows = "\n".join(row(n, True) for n in waiting) or '<tr><td colspan="4">なし</td></tr>'
    return f"""<!doctype html>
<html lang="ja"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Issue 依存関係マップ</title>
<style>
:root{{--bg:#fff;--fg:#1f2328;--mut:#656d76;--line:#d0d7de}}
@media(prefers-color-scheme:dark){{:root{{--bg:#0d1117;--fg:#e6edf3;--mut:#8b949e;--line:#30363d}}}}
body{{background:var(--bg);color:var(--fg);font:15px/1.6 system-ui,sans-serif;max-width:1100px;margin:0 auto;padding:16px}}
a{{color:#0969da}}table{{border-collapse:collapse;width:100%}}
td,th{{border-bottom:1px solid var(--line);padding:6px 8px;text-align:left}}
.mut{{color:var(--mut)}}.mm{{overflow-x:auto}}
</style></head><body>
<h1>Issue 依存関係マップ</h1>
<p class="mut">最終更新: {now} / オープン {len(issues)} 件 / 着手できる {len(ready)} 件。
GitHub の「blocked by」から自動生成しています。依存関係の編集は各 Issue で行ってください。</p>
<h2>今すぐ着手できる ({len(ready)})</h2>
<table><tr><th>Issue</th><th>タイトル</th><th>担当</th></tr>
{ready_rows}</table>
<h2>先行待ち ({len(waiting)})</h2>
<table><tr><th>Issue</th><th>タイトル</th><th>担当</th><th>待っている Issue</th></tr>
{waiting_rows}</table>
<h2>ツリー</h2>
<div class="mm"><pre class="mermaid">
{html.escape(mermaid(issues, blockers, wv))}
</pre></div>
<script type="module">
import mermaid from "https://cdn.jsdelivr.net/npm/mermaid@11.4.0/dist/mermaid.esm.min.mjs";
const dark = matchMedia("(prefers-color-scheme: dark)").matches;
mermaid.initialize({{startOnLoad:true,theme:dark?"dark":"default",securityLevel:"loose"}});
</script>
</body></html>
"""


def main():
    out = sys.argv[1]
    issues, blockers = collect()
    wv = waves(issues, blockers)
    os.makedirs(out, exist_ok=True)
    with open(os.path.join(out, "index.html"), "w", encoding="utf-8") as f:
        f.write(render(issues, blockers, wv))
    print(f"issues={len(issues)} ready={len(wv.get(0, []))} waves={len(wv)}")


if __name__ == "__main__":
    main()
