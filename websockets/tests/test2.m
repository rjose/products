#include <err.h>
#include <stdlib.h>
#include <string.h>

#include "../ws.h"

#import "Testing.h"

/*
 * Static functions
 */
static int check_response(const char *, const char *);

/*
 * Test data
 */
static const char valid_ws_request_string[] = 
        "GET /chat HTTP/1.1\r\n"
        "Host: server.example.com\r\n"
        "Upgrade: websocket\r\n"
        "Connection: Upgrade\r\n"
        "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\n"
        "Origin: http://example.com\r\n"
        "Sec-WebSocket-Protocol: chat, superchat\r\n"
        "Sec-WebSocket-Version: 13\r\n"
        "\r\n";


static int check_response(const char* response_str, const char *accept_key)
{
        if (response_str == NULL)
                return 0;

        if (strcasestr(response_str, "101 Switching Protocols") == NULL)
                return 0;

        if (strcasestr(response_str, "Upgrade: websocket") == NULL)
                return 0;

        if (strcasestr(response_str, "Connection: upgrade") == NULL)
                return 0;

        if (strcasestr(response_str, "Sec-WebSocket-Accept:") == NULL)
                return 0;

        /*
         * NOTE: Should really check that the accept_key is the value of
         * Sec-WebSocket-key, but this is good enough.
         */
        if (strstr(response_str, accept_key) == NULL)
                return 0;

        return 1;
}

int main()
{
        const char *response_str = NULL;

        /*
         * Complete handshake
         */
        START_SET("Complete handshake");
        response_str = ws_complete_handshake(valid_ws_request_string);
        pass(1 == check_response(response_str,
                   "s3pPLMBiTxaQ9kYGzzhZRbK+xOo="), "Check handshake response");

        if (response_str != NULL)
                free(response_str);
        END_SET("Complete handshake");
        
        return 0;
}
