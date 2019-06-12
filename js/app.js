const node = document.getElementById('app-node')
  , id = Math.floor(Math.random() * Math.pow(2, 32))
  , flags = { id: id }
  , app = Elm.Main.init({ node: node, flags: flags });


// let socket;

// const connect = function() {
//   socket = new WebSocket('ws://localhost:8001');

//   socket.onmessage = event => {
//     const op = JSON.parse(event.data)
//     app.ports.messageIn.send(op);
//   };

//   socket.onclose = event => { setTimeout(connect, 100); };
//   socket.onerror = error => { socket.close() };
// }

// connect();


// app.ports.messageOut.subscribe(function(data) {
//   socket.send(JSON.stringify(data));
// })

