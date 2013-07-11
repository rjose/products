#ifndef BASE64_H
#define BASE64_H

#include <stdint.h>

int base64_encode(uint8_t **dst, const uint8_t *src);
int base64_decode(uint8_t **dst, const uint8_t *b64_src);

#endif
