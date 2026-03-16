// api/_arinc429.js — ARINC 429 encode/decode + label map for Vercel API

// ══════════════════════════════════════════════════════════════
// BIT OPERATIONS (32-bit unsigned)
// ══════════════════════════════════════════════════════════════

function reverseLabel(label) {
  let input = label & 0xFF, output = 0;
  for (let i = 0; i < 8; i++) {
    output = (output << 1) | (input & 1);
    input >>= 1;
  }
  return output & 0xFF;
}

function computeOddParity(word) {
  let w = word >>> 0, n = 0;
  while (w) { n += w & 1; w >>>= 1; }
  return (n % 2) === 1;
}

function encodeWord(label, sdi, data19, ssm) {
  let w = (reverseLabel(label) & 0xFF) |
          ((sdi   & 0x03) << 8)        |
          ((data19 & 0x7FFFF) << 10)   |
          ((ssm   & 0x03) << 29);
  w = w >>> 0;
  if (!computeOddParity(w)) w = (w | 0x80000000) >>> 0;
  return w;
}

function decodeWord(raw) {
  raw = raw >>> 0;
  const label  = reverseLabel(raw & 0xFF);
  const sdi    = (raw >>> 8)  & 0x03;
  const data19 = (raw >>> 10) & 0x7FFFF;
  const ssm    = (raw >>> 29) & 0x03;
  const parity = (raw >>> 31) & 0x01;
  // verify parity
  let w = raw, n = 0;
  while (w) { n += w & 1; w = (w >>> 1) >>> 0; }
  return { raw, label, sdi, data19, ssm, parity, valid: (n % 2) === 1 };
}

// BNR encode/decode
function encodeBNR(value, resolution) {
  const raw = Math.round(value / resolution);
  const clamped = Math.max(-(1 << 18), Math.min((1 << 18) - 1, raw));
  return clamped >= 0 ? clamped : ((1 << 19) + clamped);
}

function decodeBNR(data19, resolution, ssm) {
  if (ssm === 0 || ssm === 1) return null; // NCD or FW
  const sign = (data19 & 0x40000) !== 0;
  if (sign) return -((~data19 & 0x7FFFF) + 1) * resolution;
  return data19 * resolution;
}

// BCD encode
function encodeBCD(value) {
  let v = Math.round(Math.abs(value)), result = 0, shift = 0;
  while (v > 0 && shift < 20) {
    result |= (v % 10) << shift;
    v = Math.floor(v / 10);
    shift += 4;
  }
  return result;
}

// SSM constants
const SSM_FW = 0b00, SSM_NCD = 0b01, SSM_FT = 0b10, SSM_NORM = 0b11;
const SSM_PLUS = 0b11, SSM_MINUS = 0b01;

// ══════════════════════════════════════════════════════════════
// LABEL MAP — ARINC 429 Part 2 assignments
// ══════════════════════════════════════════════════════════════

const LABEL_MAP = [
  // FADEC
  { label: 0o061, hex:"0x31", name:"N1 Engine 1",        subsystem:"FADEC",  format:"BNR", resolution:0.00391,  unit:"%" },
  { label: 0o062, hex:"0x32", name:"N1 Engine 2",        subsystem:"FADEC",  format:"BNR", resolution:0.00391,  unit:"%" },
  { label: 0o063, hex:"0x33", name:"N1 Engine 3",        subsystem:"FADEC",  format:"BNR", resolution:0.00391,  unit:"%" },
  { label: 0o064, hex:"0x34", name:"N1 Engine 4",        subsystem:"FADEC",  format:"BNR", resolution:0.00391,  unit:"%" },
  { label: 0o065, hex:"0x35", name:"N2 Engine 1",        subsystem:"FADEC",  format:"BNR", resolution:0.00391,  unit:"%" },
  { label: 0o066, hex:"0x36", name:"N2 Engine 2",        subsystem:"FADEC",  format:"BNR", resolution:0.00391,  unit:"%" },
  { label: 0o071, hex:"0x39", name:"EGT Engine 1",       subsystem:"FADEC",  format:"BNR", resolution:0.5,      unit:"°C" },
  { label: 0o072, hex:"0x3A", name:"EGT Engine 2",       subsystem:"FADEC",  format:"BNR", resolution:0.5,      unit:"°C" },
  { label: 0o073, hex:"0x3B", name:"Fuel Flow Eng 1",    subsystem:"FADEC",  format:"BNR", resolution:0.5,      unit:"kg/h" },
  { label: 0o074, hex:"0x3C", name:"Fuel Flow Eng 2",    subsystem:"FADEC",  format:"BNR", resolution:0.5,      unit:"kg/h" },
  { label: 0o077, hex:"0x3F", name:"Oil Pressure Eng 1", subsystem:"FADEC",  format:"BNR", resolution:0.125,    unit:"PSI" },
  { label: 0o041, hex:"0x21", name:"Oil Temp Eng 1",     subsystem:"FADEC",  format:"BNR", resolution:0.25,     unit:"°C" },
  { label: 0o051, hex:"0x29", name:"EPR Engine 1",       subsystem:"FADEC",  format:"BNR", resolution:0.001,    unit:"ratio" },
  { label: 0o055, hex:"0x2D", name:"Vibration Eng 1",    subsystem:"FADEC",  format:"BNR", resolution:0.001,    unit:"IPS" },
  { label: 0o057, hex:"0x2F", name:"Thrust Rating",      subsystem:"FADEC",  format:"DIS", resolution:1,        unit:"discrete" },
  // ADC
  { label: 0o203, hex:"0x83", name:"Baro Corrected Alt", subsystem:"ADC",    format:"BNR", resolution:0.125,    unit:"ft" },
  { label: 0o204, hex:"0x84", name:"Baro Alt (2)",       subsystem:"ADC",    format:"BNR", resolution:0.125,    unit:"ft" },
  { label: 0o205, hex:"0x85", name:"Mach Number",        subsystem:"ADC",    format:"BNR", resolution:0.000488, unit:"M" },
  { label: 0o206, hex:"0x86", name:"Indicated Airspeed", subsystem:"ADC",    format:"BNR", resolution:0.5,      unit:"kt" },
  { label: 0o210, hex:"0x88", name:"True Airspeed",      subsystem:"ADC",    format:"BNR", resolution:0.5,      unit:"kt" },
  { label: 0o211, hex:"0x89", name:"Static Air Temp",    subsystem:"ADC",    format:"BNR", resolution:0.25,     unit:"°C" },
  { label: 0o213, hex:"0x8B", name:"Total Air Temp",     subsystem:"ADC",    format:"BNR", resolution:0.25,     unit:"°C" },
  { label: 0o235, hex:"0x9D", name:"Baro Setting",       subsystem:"ADC",    format:"BCD", resolution:0.1,      unit:"hPa" },
  // IRS
  { label: 0o100, hex:"0x40", name:"Latitude",           subsystem:"IRS",    format:"BNR", resolution:0.000021458, unit:"°" },
  { label: 0o101, hex:"0x41", name:"Longitude",          subsystem:"IRS",    format:"BNR", resolution:0.000021458, unit:"°" },
  { label: 0o102, hex:"0x42", name:"Ground Speed",       subsystem:"IRS",    format:"BNR", resolution:0.5,      unit:"kt" },
  { label: 0o114, hex:"0x4C", name:"True Heading",       subsystem:"IRS",    format:"BNR", resolution:0.000687, unit:"°" },
  { label: 0o212, hex:"0x8A", name:"Inertial V/S",       subsystem:"IRS",    format:"BNR", resolution:8.0,      unit:"fpm" },
  { label: 0o320, hex:"0xD0", name:"Magnetic Heading",   subsystem:"IRS",    format:"BNR", resolution:0.000687, unit:"°" },
  { label: 0o324, hex:"0xD4", name:"Pitch Attitude",     subsystem:"IRS",    format:"BNR", resolution:0.00137,  unit:"°" },
  { label: 0o325, hex:"0xD5", name:"Roll Attitude",      subsystem:"IRS",    format:"BNR", resolution:0.00137,  unit:"°" },
  { label: 0o326, hex:"0xD6", name:"Pitch Rate",         subsystem:"IRS",    format:"BNR", resolution:0.0000084,unit:"°/s" },
  { label: 0o327, hex:"0xD7", name:"Roll Rate",          subsystem:"IRS",    format:"BNR", resolution:0.0000084,unit:"°/s" },
  { label: 0o330, hex:"0xD8", name:"Yaw Rate",           subsystem:"IRS",    format:"BNR", resolution:0.0000084,unit:"°/s" },
  { label: 0o335, hex:"0xDD", name:"Normal Acceleration",subsystem:"IRS",    format:"BNR", resolution:0.0000153,unit:"g" },
  { label: 0o336, hex:"0xDE", name:"Long. Acceleration", subsystem:"IRS",    format:"BNR", resolution:0.0000153,unit:"g" },
  { label: 0o337, hex:"0xDF", name:"Lat. Acceleration",  subsystem:"IRS",    format:"BNR", resolution:0.0000153,unit:"g" },
  // FMS
  { label: 0o130, hex:"0x58", name:"Cruise Altitude",    subsystem:"FMS",    format:"BNR", resolution:4.0,      unit:"ft" },
  { label: 0o151, hex:"0x69", name:"DTG Destination",    subsystem:"FMS",    format:"BNR", resolution:0.5,      unit:"NM" },
  { label: 0o173, hex:"0x7B", name:"XTK Error",          subsystem:"FMS",    format:"BNR", resolution:0.000191, unit:"NM" },
  { label: 0o132, hex:"0x5A", name:"Gross Weight",       subsystem:"FMS",    format:"BNR", resolution:4.0,      unit:"lb" },
  { label: 0o135, hex:"0x5D", name:"Fuel on Board",      subsystem:"FMS",    format:"BNR", resolution:2.0,      unit:"lb" },
  // AFCS
  { label: 0o273, hex:"0xBB", name:"AP Engaged",         subsystem:"AFCS",   format:"DIS", resolution:1,        unit:"discrete" },
  { label: 0o274, hex:"0xBC", name:"AT Engaged",         subsystem:"AFCS",   format:"DIS", resolution:1,        unit:"discrete" },
  { label: 0o275, hex:"0xBD", name:"FD On",              subsystem:"AFCS",   format:"DIS", resolution:1,        unit:"discrete" },
  // ILS
  { label: 0o035, hex:"0x1D", name:"ILS Frequency",      subsystem:"ILS",    format:"BCD", resolution:0.01,     unit:"MHz" },
  { label: 0o173, hex:"0x7B", name:"LOC Deviation",      subsystem:"ILS",    format:"BNR", resolution:0.00000954,unit:"dots" },
  // Systems
  { label: 0o261, hex:"0xB1", name:"Hydraulic Press A",  subsystem:"HYD",    format:"BNR", resolution:1.0,      unit:"PSI" },
  { label: 0o262, hex:"0xB2", name:"Hydraulic Press B",  subsystem:"HYD",    format:"BNR", resolution:1.0,      unit:"PSI" },
  { label: 0o247, hex:"0xA7", name:"Cabin Altitude",     subsystem:"PRESS",  format:"BNR", resolution:4.0,      unit:"ft" },
  { label: 0o250, hex:"0xA8", name:"Diff Pressure",      subsystem:"PRESS",  format:"BNR", resolution:0.00391,  unit:"PSI" },
  // Comms
  { label: 0o026, hex:"0x16", name:"Squawk Code",        subsystem:"COMMS",  format:"BCD", resolution:1,        unit:"octal" },
  { label: 0o030, hex:"0x18", name:"VHF1 Active Freq",   subsystem:"COMMS",  format:"BCD", resolution:0.005,    unit:"MHz" },
  { label: 0o031, hex:"0x19", name:"VHF2 Active Freq",   subsystem:"COMMS",  format:"BCD", resolution:0.005,    unit:"MHz" },
  { label: 0o035, hex:"0x1D", name:"ILS Frequency",      subsystem:"COMMS",  format:"BCD", resolution:0.01,     unit:"MHz" },
  // TCAS
  { label: 0o270, hex:"0xB8", name:"TCAS Mode",          subsystem:"TCAS",   format:"DIS", resolution:1,        unit:"discrete" },
  { label: 0o271, hex:"0xB9", name:"TCAS RA Command",    subsystem:"TCAS",   format:"DIS", resolution:1,        unit:"discrete" },
];

// ══════════════════════════════════════════════════════════════
// BUS SNAPSHOT BUILDER — called from API handler
// ══════════════════════════════════════════════════════════════

function makeBNRWord(label, sdi, value, resolution, positive = true) {
  const data = encodeBNR(positive ? Math.abs(value) : Math.abs(value), resolution);
  const ssm  = positive ? SSM_PLUS : SSM_MINUS;
  const raw  = encodeWord(label, sdi, data, ssm);
  return {
    label,
    label_octal:  "0o" + label.toString(8).padStart(3,"0"),
    label_hex:    "0x" + label.toString(16).padStart(2,"0").toUpperCase(),
    label_name:   LABEL_MAP.find(l=>l.label===label)?.name || `LBL_${label}`,
    raw_hex:      "0x" + raw.toString(16).padStart(8,"0").toUpperCase(),
    raw_uint32:   raw >>> 0,
    sdi,
    data19:       data,
    ssm,
    ssm_text:     ssm === SSM_NORM ? "NORM" : ssm === SSM_NCD ? "NCD" : ssm === SSM_FW ? "FW" : "FT",
    decoded_value: +(value).toFixed(4),
    parity_valid: computeOddParity(raw),
    format:       "BNR",
  };
}

function makeDISWord(label, sdi, bits) {
  const raw = encodeWord(label, sdi, bits & 0x7FFFF, SSM_NORM);
  return {
    label, label_octal: "0o"+label.toString(8).padStart(3,"0"),
    label_hex: "0x"+label.toString(16).padStart(2,"0").toUpperCase(),
    label_name: LABEL_MAP.find(l=>l.label===label)?.name || `LBL_${label}`,
    raw_hex: "0x"+raw.toString(16).padStart(8,"0").toUpperCase(),
    raw_uint32: raw>>>0, sdi, data19: bits, ssm: SSM_NORM,
    ssm_text: "NORM", decoded_value: bits, parity_valid: computeOddParity(raw),
    format: "DIS",
  };
}

function buildBusSnapshot(S) {
  const t = S.t;
  const eng = S.engines;
  const ap  = S.autopilot;

  const channels = {

    FADEC_1: [
      makeBNRWord(0o061, 1, eng[0].n1_pct,          0.00391),
      makeBNRWord(0o065, 1, eng[0].n2_pct,          0.00391),
      makeBNRWord(0o071, 1, eng[0].egt_c,           0.5),
      makeBNRWord(0o073, 1, eng[0].ff_kg_h,         0.5),
      makeBNRWord(0o077, 1, eng[0].oil_pressure_psi, 0.125),
      makeBNRWord(0o041, 1, eng[0].oil_temp_c,      0.25),
      makeBNRWord(0o055, 1, eng[0].vibration,       0.001),
      makeBNRWord(0o051, 1, 1.420,                   0.001),
    ],

    FADEC_2: [
      makeBNRWord(0o062, 2, eng[1].n1_pct,          0.00391),
      makeBNRWord(0o066, 2, eng[1].n2_pct,          0.00391),
      makeBNRWord(0o072, 2, eng[1].egt_c,           0.5),
      makeBNRWord(0o074, 2, eng[1].ff_kg_h,         0.5),
      makeBNRWord(0o100, 2, eng[1].oil_pressure_psi, 0.125),
      makeBNRWord(0o042, 2, eng[1].oil_temp_c,      0.25),
      makeBNRWord(0o056, 2, eng[1].vibration,       0.001),
      makeBNRWord(0o052, 2, 1.418,                   0.001),
    ],

    ADC_1: [
      makeBNRWord(0o206, 0, S.ias_kt,   0.5),
      makeBNRWord(0o205, 0, S.mach,     0.000488),
      makeBNRWord(0o210, 0, S.tas_kt,   0.5),
      makeBNRWord(0o203, 0, S.altitude_ft, 0.125),
      makeBNRWord(0o211, 0, 57.0,       0.25, false), // SAT -57°C
      makeBNRWord(0o213, 0, 34.0,       0.25, false), // TAT -34°C
    ],

    ADC_2: [
      makeBNRWord(0o206, 2, S.ias_kt,   0.5),
      makeBNRWord(0o205, 2, S.mach,     0.000488),
      makeBNRWord(0o204, 2, S.altitude_ft, 0.125),
    ],

    IRS_1: [
      makeBNRWord(0o324, 1, Math.abs(S.pitch_deg),  0.00137, S.pitch_deg >= 0),
      makeBNRWord(0o325, 1, Math.abs(S.roll_deg),   0.00137, S.roll_deg >= 0),
      makeBNRWord(0o320, 1, S.heading_mag,          0.000687),
      makeBNRWord(0o100, 1, Math.abs(S.latitude),   0.000021458, S.latitude >= 0),
      makeBNRWord(0o101, 1, Math.abs(S.longitude),  0.000021458, S.longitude >= 0),
      makeBNRWord(0o102, 1, S.gs_kt,                0.5),
      makeBNRWord(0o212, 1, Math.abs(S.vs_fpm),     8.0, S.vs_fpm >= 0),
      makeBNRWord(0o335, 1, 1.003,                   0.0000153),
    ],

    IRS_2: [
      makeBNRWord(0o324, 2, Math.abs(S.pitch_deg+0.001), 0.00137, S.pitch_deg >= 0),
      makeBNRWord(0o325, 2, Math.abs(S.roll_deg +0.001), 0.00137, S.roll_deg  >= 0),
      makeBNRWord(0o320, 2, S.heading_mag+0.002,         0.000687),
    ],

    IRS_3: [
      makeBNRWord(0o324, 3, Math.abs(S.pitch_deg+0.002), 0.00137, S.pitch_deg >= 0),
      makeBNRWord(0o325, 3, Math.abs(S.roll_deg +0.002), 0.00137, S.roll_deg  >= 0),
    ],

    FMS_1: [
      makeBNRWord(0o130, 1, S.autopilot.targets.target_altitude_ft, 4.0),
      makeBNRWord(0o135, 1, S.fuel_lb.total,  2.0),
      makeBNRWord(0o132, 1, 347820.0,         4.0),
      makeBNRWord(0o151, 1, 2847.0 - S.t*0.133, 0.5),
      makeBNRWord(0o173, 1, 0.08,             0.000191),
    ],

    AFCS_1: [
      makeDISWord(0o273, 1, ap.engaged    ? 1 : 0),
      makeDISWord(0o274, 1, ap.autothrust_engaged ? 1 : 0),
      makeDISWord(0o275, 1, ap.fd_on      ? 1 : 0),
      makeBNRWord(0o102, 1, ap.targets.target_altitude_ft, 4.0),
      makeBNRWord(0o103, 1, ap.targets.target_mach, 0.000488),
    ],

    HYD: [
      makeBNRWord(0o261, 0, 3010.0, 1.0),
      makeBNRWord(0o262, 0, 2990.0, 1.0),
    ],

    PRESS: [
      makeBNRWord(0o247, 0, 7200.0, 4.0),
      makeBNRWord(0o250, 0, 8.23,   0.00391),
      makeBNRWord(0o251, 0, 200.0,  8.0, false),
    ],

    FUEL: [
      makeBNRWord(0o135, 0, S.fuel_lb.total,  2.0),
      makeBNRWord(0o136, 0, S.fuel_lb.left,   2.0),
      makeBNRWord(0o137, 0, S.fuel_lb.right,  2.0),
      makeBNRWord(0o140, 0, S.fuel_lb.center, 2.0),
    ],

    COMMS: [
      makeDISWord(0o030, 0, 132725),
      makeDISWord(0o031, 0, 119100),
      makeDISWord(0o026, 0, 4823),
    ],

    TCAS: [
      makeDISWord(0o270, 0, 0b11),  // TA_RA
      makeDISWord(0o271, 0, 0),     // no RA
    ],

    ILS_MMR: [
      makeDISWord(0o035, 0, encodeBCD(109.90)),
      makeBNRWord(0o173, 0, Math.abs(+(0.04 + Math.sin(t*0.3)*0.06).toFixed(3)), 0.00000954),
      makeBNRWord(0o174, 0, Math.abs(+(0.02 + Math.sin(t*0.2)*0.04).toFixed(3)), 0.00000954),
    ],
  };

  // Count totals
  let total = 0;
  Object.values(channels).forEach(ch => { total += ch.length; });

  return {
    timestamp:     new Date().toISOString(),
    flight_id:     S.flight_id,
    aircraft_type: S.aircraft_type || "A320",
    word_count:    total,
    bus_rate_hz:   100,
    channels,
    summary: {
      fadec_words:  channels.FADEC_1.length + channels.FADEC_2.length,
      adc_words:    channels.ADC_1.length + channels.ADC_2.length,
      irs_words:    channels.IRS_1.length + channels.IRS_2.length + channels.IRS_3.length,
      fms_words:    channels.FMS_1.length,
      afcs_words:   channels.AFCS_1.length,
      system_words: channels.HYD.length + channels.PRESS.length + channels.FUEL.length,
      comms_words:  channels.COMMS.length + channels.TCAS.length,
      ils_words:    channels.ILS_MMR.length,
    },
  };
}

module.exports = { encodeWord, decodeWord, encodeBNR, decodeBNR, encodeBCD,
                   LABEL_MAP, buildBusSnapshot };
