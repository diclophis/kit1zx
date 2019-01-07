/* */

window.startConnection = function(wsUrl) {
  if (window["WebSocket"]) {
    //TODO: this goes in the client/shell.js later
    //var debug_print = Module.cwrap(
    //  'debug_print', 'number', ['number', 'number']
    //);

    window.conn = new WebSocket(wsUrl);
    window.conn.binaryType = 'arraybuffer';

    window.conn.onopen = function (event) {
      console.log(event);

      window.onbeforeunload = function() {
        window.conn.onclose = function () {};
        window.conn.close();
      };
    };

    window.conn.onclose = function (event) {
      console.log("Connection closed.");
    };

    window.conn.onmessage = function (event) {
      console.log(event);
      /*
      origData = event.data;
      typedData = new Uint8Array(origData);
      var heapBuffer = Module._malloc(typedData.length * typedData.BYTES_PER_ELEMENT);
      Module.HEAPU8.set(typedData, heapBuffer);
      debug_print(heapBuffer, typedData.length);
      Module._free(heapBuffer);
      */
    };
  } else {
    console.log("Your browser does not support WebSockets.");
  }
};

startConnection("ws://localhost:8081/wss");
