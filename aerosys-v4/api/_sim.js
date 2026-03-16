// api/_sim.js — Shared simulation state
// Generates realistic time-varying avionics data
// Used by all Vercel serverless functions

const BASE_TIME = Date.now();

function noise(t, freq = 1, amp = 1) {
  return amp * (Math.sin(t * freq) * 0.5 + Math.sin(t * freq * 1.7) * 0.3 + Math.sin(t * freq * 2.9) * 0.2);
}

function getSimState() {
  const t = (Date.now() - BASE_TIME) / 1000;
  const fuelBurn = t * 0.0028; // ~10kg/s total
  const distFlown = t * 0.133; // ~481kts

  return {
    t,
    flight_id: "AS2847",
    callsign:  "SHY847",
    origin:    "KJFK",
    destination: "EGLL",

    // Attitude
    pitch_deg:  +(1.2  + noise(t, 0.5,  0.18)).toFixed(3),
    roll_deg:   +(2.5  + noise(t, 0.3,  0.35)).toFixed(3),
    yaw_deg:    +(0.4  + noise(t, 0.2,  0.1)).toFixed(3),
    pitch_rate: +(noise(t, 1.2, 0.02)).toFixed(4),
    roll_rate:  +(noise(t, 0.9, 0.01)).toFixed(4),

    // Speeds
    ias_kt:    +(280   + noise(t, 0.8,  1.6)).toFixed(1),
    cas_kt:    +(280   + noise(t, 0.8,  1.5)).toFixed(1),
    tas_kt:    +(458   + noise(t, 0.4,  2.2)).toFixed(1),
    gs_kt:     Math.round(481 + noise(t, 0.4,  4)),
    mach:      +(0.840 + noise(t, 0.8,  0.002)).toFixed(4),
    vmo_kt:    340,
    mmo:       0.86,

    // Position
    latitude:   +(47.3821 + distFlown * 0.0028).toFixed(6),
    longitude:  +(-42.7419 + distFlown * 0.0065).toFixed(6),
    altitude_ft: Math.round(37000 + noise(t, 0.2, 10)),
    flight_level: Math.round((37000 + noise(t, 0.2, 10)) / 100),
    vs_fpm:     Math.round(noise(t, 0.5, 35)),
    track_deg:  +(86.0 + noise(t, 0.1, 0.4)).toFixed(1),
    heading_mag: +(85.0 + noise(t, 0.1, 0.4)).toFixed(1),

    // G-forces
    normal_g:     +(1.0  + noise(t, 0.6, 0.008)).toFixed(3),
    lateral_g:    +(noise(t, 0.4, 0.003)).toFixed(4),
    longitudinal_g: +(noise(t, 0.3, 0.002)).toFixed(4),

    // Engines
    engines: [1, 2].map(id => ({
      engine_id:       id,
      type:            "CFM56-5B4/P",
      status:          "RUNNING",
      n1_pct:          +((id === 1 ? 84.6 : 84.4) + noise(t * (id === 1 ? 1.2 : 0.9), 2, 0.35)).toFixed(2),
      n2_pct:          +((id === 1 ? 92.1 : 91.8) + noise(t * 0.5, 1, 0.3)).toFixed(2),
      egt_c:           Math.round((id === 1 ? 741 : 738) + noise(t * 0.7, 1.5, 5)),
      ff_kg_h:         +(1095 + noise(t, 1, 8)).toFixed(1),
      oil_pressure_psi: +(62.0 + noise(t * 0.3, 0.5, 0.8)).toFixed(1),
      oil_temp_c:      +(112  + noise(t * 0.2, 0.3, 0.4)).toFixed(1),
      vibration:       +(0.12 + noise(t * 2, 3, 0.015)).toFixed(3),
      thrust_rating:   "CRZ",
      epr:             +(1.42 + noise(t * 0.4, 0.6, 0.004)).toFixed(3),
      reverse_deployed: false,
    })),

    // Fuel
    fuel_lb: {
      center:  Math.max(0, 22400 - t * 0.56),
      left:    Math.max(0, 31500 - t * 0.62),
      right:   Math.max(0, 31500 - t * 0.62),
      total:   Math.max(0, 85400 - fuelBurn * 1000),
    },

    // Autopilot
    autopilot: {
      engaged: true,
      fd_on: true,
      autothrust_engaged: true,
      lateral_mode: "LNAV",
      vertical_mode: "VNAV_ALT",
      speed_mode: "MACH",
      targets: {
        target_speed_kt:   280,
        target_mach:       0.840,
        target_heading_deg: Math.round(85 + noise(t * 0.05, 0.1, 0.5)),
        target_altitude_ft: 37000,
        target_vs_fpm:     0,
      },
      limits: { max_bank_deg: 25, max_pitch_deg: 15, alt_capture_ft: 1000 },
    },

    // Navigation
    ils: {
      frequency_mhz: 109.90,
      identifier: "IWR",
      localizer_dev_dots:  +(noise(t * 0.3, 0.4, 0.06)).toFixed(3),
      glideslope_dev_dots: +(noise(t * 0.2, 0.3, 0.04)).toFixed(3),
      dme_nm: 0,
      localizer_captured: false,
      glideslope_captured: false,
      back_course: false,
    },

    tcas: {
      mode: "TA_RA",
      ra_active: false,
      ra_sense: "NONE",
      targets: [
        { id: "T001", callsign: "UAL441", squawk: "3421", relative_alt_ft: +1000, bearing_deg: 285, distance_nm: 4.2, vs_fpm: -320, threat_level: "PROXIMATE" },
        { id: "T002", callsign: "DAL882", squawk: "2201", relative_alt_ft: -2200, bearing_deg: 112, distance_nm: 12.8, vs_fpm: 0, threat_level: "TRAFFIC" },
        { id: "T003", callsign: "BAW174", squawk: "4101", relative_alt_ft: +400,  bearing_deg: 048, distance_nm: 28.1, vs_fpm: +800, threat_level: "PROXIMATE" },
      ],
    },

    // Communications
    radios: [
      { radio_id: 1, active_mhz: 132.725, standby_mhz: 122.800, tx: false, rx: true, squelch: true },
      { radio_id: 2, active_mhz: 119.100, standby_mhz: 121.500, tx: false, rx: true, squelch: true },
      { radio_id: 3, active_mhz: 121.500, standby_mhz: 121.500, tx: false, rx: false, squelch: true },
    ],
    transponder: { squawk: "4823", mode: "TA_RA", ident: false, flight_id: "AS2847", altitude_reported: Math.round(37000 + noise(t, 0.2, 10)) },

    // Alerts
    alerts: [
      { id: "A001", severity: "CAUTION",  category: "ENGINE",  message: "APU FAULT",              system_id: "apu",     triggered_at: new Date(Date.now()-3600000).toISOString(), acknowledged: false, inhibited: false },
      { id: "A002", severity: "ADVISORY", category: "OTHER",   message: "SEATBELT SIGN ON",        system_id: "cabin",   triggered_at: new Date(Date.now()-7200000).toISOString(), acknowledged: true,  inhibited: false },
      { id: "A003", severity: "ADVISORY", category: "NAVIGATION","message": "TCAS RA CLEAR",       system_id: "tcas",    triggered_at: new Date(Date.now()-9000000).toISOString(), acknowledged: true,  inhibited: false },
      { id: "A004", severity: "ADVISORY", category: "FUEL",    message: "FUEL IMBALANCE < 500 LB", system_id: "fuel",    triggered_at: new Date(Date.now()-1800000).toISOString(), acknowledged: false, inhibited: false },
    ],

    // Performance
    performance: {
      cost_index:       35,
      gross_weight_lb:  Math.round(347820 - fuelBurn * 1000),
      fuel_on_board_lb: Math.max(30000, 85400 - fuelBurn * 1000),
      cruise_mach:      0.840,
      optimal_fl:       370,
      max_fl:           410,
      efob_destination: Math.max(25000, 32000 - fuelBurn * 200),
      efob_alternate:   Math.max(12000, 18000 - fuelBurn * 100),
      trip_fuel_lb:     51200,
      contingency_fuel_lb: 2560,
      isa_deviation:    -4.0,
    },

    // Flight plan
    route: {
      id: "b3a7c2d1-4e5f-6789-abcd-ef0123456789",
      flight_id: "AS2847",
      origin: "KJFK", destination: "EGLL", alternate: "EHAM",
      active_leg: Math.min(2, Math.floor(t / 1200)),
      total_distance_nm: 3450,
      eta_destination: new Date(Date.now() + 3.5 * 3600000).toISOString(),
      waypoints: [
        { identifier: "KJFK",  latitude: 40.6413, longitude: -73.7781, type: "AIRPORT",  eta: new Date(Date.now()-2*3600000).toISOString(), dist_to_go_nm: 0,    overfly: false },
        { identifier: "MERIT", latitude: 40.9300, longitude: -72.0100, type: "FIX",      eta: new Date(Date.now()-1.8*3600000).toISOString(), dist_to_go_nm: 42,  overfly: false },
        { identifier: "JANJO", latitude: 50.1200, longitude: -38.2000, type: "FIX",      eta: new Date(Date.now()+0.5*3600000).toISOString(), dist_to_go_nm: 164, overfly: false },
        { identifier: "BEDRA", latitude: 52.8000, longitude: -27.6000, type: "FIX",      eta: new Date(Date.now()+1.3*3600000).toISOString(), dist_to_go_nm: 387, overfly: false },
        { identifier: "SOMAX", latitude: 54.2000, longitude: -18.4000, type: "FIX",      eta: new Date(Date.now()+2.1*3600000).toISOString(), dist_to_go_nm: 621, overfly: false },
        { identifier: "MALOT", latitude: 55.1000, longitude: -8.8000,  type: "FIX",      eta: new Date(Date.now()+2.8*3600000).toISOString(), dist_to_go_nm: 879, overfly: false },
        { identifier: "EGLL",  latitude: 51.4775, longitude: -0.4614,  type: "AIRPORT",  eta: new Date(Date.now()+3.5*3600000).toISOString(), dist_to_go_nm: 1243,overfly: false },
      ],
    },

    // Systems map
    systems: {
      electrical:     { status: "NORMAL",     params: { bus_volts: 115, freq_hz: 400, gen1: true, gen2: true } },
      hydraulic_a:    { status: "NORMAL",     params: { pressure_psi: 3010, qty_pct: 100, pump1: true, pump2: true } },
      hydraulic_b:    { status: "NORMAL",     params: { pressure_psi: 2990, qty_pct: 98,  pump1: true, pump2: true } },
      pneumatic:      { status: "NORMAL",     params: { bleed1: "OPEN", bleed2: "OPEN", xbleed: "AUTO" } },
      pressurization: { status: "NORMAL",     params: { cab_alt_ft: 7200, diff_press_psi: 8.23, vs_fpm: -200 } },
      apu:            { status: "ADVISORY_H", params: { status: "FAULT", n1_pct: null, egt_c: null, bleed: false } },
      anti_ice:       { status: "NORMAL",     params: { wing: false, eng1: false, eng2: false, probe_heat: "AUTO" } },
      bleed_air:      { status: "NORMAL",     params: { pack1: "NORM", pack2: "NORM", xbleed: "AUTO" } },
      fuel:           { status: "NORMAL",     params: { crossfeed: "CLOSED", ctr_pump: "ON", wing_pumps: "ON" } },
      flight_controls:{ status: "NORMAL",     params: { spoilers: "ARMED", flaps: 0, slats: 0, rudder: "FREE" } },
      irs:            { status: "NORMAL",     params: { irs1: "NAV", irs2: "NAV", irs3: "NAV", align: "COMPLETE" } },
      fire_protection:{ status: "NORMAL",     params: { eng1_loop: "NORMAL", eng2_loop: "NORMAL", apu_loop: "NORMAL" } },
    },
  };
}

function corsHeaders(req) {
  return {
    "Access-Control-Allow-Origin":  "*",
    "Access-Control-Allow-Methods": "GET, POST, PUT, PATCH, DELETE, OPTIONS",
    "Access-Control-Allow-Headers": "Authorization, Content-Type",
    "Content-Type": "application/json; charset=utf-8",
    "X-AeroSys-Version": "3.0.0",
    "X-Request-ID": Math.random().toString(36).slice(2),
  };
}

function checkAuth(req) {
  const auth = req.headers.authorization || req.headers.Authorization || "";
  return auth.startsWith("Bearer ") || req.url.includes("no_auth=1");
}

module.exports = { getSimState, corsHeaders, checkAuth };

// ════════════════════════════════════════
// Aircraft type registry integration
let ACTIVE_AIRCRAFT = "A320";
function setAircraftType(icao) { ACTIVE_AIRCRAFT = icao; }
function getAircraftType() { return ACTIVE_AIRCRAFT; }

const origGetSim = module.exports.getSimState;
module.exports.getSimState = function() {
  const s = origGetSim();
  s.aircraft_type = ACTIVE_AIRCRAFT;
  return s;
};
module.exports.setAircraftType = setAircraftType;
module.exports.getAircraftType = getAircraftType;
