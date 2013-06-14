#ifndef CHTBL_H
#define CHTBL_H

#include <stdlib.h>
#include "list.h"

/* ============================================================================
 * Data Structures
 */

typedef struct CHTbl_ {
        int num_buckets;

        int (*h)(const void *key);
        int (*match)(const void *key1, const void *key2);
        void (*destroy)(void *data);

        int size;
        List *table;
} CHTbl;

/* ============================================================================
 * Public API
 */

int chtbl_init(CHTbl *htbl, int num_buckets, int (*h)(const void *key),
                            int (*match)(const void *key1, const void *key2),
                            void (*destroy)(void *data));

void chtbl_destroy(CHTbl *htbl);

int chtbl_insert(CHTbl *htbl, const void *data);

int chtbl_remove(CHTbl *htbl, void **data);

int chtbl_lookup(const CHTbl *htbl, void **data);

#define chtbl_size(htbl) ((htbl)->size)


#endif
