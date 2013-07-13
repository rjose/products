#ifndef WS_H
#define WS_H

#include <stdint.h>

/* ============================================================================ 
 * Data structures
 */

enum WebsocketReadState {WSF_START,
                         WSF_READ_MED_LEN,
                         WSF_READ_LONG_LEN,
                         WSF_READ};

typedef struct WebsocketFrame_ {
        uint8_t *buf;
        size_t buf_len;
        size_t num_read;
        size_t num_to_read;
        enum WebsocketReadState read_state;
} WebsocketFrame;


/* ============================================================================ 
 * Public API
 */

int ws_is_handshake(const char* req_str);

/* 
 * Frame construction
 * ------------------
 */
const uint8_t *ws_make_text_frame(const char *message,
                                                    const uint8_t mask[4]);
const uint8_t *ws_make_close_frame();
const uint8_t *ws_make_ping_frame();
const uint8_t *ws_make_pong_frame();

const uint8_t *ws_extract_message(const uint8_t *frame);

/* 
 * WebsocketFrame functions
 * ------------------------
 */
int ws_init_frame(WebsocketFrame *frame);
int ws_update_read_state(WebsocketFrame *frame);
int ws_extend_frame_buf(WebsocketFrame *frame, size_t more_len);
int ws_append_bytes(WebsocketFrame *frame, uint8_t *src, size_t n);

#endif
