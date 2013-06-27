#include <stdlib.h>
#include <string.h>

int issort(void *data, int size, int esize,
                             int (*compare)(const void *key1, const void *key2))
{
        char *a = data;         /* Used for copying byte-by-byte */
        void *key;
        int i, j;

        if ((key = (char *)malloc(esize)) == NULL)
                return -1;

        /*
         * Items to the left of "j" are sorted. Items to the right, including
         * "j" are unsorted.
         */
        for (j = 1; j < size; j++) {
                memcpy(key, &a[j * esize], esize);

                /*
                 * Go through sorted items starting just to the left of "j"
                 * and move elements one spot to the right until we find the
                 * right slot for the "j" item.
                 */
                i = j - 1;
                while (i >= 0 && compare(&a[i * esize], key) > 0) {
                        memcpy(&a[(i + 1) * esize], &a[i * esize], esize);
                        i--;
                }

                /*
                 * Copy "j" item into position
                 */
                memcpy(&a[(i + 1) * esize], key, esize);
        }

        free(key);
        return 0;
}
