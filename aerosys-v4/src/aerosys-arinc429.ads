------------------------------------------------------------------------------
--  AeroSys.ARINC429 — ARINC 429 Bus Interface Package
--
--  Implements ARINC 429 digital information transfer standard.
--  32-bit word format:  [P|SSM|DATA(19)|SDI|LABEL(8)]
--    Bits  1– 8 : Label (octal, MSB-first on wire = LSB in word)
--    Bits  9–10 : Source/Destination Identifier (SDI)
--    Bits 11–29 : Data field (BNR, BCD, DIS, or ISO-5)
--    Bits 30–31 : Sign/Status Matrix (SSM)
--    Bit  32    : Odd parity
--
--  Supported data formats:
--    BNR  — Binary (two's complement, scaled)
--    BCD  — Binary-coded decimal
--    DIS  — Discrete (bit flags)
--    ISO5 — Character data (ISO 5 / ASCII)
--
--  Supported bus speeds:
--    Low  speed :  12.5 kbps
--    High speed : 100.0 kbps
--
--  Standards: ARINC 429 Part 1 (Data Transmission) Rev 17
--             ARINC 429 Part 2 (Label Assignments)
--             ARINC 429 Part 3 (File Data Transfer)
------------------------------------------------------------------------------

with Interfaces; use Interfaces;

package AeroSys.ARINC429 is

   pragma Pure;

   --  ═══════════════════════════════════════════════════════════════
   --  FUNDAMENTAL TYPES
   --  ═══════════════════════════════════════════════════════════════

   subtype ARINC_Word    is Unsigned_32;
   subtype ARINC_Label   is Unsigned_8;   -- octal label 000–377
   subtype ARINC_SDI     is Unsigned_2;   -- 00–11
   subtype ARINC_SSM     is Unsigned_2;
   subtype ARINC_Data_19 is Unsigned_32;  -- 19-bit data field

   type Bus_Speed   is (Low_Speed_12K5, High_Speed_100K);
   type Data_Format is (BNR, BCD, DIS, ISO5, OPCODE);

   --  SSM field values for BNR words
   SSM_FAILURE_WARNING : constant ARINC_SSM := 2#00#;
   SSM_NO_COMPUTED_DATA: constant ARINC_SSM := 2#01#;
   SSM_FUNCTIONAL_TEST : constant ARINC_SSM := 2#10#;
   SSM_NORMAL_OPERATION: constant ARINC_SSM := 2#11#;

   --  SSM BNR sign conventions
   SSM_PLUS  : constant ARINC_SSM := 2#11#;
   SSM_MINUS : constant ARINC_SSM := 2#01#;

   --  ═══════════════════════════════════════════════════════════════
   --  WORD RECORD
   --  ═══════════════════════════════════════════════════════════════

   type ARINC_Word_Decoded is record
      Raw    : ARINC_Word;
      Label  : ARINC_Label;
      SDI    : ARINC_SDI;
      Data   : ARINC_Data_19;
      SSM    : ARINC_SSM;
      Parity : Boolean;      -- True = parity bit set
      Valid  : Boolean;      -- Parity check passed
      Format : Data_Format;
   end record;

   --  ═══════════════════════════════════════════════════════════════
   --  LABEL CONSTANTS — ARINC 429 Part 2 standard assignments
   --  (octal notation matches ARINC documentation)
   --  ═══════════════════════════════════════════════════════════════

   --  Navigation — IRS / GPS
   LBL_LATITUDE              : constant ARINC_Label := 8#100#;  -- 64h
   LBL_LONGITUDE             : constant ARINC_Label := 8#101#;  -- 65h
   LBL_GROUND_SPEED          : constant ARINC_Label := 8#102#;  -- 66h
   LBL_WIND_SPEED            : constant ARINC_Label := 8#103#;  -- 67h
   LBL_WIND_DIRECTION        : constant ARINC_Label := 8#104#;  -- 68h
   LBL_TRACK_ANGLE_TRUE      : constant ARINC_Label := 8#103#;
   LBL_TRUE_HEADING          : constant ARINC_Label := 8#114#;  -- 4Ch
   LBL_MAGNETIC_HEADING      : constant ARINC_Label := 8#320#;  -- D0h
   LBL_DRIFT_ANGLE           : constant ARINC_Label := 8#121#;
   LBL_FLIGHT_PATH_ANGLE     : constant ARINC_Label := 8#122#;
   LBL_INERTIAL_ALTITUDE     : constant ARINC_Label := 8#361#;
   LBL_INERTIAL_VS           : constant ARINC_Label := 8#212#;
   LBL_NORM_ACCEL            : constant ARINC_Label := 8#335#;
   LBL_LONG_ACCEL            : constant ARINC_Label := 8#336#;
   LBL_LAT_ACCEL             : constant ARINC_Label := 8#337#;

   --  Air Data — ADC
   LBL_BARO_CORRECTED_ALT_1  : constant ARINC_Label := 8#203#;  -- 83h
   LBL_BARO_CORRECTED_ALT_2  : constant ARINC_Label := 8#204#;
   LBL_AIRSPEED_IAS          : constant ARINC_Label := 8#206#;  -- 86h
   LBL_MACH_NUMBER           : constant ARINC_Label := 8#205#;  -- 85h
   LBL_TAS                   : constant ARINC_Label := 8#210#;  -- 88h
   LBL_TOTAL_AIR_TEMP        : constant ARINC_Label := 8#213#;
   LBL_STATIC_AIR_TEMP       : constant ARINC_Label := 8#211#;
   LBL_BARO_SETTING          : constant ARINC_Label := 8#235#;
   LBL_OVERSPEED_WARNING     : constant ARINC_Label := 8#270#;
   LBL_MAX_OPERATING_SPEED   : constant ARINC_Label := 8#271#;

   --  Attitude — IRS / AHRS
   LBL_PITCH_ATTITUDE        : constant ARINC_Label := 8#324#;  -- D4h
   LBL_ROLL_ATTITUDE         : constant ARINC_Label := 8#325#;  -- D5h
   LBL_PITCH_RATE            : constant ARINC_Label := 8#326#;
   LBL_ROLL_RATE             : constant ARINC_Label := 8#327#;
   LBL_YAW_RATE              : constant ARINC_Label := 8#330#;

   --  Engine / FADEC (CFM56, LEAP, V2500, Trent)
   LBL_N1_ENGINE_1           : constant ARINC_Label := 8#061#;  -- 31h
   LBL_N1_ENGINE_2           : constant ARINC_Label := 8#062#;  -- 32h
   LBL_N1_ENGINE_3           : constant ARINC_Label := 8#063#;
   LBL_N1_ENGINE_4           : constant ARINC_Label := 8#064#;
   LBL_N2_ENGINE_1           : constant ARINC_Label := 8#065#;
   LBL_N2_ENGINE_2           : constant ARINC_Label := 8#066#;
   LBL_EGT_ENGINE_1          : constant ARINC_Label := 8#071#;
   LBL_EGT_ENGINE_2          : constant ARINC_Label := 8#072#;
   LBL_FUEL_FLOW_1           : constant ARINC_Label := 8#073#;
   LBL_FUEL_FLOW_2           : constant ARINC_Label := 8#074#;
   LBL_FUEL_FLOW_3           : constant ARINC_Label := 8#075#;
   LBL_FUEL_FLOW_4           : constant ARINC_Label := 8#076#;
   LBL_OIL_PRESSURE_1        : constant ARINC_Label := 8#077#;
   LBL_OIL_PRESSURE_2        : constant ARINC_Label := 8#100#;
   LBL_OIL_TEMP_1            : constant ARINC_Label := 8#041#;
   LBL_OIL_TEMP_2            : constant ARINC_Label := 8#042#;
   LBL_EPR_1                 : constant ARINC_Label := 8#051#;
   LBL_EPR_2                 : constant ARINC_Label := 8#052#;
   LBL_VIBRATION_1           : constant ARINC_Label := 8#055#;
   LBL_VIBRATION_2           : constant ARINC_Label := 8#056#;
   LBL_THRUST_RATING         : constant ARINC_Label := 8#057#;
   LBL_FLEX_TEMP             : constant ARINC_Label := 8#046#;
   LBL_FADEC_STATUS_1        : constant ARINC_Label := 8#270#;
   LBL_FADEC_STATUS_2        : constant ARINC_Label := 8#271#;

   --  FMS / FMC
   LBL_FMS_ALTITUDE_CMD      : constant ARINC_Label := 8#102#;
   LBL_FMS_SPEED_CMD         : constant ARINC_Label := 8#103#;
   LBL_FMS_MACH_CMD          : constant ARINC_Label := 8#115#;
   LBL_FMS_LATERAL_MODE      : constant ARINC_Label := 8#270#;
   LBL_FMS_VERTICAL_MODE     : constant ARINC_Label := 8#271#;
   LBL_DESTINATION_ETA       : constant ARINC_Label := 8#150#;
   LBL_DTG_TO_DESTINATION    : constant ARINC_Label := 8#151#;
   LBL_XTK_ERROR             : constant ARINC_Label := 8#173#;
   LBL_ALONG_TRK_DIST        : constant ARINC_Label := 8#174#;
   LBL_DESIRED_TRACK         : constant ARINC_Label := 8#121#;
   LBL_ACTIVE_WPT_BEARING    : constant ARINC_Label := 8#113#;
   LBL_ACTIVE_WPT_DISTANCE   : constant ARINC_Label := 8#125#;
   LBL_CRZ_ALTITUDE          : constant ARINC_Label := 8#130#;
   LBL_COST_INDEX            : constant ARINC_Label := 8#131#;
   LBL_GROSS_WEIGHT          : constant ARINC_Label := 8#132#;
   LBL_FUEL_ON_BOARD         : constant ARINC_Label := 8#135#;

   --  Autopilot / AFCS
   LBL_AP_ENGAGED            : constant ARINC_Label := 8#273#;
   LBL_AT_ENGAGED            : constant ARINC_Label := 8#274#;
   LBL_FD_ON                 : constant ARINC_Label := 8#275#;
   LBL_SELECTED_ALTITUDE     : constant ARINC_Label := 8#102#;
   LBL_SELECTED_AIRSPEED     : constant ARINC_Label := 8#103#;
   LBL_SELECTED_HEADING      : constant ARINC_Label := 8#104#;
   LBL_SELECTED_VS           : constant ARINC_Label := 8#105#;

   --  Communications
   LBL_VHF1_ACTIVE_FREQ      : constant ARINC_Label := 8#030#;
   LBL_VHF2_ACTIVE_FREQ      : constant ARINC_Label := 8#031#;
   LBL_VOR1_FREQ             : constant ARINC_Label := 8#034#;
   LBL_ILS_FREQ              : constant ARINC_Label := 8#035#;
   LBL_SQUAWK_CODE           : constant ARINC_Label := 8#026#;
   LBL_ATC_MODE              : constant ARINC_Label := 8#027#;

   --  Systems — pressurisation
   LBL_CABIN_ALTITUDE        : constant ARINC_Label := 8#247#;
   LBL_DIFF_PRESSURE         : constant ARINC_Label := 8#250#;
   LBL_CABIN_VS              : constant ARINC_Label := 8#251#;

   --  Fuel
   LBL_FUEL_QTY_TOTAL        : constant ARINC_Label := 8#135#;
   LBL_FUEL_QTY_LEFT         : constant ARINC_Label := 8#136#;
   LBL_FUEL_QTY_RIGHT        : constant ARINC_Label := 8#137#;
   LBL_FUEL_QTY_CENTER       : constant ARINC_Label := 8#140#;

   --  Hydraulic
   LBL_HYD_PRESS_A           : constant ARINC_Label := 8#261#;
   LBL_HYD_PRESS_B           : constant ARINC_Label := 8#262#;

   --  TCAS / ACAS
   LBL_TCAS_MODE             : constant ARINC_Label := 8#270#;
   LBL_TCAS_RA_COMMAND       : constant ARINC_Label := 8#271#;
   LBL_TCAS_TARGET_ALTITUDE  : constant ARINC_Label := 8#272#;

   --  ═══════════════════════════════════════════════════════════════
   --  ENCODING / DECODING
   --  ═══════════════════════════════════════════════════════════════

   --  Build a raw ARINC word from components
   function Encode_Word
     (Label  : ARINC_Label;
      SDI    : ARINC_SDI;
      Data   : ARINC_Data_19;
      SSM    : ARINC_SSM) return ARINC_Word;

   --  Decode a raw 32-bit word into components
   function Decode_Word (Raw : ARINC_Word) return ARINC_Word_Decoded;

   --  BNR encoding: float value → 19-bit two's complement scaled
   function Encode_BNR
     (Value      : Float;
      Resolution : Float;
      Positive   : Boolean := True) return ARINC_Data_19;

   --  BNR decoding: 19-bit raw → float
   function Decode_BNR
     (Data       : ARINC_Data_19;
      Resolution : Float;
      SSM        : ARINC_SSM) return Float;

   --  BCD encoding: float → packed BCD digits
   function Encode_BCD (Value : Float; Scale : Natural) return ARINC_Data_19;
   function Decode_BCD (Data  : ARINC_Data_19; Scale : Natural) return Float;

   --  Parity
   function Compute_Parity (Word : ARINC_Word) return Boolean;
   function Check_Parity   (Word : ARINC_Word) return Boolean;

   --  Label bit-reversal (ARINC 429 transmits label LSB first)
   function Reverse_Label (Label : ARINC_Label) return ARINC_Label;

   --  Label name lookup (returns short string)
   function Label_Name (Label : ARINC_Label) return String;

   --  ═══════════════════════════════════════════════════════════════
   --  BUS CONFIGURATION
   --  ═══════════════════════════════════════════════════════════════

   type Bus_Config is record
      Speed         : Bus_Speed     := High_Speed_100K;
      Max_Words_Sec : Natural       := 3_000;  -- at 100kbps
      Tx_Enabled    : Boolean       := True;
      Rx_Enabled    : Boolean       := True;
      Self_Test     : Boolean       := False;
   end record;

   --  BUS WORD STREAM — circular buffer for monitoring
   Max_Bus_Buffer : constant := 512;
   type Bus_Buffer_Index is mod Max_Bus_Buffer;
   type Bus_Word_Array   is array (Bus_Buffer_Index) of ARINC_Word_Decoded;

   type Bus_Monitor is record
      Buffer      : Bus_Word_Array;
      Head        : Bus_Buffer_Index := 0;
      Word_Count  : Natural          := 0;
      Error_Count : Natural          := 0;
      Rate_Hz     : Float            := 0.0;
      Active      : Boolean          := False;
   end record;

   procedure Push_Word  (Monitor : in out Bus_Monitor; W : ARINC_Word);
   function  Peek_Words (Monitor : Bus_Monitor; Count : Natural)
                         return Bus_Word_Array;

end AeroSys.ARINC429;
