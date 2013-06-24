#include <stdlib.h>
#include <string.h>

#include "sort.h"

int ctsort(int *data, int size, int k)
{
        int *counts, *temp;
        int i, j;

        /*
         * Allocate space for counts
         */
        if ((counts = (int *)malloc(k * sizeof(int))) == NULL)
                return -1;

        /*
         * Allocate storage for sorted elements
         */
        if ((temp = (int *)malloc(size * sizeof(int))) == NULL)
                return -1;

        /*
         * Initialize the counts
         */
        for (i = 0; i < k; i++)
                counts[i] = 0;

        /*
         * Count occurences of each element
         */
        for (j = 0; j < size; j++)
                counts[data[j]]++;

        /*
         * Compute running totals to use for item indices
         */
        for (i = 1; i < k; i++)
                counts[i] = counts[i] + counts[i - 1];

        /*
         * Use counts to place element in position
         */
        for (j = size - 1; j >= 0; j--) {
                temp[counts[data[j]] - 1] = data[j];
                counts[data[j]]--;
        }

        /*
         * Copy result over and free storage
         */
        memcpy(data, temp, size * sizeof(int));
        free(counts);
        free(temp);
        return 0;
}
