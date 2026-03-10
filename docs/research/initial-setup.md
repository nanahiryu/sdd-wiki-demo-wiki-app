# 初期セットアップ

GitHub App を使ったドキュメント同期の仕組みを新規に導入する際の手順。

## 前提

- GitHub アカウントを持っていること

## 1. GitHub App の作成

https://github.com/settings/apps/new から作成する。

| 項目 | 値 |
|---|---|
| GitHub App name | `<app-name>` (例: `sdd-wiki-demo-bot`) |
| Homepage URL | 任意 |
| Webhook | Active のチェックを **外す** |
| Repository permissions > Contents | **Read and write** |
| Where can this GitHub App be installed? | **Only on this account** |

作成後、App 設定ページに表示される **App ID** を控えておく。

## 2. 秘密鍵の生成

App 設定ページ下部「Private keys」→「Generate a private key」で `.pem` ファイルをダウンロードする。

## 3. App のインストール

App 設定ページ左サイドバー「Install App」から、自分のアカウントにインストールする。

- Repository access: **Only select repositories**
- 対象: wiki-app リポジトリ + 全ソースリポジトリ

## 4. Secrets の登録

各ソースリポジトリの Settings > Secrets and variables > Actions に以下を登録する。

| Secret Name | Value |
|---|---|
| `GH_APP_ID` | App 設定ページに表示される App ID |
| `GH_APP_PRIVATE_KEY` | ダウンロードした `.pem` ファイルの中身 |

CLI で一括登録する場合:

```bash
gh secret set GH_APP_ID --repo <owner>/<repo> --body "<App ID>"
gh secret set GH_APP_PRIVATE_KEY --repo <owner>/<repo> < /path/to/private-key.pem
```

> **注意**: 個人アカウントでは Organization Secrets が使えないため、各リポジトリに個別登録が必要。

## 5. Reusable Workflow の配置

wiki-app リポジトリに `.github/workflows/receive-docs.yml` を配置する。詳細は [workflow-architecture.md](./workflow-architecture.md) を参照。

## 6. 各ソースリポジトリに Caller Workflow を配置

各ソースリポジトリに `.github/workflows/sync-docs.yml` を配置する。テンプレートは [add-new-repo.md](./add-new-repo.md) を参照。

---

## Organization で運用する場合の差分

| 項目 | 個人アカウント | Organization |
|---|---|---|
| App 作成場所 | https://github.com/settings/apps/new | Organization の Settings > Developer settings > GitHub Apps |
| App インストール先 | Only on this account | Any account → 対象 Org にインストール |
| Secrets 登録 | 各リポジトリに個別登録 | Organization Secrets に1回登録（`--visibility selected`） |
| 新規リポ追加時 | Secret を個別登録 | 設定変更不要（`visibility: all` の場合） |
| 鍵ローテーション | 全リポジトリで更新 | 1箇所で更新 |

Organization Secrets の CLI 登録例:

```bash
gh secret set GH_APP_ID --org <org-name> --visibility all --body "<App ID>"
gh secret set GH_APP_PRIVATE_KEY --org <org-name> --visibility all < /path/to/private-key.pem
```

> **補足**: `--visibility` は `all`（全リポジトリ）、`private`（private リポジトリのみ）、`selected`（指定リポジトリのみ）から選択可能。新規リポジトリ追加時に Secrets の設定変更が不要になるため、ここでは `all` を採用している。
