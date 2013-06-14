#include "chtbl.h"


int chtbl_init(CHTbl *htbl, int num_buckets, int (*h)(const void *key),
                            int (*match)(const void *key1, const void *key2),
                            void (*destroy)(void *data))
{
        int i;

        /*
         * Allocate space for hash table
         */
        if ((htbl->table = (List *)malloc(num_buckets * sizeof(List))) == NULL)
                return -1;

        /*
         * Initialize hash table data
         */
        htbl->num_buckets = num_buckets;
        htbl->h = h;
        htbl->match = match;
        htbl->destroy = destroy;
        htbl->size = 0;

        /*
         * Initialize the buckets
         */
        for (i=0; i < htbl->num_buckets; i++)
                list_init(&htbl->table[i], destroy);

        return 0;
}

void chtbl_destroy(CHTbl *htbl)
{
        int i;

        for (i=0; i < htbl->num_buckets; i++)
                list_destroy(&htbl->table[i]);

        free(htbl->table);
        return;
}

int chtbl_insert(CHTbl *htbl, const void *data)
{
        void *temp;
        int bucket;

        temp = (void *)data;

        /*
         * If element is already in the table, return
         */
        if (chtbl_lookup(htbl, &temp) == 0)
                return 1;

        /*
         * Hash the key
         */
        bucket = htbl->h(data) % htbl->num_buckets;

        /*
         * Insert data into the bucket
         */
        int retval;
        if ((retval = list_ins_next(&htbl->table[bucket], NULL, data)) == 0)
                htbl->size++;

        return retval;
}

int chtbl_remove(CHTbl *htbl, void **data)
{
        ListElmt *element, *prev;
        int bucket;

        /*
         * Hash the key
         */
        bucket = htbl->h(*data) % htbl->num_buckets;

        /*
         * Look for data in bucket
         */
        prev = NULL;
        element = list_head(&htbl->table[bucket]);
        for ( ; element != NULL; element = list_next(element)) {
                if (htbl->match(*data, list_data(element))) {
                        break;
                }
        }

        /*
         * If couldn't find element in table, return -1
         */
        if (element == NULL) {
                return -1;
        }

        /*
         * Remove element from bucket (and thus, table)
         */
        return list_rem_next(&htbl->table[bucket], prev, data);
}

int chtbl_lookup(const CHTbl *htbl, void **data)
{
        ListElmt *element;
        int bucket;

        /*
         * Hash the key
         */
        bucket = htbl->h(*data) % htbl->num_buckets;

        /*
         * Look for data
         */
        element = list_head(&htbl->table[bucket]);
        for ( ; element != NULL; element = list_next(element)) {
                if (htbl->match(*data, list_data(element))) {
                        *data = list_data(element);
                        return 0;
                }
        }

        /*
         * Couldn't find data
         */
        return -1;
}

