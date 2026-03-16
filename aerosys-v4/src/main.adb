------------------------------------------------------------------------------
--  AeroSys 9000 — Main Entry Point
--  File: src/main.adb
--
--  Starts the REST API server on the configured port.
--  Handles OS signals for graceful shutdown (SIGTERM, SIGINT).
------------------------------------------------------------------------------

with AeroSys.Server;
with Ada.Text_IO;       use Ada.Text_IO;
with Ada.Command_Line;
with Ada.Exceptions;

procedure Main is

   Port : Natural := AeroSys.Server.Default_Port;

begin
   --  Parse optional port argument
   if Ada.Command_Line.Argument_Count >= 1 then
      begin
         Port := Natural'Value (Ada.Command_Line.Argument (1));
      exception
         when Constraint_Error =>
            Put_Line ("Usage: aerosys_api [port]");
            Put_Line ("  port defaults to 8080");
            Ada.Command_Line.Set_Exit_Status (1);
            return;
      end;
   end if;

   Put_Line ("╔══════════════════════════════════════════════════╗");
   Put_Line ("║   AeroSys 9000 — Integrated Avionics Suite       ║");
   Put_Line ("║   REST API Server  v2.1.0                        ║");
   Put_Line ("║   Ada 2022 / GNAT 14.1 / DO-178C Level B         ║");
   Put_Line ("╚══════════════════════════════════════════════════╝");
   New_Line;

   AeroSys.Server.Start (Port);

exception
   when E : others =>
      Put_Line ("FATAL: " & Ada.Exceptions.Exception_Information (E));
      AeroSys.Server.Stop;
      Ada.Command_Line.Set_Exit_Status (1);
end Main;
