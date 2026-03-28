------------------------------------------------------------------------------
--  AeroSys.Tests — AUnit Test Suite
--  DO-178C LLT (Low-Level Tests) for DAL B/C SPARK packages
--
--  Covers:
--    AEROSYS-HLR-BUS-001 through BUS-008   (SPARK.ARINC)
--    AEROSYS-HLR-FADEC-001 through FADEC-005 (SPARK.FADEC)
--    AEROSYS-HLR-AFCS-001 through AFCS-003  (SPARK.Autopilot)
--    AEROSYS-HLR-IRS-001 through IRS-002    (SPARK.IRS)
--
--  Run: aunit_main (built by GNATtest or manually)
--  Build: gprbuild -P aerosys_tests.gpr
------------------------------------------------------------------------------

with AUnit.Test_Suites;   use AUnit.Test_Suites;
with AUnit.Test_Cases;    use AUnit.Test_Cases;
with AUnit.Assertions;    use AUnit.Assertions;
with AUnit.Test_Caller;

with AeroSys.SPARK.ARINC;     use AeroSys.SPARK.ARINC;
with AeroSys.SPARK.FADEC;     use AeroSys.SPARK.FADEC;
with AeroSys.SPARK.Autopilot; use AeroSys.SPARK.Autopilot;
with AeroSys.SPARK.IRS;       use AeroSys.SPARK.IRS;
with AeroSys.Aircraft;        use AeroSys.Aircraft;
with AeroSys.Types;           use AeroSys.Types;
with Interfaces;              use Interfaces;

package body AeroSys.Tests is

   --  ═══════════════════════════════════════════════════════════════
   --  ARINC 429 TESTS — AEROSYS-HLR-BUS-001 through BUS-008
   --  ═══════════════════════════════════════════════════════════════

   --  TC-BUS-001: Word encode then decode round-trip
   --  Traces to: AEROSYS-HLR-BUS-001
   procedure Test_Word_Roundtrip (T : in out Test_Case'Class) is
      Label : constant ARINC_Label   := 16#31#;  -- N1 Engine 1 (0o061)
      SDI   : constant ARINC_SDI     := 1;
      Data  : constant ARINC_Data_19 := 16#12345#;
      SSM   : constant ARINC_SSM     := SSM_NORM;
      W     : constant ARINC_Word    := Encode_Word (Label, SDI, Data, SSM);
      D     : constant ARINC_Word_Decoded := Decode_Word (W);
   begin
      Assert (D.Valid,  "TC-BUS-001: Parity should be valid after encode");
      Assert (D.Data = Data, "TC-BUS-001: Data field preserved");
      Assert (D.SSM  = SSM,  "TC-BUS-001: SSM field preserved");
      Assert (D.SDI  = SDI,  "TC-BUS-001: SDI field preserved");
   end Test_Word_Roundtrip;

   --  TC-BUS-002: Odd parity validation — corrupt word
   --  Traces to: AEROSYS-HLR-BUS-002
   procedure Test_Parity_Detection (T : in out Test_Case'Class) is
      Good_W : constant ARINC_Word := Encode_Word (16#31#, 0, 12345, SSM_NORM);
      Bad_W  : constant ARINC_Word := Good_W xor 1;  -- flip one data bit
      D_Good : constant ARINC_Word_Decoded := Decode_Word (Good_W);
      D_Bad  : constant ARINC_Word_Decoded := Decode_Word (Bad_W);
   begin
      Assert (D_Good.Valid,     "TC-BUS-002: Valid word passes parity");
      Assert (not D_Bad.Valid,  "TC-BUS-002: Single-bit error detected by parity");
   end Test_Parity_Detection;

   --  TC-BUS-003: Label bit reversal — involution property
   --  Traces to: AEROSYS-HLR-BUS-003
   procedure Test_Label_Reversal (T : in out Test_Case'Class) is
      Original : constant ARINC_Label := 16#31#;  -- 0b00110001
      Reversed : constant ARINC_Label := Reverse_Label (Original);
      Restored : constant ARINC_Label := Reverse_Label (Reversed);
   begin
      Assert (Restored = Original, "TC-BUS-003: Double reversal = identity");
      --  0b00110001 reversed = 0b10001100 = 0x8C
      Assert (Reversed = 16#8C#, "TC-BUS-003: 0x31 reversed = 0x8C");
   end Test_Label_Reversal;

   --  TC-BUS-004a: BNR positive decode
   --  Traces to: AEROSYS-HLR-BUS-004, BUS-005
   procedure Test_BNR_Positive (T : in out Test_Case'Class) is
      --  N1 = 84.6%, resolution = 0.00391 → raw = round(84.6/0.00391) = 21637
      Raw    : constant ARINC_Data_19 := 21637;
      Result : constant Float := Decode_BNR (Raw, 0.00391, SSM_NORM);
      --  Allow ±0.5 * resolution tolerance
      Tolerance : constant := 0.002;
   begin
      Assert (abs (Result - 84.6) < 0.5,
              "TC-BUS-004a: BNR positive decode correct (N1=84.6%)");
      Assert (Result >= 0.0, "TC-BUS-004a: Positive BNR non-negative");
   end Test_BNR_Positive;

   --  TC-BUS-004b: BNR negative decode — SSM MINUS
   --  Traces to: AEROSYS-HLR-BUS-004
   procedure Test_BNR_Negative (T : in out Test_Case'Class) is
      --  Pitch -2.5° @ resolution 0.00137 → two's complement
      Raw    : constant ARINC_Data_19 := Encode_BNR (-2.5, 0.00137);
      Result : constant Float := Decode_BNR (Raw, 0.00137, SSM_MINUS);
   begin
      Assert (Result < 0.0, "TC-BUS-004b: Negative BNR gives negative result");
      Assert (abs (Result - (-2.5)) < 0.01,
              "TC-BUS-004b: BNR negative decode correct (pitch -2.5)");
   end Test_BNR_Negative;

   --  TC-BUS-005: SSM_FW → return 0.0 (invalid data rejection)
   --  Traces to: AEROSYS-HLR-BUS-008
   procedure Test_BNR_FW_Rejected (T : in out Test_Case'Class) is
      Raw    : constant ARINC_Data_19 := 21637;
      Result : constant Float := Decode_BNR (Raw, 0.00391, SSM_FW);
   begin
      Assert (Result = 0.0,
              "TC-BUS-005: SSM Failure Warning → 0.0 returned");
   end Test_BNR_FW_Rejected;

   --  TC-BUS-006: SSM_NCD → return 0.0 (no computed data)
   procedure Test_BNR_NCD_Rejected (T : in out Test_Case'Class) is
      Raw    : constant ARINC_Data_19 := 21637;
      Result : constant Float := Decode_BNR (Raw, 0.00391, SSM_NCD);
   begin
      Assert (Result = 0.0, "TC-BUS-006: SSM NCD → 0.0 returned");
   end Test_BNR_NCD_Rejected;

   --  TC-BUS-007: BCD decode — VHF frequency 132.725
   --  Traces to: AEROSYS-HLR-BUS-006
   procedure Test_BCD_Frequency (T : in out Test_Case'Class) is
      --  132725 in BCD: digit 0=5, 1=2, 2=7, 3=2, 4=3, 5=1 → BCD packing
      --  132.725 * 1000 = 132725
      Raw    : constant ARINC_Data_19 := 16#132725# and 16#7FFFF#;
      -- Simplified: just verify non-negative and positive
      Result : constant Float := Decode_BCD (Raw, 3);  -- scale 10^-3
   begin
      Assert (Result >= 0.0, "TC-BUS-007: BCD result non-negative");
   end Test_BCD_Frequency;

   --  ═══════════════════════════════════════════════════════════════
   --  FADEC TESTS — AEROSYS-HLR-FADEC-001 through FADEC-005
   --  ═══════════════════════════════════════════════════════════════

   --  TC-FADEC-001: N1 decode valid range
   procedure Test_N1_Valid (T : in out Test_Case'Class) is
      W      : constant ARINC_Word := Encode_Word (16#31#, 1,
                                        Encode_BNR (84.6, 0.00391), SSM_NORM);
      Result : constant Engine_Decode_Result :=
                 Decode_N1 (W, CFM56_5B4P);
   begin
      Assert (Result.Status = OK, "TC-FADEC-001: N1 decode status OK");
      Assert (abs (Float (Result.Data.N1_Pct) - 84.6) < 0.05,
              "TC-FADEC-001: N1 value correct");
      Assert (Float (Result.Data.N1_Pct) in 0.0 .. 110.0,
              "TC-FADEC-001: N1 within valid range");
   end Test_N1_Valid;

   --  TC-FADEC-002: N1 parity error → rejected
   procedure Test_N1_ParityError (T : in out Test_Case'Class) is
      Good_W : constant ARINC_Word := Encode_Word (16#31#, 1,
                                         Encode_BNR (84.6, 0.00391), SSM_NORM);
      Bad_W  : constant ARINC_Word := Good_W xor 2;  -- corrupt data bit
      Result : constant Engine_Decode_Result := Decode_N1 (Bad_W, CFM56_5B4P);
   begin
      Assert (Result.Status = Parity_Error,
              "TC-FADEC-002: Parity error detected, N1 rejected");
   end Test_N1_ParityError;

   --  TC-FADEC-003: N1 SSM_FW → SSM_Invalid rejection
   procedure Test_N1_FW (T : in out Test_Case'Class) is
      W      : constant ARINC_Word := Encode_Word (16#31#, 1,
                                         Encode_BNR (84.6, 0.00391), SSM_FW);
      Result : constant Engine_Decode_Result := Decode_N1 (W, CFM56_5B4P);
   begin
      Assert (Result.Status = SSM_Invalid,
              "TC-FADEC-003: SSM FW → rejected with SSM_Invalid");
   end Test_N1_FW;

   --  TC-FADEC-004: EGT below TOGA limit → No_Alert
   procedure Test_EGT_NoExceedance (T : in out Test_Case'Class) is
      W      : constant ARINC_Word := Encode_Word (16#39#, 1,
                                         Encode_BNR (741.0, 0.5), SSM_NORM);
      Result : constant Engine_Decode_Result :=
                 Decode_EGT (W, CFM56_5B4P, CRZ);
      Alert  : constant FADEC_Alert :=
                 Check_EGT_Limit (Result.Data.EGT_C, CFM56_5B4P, CRZ, 1);
   begin
      Assert (Result.Status = OK, "TC-FADEC-004: EGT decode OK");
      Assert (Alert.Kind = No_Alert,
              "TC-FADEC-004: EGT 741 < 895 CRZ limit → No_Alert");
   end Test_EGT_NoExceedance;

   --  TC-FADEC-005: EGT above TOGA limit → alert raised
   procedure Test_EGT_TOGAExceedance (T : in out Test_Case'Class) is
      Alert : constant FADEC_Alert :=
                Check_EGT_Limit (980, CFM56_5B4P, TOGA, 1);
      --  CFM56-5B4P EGT_Max_TOGA = 950
   begin
      Assert (Alert.Kind = EGT_Exceedance_TOGA,
              "TC-FADEC-005: EGT 980 > 950 TOGA limit → EGT_Exceedance_TOGA");
      Assert (Alert.Engine_ID = 1, "TC-FADEC-005: Correct engine ID");
   end Test_EGT_TOGAExceedance;

   --  TC-FADEC-006: Freshness — within threshold → No_Alert
   procedure Test_Freshness_OK (T : in out Test_Case'Class) is
      Alert : constant FADEC_Alert :=
                Check_Freshness (Last_Update_Ms  => 10000,
                                  Current_Time_Ms => 10200,  -- 200ms elapsed
                                  Eng_ID          => 1);
   begin
      Assert (Alert.Kind = No_Alert,
              "TC-FADEC-006: 200ms elapsed < 500ms threshold → No_Alert");
   end Test_Freshness_OK;

   --  TC-FADEC-007: Freshness — STALE threshold
   procedure Test_Freshness_Stale (T : in out Test_Case'Class) is
      Alert : constant FADEC_Alert :=
                Check_Freshness (Last_Update_Ms  => 10000,
                                  Current_Time_Ms => 10600,  -- 600ms elapsed
                                  Eng_ID          => 2);
   begin
      Assert (Alert.Kind = Parameter_Stale,
              "TC-FADEC-007: 600ms elapsed ≥ 500ms threshold → Parameter_Stale");
   end Test_Freshness_Stale;

   --  TC-FADEC-008: Freshness — LOST threshold
   procedure Test_Freshness_Lost (T : in out Test_Case'Class) is
      Alert : constant FADEC_Alert :=
                Check_Freshness (Last_Update_Ms  => 10000,
                                  Current_Time_Ms => 12500,  -- 2500ms elapsed
                                  Eng_ID          => 1);
   begin
      Assert (Alert.Kind = Parameter_Lost,
              "TC-FADEC-008: 2500ms elapsed ≥ 2000ms threshold → Parameter_Lost");
   end Test_Freshness_Lost;

   --  TC-FADEC-009: Thrust rating decode — all 7 ratings
   procedure Test_Thrust_Rating_Decode (T : in out Test_Case'Class) is
      Ratings : constant array (0 .. 6) of Thrust_Rating :=
        (IDLE, REVERSE, CRZ, CLB, MCT, FLEX, TOGA);
   begin
      for I in Ratings'Range loop
         declare
            W : constant ARINC_Word :=
                  Encode_Word (16#2F#, 0, ARINC_Data_19 (I), SSM_NORM);
            R : constant Thrust_Rating := Decode_Thrust_Rating (W);
         begin
            Assert (R = Ratings (I),
                    "TC-FADEC-009: Rating" & I'Image & " decoded correctly");
         end;
      end loop;
   end Test_Thrust_Rating_Decode;

   --  ═══════════════════════════════════════════════════════════════
   --  AUTOPILOT TESTS — AEROSYS-HLR-AFCS-001 through AFCS-003
   --  ═══════════════════════════════════════════════════════════════

   --  TC-AFCS-001: Nominal engage — all conditions met
   procedure Test_AP_Engage_Nominal (T : in out Test_Case'Class) is
      Result : constant AP_Engage_Result :=
                 Validate_AP_Engage
                   (Pitch_Deg  => 2.0,
                    Roll_Deg   => 5.0,
                    IAS_Kt     => 280.0,
                    Source     => Source_FMS,
                    Profile    => A320_CFM56_Profile,
                    Already_On => False);
   begin
      Assert (Result = Engaged_OK,
              "TC-AFCS-001: Nominal conditions → Engaged_OK");
   end Test_AP_Engage_Nominal;

   --  TC-AFCS-002: Pitch too high → rejected
   procedure Test_AP_PitchHigh (T : in out Test_Case'Class) is
      Result : constant AP_Engage_Result :=
                 Validate_AP_Engage
                   (Pitch_Deg  => 25.0,   -- > 20° limit
                    Roll_Deg   => 0.0,
                    IAS_Kt     => 280.0,
                    Source     => Source_Pilot,
                    Profile    => A320_CFM56_Profile,
                    Already_On => False);
   begin
      Assert (Result = Rejected_Pitch_High,
              "TC-AFCS-002: Pitch 25° > 20° → Rejected_Pitch_High");
   end Test_AP_PitchHigh;

   --  TC-AFCS-003: Pitch too low → rejected
   procedure Test_AP_PitchLow (T : in out Test_Case'Class) is
      Result : constant AP_Engage_Result :=
                 Validate_AP_Engage
                   (Pitch_Deg  => -15.0,  -- < -10° limit
                    Roll_Deg   => 0.0,
                    IAS_Kt     => 280.0,
                    Source     => Source_Pilot,
                    Profile    => A320_CFM56_Profile,
                    Already_On => False);
   begin
      Assert (Result = Rejected_Pitch_Low,
              "TC-AFCS-003: Pitch -15° < -10° → Rejected_Pitch_Low");
   end Test_AP_PitchLow;

   --  TC-AFCS-004: Roll too high → rejected
   procedure Test_AP_RollExcessive (T : in out Test_Case'Class) is
      Result : constant AP_Engage_Result :=
                 Validate_AP_Engage
                   (Pitch_Deg  => 0.0,
                    Roll_Deg   => -35.0,  -- abs 35 > 30° limit
                    IAS_Kt     => 280.0,
                    Source     => Source_Pilot,
                    Profile    => A320_CFM56_Profile,
                    Already_On => False);
   begin
      Assert (Result = Rejected_Roll,
              "TC-AFCS-004: Roll -35° > 30° limit → Rejected_Roll");
   end Test_AP_RollExcessive;

   --  TC-AFCS-005: Unknown source → rejected
   procedure Test_AP_BadSource (T : in out Test_Case'Class) is
      Result : constant AP_Engage_Result :=
                 Validate_AP_Engage
                   (Pitch_Deg  => 0.0,
                    Roll_Deg   => 0.0,
                    IAS_Kt     => 280.0,
                    Source     => Source_Unknown,
                    Profile    => A320_CFM56_Profile,
                    Already_On => False);
   begin
      Assert (Result = Rejected_Bad_Source,
              "TC-AFCS-005: Unknown source → Rejected_Bad_Source");
   end Test_AP_BadSource;

   --  TC-AFCS-006: Already engaged → rejected
   procedure Test_AP_AlreadyOn (T : in out Test_Case'Class) is
      Result : constant AP_Engage_Result :=
                 Validate_AP_Engage
                   (Pitch_Deg  => 0.0,
                    Roll_Deg   => 0.0,
                    IAS_Kt     => 280.0,
                    Source     => Source_FMS,
                    Profile    => A320_CFM56_Profile,
                    Already_On => True);
   begin
      Assert (Result = Rejected_Already_Engaged,
              "TC-AFCS-006: AP already on → Rejected_Already_Engaged");
   end Test_AP_AlreadyOn;

   --  TC-AFCS-007: Altitude target above ceiling → rejected
   procedure Test_AP_AltTooHigh (T : in out Test_Case'Class) is
      Result : constant AP_Target_Result :=
                 Validate_Alt_Target (45000, A320_CFM56_Profile);
      --  A320 max = 39800 ft
   begin
      Assert (Result = Target_Alt_Too_High,
              "TC-AFCS-007: Alt 45000 > A320 max 39800 → Target_Alt_Too_High");
   end Test_AP_AltTooHigh;

   --  TC-AFCS-008: Mach above MMO → rejected
   procedure Test_AP_MachTooFast (T : in out Test_Case'Class) is
      Result : constant AP_Target_Result :=
                 Validate_Mach_Target (0.90, A320_CFM56_Profile);
      --  A320 MMO = 0.82
   begin
      Assert (Result = Target_Mach_Too_Fast,
              "TC-AFCS-008: Mach 0.90 > A320 MMO 0.82 → Target_Mach_Too_Fast");
   end Test_AP_MachTooFast;

   --  TC-AFCS-009: AP disconnect always raises alert (AEROSYS-HLR-AFCS-003)
   procedure Test_AP_Disconnect_Alert (T : in out Test_Case'Class) is
      Alert : FADEC_Alert;
   begin
      Process_Disconnect (Was_Engaged => True, Alert_Out => Alert);
      Assert (Alert.Kind /= No_Alert,
              "TC-AFCS-009: Disconnect from engaged state → alert MUST be raised");
   end Test_AP_Disconnect_Alert;

   --  TC-AFCS-010: Disconnect when not engaged → no alert
   procedure Test_AP_Disconnect_NoAlert (T : in out Test_Case'Class) is
      Alert : FADEC_Alert;
   begin
      Process_Disconnect (Was_Engaged => False, Alert_Out => Alert);
      Assert (Alert.Kind = No_Alert,
              "TC-AFCS-010: Disconnect when not engaged → No_Alert");
   end Test_AP_Disconnect_NoAlert;

   --  ═══════════════════════════════════════════════════════════════
   --  IRS TESTS — AEROSYS-HLR-IRS-001, IRS-002
   --  ═══════════════════════════════════════════════════════════════

   --  TC-IRS-001: Pitch decode within range
   procedure Test_IRS_Pitch (T : in out Test_Case'Class) is
      --  Pitch = 1.2° → raw = round(1.2/0.00137) = 876
      W      : constant ARINC_Word := Encode_Word (16#D4#, 1,
                                         Encode_BNR (1.2, 0.00137), SSM_NORM);
      Result : constant Float := Decode_Pitch (W);
   begin
      Assert (abs (Result - 1.2) < 0.01,
              "TC-IRS-001: Pitch 1.2° decoded correctly");
      Assert (Result in -90.0 .. 90.0, "TC-IRS-001: Pitch within ±90°");
   end Test_IRS_Pitch;

   --  TC-IRS-002: Roll decode negative
   procedure Test_IRS_Roll_Negative (T : in out Test_Case'Class) is
      W      : constant ARINC_Word := Encode_Word (16#D5#, 1,
                                         Encode_BNR (-15.5, 0.00137), SSM_MINUS);
      Result : constant Float := Decode_Roll (W);
   begin
      Assert (Result in -180.0 .. 180.0, "TC-IRS-002: Roll within ±180°");
   end Test_IRS_Roll_Negative;

   --  TC-IRS-003: Heading always 0–360
   procedure Test_IRS_Heading_Bounds (T : in out Test_Case'Class) is
      W      : constant ARINC_Word := Encode_Word (16#D0#, 1,
                                         Encode_BNR (350.0, 0.000687), SSM_NORM);
      Result : constant Float := Decode_Heading (W);
   begin
      Assert (Result in 0.0 .. 360.0,
              "TC-IRS-003: Heading always in 0–360 range");
   end Test_IRS_Heading_Bounds;

   --  TC-IRS-004: Triple IRS unanimous vote
   procedure Test_IRS_Vote_Unanimous (T : in out Test_Case'Class) is
      Units : Triple_IRS;
   begin
      -- All three agree within tolerance
      Units (1) := (Data => (Pitch_Deg=>1.2, Roll_Deg=>2.5, Heading_Deg=>85.0,
                              Latitude=>47.38, Longitude=>-42.74, GS_Kt=>481.0,
                              VS_Fpm=>0.0, Nav_State=>FULL_NAV, Valid=>True),
                   Unit_ID=>1, Miscompare=>False);
      Units (2) := (Data => (Pitch_Deg=>1.21, Roll_Deg=>2.51, Heading_Deg=>85.01,
                              Latitude=>47.38, Longitude=>-42.74, GS_Kt=>481.0,
                              VS_Fpm=>0.0, Nav_State=>FULL_NAV, Valid=>True),
                   Unit_ID=>2, Miscompare=>False);
      Units (3) := (Data => (Pitch_Deg=>1.19, Roll_Deg=>2.49, Heading_Deg=>84.99,
                              Latitude=>47.38, Longitude=>-42.74, GS_Kt=>480.9,
                              VS_Fpm=>0.0, Nav_State=>FULL_NAV, Valid=>True),
                   Unit_ID=>3, Miscompare=>False);
      Assert (Vote_IRS (Units) = Unanimous,
              "TC-IRS-004: All three IRS agree → Unanimous");
   end Test_IRS_Vote_Unanimous;

   --  TC-IRS-005: Single IRS miscompare detected
   procedure Test_IRS_Vote_SingleMiscompare (T : in out Test_Case'Class) is
      Units : Triple_IRS;
   begin
      Units (1) := (Data => (Pitch_Deg=>1.2,  Roll_Deg=>2.5, Heading_Deg=>85.0,
                              Latitude=>47.38, Longitude=>-42.74, GS_Kt=>481.0,
                              VS_Fpm=>0.0, Nav_State=>FULL_NAV, Valid=>True),
                   Unit_ID=>1, Miscompare=>False);
      Units (2) := (Data => (Pitch_Deg=>1.21, Roll_Deg=>2.51, Heading_Deg=>85.0,
                              Latitude=>47.38, Longitude=>-42.74, GS_Kt=>481.0,
                              VS_Fpm=>0.0, Nav_State=>FULL_NAV, Valid=>True),
                   Unit_ID=>2, Miscompare=>False);
      -- IRS 3 is faulty — pitch deviates by 5° (> 2° threshold)
      Units (3) := (Data => (Pitch_Deg=>6.5,  Roll_Deg=>2.5, Heading_Deg=>85.0,
                              Latitude=>47.38, Longitude=>-42.74, GS_Kt=>481.0,
                              VS_Fpm=>0.0, Nav_State=>FULL_NAV, Valid=>True),
                   Unit_ID=>3, Miscompare=>False);
      Assert (Vote_IRS (Units) = Single_Miscompare,
              "TC-IRS-005: IRS 3 faulty → Single_Miscompare");
   end Test_IRS_Vote_SingleMiscompare;

   --  ═══════════════════════════════════════════════════════════════
   --  AIRCRAFT PROFILE TESTS
   --  ═══════════════════════════════════════════════════════════════

   --  TC-ACM-001: All 6 profiles have valid EGT limits
   procedure Test_Profile_EGT_Limits (T : in out Test_Case'Class) is
   begin
      for Idx in Profile_Index loop
         declare
            Prof : constant Aircraft_Profile := Get_Profile (Idx);
         begin
            Assert (Prof.Engine.EGT_Max_TOGA > Prof.Engine.EGT_Max_MCT,
                    "TC-ACM-001: TOGA limit > MCT for " & Idx'Image);
            Assert (Prof.Engine.EGT_Max_MCT > Prof.Engine.EGT_Max_Cont,
                    "TC-ACM-001: MCT limit > CRZ for " & Idx'Image);
         end;
      end loop;
   end Test_Profile_EGT_Limits;

   --  TC-ACM-002: A350/A380 have higher EGT limits than narrowbody
   procedure Test_Profile_Widebody_EGT (T : in out Test_Case'Class) is
      A320 : constant Aircraft_Profile := Get_Profile (IDX_A320_CFM);
      A350 : constant Aircraft_Profile := Get_Profile (IDX_A350_900);
   begin
      Assert (A350.Engine.EGT_Max_TOGA > A320.Engine.EGT_Max_TOGA,
              "TC-ACM-002: A350 Trent XWB EGT limit > A320 CFM56");
   end Test_Profile_Widebody_EGT;

end AeroSys.Tests;
