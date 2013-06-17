#include "list.h"
#include "bitree.h"

/*
 * Preorder traversal:
 *
 *   1. Visit node
 *   2. Traverse node's left subtree
 *   3. Traverse node's right subtree
 */
int preorder(const BiTreeNode *node, List *list)
{
        if (!bitree_is_eob(node)) {

                if (list_ins_next(list, list_tail(list), bitree_data(node)) != 0)
                        return -1;

                if (!bitree_is_eob(bitree_left(node)))
                        if (preorder(bitree_left(node), list) != 0)
                                return -1;

                if (!bitree_is_eob(bitree_right(node)))
                        if (preorder(bitree_right(node), list) != 0)
                                return -1;
        }

        return 0;
}


/*
 * Inorder traversal:
 *
 *   1. Traverse node's left subtree
 *   2. Visit node
 *   3. Traverse node's right subtree
 */
int inorder(const BiTreeNode *node, List *list)
{
        if (!bitree_is_eob(node)) {

                if (!bitree_is_eob(bitree_left(node)))
                        if (inorder(bitree_left(node), list) != 0)
                                return -1;

                if (list_ins_next(list, list_tail(list), bitree_data(node)) != 0)
                        return -1;


                if (!bitree_is_eob(bitree_right(node)))
                        if (inorder(bitree_right(node), list) != 0)
                                return -1;
        }

        return 0;
}


/*
 * Postorder traversal:
 *
 *   1. Traverse node's left subtree
 *   2. Traverse node's right subtree
 *   3. Visit node
 */
int postorder(const BiTreeNode *node, List *list)
{
        if (!bitree_is_eob(node)) {

                if (!bitree_is_eob(bitree_left(node)))
                        if (postorder(bitree_left(node), list) != 0)
                                return -1;

                if (!bitree_is_eob(bitree_right(node)))
                        if (postorder(bitree_right(node), list) != 0)
                                return -1;

                if (list_ins_next(list, list_tail(list), bitree_data(node)) != 0)
                        return -1;
        }

        return 0;
}
