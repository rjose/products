#ifndef TEST_UTIL_H
#define TEST_UTIL_H

extern int check_response(const char* response_str, const char *accept_key);
extern int check_frame(const uint8_t *, size_t, const uint8_t *);

#endif
