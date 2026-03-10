# ワークフローアーキテクチャ

## 概要

各ソースリポジトリのドキュメントが更新されたとき、GitHub Actions を通じて wiki-app リポジトリに自動同期する仕組み。認証には GitHub App を使用し、短命トークンでセキュアに操作する。

## 全体構成

```
ソースリポジトリ (pj-a, pj-b, pj-c)
  └── .github/workflows/sync-docs.yml     ← Caller Workflow

wiki-app リポジトリ
  └── .github/workflows/receive-docs.yml   ← Reusable Workflow
```

## 処理の流れ

```
1. ソースリポジトリで docs を含む PR が main に merge される
         │
2. sync-docs.yml が発火 (pull_request: closed + merged == true)
         │
3. receive-docs.yml を呼び出す (workflow_call)
         │
4. GitHub App の秘密鍵から Installation Access Token を生成 (1時間で失効)
         │
5. Token を使って wiki-app とソースリポジトリを checkout
         │
6. ソースの docs を wiki-app の所定パスにコピー
         │
7. 差分があれば commit & push (なければスキップ)
```

## ワークフロー詳細

### Caller Workflow (各ソースリポジトリ)

**ファイル**: `<source-repo>/.github/workflows/sync-docs.yml`

トリガー条件と Reusable Workflow への入力値を定義する。ロジックは持たない。

```yaml
on:
  pull_request:
    branches: [main]
    types: [closed]
    paths:
      - "docs/**"          # ← ここでドキュメントディレクトリを指定

jobs:
  sync:
    if: github.event.pull_request.merged == true
    uses: nanahiryu/sdd-wiki-demo-wiki-app/.github/workflows/receive-docs.yml@main
    with:
      source-repo: <リポジトリ名>
      mappings: '<JSON配列>'   # ← ソースパスと配置先パスのマッピング
    secrets:
      GH_APP_ID: ${{ secrets.GH_APP_ID }}
      GH_APP_PRIVATE_KEY: ${{ secrets.GH_APP_PRIVATE_KEY }}
```

**トリガー条件**: `pull_request: types: [closed]` + `paths` フィルタにより、ドキュメントディレクトリの変更を含む PR が main に merge されたときだけ発火する。`docs/` 以外 (src/, config/ 等) のみの変更では発火しない。

### Reusable Workflow (wiki-app)

**ファイル**: `sdd-wiki-demo-wiki-app/.github/workflows/receive-docs.yml`

同期処理の本体。全ソースリポジトリから共通で呼び出される。

**入力**:

| パラメータ | 型 | 説明 |
|---|---|---|
| `source-repo` | string | ソースリポジトリ名 |
| `mappings` | string (JSON) | `[{"docs-path": "...", "dest-path": "..."}]` の配列 |
| `GH_APP_ID` | secret | GitHub App の ID |
| `GH_APP_PRIVATE_KEY` | secret | GitHub App の秘密鍵 |

**処理ステップ**:

| ステップ | 使用する Action / コマンド | 説明 |
|---|---|---|
| Generate App Token | `actions/create-github-app-token@v2` | 秘密鍵から JWT を生成し、Installation Access Token を取得 |
| Checkout wiki-app | `actions/checkout@v4` | Token を使って wiki-app をクローン |
| Checkout source repo | `actions/checkout@v4` | Token を使ってソースリポジトリをクローン |
| Sync docs | shell | `cp -r` でドキュメントを配置先にコピー |
| Commit and push | shell | 差分があれば `sdd-wiki-demo-bot[bot]` としてコミット & プッシュ |

**matrix strategy**: `mappings` の各エントリごとにジョブが生成される。`max-parallel: 1` により順番に実行され、wiki-app への同時 push による競合を防ぐ。

## mappings の仕組み

`mappings` は Reusable Workflow の [inputs](https://docs.github.com/en/actions/sharing-automations/reusing-workflows) として JSON 文字列で渡され、Reusable Workflow 内で [`fromJSON`](https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/evaluate-expressions#fromjson) によりオブジェクトに変換されて matrix strategy に展開される。

## mappings の設定例

### マルチレポ (単一ディレクトリ)

```json
[{"docs-path": "docs", "dest-path": "docs/pj-a"}]
```

### モノレポ (複数ディレクトリ、パス個別指定)

```json
[
  {"docs-path": "plugins/plugin-alpha/docs", "dest-path": "docs/pj-c/plugin-alpha"},
  {"docs-path": "plugins/plugin-beta/spec", "dest-path": "docs/pj-c/plugin-beta"}
]
```

各プラグインのドキュメントディレクトリ名が異なっていても (`docs/`, `spec/` 等)、mappings で個別に指定できる。

## 認証

GitHub App を使った短命トークンで認証する。詳細は [authentication.md](./authentication.md) を参照。

## wiki-app 上のディレクトリ構成

```
wiki-app/docs/
├── pj-a/                    ← sdd-wiki-demo-pj-a の docs/
├── pj-b/                    ← sdd-wiki-demo-pj-b の docs/
└── pj-c/
    ├── plugin-alpha/        ← sdd-wiki-demo-pj-c の plugins/plugin-alpha/docs/
    └── plugin-beta/         ← sdd-wiki-demo-pj-c の plugins/plugin-beta/spec/
```
