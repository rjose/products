#include <limits.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>

#include "sort.h"

// TODO: Figure out how to use ctsort here
int rxsort(int *data, int size, int p, int k)
{
        int *counts, *temp;

        int index, pval, i, j, n;

        /*
         * Allocate storage for counts
         */
        if ((counts = (int *)malloc(k * sizeof(int))) == NULL)
                return -1;

        /*
         * Allocate storage for sorted elements
         */
        if ((temp = (int *)malloc(size * sizeof(int))) == NULL)
                return -1;

        /*
         * Sort from least significant to most
         */
        for (n = 0; n < p; n++) {
                for (i = 0; i < k; i++)
                        counts[i] = 0;

                /*
                 * Count occurenes of each digit value
                 */
                pval = (int)pow((double)k, (double)n);
                for (j = 0; j < size; j++) {
                        index = (int)(data[j] / pval) % k;
                        counts[index]++;
                }

                /*
                 * Adjust counts
                 */
                for (i = 1; i < k; i++)
                        counts[i] = counts[i] + counts[i - 1];

                /*
                 * Put elements in position
                 */
                for (j = size - 1; j >= 0; j--) {
                        index = (int)(data[j] / pval) % k;
                        temp[counts[index] - 1] = data[j];
                        counts[index] = counts[index] - 1;
                }

                /*
                 * Copy data so far
                 */
                memcpy(data, temp, size * sizeof(int));
        }

        free(counts);
        free(temp);

        return 0;
}
