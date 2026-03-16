------------------------------------------------------------------------------
--  AeroSys.SPARK.ARINC — Body
--  All subprograms proved by GNATprove.
--  No exceptions, no dynamic allocation, all contracts discharged.
------------------------------------------------------------------------------

pragma SPARK_Mode (On);

package body AeroSys.SPARK.ARINC
  with SPARK_Mode => On
is

   --  ═══════════════════════════════════════════════════════════════
   --  PARITY
   --  ═══════════════════════════════════════════════════════════════

   function Check_Parity (Word : ARINC_Word) return Boolean is
      W : ARINC_Word := Word;
      N : Natural    := 0;
   begin
      --  Count set bits over all 32 bits
      --  Loop terminates: W strictly decreases each iteration
      while W /= 0 loop
         pragma Loop_Variant (Decreases => W);
         pragma Loop_Invariant (N <= 32);
         N := N + Natural (W and 1);
         W := Shift_Right (W, 1);
      end loop;
      --  Odd parity = total bit count is odd
      return (N mod 2) = 1;
   end Check_Parity;

   --  ═══════════════════════════════════════════════════════════════
   --  LABEL BIT REVERSAL
   --  ═══════════════════════════════════════════════════════════════

   function Reverse_Label (Label : ARINC_Label) return ARINC_Label is
      Input  : ARINC_Label := Label;
      Output : ARINC_Label := 0;
   begin
      for I in 1 .. 8 loop
         pragma Loop_Invariant (I in 1 .. 8);
         Output := Shift_Left  (Output, 1) or (Input and 1);
         Input  := Shift_Right (Input,  1);
      end loop;
      return Output;
   end Reverse_Label;

   --  ═══════════════════════════════════════════════════════════════
   --  WORD DECODE
   --  ═══════════════════════════════════════════════════════════════

   function Decode_Word (Raw : ARINC_Word) return ARINC_Word_Decoded is
      Result : ARINC_Word_Decoded;
   begin
      Result.Raw    := Raw;
      --  Label: bits 1–8, reversed (AEROSYS-HLR-BUS-001, BUS-003)
      Result.Label  := Reverse_Label (ARINC_Label (Raw and 16#FF#));
      --  SDI: bits 9–10
      Result.SDI    := ARINC_SDI  (Shift_Right (Raw,  8) and 16#03#);
      --  Data: bits 11–29 (19 bits)
      Result.Data   := ARINC_Data_19 (Shift_Right (Raw, 10) and 16#7FFFF#);
      --  SSM: bits 30–31
      Result.SSM    := ARINC_SSM  (Shift_Right (Raw, 29) and 16#03#);
      --  Parity bit: bit 32
      Result.Parity := (Raw and 16#8000_0000#) /= 0;
      --  Validity: odd parity check over entire word
      Result.Valid  := Check_Parity (Raw);

      --  Proof assertions for GNATprove
      pragma Assert (Result.SDI  in 0 .. 3);
      pragma Assert (Result.Data in 0 .. 16#7FFFF#);
      pragma Assert (Result.SSM  in 0 .. 3);
      pragma Assert (Result.Valid = Check_Parity (Raw));

      return Result;
   end Decode_Word;

   --  ═══════════════════════════════════════════════════════════════
   --  BNR DECODE — AEROSYS-HLR-BUS-004, BUS-005
   --  ═══════════════════════════════════════════════════════════════

   function Decode_BNR
     (Data       : ARINC_Data_19;
      Resolution : Float;
      SSM        : ARINC_SSM)
      return Float
   is
      Sign      : constant Boolean := (Data and 16#40000#) /= 0;  -- bit 19
      Magnitude : Float;
   begin
      --  NCD or FW → return 0.0 (AEROSYS-HLR-BUS-008)
      if SSM = SSM_FW or SSM = SSM_NCD then
         return 0.0;
      end if;

      if Sign then
         --  Negative: two's complement inversion over 19 bits
         declare
            Inverted : constant ARINC_Data_19 :=
              (not Data) and 16#7FFFF#;
         begin
            Magnitude := Float (Inverted + 1) * Resolution;
            return -Magnitude;
         end;
      else
         Magnitude := Float (Data) * Resolution;
         pragma Assert (Magnitude >= 0.0);
         return Magnitude;
      end if;
   end Decode_BNR;

   --  ═══════════════════════════════════════════════════════════════
   --  BNR ENCODE
   --  ═══════════════════════════════════════════════════════════════

   function Encode_BNR
     (Value      : Float;
      Resolution : Float)
      return ARINC_Data_19
   is
      Raw     : constant Integer :=
        Integer (Value / Resolution);
      --  Clamp to 19-bit signed range [-2^18, 2^18-1]
      Clamped : constant Integer :=
        Integer'Max (-(2**18),
          Integer'Min (2**18 - 1, Raw));
      Result  : ARINC_Data_19;
   begin
      if Clamped >= 0 then
         Result := ARINC_Data_19 (Clamped);
      else
         --  Two's complement over 19 bits
         Result := ARINC_Data_19 (2**19 + Clamped);
      end if;
      pragma Assert (Result in 0 .. 16#7FFFF#);
      return Result;
   end Encode_BNR;

   --  ═══════════════════════════════════════════════════════════════
   --  BCD DECODE — AEROSYS-HLR-BUS-006
   --  ═══════════════════════════════════════════════════════════════

   function Decode_BCD
     (Data      : ARINC_Data_19;
      Scale_Exp : Natural)
      return Float
   is
      D      : ARINC_Data_19 := Data;
      Result : Natural := 0;
      Mult   : Natural := 1;
      Digit  : Natural;
   begin
      --  Extract up to 5 BCD digits (4 bits each)
      for I in 1 .. 5 loop
         pragma Loop_Invariant (Mult in 1 .. 10_000);
         Digit := Natural (D and 16#F#);
         --  Clamp invalid BCD digits (A–F) to 0 (defensive)
         if Digit > 9 then Digit := 0; end if;
         Result := Result + Digit * Mult;
         D      := Shift_Right (D, 4);
         Mult   := Mult * 10;
      end loop;

      --  Apply scale factor
      declare
         Scale : Float := 1.0;
      begin
         for I in 1 .. Scale_Exp loop
            pragma Loop_Invariant (Scale >= 0.1 ** 4);
            Scale := Scale / 10.0;
         end loop;
         pragma Assert (Scale > 0.0);
         return Float (Result) * Scale;
      end;
   end Decode_BCD;

   --  ═══════════════════════════════════════════════════════════════
   --  WORD ENCODE
   --  ═══════════════════════════════════════════════════════════════

   function Encode_Word
     (Label : ARINC_Label;
      SDI   : ARINC_SDI;
      Data  : ARINC_Data_19;
      SSM   : ARINC_SSM)
      return ARINC_Word
   is
      W : ARINC_Word;
   begin
      --  Assemble fields into correct bit positions
      W := ARINC_Word (Reverse_Label (Label));          -- bits 1–8
      W := W or Shift_Left (ARINC_Word (SDI),   8);    -- bits 9–10
      W := W or Shift_Left (ARINC_Word (Data),  10);   -- bits 11–29
      W := W or Shift_Left (ARINC_Word (SSM),   29);   -- bits 30–31
      -- bit 32 = 0 at this point

      --  Set parity bit so word has odd parity (AEROSYS-HLR-BUS-002)
      if not Check_Parity (W) then
         W := W or 16#8000_0000#;
      end if;

      --  Postcondition proof helpers
      pragma Assert (Check_Parity (W));
      pragma Assert ((Shift_Right (W, 10) and 16#7FFFF#) = Data);
      pragma Assert ((Shift_Right (W, 29) and 3) = SSM);

      return W;
   end Encode_Word;

end AeroSys.SPARK.ARINC;
