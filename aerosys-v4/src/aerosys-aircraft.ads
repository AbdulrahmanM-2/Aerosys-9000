------------------------------------------------------------------------------
--  AeroSys.Aircraft — Multi-Type Aircraft Profile Definitions
--
--  Defines type-specific parameters for:
--    A320 Family : A318 / A319 / A320 / A320neo / A321 / A321neo
--    B737 Family : B737-700 / B737-800 / B737-900 / B737 MAX 8/9/10
--    A350 Family : A350-900 / A350-1000
--    A380        : A380-800
--
--  Each profile carries: engine type, performance limits, bus speeds,
--  ARINC label resolution tables, system configuration flags.
------------------------------------------------------------------------------

with AeroSys.Types;   use AeroSys.Types;
with AeroSys.ARINC429; use AeroSys.ARINC429;

package AeroSys.Aircraft is

   --  ═══════════════════════════════════════════════════════════════
   --  AIRCRAFT TYPE ENUMERATION
   --  ═══════════════════════════════════════════════════════════════

   type Aircraft_Family is
     (A320_Family,   -- Airbus narrow-body: A318/A319/A320/A321 + neo
      B737_Family,   -- Boeing narrow-body: B737 Classic/NG/MAX
      A350_Family,   -- Airbus wide-body: A350-900/1000
      A380_Family);  -- Airbus super-jumbo: A380-800

   type A320_Variant is
     (A318_CFM, A318_IAE,
      A319_CFM, A319_IAE, A319_neo_LEAP, A319_neo_PW,
      A320_CFM, A320_IAE, A320_neo_LEAP, A320_neo_PW,
      A321_CFM, A321_IAE, A321_neo_LEAP, A321_neo_PW, A321_XLR);

   type B737_Variant is
     (B737_700_CFM56, B737_800_CFM56, B737_900_CFM56,
      B737_MAX7_LEAP,  B737_MAX8_LEAP,  B737_MAX9_LEAP,  B737_MAX10_LEAP);

   type A350_Variant is
     (A350_900_XWB,   -- Rolls-Royce Trent XWB-84
      A350_1000_XWB); -- Rolls-Royce Trent XWB-97

   type A380_Variant is
     (A380_800_RR,    -- Rolls-Royce Trent 970
      A380_800_EA);   -- Engine Alliance GP7200

   --  ═══════════════════════════════════════════════════════════════
   --  ENGINE TYPE
   --  ═══════════════════════════════════════════════════════════════

   type Engine_Manufacturer is (CFM, IAE, RR, EA, PW);
   type Engine_Series is
     (CFM56_5A, CFM56_5B, CFM56_7B,     -- CFM classics
      LEAP_1A, LEAP_1B,                  -- CFM LEAP
      V2500_A1, V2500_A5,                -- IAE
      PW1100G, PW1500G,                  -- Pratt & Whitney GTF
      TRENT_XWB84, TRENT_XWB97,         -- RR Trent XWB
      TRENT_970, TRENT_972, TRENT_977,  -- RR Trent 900 series
      GP7200);                           -- Engine Alliance

   type Engine_Profile is record
      Manufacturer   : Engine_Manufacturer;
      Series         : Engine_Series;
      Display_Name   : String (1 .. 16);
      --  Thrust
      Max_Thrust_lbf : Natural;           -- sea level, ISA, static
      --  N1 limits
      N1_Max_TOGA    : N1_Percent;
      N1_Max_MCT     : N1_Percent;
      N1_Idle_Ground : N1_Percent;
      N1_Idle_Flight : N1_Percent;
      --  EGT limits
      EGT_Max_TOGA   : EGT_Celsius;
      EGT_Max_MCT    : EGT_Celsius;
      EGT_Max_Start  : EGT_Celsius;
      EGT_Max_Cont   : EGT_Celsius;
      --  N2 limits
      N2_Max         : N2_Percent;
      N2_Idle        : N2_Percent;
      --  Oil
      Oil_Min_Psi    : Oil_Psi;
      Oil_Max_Temp   : Integer;           -- °C
      --  FADEC
      Has_FADEC      : Boolean;
      FADEC_Channels : Positive;          -- A/B redundant channels
      --  ARINC bus speed
      Bus_Speed      : AeroSys.ARINC429.Bus_Speed;
      --  ARINC resolution scaling (BNR LSB values)
      N1_Resolution  : Float;   -- % per LSB
      EGT_Resolution : Float;   -- °C per LSB
      FF_Resolution  : Float;   -- kg/h per LSB
   end record;

   --  ═══════════════════════════════════════════════════════════════
   --  AIRCRAFT PERFORMANCE PROFILE
   --  ═══════════════════════════════════════════════════════════════

   type Avionics_Suite is
     (EIS1,       -- A320 ceo: older EFIS/ECAM displays
      EIS2,       -- A320 neo: updated displays, OANS
      Boeing_NDS, -- Boeing: Nav Display System (NG)
      Boeing_EFIS_MAX, -- Boeing MAX: Honeywell 4-display suite
      A350_OANS,  -- A350: On-board Airport Navigation System
      A380_IMA);  -- A380: Integrated Modular Avionics

   type Bus_Architecture is
     (ARINC_429_Only,         -- A320 ceo, B737 NG
      ARINC_429_629_Mixed,    -- A320 neo partial
      AFDX_ARINC_664,         -- A350, A380: 100Mbit switched Ethernet
      ARINC_629_Primary);     -- B777 (reference)

   type Aircraft_Profile is record
      Family          : Aircraft_Family;
      Display_Name    : String (1 .. 24);
      ICAO_Type       : String (1 .. 4);
      Engine_Count    : Positive;
      Engine          : Engine_Profile;
      --  Speeds (KIAS)
      V_MO            : Speed_Kts;    -- max operating speed
      M_MO            : Mach_Number;  -- max operating Mach
      V_LE            : Speed_Kts;    -- max landing gear extended
      V_LO            : Speed_Kts;    -- max landing gear operation
      V_FE_Flaps_1    : Speed_Kts;
      V_FE_Flaps_Full : Speed_Kts;
      V_S1G           : Speed_Kts;    -- stall speed 1g
      --  Altitudes
      Max_Altitude_Ft : Altitude_Ft;  -- certified ceiling
      Opt_Cruise_FL   : Natural;      -- typical optimal FL
      --  Weight (lb)
      MTOW_Lb         : Natural;
      MLW_Lb          : Natural;
      OEW_Lb          : Natural;
      Max_Payload_Lb  : Natural;
      Max_Fuel_Lb     : Natural;
      --  Fuel burn
      Typical_FF_Kg_H : Float;        -- per engine, cruise
      --  Range
      Range_Nm        : Natural;
      --  Systems
      Suite           : Avionics_Suite;
      Bus_Arch        : Bus_Architecture;
      Has_ACARS       : Boolean;
      Has_ADS_B_Out   : Boolean;
      Has_TCAS_II_RA  : Boolean;
      Has_EGPWS       : Boolean;
      Has_OANS        : Boolean;      -- On-board airport nav
      Has_SVS         : Boolean;      -- Synthetic vision
      --  Bus config
      ARINC_429_Buses : Natural;      -- typical number of buses
   end record;

   --  ═══════════════════════════════════════════════════════════════
   --  PRE-DEFINED ENGINE PROFILES
   --  ═══════════════════════════════════════════════════════════════

   CFM56_5B4P : constant Engine_Profile := (
      Manufacturer   => CFM,       Series => CFM56_5B,
      Display_Name   => "CFM56-5B4/P     ",
      Max_Thrust_lbf => 27_000,
      N1_Max_TOGA    => 100.0,     N1_Max_MCT     => 96.5,
      N1_Idle_Ground =>  18.5,     N1_Idle_Flight =>  24.0,
      EGT_Max_TOGA   =>  950,      EGT_Max_MCT    =>  925,
      EGT_Max_Start  =>  725,      EGT_Max_Cont   =>  895,
      N2_Max         => 105.0,     N2_Idle        =>  64.0,
      Oil_Min_Psi    =>  13.0,     Oil_Max_Temp   =>  155,
      Has_FADEC      => True,      FADEC_Channels =>  2,
      Bus_Speed      => High_Speed_100K,
      N1_Resolution  => 0.00391,   EGT_Resolution => 0.5,
      FF_Resolution  => 0.5);

   LEAP_1A26 : constant Engine_Profile := (
      Manufacturer   => CFM,       Series => LEAP_1A,
      Display_Name   => "LEAP-1A26       ",
      Max_Thrust_lbf => 27_120,
      N1_Max_TOGA    => 100.0,     N1_Max_MCT     => 97.0,
      N1_Idle_Ground =>  18.0,     N1_Idle_Flight =>  23.5,
      EGT_Max_TOGA   =>  1_040,    EGT_Max_MCT    =>  1_010,
      EGT_Max_Start  =>  770,      EGT_Max_Cont   =>  990,
      N2_Max         => 105.0,     N2_Idle        =>  64.5,
      Oil_Min_Psi    =>  13.0,     Oil_Max_Temp   =>  155,
      Has_FADEC      => True,      FADEC_Channels =>  2,
      Bus_Speed      => High_Speed_100K,
      N1_Resolution  => 0.00391,   EGT_Resolution => 0.5,
      FF_Resolution  => 0.5);

   CFM56_7B27 : constant Engine_Profile := (
      Manufacturer   => CFM,       Series => CFM56_7B,
      Display_Name   => "CFM56-7B27      ",
      Max_Thrust_lbf => 27_300,
      N1_Max_TOGA    => 100.0,     N1_Max_MCT     => 95.0,
      N1_Idle_Ground =>  20.0,     N1_Idle_Flight =>  26.0,
      EGT_Max_TOGA   =>  950,      EGT_Max_MCT    =>  920,
      EGT_Max_Start  =>  725,      EGT_Max_Cont   =>  890,
      N2_Max         => 105.0,     N2_Idle        =>  58.0,
      Oil_Min_Psi    =>  13.0,     Oil_Max_Temp   =>  155,
      Has_FADEC      => True,      FADEC_Channels =>  2,
      Bus_Speed      => High_Speed_100K,
      N1_Resolution  => 0.00391,   EGT_Resolution => 0.5,
      FF_Resolution  => 0.5);

   LEAP_1B28 : constant Engine_Profile := (
      Manufacturer   => CFM,       Series => LEAP_1B,
      Display_Name   => "LEAP-1B28       ",
      Max_Thrust_lbf => 28_000,
      N1_Max_TOGA    => 100.0,     N1_Max_MCT     => 97.0,
      N1_Idle_Ground =>  18.5,     N1_Idle_Flight =>  23.0,
      EGT_Max_TOGA   =>  1_050,    EGT_Max_MCT    =>  1_020,
      EGT_Max_Start  =>  780,      EGT_Max_Cont   =>  1_000,
      N2_Max         => 105.0,     N2_Idle        =>  62.0,
      Oil_Min_Psi    =>  13.0,     Oil_Max_Temp   =>  155,
      Has_FADEC      => True,      FADEC_Channels =>  2,
      Bus_Speed      => High_Speed_100K,
      N1_Resolution  => 0.00391,   EGT_Resolution => 0.5,
      FF_Resolution  => 0.5);

   TRENT_XWB84 : constant Engine_Profile := (
      Manufacturer   => RR,        Series => TRENT_XWB84,
      Display_Name   => "Trent XWB-84    ",
      Max_Thrust_lbf => 84_200,
      N1_Max_TOGA    => 100.0,     N1_Max_MCT     => 96.0,
      N1_Idle_Ground =>  15.5,     N1_Idle_Flight =>  20.0,
      EGT_Max_TOGA   =>  1_060,    EGT_Max_MCT    =>  1_030,
      EGT_Max_Start  =>  785,      EGT_Max_Cont   =>  1_010,
      N2_Max         => 105.0,     N2_Idle        =>  60.0,
      Oil_Min_Psi    =>  20.0,     Oil_Max_Temp   =>  165,
      Has_FADEC      => True,      FADEC_Channels =>  3,
      Bus_Speed      => High_Speed_100K,
      N1_Resolution  => 0.00391,   EGT_Resolution => 1.0,
      FF_Resolution  => 1.0);

   TRENT_970B : constant Engine_Profile := (
      Manufacturer   => RR,        Series => TRENT_970,
      Display_Name   => "Trent 970B-84   ",
      Max_Thrust_lbf => 74_000,
      N1_Max_TOGA    => 100.0,     N1_Max_MCT     => 96.0,
      N1_Idle_Ground =>  14.5,     N1_Idle_Flight =>  18.5,
      EGT_Max_TOGA   =>  1_055,    EGT_Max_MCT    =>  1_025,
      EGT_Max_Start  =>  780,      EGT_Max_Cont   =>  1_005,
      N2_Max         => 105.0,     N2_Idle        =>  58.0,
      Oil_Min_Psi    =>  20.0,     Oil_Max_Temp   =>  165,
      Has_FADEC      => True,      FADEC_Channels =>  3,
      Bus_Speed      => High_Speed_100K,
      N1_Resolution  => 0.00391,   EGT_Resolution => 1.0,
      FF_Resolution  => 1.0);

   --  ═══════════════════════════════════════════════════════════════
   --  COMPLETE AIRCRAFT PROFILES
   --  ═══════════════════════════════════════════════════════════════

   A320_CFM56_Profile : constant Aircraft_Profile := (
      Family => A320_Family,  Display_Name => "Airbus A320-214         ",
      ICAO_Type => "A320",    Engine_Count => 2,  Engine => CFM56_5B4P,
      V_MO => 350.0,  M_MO => 0.82,  V_LE => 280.0,  V_LO => 250.0,
      V_FE_Flaps_1 => 230.0,  V_FE_Flaps_Full => 185.0,  V_S1G => 110.0,
      Max_Altitude_Ft => 39_800,  Opt_Cruise_FL => 370,
      MTOW_Lb => 162_040,  MLW_Lb => 142_198,  OEW_Lb => 92_594,
      Max_Payload_Lb => 46_737,  Max_Fuel_Lb => 42_684,
      Typical_FF_Kg_H => 1_095.0,  Range_Nm => 3_300,
      Suite => EIS2,  Bus_Arch => ARINC_429_Only,
      Has_ACARS => True,  Has_ADS_B_Out => True,  Has_TCAS_II_RA => True,
      Has_EGPWS => True,  Has_OANS => False,  Has_SVS => False,
      ARINC_429_Buses => 18);

   A320NEO_LEAP_Profile : constant Aircraft_Profile := (
      Family => A320_Family,  Display_Name => "Airbus A320neo CFM      ",
      ICAO_Type => "A20N",    Engine_Count => 2,  Engine => LEAP_1A26,
      V_MO => 350.0,  M_MO => 0.82,  V_LE => 280.0,  V_LO => 250.0,
      V_FE_Flaps_1 => 230.0,  V_FE_Flaps_Full => 185.0,  V_S1G => 108.0,
      Max_Altitude_Ft => 39_800,  Opt_Cruise_FL => 390,
      MTOW_Lb => 174_165,  MLW_Lb => 148_811,  OEW_Lb => 97_444,
      Max_Payload_Lb => 46_737,  Max_Fuel_Lb => 50_053,
      Typical_FF_Kg_H => 975.0,  Range_Nm => 3_500,
      Suite => EIS2,  Bus_Arch => ARINC_429_Only,
      Has_ACARS => True,  Has_ADS_B_Out => True,  Has_TCAS_II_RA => True,
      Has_EGPWS => True,  Has_OANS => True,  Has_SVS => False,
      ARINC_429_Buses => 18);

   B737_800_Profile : constant Aircraft_Profile := (
      Family => B737_Family,  Display_Name => "Boeing 737-800 NG       ",
      ICAO_Type => "B738",    Engine_Count => 2,  Engine => CFM56_7B27,
      V_MO => 340.0,  M_MO => 0.82,  V_LE => 270.0,  V_LO => 235.0,
      V_FE_Flaps_1 => 250.0,  V_FE_Flaps_Full => 162.0,  V_S1G => 112.0,
      Max_Altitude_Ft => 41_000,  Opt_Cruise_FL => 350,
      MTOW_Lb => 174_165,  MLW_Lb => 146_300,  OEW_Lb => 91_300,
      Max_Payload_Lb => 46_800,  Max_Fuel_Lb => 46_629,
      Typical_FF_Kg_H => 1_120.0,  Range_Nm => 3_060,
      Suite => Boeing_NDS,  Bus_Arch => ARINC_429_Only,
      Has_ACARS => True,  Has_ADS_B_Out => True,  Has_TCAS_II_RA => True,
      Has_EGPWS => True,  Has_OANS => False,  Has_SVS => False,
      ARINC_429_Buses => 16);

   B737_MAX8_Profile : constant Aircraft_Profile := (
      Family => B737_Family,  Display_Name => "Boeing 737 MAX 8        ",
      ICAO_Type => "B38M",    Engine_Count => 2,  Engine => LEAP_1B28,
      V_MO => 340.0,  M_MO => 0.82,  V_LE => 270.0,  V_LO => 235.0,
      V_FE_Flaps_1 => 250.0,  V_FE_Flaps_Full => 162.0,  V_S1G => 110.0,
      Max_Altitude_Ft => 41_000,  Opt_Cruise_FL => 390,
      MTOW_Lb => 181_897,  MLW_Lb => 153_000,  OEW_Lb => 95_900,
      Max_Payload_Lb => 45_700,  Max_Fuel_Lb => 48_800,
      Typical_FF_Kg_H => 980.0,  Range_Nm => 3_550,
      Suite => Boeing_EFIS_MAX,  Bus_Arch => ARINC_429_Only,
      Has_ACARS => True,  Has_ADS_B_Out => True,  Has_TCAS_II_RA => True,
      Has_EGPWS => True,  Has_OANS => False,  Has_SVS => True,
      ARINC_429_Buses => 16);

   A350_900_Profile : constant Aircraft_Profile := (
      Family => A350_Family,  Display_Name => "Airbus A350-900         ",
      ICAO_Type => "A359",    Engine_Count => 2,  Engine => TRENT_XWB84,
      V_MO => 375.0,  M_MO => 0.89,  V_LE => 280.0,  V_LO => 250.0,
      V_FE_Flaps_1 => 245.0,  V_FE_Flaps_Full => 177.0,  V_S1G => 118.0,
      Max_Altitude_Ft => 43_100,  Opt_Cruise_FL => 410,
      MTOW_Lb => 617_295,  MLW_Lb => 495_000,  OEW_Lb => 314_159,
      Max_Payload_Lb => 108_026,  Max_Fuel_Lb => 243_000,
      Typical_FF_Kg_H => 2_850.0,  Range_Nm => 8_100,
      Suite => A350_OANS,  Bus_Arch => AFDX_ARINC_664,
      Has_ACARS => True,  Has_ADS_B_Out => True,  Has_TCAS_II_RA => True,
      Has_EGPWS => True,  Has_OANS => True,  Has_SVS => True,
      ARINC_429_Buses => 24);

   A380_800_Profile : constant Aircraft_Profile := (
      Family => A380_Family,  Display_Name => "Airbus A380-800         ",
      ICAO_Type => "A388",    Engine_Count => 4,  Engine => TRENT_970B,
      V_MO => 365.0,  M_MO => 0.89,  V_LE => 280.0,  V_LO => 250.0,
      V_FE_Flaps_1 => 240.0,  V_FE_Flaps_Full => 177.0,  V_S1G => 125.0,
      Max_Altitude_Ft => 43_000,  Opt_Cruise_FL => 380,
      MTOW_Lb => 1_234_589,  MLW_Lb => 861_182,  OEW_Lb => 610_000,
      Max_Payload_Lb => 198_000,  Max_Fuel_Lb => 550_400,
      Typical_FF_Kg_H => 3_800.0,  Range_Nm => 8_200,
      Suite => A380_IMA,  Bus_Arch => AFDX_ARINC_664,
      Has_ACARS => True,  Has_ADS_B_Out => True,  Has_TCAS_II_RA => True,
      Has_EGPWS => True,  Has_OANS => True,  Has_SVS => True,
      ARINC_429_Buses => 32);

   --  ═══════════════════════════════════════════════════════════════
   --  PROFILE REGISTRY — indexed by type string
   --  ═══════════════════════════════════════════════════════════════

   type Profile_Index is
     (IDX_A320_CFM, IDX_A320_NEO, IDX_B737_NG, IDX_B737_MAX,
      IDX_A350_900, IDX_A380_800);

   type Profile_Registry is array (Profile_Index) of Aircraft_Profile;

   Registry : constant Profile_Registry :=
     (IDX_A320_CFM => A320_CFM56_Profile,
      IDX_A320_NEO => A320NEO_LEAP_Profile,
      IDX_B737_NG  => B737_800_Profile,
      IDX_B737_MAX => B737_MAX8_Profile,
      IDX_A350_900 => A350_900_Profile,
      IDX_A380_800 => A380_800_Profile);

   --  Active profile (runtime-switchable)
   Active_Index : Profile_Index := IDX_A320_CFM;

   function  Get_Active_Profile return Aircraft_Profile;
   function  Get_Profile (Idx : Profile_Index) return Aircraft_Profile;
   procedure Set_Active  (Idx : Profile_Index);
   function  ICAO_To_Index (ICAO : String) return Profile_Index;

   --  Derive current simulation parameters from active profile
   function  Cruise_N1_Pct    return Float;
   function  Cruise_EGT_C     return Integer;
   function  Idle_N1_Pct      return Float;

end AeroSys.Aircraft;
