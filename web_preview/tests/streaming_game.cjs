const {chromium}=require('playwright');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const http=require('node:http');
const zlib=require('node:zlib');
const directory=path.resolve(__dirname,'../../rebuild/m3052/builds/web');
const report=JSON.parse(fs.readFileSync(path.join(directory,'delivery-report.json')));
const downloads=[];
let revalidations=0;
const served=new Map();
let wireBytes=0;
const server=http.createServer((req,res)=>{
 const name=decodeURIComponent(req.url.split('?')[0]).replace(/^\//,'')||'index.html';
 if(name.includes('..')||name.includes('\\')){res.writeHead(400).end();return;}
 const file=path.join(directory,name);
 if(!fs.existsSync(file)){res.writeHead(404).end();return;}
 let data=served.get(name);
 if(!data){const raw=fs.readFileSync(file);data=name.endsWith('.wasm')?zlib.gzipSync(raw):raw;served.set(name,data);}
 res.setHeader('Content-Type',name.endsWith('.wasm')?'application/wasm':name.endsWith('.js')?'text/javascript':name.endsWith('.html')?'text/html':'application/octet-stream');
 if(name.endsWith('.wasm'))res.setHeader('Content-Encoding','gzip');
 if(/^(engine-|core-|ships-)/.test(name)){
  res.setHeader('Cache-Control','public,max-age=31536000,immutable');
  const etag='"'+name+'"';res.setHeader('ETag',etag);
  if(req.headers['if-none-match']===etag){revalidations++;res.writeHead(304).end();return;}
 }
 res.setHeader('Content-Length',data.length);
 downloads.push(name);wireBytes+=data.length;res.end(data);
});
(async()=>{
 await new Promise(r=>server.listen(0,'127.0.0.1',r));
 const browser=await chromium.launch({executablePath:process.env.CHROMIUM_PATH||'/usr/bin/chromium',headless:true,args:['--no-sandbox','--disable-dev-shm-usage','--use-angle=swiftshader','--enable-unsafe-swiftshader']});
 try{
  const page=await browser.newPage({viewport:{width:1280,height:720}});
  const errors=[];let stage='';
  page.on('console',message=>{
   const text=message.text();
   if(text.includes('BROWSER_READY:captain_hub'))stage='hub';
   if(text.includes('BROWSER_READY:sea'))stage='sea';
   if(/SCRIPT ERROR:|Parse Error:|Failed to load|Missing original-GLB|Aborted\(/.test(text))errors.push(text);
  });
  page.on('pageerror',error=>errors.push(error.message));
  await page.goto(`http://127.0.0.1:${server.address().port}`);
  await page.locator('#windowed').click();
  await page.locator('#launch').waitFor({state:'hidden',timeout:120000});
  const deadline=Date.now()+30000;
  while(stage!=='hub'&&Date.now()<deadline)await new Promise(r=>setTimeout(r,100));
  assert.equal(stage,'hub','actual Godot welcome scene boots from the minimal core ZIP');
  await page.screenshot({path:'/tmp/abyssal-web-welcome.png'});
  // Real canvas input, at the shared start_hub layout's third 48px action.
  await page.mouse.click(930,442);
  const seaDeadline=Date.now()+30000;
  while(stage!=='sea'&&Date.now()<seaDeadline)await new Promise(r=>setTimeout(r,100));
  assert.equal(stage,'sea','guest reaches the actual shared Godot simulation');
  await page.screenshot({path:'/tmp/abyssal-web-sea.png'});
  assert(!downloads.some(n=>n.startsWith('ships-')),'guest sailing must not download optional ship art');
  const cold=wireBytes;
  assert(cold<23000000,`cold transfer budget exceeded: ${cold}`);
  await page.reload();
  await page.locator('#windowed').click();
  await page.locator('#launch').waitFor({state:'hidden',timeout:120000});
  assert.equal(downloads.filter(n=>n.endsWith('.wasm')).length,1,'unchanged engine is reused from browser cache');
  assert.equal(downloads.filter(n=>n===report.start_files[0]).length,1,'unchanged core is reused from browser cache');
  assert.deepEqual(errors,[],'no runtime resource or script errors in the real Web export');
  console.log(JSON.stringify({status:'PASS',cold_transfer_bytes:cold,revisit_transfer_bytes:wireBytes-cold,cache_revalidations:revalidations,optional_requests:0,real_webgl:true,shared_godot_game:true}));
 }finally{await browser.close();server.close();}
})().catch(error=>{console.error(error);server.close();process.exitCode=1;});
