// Only immutable, content-addressed game art/runtime files. Never cache
// account requests, HTML, session data or the crossplay server connection.
const CACHE='abyssal-immutable-v1';
self.addEventListener('install',event=>event.waitUntil(self.skipWaiting()));
self.addEventListener('activate',event=>event.waitUntil(self.clients.claim()));

async function verifiedSave(cache,request,response,match){
 if(!response.ok)return;
 const bytes=await response.clone().arrayBuffer();
 const digest=Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',bytes)),x=>x.toString(16).padStart(2,'0')).join('');
 if(!digest.startsWith(match[2]))return;
 await cache.put(request,response);
 const limits={engine:2,core:3,ships:4};
 const keys=await cache.keys();
 for(const [kind,limit] of Object.entries(limits)){
  const group=keys.filter(key=>new URL(key.url).pathname.split('/').pop().startsWith(kind+'-'));
  for(const old of group.slice(0,Math.max(0,group.length-limit)))await cache.delete(old);
 }
}

async function load(request,match){
 const cache=await caches.open(CACHE);
 const cached=await cache.match(request,{ignoreVary:true});
 if(cached)return {response:cached,saved:Promise.resolve()};
 const response=await fetch(request);
 const saved=verifiedSave(cache,request,response.clone(),match);
 return {response,saved};
}

self.addEventListener('fetch',event=>{
 const request=event.request;
 const url=new URL(request.url);
 if(request.method!=='GET'||url.origin!==self.location.origin)return;
 const match=/^(engine|core|ships)-([a-f0-9]{20})\.(wasm|zip)$/.exec(url.pathname.split('/').pop());
 if(!match)return;
 const task=load(request,match);
 event.respondWith(task.then(result=>result.response));
 event.waitUntil(task.then(result=>result.saved).catch(error=>console.warn('Optional game-file cache unavailable:',error)));
});
