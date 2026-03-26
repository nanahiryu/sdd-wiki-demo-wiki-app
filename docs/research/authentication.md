# 認証の仕組み

## 概要

ドキュメント同期ワークフローでは2種類のトークンを使い分けている。

| トークン | 用途 | 発行元 |
|---|---|---|
| `github.token` | ソースリポジトリの checkout（読み取り） | GitHub Actions が自動発行 |
| App Token | wiki-app の checkout & push（書き込み） | GitHub App の秘密鍵から生成 |

## github.token

> 参考: [Automatic token authentication - GitHub Docs](https://docs.github.com/en/actions/security-for-github-actions/security-guides/automatic-token-authentication)

GitHub Actions がワークフロー実行時に自動発行するトークン。caller（ソースリポジトリ）のコンテキストで発行されるため、ソースリポジトリへの読み取りアクセスを持つ。

> **補足**: `GITHUB_TOKEN` は `${{ secrets.GITHUB_TOKEN }}` と `${{ github.token }}` の2通りで参照できる（[公式ドキュメント](https://docs.github.com/en/actions/security-for-github-actions/security-guides/automatic-token-authentication)）。
> - *"You can use the GITHUB_TOKEN by using the standard syntax for referencing secrets: `${{ secrets.GITHUB_TOKEN }}`"*
> - *"An action can access the GITHUB_TOKEN through the `github.token` context"*

- 追加設定不要（デフォルトで `contents: read` が付与されている）
- ワークフロー実行が終わると自動失効
- リポジトリの Settings > Actions > General > 「Workflow permissions」で権限レベルを確認・変更可能

> **補足**: Reusable Workflow は wiki-app に定義されているが、実行コンテキストは caller（ソースリポジトリ）のもの。そのため `github.token` はソースリポジトリのトークンとなり、private リポでも自身の checkout に使用できる。

## GitHub App Token

GitHub App の秘密鍵から動的に生成する短命トークン。wiki-app への書き込みに使用する。

### GitHub App とは

GitHub App は GitHub 上で動作する「アプリケーション」としてのアイデンティティ。人間のユーザーアカウントとは別の、独立した行為者として振る舞う。

権限は細かく設定可能で、今回は Repository permissions > Contents: Read and write のみを付与している。

### App のインストール

App のインストールは「App がどのリポジトリにアクセスできるか」を決めるもの。

| リポジトリ | App インストール | 理由 |
|---|---|---|
| wiki-app | **必要** | App Token で checkout & push するため |
| ソースリポジトリ | **不要** | `github.token` で読めるため |

ソースリポジトリに必要なのは App の認証情報（Secrets: `GH_APP_ID`, `GH_APP_PRIVATE_KEY`）のみ。App のインストールとは独立した概念。

### 認証フロー

```
GH_APP_ID + GH_APP_PRIVATE_KEY (Secrets に保存)
        │
        ▼
JWT を生成 (秘密鍵で署名、有効期限10分)
        │
        ▼
GitHub API に JWT を送信
        │
        ▼
Installation Access Token を取得 (有効期限1時間)
        │
        ▼
Token で wiki-app への git clone / git push を実行
        │
        ▼
1時間後に Token は自動失効
```

秘密鍵を直接 git 操作に使うのではなく、短命トークンの生成にのみ使用する。これにより万が一トークンが漏洩しても1時間で無効化される。

## 他の認証方式との比較

| 観点 | Personal Access Token | Deploy Key | GitHub App |
|---|---|---|---|
| 正体 | ユーザーの認証情報 | SSH 鍵ペア | アプリケーション |
| トークン寿命 | 設定次第（無期限も可） | 無期限（手動で失効） | 1時間で自動失効 |
| 漏洩時の影響 | 無効化するまでアクセス可能 | 無効化するまでアクセス可能 | Token は1時間で自動失効 |
| 権限の粒度 | スコープ単位 | リポジトリ単位で read/write | API 単位で細かく設定 |
| 監査性 | ユーザーの操作として記録 | 鍵からは誰が使ったか不明 | App 経由の操作がログに残る |

## Organization Secrets を使う利点

| 項目 | リポジトリ個別登録 | Organization Secrets |
|---|---|---|
| 登録回数 | リポジトリ数 × 2 | 1回 |
| 新規リポジトリ追加 | Secret を個別登録 | アクセス対象に追加するだけ |
| 鍵ローテーション | 全リポジトリで更新 | 1箇所で更新 |
| アクセス制御 | リポジトリ管理者が閲覧可能 | Org Owner のみが管理 |

## 検証結果

不正な認証情報でドキュメント同期が実行できないことを確認済み。詳細は [auth-verification.md](./auth-verification.md) を参照。
