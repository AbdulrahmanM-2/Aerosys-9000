------------------------------------------------------------------------------
--  AeroSys.JSON — Package Body
--
--  Hand-rolled JSON builder. In production, replace with GNATCOLL.JSON.
--  Kept dependency-free for simulator portability.
------------------------------------------------------------------------------

with Ada.Calendar.Formatting;
with Ada.Float_Text_IO;
with Ada.Integer_Text_IO;
with Ada.Strings.Fixed;

package body AeroSys.JSON is

   use Ada.Calendar;
   use Ada.Strings.Unbounded;

   --------------------------------------------------------------------------
   --  INTERNAL HELPERS
   --------------------------------------------------------------------------

   function Quote (S : String) return String is
   begin
      return """" & S & """";
   end Quote;

   function JSON_Bool (B : Boolean) return String is
   begin
      return (if B then "true" else "false");
   end JSON_Bool;

   function ISO8601 (T : Ada.Calendar.Time) return String is
      use Ada.Calendar.Formatting;
   begin
      return Quote (Image (T, Include_Time_Fraction => True) & "Z");
   end ISO8601;

   function F (V : Float; Decimals : Natural := 2) return String is
      S : String (1 .. 32);
      Last : Natural;
   begin
      Ada.Float_Text_IO.Put (To => S, Item => V,
                             Aft => Decimals, Exp => 0);
      --  Trim leading spaces
      Last := S'Last;
      for I in S'Range loop
         if S (I) /= ' ' then
            return S (I .. Last);
         end if;
      end loop;
      return S;
   end F;

   function I (V : Integer) return String is
   begin
      return Ada.Strings.Fixed.Trim (V'Image, Ada.Strings.Left);
   end I;

   function UB (S : Unbounded_String) return String is
   begin
      return To_String (S);
   end UB;

   --------------------------------------------------------------------------
   --  ATTITUDE
   --------------------------------------------------------------------------

   function Att_JSON (A : Attitude_Data) return String is
   begin
      return
        "{""pitch_deg"":" & F (Float (A.Pitch_Deg)) &
        ",""roll_deg"":"  & F (Float (A.Roll_Deg)) &
        ",""yaw_deg"":"   & F (Float (A.Yaw_Deg)) &
        ",""pitch_rate"":" & F (A.Pitch_Rate, 3) &
        ",""roll_rate"":"  & F (A.Roll_Rate, 3) &
        ",""yaw_rate"":"   & F (A.Yaw_Rate, 3) &
        ",""valid"":"      & JSON_Bool (A.Valid) & "}";
   end Att_JSON;

   --------------------------------------------------------------------------
   --  SPEEDS
   --------------------------------------------------------------------------

   function Spd_JSON (S : Speed_Data) return String is
   begin
      return
        "{""ias_kt"":"  & F (Float (S.IAS_Kt)) &
        ",""cas_kt"":"  & F (Float (S.CAS_Kt)) &
        ",""tas_kt"":"  & F (Float (S.TAS_Kt)) &
        ",""gs_kt"":"   & F (Float (S.GS_Kt)) &
        ",""mach"":"    & F (Float (S.Mach), 3) &
        ",""vmo_kt"":"  & F (Float (S.VMO_Kt)) &
        ",""mmo"":"     & F (Float (S.MMO), 3) & "}";
   end Spd_JSON;

   --------------------------------------------------------------------------
   --  POSITION
   --------------------------------------------------------------------------

   function Pos_JSON (P : Position_Data) return String is
   begin
      return
        "{""latitude"":"    & F (Float (P.Latitude), 6) &
        ",""longitude"":"   & F (Float (P.Longitude), 6) &
        ",""altitude_ft"":"  & I (P.Altitude_Ft) &
        ",""flight_level"":"  & I (P.FL) &
        ",""vs_fpm"":"       & I (P.VS_FPM) &
        ",""track_deg"":"    & F (Float (P.Track_Deg)) &
        ",""heading_mag"":"  & F (Float (P.Hdg_Mag)) & "}";
   end Pos_JSON;

   --------------------------------------------------------------------------
   --  TELEMETRY SNAPSHOT
   --------------------------------------------------------------------------

   function To_JSON (Snap : Telemetry_Snapshot) return String is
   begin
      return
        "{""timestamp"":"   & ISO8601 (Snap.Timestamp) &
        ",""flight_id"":"   & Quote (UB (Snap.Flight_ID)) &
        ",""attitude"":"    & Att_JSON (Snap.Attitude) &
        ",""speeds"":"      & Spd_JSON (Snap.Speeds) &
        ",""position"":"    & Pos_JSON (Snap.Position) &
        ",""acceleration"":{" &
          """normal_g"":"   & F (Float (Snap.Normal_G), 3) &
          ",""lateral_g"":"  & F (Snap.Lateral_G, 3) &
          ",""longitudinal_g"":" & F (Snap.Long_G, 3) &
        "}}";
   end To_JSON;

   --------------------------------------------------------------------------
   --  ENGINE DATA
   --------------------------------------------------------------------------

   function To_JSON (Engine : Engine_Data) return String is
   begin
      return
        "{""engine_id"":"    & I (Engine.Engine_ID) &
        ",""type"":"         & Quote (UB (Engine.Engine_Type)) &
        ",""status"":"       & Quote (Engine.Status'Image) &
        ",""n1_pct"":"       & F (Float (Engine.N1_Pct), 1) &
        ",""n2_pct"":"       & F (Float (Engine.N2_Pct), 1) &
        ",""egt_c"":"        & I (Engine.EGT_C) &
        ",""ff_kg_h"":"      & F (Float (Engine.FF_Kg_H), 1) &
        ",""oil_pressure_psi"":" & F (Float (Engine.Oil_Press_PSI), 1) &
        ",""oil_temp_c"":"   & F (Float (Engine.Oil_Temp_C), 1) &
        ",""vibration"":"    & F (Engine.Vibration, 3) &
        ",""thrust_rating"":" & Quote (Engine.Rating'Image) &
        ",""epr"":"          & F (Engine.EPR, 3) &
        ",""reverse_deployed"":" & JSON_Bool (Engine.Reverse) & "}";
   end To_JSON;

   function To_JSON (Engines : Engine_Array;
                     Count   : Positive := 2) return String is
      Result : Unbounded_String := To_Unbounded_String ("{""count"":");
   begin
      Append (Result, I (Count));
      Append (Result, ",""engines"":[");
      for Eng in 1 .. Count loop
         if Eng > 1 then Append (Result, ","); end if;
         Append (Result, To_JSON (Engines (Eng)));
      end loop;
      Append (Result, "]}");
      return To_String (Result);
   end To_JSON;

   --------------------------------------------------------------------------
   --  AUTOPILOT
   --------------------------------------------------------------------------

   function To_JSON (AP : Autopilot_State) return String is
   begin
      return
        "{""engaged"":"          & JSON_Bool (AP.Engaged) &
        ",""fd_on"":"            & JSON_Bool (AP.FD_On) &
        ",""autothrust_engaged"":" & JSON_Bool (AP.Autothrust) &
        ",""lateral_mode"":"     & Quote (AP.Lat_Mode'Image) &
        ",""vertical_mode"":"    & Quote (AP.Vert_Mode'Image) &
        ",""speed_mode"":"       & Quote (AP.Spd_Mode'Image) &
        ",""targets"":{" &
          """target_speed_kt"":"   & F (Float (AP.Targets.Target_IAS_Kt), 0) &
          ",""target_mach"":"      & F (Float (AP.Targets.Target_Mach), 3) &
          ",""target_heading_deg"":" & F (Float (AP.Targets.Target_Hdg_Deg), 0) &
          ",""target_altitude_ft"":" & I (AP.Targets.Target_Alt_Ft) &
          ",""target_vs_fpm"":"    & I (AP.Targets.Target_VS_FPM) &
        "},""limits"":{" &
          """max_bank_deg"":"     & F (AP.Max_Bank_Deg, 1) &
          ",""max_pitch_deg"":"   & F (AP.Max_Pitch_Deg, 1) &
          ",""alt_capture_ft"":"  & I (AP.Alt_Capture_Ft) &
        "}}";
   end To_JSON;

   --------------------------------------------------------------------------
   --  WAYPOINT
   --------------------------------------------------------------------------

   function To_JSON (WP : Waypoint) return String is
   begin
      return
        "{""identifier"":"   & Quote (UB (WP.Identifier)) &
        ",""latitude"":"     & F (Float (WP.Latitude), 6) &
        ",""longitude"":"    & F (Float (WP.Longitude), 6) &
        ",""type"":"         & Quote (WP.WP_Type'Image) &
        ",""eta"":"          & ISO8601 (WP.ETA) &
        ",""dist_to_go_nm"":" & F (WP.DTG_NM, 1) &
        ",""overfly"":"      & JSON_Bool (WP.Overfly) & "}";
   end To_JSON;

   --------------------------------------------------------------------------
   --  FLIGHT PLAN
   --------------------------------------------------------------------------

   function To_JSON (Plan : Flight_Plan) return String is
      Result : Unbounded_String;
   begin
      Append (Result,
        "{""id"":"          & Quote (UB (Plan.Plan_ID)) &
        ",""flight_id"":"   & Quote (UB (Plan.Flight_ID)) &
        ",""origin"":"      & Quote (UB (Plan.Origin)) &
        ",""destination"":" & Quote (UB (Plan.Destination)) &
        ",""alternate"":"   & Quote (UB (Plan.Alternate)) &
        ",""active_leg"":"  & I (Integer (Plan.Active_Leg)) &
        ",""total_distance_nm"":" & F (Plan.Total_Dist_NM, 1) &
        ",""eta_destination"":" & ISO8601 (Plan.ETA_Dest) &
        ",""waypoints"":[");
      for W in 1 .. Plan.WP_Count loop
         if W > 1 then Append (Result, ","); end if;
         Append (Result, To_JSON (Plan.Waypoints (W)));
      end loop;
      Append (Result, "]}");
      return To_String (Result);
   end To_JSON;

   --------------------------------------------------------------------------
   --  ILS
   --------------------------------------------------------------------------

   function To_JSON (ILS : ILS_Data) return String is
   begin
      return
        "{""frequency_mhz"":"  & F (Float (ILS.Frequency_MHz), 2) &
        ",""identifier"":"     & Quote (UB (ILS.Identifier)) &
        ",""localizer_dev_dots"":" & F (Float (ILS.LOC_Dev_Dots), 2) &
        ",""glideslope_dev_dots"":" & F (Float (ILS.GS_Dev_Dots), 2) &
        ",""dme_nm"":"         & F (ILS.DME_NM, 1) &
        ",""localizer_captured"":" & JSON_Bool (ILS.LOC_Captured) &
        ",""glideslope_captured"":" & JSON_Bool (ILS.GS_Captured) &
        ",""back_course"":"    & JSON_Bool (ILS.Back_Course) & "}";
   end To_JSON;

   --------------------------------------------------------------------------
   --  TCAS
   --------------------------------------------------------------------------

   function TCAS_Target_JSON (T : TCAS_Target) return String is
   begin
      return
        "{""id"":"          & Quote (UB (T.Target_ID)) &
        ",""callsign"":"    & Quote (UB (T.Callsign)) &
        ",""squawk"":"      & Quote (T.Squawk) &
        ",""relative_alt_ft"":" & I (T.Rel_Alt_Ft) &
        ",""bearing_deg"":"  & F (Float (T.Bearing_Deg), 1) &
        ",""distance_nm"":"  & F (T.Dist_NM, 1) &
        ",""vs_fpm"":"       & I (T.VS_FPM) &
        ",""threat_level"":" & Quote (T.Threat'Image) & "}";
   end TCAS_Target_JSON;

   function To_JSON (TCAS : TCAS_Data) return String is
      Result : Unbounded_String;
   begin
      Append (Result,
        "{""mode"":"    & Quote (TCAS.Mode'Image) &
        ",""ra_active"":" & JSON_Bool (TCAS.RA_Active) &
        ",""ra_sense"":" & Quote (TCAS.RA_Sense'Image) &
        ",""targets"":[");
      for T in 1 .. TCAS.Target_Count loop
         if T > 1 then Append (Result, ","); end if;
         Append (Result, TCAS_Target_JSON (TCAS.Targets (T)));
      end loop;
      Append (Result, "]}");
      return To_String (Result);
   end To_JSON;

   --------------------------------------------------------------------------
   --  RADIO
   --------------------------------------------------------------------------

   function To_JSON (Radio : Radio_State) return String is
   begin
      return
        "{""radio_id"":"    & I (Radio.Radio_ID) &
        ",""active_mhz"":"  & F (Float (Radio.Active_MHz), 3) &
        ",""standby_mhz"":" & F (Float (Radio.Standby_MHz), 3) &
        ",""tx"":"          & JSON_Bool (Radio.TX) &
        ",""rx"":"          & JSON_Bool (Radio.RX) &
        ",""squelch"":"     & JSON_Bool (Radio.Squelch) & "}";
   end To_JSON;

   function To_JSON (Radios : Radio_Array) return String is
      Result : Unbounded_String := To_Unbounded_String ("[");
   begin
      for R in Radios'Range loop
         if R > Radios'First then Append (Result, ","); end if;
         Append (Result, To_JSON (Radios (R)));
      end loop;
      Append (Result, "]");
      return To_String (Result);
   end To_JSON;

   --------------------------------------------------------------------------
   --  TRANSPONDER
   --------------------------------------------------------------------------

   function To_JSON (XPDR : Transponder_State) return String is
   begin
      return
        "{""squawk"":"       & Quote (XPDR.Squawk) &
        ",""mode"":"         & Quote (XPDR.Mode'Image) &
        ",""ident"":"        & JSON_Bool (XPDR.Ident) &
        ",""flight_id"":"    & Quote (UB (XPDR.Flight_ID)) &
        ",""altitude_reported"":" & I (XPDR.Alt_Reported) & "}";
   end To_JSON;

   --------------------------------------------------------------------------
   --  SYSTEM STATUS
   --------------------------------------------------------------------------

   function To_JSON (Sys : System_Status) return String is
   begin
      return
        "{""system_id"":"    & Quote (UB (Sys.System_ID)) &
        ",""display_name"":" & Quote (UB (Sys.Display_Name)) &
        ",""status"":"       & Quote (Sys.Status'Image) &
        ",""last_updated"":" & ISO8601 (Sys.Last_Updated) & "}";
   end To_JSON;

   --------------------------------------------------------------------------
   --  PERFORMANCE
   --------------------------------------------------------------------------

   function To_JSON (Perf : Performance_Data) return String is
   begin
      return
        "{""cost_index"":"       & I (Perf.Cost_Index) &
        ",""gross_weight_lb"":"  & F (Perf.GW_Lb, 0) &
        ",""fuel_on_board_lb"":" & F (Perf.FOB_Lb, 0) &
        ",""cruise_mach"":"      & F (Float (Perf.Cruise_Mach), 3) &
        ",""optimal_fl"":"       & I (Integer (Perf.Optimal_FL)) &
        ",""max_fl"":"           & I (Integer (Perf.Max_FL)) &
        ",""efob_destination"":" & F (Perf.EFOB_Dest, 0) &
        ",""efob_alternate"":"   & F (Perf.EFOB_Alternate, 0) &
        ",""trip_fuel_lb"":"     & F (Perf.Trip_Fuel_Lb, 0) &
        ",""contingency_fuel_lb"":" & F (Perf.Cont_Fuel_Lb, 0) &
        ",""isa_deviation"":"    & F (Perf.ISA_Dev, 1) & "}";
   end To_JSON;

   --------------------------------------------------------------------------
   --  ALERT
   --------------------------------------------------------------------------

   function To_JSON (A : Alert) return String is
   begin
      return
        "{""id"":"          & Quote (UB (A.Alert_ID)) &
        ",""severity"":"    & Quote (A.Severity'Image) &
        ",""category"":"    & Quote (A.Category'Image) &
        ",""message"":"     & Quote (UB (A.Message)) &
        ",""system_id"":"   & Quote (UB (A.System_ID)) &
        ",""triggered_at"":" & ISO8601 (A.Triggered_At) &
        ",""acknowledged"":" & JSON_Bool (A.Acknowledged) &
        ",""inhibited"":"   & JSON_Bool (A.Inhibited) & "}";
   end To_JSON;

   --------------------------------------------------------------------------
   --  HEALTH
   --------------------------------------------------------------------------

   function Health_JSON (Status        : System_Health;
                         Version       : String;
                         Uptime_Sec    : Natural;
                         Active_Alerts : Natural) return String is
      use Ada.Calendar;
   begin
      return
        "{""status"":"        & Quote (Status'Image) &
        ",""version"":"       & Quote (Version) &
        ",""uptime_sec"":"    & I (Uptime_Sec) &
        ",""arinc_bus_ok"":"  & JSON_Bool (Status /= FAULT) &
        ",""active_alerts"":" & I (Active_Alerts) &
        ",""timestamp"":"     & ISO8601 (Clock) & "}";
   end Health_JSON;

   --------------------------------------------------------------------------
   --  ERROR
   --------------------------------------------------------------------------

   function Error_JSON (Code : String; Message : String) return String is
      use Ada.Calendar;
   begin
      return
        "{""code"":"      & Quote (Code) &
        ",""message"":"   & Quote (Message) &
        ",""timestamp"":" & ISO8601 (Clock) & "}";
   end Error_JSON;

   --------------------------------------------------------------------------
   --  STUB DESERIALISERS  (production: use GNATCOLL.JSON parser)
   --------------------------------------------------------------------------

   procedure From_JSON (JSON_Str : String;
                        AP       : out Autopilot_State;
                        OK       : out Boolean) is
      pragma Unreferenced (JSON_Str);
   begin
      AP := (others => <>);
      OK := False;
      --  TODO: Parse JSON_Str fields into AP record using GNATCOLL.JSON
   end From_JSON;

   procedure From_JSON (JSON_Str : String;
                        Targets  : out AP_Targets;
                        OK       : out Boolean) is
      pragma Unreferenced (JSON_Str);
   begin
      Targets := (others => <>);
      OK := False;
   end From_JSON;

   procedure From_JSON (JSON_Str : String;
                        WP       : out Waypoint;
                        OK       : out Boolean) is
      pragma Unreferenced (JSON_Str);
   begin
      WP := (others => <>);
      OK := False;
   end From_JSON;

   procedure From_JSON (JSON_Str : String;
                        Plan     : out Flight_Plan;
                        OK       : out Boolean) is
      pragma Unreferenced (JSON_Str);
   begin
      Plan := (others => <>);
      OK := False;
   end From_JSON;

   procedure From_JSON (JSON_Str : String;
                        XPDR     : out Transponder_State;
                        OK       : out Boolean) is
      pragma Unreferenced (JSON_Str);
   begin
      XPDR := (others => <>);
      OK := False;
   end From_JSON;

end AeroSys.JSON;
