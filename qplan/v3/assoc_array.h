#ifndef ASSOC_ARRAY_H
#define ASSOC_ARRAY_H


typedef enum {
        STRING
} aa_key_type;


typedef enum {
        LONG, DOUBLE, STRING, VOID
} aa_val_type;

typedef struct AssocArrayKey_ {
        aa_key_type key_type;
        union {
                char *sval;
        } k;
} AssocArrayKey;

typedef struct AssocArrayVal_ {
        aa_val_type val_type;
        union {
                long lval;
                double dval;
                char *sval;
                void *vval;
        } v;
} AssocArrayVal;


typedef struct AssocArrayElem_ {
        AssocArrayKey key;
        AssocArrayVal val;
} AssocArrayElem;


typedef struct AssocArray_ {
        int num_elements;
        AssocArrayElem *elements;
} AssocArray;


void aa_init(AssocArray *array);

/* TODO: Figure out how to reduce these properly */

#endif
