------------------------------------------------------------------------------
--  AeroSys.SPARK.FADEC — SPARK 2014 FADEC Bus Interface
--
--  DO-178C DAL B — Formal verification with GNATprove
--  Satisfies: AEROSYS-HLR-FADEC-001 through FADEC-005
--
--  SPARK subset restrictions applied:
--    No dynamic allocation, no recursion, no uninitialized variables,
--    no exception propagation outside this package, all contracts proved.
--
--  Build: gnatprove -P aerosys.gpr --level=4 --mode=prove
--         --prover=z3,cvc5,altergo --timeout=60
--         --checks-as-errors --proof-warnings
------------------------------------------------------------------------------

pragma SPARK_Mode (On);

with Interfaces;          use Interfaces;
with AeroSys.Types;       use AeroSys.Types;
with AeroSys.SPARK.ARINC; use AeroSys.SPARK.ARINC;
with AeroSys.Aircraft;    use AeroSys.Aircraft;

package AeroSys.SPARK.FADEC
  with SPARK_Mode => On
is

   --  ═══════════════════════════════════════════════════════════════
   --  TYPES
   --  ═══════════════════════════════════════════════════════════════

   type Engine_Index is range 1 .. 4;

   --  Per-engine data decoded from FADEC ARINC 429 bus
   type FADEC_Engine_Data is record
      Engine_ID         : Engine_Index;
      N1_Pct            : N1_Percent      := 0.0;
      N2_Pct            : N2_Percent      := 0.0;
      EGT_C             : EGT_Celsius     := 0;
      FF_Kg_H           : Fuel_Flow_Kg_H  := 0.0;
      Oil_Pressure_Psi  : Oil_Psi         := 0.0;
      Oil_Temp_C        : Integer         := 0;
      Vibration_IPS     : Float           := 0.0;
      EPR               : Float           := 1.0;
      Status            : Engine_Status   := STOPPED;
      Rating            : Thrust_Rating   := IDLE;
      FADEC_Fault       : Boolean         := False;
      N1_SSM            : ARINC_SSM       := SSM_FW;
      EGT_SSM           : ARINC_SSM       := SSM_FW;
      Valid             : Boolean         := False;
      Last_Update_Ms    : Natural         := 0;
   end record;

   --  Bus channel state — tracks freshness per parameter
   type FADEC_Bus_State is record
      Engine       : FADEC_Engine_Data;
      Word_Count   : Natural          := 0;
      Error_Count  : Natural          := 0;
      Last_N1_Ms   : Natural          := 0;
      Last_EGT_Ms  : Natural          := 0;
      Last_FF_Ms   : Natural          := 0;
      Bus_Active   : Boolean          := False;
   end record;

   --  Decode result with explicit success/failure
   type Decode_Result is (OK, Parity_Error, SSM_Invalid, Range_Error, Stale);

   --  Per-engine result record
   type Engine_Decode_Result is record
      Status  : Decode_Result;
      Data    : FADEC_Engine_Data;
   end record;

   --  Alert raised by this package (forwarded to CAS)
   type FADEC_Alert_Kind is
     (No_Alert,
      EGT_Exceedance_TOGA,
      EGT_Exceedance_MCT,
      EGT_Exceedance_CRZ,
      N1_Exceedance,
      FADEC_Fault_Detected,
      Parameter_Stale,
      Parameter_Lost);

   type FADEC_Alert is record
      Kind      : FADEC_Alert_Kind := No_Alert;
      Engine_ID : Engine_Index     := 1;
      Value     : Float            := 0.0;
      Limit     : Float            := 0.0;
   end record;

   --  ═══════════════════════════════════════════════════════════════
   --  CONSTANTS — Freshness thresholds (AEROSYS-HLR-FADEC-005)
   --  ═══════════════════════════════════════════════════════════════

   STALE_THRESHOLD_MS : constant := 500;
   LOST_THRESHOLD_MS  : constant := 2000;

   --  ═══════════════════════════════════════════════════════════════
   --  CONTRACTS — Preconditions and postconditions proved by GNATprove
   --  ═══════════════════════════════════════════════════════════════

   --  Decode a raw ARINC 429 word for a given engine and parameter
   --  AEROSYS-HLR-FADEC-001: N1 decode
   function Decode_N1
     (Word    : ARINC_Word;
      Profile : Engine_Profile)
      return Engine_Decode_Result
   with
     SPARK_Mode => On,
     Global     => null,
     Depends    => (Decode_N1'Result => (Word, Profile)),
     Pre        => Profile.N1_Resolution > 0.0,
     Post       => (if Decode_N1'Result.Status = OK then
                       Decode_N1'Result.Data.N1_Pct in 0.0 .. 110.0
                   and then Decode_N1'Result.Data.N1_SSM = SSM_NORM);

   --  AEROSYS-HLR-FADEC-002: EGT decode with limit check
   function Decode_EGT
     (Word    : ARINC_Word;
      Profile : Engine_Profile;
      Rating  : Thrust_Rating)
      return Engine_Decode_Result
   with
     SPARK_Mode => On,
     Global     => null,
     Depends    => (Decode_EGT'Result => (Word, Profile, Rating)),
     Pre        => Profile.EGT_Resolution > 0.0,
     Post       => (if Decode_EGT'Result.Status = OK then
                       Decode_EGT'Result.Data.EGT_C in -60 .. 1200);

   --  Check EGT against active thrust rating limit
   --  Returns the appropriate alert if limit exceeded; No_Alert otherwise
   function Check_EGT_Limit
     (EGT_C   : EGT_Celsius;
      Profile : Engine_Profile;
      Rating  : Thrust_Rating;
      Eng_ID  : Engine_Index)
      return FADEC_Alert
   with
     SPARK_Mode => On,
     Global     => null,
     Depends    => (Check_EGT_Limit'Result => (EGT_C, Profile, Rating, Eng_ID)),
     Post       =>
       (if EGT_C > Profile.EGT_Max_TOGA then
           Check_EGT_Limit'Result.Kind /= No_Alert
        else
           Check_EGT_Limit'Result.Kind in No_Alert | EGT_Exceedance_MCT | EGT_Exceedance_CRZ);

   --  AEROSYS-HLR-FADEC-003: Thrust rating decode from DIS word
   function Decode_Thrust_Rating (Word : ARINC_Word) return Thrust_Rating
   with
     SPARK_Mode => On,
     Global     => null,
     Depends    => (Decode_Thrust_Rating'Result => Word);

   --  AEROSYS-HLR-FADEC-004: FADEC status check
   function Decode_FADEC_Status
     (Status_Word : ARINC_Word;
      Eng_ID      : Engine_Index)
      return FADEC_Alert
   with
     SPARK_Mode => On,
     Global     => null,
     Depends    => (Decode_FADEC_Status'Result => (Status_Word, Eng_ID)),
     Post       =>
       (Decode_FADEC_Status'Result.Kind in
          No_Alert | FADEC_Fault_Detected);

   --  AEROSYS-HLR-FADEC-005: Freshness check
   function Check_Freshness
     (Last_Update_Ms  : Natural;
      Current_Time_Ms : Natural;
      Eng_ID          : Engine_Index)
      return FADEC_Alert
   with
     SPARK_Mode => On,
     Global     => null,
     Depends    => (Check_Freshness'Result =>
                      (Last_Update_Ms, Current_Time_Ms, Eng_ID)),
     Post       =>
       (if Current_Time_Ms >= Last_Update_Ms then
          (if Current_Time_Ms - Last_Update_Ms >= LOST_THRESHOLD_MS then
              Check_Freshness'Result.Kind = Parameter_Lost
           elsif Current_Time_Ms - Last_Update_Ms >= STALE_THRESHOLD_MS then
              Check_Freshness'Result.Kind = Parameter_Stale
           else
              Check_Freshness'Result.Kind = No_Alert));

   --  Process a full incoming FADEC word — routes to correct decoder
   procedure Process_FADEC_Word
     (Word       :     ARINC_Word;
      State      : in out FADEC_Bus_State;
      Profile    :     Engine_Profile;
      Timestamp  :     Natural;
      Alert_Out  : out FADEC_Alert)
   with
     SPARK_Mode => On,
     Global     => null,
     Depends    => (State     => (State, Word, Profile, Timestamp),
                    Alert_Out => (Word, State, Profile, Timestamp)),
     Pre        => Profile.N1_Resolution > 0.0
               and Profile.EGT_Resolution > 0.0,
     Post       => State.Word_Count = State.Word_Count'Old + 1
               and (if not Check_Parity (Word) then
                       State.Error_Count = State.Error_Count'Old + 1
                    else
                       State.Error_Count = State.Error_Count'Old);

   --  Validate complete engine state is within operating limits
   function Engine_State_Valid
     (Data    : FADEC_Engine_Data;
      Profile : Engine_Profile)
      return Boolean
   with
     SPARK_Mode => On,
     Global     => null,
     Depends    => (Engine_State_Valid'Result => (Data, Profile)),
     Post       =>
       (Engine_State_Valid'Result =
         (Data.Valid
          and then Data.N1_Pct in 0.0 .. Profile.N1_Max_TOGA
          and then Data.EGT_C in -60 .. Profile.EGT_Max_TOGA
          and then Data.N1_SSM = SSM_NORM
          and then Data.EGT_SSM = SSM_NORM));

end AeroSys.SPARK.FADEC;
