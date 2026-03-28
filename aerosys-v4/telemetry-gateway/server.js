
const WebSocket = require("ws");

const wss = new WebSocket.Server({port:4000});

setInterval(()=>{

 const data = {
  altitude:10000+Math.random()*100,
  speed:250+Math.random()*5,
  pitch:Math.random()*4
 }

 wss.clients.forEach(client=>{
  client.send(JSON.stringify(data))
 })

},200);
