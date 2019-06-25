const node = document.getElementById('app-node')
  , maxReplicas = Math.pow(2, 24)
  // , maxReplicas = 2
  , id = Math.floor(Math.random() * maxReplicas)
  , flags = { id: id, maxReplicas: maxReplicas }
  , app = Elm.Main.init({ node: node, flags: flags })
  , hostname = window.location.hostname
  , socketUrl = 'ws://' + hostname + ':8080'

console.log("replicaId", id)

let socket;

function bindSocket(socket) {
  socket.onmessage = event => {
    const op = JSON.parse(event.data);
    app.ports.messageIn.send(op);
  };

  socket.onclose = event => { setTimeout(connect, 1000); };
  socket.onerror = error => { socket.close() };
};

function connect() {
  socket = new WebSocket(socketUrl);
  bindSocket(socket);
};

connect();


app.ports.messageOut.subscribe(function(data) {
  if (socket.readyState !== WebSocket.OPEN) { return }
  socket.send(JSON.stringify(data));
});
