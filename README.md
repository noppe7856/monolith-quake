# MONOLITH

ホワイトベース・完全モノクロームデザインの **3D地球儀リアルタイム地震モニター & Lo-Fi チルミュージックプレイヤー** です。  
ビルド工程を必要としない単一 HTML ファイル（`index.html`）で完結し、GitHub Pages 等の静的ホスティングでそのまま公開できます。

## 設計方針（SysML v2 中心開発 / MBSE）

本プロジェクトは **Model-Based Systems Engineering（MBSE）** に基づき、SysML v2 モデルを設計の正本（Single Source of Truth）として管理しています。

- **製品仕様・要求・検証モデル**: [`model/monolith_specification-v2.sysml`](model/monolith_specification-v2.sysml)
- **開発環境・開発プロセスモデル**: [`model/monolith_engineering.sysml`](model/monolith_engineering.sysml)（Antigravity 構成・イテレーティブ V 字モデル）
- **自動検証スイート**: [`tests/monolith.spec.mjs`](tests/monolith.spec.mjs)（`VC-01`〜`VC-11` と 1 対 1 対応）

仕様変更や機能追加を行う際は、必ず **SysML v2 モデル（要求・構造・制約・VC）を更新してから**、`index.html` および `tests/monolith.spec.mjs` を同期します。

## 要求仕様一覧

### 機能要求（Functional Requirements）

| ID | 名称 | 概要 | 担当モジュール | 検証ケース |
| :--- | :--- | :--- | :--- | :--- |
| `FR-01` | 3D 地球儀表示 | 磁器調マットホワイトのカスタム GLSL シェーダー地球儀・海岸線・国境線を描画（初期距離比 `3.68`、フレネルリムハロー） | `SceneCameraModule` | `VC-01` |
| `FR-02` | インタラクティブ操作 | ドラッグ／タッチ方向と地球表面の移動方向が一致する回転操作、ズーム、慣性、自動回転 ON/OFF | `SceneCameraModule` | `VC-02` |
| `FR-03` | 地震パーティクル演出 | 震源へ極小・半透明の黒パーティクルが螺旋状に集束し、震源コア・インクハロー・3 重の 3D リップルリングを展開 | `ParticleEffectModule` | `VC-03` |
| `FR-04` | モード切替 | `LIVE`（USGS 60 秒定期監視＋`SIM` 発火）と `HISTORY 30D`（シークバー・速度切替・マグニチュードフィルタ）の切替 | `QuakeDataTimelineModule` | `VC-04` |
| `FR-05` | Lo-Fi チルミュージック生成 | 外部音声ファイルに依存せず Web Audio API で 3 種のコード進行・スウィングドラム・レコードノイズを生成し波形を表示 | `WebAudioEngineModule` | `VC-05` |
| `FR-06` | 地震ノイズ SFX | 地震発生時に 2 段階の乾いたノイズ系効果音を再生（初回ユーザー操作で AudioContext アンロック、ON/OFF 切替可） | `WebAudioEngineModule` | `VC-06` |
| `FR-07` | ミニマル HUD 設計 | 通常表示を最小限（モード切替・コンパクトプレイヤー・1 行自動フェードキャプション）に抑え、詳細ログはドロワーへ格納 | `MinimalHudUiModule` | `VC-07` |

### 非機能要求（Non-Functional Requirements）

| ID | 名称 | 概要 | 検証ケース |
| :--- | :--- | :--- | :--- |
| `NFR-01` | 完全モノクロームデザイン | ホワイトベースの完全モノクローム配色を維持 | `VC-08` |
| `NFR-02` | 可用性・フォールバック | 外部 CDN 障害やオフライン時でも内蔵フォールバック地図・マルチ CDN 切替により描画を継続 | `VC-09` |
| `NFR-03` | 単一ファイル配布 | ローカル外部 JS/CSS やビルド工程を持たない単一 `index.html` で完結 | `VC-10` |
| `NFR-04` | レスポンシブスケーリング | PC 横長・スマートフォン縦長の画面比率やリサイズに応じてカメラ距離とキャンバスを自動補正 | `VC-11` |

## システム構成（6 モジュール）

1. **`SceneCameraModule`**: Three.js (r128 UMD) WebGL レンダラー、磁器調 GLSL シェーダー、カメラ制御・慣性・レスポンシブ補正
2. **`MapVectorModule`**: 内蔵 TopoJSON デコーダー、`world-atlas@2/countries-110m.json` 読込、オフライン用フォールバック海岸線
3. **`ParticleEffectModule`**: `THREE.ShaderMaterial` による螺旋集束インクパーティクル、震源コア・ハロー・3 重リップル
4. **`QuakeDataTimelineModule`**: USGS GeoJSON API（24 時間 / 30 日間）取得、LIVE 監視、30D タイムライン再生制御
5. **`WebAudioEngineModule`**: Web Audio API による Lo-Fi シーケンサー、レコードノイズ、`AnalyserNode` 波形、2 段階ノイズ SFX
6. **`MinimalHudUiModule`**: ミニマル HUD、1 行キャプション、オーディオ設定ポップオーバー、地震ログドロワー

## ローカル実行・自動検証

### ブラウザでの確認
`index.html` をそのまま Chrome / Edge 等の WebGL・Web Audio 対応ブラウザで開くだけで動作します。

### Playwright 自動検証（VC-01〜VC-11）

```bash
npm install
npx playwright install chromium
npm test
```

PowerShell で対象 HTML を明示して実行する場合：

```powershell
$env:MONOLITH_HTML="./index.html"
npx playwright test tests/monolith.spec.mjs
```

## CI / GitHub Pages デプロイ

[`.github/workflows/verify-and-deploy.yml`](.github/workflows/verify-and-deploy.yml) により、`main` ブランチへのプッシュ時に以下が自動実行されます。

1. **Verify**: Playwright (Chromium) で `VC-01`〜`VC-11` の全自動検証を実行
2. **Deploy**: 全件 Pass 時のみ `index.html` を GitHub Pages へ自動デプロイ

> **GitHub Pages の設定**: リポジトリの `Settings > Pages > Build and deployment > Source` で **GitHub Actions** を選択してください。
