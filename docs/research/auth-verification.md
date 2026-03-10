# 認証検証レポート

## 概要

pj-b を使って、GitHub App 方式の認証が正しく機能しているかを検証した。正しい認証情報がなければドキュメント同期は実行できないことを確認する。

## 検証結果

| # | 条件 | 結果 | エラーメッセージ |
|---|---|---|---|
| 1 | `GH_APP_ID` を空にする | failure | `[@octokit/auth-app] appId option is required` |
| 2 | `GH_APP_ID` に不正な値 (`9999999`) | failure | `Integration not found` |
| 3 | `secrets` 自体を渡さない | startup_failure | ワークフローが起動しない |
| 4 | `GH_APP_PRIVATE_KEY` を空にする | failure | `[@octokit/auth-app] privateKey option is required` |
| 5 | `GH_APP_PRIVATE_KEY` に不正な値 | failure | `Invalid keyData` |

## 各テストの詳細

### テスト 1: APP_ID 空

`actions/create-github-app-token` が `app-id` の入力値を検証し、空の場合は即座にエラーを返す。JWT の生成まで到達しない。

### テスト 2: APP_ID 不正値

JWT の生成は行われるが、GitHub API に送信した際に「該当する App が存在しない」として拒否される。秘密鍵が正しくても APP_ID が一致しなければ認証できない。

### テスト 3: secrets 未指定

Reusable Workflow 側で `required: true` と定義された secrets が渡されなかった場合、GitHub Actions のランタイムがワークフロー起動前にバリデーションエラーを返す。ランナーの起動すら行われない（`startup_failure`）。

### テスト 4: PRIVATE_KEY 空

APP_ID と同様に、`actions/create-github-app-token` が入力値を検証し、空の場合は即座にエラーを返す。

### テスト 5: PRIVATE_KEY 不正値

秘密鍵として不正な文字列が渡された場合、PEM 形式のパースに失敗する。JWT の署名に使える鍵として認識されない。

## 考察

- `APP_ID` と `GH_APP_PRIVATE_KEY` の **両方が正しい場合のみ** Installation Access Token が発行される
- 認証の失敗はすべて `Generate App Token` ステップで検出される（後続のステップには到達しない）
- `secrets` の `required: true` 指定により、渡し忘れはワークフロー起動前に検出される
- 正しくない認証情報では wiki-app へのアクセス・書き込みは一切行えない
