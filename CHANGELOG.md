## 0.0.1

Initial production release of the `urovo_rfid` Flutter plugin.

### Added
- Android plugin implementation backed by Urovo USDK / RFID native libraries.
- Public Dart API (`UrovoRfid`) for reader lifecycle and RFID operations:
  - `init`, `startInventory`, `stopInventory`
  - `readTag`, `writeTag`, `writeTagEpc`
  - `getOutputPower`, `setOutputPower`
  - `setInventoryParameter`, `enableScanHead`
- Inventory event stream (`inventoryStream`) bridged from native callback events.

### Platform scope
- **Android only** (Urovo handheld devices with supported RFID hardware/firmware).
- No iOS, web, macOS, Windows, or Linux implementation in this release.

### Known limitations
- Native event payloads include raw event keys (for example `event_inventory_tag`), so consumers must parse the envelope to extract EPC/TID/RSSI data.
- `setInventoryParameter` currently expects a native JSON string format; Dart callers should validate integration behavior against target firmware.
- `readTag` and `writeTag` return values map directly to native SDK behavior/codes, which may vary by Urovo SDK version and reader model.
