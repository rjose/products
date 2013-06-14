#include "stack.h"


/* ============================================================================
 * Stack operations
 */

int stack_push(Stack *stack, const void *data)
{
        /* Insert element at head of list */
        return list_ins_next(stack, NULL, data);
}

int stack_pop(Stack *stack, void **data)
{
        return list_rem_next(stack, NULL, data);
}
