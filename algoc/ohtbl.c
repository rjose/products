#include <stdlib.h>
#include <string.h>

#include "ohtbl.h"

/* Used like NULL to indicate that an item was removed. Need this to allow
 * probing to continue over removed elements (they'd stop at NULL) 
 */
static char vacated;

#define is_position_empty(t, i) \
        (t->table[i] == NULL || t->table[i] == &t->vacated)

#define double_hash(t, d, i) \
        ((t->h1(d) + (i * t->h2(d))) % t->num_positions)


int ohtbl_init(OHTbl *htbl, int num_positions,
                          int (*h1)(const void *key),
                          int (*h2)(const void *key),
                          int (*match)(const void *key1, const void *key2),
                          void (*destroy)(void *data))
{
        int i;

        /*
         * Allocate space for hash table
         */
        if ((htbl->table = (void **)malloc(num_positions * sizeof(void *))) ==
                                                                      NULL)
                return -1;

        /*
         * Initialize each position
         */
        htbl->num_positions = num_positions;

        for (i=0; i < htbl->num_positions; i++)
                htbl->table[i] = NULL;

        /*
         * Update fields
         */
        htbl->vacated = &vacated;
        htbl->h1 = h1;
        htbl->h2 = h2;
        htbl->match = match;
        htbl->destroy = destroy;
        htbl->size = 0;

        return 0;
}

void ohtbl_destroy(OHTbl *htbl)
{
        int i;
        
        /*
         * Destroy elements in table
         */
        if (htbl->destroy != NULL) {

                for (i=0; i < htbl->num_positions; i++) {
                        if (!is_position_empty(htbl, i))
                                htbl->destroy(htbl->table[i]);
                }
        }

        /*
         * Clean up hash table
         */
        free(htbl->table);
        memset(htbl, 0, sizeof(OHTbl));
        return;
}

int ohtbl_insert(OHTbl *htbl, const void *data)
{
        void *temp;
        int i, position;

        /*
         * If table's full, return
         */
        if (htbl->size == htbl->num_positions)
                return -1;

        /*
         * If already in the table, do nothing
         */
        temp = (void *)data;
        if (ohtbl_lookup(htbl, &temp) == 0)
                return 1;

        /*
         * Double hash the key and insert data in empty slot
         */
        for (i=0; i < htbl->num_positions; i++) {
                position = double_hash(htbl, data, i);

                if (is_position_empty(htbl, position)) {
                        htbl->table[position] = (void *) data;
                        htbl->size++;
                        return 0;
                }
        }

        return -1;
}

int ohtbl_remove(OHTbl *htbl, void **data)
{
        int i, position;

        /*
         * Double hash to find element
         */
        for (i=0; i < htbl->num_positions; i++) {
                position = double_hash(htbl, data, i);

                /*
                 * There are three cases:
                 * 
                 *    1. Slot is NULL (i.e., couldn't find it)
                 *    2. Slot is vacated
                 *    3. Slot matches data
                 */
                if (htbl->table[position] == NULL) {
                        return -1;
                }
                else if (htbl->table[position] == htbl->vacated) {
                        continue;
                }
                else if (htbl->match(htbl->table[position], *data)) {
                        *data = htbl->table[position];
                        htbl->table[position] = htbl->vacated;
                        htbl->size--;
                        return 0;
                }
        }
        return -1;
}

int ohtbl_lookup(const OHTbl *htbl, void **data)
{
        int i, position;

        for (i = 0; i < htbl->num_positions; i++) {
                position = double_hash(htbl, *data, i);
                if (htbl->table[position] == NULL) {
                        return -1;
                }
                else if (htbl->match(htbl->table[position], *data)) {
                        *data = htbl->table[position];
                        return 0;
                }
        }

        /*
         * Couldn't find it
         */
        return -1;
}
