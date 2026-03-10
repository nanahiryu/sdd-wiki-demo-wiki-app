# 新規リポジトリの追加

既にドキュメント同期の仕組みが導入済みの環境に、新しいソースリポジトリを追加する手順。

初期セットアップがまだの場合は [initial-setup.md](./initial-setup.md) を参照。

## 1. GitHub App のインストール対象に追加

Organization の Settings > GitHub Apps > `<app-name>` > Configure から、新しいリポジトリをインストール対象に追加する。

## 2. Organization Secrets のアクセス対象に追加

Organization の Settings > Secrets and variables > Actions から、`GH_APP_ID` と `GH_APP_PRIVATE_KEY` それぞれの Repository access に新しいリポジトリを追加する。

CLI の場合:

```bash
gh secret set GH_APP_ID --org <org-name> --visibility selected --repos "<既存リポ>,<新規リポ>" --body "<App ID>"
```

> **注意**: `--repos` は上書きなので、既存リポジトリも含めて指定する必要がある。

## 3. Caller Workflow の配置

新しいリポジトリに `.github/workflows/sync-docs.yml` を作成する。

### マルチレポの場合

```yaml
name: Sync Docs to Wiki

on:
  pull_request:
    branches: [main]
    types: [closed]
    paths:
      - "docs/**"

jobs:
  sync:
    if: github.event.pull_request.merged == true
    uses: <org>/<wiki-app-repo>/.github/workflows/receive-docs.yml@main
    with:
      source-repo: <リポジトリ名>
      mappings: '[{"docs-path": "docs", "dest-path": "docs/<プロジェクト名>"}]'
    secrets:
      GH_APP_ID: ${{ secrets.GH_APP_ID }}
      GH_APP_PRIVATE_KEY: ${{ secrets.GH_APP_PRIVATE_KEY }}
```

### モノレポの場合

`mappings` に複数エントリを指定し、`paths` トリガーも対象ディレクトリに合わせる。

```yaml
name: Sync Docs to Wiki

on:
  pull_request:
    branches: [main]
    types: [closed]
    paths:
      - "plugins/*/docs/**"
      - "plugins/*/spec/**"

jobs:
  sync:
    if: github.event.pull_request.merged == true
    uses: <org>/<wiki-app-repo>/.github/workflows/receive-docs.yml@main
    with:
      source-repo: <リポジトリ名>
      mappings: |
        [
          {"docs-path": "plugins/plugin-alpha/docs", "dest-path": "docs/<プロジェクト名>/plugin-alpha"},
          {"docs-path": "plugins/plugin-beta/spec", "dest-path": "docs/<プロジェクト名>/plugin-beta"}
        ]
    secrets:
      GH_APP_ID: ${{ secrets.GH_APP_ID }}
      GH_APP_PRIVATE_KEY: ${{ secrets.GH_APP_PRIVATE_KEY }}
```

## 変更内容の確認

| 変更 | 場所 |
|---|---|
| App インストール対象 | Organization Settings > GitHub Apps |
| Secrets アクセス対象 | Organization Settings > Secrets |
| Caller Workflow | 新規リポジトリの `.github/workflows/sync-docs.yml` |
