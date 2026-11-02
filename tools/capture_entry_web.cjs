// Optional QA: Playwright + installed Chromium. Real Godot input/rendering only.
const {chromium}=require('playwright');
const fs=require('node:fs'),path=require('node:path'),{spawn}=require('node:child_process');
const output=path.resolve(__dirname,'../docs/qa_m18');
const records=[];
let server,browser,page;
async function main(){
  fs.mkdirSync(output,{recursive:true});
  server=spawn('python3',[path.join(__dirname,'preview.py')],{cwd:path.join(__dirname,'..'),stdio:['ignore','pipe','pipe']});
  await new Promise((resolve,reject)=>{
    const timer=setTimeout(()=>reject(new Error('Preview timeout')),30000);
    server.stdout.on('data',b=>{if(String(b).includes('PREVIEW READY')){clearTimeout(timer);resolve();}});
    server.on('exit',code=>{clearTimeout(timer);reject(new Error('Preview exit '+code));});
  });
  browser=await chromium.launch({headless:true,...(process.env.CHROMIUM_BIN?{executablePath:process.env.CHROMIUM_BIN}:{}),
    args:['--use-angle=swiftshader','--enable-webgl','--enable-unsafe-swiftshader']});
  for(const device of ['desktop','mobile','portrait']){
    const mobile=device!=='desktop';
    const viewport=device==='desktop'?{width:1600,height:900}:device==='mobile'?{width:844,height:390}:{width:390,height:844};
    const context=await browser.newContext({viewport,deviceScaleFactor:1,hasTouch:mobile,isMobile:mobile,
      ...(mobile?{userAgent:'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Mobile Safari/537.36'}:{})});
    page=await context.newPage();
    await page.addInitScript(()=>{
      // Only QA: this environment cannot enumerate physical gamepads.
      Object.defineProperty(Navigator.prototype,'getGamepads',{value:()=>[]});
      const listen=window.addEventListener.bind(window);
      window.addEventListener=(type,...rest)=>{if(!type.startsWith('gamepad'))listen(type,...rest);};
    });
    const errors=[],logs=[];
    page.on('pageerror',e=>errors.push(String(e)));
    page.on('console',m=>{logs.push(m.type()+': '+m.text());if(m.type()==='error')errors.push(m.text());});
    async function wait(screen){
      await page.waitForFunction(s=>window.sfEntryState?.screen===s,screen,{timeout:90000});
      await page.waitForTimeout(600);
    }
    async function click(id){
      for(let i=0;i<14;i++){
        const pos=await page.evaluate(id=>{
          const s=window.sfEntryState,c=s.controls[id],r=document.querySelector('canvas').getBoundingClientRect();
          return {x:r.x+c.x*r.width/s.viewport[0],y:r.y+c.y*r.height/s.viewport[1]};
        },id);
        if(pos.y>20&&pos.y<viewport.height-25){
          if(mobile)await page.touchscreen.tap(pos.x,pos.y);else await page.mouse.click(pos.x,pos.y);
          await page.waitForTimeout(350);return;
        }
        await page.mouse.move(viewport.width/2,viewport.height/2);
        await page.mouse.wheel(0,pos.y<20?-160:220);await page.waitForTimeout(350);
      }
      throw new Error('Unreachable control '+id);
    }
    async function fill(value){
      await click('name');await page.keyboard.press('ControlOrMeta+A');
      await page.keyboard.type(value,{delay:60});
      // Do not submit until the actual Godot LineEdit has received every key.
      await page.waitForFunction(value=>window.sfEntryState?.name_input===value,value,{timeout:15000});
    }
    async function boot(){
      await page.goto('http://127.0.0.1:8077/',{waitUntil:'domcontentloaded'});
      await page.locator('#start').click();await wait('splash');
    }
    async function capture(name){
      await page.waitForTimeout(900);
      const file=device+'_'+name+'.png';await page.screenshot({path:path.join(output,file)});
      records.push({file,device,viewport,actual_godot_webgl:true});
    }
    await boot();if(!mobile)await capture('splash');
    await click('continue');await wait('login');if(!mobile)await capture('login');
    await fill('MissingCaptain');await click('submit');
    await page.waitForFunction(()=>window.sfEntryState.error.includes('nicht gefunden'));
    await click('register_tab');await wait('register');
    const name='Captain_'+device;await fill(name);await capture('register');
    await click('submit');await wait('home');
    const visible=await page.evaluate(()=>{const s=window.sfEntryState,p=s.controls.play;return p.y-p.height/2>=0&&p.y+p.height/2<s.viewport[1];});
    if(!visible)throw new Error('Play below fold '+device);
    await capture('home');
    await click('settings');await wait('settings');
    await click('muted');
    await page.waitForFunction(()=>window.sfEntryState.settings.muted===true);
    await capture('settings');
    await click('settings_back');await wait('home');
    if(device!=='portrait'){
      await click('play');await wait('sea');await capture('sea');
      await click('home');await wait('home');await click('logout');await wait('login');
      await fill(name);await click('submit');await wait('home');
      await page.waitForTimeout(1500);await boot();await click('continue');await wait('login');
      await fill(name);await click('submit');await wait('home');
      await click('logout');await wait('login');await click('guest');await wait('home');
      await click('play');await wait('sea');await click('home');await wait('home');
    }
    records.push({device,flow_passed:true,errors});
    fs.writeFileSync(path.join(output,device+'_browser.log'),logs.join('\n'));
    await context.close();
  }
  if(records.some(r=>r.errors?.length))throw new Error('Browser errors');
}
main().catch(async e=>{records.push({failure:String(e)});process.exitCode=1;console.error(e);
  if(page&&!page.isClosed())await page.screenshot({path:path.join(output,'failure.png')});
}).finally(async()=>{
  if(browser)await browser.close();if(server)server.kill('SIGINT');
  fs.mkdirSync(output,{recursive:true});
  fs.writeFileSync(path.join(output,'capture_report.json'),JSON.stringify({records,
    passed:records.filter(r=>r.flow_passed).length===3&&!records.some(r=>r.failure||r.errors?.length)},null,2));
});
