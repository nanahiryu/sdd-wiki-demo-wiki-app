# 初期セットアップ

GitHub App を使ったドキュメント同期の仕組みを新規に導入する際の手順。

## 前提

- GitHub Organization があること
- Organization の Owner 権限を持っていること

## 1. GitHub App の作成

Organization の Settings > Developer settings > GitHub Apps > New GitHub App から作成する。

| 項目 | 値 |
|---|---|
| GitHub App name | `<app-name>` (例: `sdd-wiki-demo-bot`) |
| Homepage URL | 任意 |
| Webhook | Active のチェックを **外す** |
| Repository permissions > Contents | **Read and write** |
| Where can this GitHub App be installed? | **Any account** (Org 用) |

作成後、App 設定ページに表示される **App ID** を控えておく。

## 2. 秘密鍵の生成

App 設定ページ下部「Private keys」→「Generate a private key」で `.pem` ファイルをダウンロードする。

## 3. App のインストール

App 設定ページ左サイドバー「Install App」から、Organization を選択してインストールする。

- Repository access: **Only select repositories**
- 対象: wiki-app リポジトリ + 全ソースリポジトリ

## 4. Organization Secrets の登録

Organization の Settings > Secrets and variables > Actions から以下を登録する。1回の登録で全ソースリポジトリから参照可能。

| Secret Name | Value | Repository access |
|---|---|---|
| `GH_APP_ID` | App ID | 対象ソースリポジトリを選択 |
| `GH_APP_PRIVATE_KEY` | `.pem` ファイルの中身 | 対象ソースリポジトリを選択 |

CLI で登録する場合:

```bash
gh secret set GH_APP_ID --org <org-name> --visibility selected --repos "<repo-a>,<repo-b>,<repo-c>" --body "<App ID>"
gh secret set GH_APP_PRIVATE_KEY --org <org-name> --visibility selected --repos "<repo-a>,<repo-b>,<repo-c>" < /path/to/private-key.pem
```

> **注意**: `visibility` は `selected` にし、必要なリポジトリだけにアクセスを限定する。`all` にすると Organization 内の全リポジトリから参照可能になってしまう。

## 5. Reusable Workflow の配置

wiki-app リポジトリに `.github/workflows/receive-docs.yml` を配置する。詳細は [workflow-architecture.md](./workflow-architecture.md) を参照。

## 6. 各ソースリポジトリに Caller Workflow を配置

各ソースリポジトリに `.github/workflows/sync-docs.yml` を配置する。テンプレートは [add-new-repo.md](./add-new-repo.md) を参照。
