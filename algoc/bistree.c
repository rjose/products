#include <stdlib.h>
#include <string.h>

#include "bistree.h"

static void rotate_left(BiTreeNode **);
static void rotate_right(BiTreeNode **);
static void destroy_nodes(BisTree *, BiTreeNode *);
static void destroy_left(BisTree *, BiTreeNode *);
static void destroy_right(BisTree *, BiTreeNode *);
static int insert_left(BisTree *, BiTreeNode **, const void *, int *);
static int insert_right(BisTree *, BiTreeNode **, const void *, int *);
static int insert(BisTree *, BiTreeNode **, const void *, int *);
static int hide(BisTree *, BiTreeNode *, const void *);
static int lookup(BisTree *, BiTreeNode *, void **);

/* ============================================================================
 * Static functions
 */

static void rotate_left(BiTreeNode **node)
{
        BiTreeNode *left, *grandchild;

        left = bitree_left(*node);

        /*
         * If left-heavy, perform an LL rotation
         */
        if (((AvlNode *)bitree_data(left))->factor == AVL_LFT_HEAVY) {
                bitree_left(*node) = bitree_right(left);
                bitree_right(left) = *node;

                ((AvlNode *)bitree_data(*node))->factor = AVL_BALANCED;
                ((AvlNode *)bitree_data(left))->factor = AVL_BALANCED;

                *node = left;
        }
        /*
         * else, perform an LR rotation
         */
        else {
                grandchild = bitree_right(left);
                bitree_right(left) = bitree_left(grandchild);
                bitree_left(grandchild) = left;
                bitree_left(*node) = bitree_right(grandchild);
                bitree_right(grandchild) = *node;

                switch (((AvlNode *)bitree_data(grandchild))->factor) {
                        case AVL_LFT_HEAVY:
                                ((AvlNode *)bitree_data(*node))->factor = 
                                                                  AVL_RGT_HEAVY;
                                ((AvlNode *)bitree_data(left))->factor = 
                                                                  AVL_BALANCED;
                                break;

                        case AVL_BALANCED:
                                ((AvlNode *)bitree_data(*node))->factor = 
                                                                  AVL_BALANCED;
                                ((AvlNode *)bitree_data(left))->factor = 
                                                                  AVL_BALANCED;
                                break;

                        case AVL_RGT_HEAVY:
                                ((AvlNode *)bitree_data(*node))->factor = 
                                                                  AVL_BALANCED;
                                ((AvlNode *)bitree_data(left))->factor = 
                                                                  AVL_LFT_HEAVY;
                                break;
                }

                ((AvlNode *)bitree_data(grandchild))->factor = AVL_BALANCED;
                *node = grandchild;
        }

        return;
}

static void rotate_right(BiTreeNode **node)
{
        BiTreeNode *right, *grandchild;

        right = bitree_right(*node);

        /*
         * If right-heavy, perform an RR rotation
         */
        if (((AvlNode *)bitree_data(right))->factor == AVL_RGT_HEAVY) {
                bitree_right(*node) = bitree_left(right);
                bitree_left(right) = *node;

                ((AvlNode *)bitree_data(*node))->factor = AVL_BALANCED;
                ((AvlNode *)bitree_data(right))->factor = AVL_BALANCED;

                *node = right;
        }
        /*
         * else, perform an RL rotation
         */
        else {
                grandchild = bitree_left(right);
                bitree_left(right) = bitree_right(grandchild);
                bitree_right(grandchild) = right;
                bitree_right(*node) = bitree_left(grandchild);
                bitree_left(grandchild) = *node;

                switch (((AvlNode *)bitree_data(grandchild))->factor) {
                        case AVL_LFT_HEAVY:
                                ((AvlNode *)bitree_data(*node))->factor = 
                                                                  AVL_BALANCED;
                                ((AvlNode *)bitree_data(right))->factor = 
                                                                  AVL_RGT_HEAVY;
                                break;

                        case AVL_BALANCED:
                                ((AvlNode *)bitree_data(*node))->factor = 
                                                                  AVL_BALANCED;
                                ((AvlNode *)bitree_data(right))->factor = 
                                                                  AVL_BALANCED;
                                break;

                        case AVL_RGT_HEAVY:
                                ((AvlNode *)bitree_data(*node))->factor = 
                                                                  AVL_LFT_HEAVY;
                                ((AvlNode *)bitree_data(right))->factor = 
                                                                  AVL_BALANCED;
                                break;
                } 

                ((AvlNode *)bitree_data(grandchild))->factor = AVL_BALANCED;
                 *node = grandchild;
        }
        return;
}

/*
 * Helper function for destroy_left and destroy_right
 */
static void destroy_nodes(BisTree *tree, BiTreeNode *node)
{
        if (node == NULL)
                return;

        destroy_left(tree, node);
        destroy_right(tree, node);

        /* Destroy application data if possible */
        if (tree->destroy != NULL)
                tree->destroy(((AvlNode *)(node)->data)->data);

        /*
         * Free the AVL wrapper data and then the node itself
         */
        free(node->data);
        free(node);
        node = NULL;

        /*
         * Update tree stats
         */
        tree->size--;

        return;
}


static void destroy_left(BisTree *tree, BiTreeNode *node)
{
        BiTreeNode **position;

        if (bitree_size(tree) == 0)
                return;

        /*
         * Figure out where to start destroying nodes from
         */
        if (node == NULL)
                position = &tree->root;
        else
                position = &node->left;

        /*
         * Destroy the nodes
         */
        destroy_nodes(tree, *position);

        return;
}

static void destroy_right(BisTree *tree, BiTreeNode *node)
{
        BiTreeNode **position;

        if (bitree_size(tree) == 0)
                return;

        /*
         * Figure out where to start destroying nodes from
         */
        if (node == NULL)
                position = &tree->root;
        else
                position = &node->right;

        /*
         * Destroy the nodes
         */
        destroy_nodes(tree, *position);

        return;

}

static int insert_left(BisTree *tree, BiTreeNode **node, const void *data,
                                                             int *balanced)
{
        int retval;
        AvlNode *avl_data;

        /*
         * Add node to left subtree of "node"
         */

        /* If have a free slot, add node there */
        if (bitree_is_eob(bitree_left(*node))) {
                if ((avl_data = (AvlNode *)malloc(sizeof(AvlNode))) ==
                                                                   NULL)
                        return -1;

                avl_data->factor = AVL_BALANCED;
                avl_data->hidden = 0;
                avl_data->data = (void *)data;

                if(bitree_ins_left(tree, *node, avl_data) != 0)
                        return -1;

                *balanced = 0;
        }
        /* else, move down the tree until we find a free slot */
        else {
                if ((retval = insert(tree, &bitree_left(*node), data,
                                                        balanced)) != 0)
                        return retval;
        }

        /*
         * Make sure tree stays balanced 
         */ 
        if (!(*balanced)) {
                switch(((AvlNode *)bitree_data(*node))->factor) {
                        case AVL_LFT_HEAVY:
                        rotate_left(node);
                        *balanced = 1;
                        break;

                        case AVL_BALANCED:
                        ((AvlNode *)bitree_data(*node))->factor = AVL_LFT_HEAVY;
                        break;

                        case AVL_RGT_HEAVY:
                        ((AvlNode *)bitree_data(*node))->factor = AVL_BALANCED;
                        *balanced = 1;
                        break;
                }
        }

        return 0;
}


static int insert_right(BisTree *tree, BiTreeNode **node, const void *data,
                                                             int *balanced)
{
        int retval;
        AvlNode *avl_data;

        /*
         * Add node to right subtree of "node"
         */

        /* If have a free slot, add node there */
        if (bitree_is_eob(bitree_right(*node))) {
                if ((avl_data = (AvlNode *)malloc(sizeof(AvlNode))) ==
                                                                   NULL)
                        return -1;

                avl_data->factor = AVL_BALANCED;
                avl_data->hidden = 0;
                avl_data->data = (void *)data;

                if(bitree_ins_right(tree, *node, avl_data) != 0)
                        return -1;

                *balanced = 0;
        }
        /* else, move down the tree until we find a free slot */
        else {
                if ((retval = insert(tree, &bitree_right(*node), data,
                                                        balanced)) != 0)
                        return retval;
        }

        /*
         * Make sure tree stays balanced 
         */ 
        if (!(*balanced)) {
                switch(((AvlNode *)bitree_data(*node))->factor) {
                        case AVL_LFT_HEAVY:
                        ((AvlNode *)bitree_data(*node))->factor = AVL_BALANCED;
                        *balanced = 1;
                        break;

                        case AVL_BALANCED:
                        ((AvlNode *)bitree_data(*node))->factor = AVL_RGT_HEAVY;
                        break;

                        case AVL_RGT_HEAVY:
                        rotate_right(node);
                        *balanced = 1;
                        break;
                }
        }

        return 0;
}


/*
 * There are 4 cases to consider:
 *
 *   1. Insert into empty tree
 *   2. Insert to the left
 *   3. Insert to the right
 *   4. (Possibly) replace current node data
 */
static int insert(BisTree *tree, BiTreeNode **node, const void *data,
                                                          int *balanced)
{
        AvlNode *avl_data;

        int cmpval;

        /*
         * Case 1: Insert into empty tree
         */
        if (bitree_is_eob(*node)) {
                if ((avl_data = (AvlNode *)malloc(sizeof(AvlNode))) == NULL)
                        return -1;

                avl_data->factor = AVL_BALANCED;
                avl_data->hidden = 0;
                avl_data->data = (void *)data;
                
                return bitree_ins_left(tree, *node, avl_data);
        } 

        /* Compare data with node's data for remaining cases */
        cmpval = tree->compare(data, ((AvlNode *)bitree_data(*node))->data);

        /*
         * Case 2: Insert to the left
         */
        if (cmpval < 0) {
                return insert_left(tree, node, data, balanced);
        }

        /*
         * Case 3: Insert to the right
         */
        if (cmpval > 0) {
                return insert_right(tree, node, data, balanced);
        }

        /*
         * Case 4: (Possibly) replace current node data
         */

        avl_data = ((AvlNode *)bitree_data(*node));

        /* If data isn't hidden, just return */
        if (!avl_data->hidden) {
                return 1;
        }

        /* Insert new data */
        if (tree->destroy != NULL) {
                tree->destroy(avl_data->data);
        }

        avl_data->data = (void *)data;
        avl_data->hidden = 0;
        *balanced = 1;

        return 0;
}

// Function to search for and return node matching data
static int lookup_node(BisTree *tree, BiTreeNode *node, const void *data,
                                                      BiTreeNode **result)
{
        int cmpval, retval;
        AvlNode *avl_data;

        /* If end of branch, couldn't find it */
        if (bitree_is_eob(node))
                return -1;

        avl_data = ((AvlNode *)bitree_data(node));

        /* Determine which subtree to search */
        cmpval = tree->compare(data, avl_data->data);

        if (cmpval < 0)
                retval = lookup_node(tree, bitree_left(node), data, result);
        else if (cmpval > 0)
                retval = lookup_node(tree, bitree_right(node), data, result);
        else {
                if (avl_data->hidden)
                        retval = -1;
                else {
                        *result = node;
                        retval = 0;
                }
        }
        return retval;
}

static int hide(BisTree *tree, BiTreeNode *node, const void *data)
{
        BiTreeNode *result;

        if (lookup_node(tree, node, data, &result) != 0)
                return -1;

        ((AvlNode *)bitree_data(result))->hidden = 1;

        return 0;
}

static int lookup(BisTree *tree, BiTreeNode *node, void **data)
{
        BiTreeNode *result;

        if (lookup_node(tree, node, *data, &result) != 0)
                return -1;

        *data = ((AvlNode *)bitree_data(result))->data;
        return 0;
}

/* ============================================================================
 * Public functions
 */

void bistree_init(BisTree *tree,
                  int (*compare)(const void *key1, const void *key2),
                  void (*destroy)(void *data))
{
        bitree_init(tree, destroy);
        tree->compare = compare;
        return;
}

void bistree_destroy(BisTree *tree)
{
        destroy_left(tree, NULL);
        memset(tree, 0, sizeof(BisTree));
        return;
}

int bistree_insert(BisTree *tree, const void *data)
{
        int balanced = 0;
        return insert(tree, &bitree_root(tree), data, &balanced);
}

int bistree_remove(BisTree *tree, const void *data)
{
        return hide(tree, bitree_root(tree), data);
}

int bistree_lookup(BisTree *tree, void **data)
{
        return lookup(tree, bitree_root(tree), data);
}

