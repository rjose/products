#ifndef WS_H
#define WS_H

#include <stdint.h>

extern int ws_is_handshake(const char* req_str);

extern const uint8_t *ws_make_text_frame(const char *message,
                                                    const uint8_t mask[4]);

extern const uint8_t *ws_extract_message(const uint8_t *frame);
#endif
