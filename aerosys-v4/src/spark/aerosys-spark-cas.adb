pragma SPARK_Mode (On);
package body AeroSys.SPARK.CAS with SPARK_Mode => On is

   function Compute_Master_Flags (State : CAS_State) return CAS_State is
      S : CAS_State := State;
      Has_Warning : Boolean := False;
      Has_Caution : Boolean := False;
   begin
      for I in 1 .. State.Count loop
         pragma Loop_Invariant (I in 1 .. Max_Alerts + 1);
         if State.Alerts (I).Active and not State.Alerts (I).Acknowledged then
            if State.Alerts (I).Severity = WARNING then
               Has_Warning := True;
            elsif State.Alerts (I).Severity = CAUTION then
               Has_Caution := True;
            end if;
         end if;
      end loop;
      S.Master_Warning := Has_Warning;
      S.Master_Caution := Has_Caution;
      return S;
   end Compute_Master_Flags;

   procedure Acknowledge_Alert
     (State : in out CAS_State;
      ID    : Alert_ID_String;
      Found : out Boolean)
   is
   begin
      Found := False;
      for I in 1 .. State.Count loop
         pragma Loop_Invariant (State.Count = State.Count'Loop_Entry);
         if State.Alerts (I).ID = ID then
            State.Alerts (I).Acknowledged := True;
            Found := True;
            exit;
         end if;
      end loop;
   end Acknowledge_Alert;

end AeroSys.SPARK.CAS;
