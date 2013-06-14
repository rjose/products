#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include "dlist.h"

/* ============================================================================
 * Initialize a DList
 */
void dlist_init(DList *list, void (*destroy)(void *data))
{
        list->size = 0;
        list->destroy = destroy;
        list->head = NULL;
        list->tail = NULL;

	list->match = NULL;
        return;
}

void dlist_init_with_match(DList *list,
                           int (*match)(const void *key1, const void *key2),
                           void (*destroy)(void *data))
{
        list->size = 0;
        list->destroy = destroy;
	list->match = match;
        list->head = NULL;
        list->tail = NULL;
}

void dlist_destroy(DList *list)
{
        /* Will point to data payload to be removed for each element */
        void *data;

        /* Remove each element (and its payload) */
        while (dlist_size(list) > 0) {

		if (dlist_remove(list, dlist_tail(list), (void **)&data) != 0) {
			fprintf(stderr, "Problem removing element from dlist\n");
			return;
		}

		if (list->destroy != NULL)
			list->destroy(data);
        }

        /* Zero list out */
        memset(list, 0, sizeof(DList));

	return;
}

/* Insert a new DListElmt after 'element' and sets its data to 'data'. If element
 * is NULL, then inserts it at the front of the list as the new head. */
int dlist_ins_next(DList *list, DListElmt *element, const void *data)
{
        DListElmt *new_element;

        /*
         * Only allow element to be NULL if the list is empty
         */
	if (element == NULL && dlist_size(list) != 0)
		return -1;

        /*
         * Allocate storage for element and set payload
         */
        if ((new_element = (DListElmt *)malloc(sizeof(DListElmt))) == NULL)
                return -1;

        new_element->data = (void *) data;

	/*
	 * Insert element into list
	 */
	if (dlist_size(list) == 0) {	/* Case 1: List is empty */
		new_element->next = NULL;
		new_element->prev = NULL;

		list->head = new_element;
		list->tail = new_element;
	}
	else {				/* Case 2: List is not empty */
		/* Hook up new_element */
		new_element->next = element->next;
		new_element->prev = element;

		/* Hook up element */
		element->next = new_element;

		/* Hook up next element and update tail if necessary*/
		if (dlist_is_tail(list, element))
			list->tail = new_element;
		else
			new_element->next->prev = new_element;
	}


        /*
         * Update list stats
         */
        list->size++;

        return 0;
}

int dlist_ins_prev(DList *list, DListElmt *element, const void *data)
{
        DListElmt *new_element;

        /*
         * Only allow element to be NULL if the list is empty
         */
	if (element == NULL && dlist_size(list) != 0)
		return -1;

        /*
         * Allocate storage for element and set payload
         */
        if ((new_element = (DListElmt *)malloc(sizeof(DListElmt))) == NULL)
                return -1;

        new_element->data = (void *) data;

	/*
	 * Insert element into list
	 */
	if (dlist_size(list) == 0) {	/* Case 1: List is empty */
		new_element->next = NULL;
		new_element->prev = NULL;

		list->head = new_element;
		list->tail = new_element;
	}
	else {				/* Case 2: List is not empty */
		/* Hook up new_element */
		new_element->prev = element->prev;
		new_element->next = element;

		/* Hook up element */
		element->prev = new_element;

		/* Hook up next element and update head if necessary*/
		if (dlist_is_head(list, element))
			list->head = new_element;
		else
			new_element->prev->next = new_element;
	}

	return 0;
}

int dlist_remove(DList *list, DListElmt *element, void **data)
{
	if (dlist_size(list) == 0 || element == NULL)
		return -1;

	/*
	 * Store data for DListElmt to be removed
	 */
	*data = element->data;


	/*
	 * Remove element. There are four cases:
	 *
	 * 1. One element in list
	 * 2. Head of list
	 * 3. Tail of list
	 * 4. Middle of list
	 */
	if (dlist_size(list) == 1) {			/* Case 1: One element is list */
		list->head = NULL;
		list->tail = NULL;
	}
	else if (dlist_is_head(list, element)) {	/* Case 2: Element is head */
		list->head = element->next;
		list->head->prev = NULL;
	}
	else if (dlist_is_tail(list, element)) {	/* Case 3: Element is tail */
		list->tail = element->prev;
		list->tail->next = NULL;
	}
	else {						/* Case 4: Element is in middle */
		element->prev->next = element->next;
		element->next->prev = element->prev;
	}

        /*
         * Free memory
         */
        free(element);

        /*
         * Update list stats
         */
        list->size--;

        return 0;
}

#define dlist_size(list) ((list)->size)

#define dlist_head(list) ((list)->head)

#define dlist_tail(list) ((list)->tail)

#define dlist_is_head(list, element) ((element) == (list)->head ? 1 : 0)

#define dlist_is_tail(list, element) ((element) == (list)->tail ? 1 : 0)

#define dlist_data(element) ((element)->data)

#define dlist_next(element) ((element)->next)

#define dlist_prev(element) ((element)->prev)

