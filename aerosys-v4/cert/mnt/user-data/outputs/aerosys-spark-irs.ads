------------------------------------------------------------------------------
--  AeroSys.SPARK.IRS — SPARK 2014 IRS Bus Interface (DAL C)
--  Satisfies: AEROSYS-HLR-IRS-001 through IRS-004
------------------------------------------------------------------------------

pragma SPARK_Mode (On);
with AeroSys.Types;        use AeroSys.Types;
with AeroSys.SPARK.ARINC;  use AeroSys.SPARK.ARINC;

package AeroSys.SPARK.IRS
  with SPARK_Mode => On
is
   --  IRS state enumeration (AEROSYS-HLR-IRS-004)
   type IRS_Nav_State is (OFF, ALIGN, ATT_ONLY, FULL_NAV, FAULT);

   type IRS_Data_Set is record
      Pitch_Deg   : Float   := 0.0;
      Roll_Deg    : Float   := 0.0;
      Heading_Deg : Float   := 0.0;
      Latitude    : Float   := 0.0;
      Longitude   : Float   := 0.0;
      GS_Kt       : Float   := 0.0;
      VS_Fpm      : Float   := 0.0;
      Nav_State   : IRS_Nav_State := OFF;
      Valid       : Boolean := False;
   end record;

   --  Per-IRS channel state (3 units)
   type IRS_Unit_Index is range 1 .. 3;
   type IRS_Unit_State is record
      Data      : IRS_Data_Set;
      Unit_ID   : IRS_Unit_Index := 1;
      Miscompare: Boolean := False;
   end record;
   type Triple_IRS is array (IRS_Unit_Index) of IRS_Unit_State;

   type IRS_Vote_Result is (Unanimous, Single_Miscompare, Two_Miscompare, All_Invalid);

   --  Comparison thresholds (AEROSYS-HLR-IRS-002)
   ATTITUDE_MISCOMPARE_DEG : constant := 2.0;
   HEADING_MISCOMPARE_DEG  : constant := 0.1;

   --  Decode attitude from IRS ARINC 429 bus word
   --  AEROSYS-HLR-IRS-001
   function Decode_Pitch
     (Word : ARINC_Word) return Float
   with
     SPARK_Mode => On, Global => null, Depends => (Decode_Pitch'Result => Word),
     Post => (if Check_Parity (Word) and
                  ((Shift_Right (Word, 29) and 3) = SSM_NORM or
                   (Shift_Right (Word, 29) and 3) = SSM_MINUS)
              then Decode_Pitch'Result in -90.0 .. 90.0);

   function Decode_Roll
     (Word : ARINC_Word) return Float
   with
     SPARK_Mode => On, Global => null, Depends => (Decode_Roll'Result => Word),
     Post => Decode_Roll'Result in -180.0 .. 180.0;

   function Decode_Heading
     (Word : ARINC_Word) return Float
   with
     SPARK_Mode => On, Global => null, Depends => (Decode_Heading'Result => Word),
     Post => Decode_Heading'Result in 0.0 .. 360.0;

   function Decode_Latitude
     (Word : ARINC_Word) return Float
   with
     SPARK_Mode => On, Global => null, Depends => (Decode_Latitude'Result => Word),
     Post => Decode_Latitude'Result in -90.0 .. 90.0;

   function Decode_Longitude
     (Word : ARINC_Word) return Float
   with
     SPARK_Mode => On, Global => null, Depends => (Decode_Longitude'Result => Word),
     Post => Decode_Longitude'Result in -180.0 .. 180.0;

   --  IRS voting and comparison (AEROSYS-HLR-IRS-002)
   --  Proves: if result = Unanimous, no unit is flagged as miscompare
   function Vote_IRS
     (Units : Triple_IRS) return IRS_Vote_Result
   with
     SPARK_Mode => On, Global => null, Depends => (Vote_IRS'Result => Units),
     Post =>
       (if Vote_IRS'Result = Unanimous then
           not Units (1).Miscompare
           and not Units (2).Miscompare
           and not Units (3).Miscompare);

   --  Select primary IRS source (median voter)
   function Select_Primary (Units : Triple_IRS) return IRS_Data_Set
   with
     SPARK_Mode => On, Global => null, Depends => (Select_Primary'Result => Units),
     Post => (if Select_Primary'Result.Valid then
                Select_Primary'Result.Pitch_Deg in -90.0 .. 90.0
                and Select_Primary'Result.Roll_Deg in -180.0 .. 180.0
                and Select_Primary'Result.Heading_Deg in 0.0 .. 360.0);

end AeroSys.SPARK.IRS;
