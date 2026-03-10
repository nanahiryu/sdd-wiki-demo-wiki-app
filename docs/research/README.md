# ドキュメント自動同期システム - 調査・設計資料

複数リポジトリのドキュメントを GitHub Actions + GitHub App で wiki-app に自動同期する仕組みの調査・設計資料。

## ドキュメント一覧

| ファイル | 内容 |
|---|---|
| [initial-setup.md](./initial-setup.md) | 初期セットアップ手順（App 作成、Secrets 登録、ワークフロー配置） |
| [add-new-repo.md](./add-new-repo.md) | 新規ソースリポジトリ追加時の手順とワークフローテンプレート |
| [workflow-architecture.md](./workflow-architecture.md) | ワークフローの全体構成、処理の流れ |
| [authentication.md](./authentication.md) | GitHub App による認証の仕組み、他方式との比較 |
| [auth-verification.md](./auth-verification.md) | 認証の検証レポート（不正な認証情報での失敗パターン確認） |

## 構成概要

```
ソースリポジトリ                          wiki-app
┌──────────────────┐                  ┌──────────────────────┐
│ pj-a             │                  │ docs/                │
│   docs/ ─────────┼──── sync ──────→│   pj-a/              │
│                  │                  │                      │
│ pj-b             │                  │                      │
│   docs/ ─────────┼──── sync ──────→│   pj-b/              │
│                  │                  │                      │
│ pj-c (モノレポ)   │                  │                      │
│   plugin-alpha/  │                  │                      │
│     docs/ ───────┼──── sync ──────→│   pj-c/plugin-alpha/ │
│   plugin-beta/   │                  │                      │
│     spec/ ───────┼──── sync ──────→│   pj-c/plugin-beta/  │
└──────────────────┘                  └──────────────────────┘
```

## 技術スタック

| 要素 | 採用技術 |
|---|---|
| 認証 | GitHub App + Installation Access Token |
| CI/CD | GitHub Actions (Reusable Workflow) |
| トリガー | PR マージ時に paths フィルタで発火 |
| パス設定 | mappings (JSON) によるソース → 配置先のマッピング |

## 同期の流れ

1. ソースリポジトリで docs を含む PR が main にマージされる
2. Caller Workflow (`sync-docs.yml`) が発火
3. wiki-app の Reusable Workflow (`receive-docs.yml`) を呼び出す
4. GitHub App の秘密鍵から短命トークン（1時間）を生成
5. トークンを使ってドキュメントを wiki-app にコピー & push
