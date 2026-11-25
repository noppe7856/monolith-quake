# プロジェクト引継ぎ指示書: MONOLITH

## 1. プロジェクト概要
単一HTMLファイル（`index.html`）で動作する、ホワイトベース・完全モノクロームの3D地球儀リアルタイム地震モニター＆Lo-Fiチルミュージックプレイヤー **「MONOLITH」** を開発しています。

## 2. 最重要開発方針（必守）
- **SysML v2 中心開発（Model-Based Systems Engineering）**:
  - `model/monolith_specification-v2.sysml` を設計の正本（Single Source of Truth）とします。
  - 開発プロセスは `model/monolith_engineering.sysml` に定義した **イテレーティブV字モデル** に従います。
  - 仕様変更・機能追加を行う際は、必ず **SysML v2モデル（要求・構造・制約・VC）を更新してから**、`index.html` と `tests/monolith.spec.mjs` を同期してください。
- **ビルド不要の単一HTML維持（NFR-03）**:
  - `index.html` はローカル相対パスの外部JS/CSSを持たず、単一ファイルのまま GitHub Pages で公開できる状態を維持してください。

## 3. 同梱済み成果物
- `index.html`: WebGL/GLSLギャラリー品質版（単一HTML）
- `model/monolith_specification-v2.sysml`: 製品仕様・要求（FR-01..07, NFR-01..04）・6モジュール構成・検証ケース（VC-01..11）
- `model/monolith_engineering.sysml`: 開発環境・開発モデル定義
- `tests/monolith.spec.mjs`: VC-01..11 と1対1対応する Playwright 自動検証テストコード

## 4. Antigravity に依頼する次のタスク（順番に実施）
1. **環境モデルの更新**:
   - `model/monolith_engineering.sysml` の `ModelingToolchain` / `ImplementationEditor` のIDE定義を VS Code から **Antigravity** 構成へ更新してください。
2. **テスト環境のセットアップと初回検証（V右辺）**:
   - `npm init -y`、`npm i -D @playwright/test`、`npx playwright install chromium` を実行し、`MONOLITH_HTML=./index.html npx playwright test tests/monolith.spec.mjs` を実行して VC-01..11 の合否（Verdict）を確認してください。
3. **不整合の解消（Failがある場合）**:
   - DOMセレクタの差異や制約違反でFailが出た場合、仕様意図を保ったままモデル・実装・テストの整合を取って全件Passにしてください。
4. **ドキュメント整備とGitHub公開準備**:
   - SysML v2モデルの内容に基づいて `README.md` を作成してください。
   - 必要に応じて `.github/workflows/verify-and-deploy.yml` を作成し、Git初期化およびGitHubリポジトリ作成・プッシュまで支援してください。
