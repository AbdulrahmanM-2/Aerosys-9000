
package body PID_Controller is
   function Update(Error : Float) return Float is
   begin
      return Error * 0.5;
   end Update;
end PID_Controller;
