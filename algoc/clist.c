#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include "clist.h"

/* ============================================================================
 * Initialize a List
 */
void clist_init(CList *list, void (*destroy)(void *data))
{
        list->size = 0;
        list->destroy = destroy;
        list->head = NULL;

	list->match = NULL;
        return;
}

void clist_init_with_match(CList *list,
                           int (*match)(const void *key1, const void *key2),
                           void (*destroy)(void *data))
{
        list->size = 0;
        list->destroy = destroy;
        list->head = NULL;

	list->match = match;
        return;
}

void clist_destroy(CList *list)
{
        /* Will point to data payload to be removed for each element */
        void *data;

        /* Remove each element (and its payload) */
        while (clist_size(list) > 0) {

		if (clist_rem_next(list, NULL, (void **)&data) != 0) {
			fprintf(stderr, "Problem removing element from CList\n");
			return;
		}

		if (list->destroy != NULL)
			list->destroy(data);
        }

        /* Zero list out */
        memset(list, 0, sizeof(CList));

	return;
}

int clist_ins_next(CList *list, CListElmt *element, const void *data)
{
        CListElmt *new_element;

        /*
         * Allocate storage for element and set payload
         */
        if ((new_element = (CListElmt *)malloc(sizeof(CListElmt))) == NULL)
                return -1;

        new_element->data = (void *) data;

	/*
	 * Insert new_element after element
	 */
	if (clist_size(list) == 0) { 			/* Case 1: List is empty */
		new_element->next = new_element;
		list->head = new_element;
	}
	else { 						/* Case 2: List is not empty */
		new_element->next = element->next;
		element->next = new_element;
	}

        /*
         * Update list stats
         */
        list->size++;

        return 0;
}

int clist_rem_next(CList *list, CListElmt *element, void **data)
{
        CListElmt *old_element;

        if (clist_size(list) == 0 || element == NULL)
                return -1;

	*data = element->next->data;

	/*
	 * Remove element after "element"
	 */
	if (clist_size(list) == 1) { 	 	/* Case 1: List has one element */
		old_element = element;
		list->head = NULL;
	}
	else { 					/* Case 2: Multiple elements */
		old_element = element->next;
		element->next = old_element->next;

		if (clist_is_head(list, old_element))
			list->head = element->next;
	}

        /*
         * Free storage
         */
        free(old_element);

        /*
         * Update list stats
         */
        list->size--;

        return 0;
}

#define clist_size(list) ((list)->size)

#define clist_head(list) ((list)->head)

#define clist_is_head(list, element) ((element) == (list)->head ? 1 : 0)

#define clist_data(element) ((element)->data)

#define clist_next(element) ((element)->next)

