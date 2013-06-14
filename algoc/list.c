#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include "list.h"

/* ============================================================================
 * Initialize a List
 */
void list_init(List *list, void (*destroy)(void *data))
{
        list->size = 0;
        list->destroy = destroy;
        list->head = NULL;
        list->tail = NULL;

	list->match = NULL;
        return;
}

void list_init_with_match(List *list, void (*destroy)(void *data),
     			       int (*match)(const void *key1, const void *key2))
{
        list->size = 0;
        list->destroy = destroy;
	list->match = match;
        list->head = NULL;
        list->tail = NULL;
        return;
}

/* ============================================================================
 * Destroy a List
 */
void list_destroy(List *list)
{
        /* Will point to data payload to be removed for each element */
        void *data;

        /* Remove each element (and its payload) */
        while (list_size(list) > 0) {

		if (list_rem_next(list, NULL, (void **)&data) != 0) {
			fprintf(stderr, "Problem removing element from dlist\n");
			return;
		}

		if (list_destroy != NULL)
			list->destroy(data);
        }

        /* Zero list out */
        memset(list, 0, sizeof(List));

	return;
}

/* ============================================================================
 * Insert after element
 */
int list_ins_next(List *list, ListElmt *element, const void *data)
{
        ListElmt *new_element;

        /*
         * Allocate storage for element and set payload
         */
        if ((new_element = (ListElmt *)malloc(sizeof(ListElmt))) == NULL)
                return -1;

        new_element->data = (void *) data;

        /*
         * Insert new_element after element
         */
        if (element == NULL) {          /* Handle insertion at head of list */
                new_element->next = list->head;
                list->head = new_element;

                if (list_size(list) == 0)
                        list->tail = new_element;
        }
        else {                          /* Handle insertion somewhere after head */
                new_element->next = element->next;
                element->next = new_element;

                if (list_is_tail(list, element))
                        list->tail = new_element;
        }

        /*
         * Update list stats
         */
        list->size++;

        return 0;
}


/* ============================================================================
 * Remove after element
 */
int list_rem_next(List *list, ListElmt *element, void **data)
{
        ListElmt *old_element;

        if (list_size(list) == 0)
                return -1;

        /*
         * Remove element after "element"
         */
        if (element == NULL) {          /* Handle removing head */
                old_element = list->head;
                list->head = old_element->next;

                *data = old_element->data;

                /* If this is the last element, then the tail should be NULL */
                if (list_size(list) == 1)
                        list->tail = NULL;
        }
        else {                          /* Handle removal somewhere after head */
                if (list_is_tail(list, element))
                        return -1;

                old_element = element->next;
                element->next = old_element->next;

                *data = old_element->data;

                if (list_is_tail(list, old_element))
                        list->tail = element;
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
