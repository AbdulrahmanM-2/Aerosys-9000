------------------------------------------------------------------------------
--  AeroSys.Tests — Test Suite Spec
--  Declares all test procedures for AUnit registration
------------------------------------------------------------------------------

with AUnit.Test_Cases; use AUnit.Test_Cases;

package AeroSys.Tests is

   --  BUS tests
   procedure Test_Word_Roundtrip       (T : in out Test_Case'Class);
   procedure Test_Parity_Detection     (T : in out Test_Case'Class);
   procedure Test_Label_Reversal       (T : in out Test_Case'Class);
   procedure Test_BNR_Positive         (T : in out Test_Case'Class);
   procedure Test_BNR_Negative         (T : in out Test_Case'Class);
   procedure Test_BNR_FW_Rejected      (T : in out Test_Case'Class);
   procedure Test_BNR_NCD_Rejected     (T : in out Test_Case'Class);
   procedure Test_BCD_Frequency        (T : in out Test_Case'Class);

   --  FADEC tests
   procedure Test_N1_Valid             (T : in out Test_Case'Class);
   procedure Test_N1_ParityError       (T : in out Test_Case'Class);
   procedure Test_N1_FW                (T : in out Test_Case'Class);
   procedure Test_EGT_NoExceedance     (T : in out Test_Case'Class);
   procedure Test_EGT_TOGAExceedance   (T : in out Test_Case'Class);
   procedure Test_Freshness_OK         (T : in out Test_Case'Class);
   procedure Test_Freshness_Stale      (T : in out Test_Case'Class);
   procedure Test_Freshness_Lost       (T : in out Test_Case'Class);
   procedure Test_Thrust_Rating_Decode (T : in out Test_Case'Class);

   --  Autopilot tests
   procedure Test_AP_Engage_Nominal    (T : in out Test_Case'Class);
   procedure Test_AP_PitchHigh         (T : in out Test_Case'Class);
   procedure Test_AP_PitchLow          (T : in out Test_Case'Class);
   procedure Test_AP_RollExcessive     (T : in out Test_Case'Class);
   procedure Test_AP_BadSource         (T : in out Test_Case'Class);
   procedure Test_AP_AlreadyOn         (T : in out Test_Case'Class);
   procedure Test_AP_AltTooHigh        (T : in out Test_Case'Class);
   procedure Test_AP_MachTooFast       (T : in out Test_Case'Class);
   procedure Test_AP_Disconnect_Alert  (T : in out Test_Case'Class);
   procedure Test_AP_Disconnect_NoAlert(T : in out Test_Case'Class);

   --  IRS tests
   procedure Test_IRS_Pitch            (T : in out Test_Case'Class);
   procedure Test_IRS_Roll_Negative    (T : in out Test_Case'Class);
   procedure Test_IRS_Heading_Bounds   (T : in out Test_Case'Class);
   procedure Test_IRS_Vote_Unanimous   (T : in out Test_Case'Class);
   procedure Test_IRS_Vote_SingleMiscompare (T : in out Test_Case'Class);

   --  Aircraft profile tests
   procedure Test_Profile_EGT_Limits   (T : in out Test_Case'Class);
   procedure Test_Profile_Widebody_EGT (T : in out Test_Case'Class);

end AeroSys.Tests;
