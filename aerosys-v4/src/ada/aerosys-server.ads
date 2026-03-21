------------------------------------------------------------------------------
--  AeroSys.Server — AWS REST API Server
--
--  Implements the HTTP routing table for the AeroSys OpenAPI specification.
--  Built on AWS (Ada Web Server) with CORS, JWT auth middleware.
--
--  Endpoints:
--    GET  /api/v2/telemetry
--    GET  /api/v2/telemetry/stream      (SSE)
--    GET  /api/v2/telemetry/history
--    GET  /api/v2/autopilot
--    POST /api/v2/autopilot/engage
--    PUT  /api/v2/autopilot/modes
--    PATCH /api/v2/autopilot/targets
--    GET  /api/v2/fms/route
--    PUT  /api/v2/fms/route
--    POST /api/v2/fms/route/waypoints
--    DELETE /api/v2/fms/route/waypoints/:id
--    GET  /api/v2/fms/performance
--    PUT  /api/v2/fms/performance/cruise
--    GET  /api/v2/engines
--    GET  /api/v2/engines/:id
--    POST /api/v2/engines/:id/thrust
--    GET  /api/v2/navigation/position
--    GET  /api/v2/navigation/irs
--    GET  /api/v2/navigation/ils
--    GET  /api/v2/navigation/tcas
--    GET  /api/v2/systems
--    GET  /api/v2/systems/:id
--    POST /api/v2/systems/:id/command
--    GET  /api/v2/comms/vhf
--    PUT  /api/v2/comms/vhf/:id/frequency
--    GET  /api/v2/comms/transponder
--    PATCH /api/v2/comms/transponder
--    GET  /api/v2/alerts
--    POST /api/v2/alerts/:id/acknowledge
--    GET  /api/v2/health
--    GET  /api/v2/health/diagnostics
------------------------------------------------------------------------------

with AeroSys.Types; use AeroSys.Types;

package AeroSys.Server is

   --  Server configuration
   Default_Port    : constant := 8080;
   API_Base        : constant String := "/api/v2";
   Server_Name     : constant String := "AeroSys/2.1.0 (Ada/AWS)";
   Max_Connections : constant := 128;
   Request_Timeout : constant := 30;   -- seconds

   --------------------------------------------------------------------------
   --  REQUEST / RESPONSE types
   --------------------------------------------------------------------------

   type HTTP_Method is (GET, POST, PUT, PATCH, DELETE, OPTIONS, HEAD);

   type Request is record
      Method      : HTTP_Method;
      Path        : String (1 .. 512);
      Path_Last   : Natural := 0;
      Query       : String (1 .. 1024);
      Query_Last  : Natural := 0;
      Body_Data   : String (1 .. 65536);
      Body_Last   : Natural := 0;
      Auth_Token  : String (1 .. 512);
      Token_Last  : Natural := 0;
      Client_IP   : String (1 .. 64);
      Request_ID  : String (1 .. 36);   -- UUID
   end record;

   type Response is record
      Status      : HTTP_Status         := HTTP_200_OK;
      Body_Data   : String (1 .. 65536);
      Body_Last   : Natural             := 0;
      Content_Type : String (1 .. 64)  := "application/json              ";
      Is_SSE      : Boolean             := False;
   end record;

   --------------------------------------------------------------------------
   --  MAIN ENTRY POINTS
   --------------------------------------------------------------------------

   procedure Start (Port : Natural := Default_Port);
   --  Start the HTTP server — blocks until Stop is called

   procedure Stop;
   --  Graceful shutdown

   --------------------------------------------------------------------------
   --  ROUTER
   --------------------------------------------------------------------------

   procedure Dispatch (Req : Request; Resp : out Response);
   --  Main routing dispatcher — matches method + path to handler

   --------------------------------------------------------------------------
   --  MIDDLEWARE
   --------------------------------------------------------------------------

   function Authenticate (Token : String) return Boolean;
   --  Validate JWT bearer token; returns True if valid

   procedure Add_CORS_Headers (Resp : in out Response);
   --  Inject Access-Control-* headers for browser clients

   procedure Add_Common_Headers (Resp : in out Response; Req : Request);
   --  Request-ID, Server, Content-Type headers

   --------------------------------------------------------------------------
   --  HANDLER PROCEDURES
   --  Each maps to one or more OpenAPI operations
   --------------------------------------------------------------------------

   --  Telemetry
   procedure Handle_Telemetry          (Req : Request; Resp : out Response);
   procedure Handle_Telemetry_Stream   (Req : Request; Resp : out Response);
   procedure Handle_Telemetry_History  (Req : Request; Resp : out Response);

   --  Autopilot
   procedure Handle_AP_Get             (Req : Request; Resp : out Response);
   procedure Handle_AP_Engage          (Req : Request; Resp : out Response);
   procedure Handle_AP_Modes           (Req : Request; Resp : out Response);
   procedure Handle_AP_Targets         (Req : Request; Resp : out Response);

   --  FMS
   procedure Handle_Route_Get          (Req : Request; Resp : out Response);
   procedure Handle_Route_Put          (Req : Request; Resp : out Response);
   procedure Handle_WP_Insert          (Req : Request; Resp : out Response);
   procedure Handle_WP_Delete          (Req : Request; Resp : out Response);
   procedure Handle_Perf_Get           (Req : Request; Resp : out Response);
   procedure Handle_Perf_Cruise_Put    (Req : Request; Resp : out Response);

   --  Engines
   procedure Handle_Engines_All        (Req : Request; Resp : out Response);
   procedure Handle_Engine_By_ID       (Req : Request; Resp : out Response);
   procedure Handle_Engine_Thrust      (Req : Request; Resp : out Response);

   --  Navigation
   procedure Handle_Nav_Position       (Req : Request; Resp : out Response);
   procedure Handle_Nav_IRS            (Req : Request; Resp : out Response);
   procedure Handle_Nav_ILS            (Req : Request; Resp : out Response);
   procedure Handle_Nav_TCAS           (Req : Request; Resp : out Response);

   --  Systems
   procedure Handle_Systems_All        (Req : Request; Resp : out Response);
   procedure Handle_System_By_ID       (Req : Request; Resp : out Response);
   procedure Handle_System_Command     (Req : Request; Resp : out Response);

   --  Communications
   procedure Handle_VHF_Get            (Req : Request; Resp : out Response);
   procedure Handle_VHF_Freq_Put       (Req : Request; Resp : out Response);
   procedure Handle_XPDR_Get           (Req : Request; Resp : out Response);
   procedure Handle_XPDR_Patch         (Req : Request; Resp : out Response);

   --  Alerts
   procedure Handle_Alerts_Get         (Req : Request; Resp : out Response);
   procedure Handle_Alert_Ack          (Req : Request; Resp : out Response);

   --  Health
   procedure Handle_Health             (Req : Request; Resp : out Response);
   procedure Handle_Diagnostics        (Req : Request; Resp : out Response);

   --------------------------------------------------------------------------
   --  PATH UTILITIES
   --------------------------------------------------------------------------

   function Path_Segment (Path : String; Index : Positive) return String;
   --  Returns Nth path segment (1-indexed). "/api/v2/engines/2" → seg 4 = "2"

   function Path_Matches (Path : String; Pattern : String) return Boolean;
   --  Glob-style match with :param wildcards. "/engines/:id" matches "/engines/2"

   function Extract_Param (Path    : String;
                           Pattern : String;
                           Name    : String) return String;
   --  Extracts named param from path. Pattern="/engines/:id", Name="id" → "2"

   function Query_Param (Query : String; Name : String) return String;
   --  Extracts query parameter by name

end AeroSys.Server;
