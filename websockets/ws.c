#include <string.h>

#include "ws.h"

/*
 * We're basically checking to see if the required fields are present.
 */
int ws_is_handshake(const char* req_str)
{
        /* Look for "Upgrade: websocket" */ 
        if (strcasestr(req_str, "Upgrade: websocket") == NULL)
                return 0;

        /* Look for "Connection: Upgrade" */
        if (strcasestr(req_str, "Connection: upgrade") == NULL)
                return 0;

        /* Look for "Sec-WebSocket-Key:" */
        if (strcasestr(req_str, "Sec-WebSocket-Key:") == NULL)
                return 0;

        return 1;
}
