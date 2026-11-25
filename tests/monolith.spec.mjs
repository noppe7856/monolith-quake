/**
 * MONOLITH 自動検証テストスイート (Playwright)
 * SysML v2 検証モデル (MonolithVerification::VC-01 .. VC-11) と 1対1 対応
 *
 * 実行準備:
 *   npm init -y
 *   npm i -D @playwright/test
 *   npx playwright install chromium
 *
 * 実行コマンド:
 *   MONOLITH_HTML=./index.html npx playwright test tests/monolith.spec.mjs
 */

import { test, expect } from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

const HTML_PATH = path.resolve(process.env.MONOLITH_HTML || './index.html');
const APP_URL = pathToFileURL(HTML_PATH).href;

function readHtmlSource() {
  return fs.readFileSync(HTML_PATH, 'utf-8');
}

test.describe('MONOLITH Model-Based Verification Suite (SysML v2)', () => {
  test('[VC-10][NFR-03] 単一HTMLファイルとしてビルド不要で完結していること', async () => {
    expect(fs.existsSync(HTML_PATH)).toBeTruthy();
    const src = readHtmlSource();

    const localScriptRefs = src.match(/<script[^>]+src=["'](?!https?:\/\/)[^"']+["']/gi) || [];
    const localCssRefs = src.match(/<link[^>]+rel=["']stylesheet["'][^>]+href=["'](?!https?:\/\/)[^"']+["']/gi) || [];

    expect(localScriptRefs.length).toBe(0);
    expect(localCssRefs.length).toBe(0);
    expect(src).toMatch(/<style[\s>]/i);
    expect(src).toMatch(/<script[\s>]/i);
  });

  test('[VC-01][FR-01] WebGL3D地球儀が初期描画され、磁器調シェーダー・初期距離制約を満たすこと', async ({ page }) => {
    const errors = [];
    page.on('pageerror', (err) => errors.push(err.message));

    await page.setViewportSize({ width: 1280, height: 720 });
    await page.goto(APP_URL, { waitUntil: 'domcontentloaded' });

    const canvas = page.locator('canvas').first();
    await expect(canvas).toBeVisible();

    const box = await canvas.boundingBox();
    expect(box).not.toBeNull();
    expect(box.width).toBeGreaterThanOrEqual(1200);
    expect(box.height).toBeGreaterThanOrEqual(700);

    const src = readHtmlSource();
    expect(src).toMatch(/3\.68/);
    expect(src).toMatch(/ShaderMaterial/);
    expect(errors).toEqual([]);
  });

  test('[VC-02][FR-02] マウスドラッグによる回転操作が例外なく機能し、移動方向が一致する座標式であること', async ({ page }) => {
    const errors = [];
    page.on('pageerror', (err) => errors.push(err.message));

    await page.setViewportSize({ width: 1280, height: 720 });
    await page.goto(APP_URL, { waitUntil: 'domcontentloaded' });

    await page.mouse.move(640, 360);
    await page.mouse.down();
    await page.mouse.move(780, 440, { steps: 10 });
    await page.mouse.up();
    await page.waitForTimeout(200);

    expect(errors).toEqual([]);

    const src = readHtmlSource();
    expect(src).toMatch(/theta\s*-=/);
    expect(src).toMatch(/phi\s*-=/);
  });

  test('[VC-03][FR-03] SIM発火時にパーティクル集束・半透明インクシェーダー・3重リップル制約を満たすこと', async ({ page }) => {
    const errors = [];
    page.on('pageerror', (err) => errors.push(err.message));

    await page.goto(APP_URL, { waitUntil: 'domcontentloaded' });

    const simBtn = page.getByRole('button', { name: /SIM/i }).first();
    await expect(simBtn).toBeVisible();
    await simBtn.click();
    await page.waitForTimeout(400);

    expect(errors).toEqual([]);

    const src = readHtmlSource();
    expect(src).toMatch(/smoothstep\s*\(\s*0\.5\s*,\s*0\.05/);
    expect(src).toMatch(/aAlpha/);
    expect(src).toMatch(/aSize/);
  });

  test('[VC-04][FR-04] LIVEモードとHISTORY 30Dモードを切り替えられること', async ({ page }) => {
    await page.goto(APP_URL, { waitUntil: 'domcontentloaded' });

    const btn30d = page.getByRole('button', { name: /30D/i }).first();
    const btnLive = page.getByRole('button', { name: /LIVE/i }).first();

    await expect(btn30d).toBeVisible();
    await expect(btnLive).toBeVisible();

    await btn30d.click();
    await page.waitForTimeout(200);

    const slider = page.locator('#history-slider');
    await expect(slider).toBeVisible();

    await btnLive.click();
    await page.waitForTimeout(200);
    await expect(slider).toBeHidden();

    const src = readHtmlSource();
    expect(src).toMatch(/60000|60\s*\*\s*1000/);
  });

  test('[VC-05][FR-05] Lo-Fiチルミュージック再生が外部音声ファイルなしで起動しエラーを出さないこと', async ({ page }) => {
    const errors = [];
    page.on('pageerror', (err) => errors.push(err.message));

    const externalAudioRequests = [];
    page.on('request', (req) => {
      if (/\.(mp3|wav|ogg|m4a)(\?|$)/i.test(req.url())) {
        externalAudioRequests.push(req.url());
      }
    });

    await page.goto(APP_URL, { waitUntil: 'domcontentloaded' });

    const playBtn = page.locator('button[id*="play" i], button[class*="play" i], button[aria-label*="play" i]').first();
    await expect(playBtn).toBeVisible();
    await playBtn.click();
    await page.waitForTimeout(400);

    expect(externalAudioRequests).toEqual([]);
    expect(errors).toEqual([]);

    const src = readHtmlSource();
    expect(src).toMatch(/AudioContext|webkitAudioContext/);
    expect(src).toMatch(/createAnalyser/);
  });

  test('[VC-06][FR-06] 地震ノイズSFXの設定切替と初回ユーザー操作でのAudioContextアンロックを備えること', async ({ page }) => {
    const errors = [];
    page.on('pageerror', (err) => errors.push(err.message));

    await page.goto(APP_URL, { waitUntil: 'domcontentloaded' });

    await page.mouse.click(200, 200);
    const simBtn = page.getByRole('button', { name: /SIM/i }).first();
    await simBtn.click();
    await page.waitForTimeout(300);

    expect(errors).toEqual([]);

    const src = readHtmlSource();
    expect(src).toMatch(/createBiquadFilter/);
    expect(src).toMatch(/SFX/i);
  });

  test('[VC-07][FR-07] 初期状態はミニマル表示であり、INFOボタンでドロワーを開閉できること', async ({ page }) => {
    await page.goto(APP_URL, { waitUntil: 'domcontentloaded' });

    const drawer = page.locator('#info-drawer');
    const infoBtn = page.getByRole('button', { name: /INFO/i }).first();
    const closeBtn = page.getByRole('button', { name: /CLOSE/i }).first();

    await expect(infoBtn).toBeVisible();
    await expect(drawer).toHaveAttribute('aria-hidden', 'true');

    await infoBtn.click();
    await page.waitForTimeout(200);
    await expect(drawer).toHaveClass(/open/);
    await expect(drawer).toHaveAttribute('aria-hidden', 'false');

    await closeBtn.click();
    await page.waitForTimeout(200);
    await expect(drawer).not.toHaveClass(/open/);
    await expect(drawer).toHaveAttribute('aria-hidden', 'true');
  });

  test('[VC-08][NFR-01] 背景色がホワイトベースのモノクロームであること', async ({ page }) => {
    await page.goto(APP_URL, { waitUntil: 'domcontentloaded' });

    const bgRgb = await page.evaluate(() => {
      const bg = getComputedStyle(document.body).backgroundColor;
      const match = bg.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)/);
      return match ? [Number(match[1]), Number(match[2]), Number(match[3])] : null;
    });

    expect(bgRgb).not.toBeNull();
    const [r, g, b] = bgRgb;

    expect(r).toBeGreaterThanOrEqual(235);
    expect(g).toBeGreaterThanOrEqual(235);
    expect(b).toBeGreaterThanOrEqual(235);

    const spread = Math.max(r, g, b) - Math.min(r, g, b);
    expect(spread).toBeLessThanOrEqual(15);
  });

  test('[VC-09][NFR-02] 外部地図CDN・USGS APIを遮断してもクラッシュせず描画継続すること', async ({ page }) => {
    const errors = [];
    page.on('pageerror', (err) => errors.push(err.message));

    await page.route(/earthquake\.usgs\.gov|world-atlas|topojson/i, (route) => route.abort());

    await page.goto(APP_URL, { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(500);

    const canvas = page.locator('canvas').first();
    await expect(canvas).toBeVisible();
    expect(errors).toEqual([]);
  });

  test('[VC-11][NFR-04] PC横長とスマホ縦長のリサイズでキャンバスが画面比率へ追従すること', async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 720 });
    await page.goto(APP_URL, { waitUntil: 'domcontentloaded' });

    const canvas = page.locator('canvas').first();
    let box = await canvas.boundingBox();
    expect(box.width).toBeGreaterThan(box.height);

    await page.setViewportSize({ width: 390, height: 844 });
    await page.waitForTimeout(250);

    box = await canvas.boundingBox();
    expect(box.height).toBeGreaterThan(box.width);
    expect(box.width).toBeGreaterThanOrEqual(380);
    expect(box.height).toBeGreaterThanOrEqual(800);
  });
});
