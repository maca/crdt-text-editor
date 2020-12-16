const node = document.getElementById('app-node')
  , id = Math.floor(Math.random() * Math.pow(2, 19))
  , app = Elm.Main.init({ node: node, flags: id })
  , hostname = window.location.hostname
  , protocol = window.location.protocol.replace('http', 'ws')
  , port = window.location.port && ':8080' || ''
  , socketUrl = protocol + '//' + hostname + port + '/ws'

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
