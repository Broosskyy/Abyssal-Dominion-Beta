# Signierschlüssel – Stand und nächste Schritte

## Stand (4. Nov. 2026)

- Die APK **und** die Daten-Updates werden mit **einem** Schlüssel signiert: dem Android-Debug-Keystore (Zertifikat-SHA-256 `278a2899…3b`, Passwort `android`). Den öffentlichen Daten-Schlüssel leitet die CI daraus ab (`rebuild/m3052/updater/data_public.pem`).
- Das Secret `ABYSSAL_ANDROID_KEYSTORE_BASE64` ist **leer** (siehe Log von Lauf 48). Den Keystore gibt es nur im Actions-Cache `m3052-private-debug-signing-v1`.
- Das ist doppelt riskant:
  1. **Verlust:** GitHub löscht Caches, auf die 7 Tage lang nicht zugegriffen wurde. Ohne den Schlüssel kann keine installierte App je wieder ein Update bekommen, weder als APK noch als Daten-Paket.
  2. **Offenlegung:** Das Repo ist öffentlich. Bei Pull Requests aus Forks können Workflows Caches des Standard-Branches wiederherstellen. Schutz bietet dann nur die Freigabepflicht für Erst-Beitragende.

## Sicherheitsnetz (schon aktiv)

`.github/workflows/signing-keepalive.yml` greift alle 2 Tage auf den Cache zu und prüft das Zertifikat. Fehlt der Schlüssel, schlägt der Workflow rot fehl. `m3052.yml` warnt bei jedem Build, solange das Secret fehlt.

## Schritt 1 – Keystore ins Secret übertragen (einmalig, ~5 Min.)

1. Lege auf GitHub ein Fine-grained Token an: Settings → Developer settings → Fine-grained tokens. Wähle nur dieses Repo und die Berechtigung **Secrets: Read and write**, mit kurzer Laufzeit.
2. Lege im Repo unter Settings → Secrets and variables → Actions das Secret `SECRETS_ADMIN_TOKEN` mit diesem Token an.
3. Optional für eine verschlüsselte Offline-Sicherung: Lege das Secret `BACKUP_PASSPHRASE` mit einer langen Passphrase an und notiere sie dir offline.
4. Starte unter Actions → **Store signing keystore as secret** → Run workflow.
5. Lade danach das Artefakt `encrypted-signing-backup` herunter (falls angelegt) und bewahre es offline auf. Das Artefakt wird nach 1 Tag gelöscht.
6. Lösche das Secret `SECRETS_ADMIN_TOKEN` und widerrufe das Token.
7. Danach kann der Cache weg (Actions → Caches), außerdem `signing-keepalive.yml`, `store-signing-secret.yml` und der `actions/cache`-Schritt in `m3052.yml`.

## Schritt 2 – Getrennter Schlüssel für Daten-Updates (mit der nächsten neuen APK)

Die CI unterstützt das bereits. Ist das Secret `ABYSSAL_CONTENT_SIGNING_KEY` gesetzt (RSA-2048-Private-Key im PEM-Format), werden die Daten-Pakete damit signiert statt mit dem APK-Schlüssel.

```bash
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out content-signing.pem
```

**Wichtig:** Ein neuer Daten-Schlüssel ändert den öffentlichen Schlüssel in der App. Installierte Apps akzeptieren deshalb erst nach einem APK-Update Daten-Pakete mit dem neuen Schlüssel. Bevor das Secret gesetzt wird, muss `VERSION_CODE` in `rebuild/m3052/updater/update_model.gd` erhöht werden. Die CI bricht sonst bewusst ab, damit keine Daten-Updates veröffentlicht werden, die niemand installieren kann.
