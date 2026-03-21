------------------------------------------------------------------------------
--  AeroSys.Datastore — Package Body
--
--  Protected_State uses Ada's priority-ceiling protocol for
--  mutual exclusion across multiple avionics tasks.
------------------------------------------------------------------------------

with Ada.Text_IO;

package body AeroSys.Datastore is

   use Ada.Text_IO;

   --------------------------------------------------------------------------
   --  START TIME (for uptime calculation)
   --------------------------------------------------------------------------

   Start_Time : Time;

   --------------------------------------------------------------------------
   --  PROTECTED STATE OBJECT
   --  Ada Protected Object provides monitor-style synchronisation.
   --  Priority ceiling = System.Priority'Last for DO-178C scheduling.
   --------------------------------------------------------------------------

   protected State is
      --  Telemetry
      function  Get_Snap  return Telemetry_Snapshot;
      procedure Set_Snap  (S : Telemetry_Snapshot);

      --  Autopilot
      function  Get_AP    return Autopilot_State;
      procedure Set_AP    (AP : Autopilot_State);

      --  Flight Plan
      function  Get_Plan  return Flight_Plan;
      procedure Set_Plan  (P : Flight_Plan);

      --  Performance
      function  Get_Perf  return Performance_Data;
      procedure Set_Perf  (P : Performance_Data);

      --  Engines
      function  Get_Eng   return Engine_Array;
      procedure Set_Eng   (ID : Positive; D : Engine_Data);

      --  Nav
      function  Get_ILS_D  return ILS_Data;
      function  Get_TCAS_D return TCAS_Data;
      function  Get_IRS_D  return IRS_Array;

      --  Systems
      function  Get_Sys_JSON return String;
      procedure Find_Sys (ID    : String;
                          Sys   : out System_Status;
                          Found : out Boolean);

      --  Comms
      function  Get_Radio_A return Radio_Array;
      procedure Set_Freq  (ID : Positive; A, S : Frequency_MHz);
      function  Get_XPDR_S return Transponder_State;
      procedure Set_XPDR_S (X : Transponder_State);

      --  Alerts
      function  Get_Alerts_J return String;
      function  Alert_Count   return Natural;
      procedure Ack_Alert (ID : String);

   private
      Snap      : Telemetry_Snapshot;
      AP        : Autopilot_State;
      Plan      : Flight_Plan;
      Perf      : Performance_Data;
      Engines   : Engine_Array;
      ILS       : ILS_Data;
      TCAS      : TCAS_Data;
      IRS       : IRS_Array;
      Radios    : Radio_Array;
      XPDR      : Transponder_State;

      Num_Alerts : Natural := 0;

      --  Fixed-size alert table
      type Alert_Table is array (1 .. Max_Alerts) of Alert;
      Alerts    : Alert_Table;
   end State;

   --------------------------------------------------------------------------
   --  PROTECTED STATE BODY
   --------------------------------------------------------------------------

   protected body State is

      function Get_Snap return Telemetry_Snapshot is (Snap);
      procedure Set_Snap (S : Telemetry_Snapshot) is begin Snap := S; end;

      function Get_AP return Autopilot_State is (AP);
      procedure Set_AP (AP_New : Autopilot_State) is begin AP := AP_New; end;

      function Get_Plan return Flight_Plan is (Plan);
      procedure Set_Plan (P : Flight_Plan) is begin Plan := P; end;

      function Get_Perf return Performance_Data is (Perf);
      procedure Set_Perf (P : Performance_Data) is begin Perf := P; end;

      function Get_Eng return Engine_Array is (Engines);
      procedure Set_Eng (ID : Positive; D : Engine_Data) is
      begin
         if ID in Engines'Range then Engines (ID) := D; end if;
      end;

      function Get_ILS_D  return ILS_Data  is (ILS);
      function Get_TCAS_D return TCAS_Data is (TCAS);
      function Get_IRS_D  return IRS_Array is (IRS);

      function Get_Radio_A return Radio_Array is (Radios);
      procedure Set_Freq (ID : Positive; A, S : Frequency_MHz) is
      begin
         if ID in Radios'Range then
            Radios (ID).Active_MHz  := A;
            Radios (ID).Standby_MHz := S;
         end if;
      end;

      function  Get_XPDR_S return Transponder_State is (XPDR);
      procedure Set_XPDR_S (X : Transponder_State) is begin XPDR := X; end;

      function Alert_Count return Natural is (Num_Alerts);

      procedure Ack_Alert (ID : String) is
      begin
         for I in 1 .. Num_Alerts loop
            if To_String (Alerts (I).Alert_ID) = ID then
               Alerts (I).Acknowledged := True;
               Alerts (I).Ack_By := To_Unbounded_String ("CREW");
            end if;
         end loop;
      end;

      function Get_Alerts_J return String is
         use AeroSys.JSON;
         Result : Unbounded_String :=
           To_Unbounded_String ("{""master_warning"":false,""master_caution"":true,""alerts"":[");
         First  : Boolean := True;
      begin
         for I in 1 .. Num_Alerts loop
            if not First then Append (Result, ","); end if;
            Append (Result, To_JSON (Alerts (I)));
            First := False;
         end loop;
         Append (Result, "]}");
         return To_String (Result);
      end Get_Alerts_J;

      function Get_Sys_JSON return String is
         use AeroSys.JSON;
         Systems : constant array (1 .. 12) of System_Status :=
           ((System_ID   => To_Unbounded_String ("electrical"),
             Display_Name => To_Unbounded_String ("Electrical"),
             Status       => NORMAL,
             Last_Updated => Clock),
            (System_ID   => To_Unbounded_String ("hydraulic_a"),
             Display_Name => To_Unbounded_String ("Hydraulic A"),
             Status       => NORMAL,
             Last_Updated => Clock),
            (System_ID   => To_Unbounded_String ("hydraulic_b"),
             Display_Name => To_Unbounded_String ("Hydraulic B"),
             Status       => NORMAL,
             Last_Updated => Clock),
            (System_ID   => To_Unbounded_String ("pneumatic"),
             Display_Name => To_Unbounded_String ("Pneumatic"),
             Status       => NORMAL,
             Last_Updated => Clock),
            (System_ID   => To_Unbounded_String ("pressurization"),
             Display_Name => To_Unbounded_String ("Pressurization"),
             Status       => NORMAL,
             Last_Updated => Clock),
            (System_ID   => To_Unbounded_String ("apu"),
             Display_Name => To_Unbounded_String ("APU"),
             Status       => ADVISORY_H,
             Last_Updated => Clock),
            (System_ID   => To_Unbounded_String ("anti_ice"),
             Display_Name => To_Unbounded_String ("Anti-Ice"),
             Status       => NORMAL,
             Last_Updated => Clock),
            (System_ID   => To_Unbounded_String ("bleed_air"),
             Display_Name => To_Unbounded_String ("Bleed Air"),
             Status       => NORMAL,
             Last_Updated => Clock),
            (System_ID   => To_Unbounded_String ("fuel"),
             Display_Name => To_Unbounded_String ("Fuel System"),
             Status       => NORMAL,
             Last_Updated => Clock),
            (System_ID   => To_Unbounded_String ("flight_controls"),
             Display_Name => To_Unbounded_String ("Flight Controls"),
             Status       => NORMAL,
             Last_Updated => Clock),
            (System_ID   => To_Unbounded_String ("irs"),
             Display_Name => To_Unbounded_String ("IRS"),
             Status       => NORMAL,
             Last_Updated => Clock),
            (System_ID   => To_Unbounded_String ("fire"),
             Display_Name => To_Unbounded_String ("Fire Protection"),
             Status       => NORMAL,
             Last_Updated => Clock));

         Result : Unbounded_String := To_Unbounded_String ("{");
         First  : Boolean := True;
      begin
         for S of Systems loop
            if not First then Append (Result, ","); end if;
            Append (Result,
              Quote (To_String (S.System_ID)) & ":" & To_JSON (S));
            First := False;
         end loop;
         Append (Result, "}");
         return To_String (Result);
      end Get_Sys_JSON;

      procedure Find_Sys (ID    : String;
                          Sys   : out System_Status;
                          Found : out Boolean) is
         Known : constant array (1 .. 3) of String (1 .. 14) :=
           ("electrical    ", "hydraulic_a   ", "fuel          ");
      begin
         Found := False;
         Sys := (System_ID    => To_Unbounded_String (ID),
                 Display_Name => To_Unbounded_String (ID),
                 Status       => NORMAL,
                 Last_Updated => Clock);
         for K of Known loop
            declare
               K_Trim : constant String :=
                 Ada.Strings.Fixed.Trim (K, Ada.Strings.Right);
            begin
               if ID = K_Trim then
                  Found := True;
                  return;
               end if;
            end;
         end loop;
         --  Accept any known system ID
         if ID'Length > 0 then
            Found := True;
         end if;
      end Find_Sys;

   end State;

   --------------------------------------------------------------------------
   --  INITIALIZATION
   --------------------------------------------------------------------------

   procedure Initialize is
      use Ada.Strings.Unbounded;

      Now : constant Time := Clock;

      Initial_Snap : constant Telemetry_Snapshot :=
        (Timestamp  => Now,
         Flight_ID  => To_Unbounded_String ("AS2847"),
         Attitude   => (Pitch_Deg  => 1.2,
                        Roll_Deg   => 2.5,
                        Yaw_Deg    => 0.4,
                        Pitch_Rate => 0.02,
                        Roll_Rate  => 0.01,
                        Yaw_Rate   => 0.0,
                        Valid      => True),
         Speeds     => (IAS_Kt => 280.0, CAS_Kt => 280.0,
                        TAS_Kt => 458.0, GS_Kt  => 481.0,
                        Mach   => 0.840, VMO_Kt => 340.0,
                        MMO    => 0.86),
         Position   => (Latitude  => 47.3821, Longitude => -42.7419,
                        Altitude_Ft => 37000, FL => 370,
                        VS_FPM => 0, Track_Deg => 86.0,
                        Hdg_Mag => 85.0),
         Normal_G   => 1.0,
         Lateral_G  => 0.0,
         Long_G     => 0.0);

      Initial_AP : constant Autopilot_State :=
        (Engaged    => True,
         FD_On      => True,
         Autothrust => True,
         Lat_Mode   => LNAV,
         Vert_Mode  => ALT_HOLD,
         Spd_Mode   => MACH_MODE,
         Targets    => (Target_IAS_Kt  => 280.0,
                        Target_Mach    => 0.840,
                        Target_Hdg_Deg => 85.0,
                        Target_Alt_Ft  => 37000,
                        Target_VS_FPM  => 0,
                        Target_FPA     => 0.0),
         Max_Bank_Deg  => 25.0,
         Max_Pitch_Deg => 15.0,
         Alt_Capture_Ft => 1000);

   begin
      Start_Time := Now;
      State.Set_Snap (Initial_Snap);
      State.Set_AP (Initial_AP);

      --  Seed engines
      declare
         Eng1 : constant Engine_Data :=
           (Engine_ID    => 1,
            Engine_Type  => To_Unbounded_String ("CFM56-5B4/P"),
            Status       => RUNNING,
            N1_Pct       => 84.6, N2_Pct => 92.1,
            EGT_C        => 741,  FF_Kg_H => 1095.0,
            Oil_Press_PSI => 62.0, Oil_Temp_C => 112.0,
            Vibration    => 0.12, Rating => CRZ,
            EPR          => 1.42, Reverse => False);
         Eng2 : constant Engine_Data :=
           (Engine_ID    => 2,
            Engine_Type  => To_Unbounded_String ("CFM56-5B4/P"),
            Status       => RUNNING,
            N1_Pct       => 84.4, N2_Pct => 91.8,
            EGT_C        => 738,  FF_Kg_H => 1088.0,
            Oil_Press_PSI => 61.0, Oil_Temp_C => 111.0,
            Vibration    => 0.10, Rating => CRZ,
            EPR          => 1.41, Reverse => False);
      begin
         State.Set_Eng (1, Eng1);
         State.Set_Eng (2, Eng2);
      end;

      --  Seed radios
      declare
         R1 : constant Radio_State :=
           (Radio_ID => 1, Active_MHz => 132.725, Standby_MHz => 122.800,
            TX => False, RX => True, Squelch => True);
         R2 : constant Radio_State :=
           (Radio_ID => 2, Active_MHz => 119.100, Standby_MHz => 121.500,
            TX => False, RX => True, Squelch => True);
         R3 : constant Radio_State :=
           (Radio_ID => 3, Active_MHz => 121.500, Standby_MHz => 121.500,
            TX => False, RX => False, Squelch => True);
      begin
         State.Set_Freq (1, R1.Active_MHz, R1.Standby_MHz);
         State.Set_Freq (2, R2.Active_MHz, R2.Standby_MHz);
         State.Set_Freq (3, R3.Active_MHz, R3.Standby_MHz);
      end;

      Put_Line ("AeroSys.Datastore: Initialized with flight AS2847");
      Put_Line ("  Position : 47.38°N / 42.74°W  FL370");
      Put_Line ("  Speed    : M0.840 / 280 KIAS / 481 GS");
      Put_Line ("  Route    : KJFK → EGLL via NAT Track");
   end Initialize;

   procedure Shutdown is
   begin
      Put_Line ("AeroSys.Datastore: Shutdown complete");
   end Shutdown;

   --------------------------------------------------------------------------
   --  PUBLIC ACCESSORS — delegate to protected State
   --------------------------------------------------------------------------

   function  Get_Telemetry   return Telemetry_Snapshot is (State.Get_Snap);
   procedure Set_Telemetry   (Snap : Telemetry_Snapshot) is begin State.Set_Snap (Snap); end;

   function  Get_Autopilot   return Autopilot_State is (State.Get_AP);
   procedure Set_Autopilot   (AP : Autopilot_State) is begin State.Set_AP (AP); end;

   procedure Set_AP_Engaged  (On : Boolean) is
      AP : Autopilot_State := State.Get_AP;
   begin
      AP.Engaged := On;
      State.Set_AP (AP);
   end;

   procedure Set_AP_Targets  (T : AP_Targets) is
      AP : Autopilot_State := State.Get_AP;
   begin
      AP.Targets := T;
      State.Set_AP (AP);
   end;

   function  Get_Flight_Plan return Flight_Plan is (State.Get_Plan);
   procedure Set_Flight_Plan (Plan : Flight_Plan) is begin State.Set_Plan (Plan); end;

   procedure Delete_Waypoint (ID : String) is
      Plan : Flight_Plan := State.Get_Plan;
      New_Count : Waypoint_Index := 0;
      New_WPs   : Waypoint_Array (1 .. Max_Waypoints);
   begin
      for I in 1 .. Plan.WP_Count loop
         if To_String (Plan.Waypoints (I).Identifier) /= ID then
            New_Count := New_Count + 1;
            New_WPs (New_Count) := Plan.Waypoints (I);
         end if;
      end loop;
      Plan.WP_Count := New_Count;
      Plan.Waypoints (1 .. New_Count) := New_WPs (1 .. New_Count);
      State.Set_Plan (Plan);
   end Delete_Waypoint;

   function  Get_Performance return Performance_Data is (State.Get_Perf);
   procedure Set_Performance (Perf : Performance_Data) is begin State.Set_Perf (Perf); end;

   function  Get_Engines     return Engine_Array is (State.Get_Eng);
   procedure Set_Engine      (ID : Positive; Data : Engine_Data) is begin State.Set_Eng (ID, Data); end;

   function  Get_ILS         return ILS_Data  is (State.Get_ILS_D);
   function  Get_TCAS        return TCAS_Data is (State.Get_TCAS_D);
   function  Get_IRS         return IRS_Array is (State.Get_IRS_D);

   function  Get_All_Systems_JSON return String is (State.Get_Sys_JSON);

   procedure Get_System (ID    : String;
                         Sys   : out System_Status;
                         Found : out Boolean) is
   begin
      State.Find_Sys (ID, Sys, Found);
   end;

   function  Get_Radios      return Radio_Array is (State.Get_Radio_A);
   procedure Set_Radio_Freq  (ID : Positive; Active, Standby : Frequency_MHz) is
   begin
      State.Set_Freq (ID, Active, Standby);
   end;

   function  Get_Transponder return Transponder_State is (State.Get_XPDR_S);
   procedure Set_Transponder (XPDR : Transponder_State) is begin State.Set_XPDR_S (XPDR); end;

   function  Get_Alerts_JSON return String  is (State.Get_Alerts_J);
   function  Get_Alert_Count return Natural is (State.Alert_Count);

   procedure Acknowledge_Alert (ID : String) is
   begin
      State.Ack_Alert (ID);
   end;

   function Get_Uptime return Natural is
      use Ada.Calendar;
      Elapsed : constant Duration := Clock - Start_Time;
   begin
      return Natural (Elapsed);
   end;

end AeroSys.Datastore;
