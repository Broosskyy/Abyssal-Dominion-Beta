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
        response=await self.client.post('/v1/register',json={'protocol':1,'email':email,'username':name,'password':'test-password-937'})
        self.assertEqual(response.status,200)
        return await response.json()
    async def test_auth_isolation_sequence_and_speed(self):
        a=await self.account('one@example.com','One');b=await self.account('two@example.com','Two')
        bad=await self.client.post('/v1/login',json={'protocol':1,'email':'one@example.com','password':'incorrect-password'})
        self.assertEqual(bad.status,401)
        valid=await self.client.post('/v1/login',json={'protocol':1,'email':'one@example.com','password':'test-password-937'})
        self.assertEqual(valid.status,200)
        wa=await self.client.ws_connect('/v1/world');wb=await self.client.ws_connect('/v1/world')
        await wa.send_json({'type':'join','protocol':1,'token':a['token'],'map_id':0})
        self.assertEqual((await wa.receive_json())['type'],'welcome')
        await wb.send_json({'type':'join','protocol':1,'token':b['token'],'map_id':6})
        self.assertEqual((await wb.receive_json())['type'],'welcome')
        await wa.send_json({'type':'course','sequence':1,'x':2300,'y':1600})
        await asyncio.sleep(.16)
        snapshot=await wa.receive_json()
        self.assertEqual(len(snapshot['players']),1)
        player=snapshot['players'][0]
        self.assertEqual(player['id'],a['account']['id'])
        self.assertLess(player['x'],2150) # A course cannot teleport or set velocity.
        self.assertNotIn('token',str(snapshot))
        await wa.send_json({'type':'course','sequence':0,'x':3000,'y':1600})
        await wa.send_json({'type':'course','sequence':2,'x':float('inf'),'y':1600})
        await asyncio.sleep(.1)
        self.assertEqual(self.client.server.app['world'].peers[next(iter(self.client.server.app['world'].peers))]['sequence'],1)
        await wa.close();await wb.close()
    async def test_invalid_auth_map_origin_and_duplicate(self):
        a=await self.account('one@example.com','One')
        invalid=await self.client.post('/v1/login',json=[],headers={'Origin':'https://bad.example'})
        self.assertEqual(invalid.status,403)
        ws=await self.client.ws_connect('/v1/world')
        await ws.send_json({'type':'join','protocol':1,'token':a['token'],'map_id':3})
        closed=await ws.receive();self.assertEqual(closed.type.name,'CLOSE')
        self.assertEqual(ws.close_code,1008)
        await ws.close()
        duplicate=await self.client.post('/v1/register',json={'protocol':1,'email':'one@example.com','username':'One','password':'test-password-937'})
        self.assertEqual(duplicate.status,409)
if __name__=='__main__':unittest.main()
