# M7 – SeeFight Unity source recovery

## Ergebnis

Die drei bereitgestellten Archive wurden als Unity-2021.3.45f1-Build ausgewertet. Die Rohdaten bleiben ein nachvollziehbarer Test-/Referenzbestand und sind in allen Godot-Release-Presets ausgeschlossen.

| Bereich | Gefunden |
| --- | ---: |
| Serialisierte Unity-Objekte | 196,237 |
| GameObjects | 51,618 |
| MonoBehaviour-Komponenten | 13,705 |
| Script-Typen gesamt | 2,593 |
| Projektspezifische Script-Typen | 793 |
| Texturen | 1,559 |
| Sprites | 871 |
| Meshes | 660 |
| Materialien | 740 |
| Animationen | 35 |
| AudioClips | 8 |

## Wiederhergestellte Systemgruppen

- **ships_and_combat**: 110 Typen. `Code.Core.Common.Installers.ShipVisualObjectsInstaller`, `Code.Core.GameShop.Assistants.AmmoItemsShopViewModel`, `Code.Core.GameShop.Assistants.ShipAssistantShopService`, `Code.Core.GameShop.Assistants.ShipAssistantsShopViewModel`, `Code.Core.GameShop.Ships.ShipShopViewModel`, `Code.Core.GameShop.UI.UIPlayerShipsShop`, `Code.Core.GameShop.UI.UIShipAssistantsShop`, `Code.Core.PlayerInventory.ShipDeckData`

- **world_ports_islands**: 80 Typen. `CastleSlotType`, `CastleType`, `ChestRewardGenerator`, `Code.Core.Castles.CastlePurchaseRepository`, `Code.Core.Castles.CastleRefundRpcClient`, `Code.Core.Castles.CastleService`, `Code.Core.Castles.CastlesDataDTO`, `Code.Core.Castles.CastlesDataSO`

- **quests_progression**: 111 Typen. `AchievementProgressType`, `ChestRewardGenerator`, `Code.Core.Achievements.AchievementClaimRepository`, `Code.Core.Achievements.AchievementDefinition`, `Code.Core.Achievements.AchievementProgress.AchievementCalculator`, `Code.Core.Achievements.AchievementProgress.AchievementProgress`, `Code.Core.Achievements.AchievementProgress.CompletedAchievement`, `Code.Core.Achievements.AchievementSO`

- **economy_inventory**: 159 Typen. `Code.Core.Achievements.CurrencyReward`, `Code.Core.Auction.AuctionItem`, `Code.Core.Auction.ClientAuctionController`, `Code.Core.Auction.FirestoreAuctionRepository`, `Code.Core.Auction.ServerAuctionController`, `Code.Core.Auction.TestAuctionService`, `Code.Core.BonusCode.BonusCodeFirestoreModel`, `Code.Core.Castles.CastlePurchaseRepository`

- **social_guild_chat**: 71 Typen. `ChatController`, `Code.Core.Guilds.DonationSystem.Client.GuildDonationHistoryReaderService`, `Code.Core.Guilds.DonationSystem.Client.GuildDonationHistoryViewModel`, `Code.Core.Guilds.DonationSystem.Client.GuildWalletReaderRepository`, `Code.Core.Guilds.DonationSystem.Client.GuildWalletReaderService`, `Code.Core.Guilds.DonationSystem.Client.GuildWalletViewModel`, `Code.Core.Guilds.DonationSystem.Client.UI.DonationRecordRowPrefab`, `Code.Core.Guilds.DonationSystem.Client.UI.GuildDonationHistoryView`

- **network_backend**: 133 Typen. `AdmiralSpawnedNetworkInfo`, `Code.Core.Achievements.Repositories.PlayFabAchievementDefinitionRepository`, `Code.Core.ArenaRankSystem.FastArenaMatchMaking`, `Code.Core.ArenaRankSystem.MatchmakingHistory`, `Code.Core.Auction.FirestoreAuctionRepository`, `Code.Core.Auction.ServerAuctionController`, `Code.Core.BonusCode.BonusCodeFirestoreModel`, `Code.Core.Chest.NetworkChest`

- **ui_input_mobile**: 249 Typen. `CameraChanger`, `CameraShake`, `Code.Core.Achievements.UI.AchievementCardView`, `Code.Core.Achievements.UI.AchievementProgressDTO`, `Code.Core.Achievements.UI.PlayerAchievementsView`, `Code.Core.Castles.UICastleRowInfo`, `Code.Core.Castles.UICastleSlot`, `Code.Core.Castles.UICastlesShop`

## Grenzen der Rekonstruktion

Der PC-Build ist IL2CPP-kompiliert. Klassen-/Namespace-Namen, serialisierte Komponenten, Szenenstruktur, Asset-Daten und Konfigurationen sind auslesbar; der ursprüngliche C#-Quelltext mit Kommentaren und exakter Formatierung ist nicht Bestandteil des Builds. Godot-Systeme werden daher funktionsgleich aus den wiederhergestellten Strukturen neu implementiert.

413 Texture2D-Objekte konnten nicht direkt als PNG dekodiert werden; davon meldeten 394 ein nicht unterstütztes Format/Layout und 19 einen ungültigen Ressourcenpfad. Sie bleiben im Originalarchiv und im Inventar referenziert. Alle 660 Meshes, 740 Materialbeschreibungen, 35 Animationen, 26 TextAssets und acht AudioClips wurden gesichert; die PCM-Audios wurden zusätzlich als WAV erzeugt.

## Plattformregel

Die vollständigen Unity-Referenzpakete sind nicht Teil von Android-, iOS-, Web- oder Desktop-Releases. Für Produktion werden daraus optimierte Godot-Assets bzw. neu lizenzierte/erstellte Ersatzassets abgeleitet.
