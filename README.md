# FireStarting

火起こしをモチーフにした2Dローグライク。設計の全体像は [DEVELOPMENT.md](DEVELOPMENT.md) を参照してください。

## 操作方法

| 操作 | キーボード | ゲームパッド |
|---|---|---|
| 移動(8方向) | WASD / 矢印キー | 左スティック・十字キー |
| 掘る(採取) | J 長押し | X ボタン |
| 攻撃 | K | B ボタン |
| 決定・メニュー操作 | E | Y ボタン |

- 昼: マップを歩き回り、木・岩・草むらを掘って素材を集める。ゾンビに触れるとダメージ
- 夜(火起こし): ← →でスロット選択、↑ ↓で個数変更、E で点火
- 夜(強化): ↑ ↓ で項目選択、E で購入/次の日へ
- タイトル/ゲームオーバー画面も ↑ ↓ + E で操作

## 開発者へ向けたメモ

- Godot **4.7.2 stable** を使用。バージョン違いだとシーンやプロジェクト設定が壊れる可能性があるため揃えてください
- `class_name` を持つスクリプトを追加/変更した後は、一度 `godot --headless --path . --import` を実行してからでないと `Could not find type X` エラーが出ることがあります(クラスキャッシュの更新タイミングの都合)
- `.mcp.json` は各自のローカル環境(Godotの実行パスなど)に依存するため `.gitignore` 対象です。AI/MCPツールを使う場合は各自で作成してください
- 本プロジェクトの開発には [godot-mcp](https://github.com/LeeSinLiang/godot-mcp)(シーン編集・実行・デバッグ出力取得などをAIから操作するMCPサーバー)を使用しています
- テストは `tests/` にヘッドレスで実行できる形で置いています。`extends SceneTree` のものは `godot --headless --path . --script res://tests/xxx.gd`、Autoload に依存するものは `.tscn` にして `godot --headless --path . res://tests/Xxx.tscn` で実行してください
- レンダラーはデスクトップ/エディタが Forward+、Web 書き出しのみ `gl_compatibility`(`project.godot` の `renderer/rendering_method.web` で上書き)。Web は Forward+ 非対応なので変更時は注意
- 日本語テキストは `assets/fonts/DotGothic16-Regular.ttf` を `gui/theme/custom_font` に設定して表示しています。外すと日本語が文字化け(豆腐)します
- `main`/`master` に push すると GitHub Actions (`.github/workflows/deploy-web.yml`) が自動でWeb版をビルドし GitHub Pages に公開します
- 設計や仕様に変更がある場合は `DEVELOPMENT.md` を正として更新してください
