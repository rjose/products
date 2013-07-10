#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <openssl/sha.h>

#include "ws.h"

#define MAX_HANDSHAKE_RESPONSE_LEN 300
#define MAX_WEBSOCKET_KEY_LEN 40
#define SEC_WEBSOCKET_KEY "Sec-WebSocket-Key"
#define SEC_WEBSOCKET_KEY_LEN 17
#define BUF_LENGTH 200

/*
 * Declare static functions
 */
static void err_abort(int, const char *);
static int get_ws_key(char *, size_t, const char *);

static char ws_magic_string[] = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";


// TODO: Move this to a util file
static void err_abort(int status, const char *message)
{
        fprintf(stderr, message);
        exit(status);
}

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

static int get_ws_key(char *dst, size_t n, const char *req_str)
{
        int i;
        const char *start_key;
        const char *val;

        start_key = strcasestr(req_str, SEC_WEBSOCKET_KEY);
        if (start_key == NULL)
                return -1;

        val = start_key + SEC_WEBSOCKET_KEY_LEN + 2; /* 2 for the colon and space */
        for (i = 0; i < n-1 && *val != '\r'; i++)
                *dst++ = *val++;
        *dst = '\0';

        return 0;
}

/*
 * We're assuming req_str is a valid handshake string.
 *
 * NOTE: This function allocates memory for the response, so the caller must
 * free it when done.
 *
 */
const char *ws_complete_handshake(const char *req_str)
{
        char buf[BUF_LENGTH];
        char websocket_key[MAX_WEBSOCKET_KEY_LEN];
	unsigned char sha_digest[SHA_DIGEST_LENGTH];
        char *websocket_accept = NULL;
        static char response_template[] = 
                "HTTP/1.1 101 Switching Protocols\r\n"
                "Upgrade: websocket\r\n"
                "Connection: Upgrade\r\n"
                "Sec-WebSocket-Accept: %s\r\n"
                "\r\n";
        char *result;
        
        /*
         * Allocate space for result
         */
        result = calloc(MAX_HANDSHAKE_RESPONSE_LEN, sizeof(char));
        if (result == NULL) {
                err_abort(-1, "Can't allocate memory in ws_complete_handshake");
        }

	/* Compute websocket accept value */
        if (get_ws_key(websocket_key, MAX_WEBSOCKET_KEY_LEN, req_str) != 0)
                goto error;

	strncpy(buf, websocket_key, BUF_LENGTH/2);
	strncat(buf, ws_magic_string, BUF_LENGTH/2);
	SHA1((const unsigned char*)buf, strlen(buf), sha_digest);

        if (base64_encode(&websocket_accept, sha_digest) != 0)
                goto error;

        /*
         * Construct response and return
         */
        snprintf(result, MAX_HANDSHAKE_RESPONSE_LEN, response_template, websocket_accept);
        free(websocket_accept);
        return result;

error:
        if (result != NULL)
                free(result);

        if (websocket_accept != NULL)
                free(websocket_accept);
        return NULL;
}
