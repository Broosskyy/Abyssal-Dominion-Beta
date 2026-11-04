"""Server-owned guild towers and seasonal combat slice.

The gateway MUST supply authenticated captain identity, trusted server movement,
server clock, and serialized world-instance access. Never expose admin/setup
methods or this object's methods directly to untrusted client payloads.
Receipts are pending M266 settlement, not durable inventory grants.
"""

from __future__ import annotations

import json
import math
import sqlite3
from pathlib import Path


CONFIG_PATH = Path(__file__).resolve().parents[1] / "data/m301_halloween_guild_server_config.json"


class Rejected(ValueError):
    """A command failed server-side validation without changing world state."""


class HalloweenGuildDomain:
    def __init__(self, connection: sqlite3.Connection, config: dict | None = None):
        self.db = connection
        self.db.row_factory = sqlite3.Row
        self.config = config if config is not None else json.loads(CONFIG_PATH.read_text())
        self.db.executescript("""
            CREATE TABLE IF NOT EXISTS world (
              instance TEXT PRIMARY KEY, environment TEXT NOT NULL,
              event_start_ms INTEGER, event_end_ms INTEGER);
            CREATE TABLE IF NOT EXISTS entities (
              instance TEXT NOT NULL, id TEXT NOT NULL, kind TEXT NOT NULL,
              owner TEXT NOT NULL DEFAULT '', guild TEXT NOT NULL DEFAULT '',
              hp INTEGER NOT NULL, max_hp INTEGER NOT NULL, x REAL NOT NULL, z REAL NOT NULL,
              reach REAL NOT NULL DEFAULT 0, damage INTEGER NOT NULL DEFAULT 0,
              reload_ms INTEGER NOT NULL DEFAULT 0, last_fire_ms INTEGER NOT NULL DEFAULT -100000000,
              PRIMARY KEY(instance,id));
            CREATE TABLE IF NOT EXISTS wars (
              instance TEXT NOT NULL, guild TEXT NOT NULL, enemy_guild TEXT NOT NULL,
              PRIMARY KEY(instance,guild,enemy_guild));
            CREATE TABLE IF NOT EXISTS session_ammo (
              instance TEXT NOT NULL, captain TEXT NOT NULL, ammo TEXT NOT NULL,
              quantity INTEGER NOT NULL CHECK(quantity>=0), PRIMARY KEY(instance,captain,ammo));
            CREATE TABLE IF NOT EXISTS commands (
              instance TEXT NOT NULL, captain TEXT NOT NULL, request_id TEXT NOT NULL,
              result TEXT NOT NULL, PRIMARY KEY(instance,captain,request_id));
            CREATE TABLE IF NOT EXISTS contributions (
              instance TEXT NOT NULL, target TEXT NOT NULL, captain TEXT NOT NULL,
              damage INTEGER NOT NULL DEFAULT 0, PRIMARY KEY(instance,target,captain));
            CREATE TABLE IF NOT EXISTS reward_intents (
              instance TEXT NOT NULL, reward_id TEXT NOT NULL, captain TEXT NOT NULL,
              item TEXT NOT NULL, amount INTEGER NOT NULL, status TEXT NOT NULL,
              PRIMARY KEY(instance,reward_id,captain,item));
        """)

    def _entity(self, instance: str, entity_id: str) -> sqlite3.Row:
        row = self.db.execute("SELECT * FROM entities WHERE instance=? AND id=?", (instance, entity_id)).fetchone()
        if row is None:
            raise Rejected("unknown entity")
        return row

    def _world(self, instance: str) -> sqlite3.Row:
        row = self.db.execute("SELECT * FROM world WHERE instance=?", (instance,)).fetchone()
        if row is None:
            raise Rejected("unknown instance")
        return row

    def _event_active(self, instance: str, now_ms: int) -> bool:
        row = self._world(instance)
        return row["event_start_ms"] is not None and row["event_start_ms"] <= now_ms < row["event_end_ms"]

    def _reward(self, instance: str, receipt: str, captain: str, item: str, amount: int) -> None:
        self.db.execute("INSERT OR IGNORE INTO reward_intents VALUES (?,?,?,?,?,?)",
                        (instance, receipt, captain, item, amount, "PENDING_M266"))

    def _distance(self, a: sqlite3.Row, b: sqlite3.Row) -> float:
        return math.hypot(a["x"] - b["x"], a["z"] - b["z"])

    def _transaction(self, operation):
        # One writer/instance per process, backed by SQLite BEGIN IMMEDIATE.
        self.db.execute("BEGIN IMMEDIATE")
        try:
            result = operation()
            self.db.commit()
            return result
        except BaseException:
            self.db.rollback()
            raise

    # Trusted server setup and scheduler only; never forward untrusted JSON here.
    def create_world(self, instance: str, environment: str) -> None:
        if not instance or environment not in ("TEST", "GLOBAL"):
            raise Rejected("invalid instance/environment")
        with self.db:
            self.db.execute("INSERT INTO world(instance,environment) VALUES (?,?)", (instance, environment))

    def schedule_event(self, instance: str, start_ms: int, end_ms: int) -> None:
        if end_ms <= start_ms:
            raise Rejected("invalid event window")
        with self.db:
            self.db.execute("UPDATE world SET event_start_ms=?,event_end_ms=? WHERE instance=?",
                            (start_ms, end_ms, instance))

    def set_war(self, instance: str, guild: str, enemy_guild: str, active: bool) -> None:
        self._world(instance)
        if not guild or not enemy_guild or guild == enemy_guild:
            raise Rejected("invalid guild war pair")
        with self.db:
            if active:
                self.db.execute("INSERT OR IGNORE INTO wars VALUES (?,?,?)", (instance, guild, enemy_guild))
                self.db.execute("INSERT OR IGNORE INTO wars VALUES (?,?,?)", (instance, enemy_guild, guild))
            else:
                self.db.execute("DELETE FROM wars WHERE instance=? AND guild=? AND enemy_guild=?",
                                (instance, guild, enemy_guild))
                self.db.execute("DELETE FROM wars WHERE instance=? AND guild=? AND enemy_guild=?",
                                (instance, enemy_guild, guild))

    def spawn(self, instance: str, entity_id: str, kind: str, x: float, z: float,
              *, owner: str = "", guild: str = "") -> None:
        self._world(instance)
        if not entity_id or not math.isfinite(x) or not math.isfinite(z):
            raise Rejected("invalid spawn")
        if kind == "player":
            if not owner:
                raise Rejected("player needs authenticated owner")
            hp, reach, damage, reload = 600, self.config["player_range"], 0, self.config["player_reload_ms"]
        elif kind.startswith("tower:"):
            if not guild:
                raise Rejected("tower needs guild owner")
            profile = self.config["tower_profiles"].get(kind.removeprefix("tower:"))
            if profile is None:
                raise Rejected("unknown tower")
            hp, reach, damage, reload = (profile[k] for k in ("hp", "range", "damage", "reload_ms"))
        elif kind == "pumpkin":
            hp, reach, damage, reload = 1, 0, 0, 0
        elif kind == "pumpkin_wreck":
            hp, reach, damage, reload = self.config["pumpkin_wreck_hp"], 0, 0, 0
        elif kind in self.config["npc_profiles"]:
            hp, reach, damage, reload = self.config["npc_profiles"][kind], 0, 0, 0
        else:
            raise Rejected("unknown kind")
        with self.db:
            self.db.execute("INSERT INTO entities (instance,id,kind,owner,guild,hp,max_hp,x,z,reach,damage,reload_ms) "
                            "VALUES (?,?,?,?,?,?,?,?,?,?,?,?)",
                            (instance, entity_id, kind, owner, guild, hp, hp, x, z, reach, damage, reload))

    def set_server_player_position(self, instance: str, captain: str, x: float, z: float) -> None:
        """Called ONLY with a verified movement verdict from the movement service."""
        if not math.isfinite(x) or not math.isfinite(z):
            raise Rejected("invalid position")
        with self.db:
            self.db.execute("UPDATE entities SET x=?,z=? WHERE instance=? AND owner=? AND kind='player'",
                            (x, z, instance, captain))

    def provision_session_ammo(self, instance: str, captain: str, ammo: str, quantity: int) -> None:
        """Trusted inventory adapter only; this table is NOT durable M266 inventory."""
        if ammo not in ("iron", "pumpkin", "harpoon") or quantity < 0:
            raise Rejected("invalid ammunition")
        with self.db:
            self.db.execute("INSERT INTO session_ammo VALUES (?,?,?,?) ON CONFLICT(instance,captain,ammo) "
                            "DO UPDATE SET quantity=excluded.quantity", (instance, captain, ammo, quantity))

    def collect_pumpkin(self, instance: str, captain: str, pumpkin_id: str, request_id: str,
                        now_ms: int) -> dict:
        def action():
            receipt = self._existing(instance, captain, request_id)
            if receipt is not None:
                return receipt
            if not self._event_active(instance, now_ms):
                raise Rejected("event inactive")
            player = self._player(instance, captain)
            pumpkin = self._entity(instance, pumpkin_id)
            if pumpkin["kind"] != "pumpkin" or pumpkin["hp"] <= 0 or self._distance(player, pumpkin) > 4:
                raise Rejected("pumpkin unavailable or out of range")
            self.db.execute("UPDATE entities SET hp=0 WHERE instance=? AND id=?", (instance, pumpkin_id))
            reward = self.config["reward_intents"]
            self.db.execute("INSERT INTO session_ammo VALUES (?,?,?,?) ON CONFLICT(instance,captain,ammo) "
                            "DO UPDATE SET quantity=quantity+excluded.quantity",
                            (instance, captain, "pumpkin", reward["collect_pumpkin_ammo"]))
            self._reward(instance, pumpkin_id, captain, "pumpkin_tokens", reward["collect_pumpkin_tokens"])
            return self._receipt(instance, captain, request_id, {"outcome":"COLLECTED","entity_id":pumpkin_id,
                                                          "session_pumpkin_ammo":reward["collect_pumpkin_ammo"]})
        return self._transaction(action)

    def _player(self, instance: str, captain: str) -> sqlite3.Row:
        row = self.db.execute("SELECT * FROM entities WHERE instance=? AND kind='player' AND owner=? AND hp>0",
                              (instance, captain)).fetchone()
        if row is None:
            raise Rejected("no living authenticated captain")
        return row

    def _existing(self, instance: str, captain: str, request_id: str) -> dict | None:
        if not request_id:
            raise Rejected("request id required")
        row = self.db.execute("SELECT result FROM commands WHERE instance=? AND captain=? AND request_id=?",
                              (instance, captain, request_id)).fetchone()
        return json.loads(row["result"]) if row is not None else None

    def _receipt(self, instance: str, captain: str, request_id: str, result: dict) -> dict:
        self.db.execute("INSERT INTO commands VALUES (?,?,?,?)", (instance, captain, request_id, json.dumps(result)))
        return result

    def fire(self, instance: str, captain: str, target_id: str, weapon: str, ammo: str,
             request_id: str, now_ms: int) -> dict:
        def action():
            receipt = self._existing(instance, captain, request_id)
            if receipt is not None:
                return receipt
            player = self._player(instance, captain)
            target = self._entity(instance, target_id)
            if target["hp"] <= 0 or target["id"] == player["id"]:
                raise Rejected("target unavailable")
            if weapon not in ("CANNON", "HARPOON") or (weapon == "HARPOON") != (ammo == "harpoon"):
                raise Rejected("weapon/ammo mismatch")
            if weapon == "CANNON" and ammo not in ("iron", "pumpkin"):
                raise Rejected("unknown cannon ammunition")
            kind = target["kind"]
            seasonal = kind in self.config["npc_profiles"] or kind == "pumpkin_wreck"
            if seasonal and not self._event_active(instance, now_ms):
                raise Rejected("event inactive")
            if kind.startswith("tower:"):
                at_war = self.db.execute("SELECT 1 FROM wars WHERE instance=? AND guild=? AND enemy_guild=?",
                                         (instance, target["guild"], player["guild"])).fetchone()
                if at_war is None or target["guild"] == player["guild"]:
                    raise Rejected("tower not hostile")
            elif not seasonal:
                raise Rejected("invalid attack target")
            if kind == "pumpkin_wreck" and weapon != "HARPOON":
                raise Rejected("pumpkin wreck requires harpoon")
            if self._distance(player, target) > player["reach"]:
                raise Rejected("out of range")
            if now_ms - player["last_fire_ms"] < player["reload_ms"]:
                raise Rejected("reloading")
            stocked = self.db.execute("SELECT quantity FROM session_ammo WHERE instance=? AND captain=? AND ammo=?",
                                      (instance, captain, ammo)).fetchone()
            if stocked is None or stocked["quantity"] < 1:
                raise Rejected("no server-stocked ammo")
            base = self.config["base_harpoon_damage"] if weapon == "HARPOON" else self.config["base_cannon_damage"]
            # Pumpkin is only stronger against marked event NPCs. The server, not a client impact VFX,
            # chooses the ammunition profile and clamps to remaining HP.
            multiplier = self.config["pumpkin_event_damage_multiplier"] if ammo == "pumpkin" and kind in self.config["npc_profiles"] else 1
            amount = min(target["hp"], 1 if kind == "pumpkin_wreck" else int(base * multiplier))
            remaining = target["hp"] - amount
            self.db.execute("UPDATE entities SET hp=? WHERE instance=? AND id=?", (remaining, instance, target_id))
            self.db.execute("UPDATE entities SET last_fire_ms=? WHERE instance=? AND id=?", (now_ms, instance, player["id"]))
            self.db.execute("UPDATE session_ammo SET quantity=quantity-1 WHERE instance=? AND captain=? AND ammo=?",
                            (instance, captain, ammo))
            if kind in self.config["npc_profiles"]:
                self.db.execute("INSERT INTO contributions VALUES (?,?,?,?) ON CONFLICT(instance,target,captain) "
                                "DO UPDATE SET damage=damage+excluded.damage", (instance, target_id, captain, amount))
            if remaining == 0:
                self._settle_defeat(instance, captain, target_id, kind)
            return self._receipt(instance, captain, request_id,
                                 {"outcome":"HIT","damage":amount,"target_hp":remaining,
                                  "defeated":remaining == 0,"target_id":target_id})
        return self._transaction(action)

    def _settle_defeat(self, instance: str, captain: str, target_id: str, kind: str) -> None:
        rewards = self.config["reward_intents"]
        if kind == "pumpkin_wreck":
            self._reward(instance, target_id, captain, "pumpkin_tokens", rewards["pumpkin_wreck_tokens"])
        elif kind == "event_halloween_boss_01":
            leader = self.db.execute("SELECT captain FROM contributions WHERE instance=? AND target=? "
                                     "ORDER BY damage DESC,captain ASC LIMIT 1", (instance, target_id)).fetchone()
            if leader is not None:
                policy = self.config["boss_ship_design_award_policy"]
                if policy not in ("TOP_DAMAGE", "LAST_HIT"):
                    raise Rejected("invalid boss prize policy")
                design_winner = leader["captain"] if policy == "TOP_DAMAGE" else captain
                self._reward(instance, target_id, design_winner, rewards["boss_top_damage_ship_design"], 1)
                self._reward(instance, target_id, leader["captain"], "pumpkin_tokens", rewards["boss_top_damage_tokens"])
            self._reward(instance, target_id + ":final_blow", captain, "pumpkin_tokens", rewards["boss_final_blow_tokens"])
        elif kind in self.config["npc_profiles"]:
            self._reward(instance, target_id, captain, "pumpkin_tokens", rewards["event_npc_tokens"])

    def tick_towers(self, instance: str, now_ms: int) -> list[dict]:
        """Server tick: nearest valid war enemy, server-owned cooldown and HP; no client fire intent."""
        def action():
            self._world(instance)
            towers = self.db.execute("SELECT * FROM entities WHERE instance=? AND kind LIKE 'tower:%' AND hp>0 ORDER BY id",
                                     (instance,)).fetchall()
            events = []
            for tower in towers:
                if now_ms - tower["last_fire_ms"] < tower["reload_ms"]:
                    continue
                candidates = self.db.execute(
                    "SELECT p.* FROM entities p JOIN wars w ON w.instance=p.instance "
                    "AND w.guild=? AND w.enemy_guild=p.guild WHERE p.instance=? AND p.kind='player' AND p.hp>0",
                    (tower["guild"], instance)).fetchall()
                in_range = [p for p in candidates if self._distance(tower, p) <= tower["reach"]]
                if not in_range:
                    continue
                target = min(in_range, key=lambda p: (self._distance(tower, p), p["id"]))
                amount = min(tower["damage"], target["hp"])
                self.db.execute("UPDATE entities SET hp=hp-? WHERE instance=? AND id=?", (amount, instance, target["id"]))
                self.db.execute("UPDATE entities SET last_fire_ms=? WHERE instance=? AND id=?", (now_ms, instance, tower["id"]))
                events.append({"tower_id":tower["id"],"target_id":target["id"],"damage":amount,
                               "target_hp":target["hp"] - amount})
            return events
        return self._transaction(action)

    def snapshot(self, instance: str, now_ms: int) -> dict:
        world = self._world(instance)
        return {"source":"SERVER_DOMAIN","environment":world["environment"],"instance":instance,
                "event_active":self._event_active(instance, now_ms),
                "entities":[dict(row) for row in self.db.execute("SELECT * FROM entities WHERE instance=? ORDER BY id", (instance,))],
                "pending_rewards":[dict(row) for row in self.db.execute(
                    "SELECT * FROM reward_intents WHERE instance=? ORDER BY reward_id,captain,item", (instance,))]}
