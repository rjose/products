#ifndef WS_H
#define WS_H

extern int ws_is_handshake(const char* req_str);

extern const unsigned char *ws_make_text_frame(const char *message,
                                                              const char *mask);

#endif
