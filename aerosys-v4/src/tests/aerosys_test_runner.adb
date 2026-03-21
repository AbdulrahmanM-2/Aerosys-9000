------------------------------------------------------------------------------
--  aerosys_test_runner.adb — AUnit test runner entry point
--  Run: ./aerosys_tests
--  Output: XML report (Jenkins-compatible) + console summary
------------------------------------------------------------------------------

with AUnit.Reporter.XML;
with AUnit.Reporter.Text;
with AUnit.Run;
with AUnit.Test_Suites;   use AUnit.Test_Suites;
with AUnit.Test_Cases;    use AUnit.Test_Cases;
with AUnit.Test_Caller;

with AeroSys.Tests;

procedure AeroSys_Test_Runner is

   package Caller is new AUnit.Test_Caller (AUnit.Test_Cases.Test_Case);

   use AeroSys.Tests;

   function Suite return Access_Test_Suite is
      S : constant Access_Test_Suite := AUnit.Test_Suites.New_Suite;
   begin
      --  ARINC 429 Bus Tests (AEROSYS-HLR-BUS-001 through BUS-008)
      S.Add_Test (Caller.Create ("TC-BUS-001: Word Roundtrip",         Test_Word_Roundtrip'Access));
      S.Add_Test (Caller.Create ("TC-BUS-002: Parity Error Detection", Test_Parity_Detection'Access));
      S.Add_Test (Caller.Create ("TC-BUS-003: Label Bit Reversal",     Test_Label_Reversal'Access));
      S.Add_Test (Caller.Create ("TC-BUS-004a: BNR Positive Decode",   Test_BNR_Positive'Access));
      S.Add_Test (Caller.Create ("TC-BUS-004b: BNR Negative Decode",   Test_BNR_Negative'Access));
      S.Add_Test (Caller.Create ("TC-BUS-005: SSM_FW Rejection",       Test_BNR_FW_Rejected'Access));
      S.Add_Test (Caller.Create ("TC-BUS-006: SSM_NCD Rejection",      Test_BNR_NCD_Rejected'Access));
      S.Add_Test (Caller.Create ("TC-BUS-007: BCD Frequency Decode",   Test_BCD_Frequency'Access));

      --  FADEC Tests (AEROSYS-HLR-FADEC-001 through FADEC-005)
      S.Add_Test (Caller.Create ("TC-FADEC-001: N1 Valid Decode",         Test_N1_Valid'Access));
      S.Add_Test (Caller.Create ("TC-FADEC-002: N1 Parity Error",         Test_N1_ParityError'Access));
      S.Add_Test (Caller.Create ("TC-FADEC-003: N1 SSM Failure Warning",  Test_N1_FW'Access));
      S.Add_Test (Caller.Create ("TC-FADEC-004: EGT No Exceedance",       Test_EGT_NoExceedance'Access));
      S.Add_Test (Caller.Create ("TC-FADEC-005: EGT TOGA Exceedance",     Test_EGT_TOGAExceedance'Access));
      S.Add_Test (Caller.Create ("TC-FADEC-006: Freshness OK",            Test_Freshness_OK'Access));
      S.Add_Test (Caller.Create ("TC-FADEC-007: Freshness Stale",         Test_Freshness_Stale'Access));
      S.Add_Test (Caller.Create ("TC-FADEC-008: Freshness Lost",          Test_Freshness_Lost'Access));
      S.Add_Test (Caller.Create ("TC-FADEC-009: Thrust Rating All 7",     Test_Thrust_Rating_Decode'Access));

      --  Autopilot Tests (AEROSYS-HLR-AFCS-001 through AFCS-003)
      S.Add_Test (Caller.Create ("TC-AFCS-001: AP Engage Nominal",         Test_AP_Engage_Nominal'Access));
      S.Add_Test (Caller.Create ("TC-AFCS-002: AP Reject Pitch High",      Test_AP_PitchHigh'Access));
      S.Add_Test (Caller.Create ("TC-AFCS-003: AP Reject Pitch Low",       Test_AP_PitchLow'Access));
      S.Add_Test (Caller.Create ("TC-AFCS-004: AP Reject Roll Excessive",  Test_AP_RollExcessive'Access));
      S.Add_Test (Caller.Create ("TC-AFCS-005: AP Reject Bad Source",      Test_AP_BadSource'Access));
      S.Add_Test (Caller.Create ("TC-AFCS-006: AP Reject Already Engaged", Test_AP_AlreadyOn'Access));
      S.Add_Test (Caller.Create ("TC-AFCS-007: Alt Target Above Ceiling",  Test_AP_AltTooHigh'Access));
      S.Add_Test (Caller.Create ("TC-AFCS-008: Mach Target Above MMO",     Test_AP_MachTooFast'Access));
      S.Add_Test (Caller.Create ("TC-AFCS-009: Disconnect Raises Alert",   Test_AP_Disconnect_Alert'Access));
      S.Add_Test (Caller.Create ("TC-AFCS-010: Disconnect No Alert",       Test_AP_Disconnect_NoAlert'Access));

      --  IRS Tests (AEROSYS-HLR-IRS-001, IRS-002)
      S.Add_Test (Caller.Create ("TC-IRS-001: Pitch Decode",              Test_IRS_Pitch'Access));
      S.Add_Test (Caller.Create ("TC-IRS-002: Roll Negative",             Test_IRS_Roll_Negative'Access));
      S.Add_Test (Caller.Create ("TC-IRS-003: Heading 0-360 Bounds",      Test_IRS_Heading_Bounds'Access));
      S.Add_Test (Caller.Create ("TC-IRS-004: Triple IRS Unanimous",      Test_IRS_Vote_Unanimous'Access));
      S.Add_Test (Caller.Create ("TC-IRS-005: Single Miscompare Detected",Test_IRS_Vote_SingleMiscompare'Access));

      --  Aircraft Profile Tests
      S.Add_Test (Caller.Create ("TC-ACM-001: All Profiles EGT Limits",   Test_Profile_EGT_Limits'Access));
      S.Add_Test (Caller.Create ("TC-ACM-002: Widebody Higher EGT",       Test_Profile_Widebody_EGT'Access));

      return S;
   end Suite;

   XML_Reporter  : AUnit.Reporter.XML.XML_Reporter;
   Text_Reporter : AUnit.Reporter.Text.Text_Reporter;
   Result        : AUnit.Status;
begin
   --  Run against both reporters
   Result := AUnit.Run.Run (Suite, XML_Reporter);
   Result := AUnit.Run.Run (Suite, Text_Reporter);

   if Result = AUnit.Failure then
      --  Return non-zero exit code for CI integration
      raise Program_Error with "One or more test cases FAILED";
   end if;
end AeroSys_Test_Runner;
