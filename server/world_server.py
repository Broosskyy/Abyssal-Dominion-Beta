"""Abyssal crossplay preparation: real auth and authoritative presence sandbox.
Not the production combat/economy backend. Guest inventory is never imported.
Run behind a TLS proxy; bind localhost by default. Credentials never enter logs.
"""
import asyncio
import hashlib
import hmac
import json
import math
import os
import secrets
import sqlite3
import time
from collections import defaultdict, deque
from pathlib import Path
from aiohttp import web, WSMsgType

PROTOCOL = 2
SEA_IDS = {0, 1, 2, *range(6, 43)}
SESSION_SECONDS = 86400
MAX_CLIENTS = 128
MAX_ROOM = 32

class World:
    def __init__(self, database):
        self.db = sqlite3.connect(database)
        self.db.execute('PRAGMA journal_mode=WAL')
        self.db.executescript('''CREATE TABLE IF NOT EXISTS accounts (
            id TEXT PRIMARY KEY, email TEXT UNIQUE NOT NULL, username TEXT NOT NULL,
            salt BLOB NOT NULL, password BLOB NOT NULL);
            CREATE TABLE IF NOT EXISTS sessions (
            digest TEXT PRIMARY KEY, account TEXT NOT NULL, expires INTEGER NOT NULL);
            CREATE TABLE IF NOT EXISTS characters (
            account TEXT NOT NULL, map_id INTEGER NOT NULL, x REAL NOT NULL, y REAL NOT NULL,
            heading REAL NOT NULL, skin INTEGER NOT NULL, PRIMARY KEY(account,map_id));''')
        # Upgrade persisted preview coordinates exactly once. Protocol 2 prevents
        # older small-world clients joining the expanded-world rooms.
        if self.db.execute('PRAGMA user_version').fetchone()[0] < 2:
            self.db.execute('UPDATE characters SET x=x*2,y=y*2')
            self.db.execute('PRAGMA user_version=2')
            self.db.commit()
        self.peers = {}
        self.rates = defaultdict(deque)
        self.tick = 0

    def save_character(self, peer):
        self.db.execute('INSERT OR REPLACE INTO characters VALUES (?,?,?,?,?,?)',
            (peer['id'],peer['map_id'],peer['x'],peer['y'],peer['heading'],peer['skin']))
        self.db.commit()

    @staticmethod
    def route(data):
        route = data.get('route', [[data.get('x'), data.get('y')]])
        if not isinstance(route,list) or not 1 <= len(route) <= 128: return None
        result = []
        for point in route:
            if not isinstance(point,list) or len(point)!=2: return None
            x,y=point
            if type(x) not in (int,float) or type(y) not in (int,float): return None
            if not math.isfinite(x) or not math.isfinite(y) or not (40<=x<=8760 and 40<=y<=6360): return None
            result.append((float(x),float(y)))
        return result

    def limited(self, key, limit=12, span=60):
        now = time.monotonic()
        entries = self.rates[key]
        while entries and entries[0] < now-span: entries.popleft()
        if len(entries) >= limit: return True
        entries.append(now)
        # Do not retain unbounded source identities indefinitely.
        if len(self.rates) > 4096:
            self.rates = defaultdict(deque, {k:v for k,v in self.rates.items() if v and v[-1] >= now-span})
        return False

    def session(self, token):
        if not isinstance(token, str) or len(token) != 64: return None
        row = self.db.execute('''SELECT a.id,a.username,s.expires FROM accounts a JOIN sessions s
            ON a.id=s.account WHERE s.digest=? AND s.expires>?''',
            (hashlib.sha256(token.encode()).hexdigest(), int(time.time()))).fetchone()
        return dict(id=row[0], username=row[1],expires_at=row[2]) if row else None

    def issue(self, account_id):
        token = secrets.token_hex(32)
        self.db.execute('DELETE FROM sessions WHERE expires<=?', (int(time.time()),))
        self.db.execute('INSERT INTO sessions VALUES (?,?,?)',
            (hashlib.sha256(token.encode()).hexdigest(), account_id, int(time.time())+SESSION_SECONDS))
        self.db.commit()
        return token

    async def auth(self, request):
        if self.limited(('auth',request.remote)): return web.json_response({'error':'Zu viele Versuche. Bitte später erneut versuchen.'},status=429)
        try:
            data = await request.json()
            if not isinstance(data,dict): raise ValueError()
            email = data.get('email','').strip().casefold()
            password = data.get('password','')
            username = data.get('username','').strip()
            if type(data.get('protocol')) is not int or data.get('protocol') != PROTOCOL: return web.json_response({'error':'Spielversion nicht kompatibel'},status=409)
            if not isinstance(password,str) or not 10<=len(password)<=128 or not 3<=len(email)<=254 or '@' not in email:
                raise ValueError()
        except (ValueError, AttributeError, TypeError):
            return web.json_response({'error':'E-Mail und Passwort prüfen (10–128 Zeichen).'},status=400)
        row = self.db.execute('SELECT id,username,salt,password FROM accounts WHERE email=?',(email,)).fetchone()
        if request.path.endswith('/register'):
            if not 3<=len(username)<=24 or any(ord(c)<32 for c in username):
                return web.json_response({'error':'Spielername benötigt 3–24 Zeichen.'},status=400)
            if row: return web.json_response({'error':'Registrierung für diese E-Mail nicht möglich.'},status=409)
            salt = secrets.token_bytes(16)
            derived = await asyncio.to_thread(hashlib.scrypt,password.encode(),salt=salt,n=16384,r=8,p=1)
            account_id = secrets.token_hex(12)
            try:
                self.db.execute('INSERT INTO accounts VALUES (?,?,?,?,?)',(account_id,email,username,salt,derived)); self.db.commit()
            except sqlite3.IntegrityError:
                return web.json_response({'error':'Registrierung nicht möglich.'},status=409)
        else:
            salt = row[2] if row else b'constant-dummy!!'
            derived = await asyncio.to_thread(hashlib.scrypt,password.encode(),salt=salt,n=16384,r=8,p=1)
            if not row or not hmac.compare_digest(derived,row[3]):
                return web.json_response({'error':'E-Mail oder Passwort stimmt nicht.'},status=401)
            account_id,username = row[:2]
        return web.json_response({'protocol':PROTOCOL,'token':self.issue(account_id),
            'account':{'id':account_id,'username':username},'scope':'presence-preview'})

    async def websocket(self, request):
        if len(self.peers)>=MAX_CLIENTS or self.limited(('ws',request.remote),30):
            return web.json_response({'error':'Server ausgelastet'},status=429)
        ws = web.WebSocketResponse(heartbeat=20,max_msg_size=16384)
        await ws.prepare(request)
        peer = None
        try:
            hello = await asyncio.wait_for(ws.receive_json(),timeout=8)
            if not isinstance(hello,dict) or hello.get('type')!='join' or hello.get('protocol')!=PROTOCOL: raise ValueError('protocol')
            account = self.session(hello.get('token'))
            map_id = hello.get('map_id')
            if not account or type(map_id) is not int or map_id not in SEA_IDS: raise ValueError('auth/map')
            for previous,active in list(self.peers.items()):
                if active['id']==account['id']:
                    self.save_character(active)
                    await previous.close(code=1000,message=b'Session resumed elsewhere')
                    self.peers.pop(previous,None)
            if sum(p['map_id']==map_id for p in self.peers.values())>=MAX_ROOM: raise ValueError('room full')
            saved = self.db.execute('SELECT x,y,heading,skin FROM characters WHERE account=? AND map_id=?',(account['id'],map_id)).fetchone()
            peer = dict(**account,map_id=map_id,x=saved[0] if saved else 4200.,y=saved[1] if saved else 2900.,
                heading=saved[2] if saved else math.pi,skin=saved[3] if saved else 0,
                hp=2400,max_hp=2400,route=[],sequence=0,expires=time.monotonic()+max(0,account['expires_at']-time.time()))
            self.peers[ws] = peer
            await ws.send_json({'type':'welcome','protocol':PROTOCOL,'account_id':account['id'],'map_id':map_id,'tick_rate':20,'player':{k:peer[k] for k in ('x','y','heading','skin')},'scope':'presence-preview'})
            async for msg in ws:
                if msg.type!=WSMsgType.TEXT: continue
                if self.limited(('input',account['id']),40,1): continue
                try:
                    data=json.loads(msg.data)
                    if not isinstance(data,dict): continue
                    if data.get('type')=='appearance':
                        # Cosmetic preview only. Never grants inventory, damage or rewards.
                        skin,hp,maximum=data.get('skin'),data.get('hp'),data.get('max_hp')
                        if type(skin) is int and 0<=skin<=13: peer['skin']=skin
                        if type(hp) is int and type(maximum) is int and 1<=maximum<=10000000 and 0<=hp<=maximum:
                            peer.update(hp=hp,max_hp=maximum)
                        continue
                    if data.get('type')!='course': continue
                    seq=data.get('sequence')
                    if type(seq) is not int or seq<=peer['sequence'] or seq>2**31: continue
                    route=self.route(data)
                    if route is None: continue
                    peer.update(sequence=seq,route=route)
                except (ValueError,TypeError): continue
        except (ValueError,TypeError,KeyError,asyncio.TimeoutError):
            await ws.close(code=1008,message=b'Invalid session or map')
        finally:
            if peer is not None: self.save_character(peer)
            self.peers.pop(ws,None)
        return ws

    async def ticks(self,app):
        async def loop():
            previous=time.monotonic()
            while True:
                await asyncio.sleep(.05)
                now=time.monotonic(); delta=min(.1,now-previous); previous=now
                self.tick+=1
                for ws,peer in list(self.peers.items()):
                    if peer['expires']<=now: await ws.close(code=1008,message=b'Session expired');continue
                    travel=165*delta
                    while peer['route'] and travel>0:
                        dx,dy=peer['route'][0][0]-peer['x'],peer['route'][0][1]-peer['y']
                        distance=math.hypot(dx,dy); step=min(distance,travel)
                        if distance>.001:
                            peer['heading']=math.atan2(dy,dx)
                            peer['x']+=dx/distance*step;peer['y']+=dy/distance*step
                        travel-=step
                        if distance<=step: peer['route'].pop(0)
                        else: break
                    if self.tick%100==0: self.save_character(peer)
                rooms={p['map_id'] for p in self.peers.values()}
                snapshots={room: {'type':'snapshot','tick':self.tick,'map_id':room,'players':[
                    dict({k:p[k] for k in ('id','username','x','y','sequence','heading','skin','hp','max_hp')},moving=bool(p['route'])) for p in self.peers.values() if p['map_id']==room]} for room in rooms}
                for ws,peer in list(self.peers.items()):
                    try: await asyncio.wait_for(ws.send_json(snapshots[peer['map_id']]),timeout=.2)
                    except (ConnectionError,RuntimeError,asyncio.TimeoutError):
                        self.save_character(peer); self.peers.pop(ws,None); await ws.close()
        task=asyncio.create_task(loop())
        yield
        task.cancel()
        try: await task
        except asyncio.CancelledError: pass
        for ws,peer in list(self.peers.items()):
            self.save_character(peer)
            await ws.close(code=1001,message=b'Server stopping')
        self.db.close()

@web.middleware
async def headers(request,handler):
    # Explicit browser origin for hosted web crossplay, never reflect arbitrary origins.
    allowed=request.app['allowed_origin']
    origin=request.headers.get('Origin','')
    if origin and origin not in allowed: return web.json_response({'error':'Origin denied'},status=403)
    response=web.Response(status=204) if request.method=='OPTIONS' else await handler(request)
    response.headers['Cache-Control']='no-store'
    response.headers['X-Content-Type-Options']='nosniff'
    if origin:
        response.headers['Access-Control-Allow-Origin']=origin
        response.headers['Access-Control-Allow-Headers']='Content-Type'
        response.headers['Access-Control-Allow-Methods']='GET, POST, OPTIONS'
        response.headers['Vary']='Origin'
    return response

def create_app(database='abyssal.sqlite3',allowed_origin=''):
    app=web.Application(client_max_size=8192,middlewares=[headers])
    world=World(database);app['world']=world;app['allowed_origin']={item.strip() for item in allowed_origin.split(',') if item.strip()}
    app.router.add_post('/v1/register',world.auth);app.router.add_post('/v1/login',world.auth)
    app.router.add_get('/v1/world',world.websocket)
    async def health(_): return web.json_response({'status':'ready','protocol':PROTOCOL,'scope':'presence-preview'})
    app.router.add_get('/health',health)
    app.router.add_route('OPTIONS','/{tail:.*}',health)
    app.cleanup_ctx.append(world.ticks)
    return app

if __name__=='__main__':
    web.run_app(create_app(os.environ.get('ABYSSAL_DATABASE','abyssal.sqlite3'),os.environ.get('ABYSSAL_WEB_ORIGIN','')),
        host=os.environ.get('ABYSSAL_BIND','127.0.0.1'),port=int(os.environ.get('PORT','8787')),access_log=None)
