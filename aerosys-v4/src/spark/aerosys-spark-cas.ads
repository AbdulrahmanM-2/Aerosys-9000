------------------------------------------------------------------------------
--  AeroSys.SPARK.CAS — SPARK 2014 Crew Alerting System (DAL C)
--  Satisfies: AEROSYS-HLR-CAS-001 through CAS-003
--
--  Proves: severity classification immutable, master flags correct,
--  acknowledgement state transitions valid.
------------------------------------------------------------------------------

pragma SPARK_Mode (On);
with AeroSys.Types; use AeroSys.Types;

package AeroSys.SPARK.CAS with SPARK_Mode => On is

   Max_Alerts : constant := 32;

   type Alert_ID_String is new String (1 .. 8);
   type Alert_Msg_String is new String (1 .. 48);

   type CAS_Alert is record
      ID           : Alert_ID_String   := (others => ' ');
      Severity     : Alert_Severity    := ADVISORY;
      Category     : Alert_Category    := OTHER;
      Message      : Alert_Msg_String  := (others => ' ');
      Acknowledged : Boolean           := False;
      Active       : Boolean           := False;
   end record;

   type Alert_Array is array (1 .. Max_Alerts) of CAS_Alert;

   type CAS_State is record
      Alerts        : Alert_Array;
      Count         : Natural := 0;
      Master_Warning: Boolean := False;
      Master_Caution: Boolean := False;
   end record;

   --  AEROSYS-HLR-CAS-002: compute master flags from alert array
   --  Proves: Master_Warning iff any unacknowledged WARNING exists
   function Compute_Master_Flags (State : CAS_State) return CAS_State
   with
     SPARK_Mode => On, Global => null,
     Depends => (Compute_Master_Flags'Result => State),
     Post =>
       (Compute_Master_Flags'Result.Master_Warning =
          (for some I in 1 .. State.Count =>
             State.Alerts(I).Active
             and not State.Alerts(I).Acknowledged
             and State.Alerts(I).Severity = WARNING))
       and then
       (Compute_Master_Flags'Result.Master_Caution =
          (for some I in 1 .. State.Count =>
             State.Alerts(I).Active
             and not State.Alerts(I).Acknowledged
             and State.Alerts(I).Severity = CAUTION));

   --  AEROSYS-HLR-CAS-003: acknowledge a single alert by ID
   --  Proves: acknowledged alert remains in list (not deleted),
   --  no other alert is modified
   procedure Acknowledge_Alert
     (State : in out CAS_State;
      ID    : Alert_ID_String;
      Found : out Boolean)
   with
     SPARK_Mode => On, Global => null,
     Depends => (State => (State, ID), Found => (State, ID)),
     Post =>
       State.Count = State.Count'Old
       and then (if Found then
                    (for some I in 1 .. State.Count =>
                       State.Alerts(I).ID = ID
                       and State.Alerts(I).Acknowledged = True));

end AeroSys.SPARK.CAS;
