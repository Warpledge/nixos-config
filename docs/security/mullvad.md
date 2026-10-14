# Mullvad Notes

Behaviour of the Mullvad setup in `modules/nixos/security/mullvad/` that isn't
visible from the config.

## DataPacket relays read as London

Mullvad's DataPacket-hosted relays (`us-chi-wg-2xx`, and DataPacket relays in
other US cities) sit in netblocks registered to Datacamp Limited with country
code GB. Commercial geo-IP databases (ipinfo.io, ip-api.com) place them in
their real city, but a service that reads the RIPE or ARIN registry reports
London.

Checked 2026-09-20 on `87.249.134.18` (`us-chi-wg-202`): ipinfo and ip-api both
said Chicago, while RIPE WHOIS gave `country: GB`. Steam's login notification
showed London, and Steam blocked a browser login over that exit the same day.
The desktop Steam client runs outside the tunnel (`steam` is in
`mullvad.splitTunnel`), so one account showed two countries at once, which is
the pattern that triggers Steam trade holds. Ordinary browsing isn't affected;
geofenced or fraud-checked services are.

Pick a Tzulo-hosted relay in the same city instead. `us-chi-wg-3xx`
(68.235.46.x, 173.249.252.x) is ARIN-registered to TZULO in Chicago, so it
reads as Chicago both ways:

```bash
mullvad relay list                          # "hosted by <provider>" per relay
mullvad relay set location us-chi-wg-301    # Tzulo, not DataPacket
curl https://am.i.mullvad.net/json
```
