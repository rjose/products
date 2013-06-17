#include <stdlib.h>
#include <string.h>

#include "graph.h"


void graph_init(Graph *graph, int (*match)(const void *key1, const void *key2),
                                                   void (*destroy)(void *data))
{
        graph->vcount = 0;
        graph->ecount = 0;
        graph->match = match;
        graph->destroy = destroy;

        /*
         * Initialize adjacency lists
         */
        list_init(&graph->adjlists, NULL);
        return;
}

void graph_destroy(Graph *graph)
{
        AdjList *adjlist;

        while (list_size(&graph->adjlists) > 0) {
                if (list_rem_next(&graph->adjlists, NULL,
                                                    (void **)&adjlist) == 0) {
                        set_destroy(&adjlist->adjacent);

                        if (graph->destroy != NULL)
                                graph->destroy(adjlist->vertex);

                        free(adjlist);
                }
        }

        /*
         * Destroy adjacency list structures (now empty)
         */
        list_destroy(&graph->adjlists);
        memset(graph, 0, sizeof(Graph));
        return;
}

int graph_ins_vertex(Graph *graph, const void *data)
{
        ListElmt *element;
        AdjList *adjlist;
        List *list;
        int retval;

        /*
         * Make sure we don't add a duplicate vertex
         */
        element = list_head(&graph->adjlists);
        for ( ; element != NULL; element = list_next(element)) {
                adjlist = ((AdjList *)list_data(element));
                if (graph->match(data, adjlist->vertex))
                        return 1;
        }

        /*
         * Insert the vertex
         */
        if ((adjlist = (AdjList *)malloc(sizeof(AdjList))) == NULL)
                return -1;

        adjlist->vertex = (void *)data;
        set_init(&adjlist->adjacent, graph->match, NULL);

        list = &graph->adjlists;
        if ((retval = list_ins_next(list, list_tail(list), adjlist)) != 0)
                return retval;

        /*
         * Update graph stats
         */
        graph->vcount++;

        return 0;
}

int graph_ins_edge(Graph *graph, const void *data1, const void *data2)
{
        ListElmt *element;
        Set *adjacent;
        AdjList *adjlist;
        int retval;

        /*
         * Make sure both vertices are in graph first
         */
        element = list_head(&graph->adjlists);
        for ( ; element != NULL; element = list_next(element)) {
                adjlist = ((AdjList *)list_data(element));

                if (graph->match(data2, adjlist->vertex))
                        break;
        }

        element = list_head(&graph->adjlists);
        for ( ; element != NULL; element = list_next(element)) {
                adjlist = ((AdjList *)list_data(element));

                if (graph->match(data1, adjlist->vertex))
                        break;
        }

        if (element == NULL)
                return -1;

        /*
         * Insert the second vertex into the adjacency list of the first
         */

        /* NOTE: At this point "element" points to the first vertex */
        adjacent = &((AdjList *)list_data(element))->adjacent;
        if ((retval = set_insert(adjacent, data2)) != 0)
                return retval;

        /*
         * Update graph stats
         */
        graph->ecount++;

        return 0;
}

int graph_rem_vertex(Graph *graph, void **data)
{
        ListElmt *element, *temp, *prev;
        AdjList *adjlist;
        int found;

        temp = NULL;
        prev = NULL;
        found = 0;

        /*
         * Check the key vertex in each adjacency list. If we find the vertex in
         * one of the adjacency sets for a key vertex, return (since there's an
         * existing edge).
         */
        element = list_head(&graph->adjlists);
        for ( ; element != NULL; element = list_next(element)) {
                if (set_is_member(&((AdjList *)list_data(element))->adjacent,
                                                                         *data))
                        return -1;

                if (graph->match(*data,
                                    ((AdjList *)list_data(element))->vertex)) {
                        temp = element;
                        found = 1;
                }

                /* Keep track of the vertex before the element to be removed */
                if (!found)
                        prev = element;
        }

        /*
         * If didn't find it, return
         */
        if (!found)
                return -1;

        /*
         * If there are existing edges incident from our vertex, just return
         */
        if (set_size(&((AdjList *)list_data(temp))->adjacent) > 0)
                return -1;

        /*
         * Remove the vertex
         */
        if (list_rem_next(&graph->adjlists, prev, (void **)&adjlist) != 0)
                return -1;

        *data = adjlist->vertex;

        /*
         * Free storage and clean up
         */
        free(adjlist);

        /*
         * Update graph stats
         */
        graph->vcount--;

        return 0;
}

int graph_rem_edge(Graph *graph, void *data1, void **data2)
{
        ListElmt *element;

        /*
         * Find adjacency list for first vertex
         */
        element = list_head(&graph->adjlists);
        for ( ; element != NULL; element = list_next(element)) {
                if (graph->match(data1,
                                       ((AdjList *)list_data(element))->vertex))
                        break;
        }

        if (element == NULL)
                return -1;

        /*
         * Remove the second vertex from the adjacency list of the first
         */
        if (set_remove(&((AdjList *)list_data(element))->adjacent, data2) != 0)
                return -1;

        /*
         * Update graph stats
         */
        graph->ecount--;

        return 0;
}

int graph_adjlist(const Graph *graph, const void *data, AdjList **adjlist)
{
        ListElmt *element, *prev;

        element = list_head(&graph->adjlists);
        for ( ; element != NULL; element = list_next(element)) {
                if (graph->match(data, ((AdjList *)list_data(element))->vertex))
                        break;

                prev = element;
        }

        if (element == NULL)
                return -1;

        /*
         * Set result
         */
        *adjlist = list_data(element);

        return 0;
}

int graph_is_adjacent(const Graph *graph, const void *data1,
                                                        const void *data2)
{
        AdjList *adjlist;

        if (graph_adjlist(graph, data1, &adjlist) != 0)
                return 0;

        return set_is_member(&adjlist->adjacent, data2);
}

