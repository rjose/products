#ifndef TAG_H
#define TAG_H

#include "assoc_array.h"

// TODO: Add some documentation
typedef enum {
        TAG_LONG, TAG_DOUBLE
} tag_val_type;

typedef struct Tag_ {
        char *key;
        char *val;
        tag_val_type type;
        union {
                long lval;
                double dval;
        } v;

        // TODO: Get rid of this
        struct Tag_ *next;
} Tag;

int tag_parse_string(const char *tag_string, AssocArray *result);
int tag_store_value(Tag *tag, tag_val_type type);
int Tag_free(Tag **tags);

#endif
