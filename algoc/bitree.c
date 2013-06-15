#include <stdlib.h>
#include <string.h>

#include "bitree.h"

#define create_node(new_node, data) \
        if ((new_node = (BiTreeNode *)malloc(sizeof(BiTreeNode))) == NULL) \
                return -1; \
        new_node->data = (void *)data; \
        new_node->left = NULL; \
        new_node->right = NULL;

#define remove_nodes(tree, position) \
        if (*position != NULL) { \
                bitree_rem_left(tree, *position); \
                bitree_rem_right(tree, *position); \
                if (tree->destroy != NULL) \
                        tree->destroy((*position)->data); \
                free(*position); \
                *position = NULL; \
                tree->size--; \
        }

void bitree_init(BiTree *tree, void (*destroy)(void *data))
{
        tree->size = 0;
        tree->destroy = destroy;
        tree->root = NULL;

        return;
}

void bitree_destroy(BiTree *tree)
{
        /* Treats the root like the left subtree of some bigger tree */
        bitree_rem_left(tree, NULL);
        memset(tree, 0, sizeof(BiTree));
}

int bitree_ins_left(BiTree *tree, BiTreeNode *node, const void *data)
{
        BiTreeNode *new_node;
        BiTreeNode **position;      /* Use this to update the left node */

        /*
         * Figure out where to add the node
         */
        if (node == NULL) {
                /* Can only insert at root if tree is empty */
                if (bitree_size(tree) > 0)
                        return -1;

                position = &tree->root;
        }
        else {
                /* Can only insert when the left node is empty */
                if (bitree_left(node) != NULL)
                        return -1;

                position = &node->left;
        }

        /*
         * Create node have the tree point to it
         */
        create_node(new_node, data);
        *position = new_node;

        /*
         * Update tree stats
         */
        tree->size++;

        return 0;
}

int bitree_ins_right(BiTree *tree, BiTreeNode *node, const void *data)
{
        BiTreeNode *new_node;
        BiTreeNode **position;      /* Use this to update the right node */

        /*
         * Figure out where to add the node
         */
        if (node == NULL) {
                /* Can only insert at root if tree is empty */
                if (bitree_size(tree) > 0)
                        return -1;

                position = &tree->root;
        }
        else {
                /* Can only insert when the right node is empty */
                if (bitree_right(node) != NULL)
                        return -1;

                position = &node->right;
        }

        /*
         * Create node have the tree point to it
         */
        create_node(new_node, data);
        *position = new_node;

        /*
         * Update tree stats
         */
        tree->size++;

        return 0;
}

void bitree_rem_left(BiTree *tree, BiTreeNode *node)
{
        BiTreeNode **position;

        if (bitree_size(tree) == 0)
                return;

        /*
         * Figure out where to start removing nodes
         */
        if (node == NULL)
                position = &tree->root;
        else
                position = &node->left;

        /*
         * Remove nodes
         */
        remove_nodes(tree, position);
        return;
}

void bitree_rem_right(BiTree *tree, BiTreeNode *node)
{
        BiTreeNode **position;

        if (bitree_size(tree) == 0)
                return;

        /*
         * Figure out where to start removing nodes
         */
        if (node == NULL)
                position = &tree->root;
        else
                position = &node->right;

        /*
         * Remove nodes
         */
        remove_nodes(tree, position);
        return;
}

int bitree_merge(BiTree *merge, BiTree *left, BiTree *right, const void *data)
{
        bitree_init(merge, left->destroy);

        if (bitree_ins_left(merge, NULL, data) != 0) {
                bitree_destroy(merge);
                return -1;
        }

        /*
         * Merge the left and right trees into "merge"
         */
        bitree_root(merge)->left = bitree_root(left);
        bitree_root(merge)->right = bitree_root(right);
        merge->size = merge->size + bitree_size(left) + bitree_size(right);

        /*
         * Null out the left and right trees
         */
        left->root = NULL;
        left->size = 0;
        right->root = NULL;
        right->size = 0;

        return 0;
}

