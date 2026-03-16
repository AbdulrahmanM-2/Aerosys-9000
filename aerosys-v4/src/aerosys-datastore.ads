------------------------------------------------------------------------------
--  AeroSys.Datastore — Protected Avionics State
--
--  Thread-safe store for all live avionics data.
--  Uses Ada Protected Objects (SPARK-compatible) to guarantee
--  priority-ceiling mutual exclusion per DO-178C requirements.
--
--  In production, this interfaces with ARINC 429/629 data bus drivers.
------------------------------------------------------------------------------

with AeroSys.Types;          use AeroSys.Types;
with AeroSys.JSON;           use AeroSys.JSON;
with Ada.Calendar;           use Ada.Calendar;
with Ada.Strings.Unbounded;  use Ada.Strings.Unbounded;

package AeroSys.Datastore is

   --------------------------------------------------------------------------
   --  LIFECYCLE
   --------------------------------------------------------------------------

   procedure Initialize;
   --  Seed with realistic cruise defaults; start data bus interface

   procedure Shutdown;
   --  Flush state, disconnect data bus

   --------------------------------------------------------------------------
   --  TELEMETRY
   --------------------------------------------------------------------------

   function  Get_Telemetry    return Telemetry_Snapshot;
   procedure Set_Telemetry    (Snap : Telemetry_Snapshot);

   --------------------------------------------------------------------------
   --  AUTOPILOT
   --------------------------------------------------------------------------

   function  Get_Autopilot    return Autopilot_State;
   procedure Set_Autopilot    (AP   : Autopilot_State);
   procedure Set_AP_Engaged   (On   : Boolean);
   procedure Set_AP_Targets   (T    : AP_Targets);

   --------------------------------------------------------------------------
   --  FLIGHT PLAN
   --------------------------------------------------------------------------

   function  Get_Flight_Plan  return Flight_Plan;
   procedure Set_Flight_Plan  (Plan : Flight_Plan);
   procedure Delete_Waypoint  (ID   : String);

   --------------------------------------------------------------------------
   --  PERFORMANCE
   --------------------------------------------------------------------------

   function  Get_Performance  return Performance_Data;
   procedure Set_Performance  (Perf : Performance_Data);

   --------------------------------------------------------------------------
   --  ENGINES
   --------------------------------------------------------------------------

   function  Get_Engines      return Engine_Array;
   procedure Set_Engine       (ID  : Positive; Data : Engine_Data);

   --------------------------------------------------------------------------
   --  NAVIGATION
   --------------------------------------------------------------------------

   function  Get_ILS          return ILS_Data;
   function  Get_TCAS         return TCAS_Data;
   function  Get_IRS          return IRS_Array;

   --------------------------------------------------------------------------
   --  SYSTEMS
   --------------------------------------------------------------------------

   function  Get_All_Systems_JSON return String;
   procedure Get_System (ID    :  String;
                         Sys   : out System_Status;
                         Found : out Boolean);

   --------------------------------------------------------------------------
   --  COMMUNICATIONS
   --------------------------------------------------------------------------

   function  Get_Radios       return Radio_Array;
   procedure Set_Radio_Freq   (ID        : Positive;
                                Active    : Frequency_MHz;
                                Standby   : Frequency_MHz);

   function  Get_Transponder  return Transponder_State;
   procedure Set_Transponder  (XPDR : Transponder_State);

   --------------------------------------------------------------------------
   --  ALERTS
   --------------------------------------------------------------------------

   function  Get_Alerts_JSON  return String;
   function  Get_Alert_Count  return Natural;
   procedure Acknowledge_Alert (ID : String);

   --------------------------------------------------------------------------
   --  DIAGNOSTICS
   --------------------------------------------------------------------------

   function  Get_Uptime       return Natural;
   --  Returns uptime in seconds since Initialize was called

end AeroSys.Datastore;
