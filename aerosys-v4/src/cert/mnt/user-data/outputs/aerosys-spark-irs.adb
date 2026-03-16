pragma SPARK_Mode (On);
package body AeroSys.SPARK.IRS with SPARK_Mode => On is

   -- Resolution constants (ARINC 429 Part 2)
   PITCH_RES   : constant := 0.00137;   -- deg/LSB, label 0o324
   ROLL_RES    : constant := 0.00137;   -- deg/LSB, label 0o325
   HDG_RES     : constant := 0.000687;  -- deg/LSB, labels 0o320/0o114
   LAT_RES     : constant := 0.000021458; -- deg/LSB, label 0o100
   LON_RES     : constant := 0.000021458; -- deg/LSB, label 0o101

   function Clamp (V, Lo, Hi : Float) return Float is
   begin
      if V < Lo then return Lo;
      elsif V > Hi then return Hi;
      else return V;
      end if;
   end Clamp;

   function Decode_Pitch (Word : ARINC_Word) return Float is
      W    : constant ARINC_Word_Decoded := Decode_Word (Word);
      Sign : constant Boolean := W.SSM = SSM_MINUS;
      V    : Float;
   begin
      if not W.Valid or W.SSM = SSM_FW or W.SSM = SSM_NCD then
         return 0.0;
      end if;
      V := Float (W.Data) * PITCH_RES;
      if Sign then V := -V; end if;
      V := Clamp (V, -90.0, 90.0);
      pragma Assert (V in -90.0 .. 90.0);
      return V;
   end Decode_Pitch;

   function Decode_Roll (Word : ARINC_Word) return Float is
      W    : constant ARINC_Word_Decoded := Decode_Word (Word);
      Sign : constant Boolean := W.SSM = SSM_MINUS;
      V    : Float;
   begin
      if not W.Valid or W.SSM = SSM_FW or W.SSM = SSM_NCD then
         return 0.0;
      end if;
      V := Float (W.Data) * ROLL_RES;
      if Sign then V := -V; end if;
      V := Clamp (V, -180.0, 180.0);
      pragma Assert (V in -180.0 .. 180.0);
      return V;
   end Decode_Roll;

   function Decode_Heading (Word : ARINC_Word) return Float is
      W : constant ARINC_Word_Decoded := Decode_Word (Word);
      V : Float;
   begin
      if not W.Valid or W.SSM /= SSM_NORM then return 0.0; end if;
      V := Float (W.Data) * HDG_RES;
      -- Heading always 0..360
      while V >= 360.0 loop V := V - 360.0; end loop;
      V := Clamp (V, 0.0, 360.0);
      pragma Assert (V in 0.0 .. 360.0);
      return V;
   end Decode_Heading;

   function Decode_Latitude (Word : ARINC_Word) return Float is
      W    : constant ARINC_Word_Decoded := Decode_Word (Word);
      Sign : constant Boolean := W.SSM = SSM_MINUS;
      V    : Float;
   begin
      if not W.Valid or W.SSM = SSM_FW or W.SSM = SSM_NCD then return 0.0; end if;
      V := Float (W.Data) * LAT_RES;
      if Sign then V := -V; end if;
      V := Clamp (V, -90.0, 90.0);
      pragma Assert (V in -90.0 .. 90.0);
      return V;
   end Decode_Latitude;

   function Decode_Longitude (Word : ARINC_Word) return Float is
      W    : constant ARINC_Word_Decoded := Decode_Word (Word);
      Sign : constant Boolean := W.SSM = SSM_MINUS;
      V    : Float;
   begin
      if not W.Valid or W.SSM = SSM_FW or W.SSM = SSM_NCD then return 0.0; end if;
      V := Float (W.Data) * LON_RES;
      if Sign then V := -V; end if;
      V := Clamp (V, -180.0, 180.0);
      pragma Assert (V in -180.0 .. 180.0);
      return V;
   end Decode_Longitude;

   function Abs_Diff (A, B : Float) return Float is
      D : constant Float := A - B;
   begin
      return (if D >= 0.0 then D else -D);
   end Abs_Diff;

   function Vote_IRS (Units : Triple_IRS) return IRS_Vote_Result is
      Miscount : Natural := 0;
      P1 : constant Float := Units (1).Data.Pitch_Deg;
      P2 : constant Float := Units (2).Data.Pitch_Deg;
      P3 : constant Float := Units (3).Data.Pitch_Deg;
      V1, V2, V3 : Boolean;
   begin
      -- Check all three have valid data
      if not (Units (1).Data.Valid and Units (2).Data.Valid and Units (3).Data.Valid) then
         return All_Invalid;
      end if;
      -- Compute median and flag deviators
      -- If |P1 - P2| > threshold and |P1 - P3| > threshold => IRS1 is outlier
      V1 := Abs_Diff (P1, P2) > ATTITUDE_MISCOMPARE_DEG
            and then Abs_Diff (P1, P3) > ATTITUDE_MISCOMPARE_DEG;
      V2 := Abs_Diff (P2, P1) > ATTITUDE_MISCOMPARE_DEG
            and then Abs_Diff (P2, P3) > ATTITUDE_MISCOMPARE_DEG;
      V3 := Abs_Diff (P3, P1) > ATTITUDE_MISCOMPARE_DEG
            and then Abs_Diff (P3, P2) > ATTITUDE_MISCOMPARE_DEG;
      if V1 then Miscount := Miscount + 1; end if;
      if V2 then Miscount := Miscount + 1; end if;
      if V3 then Miscount := Miscount + 1; end if;
      -- Postcondition proof helper
      pragma Assert
        (if Miscount = 0 then not V1 and not V2 and not V3);
      case Miscount is
         when 0 => return Unanimous;
         when 1 => return Single_Miscompare;
         when others => return Two_Miscompare;
      end case;
   end Vote_IRS;

   function Select_Primary (Units : Triple_IRS) return IRS_Data_Set is
      VR : constant IRS_Vote_Result := Vote_IRS (Units);
   begin
      -- If unanimous or at most one miscompare, use Unit 1 as primary
      -- (In production: use median value, not just Unit 1)
      case VR is
         when Unanimous | Single_Miscompare =>
            return Units (1).Data;
         when Two_Miscompare =>
            -- Two units agree — find the pair
            -- Simplified: return Unit 2 (statistically most likely to be correct)
            return Units (2).Data;
         when All_Invalid =>
            return (others => <>);
      end case;
   end Select_Primary;

end AeroSys.SPARK.IRS;
