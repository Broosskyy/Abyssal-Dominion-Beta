// Isolated browser-shell checks; gameplay is verified with the actual Web export.
const { chromium } = require('playwright');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const http = require('node:http');
const path = require('node:path');
const source = fs.readFileSync(path.join(__dirname, '../../rebuild/m3052/web/browser_shell.html'), 'utf8');
const html = source.replace('$GODOT_CONFIG', '{}').replace('$GODOT_URL', 'engine.js').replace('$GODOT_HEAD_INCLUDE', '');
const stub = `window.Engine = class {startGame(options) { window.bootOptions=options; options.onProgress(5242880,10485760); return new Promise((resolve,reject)=>{window.completeBoot=resolve;window.failBoot=reject;}); }};`;
const server = http.createServer((req,res) => {res.setHeader('Content-Type', req.url === '/engine.js' ? 'text/javascript' : 'text/html');res.end(req.url === '/engine.js' ? stub : html);});
(async () => {
 await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
 const browser = await chromium.launch({executablePath:process.env.CHROMIUM_PATH || '/usr/bin/chromium',headless:true,args:['--no-sandbox','--disable-dev-shm-usage']});
 try {
  for (const size of [{width:393,height:852},{width:852,height:393},{width:1280,height:720}]) {
   const page = await browser.newPage({viewport:size});
   await page.goto(`http://127.0.0.1:${server.address().port}`);
   await page.waitForFunction(() => window.completeBoot);
   assert.match(await page.locator('#status').textContent(), /50 %/);
   const start = await page.locator('#start').boundingBox();
   assert(start.height >= 48 && start.x >= 0 && start.x + start.width <= size.width);
   if (size.width === 852) await page.screenshot({path:'/tmp/abyssal-shell-loading.png'});
   await page.locator('#start').click();
   await page.waitForFunction(() => document.fullscreenElement?.id === 'game');
   assert.equal(await page.locator('#launch').isVisible(), true, 'fullscreen gesture does not discard the loader before boot');
   await page.evaluate(() => window.completeBoot());
   await page.waitForFunction(() => document.querySelector('#launch').hidden);
   assert.equal(await page.locator('#fullscreen').isVisible(), true);
   await page.locator('#fullscreen').click();
   await page.waitForFunction(() => !document.fullscreenElement && document.querySelector('#fullscreen').getAttribute('aria-label') === 'Vollbild einschalten');
   assert.equal(await page.locator('#fullscreen').getAttribute('aria-label'), 'Vollbild einschalten');
   // Start without fullscreen, then recover a denied fullscreen request.
   await page.reload();
   await page.waitForFunction(() => window.completeBoot);
   await page.evaluate(() => window.completeBoot());
   await page.locator('#windowed').click();
   assert.equal(await page.locator('#launch').isVisible(), false);
   await page.evaluate(() => { document.querySelector('#game').requestFullscreen=()=>Promise.reject(new Error('denied')); });
   await page.locator('#fullscreen').click();
   await page.waitForFunction(() => document.querySelector('#notice').textContent.includes('Browser'));
   assert.equal(await page.locator('#canvas').isVisible(), true);
   // A failed download stays actionable instead of leaving an empty canvas.
   await page.reload();
   await page.waitForFunction(() => window.failBoot);
   await page.evaluate(() => window.failBoot(new Error('network')));
   await page.waitForFunction(() => !document.querySelector('#retry').hidden);
   assert.match(await page.locator('#status').textContent(), /nicht geladen/);
   assert.equal(await page.locator('#start').isVisible(), false);
   await page.close();
  }
  console.log('PASS: portrait, landscape, desktop; real fullscreen entry/exit, loading, windowed fallback, rejected fullscreen, network failure');
 } finally { await browser.close(); server.close(); }
})().catch(error => { console.error(error); server.close(); process.exitCode=1; });
