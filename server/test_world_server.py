import asyncio
import tempfile
import unittest
from pathlib import Path
from aiohttp.test_utils import TestClient, TestServer
from world_server import create_app

class CrossplayTest(unittest.IsolatedAsyncioTestCase):
    async def asyncSetUp(self):
        self.temp=tempfile.TemporaryDirectory()
        self.client=TestClient(TestServer(create_app(str(Path(self.temp.name)/'accounts.db'),'https://game.example')))
        await self.client.start_server()
    async def asyncTearDown(self):
        await self.client.close();self.temp.cleanup()
    async def account(self,email,name):
        response=await self.client.post('/v1/register',json={'protocol':2,'email':email,'username':name,'password':'test-password-937'})
        self.assertEqual(response.status,200)
        return await response.json()
    async def test_auth_isolation_sequence_and_speed(self):
        a=await self.account('one@example.com','One');b=await self.account('two@example.com','Two')
        bad=await self.client.post('/v1/login',json={'protocol':2,'email':'one@example.com','password':'incorrect-password'})
        self.assertEqual(bad.status,401)
        valid=await self.client.post('/v1/login',json={'protocol':2,'email':'one@example.com','password':'test-password-937'})
        self.assertEqual(valid.status,200)
        wa=await self.client.ws_connect('/v1/world');wb=await self.client.ws_connect('/v1/world')
        await wa.send_json({'type':'join','protocol':2,'token':a['token'],'map_id':0})
        self.assertEqual((await wa.receive_json())['type'],'welcome')
        await wb.send_json({'type':'join','protocol':2,'token':b['token'],'map_id':6})
        self.assertEqual((await wb.receive_json())['type'],'welcome')
        await wa.send_json({'type':'course','sequence':1,'x':4600,'y':3200})
        await asyncio.sleep(.16)
        snapshot=await wa.receive_json()
        self.assertEqual(len(snapshot['players']),1)
        player=snapshot['players'][0]
        self.assertEqual(player['id'],a['account']['id'])
        self.assertLess(player['x'],4250) # A course cannot teleport or set velocity.
        self.assertNotIn('token',str(snapshot))
        await wa.send_json({'type':'course','sequence':0,'x':3000,'y':1600})
        await wa.send_json({'type':'course','sequence':2,'x':float('inf'),'y':1600})
        await asyncio.sleep(.1)
        self.assertEqual(self.client.server.app['world'].peers[next(iter(self.client.server.app['world'].peers))]['sequence'],1)
        await wa.close();await wb.close()
    async def test_expanded_world_bounds_and_legacy_coordinates(self):
        from world_server import World
        self.assertIsNotNone(World.route({'route':[[8700,6300]]}))
        self.assertIsNone(World.route({'route':[[8801,6300]]}))
        self.assertIsNone(World.route({'route':[[8700,6401]]}))
        response=await self.client.post('/v1/login',json={'protocol':1,'email':'old@example.com','password':'test-password-937'})
        self.assertEqual(response.status,409)
        path=str(Path(self.temp.name)/'legacy.db')
        old=World(path)
        old.db.execute('INSERT INTO characters VALUES (?,?,?,?,?,?)',('legacy',0,2100.,1450.,0.,13))
        old.db.execute('PRAGMA user_version=0');old.db.commit();old.db.close()
        for _ in range(2):
            migrated=World(path)
            self.assertEqual(migrated.db.execute('SELECT x,y,skin FROM characters').fetchone(),(4200.,2900.,13))
            migrated.db.close()

    async def test_two_captains_share_one_room_without_economy_or_combat(self):
        first=await self.account('room-one@example.com','HarborOne')
        second=await self.account('room-two@example.com','HarborTwo')
        wa=await self.client.ws_connect('/v1/world')
        wb=await self.client.ws_connect('/v1/world')
        try:
            await wa.send_json({'type':'join','protocol':2,'token':first['token'],'map_id':0})
            self.assertEqual((await wa.receive_json())['type'],'welcome')
            await wb.send_json({'type':'join','protocol':2,'token':second['token'],'map_id':0})
            self.assertEqual((await wb.receive_json())['type'],'welcome')
            async def both(ws):
                for _ in range(30):
                    frame=await asyncio.wait_for(ws.receive_json(),timeout=2)
                    if frame.get('type')=='snapshot' and len(frame['players'])==2:return frame
                self.fail('Both captains did not receive the same online room')
            left,right=await asyncio.gather(both(wa),both(wb))
            expected={first['account']['id'],second['account']['id']}
            for frame in (left,right):
                self.assertEqual({x['id'] for x in frame['players']},expected)
                self.assertEqual(frame['map_id'],0)
                self.assertNotIn('token',str(frame))
                self.assertNotIn('password',str(frame))
                self.assertNotIn('gold',str(frame))
                self.assertEqual(frame['players'][0]['max_hp'],2400)
            await wa.send_json({'type':'course','sequence':1,'x':4400,'y':3000})
            seen_move=False
            for _ in range(30):
                frame=await asyncio.wait_for(wb.receive_json(),timeout=2)
                if frame.get('type')!='snapshot':continue
                p=next(x for x in frame['players'] if x['id']==first['account']['id'])
                if p['x']>4200:seen_move=True;break
            self.assertTrue(seen_move,'Second player must see the first player moving')
        finally:
            await wa.close()
            await wb.close()
    async def test_design_heading_hp_route_and_restart_persistence(self):
        a=await self.account('persistent@example.com','SavedCaptain')
        ws=await self.client.ws_connect('/v1/world')
        await ws.send_json({'type':'join','protocol':2,'token':a['token'],'map_id':0})
        welcome=await ws.receive_json()
        self.assertEqual(welcome['player']['y'],2900)
        await ws.send_json({'type':'appearance','skin':13,'hp':1200,'max_hp':2400})
        await ws.send_json({'type':'course','sequence':1,'route':[[4200,2910],[4210,2910]]})
        await asyncio.sleep(.25)
        world=self.client.server.app['world']
        peer=next(iter(world.peers.values()))
        self.assertEqual(peer['skin'],13)
        self.assertEqual(peer['hp'],1200)
        self.assertAlmostEqual(peer['x'],4210,delta=.1)
        self.assertAlmostEqual(peer['y'],2910,delta=.1)
        self.assertAlmostEqual(peer['heading'],0,delta=.01)
        await ws.send_json({'type':'appearance','skin':99,'hp':-1,'max_hp':2400})
        await asyncio.sleep(.06)
        self.assertEqual(peer['skin'],13)
        self.assertEqual(peer['hp'],1200)
        await ws.close()
        await asyncio.sleep(.06)
        # New World instance models process restart against the same durable file.
        from world_server import World
        restarted=World(str(Path(self.temp.name)/'accounts.db'))
        self.assertIsNotNone(restarted.session(a['token']))
        row=restarted.db.execute('SELECT x,y,skin FROM characters WHERE account=? AND map_id=0',(a['account']['id'],)).fetchone()
        self.assertEqual(row,(4210.,2910.,13))
        restarted.db.close()
        resumed=await self.client.ws_connect('/v1/world')
        await resumed.send_json({'type':'join','protocol':2,'token':a['token'],'map_id':0})
        welcome=await resumed.receive_json()
        self.assertEqual(welcome['player']['skin'],13)
        self.assertEqual(welcome['player']['x'],4210.)
        await resumed.close()

    async def test_room_switch_replaces_old_connection_and_cors_is_explicit(self):
        a=await self.account('switch@example.com','SwitchCaptain')
        first=await self.client.ws_connect('/v1/world')
        await first.send_json({'type':'join','protocol':2,'token':a['token'],'map_id':0})
        await first.receive_json()
        second=await self.client.ws_connect('/v1/world')
        await second.send_json({'type':'join','protocol':2,'token':a['token'],'map_id':6})
        welcome=await asyncio.wait_for(second.receive_json(),timeout=2)
        self.assertEqual(welcome['type'],'welcome')
        self.assertEqual(welcome['map_id'],6)
        self.assertEqual(len(self.client.server.app['world'].peers),1)
        await first.close();await second.close()
        allowed=await self.client.options('/v1/login',headers={'Origin':'https://game.example'})
        self.assertEqual(allowed.status,204)
        self.assertEqual(allowed.headers['Access-Control-Allow-Origin'],'https://game.example')
        denied=await self.client.options('/v1/login',headers={'Origin':'https://evil.example'})
        self.assertEqual(denied.status,403)

    async def test_invalid_auth_map_origin_and_duplicate(self):
        a=await self.account('one@example.com','One')
        invalid=await self.client.post('/v1/login',json=[],headers={'Origin':'https://bad.example'})
        self.assertEqual(invalid.status,403)
        ws=await self.client.ws_connect('/v1/world')
        await ws.send_json({'type':'join','protocol':2,'token':a['token'],'map_id':3})
        closed=await ws.receive();self.assertEqual(closed.type.name,'CLOSE')
        self.assertEqual(ws.close_code,1008)
        await ws.close()
        duplicate=await self.client.post('/v1/register',json={'protocol':2,'email':'one@example.com','username':'One','password':'test-password-937'})
        self.assertEqual(duplicate.status,409)
if __name__=='__main__':unittest.main()
