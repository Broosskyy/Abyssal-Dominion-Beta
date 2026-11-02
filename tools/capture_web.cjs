// Actual WebGL canvas captures, not mockups. Optional QA dependency: Playwright.
const {chromium}=require('playwright');
const fs=require('node:fs');
const path=require('node:path');
const {spawn}=require('node:child_process');
const base=process.env.PREVIEW_URL || 'http://127.0.0.1:8077/';
const output=path.resolve(__dirname,'../docs/qa_m12');
const records=[];
async function main(){
  fs.mkdirSync(output,{recursive:true});
  let server;
  if(process.env.START_PREVIEW==='1'){
    server=spawn('python3',[path.join(__dirname,'preview.py')],{cwd:path.join(__dirname,'..'),stdio:['ignore','pipe','pipe']});
    await new Promise((resolve,reject)=>{
      const timeout=setTimeout(()=>reject(new Error('Preview startup timeout')),30000);
      server.stdout.on('data',data=>{if(String(data).includes('PREVIEW READY')){clearTimeout(timeout);resolve();}});
      server.stderr.on('data',data=>process.stderr.write(data));
      server.on('exit',code=>{clearTimeout(timeout);reject(new Error('Preview exited '+code));});
    });
  }
  const browser=await chromium.launch({headless:true,
    ...(process.env.CHROMIUM_BIN ? {executablePath:process.env.CHROMIUM_BIN}:{}),
    args:['--use-angle=swiftshader','--enable-webgl','--enable-unsafe-swiftshader']});
  try{
    for(const mobile of [false,true]){
      const context=await browser.newContext({viewport:mobile?{width:844,height:390}:{width:1600,height:900},deviceScaleFactor:1,hasTouch:mobile,isMobile:mobile,
        ...(mobile?{userAgent:'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Mobile Safari/537.36'}:{})});
      const page=await context.newPage();
      // This container cannot enumerate physical input devices. Restrict QA to
      // keyboard/touch; do not request unavailable OS gamepad access.
      await page.addInitScript(()=>{
        Object.defineProperty(Navigator.prototype,'getGamepads',{value:()=>[]});
        const listen=window.addEventListener.bind(window);
        window.addEventListener=(type,...rest)=>{if(!type.startsWith('gamepad'))listen(type,...rest);};
      });
      const errors=[];const consoleLog=[];
      page.on('pageerror',e=>errors.push(String(e)));
      page.on('console',m=>{consoleLog.push(m.type()+': '+m.text());fs.appendFileSync(path.join(output,'live_browser.log'),m.type()+': '+m.text()+'\n');if(m.type()==='error')errors.push(m.text());});
      await page.goto(base+'?qa=1',{waitUntil:'domcontentloaded',timeout:60000});
      await page.locator('#start').click();
      await page.waitForFunction(()=>window.sfQAReady === true,{},{timeout:120000});
      await page.waitForTimeout(2000);
      for(const fixture of mobile?['wide','arsenal']:['wide','ship_detail','harbor','snow','arsenal']){
        if(fixture==='arsenal'){
          if(mobile)await page.touchscreen.tap(742,224);else await page.keyboard.press('KeyI');
          await page.waitForFunction(()=>window.sfQARuntime?.inventory_open === true,{},{timeout:30000});
        }else{
          await page.evaluate(fixture=>{window.sfQAFixtureReady=false;window.sfQARequest={fixture};},fixture);
          await page.waitForFunction(()=>window.sfQAFixtureReady === true,{},{timeout:30000});
        }
        await page.waitForTimeout(1500);
        const filename=(mobile?'mobile_':'desktop_')+fixture+'.png';
        await page.screenshot({path:path.join(output,filename)});
        records.push({file:filename,fixture,mobile_emulation:mobile,viewport:page.viewportSize(),kind:'actual Godot WebGL runtime; debug fixture; software renderer'});
        console.log('CAPTURED '+filename);
      }
      fs.writeFileSync(path.join(output,mobile?'mobile_browser.log':'desktop_browser.log'),consoleLog.join('\n'));
      records.push({mobile_emulation:mobile,errors});
      await context.close();
    }
  }finally{await browser.close();if(server)server.kill('SIGINT');fs.writeFileSync(path.join(output,'capture_report.json'),JSON.stringify({base,renderer:'Chromium WebGL2 / SwiftShader',records},null,2));}
  if(records.some(record=>record.errors?.length))process.exitCode=1;
}
main().catch(e=>{console.error(e);process.exitCode=1});
