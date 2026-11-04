import sqlite3
import unittest

from server.halloween_guild_domain import HalloweenGuildDomain, Rejected


class HalloweenGuildServerTests(unittest.TestCase):
    def setUp(self):
        self.db = sqlite3.connect(":memory:")
        self.domain = HalloweenGuildDomain(self.db)
        self.domain.create_world("sea-1", "TEST")
        self.domain.schedule_event("sea-1", 1000, 100000)
        self.domain.spawn("sea-1", "ship-a", "player", 0, 0, owner="a", guild="blue")
        self.domain.spawn("sea-1", "ship-b", "player", 0, 1, owner="b", guild="green")
        for captain in ("a", "b"):
            for ammo in ("iron", "pumpkin", "harpoon"):
                self.domain.provision_session_ammo("sea-1", captain, ammo, 100)

    def tearDown(self):
        self.db.close()

    def entity(self, entity_id):
        return self.domain._entity("sea-1", entity_id)

    def test_live_window_is_server_scheduled_not_client_clock(self):
        self.domain.spawn("sea-1", "npc", "event_halloween_npc_sloop_01", 3, 0)
        with self.assertRaises(Rejected):
            self.domain.fire("sea-1", "a", "npc", "CANNON", "iron", "before", 999)
        self.assertEqual(self.domain.fire("sea-1", "a", "npc", "CANNON", "iron", "during", 1000)["damage"], 35)
        with self.assertRaises(Rejected):
            self.domain.fire("sea-1", "b", "npc", "CANNON", "iron", "after", 100000)

    def test_pumpkin_ammo_bonus_only_against_event_npcs(self):
        self.domain.spawn("sea-1", "npc", "event_halloween_npc_raider_01", 3, 0)
        hit = self.domain.fire("sea-1", "a", "npc", "CANNON", "pumpkin", "p-1", 2000)
        self.assertEqual(hit["damage"], int(35 * 1.35))
        self.domain.spawn("sea-1", "tower", "tower:cannon", 3, 0, guild="red")
        self.domain.set_war("sea-1", "red", "blue", True)
        self.assertEqual(self.domain.fire("sea-1", "a", "tower", "CANNON", "pumpkin", "p-2", 4000)["damage"], 35)

    def test_pumpkin_pickup_is_proximity_checked_single_claim_and_replay_safe(self):
        self.domain.spawn("sea-1", "pumpkin-1", "pumpkin", 2, 0)
        result = self.domain.collect_pumpkin("sea-1", "a", "pumpkin-1", "collect-1", 2000)
        self.assertEqual(result, self.domain.collect_pumpkin("sea-1", "a", "pumpkin-1", "collect-1", 2001))
        self.assertEqual(self.entity("pumpkin-1")["hp"], 0)
        self.assertEqual(self.db.execute("SELECT quantity FROM session_ammo WHERE captain='a' AND ammo='pumpkin'").fetchone()[0], 102)
        with self.assertRaises(Rejected):
            self.domain.collect_pumpkin("sea-1", "b", "pumpkin-1", "collect-2", 2001)
        self.domain.spawn("sea-1", "pumpkin-far", "pumpkin", 90, 90)
        with self.assertRaises(Rejected):
            self.domain.collect_pumpkin("sea-1", "a", "pumpkin-far", "collect-3", 2001)

    def test_wreck_requires_harpoon_and_rewards_once_on_defeat(self):
        self.domain.spawn("sea-1", "wreck", "pumpkin_wreck", 3, 0)
        with self.assertRaises(Rejected):
            self.domain.fire("sea-1", "a", "wreck", "CANNON", "pumpkin", "no", 2000)
        for i in range(3):
            result = self.domain.fire("sea-1", "a", "wreck", "HARPOON", "harpoon", f"h-{i}", 2000+i*1800)
        self.assertTrue(result["defeated"])
        self.assertEqual(len(self.domain.snapshot("sea-1", 8000)["pending_rewards"]), 1)
        with self.assertRaises(Rejected):
            self.domain.fire("sea-1", "a", "wreck", "HARPOON", "harpoon", "h-4", 8000)

    def test_enemy_tower_shoots_server_tick_only_during_war_and_can_be_destroyed(self):
        self.domain.spawn("sea-1", "tower", "tower:cannon", 3, 0, guild="red")
        self.assertEqual(self.domain.tick_towers("sea-1", 2000), [])
        with self.assertRaises(Rejected):
            self.domain.fire("sea-1", "a", "tower", "CANNON", "iron", "peacetime", 2000)
        self.domain.set_war("sea-1", "red", "blue", True)
        first = self.domain.tick_towers("sea-1", 2000)
        self.assertEqual(len(first), 1)
        self.assertEqual(first[0]["damage"], 32)
        self.assertEqual(first[0]["target_id"], "ship-a")  # green guild is neutral
        with self.assertRaises(Rejected):
            self.domain.fire("sea-1", "b", "tower", "CANNON", "iron", "neutral-shot", 2000)
        self.assertEqual(self.domain.tick_towers("sea-1", 3000), [])
        self.assertEqual(len(self.domain.tick_towers("sea-1", 6000)), 1)
        with self.db:
            self.db.execute("UPDATE entities SET hp=1 WHERE instance='sea-1' AND id='tower'")
        result = self.domain.fire("sea-1", "a", "tower", "CANNON", "iron", "kill", 6000)
        self.assertTrue(result["defeated"])
        self.assertEqual(self.domain.tick_towers("sea-1", 11000), [])

    def test_boss_design_follows_top_effective_damage_final_shot_separate(self):
        self.domain.spawn("sea-1", "boss", "event_halloween_boss_01", 3, 0)
        # Reaching the last 100 HP after preceding canonical combat is a trusted server test fixture.
        with self.db:
            self.db.execute("UPDATE entities SET hp=100 WHERE instance='sea-1' AND id='boss'")
        self.domain.fire("sea-1", "a", "boss", "CANNON", "pumpkin", "a-1", 2000)
        self.domain.fire("sea-1", "a", "boss", "CANNON", "iron", "a-2", 4000)
        final = self.domain.fire("sea-1", "b", "boss", "CANNON", "pumpkin", "b-last", 4000)
        self.assertEqual(final["damage"], 18)
        self.assertEqual(final, self.domain.fire("sea-1", "b", "boss", "CANNON", "pumpkin", "b-last", 4000))
        rows = self.domain.snapshot("sea-1", 5000)["pending_rewards"]
        design = [r for r in rows if r["item"] == "event_halloween_ship_design_01"]
        self.assertEqual([(r["captain"], r["status"]) for r in design], [("a", "PENDING_M266")])
        self.assertTrue(any(r["captain"] == "b" and r["amount"] == 150 for r in rows))
        self.assertEqual(self.db.execute("SELECT quantity FROM session_ammo WHERE captain='b' AND ammo='pumpkin'").fetchone()[0], 99)

    def test_last_hit_ship_design_policy_is_server_configured(self):
        self.domain.config["boss_ship_design_award_policy"] = "LAST_HIT"
        self.domain.spawn("sea-1", "boss", "event_halloween_boss_01", 3, 0)
        with self.db:
            self.db.execute("UPDATE entities SET hp=90 WHERE instance='sea-1' AND id='boss'")
        self.domain.fire("sea-1", "a", "boss", "CANNON", "pumpkin", "a1", 2000)
        self.domain.fire("sea-1", "a", "boss", "CANNON", "iron", "a2", 4000)
        self.domain.fire("sea-1", "b", "boss", "CANNON", "iron", "b1", 4000)
        rewards = self.domain.snapshot("sea-1", 5000)["pending_rewards"]
        design = [r for r in rewards if r["item"] == "event_halloween_ship_design_01"]
        self.assertEqual([r["captain"] for r in design], ["b"])
        self.assertTrue(any(r["captain"] == "a" and r["amount"] == 500 for r in rewards))

    def test_cross_instance_identity_and_revision_fail_closed(self):
        self.domain.spawn("sea-1", "npc", "event_halloween_npc_sloop_01", 70, 0)
        with self.assertRaises(Rejected):
            self.domain.fire("sea-1", "a", "npc", "CANNON", "iron", "too-far", 2000)
        self.domain.create_world("sea-2", "GLOBAL")
        self.assertFalse(self.domain.snapshot("sea-2", 2000)["event_active"])
        with self.assertRaises(Rejected):
            self.domain.collect_pumpkin("sea-2", "a", "npc", "foreign", 2000)

    def test_war_pair_revocation_stops_tower_fire_and_player_hits(self):
        self.domain.spawn("sea-1", "tower", "tower:ward", 3, 0, guild="red")
        self.domain.set_war("sea-1", "red", "blue", True)
        self.assertEqual(len(self.domain.tick_towers("sea-1", 2000)), 1)
        self.domain.set_war("sea-1", "red", "blue", False)
        self.assertEqual(self.domain.tick_towers("sea-1", 9000), [])
        with self.assertRaises(Rejected):
            self.domain.fire("sea-1", "a", "tower", "CANNON", "iron", "peace", 9000)


if __name__ == "__main__":
    unittest.main()
