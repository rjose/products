#include <stdlib.h>
#include <string.h>

#include "sort.h"

static int compare_int(const void *int1, const void *int2)
{
        if (*(const int *)int1 > *(const int *)int2)
                return 1;
        else if (*(const int *)int1 < *(const int *)int2)
                return -1;
        else
                return 0;
}

static int partition(void *data, int esize, int i, int k,
                             int (*compare)(const void *key1, const void *key2))
{
        char *a = data;
        void *pval, *temp;
        int j;
        int r[3];

        if ((pval = malloc(esize)) == NULL)
                return -1;

        if ((temp = malloc(esize)) == NULL) {
                free(pval);
                return -1;
        }

        /*
         * Find partition
         */
        for (j = 0; j < 3; j++)
                r[j] = (rand() % (k - i + 1)) + i;
        issort(r, 3, sizeof(int), compare_int);
        memcpy(pval, &a[r[1] * esize], esize);

        /* Move indices off the array */
        i--;
        k++;

        while(1) {
                /*
                 * Move left until element is in wrong partition
                 */
                do {
                        k--;
                } while (compare(&a[k * esize], pval) > 0);

                /*
                 * Move right until element is in wrong partition
                 */
                do {
                        i++;
                } while (compare(&a[i * esize], pval) < 0);

                if (i >= k)
                        break;
                else {
                        /*
                         * Swap elements
                         */
                        memcpy(temp, &a[i * esize], esize);
                        memcpy(&a[i * esize], &a[k * esize], esize);
                        memcpy(&a[k * esize], temp, esize);
                }
        }

        free(pval);
        free(temp);

        return k;
}

int qksort(void *data, int size, int esize, int i, int k,
                             int (*compare)(const void *key1, const void *key2))
{
        int j;

        while (i < k) {
                if ((j = partition(data, esize, i, k, compare)) < 0)
                        return -1;

                if (qksort(data, size, esize, i, j, compare) < 0)
                        return -1;

                /* Set up to sort the right partition */
                i = j + 1;
        }
        return 0;
}
