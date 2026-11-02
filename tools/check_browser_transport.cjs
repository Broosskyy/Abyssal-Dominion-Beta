const {chromium}=require('playwright');
const {spawn}=require('node:child_process');
const fs=require('node:fs');
const path=require('node:path');
async function main(){
  if(!process.env.GODOT_BIN)throw new Error('Set GODOT_BIN');
  const root=path.join(__dirname,'..');
  const server=spawn(process.env.GODOT_BIN,['--headless','--path',root,'--script','res://tools/start_transport_probe.gd'],{stdio:['ignore','pipe','pipe']});
  let browser;
  try{
    await new Promise((resolve,reject)=>{
      const timer=setTimeout(()=>reject(new Error('Server timeout')),20000);
      server.stdout.on('data',d=>{if(String(d).includes('TRANSPORT PROBE READY')){clearTimeout(timer);resolve();}});
      server.on('exit',code=>{clearTimeout(timer);reject(new Error('Server exit '+code));});
    });
    browser=await chromium.launch({headless:true,...(process.env.CHROMIUM_BIN?{executablePath:process.env.CHROMIUM_BIN}:{})});
    const page=await browser.newPage();
    const result=await page.evaluate(()=>new Promise((resolve,reject)=>{
      const socket=new WebSocket('ws://127.0.0.1:9080');
      const timer=setTimeout(()=>{socket.close();reject(new Error('Socket timeout'));},10000);
      socket.onopen=()=>socket.send(JSON.stringify({type:'hello',protocol:1,build:'M12'}));
      socket.onerror=()=>{clearTimeout(timer);reject(new Error('Socket error'));};
      socket.onmessage=event=>{clearTimeout(timer);const data=JSON.parse(event.data);socket.close();resolve(data);};
    }));
    if(result.type!=='welcome'||result.protocol!==1||result.session<=0)throw new Error('Invalid welcome');
    const report={passed:true,browser:await browser.version(),transport:'Browser WebSocket to Godot local probe',result,shared_gameplay:false};
    fs.writeFileSync(path.join(root,'docs/m12_browser_transport.json'),JSON.stringify(report,null,2));
    console.log(JSON.stringify(report));
  }finally{if(browser)await browser.close();server.kill('SIGTERM');}
}
main().catch(error=>{console.error(error);process.exitCode=1;});
