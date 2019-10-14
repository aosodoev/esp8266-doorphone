#include "web-ui.h"
#include "audio.h"
#include "doorphone.h"

#include <WebSocketsServer.h>
#include <ESP8266WebServer.h>
#include <DNSServer.h>
#include <FS.h>

ESP8266WebServer server(80);
DNSServer        dnsServer;
WebSocketsServer webSocket(81);

const uint8_t DNS_PORT = 53;

void handleNotFound();
void webSocketEvent(uint8_t num, WStype_t type, uint8_t * payload, size_t length);

void setupWebUI() {

  webSocket.begin();                          // start the websocket server
  webSocket.onEvent(webSocketEvent);          // if there's an incomming websocket message, go to function 'webSocketEvent'
  DPRINTF("WebSocket server started.");
  
  server.onNotFound(handleNotFound);          // if someone requests any other file or page, go to function 'handleNotFound'
                                              // and check if the file exists
  server.begin();                             // start the HTTP server
  DPRINTF("HTTP server started.");

  dnsServer.setErrorReplyCode(DNSReplyCode::NoError);
  dnsServer.start(DNS_PORT, "*", WiFi.softAPIP());
}

void loopWebUI() {
  dnsServer.processNextRequest();
  webSocket.loop();
  server.handleClient();
}

String getContentType(String filename) { // determine the filetype of a given filename, based on the extension
  if (filename.endsWith(".html")) return "text/html";
  else if (filename.endsWith(".css")) return "text/css";
  else if (filename.endsWith(".js")) return "application/javascript";
  else if (filename.endsWith(".ico")) return "image/x-icon";
  else if (filename.endsWith(".gz")) return "application/x-gzip";
  return "text/plain";
}

bool handleFileRead(String path) { // send the right file to the client (if it exists)
  if (path.endsWith("/")) path += "index.html";          // If a folder is requested, send the index files
  path = "/web" + path;
  String contentType = getContentType(path);             // Get the MIME type
  String pathWithGz = path + ".gz";
  if (SPIFFS.exists(pathWithGz) || SPIFFS.exists(path)) { // If the file exists, either as a compressed archive, or normal
    if (SPIFFS.exists(pathWithGz))                         // If there's a compressed version available
      path += ".gz";                                         // Use the compressed verion
    File file = SPIFFS.open(path, "r");                    // Open the file
    size_t sent = server.streamFile(file, contentType);    // Send it to the client
    file.close();                                        // Close the file again
    DPRINTF("Sent file: %s", path.c_str());
    return true;
  }
  DPRINTF("File Not Found: %s", path.c_str());   // If the file doesn't exist, return false
  return false;
}

void handleNotFound(){ // if the requested file or page doesn't exist, return a 404 not found error
  if(!handleFileRead(server.uri())){          // check if the file exists in the flash memory (SPIFFS), if so, send it
    server.send(404, "text/plain", "404: File Not Found");
  }
}

void broadcastSettings() {
  char *response = NULL;
  response = settings_json();
  webSocket.broadcastTXT(response, strlen(response));
  delete [] response;
}

void webSocketEvent(uint8_t num, WStype_t type, uint8_t * payload, size_t length) { // When a WebSocket message is received
  switch (type) {
  case WStype_DISCONNECTED:             // if the websocket is disconnected
    DPRINTF("[%u] Disconnected!\n", num);
    break;
  case WStype_CONNECTED:              // if a new websocket connection is established
    {
      IPAddress ip = webSocket.remoteIP(num);
      DPRINTF("[%u] Connected from %d.%d.%d.%d url: %s\n", num, ip[0], ip[1], ip[2], ip[3], payload);
      broadcastSettings();
    }
    break;
  case WStype_TEXT:                     // if new text data is received
    DPRINTF("[%u] get Text: %s\n", num, payload);
    String message((const char *)payload);
    if (message.startsWith("ringtone:")) {
      set_ringtone(message.substring(9).c_str());
    } else if (message.startsWith("key_add:")) {
      add_key(message.substring(8).c_str());
    } else if (message.startsWith("key_del:")) {
      delete_key(message.substring(8).c_str());
    }
    broadcastSettings();
    break;
  }
}
