#include "queue.h"


int queue_enqueue(Queue *queue, const void *data)
{
        /* Add after tail of list */
        return list_ins_next(queue, list_tail(queue), data);
}

int queue_dequeue(Queue *queue, void **data)
{
        /* Remove the head of the list */
        return list_rem_next(queue, NULL, data);
}

