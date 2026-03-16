------------------------------------------------------------------------------
--  AeroSys.SPARK.Autopilot — Body
------------------------------------------------------------------------------

pragma SPARK_Mode (On);

package body AeroSys.SPARK.Autopilot
  with SPARK_Mode => On
is

   function Validate_AP_Engage
     (Pitch_Deg   : Pitch_Deg;
      Roll_Deg    : Roll_Deg;
      IAS_Kt      : Speed_Kts;
      Source      : AP_Engage_Source;
      Profile     : Aircraft_Profile;
      Already_On  : Boolean)
      return AP_Engage_Result
   is
      V_S1G_Kt : constant Float := Float (Profile.V_S1G);
      V_MO_Kt  : constant Float := Float (Profile.V_MO);
      IAS_F    : constant Float := Float (IAS_Kt);
   begin
      if Already_On then
         return Rejected_Already_Engaged;
      end if;

      if Source = Source_Unknown then
         return Rejected_Bad_Source;
      end if;

      if Float (Pitch_Deg) > AP_MAX_PITCH_ENGAGE_DEG then
         return Rejected_Pitch_High;
      end if;

      if Float (Pitch_Deg) < AP_MIN_PITCH_ENGAGE_DEG then
         return Rejected_Pitch_Low;
      end if;

      if abs Float (Roll_Deg) > AP_MAX_ROLL_ENGAGE_DEG then
         return Rejected_Roll;
      end if;

      if IAS_F < V_S1G_Kt * 1.3 then
         return Rejected_Speed_Low;
      end if;

      if IAS_F > V_MO_Kt - AP_MARGIN_KNOTS then
         return Rejected_Speed_High;
      end if;

      --  Proof assertions — all conditions satisfied
      pragma Assert (Float (Pitch_Deg) in AP_MIN_PITCH_ENGAGE_DEG .. AP_MAX_PITCH_ENGAGE_DEG);
      pragma Assert (abs Float (Roll_Deg) <= AP_MAX_ROLL_ENGAGE_DEG);
      pragma Assert (Source /= Source_Unknown);
      pragma Assert (not Already_On);

      return Engaged_OK;
   end Validate_AP_Engage;

   function Validate_Alt_Target
     (Target_Alt_Ft : Integer;
      Profile       : Aircraft_Profile)
      return AP_Target_Result
   is
   begin
      if Target_Alt_Ft < 0 then
         return Target_Alt_Negative;
      end if;
      if Target_Alt_Ft > Profile.Max_Altitude_Ft then
         return Target_Alt_Too_High;
      end if;
      pragma Assert (Target_Alt_Ft in 0 .. Profile.Max_Altitude_Ft);
      return Target_OK;
   end Validate_Alt_Target;

   function Validate_Mach_Target
     (Target_Mach : Float;
      Profile     : Aircraft_Profile)
      return AP_Target_Result
   is
   begin
      if Target_Mach < 0.10 then
         return Target_Mach_Too_Slow;
      end if;
      if Target_Mach > Float (Profile.M_MO) then
         return Target_Mach_Too_Fast;
      end if;
      pragma Assert (Target_Mach in 0.10 .. Float (Profile.M_MO));
      return Target_OK;
   end Validate_Mach_Target;

   function Validate_VS_Target (Target_VS_Fpm : Integer) return AP_Target_Result is
   begin
      if Target_VS_Fpm > 8000 then return Target_VS_Too_High; end if;
      if Target_VS_Fpm < -8000 then return Target_VS_Too_Low; end if;
      pragma Assert (Target_VS_Fpm in -8000 .. 8000);
      return Target_OK;
   end Validate_VS_Target;

   procedure Process_Disconnect
     (Was_Engaged : Boolean;
      Alert_Out   : out FADEC_Alert)
   is
   begin
      if Was_Engaged then
         --  AEROSYS-HLR-AFCS-003: MUST raise alert unconditionally
         Alert_Out := (Kind      => FADEC_Fault_Detected,
                       Engine_ID => 1,
                       Value     => 0.0,
                       Limit     => 0.0);
         --  Note: using FADEC_Fault_Detected as a proxy for AP_Disconnect
         --  In full implementation this would be a separate Alert type.
         pragma Assert (Alert_Out.Kind /= No_Alert);
      else
         Alert_Out := (Kind => No_Alert, Engine_ID => 1,
                       Value => 0.0, Limit => 0.0);
      end if;
   end Process_Disconnect;

end AeroSys.SPARK.Autopilot;
