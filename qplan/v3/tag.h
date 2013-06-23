#ifndef TAG_H
#define TAG_H

typedef enum {
        INT, FLOAT
} tag_val_type;

typedef struct Tag_ {
        char *key;
        char *val;
        tag_val_type type;
        union {
                int ival;
                double dval;
        } v;

        struct Tag_ *next;
} Tag;

int Tag_parse_string(const char *tag_string, Tag **tags);

#endif
