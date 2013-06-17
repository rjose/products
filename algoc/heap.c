#include <stdlib.h>
#include <string.h>

#include "heap.h"

/* ============================================================================
 * Private macros
 */

#define heap_parent(npos) ((int)(((npos) - 1) / 2))

#define heap_left(npos) (((npos) * 2) + 1)

#define heap_right(npos) (((npos) * 2) + 2)


void heap_init(Heap *heap, int (*compare)(const void *key1, const void *key2),
                                                   void (*destroy)(void *data))
{
        heap->size = 0;
        heap->compare = compare;
        heap->destroy = destroy;
        heap->tree = NULL;
        return;
}

void heap_destroy(Heap *heap)
{
        int i;

        /*
         * Destroy application data
         */
        if (heap->destroy != NULL) {
                for (i = 0; i < heap_size(heap); i++)
                        heap->destroy(heap->tree[1]);
        }

        /*
         * Free heap and clean up
         */
        free(heap->tree);
        memset(heap, 0, sizeof(Heap));

        return;
}

int heap_insert(Heap *heap, const void *data)
{
        void *temp;

        int ipos, ppos;

        /*
         * Allocate storage for node
         */
        if ((temp = (void **)realloc(heap->tree, (heap_size(heap) + 1) *
                                                       sizeof(void *))) == NULL)
                return -1;

        heap->tree = temp;

        /*
         * Insert node at end
         */
        heap->tree[heap_size(heap)] = (void *)data;

        /*
         * Heapify by swapping node upwards as necessary
         */
        ipos = heap_size(heap);
        ppos = heap_parent(ipos);
        while (ipos > 0 &&
                        heap->compare(heap->tree[ppos], heap->tree[ipos]) < 0) {
                temp = heap->tree[ppos];
                heap->tree[ppos] = heap->tree[ipos];
                heap->tree[ipos] = temp;

                ipos = ppos;
                ppos = heap_parent(ipos);
        }

        /*
         * Update heap stats
         */
        heap->size++;

        return 0;
}


int heap_extract(Heap *heap, void **data)
{
        void *save, *temp;
        int ipos, lpos, rpos, mpos;

        if (heap_size(heap) == 0)
                return -1;

        *data = heap->tree[0];
        save = heap->tree[heap_size(heap) - 1];

        /*
         * Adjust heap storage. There are two cases:
         *
         *   1. Only one node left
         *   2. More than one node left
         */

        /* Case 1: Only one left */
        if (heap_size(heap) - 1 == 0) {
                free(heap->tree);
                heap->tree = NULL;
                heap->size = 0;
                return 0;
        }

        /* Case 2: More than 1 left */
        if ((temp = (void **)realloc(heap->tree,(heap_size(heap) - 1) *
                                               sizeof(void *))) == NULL)
                return -1;
        heap->tree = temp;
        heap->size--;

        /*
         * Copy last node to top and then heapify
         */
        heap->tree[0] = save;
        ipos = 0;
        while (1) {
                lpos = heap_left(ipos);
                rpos = heap_right(ipos);

                /* 
                 * Find position with max value. First check left child...
                 */
                if (lpos < heap_size(heap) &&
                          heap->compare(heap->tree[lpos], heap->tree[ipos]) > 0)
                        mpos = lpos;
                else
                        mpos = ipos;

                /* ...then check right child */
                if (rpos < heap_size(heap) &&
                          heap->compare(heap->tree[rpos], heap->tree[mpos]) > 0)
                        mpos = rpos;

                /* If the max position is the insert position, we're done. */
                if (mpos == ipos)
                        break;

                /* otherwise, keep going */
                temp = heap->tree[mpos];
                heap->tree[mpos] = heap->tree[ipos];
                heap->tree[ipos] = temp;
                ipos = mpos;
        }

        return 0;
}
