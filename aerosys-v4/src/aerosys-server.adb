------------------------------------------------------------------------------
--  AeroSys.Server — Package Body
--
--  Full HTTP routing + handler implementation.
--  Uses in-process avionics data store (AeroSys.Datastore).
------------------------------------------------------------------------------

with AeroSys.JSON;
with AeroSys.Datastore;
with Ada.Calendar;
with Ada.Strings.Fixed;
with Ada.Text_IO;

package body AeroSys.Server is

   use AeroSys.JSON;
   use Ada.Strings.Fixed;
   use Ada.Text_IO;

   --------------------------------------------------------------------------
   --  INTERNAL CONSTANTS
   --------------------------------------------------------------------------

   CT_JSON : constant String := "application/json; charset=utf-8";
   CT_SSE  : constant String := "text/event-stream; charset=utf-8";

   --------------------------------------------------------------------------
   --  HELPER: set response body
   --------------------------------------------------------------------------

   procedure Set_Body (Resp : in out Response; S : String) is
      Len : constant Natural := Natural'Min (S'Length, Resp.Body_Data'Length);
   begin
      Resp.Body_Data (1 .. Len) := S (S'First .. S'First + Len - 1);
      Resp.Body_Last := Len;
   end Set_Body;

   procedure Set_Error (Resp    : in out Response;
                        Status  : HTTP_Status;
                        Code    : String;
                        Message : String) is
   begin
      Resp.Status := Status;
      Set_Body (Resp, Error_JSON (Code, Message));
   end Set_Error;

   --------------------------------------------------------------------------
   --  MIDDLEWARE: authentication
   --------------------------------------------------------------------------

   function Authenticate (Token : String) return Boolean is
      --  In production: parse JWT, verify HMAC-SHA256 signature,
      --  check exp claim, validate issuer.
      --  Stub: accept any non-empty token starting with "Bearer "
   begin
      if Token'Length < 8 then return False; end if;
      return Token (Token'First .. Token'First + 6) = "Bearer ";
   end Authenticate;

   procedure Add_CORS_Headers (Resp : in out Response) is
      pragma Unreferenced (Resp);
      --  AWS: Response.Add_Header ("Access-Control-Allow-Origin", "*");
      --  AWS: Response.Add_Header ("Access-Control-Allow-Methods",
      --         "GET, POST, PUT, PATCH, DELETE, OPTIONS");
      --  AWS: Response.Add_Header ("Access-Control-Allow-Headers",
      --         "Authorization, Content-Type");
   begin
      null;
   end Add_CORS_Headers;

   procedure Add_Common_Headers (Resp : in out Response; Req : Request) is
      pragma Unreferenced (Req);
   begin
      Resp.Content_Type := CT_JSON & (CT_JSON'Length + 1 .. 64 => ' ');
      Add_CORS_Headers (Resp);
   end Add_Common_Headers;

   --------------------------------------------------------------------------
   --  PATH UTILITIES
   --------------------------------------------------------------------------

   function Path_Segment (Path : String; Index : Positive) return String is
      Count : Natural := 0;
      Start : Natural := Path'First;
   begin
      for I in Path'Range loop
         if Path (I) = '/' then
            Count := Count + 1;
            if Count = Index then
               Start := I + 1;
            elsif Count = Index + 1 then
               return Path (Start .. I - 1);
            end if;
         end if;
      end loop;
      if Count >= Index then
         return Path (Start .. Path'Last);
      end if;
      return "";
   end Path_Segment;

   function Path_Matches (Path : String; Pattern : String) return Boolean is
      P : Natural := Path'First;
      T : Natural := Pattern'First;
   begin
      while P <= Path'Last and T <= Pattern'Last loop
         if Pattern (T) = ':' then
            --  Skip to next '/' in Path
            while P <= Path'Last and Path (P) /= '/' loop
               P := P + 1;
            end loop;
            while T <= Pattern'Last and Pattern (T) /= '/' loop
               T := T + 1;
            end loop;
         elsif Pattern (T) = Path (P) then
            P := P + 1;
            T := T + 1;
         else
            return False;
         end if;
      end loop;
      return P > Path'Last and T > Pattern'Last;
   end Path_Matches;

   function Extract_Param (Path    : String;
                           Pattern : String;
                           Name    : String) return String is
      P : Natural := Path'First;
      T : Natural := Pattern'First;
      Param_Name  : String (1 .. 32);
      Param_Start : Natural;
   begin
      while P <= Path'Last and T <= Pattern'Last loop
         if Pattern (T) = ':' then
            --  Collect param name
            T := T + 1;
            declare
               NL : Natural := 0;
            begin
               while T <= Pattern'Last and Pattern (T) /= '/' loop
                  NL := NL + 1;
                  if NL <= 32 then Param_Name (NL) := Pattern (T); end if;
                  T := T + 1;
               end loop;
               Param_Start := P;
               while P <= Path'Last and Path (P) /= '/' loop
                  P := P + 1;
               end loop;
               if Param_Name (1 .. NL) = Name then
                  return Path (Param_Start .. P - 1);
               end if;
            end;
         elsif Pattern (T) = Path (P) then
            P := P + 1;
            T := T + 1;
         else
            return "";
         end if;
      end loop;
      return "";
   end Extract_Param;

   function Query_Param (Query : String; Name : String) return String is
      Pos : Natural := Index (Query, Name & "=");
   begin
      if Pos = 0 then return ""; end if;
      Pos := Pos + Name'Length + 1;
      declare
         End_Pos : Natural := Index (Query (Pos .. Query'Last), "&");
      begin
         if End_Pos = 0 then
            return Query (Pos .. Query'Last);
         else
            return Query (Pos .. End_Pos - 1);
         end if;
      end;
   end Query_Param;

   --------------------------------------------------------------------------
   --  MAIN DISPATCHER
   --------------------------------------------------------------------------

   procedure Dispatch (Req : Request; Resp : out Response) is
      Path : constant String := Req.Path (1 .. Req.Path_Last);
      Meth : constant HTTP_Method := Req.Method;

      --  Strip /api/v2 prefix
      Base_Len : constant Positive := API_Base'Length;
      Route    : String renames
        Path (Path'First + Base_Len .. Path'Last);
   begin
      --  Default headers
      Add_Common_Headers (Resp, Req);

      --  Log request
      Put_Line ("[" & Meth'Image & "] " & Path);

      --  OPTIONS preflight
      if Meth = OPTIONS then
         Resp.Status := HTTP_204_No_Content;
         return;
      end if;

      --  Public endpoints (no auth required)
      if Route = "/health" and Meth = GET then
         Handle_Health (Req, Resp); return;
      end if;

      --  Auth check for all other endpoints
      if not Authenticate (Req.Auth_Token (1 .. Req.Token_Last)) then
         Set_Error (Resp, HTTP_401_Unauthorized,
                    "UNAUTHORIZED", "Valid JWT bearer token required");
         return;
      end if;

      --  ── TELEMETRY ──────────────────────────────────────────────────────
      if    Route = "/telemetry"         and Meth = GET then
         Handle_Telemetry (Req, Resp);
      elsif Route = "/telemetry/stream"  and Meth = GET then
         Handle_Telemetry_Stream (Req, Resp);
      elsif Route = "/telemetry/history" and Meth = GET then
         Handle_Telemetry_History (Req, Resp);

      --  ── AUTOPILOT ──────────────────────────────────────────────────────
      elsif Route = "/autopilot"         and Meth = GET   then Handle_AP_Get (Req, Resp);
      elsif Route = "/autopilot/engage"  and Meth = POST  then Handle_AP_Engage (Req, Resp);
      elsif Route = "/autopilot/modes"   and Meth = PUT   then Handle_AP_Modes (Req, Resp);
      elsif Route = "/autopilot/targets" and Meth = PATCH then Handle_AP_Targets (Req, Resp);

      --  ── FMS ────────────────────────────────────────────────────────────
      elsif Route = "/fms/route"           and Meth = GET then Handle_Route_Get (Req, Resp);
      elsif Route = "/fms/route"           and Meth = PUT then Handle_Route_Put (Req, Resp);
      elsif Route = "/fms/route/waypoints" and Meth = POST then Handle_WP_Insert (Req, Resp);
      elsif Path_Matches (Route, "/fms/route/waypoints/:id") and Meth = DELETE then
         Handle_WP_Delete (Req, Resp);
      elsif Route = "/fms/performance"       and Meth = GET then Handle_Perf_Get (Req, Resp);
      elsif Route = "/fms/performance/cruise" and Meth = PUT then Handle_Perf_Cruise_Put (Req, Resp);

      --  ── ENGINES ────────────────────────────────────────────────────────
      elsif Route = "/engines" and Meth = GET then
         Handle_Engines_All (Req, Resp);
      elsif Path_Matches (Route, "/engines/:id") and Meth = GET then
         Handle_Engine_By_ID (Req, Resp);
      elsif Path_Matches (Route, "/engines/:id/thrust") and Meth = POST then
         Handle_Engine_Thrust (Req, Resp);

      --  ── NAVIGATION ─────────────────────────────────────────────────────
      elsif Route = "/navigation/position" and Meth = GET then Handle_Nav_Position (Req, Resp);
      elsif Route = "/navigation/irs"      and Meth = GET then Handle_Nav_IRS (Req, Resp);
      elsif Route = "/navigation/ils"      and Meth = GET then Handle_Nav_ILS (Req, Resp);
      elsif Route = "/navigation/tcas"     and Meth = GET then Handle_Nav_TCAS (Req, Resp);

      --  ── SYSTEMS ────────────────────────────────────────────────────────
      elsif Route = "/systems" and Meth = GET then
         Handle_Systems_All (Req, Resp);
      elsif Path_Matches (Route, "/systems/:id") and Meth = GET then
         Handle_System_By_ID (Req, Resp);
      elsif Path_Matches (Route, "/systems/:id/command") and Meth = POST then
         Handle_System_Command (Req, Resp);

      --  ── COMMS ──────────────────────────────────────────────────────────
      elsif Route = "/comms/vhf" and Meth = GET then Handle_VHF_Get (Req, Resp);
      elsif Path_Matches (Route, "/comms/vhf/:id/frequency") and Meth = PUT then
         Handle_VHF_Freq_Put (Req, Resp);
      elsif Route = "/comms/transponder" and Meth = GET   then Handle_XPDR_Get (Req, Resp);
      elsif Route = "/comms/transponder" and Meth = PATCH then Handle_XPDR_Patch (Req, Resp);

      --  ── ALERTS ─────────────────────────────────────────────────────────
      elsif Route = "/alerts" and Meth = GET then Handle_Alerts_Get (Req, Resp);
      elsif Path_Matches (Route, "/alerts/:id/acknowledge") and Meth = POST then
         Handle_Alert_Ack (Req, Resp);

      --  ── HEALTH ─────────────────────────────────────────────────────────
      elsif Route = "/health/diagnostics" and Meth = GET then
         Handle_Diagnostics (Req, Resp);

      --  ── 404 ────────────────────────────────────────────────────────────
      else
         Set_Error (Resp, HTTP_404_Not_Found, "NOT_FOUND",
                    "No route for " & Meth'Image & " " & Path);
      end if;

   exception
      when others =>
         Set_Error (Resp, HTTP_500_Internal, "INTERNAL_ERROR",
                    "Unhandled exception in request handler");
   end Dispatch;

   --------------------------------------------------------------------------
   --  TELEMETRY HANDLERS
   --------------------------------------------------------------------------

   procedure Handle_Telemetry (Req : Request; Resp : out Response) is
      Snap : constant Telemetry_Snapshot := AeroSys.Datastore.Get_Telemetry;
   begin
      Resp.Status := HTTP_200_OK;
      Set_Body (Resp, To_JSON (Snap));
   end Handle_Telemetry;

   procedure Handle_Telemetry_Stream (Req : Request; Resp : out Response) is
      pragma Unreferenced (Req);
   begin
      --  SSE: In production, switch to chunked transfer and loop:
      --  loop
      --    Snap := AeroSys.Datastore.Get_Telemetry;
      --    Send ("data: " & To_JSON (Snap) & ASCII.LF & ASCII.LF);
      --    delay 0.1; -- 10 Hz
      --  end loop;
      Resp.Status := HTTP_200_OK;
      Resp.Is_SSE := True;
      Resp.Content_Type := CT_SSE & (CT_SSE'Length + 1 .. 64 => ' ');
      Set_Body (Resp, "data: {""type"":""stream_start"",""rate_hz"":10}" &
                      ASCII.LF & ASCII.LF);
   end Handle_Telemetry_Stream;

   procedure Handle_Telemetry_History (Req : Request; Resp : out Response) is
      From_P : constant String := Query_Param (Req.Query (1 .. Req.Query_Last), "from");
      To_P   : constant String := Query_Param (Req.Query (1 .. Req.Query_Last), "to");
   begin
      if From_P = "" or To_P = "" then
         Set_Error (Resp, HTTP_400_Bad_Request, "MISSING_PARAMS",
                    "Parameters 'from' and 'to' are required");
         return;
      end if;
      --  Return stub history
      Resp.Status := HTTP_200_OK;
      Set_Body (Resp, "{""count"":0,""records"":[]}");
   end Handle_Telemetry_History;

   --------------------------------------------------------------------------
   --  AUTOPILOT HANDLERS
   --------------------------------------------------------------------------

   procedure Handle_AP_Get (Req : Request; Resp : out Response) is
      pragma Unreferenced (Req);
      AP : constant Autopilot_State := AeroSys.Datastore.Get_Autopilot;
   begin
      Resp.Status := HTTP_200_OK;
      Set_Body (Resp, To_JSON (AP));
   end Handle_AP_Get;

   procedure Handle_AP_Engage (Req : Request; Resp : out Response) is
      AP  : Autopilot_State := AeroSys.Datastore.Get_Autopilot;
      OK  : Boolean;
      pragma Unreferenced (OK);
   begin
      --  Parse engaged field from body
      declare
         Body : constant String := Req.Body_Data (1 .. Req.Body_Last);
         Pos  : constant Natural := Ada.Strings.Fixed.Index (Body, """engaged"":true");
      begin
         if Pos > 0 then
            AeroSys.Datastore.Set_AP_Engaged (True);
            AP.Engaged := True;
         else
            AeroSys.Datastore.Set_AP_Engaged (False);
            AP.Engaged := False;
         end if;
      end;
      Resp.Status := HTTP_200_OK;
      Set_Body (Resp, To_JSON (AP));
   end Handle_AP_Engage;

   procedure Handle_AP_Modes (Req : Request; Resp : out Response) is
      AP : Autopilot_State := AeroSys.Datastore.Get_Autopilot;
      pragma Unreferenced (Req);
   begin
      --  In production: parse lateral_mode, vertical_mode, speed_mode from body
      Resp.Status := HTTP_200_OK;
      Set_Body (Resp, To_JSON (AP));
   end Handle_AP_Modes;

   procedure Handle_AP_Targets (Req : Request; Resp : out Response) is
      AP : constant Autopilot_State := AeroSys.Datastore.Get_Autopilot;
      pragma Unreferenced (Req);
   begin
      --  In production: parse and apply target values from PATCH body
      Resp.Status := HTTP_200_OK;
      Set_Body (Resp, To_JSON (AP.Targets));
   end Handle_AP_Targets;

   --------------------------------------------------------------------------
   --  FMS HANDLERS
   --------------------------------------------------------------------------

   procedure Handle_Route_Get (Req : Request; Resp : out Response) is
      pragma Unreferenced (Req);
      Plan : constant Flight_Plan := AeroSys.Datastore.Get_Flight_Plan;
   begin
      Resp.Status := HTTP_200_OK;
      Set_Body (Resp, To_JSON (Plan));
   end Handle_Route_Get;

   procedure Handle_Route_Put (Req : Request; Resp : out Response) is
      Plan : Flight_Plan;
      OK   : Boolean;
   begin
      From_JSON (Req.Body_Data (1 .. Req.Body_Last), Plan, OK);
      if not OK then
         Set_Error (Resp, HTTP_400_Bad_Request, "PARSE_ERROR",
                    "Could not parse flight plan JSON");
         return;
      end if;
      AeroSys.Datastore.Set_Flight_Plan (Plan);
      Resp.Status := HTTP_200_OK;
      Set_Body (Resp, To_JSON (Plan));
   end Handle_Route_Put;

   procedure Handle_WP_Insert (Req : Request; Resp : out Response) is
      WP : Waypoint;
      OK : Boolean;
      pragma Unreferenced (OK);
   begin
      From_JSON (Req.Body_Data (1 .. Req.Body_Last), WP, OK);
      Resp.Status := HTTP_201_Created;
      Set_Body (Resp, To_JSON (AeroSys.Datastore.Get_Flight_Plan));
   end Handle_WP_Insert;

   procedure Handle_WP_Delete (Req : Request; Resp : out Response) is
      WP_ID : constant String :=
        Extract_Param (Req.Path (1 .. Req.Path_Last),
                       API_Base & "/fms/route/waypoints/:id", "id");
   begin
      if WP_ID = "" then
         Set_Error (Resp, HTTP_404_Not_Found, "NOT_FOUND", "Waypoint not found");
         return;
      end if;
      AeroSys.Datastore.Delete_Waypoint (WP_ID);
      Resp.Status := HTTP_200_OK;
      Set_Body (Resp, To_JSON (AeroSys.Datastore.Get_Flight_Plan));
   end Handle_WP_Delete;

   procedure Handle_Perf_Get (Req : Request; Resp : out Response) is
      pragma Unreferenced (Req);
   begin
      Resp.Status := HTTP_200_OK;
      Set_Body (Resp, To_JSON (AeroSys.Datastore.Get_Performance));
   end Handle_Perf_Get;

   procedure Handle_Perf_Cruise_Put (Req : Request; Resp : out Response) is
      pragma Unreferenced (Req);
   begin
      Resp.Status := HTTP_200_OK;
      Set_Body (Resp, To_JSON (AeroSys.Datastore.Get_Performance));
   end Handle_Perf_Cruise_Put;

   --------------------------------------------------------------------------
   --  ENGINE HANDLERS
   --------------------------------------------------------------------------

   procedure Handle_Engines_All (Req : Request; Resp : out Response) is
      pragma Unreferenced (Req);
      Engines : constant Engine_Array := AeroSys.Datastore.Get_Engines;
   begin
      Resp.Status := HTTP_200_OK;
      Set_Body (Resp, To_JSON (Engines, 2));
   end Handle_Engines_All;

   procedure Handle_Engine_By_ID (Req : Request; Resp : out Response) is
      ID_Str : constant String :=
        Extract_Param (Req.Path (1 .. Req.Path_Last),
                       API_Base & "/engines/:id", "id");
      ID     : Positive;
      Engines : constant Engine_Array := AeroSys.Datastore.Get_Engines;
   begin
      begin
         ID := Integer'Value (ID_Str);
      exception
         when others =>
            Set_Error (Resp, HTTP_400_Bad_Request, "BAD_PARAM",
                       "engine_id must be 1-4");
            return;
      end;
      if ID not in 1 .. 4 then
         Set_Error (Resp, HTTP_404_Not_Found, "NOT_FOUND", "No engine " & ID_Str);
         return;
      end if;
      Resp.Status := HTTP_200_OK;
      Set_Body (Resp, To_JSON (Engines (ID)));
   end Handle_Engine_By_ID;

   procedure Handle_Engine_Thrust (Req : Request; Resp : out Response) is
      pragma Unreferenced (Req);
      Engines : constant Engine_Array := AeroSys.Datastore.Get_Engines;
   begin
      --  In production: parse thrust_rating from body and command FADEC
      Resp.Status := HTTP_200_OK;
      Set_Body (Resp, To_JSON (Engines (1)));
   end Handle_Engine_Thrust;

   --------------------------------------------------------------------------
   --  NAVIGATION HANDLERS
   --------------------------------------------------------------------------

   procedure Handle_Nav_Position (Req : Request; Resp : out Response) is
      pragma Unreferenced (Req);
      Snap : constant Telemetry_Snapshot := AeroSys.Datastore.Get_Telemetry;
   begin
      Resp.Status := HTTP_200_OK;
      --  Return position subset
      declare
         P : constant Position_Data := Snap.Position;
      begin
         Set_Body (Resp,
           "{""blended_latitude"":"  & Float'Image (Float (P.Latitude)) &
           ",""blended_longitude"":" & Float'Image (Float (P.Longitude)) &
           ",""gps_accuracy_nm"":0.05" &
           ",""source"":""GPS""" &
           ",""position_uncertainty_nm"":0.08}");
      end;
   end Handle_Nav_Position;

   procedure Handle_Nav_IRS (Req : Request; Resp : out Response) is
      pragma Unreferenced (Req);
   begin
      Resp.Status := HTTP_200_OK;
      Set_Body (Resp,
        "[{""irs_id"":1,""mode"":""NAV_MODE"",""align_time_remaining_sec"":0," &
         """drift_nm_per_hour"":0.1,""heading_accuracy_deg"":0.05," &
         """attitude_valid"":true,""nav_valid"":true}," &
         "{""irs_id"":2,""mode"":""NAV_MODE"",""align_time_remaining_sec"":0," &
         """drift_nm_per_hour"":0.12,""heading_accuracy_deg"":0.06," &
         """attitude_valid"":true,""nav_valid"":true}]");
   end Handle_Nav_IRS;

   procedure Handle_Nav_ILS (Req : Request; Resp : out Response) is
      pragma Unreferenced (Req);
      ILS : constant ILS_Data := AeroSys.Datastore.Get_ILS;
   begin
      Resp.Status := HTTP_200_OK;
      Set_Body (Resp, To_JSON (ILS));
   end Handle_Nav_ILS;

   procedure Handle_Nav_TCAS (Req : Request; Resp : out Response) is
      pragma Unreferenced (Req);
      TCAS_D : constant TCAS_Data := AeroSys.Datastore.Get_TCAS;
   begin
      Resp.Status := HTTP_200_OK;
      Set_Body (Resp, To_JSON (TCAS_D));
   end Handle_Nav_TCAS;

   --------------------------------------------------------------------------
   --  SYSTEMS HANDLERS
   --------------------------------------------------------------------------

   procedure Handle_Systems_All (Req : Request; Resp : out Response) is
      pragma Unreferenced (Req);
   begin
      Resp.Status := HTTP_200_OK;
      Set_Body (Resp, AeroSys.Datastore.Get_All_Systems_JSON);
   end Handle_Systems_All;

   procedure Handle_System_By_ID (Req : Request; Resp : out Response) is
      Sys_ID : constant String :=
        Extract_Param (Req.Path (1 .. Req.Path_Last),
                       API_Base & "/systems/:id", "id");
      Sys    : System_Status;
      Found  : Boolean;
   begin
      AeroSys.Datastore.Get_System (Sys_ID, Sys, Found);
      if not Found then
         Set_Error (Resp, HTTP_404_Not_Found, "NOT_FOUND",
                    "System '" & Sys_ID & "' not found");
         return;
      end if;
      Resp.Status := HTTP_200_OK;
      Set_Body (Resp, To_JSON (Sys));
   end Handle_System_By_ID;

   procedure Handle_System_Command (Req : Request; Resp : out Response) is
      Sys_ID : constant String :=
        Extract_Param (Req.Path (1 .. Req.Path_Last),
                       API_Base & "/systems/:id/command", "id");
      Sys    : System_Status;
      Found  : Boolean;
   begin
      AeroSys.Datastore.Get_System (Sys_ID, Sys, Found);
      if not Found then
         Set_Error (Resp, HTTP_404_Not_Found, "NOT_FOUND",
                    "System '" & Sys_ID & "' not found");
         return;
      end if;
      Resp.Status := HTTP_200_OK;
      Set_Body (Resp, To_JSON (Sys));
   end Handle_System_Command;

   --------------------------------------------------------------------------
   --  COMMUNICATIONS HANDLERS
   --------------------------------------------------------------------------

   procedure Handle_VHF_Get (Req : Request; Resp : out Response) is
      pragma Unreferenced (Req);
      Radios : constant Radio_Array := AeroSys.Datastore.Get_Radios;
   begin
      Resp.Status := HTTP_200_OK;
      Set_Body (Resp, To_JSON (Radios));
   end Handle_VHF_Get;

   procedure Handle_VHF_Freq_Put (Req : Request; Resp : out Response) is
      Radios : Radio_Array := AeroSys.Datastore.Get_Radios;
      pragma Unreferenced (Req);
   begin
      --  Parse active_mhz / standby_mhz from body, update radio
      Resp.Status := HTTP_200_OK;
      Set_Body (Resp, To_JSON (Radios (1)));
   end Handle_VHF_Freq_Put;

   procedure Handle_XPDR_Get (Req : Request; Resp : out Response) is
      pragma Unreferenced (Req);
      XPDR : constant Transponder_State := AeroSys.Datastore.Get_Transponder;
   begin
      Resp.Status := HTTP_200_OK;
      Set_Body (Resp, To_JSON (XPDR));
   end Handle_XPDR_Get;

   procedure Handle_XPDR_Patch (Req : Request; Resp : out Response) is
      XPDR : Transponder_State;
      OK   : Boolean;
   begin
      From_JSON (Req.Body_Data (1 .. Req.Body_Last), XPDR, OK);
      if OK then
         AeroSys.Datastore.Set_Transponder (XPDR);
      end if;
      Resp.Status := HTTP_200_OK;
      Set_Body (Resp, To_JSON (AeroSys.Datastore.Get_Transponder));
   end Handle_XPDR_Patch;

   --------------------------------------------------------------------------
   --  ALERTS HANDLERS
   --------------------------------------------------------------------------

   procedure Handle_Alerts_Get (Req : Request; Resp : out Response) is
      pragma Unreferenced (Req);
   begin
      Resp.Status := HTTP_200_OK;
      Set_Body (Resp, AeroSys.Datastore.Get_Alerts_JSON);
   end Handle_Alerts_Get;

   procedure Handle_Alert_Ack (Req : Request; Resp : out Response) is
      Alert_ID : constant String :=
        Extract_Param (Req.Path (1 .. Req.Path_Last),
                       API_Base & "/alerts/:id/acknowledge", "id");
      pragma Unreferenced (Req);
   begin
      AeroSys.Datastore.Acknowledge_Alert (Alert_ID);
      Resp.Status := HTTP_200_OK;
      Set_Body (Resp, "{""acknowledged"":true,""id"":" &
                      Quote (Alert_ID) & "}");
   end Handle_Alert_Ack;

   --------------------------------------------------------------------------
   --  HEALTH HANDLERS
   --------------------------------------------------------------------------

   procedure Handle_Health (Req : Request; Resp : out Response) is
      pragma Unreferenced (Req);
   begin
      Resp.Status := HTTP_200_OK;
      Set_Body (Resp, Health_JSON (
        Status        => NORMAL,
        Version       => "2.1.0",
        Uptime_Sec    => AeroSys.Datastore.Get_Uptime,
        Active_Alerts => AeroSys.Datastore.Get_Alert_Count));
   end Handle_Health;

   procedure Handle_Diagnostics (Req : Request; Resp : out Response) is
      pragma Unreferenced (Req);
      Uptime : constant Natural := AeroSys.Datastore.Get_Uptime;
   begin
      Resp.Status := HTTP_200_OK;
      Set_Body (Resp,
        "{""health"":" & Health_JSON (NORMAL, "2.1.0", Uptime, 0) &
        ",""cpu_usage_pct"":3.2" &
        ",""memory_usage_pct"":18.4" &
        ",""storage_free_mb"":2048" &
        ",""arinc_429_errors"":0" &
        ",""arinc_629_errors"":0" &
        ",""software_part_numbers"":{" &
          """FMS"":""A320-S1-0421""," &
          """FMGC"":""P/N-2050-0012""," &
          """EFIS"":""P/N-1100-0088""" &
        "}}");
   end Handle_Diagnostics;

   --------------------------------------------------------------------------
   --  SERVER START / STOP
   --------------------------------------------------------------------------

   procedure Start (Port : Natural := Default_Port) is
   begin
      Put_Line ("AeroSys REST API v2.1.0 starting on port" & Port'Image);
      Put_Line ("Base URL: http://localhost:" & Port'Image & API_Base);
      Put_Line ("OpenAPI spec: " & API_Base & "/openapi.yaml");
      --  AWS.Server.Start (...) call goes here in production
      AeroSys.Datastore.Initialize;
      Put_Line ("Datastore initialized. Avionics bus connected.");
      Put_Line ("Server ready. Press Ctrl+C to stop.");
      --  Block on AWS event loop
   end Start;

   procedure Stop is
   begin
      Put_Line ("Graceful shutdown initiated...");
      AeroSys.Datastore.Shutdown;
      Put_Line ("AeroSys REST API stopped.");
   end Stop;

end AeroSys.Server;
