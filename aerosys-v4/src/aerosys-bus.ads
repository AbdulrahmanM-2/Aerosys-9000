------------------------------------------------------------------------------
--  AeroSys.Bus — Full ARINC 429 Bus Driver Layer
--
--  Implements all major ARINC 429 subsystem bus interfaces:
--    FADEC Bus  — engine data from FADEC EECs (labels 061–077)
--    ADC Bus    — air data computer (labels 203–235)
--    IRS Bus    — inertial reference system (labels 100–114, 320–337)
--    FMS Bus    — flight management (labels 102–174)
--    AFCS Bus   — autopilot / flight director (labels 273–275)
--    Comms Bus  — VHF, transponder (labels 026–035)
--    System Bus — hydraulic, pressurisation, fuel (labels 135–262)
--
--  Each subsystem exposes:
--    Transmit — formats current state into ARINC words and queues them
--    Receive  — decodes received words and updates datastore
--    Monitor  — streams recent bus words for ground display
------------------------------------------------------------------------------

with AeroSys.ARINC429; use AeroSys.ARINC429;
with AeroSys.Types;    use AeroSys.Types;
with AeroSys.Aircraft; use AeroSys.Aircraft;

package AeroSys.Bus is

   --  ═══════════════════════════════════════════════════════════════
   --  BUS CHANNEL IDs
   --  ═══════════════════════════════════════════════════════════════

   type Bus_Channel is
     (FADEC_1,   FADEC_2,   FADEC_3,   FADEC_4,  -- one per engine
      ADC_1,     ADC_2,                           -- dual ADC
      IRS_1,     IRS_2,     IRS_3,                -- triple IRS
      FMS_1,     FMS_2,                           -- dual FMS
      AFCS_1,    AFCS_2,                          -- dual AFCS
      COMMS_1,   COMMS_2,                         -- VHF / ACARS
      TCAS_1,                                     -- TCAS computer
      ELEC_1,                                     -- electrical bus
      HYD_1,                                      -- hydraulic BSCU
      PRESS_1,                                    -- pressurisation
      FUEL_1,                                     -- fuel quantity
      ILS_MMR,                                    -- multi-mode receiver
      GPWS_EGPWS);                                -- ground prox

   type Bus_Channel_Monitor_Map is
     array (Bus_Channel) of Bus_Monitor;

   --  ═══════════════════════════════════════════════════════════════
   --  FADEC BUS INTERFACE
   --  Transmits engine data at 50 Hz on dedicated high-speed bus
   --  ═══════════════════════════════════════════════════════════════

   type FADEC_Bus_Word_Set is record
      N1    : ARINC_Word;
      N2    : ARINC_Word;
      EGT   : ARINC_Word;
      FF    : ARINC_Word;
      OIL_P : ARINC_Word;
      OIL_T : ARINC_Word;
      VIB   : ARINC_Word;
      EPR   : ARINC_Word;
      STAT  : ARINC_Word;   -- FADEC status discrete
   end record;

   --  Encode current engine state as ARINC 429 word set
   function  Encode_FADEC (Eng : Engine_Data; Profile : Engine_Profile)
                            return FADEC_Bus_Word_Set;

   --  Decode received FADEC words into engine data record
   procedure Decode_FADEC (Words   : FADEC_Bus_Word_Set;
                            Profile : Engine_Profile;
                            Eng     : out Engine_Data);

   --  ═══════════════════════════════════════════════════════════════
   --  AIR DATA COMPUTER (ADC) BUS
   --  ═══════════════════════════════════════════════════════════════

   type ADC_Bus_Word_Set is record
      Baro_Alt   : ARINC_Word;  -- 8#203# BNR, 0.125 ft/bit
      Baro_Alt_2 : ARINC_Word;  -- 8#204# (redundant)
      IAS        : ARINC_Word;  -- 8#206# BNR, 0.5 kt/bit
      Mach       : ARINC_Word;  -- 8#205# BNR, 0.000488/bit
      TAS        : ARINC_Word;  -- 8#210# BNR, 0.5 kt/bit
      SAT        : ARINC_Word;  -- 8#211# BNR, 0.25°C/bit
      TAT        : ARINC_Word;  -- 8#213# BNR, 0.25°C/bit
      Baro_Set   : ARINC_Word;  -- 8#235# BCD, hPa
      Overspd    : ARINC_Word;  -- 8#270# DIS
   end record;

   function  Encode_ADC (Speeds : Speed_Data; Baro_Set : Float)
                          return ADC_Bus_Word_Set;
   procedure Decode_ADC (Words  : ADC_Bus_Word_Set;
                          Speeds : out Speed_Data);

   --  ═══════════════════════════════════════════════════════════════
   --  INERTIAL REFERENCE SYSTEM (IRS) BUS
   --  ═══════════════════════════════════════════════════════════════

   type IRS_Bus_Word_Set is record
      Latitude     : ARINC_Word;  -- 8#100# BNR, 180/2^23 deg/bit
      Longitude    : ARINC_Word;  -- 8#101# BNR, 180/2^23 deg/bit
      GS           : ARINC_Word;  -- 8#102# BNR, 2 kt/bit
      Track_True   : ARINC_Word;  -- 8#103# BNR, 360/2^17 deg/bit
      True_Hdg     : ARINC_Word;  -- 8#114# BNR
      Mag_Hdg      : ARINC_Word;  -- 8#320# BNR
      Pitch        : ARINC_Word;  -- 8#324# BNR, 180/2^17 deg/bit
      Roll         : ARINC_Word;  -- 8#325# BNR
      Pitch_Rate   : ARINC_Word;  -- 8#326# BNR
      Roll_Rate    : ARINC_Word;  -- 8#327# BNR
      Yaw_Rate     : ARINC_Word;  -- 8#330# BNR
      Inert_VS     : ARINC_Word;  -- 8#212# BNR, 8 fpm/bit
      Norm_Accel   : ARINC_Word;  -- 8#335# BNR, g
      Long_Accel   : ARINC_Word;  -- 8#336# BNR
      Lat_Accel    : ARINC_Word;  -- 8#337# BNR
      IRS_Status   : ARINC_Word;  -- DIS — aligned/nav/fault
   end record;

   function  Encode_IRS (Att : Attitude_Data; Pos : Position_Data;
                          Acc : Accel_Data)    return IRS_Bus_Word_Set;
   procedure Decode_IRS (Words : IRS_Bus_Word_Set;
                          Att   : out Attitude_Data;
                          Pos   : out Position_Data;
                          Acc   : out Accel_Data);

   --  ═══════════════════════════════════════════════════════════════
   --  FLIGHT MANAGEMENT SYSTEM (FMS) BUS
   --  ═══════════════════════════════════════════════════════════════

   type FMS_Bus_Word_Set is record
      Crz_Alt      : ARINC_Word;  -- 8#130# BNR, 4 ft/bit
      Sel_Alt      : ARINC_Word;  -- 8#102# BNR
      Sel_Speed    : ARINC_Word;  -- 8#103# BNR
      Sel_Mach     : ARINC_Word;  -- 8#115# BNR
      XTK_Error    : ARINC_Word;  -- 8#173# BNR, NM
      DTG          : ARINC_Word;  -- 8#151# BNR, NM
      Desired_Trk  : ARINC_Word;  -- 8#121# BNR
      WPT_Bearing  : ARINC_Word;  -- 8#113# BNR
      WPT_Distance : ARINC_Word;  -- 8#125# BNR
      Gross_Wt     : ARINC_Word;  -- 8#132# BNR, 4 lb/bit
      FOB          : ARINC_Word;  -- 8#135# BNR
      Lat_Mode     : ARINC_Word;  -- 8#270# DIS
      Vert_Mode    : ARINC_Word;  -- 8#271# DIS
   end record;

   function  Encode_FMS (AP : Autopilot_State; FP : Flight_Plan;
                          GW : Float; FOB : Float) return FMS_Bus_Word_Set;
   procedure Decode_FMS (Words : FMS_Bus_Word_Set;
                          AP    : out Autopilot_State);

   --  ═══════════════════════════════════════════════════════════════
   --  AFCS (AUTOPILOT/FLIGHT DIRECTOR) BUS
   --  ═══════════════════════════════════════════════════════════════

   type AFCS_Bus_Word_Set is record
      AP_Engaged   : ARINC_Word;  -- 8#273# DIS
      AT_Engaged   : ARINC_Word;  -- 8#274# DIS
      FD_On        : ARINC_Word;  -- 8#275# DIS
      Sel_Alt      : ARINC_Word;  -- 8#102# BNR
      Sel_Hdg      : ARINC_Word;  -- 8#104# BNR
      Sel_VS       : ARINC_Word;  -- 8#105# BNR
      Sel_Spd      : ARINC_Word;  -- 8#103# BNR
      Lat_Dev      : ARINC_Word;  -- 8#173# BNR
   end record;

   function  Encode_AFCS (AP : Autopilot_State) return AFCS_Bus_Word_Set;
   procedure Decode_AFCS (Words : AFCS_Bus_Word_Set;
                           AP    : out Autopilot_State);

   --  ═══════════════════════════════════════════════════════════════
   --  ILS / MMR BUS
   --  ═══════════════════════════════════════════════════════════════

   type ILS_Bus_Word_Set is record
      Freq     : ARINC_Word;  -- 8#035# BCD, MHz
      LOC_Dev  : ARINC_Word;  -- BNR, dots (±2.5)
      GS_Dev   : ARINC_Word;  -- BNR, dots (±2.5)
      DME      : ARINC_Word;  -- BNR, NM
      Status   : ARINC_Word;  -- DIS
   end record;

   function  Encode_ILS (ILS : ILS_Data)   return ILS_Bus_Word_Set;
   procedure Decode_ILS (Words : ILS_Bus_Word_Set; ILS : out ILS_Data);

   --  ═══════════════════════════════════════════════════════════════
   --  SYSTEM BUS (Hydraulic / Press / Fuel / Electrical)
   --  ═══════════════════════════════════════════════════════════════

   type System_Bus_Word_Set is record
      Hyd_A     : ARINC_Word;  -- 8#261# BNR, PSI
      Hyd_B     : ARINC_Word;  -- 8#262# BNR, PSI
      Cab_Alt   : ARINC_Word;  -- 8#247# BNR, ft
      Diff_Pr   : ARINC_Word;  -- 8#250# BNR, PSI
      Cab_VS    : ARINC_Word;  -- 8#251# BNR, fpm
      Fuel_Tot  : ARINC_Word;  -- 8#135# BNR, lb
      Fuel_L    : ARINC_Word;  -- 8#136# BNR, lb
      Fuel_R    : ARINC_Word;  -- 8#137# BNR, lb
      Fuel_Ctr  : ARINC_Word;  -- 8#140# BNR, lb
   end record;

   function Encode_Systems return System_Bus_Word_Set;

   --  ═══════════════════════════════════════════════════════════════
   --  GLOBAL BUS MONITOR ARRAY
   --  ═══════════════════════════════════════════════════════════════

   Monitors : Bus_Channel_Monitor_Map;

   --  Push encoded word to appropriate channel monitor
   procedure Monitor_Word (Ch : Bus_Channel; W : ARINC_Word);

   --  Build full word snapshot for all active channels
   type Channel_Snapshot is record
      Channel    : Bus_Channel;
      Label      : ARINC_Label;
      Label_Name : String (1 .. 12);
      Raw        : ARINC_Word;
      Decoded    : Float;
      SSM        : ARINC_SSM;
      Valid      : Boolean;
      SDI        : ARINC_SDI;
   end record;

   Max_Snapshot_Words : constant := 64;
   type Snapshot_Array is array (1 .. Max_Snapshot_Words) of Channel_Snapshot;

   function Get_Bus_Snapshot return Snapshot_Array;
   function Get_Channel_Words (Ch : Bus_Channel; N : Natural)
                                return Bus_Word_Array;

end AeroSys.Bus;
