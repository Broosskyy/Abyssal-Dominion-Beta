"""Optional Supabase Auth identity bridge for the existing authoritative sea sandbox.

Never expose ABYSSAL_SUPABASE_SERVICE_ROLE_KEY to Godot, browsers, APKs,
client logs or public source control. The public key only validates Auth calls.
"""
import os
import re
import time
from urllib.parse import quote

from aiohttp import ClientSession, ClientTimeout

UUID = re.compile(r"^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$")


class SupabaseIdentity:
    def __init__(self):
        self.url = os.environ.get("ABYSSAL_SUPABASE_URL", "").rstrip("/")
        self.publishable_key = os.environ.get("ABYSSAL_SUPABASE_PUBLISHABLE_KEY", "")
        self.service_key = os.environ.get("ABYSSAL_SUPABASE_SERVICE_ROLE_KEY", "")
        self.enabled = self.url.startswith("https://") and bool(self.publishable_key)
        self.persistence_enabled = self.enabled and bool(self.service_key)

    async def verify(self, token):
        """Ask GoTrue to validate the access JWT. Do NOT decode unverified claims."""
        if not self.enabled or not isinstance(token, str) or len(token) > 8192 or len(token) < 32:
            return None
        headers = {"apikey": self.publishable_key, "Authorization": "Bearer " + token}
        try:
            async with ClientSession(timeout=ClientTimeout(total=6)) as http:
                async with http.get(self.url + "/auth/v1/user", headers=headers) as response:
                    if response.status != 200:
                        return None
                    user = await response.json()
        except (OSError, TimeoutError, ValueError):
            return None
        uid = user.get("id")
        if not isinstance(uid, str) or not UUID.fullmatch(uid):
            return None
        meta = user.get("user_metadata") or {}
        username = meta.get("username", "") if isinstance(meta, dict) else ""
        if not isinstance(username, str) or not 3 <= len(username) <= 24:
            username = "Captain_" + uid[:8]
        return {"id": uid, "username": username, "expires_at": int(time.time()) + 3600}

    async def exchange(self, request, protocol):
        """Compatibility proxy for old client builds. Current Godot calls Auth directly."""
        from aiohttp import web
        try:
            data = await request.json()
            email, password = data.get("email", ""), data.get("password", "")
            username = data.get("username", "")
            if data.get("protocol") != protocol or not isinstance(email, str) or not isinstance(password, str):
                raise ValueError()
            if not 3 <= len(email) <= 254 or not 10 <= len(password) <= 128:
                raise ValueError()
            register = request.path.endswith("/register")
            if register and (not isinstance(username, str) or not 3 <= len(username) <= 24):
                raise ValueError()
        except (ValueError, AttributeError, TypeError):
            return web.json_response({"error": "Ungültige Anmeldedaten."}, status=400)
        url = self.url + ("/auth/v1/signup" if register else "/auth/v1/token?grant_type=password")
        body = {"email": email.strip(), "password": password}
        if register:
            body["data"] = {"username": username.strip()}
        try:
            async with ClientSession(timeout=ClientTimeout(total=9)) as http:
                async with http.post(url, headers={"apikey": self.publishable_key}, json=body) as response:
                    result = await response.json()
                    if response.status >= 400:
                        return web.json_response({"error": "Registrierung oder Anmeldung fehlgeschlagen."}, status=response.status)
        except (OSError, TimeoutError, ValueError):
            return web.json_response({"error": "Identitätsdienst nicht erreichbar."}, status=503)
        token = result.get("access_token")
        user = result.get("user") or {}
        if not isinstance(token, str) or not isinstance(user, dict):
            return web.json_response({"error": "Bitte E-Mail bestätigen und danach anmelden."}, status=409)
        uid = user.get("id", "")
        meta = user.get("user_metadata") or {}
        return web.json_response({
            "protocol": protocol, "token": token,
            "account": {"id": uid, "username": meta.get("username", "Kapitän")},
            "scope": "presence-preview",
        })

    async def _postgrest(self, method, endpoint, payload, extra_headers=None):
        if not self.persistence_enabled:
            return False
        headers = {
            "apikey": self.service_key,
            "Authorization": "Bearer " + self.service_key,
            "Content-Type": "application/json",
        }
        headers.update(extra_headers or {})
        try:
            async with ClientSession(timeout=ClientTimeout(total=6)) as http:
                async with http.request(method, self.url + endpoint, headers=headers, json=payload) as response:
                    return 200 <= response.status < 300
        except (OSError, TimeoutError, ValueError):
            return False

    @staticmethod
    def _position(peer, online):
        return {
            "account_id": peer["id"],
            "map_id": peer["map_id"],
            "pos_x": round(peer["x"], 3),
            "pos_y": round(peer["y"], 3),
            "heading": float(peer["heading"]),
            "design_index": int(peer["skin"]),
            "route_sequence": int(peer["sequence"]),
            "online": bool(online),
        }

    async def mark_join(self, peer):
        if not self.persistence_enabled:
            return False
        if not UUID.fullmatch(peer["id"]):
            return False
        # The map change and the position are pushed from the authoritative
        # server, never from a client-controlled REST mutation.
        map_ok = await self._postgrest(
            "PATCH", "/rest/v1/captains?account_id=eq." + quote(peer["id"]),
            {"current_map_id": peer["map_id"]},
        )
        pos_ok = await self._postgrest(
            "POST", "/rest/v1/captain_positions?on_conflict=account_id",
            [self._position(peer, True)],
            {"Prefer": "resolution=merge-duplicates"},
        )
        return map_ok and pos_ok

    async def sync_positions(self, peers):
        if not self.persistence_enabled or not peers:
            return False
        values = [self._position(peer, True) for peer in peers if UUID.fullmatch(peer["id"])]
        if not values:
            return False
        return await self._postgrest(
            "POST", "/rest/v1/captain_positions?on_conflict=account_id",
            values,
            {"Prefer": "resolution=merge-duplicates"},
        )

    async def mark_leave(self, peer):
        if not self.persistence_enabled or not UUID.fullmatch(peer["id"]):
            return False
        return await self._postgrest(
            "PATCH", "/rest/v1/captain_positions?account_id=eq." + quote(peer["id"]),
            {"online": False},
        )
