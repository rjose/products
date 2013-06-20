#ifndef GRAPHALG_H
#define GRAPHALG_H

#include "graph.h"
#include "list.h"


/* ============================================================================
 * Data Structures
 */

/* Minimum Spanning Tree */
typedef struct MstVertex_ {
        void *data;
        double weight;

        VertexColor color;
        double key;

        struct MstVertex_ *parent;
} MstVertex;

/* Vertex for shortest path */
typedef struct PathVertex_ {
        void *data;
        double weight;

        VertexColor color;
        double d;

        struct PathVertex_ *parent;
} PathVertex;

/* Vertex for traveling salesperson */
typedef struct TspVertex_ {
        void *data;
        double x, y;

        VertexColor color;
} TspVertex;


/* ============================================================================
 * Public API
 */

int mst(Graph *graph, const MstVertex *start, List *span,
                              int (*match)(const void *key1, const void *key2));

int shortest(Graph *graph, const PathVertex *start, List *paths,
                              int (*match)(const void *key1, const void *key2));

int tsp(List *vertices, const TspVertex *start, List *tour,
                              int (*match)(const void *key1, const void *key2));
                      

#endif
