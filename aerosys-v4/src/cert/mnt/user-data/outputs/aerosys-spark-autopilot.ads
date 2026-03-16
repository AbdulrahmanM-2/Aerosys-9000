------------------------------------------------------------------------------
--  AeroSys.SPARK.Autopilot — SPARK 2014 Autopilot Engagement Logic
--
--  DO-178C DAL B — Formal verification with GNATprove
--  Satisfies: AEROSYS-HLR-AFCS-001 through AFCS-003
--
--  This package proves:
--    1. AP engagement only occurs within safe attitude envelope
--    2. All target values are range-checked against aircraft profile
--    3. AP disconnect always raises an alert
--    4. No runtime errors (ATC mode proof)
------------------------------------------------------------------------------

pragma SPARK_Mode (On);

with AeroSys.Types;         use AeroSys.Types;
with AeroSys.SPARK.FADEC;   use AeroSys.SPARK.FADEC;
with AeroSys.Aircraft;      use AeroSys.Aircraft;

package AeroSys.SPARK.Autopilot
  with SPARK_Mode => On
is

   --  ═══════════════════════════════════════════════════════════════
   --  TYPES
   --  ═══════════════════════════════════════════════════════════════

   type AP_Engage_Source is
     (Source_Pilot, Source_Copilot, Source_FMS, Source_Ground, Source_Unknown);

   type AP_Engage_Result is
     (Engaged_OK,
      Rejected_Pitch_High,
      Rejected_Pitch_Low,
      Rejected_Roll,
      Rejected_Speed_Low,
      Rejected_Speed_High,
      Rejected_Bad_Source,
      Rejected_Already_Engaged);

   type AP_Target_Result is
     (Target_OK,
      Target_Alt_Too_High,
      Target_Alt_Negative,
      Target_Mach_Too_Fast,
      Target_Mach_Too_Slow,
      Target_VS_Too_High,
      Target_VS_Too_Low,
      Target_Heading_Range);

   --  Engagement limits (AEROSYS-HLR-AFCS-001)
   AP_MAX_PITCH_ENGAGE_DEG : constant := 20.0;
   AP_MIN_PITCH_ENGAGE_DEG : constant := -10.0;
   AP_MAX_ROLL_ENGAGE_DEG  : constant := 30.0;
   AP_MARGIN_KNOTS         : constant := 10.0;

   --  ═══════════════════════════════════════════════════════════════
   --  ENGAGE VALIDATION — AEROSYS-HLR-AFCS-001
   --  ═══════════════════════════════════════════════════════════════

   --  Validate conditions for autopilot engagement.
   --  Proves: if result = Engaged_OK then all envelope conditions hold.
   function Validate_AP_Engage
     (Pitch_Deg   : Pitch_Deg;
      Roll_Deg    : Roll_Deg;
      IAS_Kt      : Speed_Kts;
      Source      : AP_Engage_Source;
      Profile     : Aircraft_Profile;
      Already_On  : Boolean)
      return AP_Engage_Result
   with
     SPARK_Mode => On,
     Global     => null,
     Depends    => (Validate_AP_Engage'Result =>
                      (Pitch_Deg, Roll_Deg, IAS_Kt, Source, Profile, Already_On)),
     Post       =>
       --  If OK, all conditions provably held
       (if Validate_AP_Engage'Result = Engaged_OK then
           Float (Pitch_Deg) in
             AP_MIN_PITCH_ENGAGE_DEG .. AP_MAX_PITCH_ENGAGE_DEG
           and then abs Float (Roll_Deg) <= AP_MAX_ROLL_ENGAGE_DEG
           and then Source /= Source_Unknown
           and then not Already_On)
       --  Specific rejection reasons map to specific failed conditions
       and then (if Validate_AP_Engage'Result = Rejected_Pitch_High then
                    Float (Pitch_Deg) > AP_MAX_PITCH_ENGAGE_DEG)
       and then (if Validate_AP_Engage'Result = Rejected_Pitch_Low then
                    Float (Pitch_Deg) < AP_MIN_PITCH_ENGAGE_DEG)
       and then (if Validate_AP_Engage'Result = Rejected_Roll then
                    abs Float (Roll_Deg) > AP_MAX_ROLL_ENGAGE_DEG)
       and then (if Validate_AP_Engage'Result = Rejected_Bad_Source then
                    Source = Source_Unknown)
       and then (if Validate_AP_Engage'Result = Rejected_Already_Engaged then
                    Already_On);

   --  ═══════════════════════════════════════════════════════════════
   --  TARGET VALIDATION — AEROSYS-HLR-AFCS-002
   --  ═══════════════════════════════════════════════════════════════

   --  Validate altitude target against aircraft profile.
   function Validate_Alt_Target
     (Target_Alt_Ft : Integer;
      Profile       : Aircraft_Profile)
      return AP_Target_Result
   with
     SPARK_Mode => On,
     Global     => null,
     Depends    => (Validate_Alt_Target'Result => (Target_Alt_Ft, Profile)),
     Post       =>
       (if Validate_Alt_Target'Result = Target_OK then
           Target_Alt_Ft in 0 .. Profile.Max_Altitude_Ft)
       and then (if Validate_Alt_Target'Result = Target_Alt_Too_High then
                    Target_Alt_Ft > Profile.Max_Altitude_Ft)
       and then (if Validate_Alt_Target'Result = Target_Alt_Negative then
                    Target_Alt_Ft < 0);

   --  Validate Mach target
   function Validate_Mach_Target
     (Target_Mach : Float;
      Profile     : Aircraft_Profile)
      return AP_Target_Result
   with
     SPARK_Mode => On,
     Global     => null,
     Depends    => (Validate_Mach_Target'Result => (Target_Mach, Profile)),
     Post       =>
       (if Validate_Mach_Target'Result = Target_OK then
           Target_Mach in 0.10 .. Float (Profile.M_MO))
       and then (if Validate_Mach_Target'Result = Target_Mach_Too_Fast then
                    Target_Mach > Float (Profile.M_MO))
       and then (if Validate_Mach_Target'Result = Target_Mach_Too_Slow then
                    Target_Mach < 0.10);

   --  Validate V/S target
   function Validate_VS_Target (Target_VS_Fpm : Integer) return AP_Target_Result
   with
     SPARK_Mode => On,
     Global     => null,
     Depends    => (Validate_VS_Target'Result => Target_VS_Fpm),
     Post       =>
       (if Validate_VS_Target'Result = Target_OK then
           Target_VS_Fpm in -8000 .. 8000)
       and then (if Validate_VS_Target'Result = Target_VS_Too_High then
                    Target_VS_Fpm > 8000)
       and then (if Validate_VS_Target'Result = Target_VS_Too_Low then
                    Target_VS_Fpm < -8000);

   --  ═══════════════════════════════════════════════════════════════
   --  DISCONNECT — AEROSYS-HLR-AFCS-003
   --  ═══════════════════════════════════════════════════════════════

   --  Process autopilot disconnect.
   --  Proves: alert is ALWAYS raised when AP transitions engaged→disengaged.
   procedure Process_Disconnect
     (Was_Engaged : Boolean;
      Alert_Out   : out FADEC_Alert)
   with
     SPARK_Mode => On,
     Global     => null,
     Depends    => (Alert_Out => Was_Engaged),
     Post       =>
       --  AEROSYS-HLR-AFCS-003: disconnect ALWAYS raises alert
       (if Was_Engaged then
           Alert_Out.Kind /= No_Alert);

end AeroSys.SPARK.Autopilot;
