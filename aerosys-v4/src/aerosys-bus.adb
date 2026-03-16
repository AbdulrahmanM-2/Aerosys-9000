------------------------------------------------------------------------------
--  AeroSys.Bus — Body
------------------------------------------------------------------------------

with AeroSys.Datastore; use AeroSys.Datastore;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;

package body AeroSys.Bus is

   --  ═══════════════════════════════════════════════════════════════
   --  HELPERS
   --  ═══════════════════════════════════════════════════════════════

   --  Build a BNR word with standard parameters
   function Make_BNR
     (Label : ARINC_Label;
      SDI   : ARINC_SDI;
      Value : Float;
      Res   : Float;
      Plus  : Boolean := True) return ARINC_Word
   is
      SSM  : constant ARINC_SSM :=
        (if Plus then SSM_PLUS else SSM_MINUS);
      Data : constant ARINC_Data_19 := Encode_BNR (Value, Res, Plus);
   begin
      return Encode_Word (Label, SDI, Data, SSM);
   end Make_BNR;

   --  Build a DIS (discrete) word
   function Make_DIS
     (Label : ARINC_Label;
      SDI   : ARINC_SDI;
      Bits  : ARINC_Data_19) return ARINC_Word
   is
   begin
      return Encode_Word (Label, SDI, Bits, SSM_NORMAL_OPERATION);
   end Make_DIS;

   --  ═══════════════════════════════════════════════════════════════
   --  FADEC BUS
   --  ═══════════════════════════════════════════════════════════════

   function Encode_FADEC
     (Eng     : Engine_Data;
      Profile : Engine_Profile) return FADEC_Bus_Word_Set
   is
      SDI : constant ARINC_SDI := ARINC_SDI (Eng.Engine_ID mod 4);
   begin
      return (
         N1   => Make_BNR (
           ARINC_Label (8#061# + Eng.Engine_ID - 1), SDI,
           Float (Eng.N1_Pct), Profile.N1_Resolution),
         N2   => Make_BNR (
           ARINC_Label (8#065# + Eng.Engine_ID - 1), SDI,
           Float (Eng.N2_Pct), 0.00391),
         EGT  => Make_BNR (
           ARINC_Label (8#071# + Eng.Engine_ID - 1), SDI,
           Float (Eng.EGT_C), Profile.EGT_Resolution),
         FF   => Make_BNR (
           ARINC_Label (8#073# + Eng.Engine_ID - 1), SDI,
           Float (Eng.FF_Kg_H), Profile.FF_Resolution),
         OIL_P => Make_BNR (8#077#, SDI, Float (Eng.Oil_Press_Psi), 0.125),
         OIL_T => Make_BNR (8#041#, SDI, Float (Eng.Oil_Temp_C), 0.25),
         VIB   => Make_BNR (ARINC_Label (8#055# + Eng.Engine_ID - 1), SDI,
                              Eng.Vibration, 0.001),
         EPR   => Make_BNR (ARINC_Label (8#051# + Eng.Engine_ID - 1), SDI,
                              Eng.EPR, 0.001),
         STAT  => Make_DIS (8#270#, SDI,
                   (if Eng.Status = RUNNING then 2#00000000001# else 0)));
   end Encode_FADEC;

   procedure Decode_FADEC
     (Words   : FADEC_Bus_Word_Set;
      Profile : Engine_Profile;
      Eng     : out Engine_Data)
   is
      N1_W : constant ARINC_Word_Decoded := Decode_Word (Words.N1);
      EGT_W: constant ARINC_Word_Decoded := Decode_Word (Words.EGT);
      FF_W : constant ARINC_Word_Decoded := Decode_Word (Words.FF);
   begin
      Eng.N1_Pct    := N1_Percent  (Decode_BNR (N1_W.Data, Profile.N1_Resolution,  N1_W.SSM));
      Eng.EGT_C     := EGT_Celsius (Integer (Decode_BNR (EGT_W.Data, Profile.EGT_Resolution, EGT_W.SSM)));
      Eng.FF_Kg_H   := Fuel_Flow_Kg_H (Decode_BNR (FF_W.Data, Profile.FF_Resolution, FF_W.SSM));
      Eng.Status    := (if Decode_Word (Words.STAT).Data /= 0 then RUNNING else STOPPED);
   end Decode_FADEC;

   --  ═══════════════════════════════════════════════════════════════
   --  ADC BUS
   --  ═══════════════════════════════════════════════════════════════

   function Encode_ADC
     (Speeds   : Speed_Data;
      Baro_Set : Float) return ADC_Bus_Word_Set
   is
   begin
      return (
         Baro_Alt   => Make_BNR (8#203#, 0, Float (0), 0.125),  -- from IRS
         Baro_Alt_2 => Make_BNR (8#204#, 0, Float (0), 0.125),
         IAS        => Make_BNR (8#206#, 0, Float (Speeds.IAS_Kt),  0.5),
         Mach       => Make_BNR (8#205#, 0, Float (Speeds.Mach),    0.000488),
         TAS        => Make_BNR (8#210#, 0, Float (Speeds.TAS_Kt),  0.5),
         SAT        => Make_BNR (8#211#, 0, -57.0, 0.25, False),
         TAT        => Make_BNR (8#213#, 0, -34.0, 0.25, False),
         Baro_Set   => Encode_Word (8#235#, 0, Encode_BCD (Baro_Set, 0), SSM_NORMAL_OPERATION),
         Overspd    => Make_DIS   (8#270#, 0, (if Speeds.Overspeed then 1 else 0)));
   end Encode_ADC;

   procedure Decode_ADC
     (Words  : ADC_Bus_Word_Set;
      Speeds : out Speed_Data)
   is
      IAS_W  : constant ARINC_Word_Decoded := Decode_Word (Words.IAS);
      Mach_W : constant ARINC_Word_Decoded := Decode_Word (Words.Mach);
      TAS_W  : constant ARINC_Word_Decoded := Decode_Word (Words.TAS);
   begin
      Speeds.IAS_Kt := Speed_Kts  (Decode_BNR (IAS_W.Data,  0.5,      IAS_W.SSM));
      Speeds.Mach   := Mach_Number(Decode_BNR (Mach_W.Data, 0.000488, Mach_W.SSM));
      Speeds.TAS_Kt := Speed_Kts  (Decode_BNR (TAS_W.Data,  0.5,      TAS_W.SSM));
   end Decode_ADC;

   --  ═══════════════════════════════════════════════════════════════
   --  IRS BUS
   --  ═══════════════════════════════════════════════════════════════

   function Encode_IRS
     (Att : Attitude_Data;
      Pos : Position_Data;
      Acc : Accel_Data) return IRS_Bus_Word_Set
   is
      Lat_Plus : constant Boolean := Pos.Latitude  >= 0.0;
      Lon_Plus : constant Boolean := Pos.Longitude >= 0.0;
   begin
      return (
         Latitude    => Make_BNR (8#100#, 0, abs Float (Pos.Latitude),  0.000021458, Lat_Plus),
         Longitude   => Make_BNR (8#101#, 0, abs Float (Pos.Longitude), 0.000021458, Lon_Plus),
         GS          => Make_BNR (8#102#, 0, Float (Pos.Track_Deg),     0.000687),
         Track_True  => Make_BNR (8#103#, 0, Float (Pos.Track_Deg),     0.000687),
         True_Hdg    => Make_BNR (8#114#, 0, Float (Pos.Heading_Mag),   0.000687),
         Mag_Hdg     => Make_BNR (8#320#, 0, Float (Pos.Heading_Mag),   0.000687),
         Pitch       => Make_BNR (8#324#, 0, abs Float (Att.Pitch_Deg), 0.00137, Att.Pitch_Deg >= 0.0),
         Roll        => Make_BNR (8#325#, 0, abs Float (Att.Roll_Deg),  0.00137, Att.Roll_Deg  >= 0.0),
         Pitch_Rate  => Make_BNR (8#326#, 0, abs Att.Pitch_Rate, 0.0000084, Att.Pitch_Rate >= 0.0),
         Roll_Rate   => Make_BNR (8#327#, 0, abs Att.Roll_Rate,  0.0000084, Att.Roll_Rate  >= 0.0),
         Yaw_Rate    => Make_BNR (8#330#, 0, 0.0, 0.0000084),
         Inert_VS    => Make_BNR (8#212#, 0, abs Float (Pos.VS_Fpm), 8.0, Pos.VS_Fpm >= 0),
         Norm_Accel  => Make_BNR (8#335#, 0, abs Float (Acc.Normal_G), 0.0000153, Acc.Normal_G >= 0.0),
         Long_Accel  => Make_BNR (8#336#, 0, abs Float (Acc.Longitudinal_G), 0.0000153, Acc.Longitudinal_G >= 0.0),
         Lat_Accel   => Make_BNR (8#337#, 0, abs Float (Acc.Lateral_G), 0.0000153, Acc.Lateral_G >= 0.0),
         IRS_Status  => Make_DIS (8#360#, 0, 2#111#));  -- all 3 IRS in NAV
   end Encode_IRS;

   procedure Decode_IRS
     (Words : IRS_Bus_Word_Set;
      Att   : out Attitude_Data;
      Pos   : out Position_Data;
      Acc   : out Accel_Data)
   is
      P_W : constant ARINC_Word_Decoded := Decode_Word (Words.Pitch);
      R_W : constant ARINC_Word_Decoded := Decode_Word (Words.Roll);
      Lat_W: constant ARINC_Word_Decoded := Decode_Word (Words.Latitude);
      Lon_W: constant ARINC_Word_Decoded := Decode_Word (Words.Longitude);
   begin
      Att.Pitch_Deg := Pitch_Deg (Decode_BNR (P_W.Data,   0.00137,      P_W.SSM));
      Att.Roll_Deg  := Roll_Deg  (Decode_BNR (R_W.Data,   0.00137,      R_W.SSM));
      Pos.Latitude  := Latitude  (Decode_BNR (Lat_W.Data, 0.000021458,  Lat_W.SSM));
      Pos.Longitude := Longitude (Decode_BNR (Lon_W.Data, 0.000021458,  Lon_W.SSM));
      Acc := (Normal_G => 1.0, Lateral_G => 0.0, Longitudinal_G => 0.0);
   end Decode_IRS;

   --  ═══════════════════════════════════════════════════════════════
   --  FMS BUS
   --  ═══════════════════════════════════════════════════════════════

   function Encode_FMS
     (AP  : Autopilot_State;
      FP  : Flight_Plan;
      GW  : Float;
      FOB : Float) return FMS_Bus_Word_Set
   is
      pragma Unreferenced (FP);
   begin
      return (
         Crz_Alt     => Make_BNR (8#130#, 0, Float (AP.Targets.Target_Altitude_Ft), 4.0),
         Sel_Alt     => Make_BNR (8#102#, 0, Float (AP.Targets.Target_Altitude_Ft), 4.0),
         Sel_Speed   => Make_BNR (8#103#, 0, Float (AP.Targets.Target_Speed_Kt),    0.5),
         Sel_Mach    => Make_BNR (8#115#, 0, Float (AP.Targets.Target_Mach),        0.000488),
         XTK_Error   => Make_BNR (8#173#, 0, 0.0, 0.000191),
         DTG         => Make_BNR (8#151#, 0, 2847.0, 0.5),
         Desired_Trk => Make_BNR (8#121#, 0, Float (AP.Targets.Target_Heading_Deg), 0.000687),
         WPT_Bearing => Make_BNR (8#113#, 0, 85.0, 0.000687),
         WPT_Distance=> Make_BNR (8#125#, 0, 42.0, 0.125),
         Gross_Wt    => Make_BNR (8#132#, 0, GW,   4.0),
         FOB         => Make_BNR (8#135#, 0, FOB,  2.0),
         Lat_Mode    => Make_DIS (8#270#, 0, 2#00001#),  -- LNAV
         Vert_Mode   => Make_DIS (8#271#, 0, 2#00010#)); -- VNAV ALT
   end Encode_FMS;

   procedure Decode_FMS
     (Words : FMS_Bus_Word_Set;
      AP    : out Autopilot_State)
   is
      Alt_W  : constant ARINC_Word_Decoded := Decode_Word (Words.Crz_Alt);
      Spd_W  : constant ARINC_Word_Decoded := Decode_Word (Words.Sel_Speed);
      Mach_W : constant ARINC_Word_Decoded := Decode_Word (Words.Sel_Mach);
   begin
      AP.Targets.Target_Altitude_Ft :=
        Altitude_Ft (Integer (Decode_BNR (Alt_W.Data,  4.0,      Alt_W.SSM)));
      AP.Targets.Target_Speed_Kt    :=
        Speed_Kts   (Decode_BNR (Spd_W.Data,  0.5,      Spd_W.SSM));
      AP.Targets.Target_Mach        :=
        Mach_Number (Decode_BNR (Mach_W.Data, 0.000488, Mach_W.SSM));
   end Decode_FMS;

   --  ═══════════════════════════════════════════════════════════════
   --  AFCS BUS
   --  ═══════════════════════════════════════════════════════════════

   function Encode_AFCS (AP : Autopilot_State) return AFCS_Bus_Word_Set is
   begin
      return (
         AP_Engaged => Make_DIS (8#273#, 0, (if AP.Engaged    then 1 else 0)),
         AT_Engaged => Make_DIS (8#274#, 0, (if AP.AT_Engaged then 1 else 0)),
         FD_On      => Make_DIS (8#275#, 0, (if AP.FD_On      then 1 else 0)),
         Sel_Alt    => Make_BNR (8#102#, 0, Float (AP.Targets.Target_Altitude_Ft), 4.0),
         Sel_Hdg    => Make_BNR (8#104#, 0, Float (AP.Targets.Target_Heading_Deg), 0.000687),
         Sel_VS     => Make_BNR (8#105#, 0, abs Float (AP.Targets.Target_VS_Fpm), 8.0,
                                  AP.Targets.Target_VS_Fpm >= 0),
         Sel_Spd    => Make_BNR (8#103#, 0, Float (AP.Targets.Target_Speed_Kt), 0.5),
         Lat_Dev    => Make_BNR (8#173#, 0, 0.0, 0.000191));
   end Encode_AFCS;

   procedure Decode_AFCS
     (Words : AFCS_Bus_Word_Set;
      AP    : out Autopilot_State)
   is
      AP_W : constant ARINC_Word_Decoded := Decode_Word (Words.AP_Engaged);
   begin
      AP.Engaged := AP_W.Data /= 0;
   end Decode_AFCS;

   --  ═══════════════════════════════════════════════════════════════
   --  ILS BUS
   --  ═══════════════════════════════════════════════════════════════

   function Encode_ILS (ILS : ILS_Data) return ILS_Bus_Word_Set is
   begin
      return (
         Freq    => Encode_Word (8#035#, 0, Encode_BCD (ILS.Frequency_Mhz, 2),
                                  SSM_NORMAL_OPERATION),
         LOC_Dev => Make_BNR (8#173#, 0, abs Float (ILS.LOC_Dots), 0.00000954,
                               Float (ILS.LOC_Dots) >= 0.0),
         GS_Dev  => Make_BNR (8#174#, 0, abs Float (ILS.GS_Dots),  0.00000954,
                               Float (ILS.GS_Dots) >= 0.0),
         DME     => Make_BNR (8#202#, 0, ILS.DME_Nm, 0.125),
         Status  => Make_DIS (8#175#, 0,
           (if ILS.LOC_Captured then 2 else 0) or
           (if ILS.GS_Captured  then 1 else 0)));
   end Encode_ILS;

   procedure Decode_ILS
     (Words : ILS_Bus_Word_Set;
      ILS   : out ILS_Data)
   is
      LOC_W : constant ARINC_Word_Decoded := Decode_Word (Words.LOC_Dev);
      GS_W  : constant ARINC_Word_Decoded := Decode_Word (Words.GS_Dev);
      St_W  : constant ARINC_Word_Decoded := Decode_Word (Words.Status);
   begin
      ILS.LOC_Dots       := ILS_Dots (Decode_BNR (LOC_W.Data, 0.00000954, LOC_W.SSM));
      ILS.GS_Dots        := ILS_Dots (Decode_BNR (GS_W.Data,  0.00000954, GS_W.SSM));
      ILS.LOC_Captured   := (St_W.Data and 2) /= 0;
      ILS.GS_Captured    := (St_W.Data and 1) /= 0;
   end Decode_ILS;

   --  ═══════════════════════════════════════════════════════════════
   --  SYSTEM BUS
   --  ═══════════════════════════════════════════════════════════════

   function Encode_Systems return System_Bus_Word_Set is
   begin
      return (
         Hyd_A    => Make_BNR (8#261#, 0, 3010.0, 1.0),
         Hyd_B    => Make_BNR (8#262#, 0, 2990.0, 1.0),
         Cab_Alt  => Make_BNR (8#247#, 0, 7200.0, 4.0),
         Diff_Pr  => Make_BNR (8#250#, 0, 8.23,   0.00391),
         Cab_VS   => Make_BNR (8#251#, 0, 200.0,  8.0, False),
         Fuel_Tot => Make_BNR (8#135#, 0, 85400.0, 4.0),
         Fuel_L   => Make_BNR (8#136#, 0, 31500.0, 4.0),
         Fuel_R   => Make_BNR (8#137#, 0, 31500.0, 4.0),
         Fuel_Ctr => Make_BNR (8#140#, 0, 22400.0, 4.0));
   end Encode_Systems;

   --  ═══════════════════════════════════════════════════════════════
   --  MONITOR UTILITIES
   --  ═══════════════════════════════════════════════════════════════

   procedure Monitor_Word (Ch : Bus_Channel; W : ARINC_Word) is
   begin
      Push_Word (Monitors (Ch), W);
   end Monitor_Word;

   function Get_Bus_Snapshot return Snapshot_Array is
      Result : Snapshot_Array;
      Idx    : Positive := 1;
      Snap   : constant Telemetry_Snapshot := Get_Telemetry;
      Prof   : constant Aircraft_Profile   := AeroSys.Aircraft.Get_Active_Profile;
      Eng    : constant Engine_Array       := Get_Engines;

      procedure Add (Ch : Bus_Channel; W : ARINC_Word; Val : Float) is
         Dec : constant ARINC_Word_Decoded := Decode_Word (W);
         N   : constant String := Label_Name (Dec.Label);
         Pad : constant String (1 .. 12) := (others => ' ');
         Nm  : String (1 .. 12) := Pad;
      begin
         if Idx > Max_Snapshot_Words then return; end if;
         Nm (1 .. Natural'Min (N'Length, 12)) := N (N'First .. N'First + Natural'Min (N'Length, 12) - 1);
         Result (Idx) := (
            Channel    => Ch,
            Label      => Dec.Label,
            Label_Name => Nm,
            Raw        => W,
            Decoded    => Val,
            SSM        => Dec.SSM,
            Valid      => Dec.Valid,
            SDI        => Dec.SDI);
         Idx := Idx + 1;
      end Add;

      FADEC_1_W : constant FADEC_Bus_Word_Set := Encode_FADEC (Eng (1), Prof.Engine);
      FADEC_2_W : constant FADEC_Bus_Word_Set := Encode_FADEC (Eng (2), Prof.Engine);
      ADC_W     : constant ADC_Bus_Word_Set   := Encode_ADC (Snap.Speeds, 1013.25);
      IRS_W     : constant IRS_Bus_Word_Set   := Encode_IRS (Snap.Attitude, Snap.Position, Snap.Accel);
      AP_W      : constant AFCS_Bus_Word_Set  := Encode_AFCS (Get_Autopilot);
      SYS_W     : constant System_Bus_Word_Set := Encode_Systems;
   begin
      --  Engine 1 FADEC
      Add (FADEC_1, FADEC_1_W.N1,   Float (Eng (1).N1_Pct));
      Add (FADEC_1, FADEC_1_W.EGT,  Float (Eng (1).EGT_C));
      Add (FADEC_1, FADEC_1_W.FF,   Float (Eng (1).FF_Kg_H));
      Add (FADEC_1, FADEC_1_W.OIL_P, Float (Eng (1).Oil_Press_Psi));
      --  Engine 2 FADEC
      Add (FADEC_2, FADEC_2_W.N1,   Float (Eng (2).N1_Pct));
      Add (FADEC_2, FADEC_2_W.EGT,  Float (Eng (2).EGT_C));
      Add (FADEC_2, FADEC_2_W.FF,   Float (Eng (2).FF_Kg_H));
      Add (FADEC_2, FADEC_2_W.OIL_P, Float (Eng (2).Oil_Press_Psi));
      --  ADC
      Add (ADC_1, ADC_W.IAS,     Float (Snap.Speeds.IAS_Kt));
      Add (ADC_1, ADC_W.Mach,    Float (Snap.Speeds.Mach));
      Add (ADC_1, ADC_W.TAS,     Float (Snap.Speeds.TAS_Kt));
      --  IRS
      Add (IRS_1, IRS_W.Pitch,   Float (Snap.Attitude.Pitch_Deg));
      Add (IRS_1, IRS_W.Roll,    Float (Snap.Attitude.Roll_Deg));
      Add (IRS_1, IRS_W.Mag_Hdg, Float (Snap.Position.Heading_Mag));
      Add (IRS_1, IRS_W.Latitude, Float (Snap.Position.Latitude));
      Add (IRS_1, IRS_W.Longitude, Float (Snap.Position.Longitude));
      --  AFCS
      Add (AFCS_1, AP_W.AP_Engaged, (if Get_Autopilot.Engaged then 1.0 else 0.0));
      Add (AFCS_1, AP_W.Sel_Alt, Float (Get_Autopilot.Targets.Target_Altitude_Ft));
      --  Systems
      Add (HYD_1,  SYS_W.Hyd_A, 3010.0);
      Add (HYD_1,  SYS_W.Hyd_B, 2990.0);
      Add (PRESS_1, SYS_W.Cab_Alt, 7200.0);
      Add (FUEL_1,  SYS_W.Fuel_Tot, 85400.0);
      return Result;
   end Get_Bus_Snapshot;

   function Get_Channel_Words
     (Ch : Bus_Channel; N : Natural) return Bus_Word_Array
   is
   begin
      return Peek_Words (Monitors (Ch), N);
   end Get_Channel_Words;

end AeroSys.Bus;
