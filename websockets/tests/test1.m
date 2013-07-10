#include <err.h>
#include <string.h>

#include "../ws.h"

#import "Testing.h"

static const char valid_request_string[] = 
        "GET /chat HTTP/1.1\r\n"
        "Host: server.example.com\r\n"
        "Upgrade: websocket\r\n"
        "Connection: Upgrade\r\n"
        "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\n"
        "Origin: http://example.com\r\n"
        "Sec-WebSocket-Protocol: chat, superchat\r\n"
        "Sec-WebSocket-Version: 13\r\n"
        "\r\n";

int main()
{
        char *message = "HOWDY";
        char *old_message;

        START_SET("Is websocket handshake");

        pass(1 == ws_is_handshake(valid_request_string), "Check start of handshake");

        END_SET("Is websocket handshake");
        
        return 0;
}
