#ifndef CLIST_H
#define CLIST_H

#include <stdlib.h>

/* ============================================================================
 * Data Structures
 */

/* An element of a circular list */
typedef struct CListElmt_ {
	void *data;
	struct CListElmt_ *next;
} CListElmt;


typedef struct CList_ {
	int size;
	int (*match)(const void *key1, const void *key2);
	void (*destroy)(void *data);

	CListElmt *head;
} CList;

/* ============================================================================
 * Public API
 */

void clist_init(CList *list, void (*destroy)(void *data));

void clist_init_with_match(CList *list,
                           int (*match)(const void *key1, const void *key2),
                           void (*destroy)(void *data));

void clist_destroy(CList *list);

int clist_ins_next(CList *list, CListElmt *element, const void *data);

int clist_rem_next(CList *list, CListElmt *element, void **data);

#define clist_size(list) ((list)->size)

#define clist_head(list) ((list)->head)

#define clist_is_head(list, element) ((element) == (list)->head ? 1 : 0)

#define clist_data(element) ((element)->data)

#define clist_next(element) ((element)->next)

#endif
