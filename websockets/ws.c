#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#include <openssl/sha.h>

#include "ws.h"

#define MAX_HANDSHAKE_RESPONSE_LEN 300
#define MAX_WEBSOCKET_KEY_LEN 40
#define SEC_WEBSOCKET_KEY "Sec-WebSocket-Key"
#define SEC_WEBSOCKET_KEY_LEN 17
#define BUF_LENGTH 200

#define SHORT_MESSAGE_LEN 125
#define MED_MESSAGE_LEN 0xFFFF 
#define MED_MESSAGE_KEY 126
#define LONG_MESSAGE_KEY 127


#define MASK_OFFSET 2

/* Byte 0 of websocket frame */
#define WS_FRAME_FIN 0x80
#define WS_FRAME_OP_CONT 0x00
#define WS_FRAME_OP_TEXT 0x01
#define WS_FRAME_OP_BIN 0x02
#define WS_FRAME_OP_CLOSE 0x08
#define WS_FRAME_OP_PING 0x09
#define WS_FRAME_OP_PONG 0x0A

/* Byte 1 of websocket frame */
#define WS_FRAME_MASK 0x80

/*
 * Declare static functions
 */
static void err_abort(int, const char *);
static int get_ws_key(char *, size_t, const char *);
static uint8_t toggle_mask(uint8_t, size_t, const uint8_t [4]);

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
	uint8_t sha_digest[SHA_DIGEST_LENGTH];
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
	SHA1((const uint8_t*)buf, strlen(buf), sha_digest);

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

static uint8_t toggle_mask(uint8_t c, size_t index, const uint8_t mask[4])
{
        uint8_t result = c;
        if (mask)
                result = c ^ mask[index % 4];

        return result;
}


/*
 * NOTE: This function will always set the FIN bit to 1. If you want to send
 * fragments, set this to 0 once you get the frame back.
 */
const uint8_t *ws_make_text_frame(const char *message, const uint8_t mask[4])
{
        uint64_t i;
        size_t message_len;
        size_t mask_len;
        size_t num_len_bytes; /* Number of extended payload len bytes */
        uint8_t byte0, byte1;     /* First two bytes of the frame */
        uint64_t tmp;
        size_t frame_len;
        uint8_t *result = NULL;

        /* We know this is a text frame */
        byte0 = WS_FRAME_OP_TEXT;
        byte0 |= WS_FRAME_FIN;

        /* If a mask is specified, set the mask bit */
        byte1 = mask ? WS_FRAME_MASK : 0;

        /*
         * Figure out the length of the frame and then allocate memory. This
         * involves figuring out if we need a mask, if we need extra length
         * bytes, and how big the message is.
         */
        mask_len = mask ? 4 : 0;
        message_len = strlen(message);
        if (message_len <= SHORT_MESSAGE_LEN) {
                num_len_bytes = 0;
                byte1 |= message_len;
        }
        else if (message_len > SHORT_MESSAGE_LEN &&
                                               message_len <= MED_MESSAGE_LEN) {
                num_len_bytes = 2;
                byte1 |= MED_MESSAGE_KEY;
        }
        else {
                num_len_bytes = 8;
                byte1 |= LONG_MESSAGE_KEY;
        }
        frame_len = 2 + num_len_bytes + mask_len + message_len;
        if ((result = (uint8_t *)malloc(frame_len)) == NULL)
                err_abort(-1, "Can't allocate memory for ws_make_text_frame");

        /*
         * Write data into the frame. First, we'll write the first 2 bytes
         * that we've constructed. After this comes the extended payload
         * length (if needed). After that is the mask (if needed). Finally, we
         * write our message.
         */
        result[0] = byte0;
        result[1] = byte1;

        /* Write extended length */
        tmp = message_len;
        for (i = num_len_bytes; i > 0; i--) {
                result[2 + i - 1] = tmp & 0xFF;
                tmp = message_len >> 8;
        }
        
        /* Write mask */
        if (mask)
                for (i = 0; i < mask_len; i++)
                        result[2 + num_len_bytes + i] = mask[i];

        /* Write message */
        for (i = 0; i < message_len; i++) {
                result[2 + num_len_bytes + mask_len + i] =
                                       toggle_mask(message[i], i, mask);
        }

        return result;
}

const uint8_t *ws_extract_message(const uint8_t *frame)
{
        uint8_t byte0;
        uint8_t byte1;
        uint64_t message_len;
        uint8_t *mask = NULL;
        uint64_t i;
        uint8_t message_start;
        uint8_t *result;

        /* Only handling TEXT or BIN frames */
        byte0 = frame[0];
        if (!(byte0 | WS_FRAME_OP_TEXT || byte0 | WS_FRAME_OP_BIN))
                return NULL;

        /* Check mask and length */
        byte1 = frame[1];
        message_len = byte1 & ~WS_FRAME_MASK;

        /* Handle short messages */
        if (message_len <= SHORT_MESSAGE_LEN) {
                message_start = 2;      /* After first 2 bytes */

                if (byte1 & WS_FRAME_MASK) {
                        mask = frame + MASK_OFFSET;
                        message_start = 6;      /* Starts after mask */
                }

                if ((result = (uint8_t *)malloc(message_len + 1)) == NULL)
                        err_abort(-1,
                             "Couldn't allocate result for ws_extract_message");

                for (i = 0; i < message_len; i++)
                        result[i] = toggle_mask(frame[message_start+i], i, mask);
        }
        // TODO: Handle medium and long messages

        /* Add NUL if text frame */
        if (byte0 | WS_FRAME_OP_TEXT)
                result[message_len] = '\0';

        return result;
}
