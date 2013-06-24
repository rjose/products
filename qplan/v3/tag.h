#ifndef TAG_H
#define TAG_H

// TODO: Add some documentation
typedef enum {
        LONG, DOUBLE
} tag_val_type;

typedef struct Tag_ {
        char *key;
        char *val;
        tag_val_type type;
        union {
                long lval;
                double dval;
        } v;

        struct Tag_ *next;
} Tag;

int Tag_parse_string(const char *tag_string, Tag **tags);
int Tag_store_value(Tag *tag, tag_val_type type);
int Tag_free(Tag **tags);

#endif
