#include <float.h>
#include <stdlib.h>

#include "graph.h"
#include "graphalg.h"
#include "list.h"

int mst(Graph *graph, const MstVertex *start, List *span,
                               int (*match)(const void *key1, const void *key2))
{
        AdjList *adjlist = NULL;

        MstVertex *mst_vertex, *adj_vertex;

        ListElmt *element, *member;

        double minimum;

        int found, i;

        found = 0;

        for (element = list_head(&graph_adjlists(graph)); element != NULL;
                                                 element = list_next(element)) {
                mst_vertex = ((AdjList *)list_data(element))->vertex;

                if (match(mst_vertex, start)) {
                        mst_vertex->color = white;
                        mst_vertex->key = 0;
                        mst_vertex->parent = NULL;
                        found = 1;
                }
                else {
                        mst_vertex->color = white;
                        mst_vertex->key = DBL_MAX;
                        mst_vertex->parent = NULL;
                }
        } 

        if (!found)
                return -1;

        /*
         * Use Prim's algorithm
         */
        i = 0;

        /* Select white vertex with the smallest value */
        while (i < graph_vcount(graph)) {
                minimum = DBL_MAX;

                for (element = list_head(&graph_adjlists(graph));
                                element != NULL; element = list_next(element)) {
                        mst_vertex = ((AdjList *)list_data(element))->vertex;

                        if (mst_vertex->color == white &&
                                                    mst_vertex->key < minimum) {
                                minimum = mst_vertex->key;
                                adjlist = list_data(element);
                        }
                }

                /* Color the selected vertex black */
                ((MstVertex *)adjlist->vertex)->color = black;

                for (member = list_head(&adjlist->adjacent); member != NULL;
                                                   member = list_next(member)) {
                        adj_vertex = list_data(member);

                        for(element = list_head(&graph_adjlists(graph));
                                element != NULL; element = list_next(element)) {
                                mst_vertex = ((AdjList *)list_data(element))->vertex;

                                if (match(mst_vertex, adj_vertex)) {
                                        if (mst_vertex->color == white &&
                                          adj_vertex->weight < mst_vertex->key) {
                                           mst_vertex->key = adj_vertex->weight;
                                           mst_vertex->parent = adjlist->vertex;
                                        }
                                        break;
                                }
                        }

                }

                i++;
        }

        list_init(span, NULL);

        for (element = list_head(&graph_adjlists(graph)); element != NULL;
                                                 element = list_next(element)) {
                mst_vertex = ((AdjList *)list_data(element))->vertex;
                if (mst_vertex->color == black) {
                        if (list_ins_next(span, list_tail(span), mst_vertex)
                                                                         != 0) {
                                list_destroy(span);
                                return -1;
                        }
                }
        }

        return 0;
}
