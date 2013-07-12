#ifndef WS_H
#define WS_H

#include <stdint.h>

int ws_is_handshake(const char* req_str);

const uint8_t *ws_make_text_frame(const char *message,
                                                    const uint8_t mask[4]);

const uint8_t *ws_make_close_frame();
const uint8_t *ws_make_ping_frame();
const uint8_t *ws_make_pong_frame();

const uint8_t *ws_extract_message(const uint8_t *frame);

#endif
