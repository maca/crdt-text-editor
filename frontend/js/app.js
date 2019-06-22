const node = document.getElementById('app-node')
  , maxReplicas = Math.pow(2, 24)
  , id = Math.floor(Math.random() * maxReplicas)
  , flags = { id: id, maxReplicas: maxReplicas }
  , app = Elm.Main.init({ node: node, flags: flags })
  , socketUrl = 'ws://localhost:8080'


let socket;

function bindSocket(socket) {
  socket.onmessage = event => {
    const op = JSON.parse(event.data);
    app.ports.operationIn.send(op);
  };

  socket.onclose = event => { setTimeout(connect, 100); };
  socket.onerror = error => { socket.close() };
};

function connect() {
  socket = new WebSocket(socketUrl);
  bindSocket(socket);
};

connect();


app.ports.operationOut.subscribe(function(data) {
  socket.send(JSON.stringify(data));
});
