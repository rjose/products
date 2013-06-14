#ifndef LIST_H
#define LIST_H

#include <stdlib.h>

/* ============================================================================
 * Data Structures
 */

/* An element of a list */
typedef struct ListElmt_ {
        void *data;
        struct ListElmt_ *next;
} ListElmt;

/* A linked list */
typedef struct List_ {
        int size;
        int (*match)(const void *key1, const void *key2);
        void (*destroy)(void *data);

        ListElmt *head;
        ListElmt *tail;
} List;


/* ============================================================================
 * Public API
 */

void list_init(List *list, void (*destroy)(void *data));

void list_destroy(List *list);

/* Insert a new ListElmt after 'element' and sets its data to 'data'. If element
 * is NULL, then inserts it at the front of the list as the new head. */
int list_ins_next(List *list, ListElmt *element, const void *data);

/* Removes element after 'element' and points data to its data. If element is
 * NULL, then removes head of list. */
int list_rem_next(List *list, ListElmt *element, void **data);

#define list_size(list) ((list)->size)

#define list_head(list) ((list)->head)

#define list_tail(list) ((list)->tail)

#define list_is_head(list, element) ((element) == (list)->head ? 1 : 0)

#define list_is_tail(list, element) ((element) == (list)->tail ? 1 : 0)

#define list_data(element) ((element)->data)

#define list_next(element) ((element)->next)

#endif
