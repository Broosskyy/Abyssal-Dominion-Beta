"""No-network regression tests for the Supabase identity bridge."""
import os
import unittest
from unittest.mock import patch

from supabase_identity import SupabaseIdentity


class FakeResponse:
    def __init__(self, status, payload):
        self.status = status
        self.payload = payload

    async def __aenter__(self):
        return self

    async def __aexit__(self, *args):
        return False

    async def json(self):
        return self.payload


class FakeSession:
    def __init__(self, status, payload):
        self.status = status
        self.payload = payload
        self.headers_seen = None

    async def __aenter__(self):
        return self

    async def __aexit__(self, *args):
        return False

    def get(self, url, headers):
        self.headers_seen = headers
        return FakeResponse(self.status, self.payload)


class IdentityTest(unittest.IsolatedAsyncioTestCase):
    def config(self, service_key=""):
        return patch.dict(os.environ, {
            "ABYSSAL_SUPABASE_URL": "https://test.supabase.co",
            "ABYSSAL_SUPABASE_PUBLISHABLE_KEY": "sb_publishable_safe_test_only",
            "ABYSSAL_SUPABASE_SERVICE_ROLE_KEY": service_key,
        })

    async def test_identity_not_configured(self):
        with patch.dict(os.environ, {
            "ABYSSAL_SUPABASE_URL": "",
            "ABYSSAL_SUPABASE_PUBLISHABLE_KEY": "",
            "ABYSSAL_SUPABASE_SERVICE_ROLE_KEY": "",
        }):
            identity = SupabaseIdentity()
            self.assertFalse(identity.enabled)
            self.assertFalse(identity.persistence_enabled)
            self.assertIsNone(await identity.verify("not-a-session"))

    async def test_reject_invalid_jwt_shape(self):
        with self.config():
            identity = SupabaseIdentity()
            self.assertIsNone(await identity.verify("bad"))
            self.assertIsNone(await identity.verify(None))
            self.assertFalse(identity.persistence_enabled)

    async def test_authorizes_only_gotrue_verified_user(self):
        valid_uuid = "49b31be1-bdf4-40be-9965-1bc67b31f62d"
        token = "x" * 64
        with self.config():
            identity = SupabaseIdentity()
            session = FakeSession(200, {
                "id": valid_uuid, "is_anonymous": False,
                "user_metadata": {"username": "BetaCaptain"},
            })
            with patch("supabase_identity.ClientSession", return_value=session):
                account = await identity.verify(token)
            self.assertEqual(account["id"], valid_uuid)
            self.assertEqual(account["username"], "BetaCaptain")
            self.assertEqual(session.headers_seen["Authorization"], "Bearer " + token)

    async def test_rejects_unverified_and_anonymous(self):
        with self.config():
            identity = SupabaseIdentity()
            for status, payload in [
                (401, {}), (200, {"id": "not-uuid"}),
                (200, {"id": "49b31be1-bdf4-40be-9965-1bc67b31f62d", "is_anonymous": True}),
            ]:
                with self.subTest(status=status, payload=payload):
                    with patch("supabase_identity.ClientSession", return_value=FakeSession(status, payload)):
                        self.assertIsNone(await identity.verify("x" * 64))

    def test_snapshot_has_shared_map_coordinates(self):
        from datetime import datetime
        peer = {"id": "49b31be1-bdf4-40be-9965-1bc67b31f62d", "map_id": 6,
                "x": 1200.25, "y": 2222.0, "heading": 0.25, "skin": 4, "sequence": 8}
        state = SupabaseIdentity._position(peer, True)
        self.assertEqual((state["pos_x"], state["pos_y"], state["map_id"]), (1200.25, 2222.0, 6))
        self.assertEqual(state["route_sequence"], 8)
        datetime.fromisoformat(state["updated_at"])


if __name__ == "__main__":
    unittest.main()
