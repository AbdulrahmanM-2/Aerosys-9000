------------------------------------------------------------------------------
--  AeroSys.JSON — JSON Serialisation Layer
--
--  Converts Ada records to/from RFC 8259 JSON strings for REST transport.
--  Uses GNATCOLL.JSON internally.
------------------------------------------------------------------------------

with AeroSys.Types;         use AeroSys.Types;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package AeroSys.JSON is

   --------------------------------------------------------------------------
   --  SERIALISERS  (Ada record → JSON string)
   --------------------------------------------------------------------------

   function To_JSON (Snap    : Telemetry_Snapshot) return String;
   function To_JSON (Engine  : Engine_Data)        return String;
   function To_JSON (Engines : Engine_Array;
                     Count   : Positive := 2)      return String;
   function To_JSON (AP      : Autopilot_State)    return String;
   function To_JSON (Plan    : Flight_Plan)        return String;
   function To_JSON (WP      : Waypoint)           return String;
   function To_JSON (ILS     : ILS_Data)           return String;
   function To_JSON (TCAS    : TCAS_Data)          return String;
   function To_JSON (Radio   : Radio_State)        return String;
   function To_JSON (Radios  : Radio_Array)        return String;
   function To_JSON (XPDR    : Transponder_State)  return String;
   function To_JSON (Sys     : System_Status)      return String;
   function To_JSON (Perf    : Performance_Data)   return String;
   function To_JSON (A       : Alert)              return String;

   function Health_JSON (Status      : System_Health;
                         Version     : String;
                         Uptime_Sec  : Natural;
                         Active_Alerts : Natural) return String;

   function Error_JSON  (Code    : String;
                         Message : String) return String;

   --------------------------------------------------------------------------
   --  DESERIALISERS  (JSON string → Ada record)
   --------------------------------------------------------------------------

   procedure From_JSON (JSON_Str : String;
                        AP       : out Autopilot_State;
                        OK       : out Boolean);

   procedure From_JSON (JSON_Str : String;
                        Targets  : out AP_Targets;
                        OK       : out Boolean);

   procedure From_JSON (JSON_Str : String;
                        WP       : out Waypoint;
                        OK       : out Boolean);

   procedure From_JSON (JSON_Str  : String;
                        Plan      : out Flight_Plan;
                        OK        : out Boolean);

   procedure From_JSON (JSON_Str : String;
                        XPDR     : out Transponder_State;
                        OK       : out Boolean);

   --------------------------------------------------------------------------
   --  HELPERS
   --------------------------------------------------------------------------

   function Quote (S : String) return String;
   function ISO8601 (T : Ada.Calendar.Time) return String;
   function JSON_Bool (B : Boolean) return String;

end AeroSys.JSON;
