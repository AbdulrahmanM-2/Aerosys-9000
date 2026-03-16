# AeroSys 9000 v4.0.0 — Multi-Type Avionics Platform

Extended from v3 with full multi-aircraft type support and ARINC 429 bus hardware interface layer.

## What's New in v4

### Multi-Aircraft Type Support
6 aircraft types with switchable profiles:

| ICAO | Aircraft | Engines | Bus Architecture |
|------|----------|---------|-----------------|
| A320 | Airbus A320-214 | 2× CFM56-5B4/P | ARINC 429 (18 buses) |
| A20N | Airbus A320neo | 2× LEAP-1A26 | ARINC 429 (18 buses) |
| A321 | Airbus A321-231 | 2× CFM56-5B3/P | ARINC 429 (18 buses) |
| B738 | Boeing 737-800 NG | 2× CFM56-7B27 | ARINC 429 (16 buses) |
| B38M | Boeing 737 MAX 8 | 2× LEAP-1B28 | ARINC 429 (16 buses) |
| A359 | Airbus A350-900 | 2× Trent XWB-84 | AFDX/664 + 24× ARINC 429 |
| A388 | Airbus A380-800 | 4× Trent 970B | AFDX/664 + 32× ARINC 429 (IMA) |

### ARINC 429 Bus Layer (Ada + JavaScript)
Complete implementation of ARINC 429 Part 1 Rev 17:
- 32-bit word format: Label (8) | SDI (2) | Data (19) | SSM (2) | Parity (1)
- BNR, BCD, DIS and ISO5 encoding/decoding
- Odd parity generation and validation
- Label bit-reversal (MSB/LSB wire convention)
- 65+ standard label assignments per ARINC 429 Part 2

### New Bus Channels (15 subsystems)
- FADEC 1-4 (one per engine): N1, N2, EGT, FF, oil, EPR, vibration, thrust rating
- ADC 1-2: IAS, Mach, TAS, altitude, SAT, TAT, baro setting
- IRS 1-3: pitch, roll, heading, lat/lon, G/S, V/S, accelerations
- FMS 1-2: cruise alt, DTG, XTK error, gross weight, FOB
- AFCS 1-2: AP/AT/FD status, selected targets
- Hydraulic, Pressurisation, Fuel Quantity
- Comms/Transponder, TCAS, ILS/MMR

### New Pages
- `/bus-monitor.html` — Live ARINC 429 bus monitor: raw hex words, decoded values, SSM/parity, aircraft type switcher

### New API Endpoints
- `GET/PUT /api/v2/aircraft` — get active profile or switch type
- `GET /api/v2/bus/snapshot` — full multi-channel bus word snapshot
- `GET /api/v2/bus/labels` — ARINC 429 Part 2 label map (65+ entries)

### New Ada Packages
- `AeroSys.ARINC429` — complete word encode/decode, label map, bus monitor buffer
- `AeroSys.Aircraft` — 6 aircraft profiles with engine specs and performance limits
- `AeroSys.Bus` — full FADEC/ADC/IRS/FMS/AFCS/System bus interface

## Deploy

```bash
unzip aerosys-9000-v4.zip && cd aerosys-v4
npm i -g vercel
vercel --prod
```

## API Quick Reference

```bash
# Switch to A350-900
curl -X PUT https://your-app.vercel.app/api/v2/aircraft \
  -H "Authorization: Bearer token" \
  -H "Content-Type: application/json" \
  -d '{"icao_type": "A359"}'

# Get full ARINC 429 bus snapshot
curl https://your-app.vercel.app/api/v2/bus/snapshot?no_auth=1

# Get all ARINC label definitions
curl https://your-app.vercel.app/api/v2/bus/labels?subsystem=FADEC&no_auth=1
```

## Ada Build

```bash
gprbuild -P aerosys.gpr -Xmode=release -j0
./bin/aerosys_api 8080
```

New packages in `src/`:
- `aerosys-arinc429.ads/adb` — ARINC 429 bus layer
- `aerosys-aircraft.ads/adb` — Multi-type aircraft profiles
- `aerosys-bus.ads/adb`      — Full subsystem bus drivers
