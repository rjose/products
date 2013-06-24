#include <stdlib.h>
#include <string.h>

#include "sort.h"

static int merge(void *data, int esize, int i, int j, int k,
                             int (*compare)(const void *key1, const void *key2))
{
        char *a = data, *m;

        int ipos, jpos, mpos;

        ipos = i;
        jpos = j + 1;
        mpos = 0;

        /*
         * Allocate storage for merged elements
         */
        if ((m = (char *)malloc(esize * ((k - i) + 1))) == NULL)
                return -1;

        while (ipos <= j || jpos <= k) {
                /*
                 * If either division is empty, copy the other division into position
                 */
                if (ipos > j) {
                        while (jpos <= k) {
                                memcpy(&m[mpos * esize], &a[jpos * esize], esize);
                                jpos++;
                                mpos++;
                        }
                        continue;
                }
                else if (jpos > k) {
                                memcpy(&m[mpos * esize], &a[ipos * esize], esize);
                                ipos++;
                                mpos++;
                        continue;
                }

                /*
                 * Otherwise, copy the smaller element over
                 */
                if (compare(&a[ipos * esize], &a[jpos * esize]) < 0) {
                        memcpy(&m[mpos * esize], &a[ipos * esize], esize);
                        ipos++;
                        mpos++;
                }
                else {
                        memcpy(&m[mpos * esize], &a[jpos * esize], esize);
                        jpos++;
                        mpos++;
                }
        }

        /*
         * Copy the merged data back and then clean up.
         */
        memcpy(&a[i * esize], m, esize * ((k - i) + 1));

        free(m);
        return 0;
}

int mgsort(void *data, int esize, int i, int k,
                             int (*compare)(const void *key1, const void *key2))
{
        int j;

        /*
         * Only recurse if i is to the left of k
         */
        if (i < k) {
                j = (int)((i + k - 1) / 2);

                if (mgsort(data, esize, i, j, compare) < 0)
                        return -1;

                if (mgsort(data, esize, j + 1, k, compare) < 0)
                        return -1;

                if (merge(data, esize, i, j, k, compare) < 0)
                        return -1;
        }

        return 0;
}
