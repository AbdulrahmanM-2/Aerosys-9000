------------------------------------------------------------------------------
--  AeroSys.ARINC429 — Body
------------------------------------------------------------------------------

package body AeroSys.ARINC429 is

   --  ═══════════════════════════════════════════════════════════════
   --  WORD ENCODING
   --  ═══════════════════════════════════════════════════════════════

   function Encode_Word
     (Label  : ARINC_Label;
      SDI    : ARINC_SDI;
      Data   : ARINC_Data_19;
      SSM    : ARINC_SSM) return ARINC_Word
   is
      W : ARINC_Word := 0;
   begin
      --  Bits 1–8   : Label (transmitted LSB-first; stored reversed in word)
      W := W or ARINC_Word (Reverse_Label (Label));
      --  Bits 9–10  : SDI
      W := W or Shift_Left (ARINC_Word (SDI),   8);
      --  Bits 11–29 : Data (19 bits)
      W := W or Shift_Left (ARINC_Word (Data and 16#7FFFF#), 10);
      --  Bits 30–31 : SSM
      W := W or Shift_Left (ARINC_Word (SSM),  29);
      --  Bit 32     : Odd parity
      if not Compute_Parity (W) then
         W := W or 16#8000_0000#;
      end if;
      return W;
   end Encode_Word;

   function Decode_Word (Raw : ARINC_Word) return ARINC_Word_Decoded is
      W : ARINC_Word_Decoded;
   begin
      W.Raw    := Raw;
      W.Label  := Reverse_Label (ARINC_Label (Raw and 16#FF#));
      W.SDI    := ARINC_SDI  (Shift_Right (Raw,  8) and 16#03#);
      W.Data   := ARINC_Data_19 (Shift_Right (Raw, 10) and 16#7FFFF#);
      W.SSM    := ARINC_SSM  (Shift_Right (Raw, 29) and 16#03#);
      W.Parity := (Raw and 16#8000_0000#) /= 0;
      W.Valid  := Check_Parity (Raw);
      W.Format := BNR;  -- default; overridden by label-specific decoder
      return W;
   end Decode_Word;

   --  ═══════════════════════════════════════════════════════════════
   --  BNR ENCODING / DECODING
   --  ═══════════════════════════════════════════════════════════════

   function Encode_BNR
     (Value      : Float;
      Resolution : Float;
      Positive   : Boolean := True) return ARINC_Data_19
   is
      pragma Unreferenced (Positive);
      Raw : constant Integer := Integer (Value / Resolution);
      --  Clamp to 19-bit signed range
      Clamped : constant Integer :=
        Integer'Max (-2**18, Integer'Min (2**18 - 1, Raw));
      As_Unsigned : ARINC_Data_19;
   begin
      if Clamped >= 0 then
         As_Unsigned := ARINC_Data_19 (Clamped);
      else
         As_Unsigned := ARINC_Data_19 (2**19 + Clamped);  -- two's complement
      end if;
      return As_Unsigned;
   end Encode_BNR;

   function Decode_BNR
     (Data       : ARINC_Data_19;
      Resolution : Float;
      SSM        : ARINC_SSM) return Float
   is
      Sign     : constant Boolean := (Data and 16#40000#) /= 0;  -- bit 29
      Magnitude : Float;
   begin
      if SSM = SSM_FAILURE_WARNING or SSM = SSM_NO_COMPUTED_DATA then
         return 0.0;  -- invalid data
      end if;
      if Sign then
         --  Negative: invert two's complement
         Magnitude := Float (Integer (not Data and 16#7FFFF#) + 1);
         return -Magnitude * Resolution;
      else
         return Float (Data) * Resolution;
      end if;
   end Decode_BNR;

   --  ═══════════════════════════════════════════════════════════════
   --  BCD ENCODING / DECODING
   --  ═══════════════════════════════════════════════════════════════

   function Encode_BCD (Value : Float; Scale : Natural) return ARINC_Data_19 is
      pragma Unreferenced (Scale);
      Int_Val : Natural := Natural (abs Value);
      Result  : ARINC_Data_19 := 0;
      Shift   : Natural := 0;
   begin
      while Int_Val > 0 and Shift < 20 loop
         Result := Result or Shift_Left (ARINC_Data_19 (Int_Val mod 10), Shift);
         Int_Val := Int_Val / 10;
         Shift := Shift + 4;
      end loop;
      return Result;
   end Encode_BCD;

   function Decode_BCD (Data : ARINC_Data_19; Scale : Natural) return Float is
      Result : Natural := 0;
      Mult   : Natural := 1;
      D      : ARINC_Data_19 := Data;
   begin
      for I in 1 .. 5 loop
         Result := Result + Natural (D and 16#F#) * Mult;
         D := Shift_Right (D, 4);
         Mult := Mult * 10;
      end loop;
      return Float (Result) / Float (10 ** Scale);
   end Decode_BCD;

   --  ═══════════════════════════════════════════════════════════════
   --  PARITY
   --  ═══════════════════════════════════════════════════════════════

   function Compute_Parity (Word : ARINC_Word) return Boolean is
      W : ARINC_Word := Word and 16#7FFF_FFFF#;  -- mask out parity bit
      N : Natural := 0;
   begin
      while W /= 0 loop
         N := N + Natural (W and 1);
         W := Shift_Right (W, 1);
      end loop;
      return (N mod 2) = 1;  -- True = odd parity set
   end Compute_Parity;

   function Check_Parity (Word : ARINC_Word) return Boolean is
      W    : ARINC_Word := Word;
      N    : Natural := 0;
   begin
      while W /= 0 loop
         N := N + Natural (W and 1);
         W := Shift_Right (W, 1);
      end loop;
      return (N mod 2) = 1;  -- valid if total bit count is odd
   end Check_Parity;

   --  ═══════════════════════════════════════════════════════════════
   --  LABEL BIT REVERSAL
   --  ═══════════════════════════════════════════════════════════════

   function Reverse_Label (Label : ARINC_Label) return ARINC_Label is
      Input  : ARINC_Label := Label;
      Output : ARINC_Label := 0;
   begin
      for I in 1 .. 8 loop
         Output := Shift_Left  (Output, 1) or (Input and 1);
         Input  := Shift_Right (Input,  1);
      end loop;
      return Output;
   end Reverse_Label;

   --  ═══════════════════════════════════════════════════════════════
   --  LABEL NAME TABLE
   --  ═══════════════════════════════════════════════════════════════

   function Label_Name (Label : ARINC_Label) return String is
   begin
      case Label is
         when 8#061# => return "N1 ENG 1";
         when 8#062# => return "N1 ENG 2";
         when 8#063# => return "N1 ENG 3";
         when 8#064# => return "N1 ENG 4";
         when 8#065# => return "N2 ENG 1";
         when 8#066# => return "N2 ENG 2";
         when 8#071# => return "EGT ENG 1";
         when 8#072# => return "EGT ENG 2";
         when 8#073# => return "FF ENG 1";
         when 8#074# => return "FF ENG 2";
         when 8#077# => return "OIL PRESS 1";
         when 8#100# => return "LATITUDE";
         when 8#101# => return "LONGITUDE";
         when 8#102# => return "GND SPEED";
         when 8#113# => return "IAS";
         when 8#114# => return "MACH";
         when 8#203# => return "BARO ALT 1";
         when 8#204# => return "BARO ALT 2";
         when 8#205# => return "MACH";
         when 8#206# => return "IAS";
         when 8#210# => return "TAS";
         when 8#211# => return "SAT";
         when 8#213# => return "TAT";
         when 8#212# => return "INERT VS";
         when 8#320# => return "MAG HDG";
         when 8#324# => return "PITCH";
         when 8#325# => return "ROLL";
         when 8#326# => return "PITCH RATE";
         when 8#327# => return "ROLL RATE";
         when 8#330# => return "YAW RATE";
         when 8#335# => return "NORM ACCEL";
         when 8#247# => return "CAB ALT";
         when 8#250# => return "DIFF PRESS";
         when 8#135# => return "FUEL TOTAL";
         when 8#273# => return "AP ENGAGED";
         when 8#274# => return "AT ENGAGED";
         when 8#261# => return "HYD PRESS A";
         when 8#262# => return "HYD PRESS B";
         when 8#270# => return "TCAS MODE";
         when 8#026# => return "SQUAWK";
         when 8#030# => return "VHF1 FREQ";
         when 8#031# => return "VHF2 FREQ";
         when 8#035# => return "ILS FREQ";
         when others => return "LBL " & Label'Image;
      end case;
   end Label_Name;

   --  ═══════════════════════════════════════════════════════════════
   --  BUS MONITOR BUFFER
   --  ═══════════════════════════════════════════════════════════════

   procedure Push_Word (Monitor : in out Bus_Monitor; W : ARINC_Word) is
      Decoded : constant ARINC_Word_Decoded := Decode_Word (W);
   begin
      Monitor.Buffer (Monitor.Head) := Decoded;
      Monitor.Head       := Monitor.Head + 1;
      Monitor.Word_Count := Monitor.Word_Count + 1;
      if not Decoded.Valid then
         Monitor.Error_Count := Monitor.Error_Count + 1;
      end if;
   end Push_Word;

   function Peek_Words
     (Monitor : Bus_Monitor; Count : Natural) return Bus_Word_Array
   is
      Result : Bus_Word_Array;
      Start  : Bus_Buffer_Index := Monitor.Head;
   begin
      for I in 0 .. Bus_Buffer_Index (Natural'Min (Count, Max_Bus_Buffer) - 1) loop
         Result (I) := Monitor.Buffer (Start - 1 - I);
      end loop;
      return Result;
   end Peek_Words;

end AeroSys.ARINC429;
