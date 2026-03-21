------------------------------------------------------------------------------
--  AeroSys 9000 — Avionics REST API
--  Package: AeroSys.Types
--  Purpose: Core data type definitions (DO-178C compliant)
--
--  Compiler: GNAT 14.1 (GCC)
--  Standard: Ada 2022
--  Certification: DO-178C Level B (Safety-Critical Aviation Software)
------------------------------------------------------------------------------

with Ada.Calendar;
with Ada.Strings.Unbounded;

package AeroSys.Types is

   pragma Pure;

   use Ada.Strings.Unbounded;
   use Ada.Calendar;

   --------------------------------------------------------------------------
   --  CONSTRAINED NUMERIC SUBTYPES
   --------------------------------------------------------------------------

   subtype Angle_Deg       is Float range -360.0 .. 360.0;
   subtype Pitch_Deg       is Float range -90.0  .. 90.0;
   subtype Roll_Deg        is Float range -180.0 .. 180.0;
   subtype Latitude_Deg    is Float range -90.0  .. 90.0;
   subtype Longitude_Deg   is Float range -180.0 .. 180.0;
   subtype Altitude_Ft     is Integer range -2000 .. 60000;
   subtype Flight_Level    is Integer range 0 .. 600;
   subtype Speed_Kts       is Float range 0.0 .. 700.0;
   subtype Mach_Number     is Float range 0.0 .. 1.0;
   subtype N1_Percent      is Float range 0.0 .. 110.0;
   subtype N2_Percent      is Float range 0.0 .. 110.0;
   subtype EGT_Celsius     is Integer range -60 .. 1200;
   subtype Fuel_Flow_Kg_H  is Float range 0.0 .. 20000.0;
   subtype Pressure_PSI    is Float range 0.0 .. 5000.0;
   subtype Temperature_C   is Float range -100.0 .. 1000.0;
   subtype ILS_Dots        is Float range -2.5 .. 2.5;
   subtype Load_Factor_G   is Float range -5.0 .. 10.0;
   subtype VS_FPM          is Integer range -30000 .. 30000;
   subtype Squawk_Code     is String (1 .. 4);
   subtype ICAO_ID         is Unbounded_String;
   subtype Frequency_MHz   is Float range 100.0 .. 400.0;

   --------------------------------------------------------------------------
   --  ENUMERATIONS
   --------------------------------------------------------------------------

   type Thrust_Rating is
     (TOGA, FLEX, MCT, CLB, CRZ, IDLE, REVERSE);

   type Engine_Status is
     (RUNNING, STARTING, SHUTTING_DOWN, STOPPED, FIRE, FAULT);

   type Lateral_Mode is
     (LNAV, HDG_SEL, HDG_HOLD, LOC, ROLLOUT, OFF);

   type Vertical_Mode is
     (VNAV_ALT, VNAV_PTH, VNAV_SPD, FLCH, ALT_HOLD,
      VS_MODE, GS, FLARE, VERTICAL_OFF);

   type Speed_Mode is
     (MACH_MODE, IAS_MODE, RETARD, SPEED_OFF);

   type Flight_Phase is
     (PREFLIGHT, TAXI, TAKEOFF, INITIAL_CLIMB, CLIMB,
      CRUISE, DESCENT, APPROACH, LANDING, ROLLOUT, PARKED);

   type Alert_Severity is (WARNING, CAUTION, ADVISORY);

   type Alert_Category is
     (ENGINE_CAT, FUEL_CAT, HYDRAULIC_CAT, ELECTRICAL_CAT,
      PRESSURIZATION_CAT, FIRE_CAT, NAVIGATION_CAT,
      AUTOPILOT_CAT, FLIGHT_CONTROLS_CAT, OTHER_CAT);

   type System_Health is
     (NORMAL, ADVISORY_H, CAUTION_H, WARNING_H, FAULT, OFF, UNKNOWN);

   type Nav_Source is (GPS, IRS, MIXED, RADIO);

   type IRS_Mode is (IRS_OFF, ALIGN, NAV_MODE, ATT);

   type TCAS_Mode is (STBY, TA_ONLY, TA_RA);

   type TCAS_Threat is (PROXIMATE, TA, RA, INTRUDER);

   type TCAS_RA_Sense is (NONE, CLIMB, DESCEND, MAINTAIN);

   type Transponder_Mode is (XPDR_OFF, STBY, MODE_A, ALT, TA_MODE, TA_RA_MODE);

   type Waypoint_Type is
     (FIX, VOR, NDB, AIRPORT, RUNWAY, SID, STAR, APPROACH, MANUAL);

   --------------------------------------------------------------------------
   --  ATTITUDE RECORD
   --------------------------------------------------------------------------

   type Attitude_Data is record
      Pitch_Deg      : Pitch_Deg   := 0.0;
      Roll_Deg       : Roll_Deg    := 0.0;
      Yaw_Deg        : Angle_Deg   := 0.0;
      Pitch_Rate     : Float       := 0.0;
      Roll_Rate      : Float       := 0.0;
      Yaw_Rate       : Float       := 0.0;
      Valid           : Boolean    := True;
   end record;

   --------------------------------------------------------------------------
   --  SPEED RECORD
   --------------------------------------------------------------------------

   type Speed_Data is record
      IAS_Kt    : Speed_Kts   := 0.0;
      CAS_Kt    : Speed_Kts   := 0.0;
      TAS_Kt    : Speed_Kts   := 0.0;
      GS_Kt     : Speed_Kts   := 0.0;
      Mach      : Mach_Number := 0.0;
      VMO_Kt    : Speed_Kts   := 340.0;
      MMO       : Mach_Number := 0.86;
   end record;

   --------------------------------------------------------------------------
   --  POSITION RECORD
   --------------------------------------------------------------------------

   type Position_Data is record
      Latitude    : Latitude_Deg  := 0.0;
      Longitude   : Longitude_Deg := 0.0;
      Altitude_Ft : Altitude_Ft   := 0;
      FL          : Flight_Level  := 0;
      VS_FPM      : VS_FPM        := 0;
      Track_Deg   : Angle_Deg     := 0.0;
      Hdg_Mag     : Angle_Deg     := 0.0;
   end record;

   --------------------------------------------------------------------------
   --  TELEMETRY SNAPSHOT
   --------------------------------------------------------------------------

   type Telemetry_Snapshot is record
      Timestamp   : Time;
      Flight_ID   : Unbounded_String;
      Attitude    : Attitude_Data;
      Speeds      : Speed_Data;
      Position    : Position_Data;
      Normal_G    : Load_Factor_G := 1.0;
      Lateral_G   : Float         := 0.0;
      Long_G      : Float         := 0.0;
   end record;

   --------------------------------------------------------------------------
   --  ENGINE DATA
   --------------------------------------------------------------------------

   type Engine_Data is record
      Engine_ID      : Positive;
      Engine_Type    : Unbounded_String;
      Status         : Engine_Status     := STOPPED;
      N1_Pct         : N1_Percent        := 0.0;
      N2_Pct         : N2_Percent        := 0.0;
      EGT_C          : EGT_Celsius       := 0;
      FF_Kg_H        : Fuel_Flow_Kg_H    := 0.0;
      Oil_Press_PSI  : Pressure_PSI      := 0.0;
      Oil_Temp_C     : Temperature_C     := 0.0;
      Vibration      : Float             := 0.0;
      Rating         : Thrust_Rating     := IDLE;
      EPR            : Float             := 1.0;
      Reverse        : Boolean           := False;
   end record;

   type Engine_Array is array (1 .. 4) of Engine_Data;

   --------------------------------------------------------------------------
   --  AUTOPILOT STATE
   --------------------------------------------------------------------------

   type AP_Targets is record
      Target_IAS_Kt    : Speed_Kts   := 250.0;
      Target_Mach      : Mach_Number := 0.840;
      Target_Hdg_Deg   : Angle_Deg   := 0.0;
      Target_Alt_Ft    : Altitude_Ft := 35000;
      Target_VS_FPM    : VS_FPM      := 0;
      Target_FPA       : Float       := 0.0;
   end record;

   type Autopilot_State is record
      Engaged          : Boolean       := False;
      FD_On            : Boolean       := True;
      Autothrust       : Boolean       := False;
      Lat_Mode         : Lateral_Mode  := LNAV;
      Vert_Mode        : Vertical_Mode := ALT_HOLD;
      Spd_Mode         : Speed_Mode    := MACH_MODE;
      Targets          : AP_Targets;
      Max_Bank_Deg     : Float         := 25.0;
      Max_Pitch_Deg    : Float         := 15.0;
      Alt_Capture_Ft   : Integer       := 1000;
   end record;

   --------------------------------------------------------------------------
   --  WAYPOINT & FLIGHT PLAN
   --------------------------------------------------------------------------

   type Alt_Constraint_Type is (AT_ALT, AT_OR_ABOVE, AT_OR_BELOW, BETWEEN, NONE_C);
   type Spd_Constraint_Type is (AT_SPD, AT_OR_BELOW_SPD, NONE_SPD);

   type Waypoint is record
      Identifier     : Unbounded_String;
      Latitude       : Latitude_Deg    := 0.0;
      Longitude      : Longitude_Deg   := 0.0;
      WP_Type        : Waypoint_Type   := FIX;
      Alt_Con_Type   : Alt_Constraint_Type := NONE_C;
      Alt_Con_Ft     : Altitude_Ft     := 0;
      Spd_Con_Type   : Spd_Constraint_Type := NONE_SPD;
      Spd_Con_Kt     : Speed_Kts       := 0.0;
      ETA            : Time;
      DTG_NM         : Float           := 0.0;
      Overfly        : Boolean         := False;
   end record;

   Max_Waypoints : constant := 200;
   type Waypoint_Index is range 0 .. Max_Waypoints;
   type Waypoint_Array is array (Waypoint_Index range <>) of Waypoint;

   type Flight_Plan is record
      Plan_ID          : Unbounded_String;
      Flight_ID        : Unbounded_String;
      Origin           : Unbounded_String;
      Destination      : Unbounded_String;
      Alternate        : Unbounded_String;
      WP_Count         : Waypoint_Index := 0;
      Waypoints        : Waypoint_Array (1 .. Max_Waypoints);
      Active_Leg       : Waypoint_Index := 0;
      Total_Dist_NM    : Float          := 0.0;
      ETA_Dest         : Time;
      Modified_At      : Time;
   end record;

   --------------------------------------------------------------------------
   --  NAVIGATION DATA
   --------------------------------------------------------------------------

   type IRS_Data is record
      IRS_ID           : Positive;
      Mode             : IRS_Mode      := IRS_OFF;
      Align_Remaining  : Natural       := 0;
      Drift_NM_H       : Float         := 0.0;
      Hdg_Accuracy     : Float         := 0.5;
      Att_Valid        : Boolean       := False;
      Nav_Valid        : Boolean       := False;
   end record;

   type IRS_Array is array (1 .. 3) of IRS_Data;

   type ILS_Data is record
      Frequency_MHz  : Frequency_MHz := 108.0;
      Identifier     : Unbounded_String;
      LOC_Dev_Dots   : ILS_Dots      := 0.0;
      GS_Dev_Dots    : ILS_Dots      := 0.0;
      DME_NM         : Float         := 0.0;
      LOC_Captured   : Boolean       := False;
      GS_Captured    : Boolean       := False;
      Back_Course    : Boolean       := False;
   end record;

   type TCAS_Target is record
      Target_ID    : Unbounded_String;
      Callsign     : Unbounded_String;
      Squawk       : Squawk_Code      := "0000";
      Rel_Alt_Ft   : Integer          := 0;
      Bearing_Deg  : Angle_Deg        := 0.0;
      Dist_NM      : Float            := 0.0;
      VS_FPM       : VS_FPM           := 0;
      Threat       : TCAS_Threat      := PROXIMATE;
   end record;

   Max_TCAS_Targets : constant := 30;
   type TCAS_Target_Array is array (1 .. Max_TCAS_Targets) of TCAS_Target;

   type TCAS_Data is record
      Mode          : TCAS_Mode       := STBY;
      RA_Active     : Boolean         := False;
      RA_Sense      : TCAS_RA_Sense   := NONE;
      Target_Count  : Natural         := 0;
      Targets       : TCAS_Target_Array;
   end record;

   --------------------------------------------------------------------------
   --  SYSTEM STATUS
   --------------------------------------------------------------------------

   type System_Status is record
      System_ID    : Unbounded_String;
      Display_Name : Unbounded_String;
      Status       : System_Health  := UNKNOWN;
      Last_Updated : Time;
   end record;

   --------------------------------------------------------------------------
   --  COMMUNICATIONS
   --------------------------------------------------------------------------

   type Radio_State is record
      Radio_ID     : Positive;
      Active_MHz   : Frequency_MHz := 121.500;
      Standby_MHz  : Frequency_MHz := 121.500;
      TX           : Boolean       := False;
      RX           : Boolean       := True;
      Squelch      : Boolean       := True;
   end record;

   type Radio_Array is array (1 .. 3) of Radio_State;

   type Transponder_State is record
      Squawk        : Squawk_Code      := "2000";
      Mode          : Transponder_Mode := STBY;
      Ident         : Boolean          := False;
      Flight_ID     : Unbounded_String;
      Alt_Reported  : Altitude_Ft      := 0;
   end record;

   --------------------------------------------------------------------------
   --  ALERTS
   --------------------------------------------------------------------------

   type Alert is record
      Alert_ID      : Unbounded_String;
      Severity      : Alert_Severity   := ADVISORY;
      Category      : Alert_Category   := OTHER_CAT;
      Message       : Unbounded_String;
      System_ID     : Unbounded_String;
      Triggered_At  : Time;
      Acknowledged  : Boolean          := False;
      Ack_By        : Unbounded_String;
      Inhibited     : Boolean          := False;
   end record;

   Max_Alerts : constant := 64;
   type Alert_Index is range 0 .. Max_Alerts;
   type Alert_Array is array (Alert_Index range <>) of Alert;

   --------------------------------------------------------------------------
   --  PERFORMANCE DATA
   --------------------------------------------------------------------------

   type Performance_Data is record
      Cost_Index       : Natural          := 35;
      GW_Lb            : Float            := 347820.0;
      FOB_Lb           : Float            := 85400.0;
      Cruise_Mach      : Mach_Number      := 0.840;
      Optimal_FL       : Flight_Level     := 370;
      Max_FL           : Flight_Level     := 410;
      EFOB_Dest        : Float            := 32000.0;
      EFOB_Alternate   : Float            := 18000.0;
      Trip_Fuel_Lb     : Float            := 51200.0;
      Cont_Fuel_Lb     : Float            := 2560.0;
      ISA_Dev          : Float            := -4.0;
   end record;

   --------------------------------------------------------------------------
   --  HTTP STATUS CODES (Ada enumeration for type safety)
   --------------------------------------------------------------------------

   type HTTP_Status is
     (HTTP_200_OK,
      HTTP_201_Created,
      HTTP_204_No_Content,
      HTTP_400_Bad_Request,
      HTTP_401_Unauthorized,
      HTTP_403_Forbidden,
      HTTP_404_Not_Found,
      HTTP_409_Conflict,
      HTTP_422_Unprocessable,
      HTTP_423_Locked,
      HTTP_500_Internal,
      HTTP_503_Unavailable);

   function Status_Code (S : HTTP_Status) return Natural;
   function Status_Text (S : HTTP_Status) return String;

end AeroSys.Types;
