# 認証の仕組み

## GitHub App とは

GitHub App は GitHub 上で動作する「アプリケーション」としてのアイデンティティ。人間のユーザーアカウントとは別の、独立した行為者として振る舞う。

権限は細かく設定可能で、今回は Repository permissions > Contents: Read and write のみを付与している。さらにインストール時にアクセス可能なリポジトリを限定できるため、最小権限の原則を守りやすい。

## 認証フロー

```
GH_APP_ID + GH_APP_PRIVATE_KEY (Organization Secrets に1回登録)
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
Token で git clone / git push を実行
        │
        ▼
1時間後に Token は自動失効
```

秘密鍵を直接 git 操作に使うのではなく、短命トークンの生成にのみ使用する。これにより万が一トークンが漏洩しても1時間で無効化される。

## 他の認証方式との比較

Org Secrets を使う前提で比較する（Secrets 登録回数はいずれも1回で済む）。

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
