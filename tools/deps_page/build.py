#!/usr/bin/env python3
"""オープンな Issue の依存関係(blocked by)と PR の状況から、静的な依存関係ページを生成する。

使い方: GITHUB_TOKEN=... GITHUB_REPOSITORY=owner/repo python3 build.py <出力ディレクトリ>
標準ライブラリのみ。出力は <出力ディレクトリ>/index.html。
"""
import html
import json
import os
import sys
import urllib.request

API = "https://api.github.com"
REPO = os.environ["GITHUB_REPOSITORY"]
TOKEN = os.environ.get("GITHUB_TOKEN", "")


def get(path, max_pages=None):
    """ページネーションをたどって取得する(max_pages で打ち切り可)。"""
    url = f"{API}{path}{'&' if '?' in path else '?'}per_page=100"
    items, pages = [], 0
    while url:
        pages += 1
        req = urllib.request.Request(url, headers={
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
            **({"Authorization": f"Bearer {TOKEN}"} if TOKEN else {}),
        })
        with urllib.request.urlopen(req) as res:
            items += json.load(res)
            url = None
            if max_pages and pages >= max_pages:
                break
            for part in res.headers.get("Link", "").split(","):
                if 'rel="next"' in part:
                    url = part[part.index("<") + 1:part.index(">")]
    return items


PR_QUERY = """
query($owner: String!, $name: String!, $after: String) {
  repository(owner: $owner, name: $name) {
    issues(states: OPEN, first: 100, after: $after) {
      pageInfo { hasNextPage endCursor }
      nodes {
        number
        closedByPullRequestsReferences(first: 10, includeClosedPrs: false) {
          nodes { number url isDraft state }
        }
      }
    }
  }
}
"""

DONE_LIMIT = 10  # 「最近完了」に出すクローズ済み Issue の件数


def graphql(query, variables):
    req = urllib.request.Request(
        f"{API}/graphql",
        data=json.dumps({"query": query, "variables": variables}).encode(),
        headers={"Authorization": f"Bearer {TOKEN}", "Content-Type": "application/json"})
    with urllib.request.urlopen(req) as res:
        body = json.load(res)
    if "errors" in body:
        raise RuntimeError(body["errors"])
    return body["data"]


def collect_prs():
    """オープンな Issue ごとに、それを閉じる予定のオープンな PR を返す。"""
    owner, name = REPO.split("/")
    prs, after = {}, None
    while True:
        conn = graphql(PR_QUERY, {"owner": owner, "name": name, "after": after})["repository"]["issues"]
        for node in conn["nodes"]:
            prs[node["number"]] = [p for p in node["closedByPullRequestsReferences"]["nodes"]
                                   if p["state"] == "OPEN"]
        if not conn["pageInfo"]["hasNextPage"]:
            return prs
        after = conn["pageInfo"]["endCursor"]


def collect_done():
    """最近クローズされた Issue(実装済みのもの。not planned は除く)。"""
    # 更新順の先頭1ページ(100件)あれば直近 DONE_LIMIT 件には十分
    closed = get(f"/repos/{REPO}/issues?state=closed&sort=updated&direction=desc", max_pages=1)
    done = [i for i in closed
            if "pull_request" not in i and i.get("state_reason") != "not_planned"
            and not i["title"].startswith("[管理]")]
    return sorted(done, key=lambda i: i["closed_at"], reverse=True)[:DONE_LIMIT]


def status_of(issue, blocked_by, prs):
    """todo / blocked / in_progress / in_review のいずれか。"""
    if any(not p["isDraft"] for p in prs):
        return "in_review"
    if prs or issue["assignees"]:
        return "in_progress"
    return "blocked" if blocked_by else "todo"


def collect():
    issues = {i["number"]: i for i in get(f"/repos/{REPO}/issues?state=open")
              if "pull_request" not in i and not i["title"].startswith("[管理]")}
    blockers = {}
    for n in issues:
        deps = get(f"/repos/{REPO}/issues/{n}/dependencies/blocked_by")
        # クローズ済みの先行 Issue は障害にならない
        blockers[n] = sorted(d["number"] for d in deps if d["state"] == "open")
    return issues, blockers


def label(issues, n):
    t = issues[n]["title"].replace('"', "'")
    return f"#{n} {t}"


STATUS_STYLE = {  # (表示名, 塗り, 枠)
    "todo": ("todo", "#ddf4ff", "#0969da"),
    "blocked": ("blocked", "#eaeef2", "#8c959f"),
    "in_progress": ("in progress", "#fff8c5", "#bf8700"),
    "in_review": ("in review", "#fbefff", "#8250df"),
}


def mermaid(issues, blockers, status):
    lines = ["flowchart LR"]
    lines += [f'  i{n}["{label(issues, n)}"]' for n in sorted(issues)]
    for n, bs in blockers.items():
        lines += [f"  i{b} --> i{n}" for b in bs if b in issues]
    for key, (_, fill, stroke) in STATUS_STYLE.items():
        lines.append(f"  classDef {key} fill:{fill},stroke:{stroke},color:#1f2328")
        members = ",".join(f"i{n}" for n in sorted(issues) if status[n] == key)
        if members:
            lines.append(f"  class {members} {key}")
    return "\n".join(lines)


def render(issues, blockers, status, prs, done):
    esc = html.escape

    def badge(key):
        name, fill, stroke = STATUS_STYLE[key]
        return f'<span class="b" style="background:{fill};border-color:{stroke}">{name}</span>'

    def link(i):
        return f'<a href="{i["html_url"]}">#{i["number"]}</a>'

    def assignee(i):
        return esc(", ".join(a["login"] for a in i["assignees"]) or "—")

    def pr_links(n):
        return " ".join(f'<a href="{p["url"]}">PR #{p["number"]}{" (draft)" if p["isDraft"] else ""}</a>'
                        for p in prs.get(n, [])) or "—"

    def section(title, keys, cols, cell):
        ns = [n for n in sorted(issues) if status[n] in keys]
        head = "".join(f"<th>{c}</th>" for c in cols)
        rows = "\n".join(f"<tr>{cell(n)}</tr>" for n in ns) or f'<tr><td colspan="{len(cols)}">なし</td></tr>'
        return f"<h2>{title} ({len(ns)})</h2>\n<table><tr>{head}</tr>\n{rows}</table>"

    def todo_cell(n):
        i = issues[n]
        return f"<td>{link(i)}</td><td>{esc(i['title'])}</td><td>{assignee(i)}</td>"

    def active_cell(n):
        i = issues[n]
        return (f"<td>{link(i)}</td><td>{esc(i['title'])}</td><td>{badge(status[n])}</td>"
                f"<td>{assignee(i)}</td><td>{pr_links(n)}</td>")

    def blocked_cell(n):
        i = issues[n]
        return (f"<td>{link(i)}</td><td>{esc(i['title'])}</td>"
                f"<td>{', '.join('#' + str(b) for b in blockers[n])}</td>")

    def done_rows():
        rows = "\n".join(
            f"<tr><td>{link(i)}</td><td>{esc(i['title'])}</td><td>{i['closed_at'][:10]}</td></tr>"
            for i in done) or '<tr><td colspan="3">なし</td></tr>'
        return f"<h2>最近完了 (直近 {len(done)} 件)</h2>\n<table><tr><th>Issue</th><th>タイトル</th><th>完了日</th></tr>\n{rows}</table>"

    counts = " / ".join(f"{badge(k)} {sum(1 for v in status.values() if v == k)}" for k in STATUS_STYLE)
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
.b{{color:#1f2328;border:1px solid;border-radius:10px;padding:0 8px;font-size:12px;white-space:nowrap}}
</style></head><body>
<h1>Issue 依存関係マップ</h1>
<p class="mut">オープン {len(issues)} 件</p>
<p>{counts}</p>
<p class="mut">状態は Issue と PR から自動判定しています(blocked: 先行 Issue が未完了 / in progress: 担当者あり or draft PR / in review: オープンな PR あり)。依存関係は各 Issue の「blocked by」で編集してください。</p>
{section("今すぐ着手できる", {"todo"}, ["Issue", "タイトル", "担当"], todo_cell)}
{section("進行中", {"in_progress", "in_review"}, ["Issue", "タイトル", "状態", "担当", "PR"], active_cell)}
{section("先行待ち", {"blocked"}, ["Issue", "タイトル", "待っている Issue"], blocked_cell)}
{done_rows()}
<h2>ツリー</h2>
<div class="mm"><pre class="mermaid">
{esc(mermaid(issues, blockers, status))}
</pre></div>
<script type="module">
import mermaid from "https://cdn.jsdelivr.net/npm/mermaid@11.4.0/dist/mermaid.esm.min.mjs";
const dark = matchMedia("(prefers-color-scheme: dark)").matches;
mermaid.initialize({{startOnLoad:true,theme:dark?"dark":"default",securityLevel:"strict"}});
</script>
</body></html>
"""


def main():
    out = sys.argv[1]
    issues, blockers = collect()
    prs = collect_prs()
    status = {n: status_of(issues[n], blockers[n], prs.get(n, [])) for n in issues}
    done = collect_done()
    os.makedirs(out, exist_ok=True)
    with open(os.path.join(out, "index.html"), "w", encoding="utf-8") as f:
        f.write(render(issues, blockers, status, prs, done))
    counts = {k: sum(1 for v in status.values() if v == k) for k in STATUS_STYLE}
    print(f"issues={len(issues)} status={counts} done(recent)={len(done)}")


if __name__ == "__main__":
    main()
