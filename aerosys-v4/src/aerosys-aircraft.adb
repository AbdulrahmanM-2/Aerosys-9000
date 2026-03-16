------------------------------------------------------------------------------
--  AeroSys.Aircraft — Body
------------------------------------------------------------------------------

package body AeroSys.Aircraft is

   function Get_Active_Profile return Aircraft_Profile is
      (Registry (Active_Index));

   function Get_Profile (Idx : Profile_Index) return Aircraft_Profile is
      (Registry (Idx));

   procedure Set_Active (Idx : Profile_Index) is
   begin
      Active_Index := Idx;
   end Set_Active;

   function ICAO_To_Index (ICAO : String) return Profile_Index is
   begin
      if    ICAO = "A320" or ICAO = "A319" or ICAO = "A318" then return IDX_A320_CFM;
      elsif ICAO = "A20N" or ICAO = "A21N" or ICAO = "A19N" then return IDX_A320_NEO;
      elsif ICAO = "B738" or ICAO = "B737" or ICAO = "B739" then return IDX_B737_NG;
      elsif ICAO = "B38M" or ICAO = "B39M" or ICAO = "B37M" then return IDX_B737_MAX;
      elsif ICAO = "A359" or ICAO = "A35K"                  then return IDX_A350_900;
      elsif ICAO = "A388"                                    then return IDX_A380_800;
      else  return IDX_A320_CFM;
      end if;
   end ICAO_To_Index;

   function Cruise_N1_Pct return Float is
      P : constant Aircraft_Profile := Get_Active_Profile;
   begin
      --  Approximate cruise N1 as ~85% of max TOGA for narrow-body,
      --  ~82% for wide-body (lower SFC point on larger fans)
      case P.Family is
         when A320_Family => return 84.5;
         when B737_Family => return 86.0;
         when A350_Family => return 81.5;
         when A380_Family => return 80.0;
      end case;
   end Cruise_N1_Pct;

   function Cruise_EGT_C return Integer is
      P : constant Aircraft_Profile := Get_Active_Profile;
   begin
      case P.Engine.Series is
         when CFM56_5B       => return 741;
         when CFM56_7B       => return 780;
         when LEAP_1A        => return 855;
         when LEAP_1B        => return 870;
         when TRENT_XWB84    => return 920;
         when TRENT_970 |
              TRENT_972 |
              TRENT_977      => return 890;
         when others         => return 750;
      end case;
   end Cruise_EGT_C;

   function Idle_N1_Pct return Float is
      (Get_Active_Profile.Engine.N1_Idle_Flight);

end AeroSys.Aircraft;
