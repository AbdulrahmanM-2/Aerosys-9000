------------------------------------------------------------------------------
--  AeroSys.Types — Package Body
------------------------------------------------------------------------------

package body AeroSys.Types is

   function Status_Code (S : HTTP_Status) return Natural is
   begin
      case S is
         when HTTP_200_OK           => return 200;
         when HTTP_201_Created      => return 201;
         when HTTP_204_No_Content   => return 204;
         when HTTP_400_Bad_Request  => return 400;
         when HTTP_401_Unauthorized => return 401;
         when HTTP_403_Forbidden    => return 403;
         when HTTP_404_Not_Found    => return 404;
         when HTTP_409_Conflict     => return 409;
         when HTTP_422_Unprocessable => return 422;
         when HTTP_423_Locked       => return 423;
         when HTTP_500_Internal     => return 500;
         when HTTP_503_Unavailable  => return 503;
      end case;
   end Status_Code;

   function Status_Text (S : HTTP_Status) return String is
   begin
      case S is
         when HTTP_200_OK           => return "OK";
         when HTTP_201_Created      => return "Created";
         when HTTP_204_No_Content   => return "No Content";
         when HTTP_400_Bad_Request  => return "Bad Request";
         when HTTP_401_Unauthorized => return "Unauthorized";
         when HTTP_403_Forbidden    => return "Forbidden";
         when HTTP_404_Not_Found    => return "Not Found";
         when HTTP_409_Conflict     => return "Conflict";
         when HTTP_422_Unprocessable => return "Unprocessable Entity";
         when HTTP_423_Locked       => return "Locked";
         when HTTP_500_Internal     => return "Internal Server Error";
         when HTTP_503_Unavailable  => return "Service Unavailable";
      end case;
   end Status_Text;

end AeroSys.Types;
