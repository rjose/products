#include <string.h>
#include "test_util.h"

int check_response(const char* response_str, const char *accept_key)
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
