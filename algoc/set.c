#include "set.h"


int set_insert(Set *set, const void *data)
{
        if (set_is_member(set, data))
                return 1;

        return list_ins_next(set, list_tail(set), data);
}

int set_remove(Set *set, void **data)
{
        ListElmt *member, *prev_to_member;

        /*
         * Find member to remove
         */

        /* Start at the head of the list.
         * Note prev_to_member is NULL as it should be for member = HEAD */
        member = list_head(set);
        prev_to_member = NULL;
        for ( ; member != NULL; member = list_next(member)) {

                /* Logic is a little delicate here. When we break,
                 * prev_to_member will be correct. */
                if (set->match(*data, list_data(member)))
                        break;

                prev_to_member = member;
        }

        /*
         * If we didn't find the element, return -1
         */
        if (member == NULL)
                return -1;

        return list_rem_next(set, prev_to_member, data);
}

/*
 * NOTE: We expect setu to be uninitialized and empty.
 */
int set_union(Set *setu, const Set *set1, const Set *set2)
{
        ListElmt *member;
        void *data;

        /*
         * Initialize set
         */
        set_init(setu, set1->match, NULL);

        /*
         * Insert members of first set
         */
        member = list_head(set1);
        for ( ; member != NULL; member = list_next(member)) {
                data = list_data(member);

                if (list_ins_next(setu, list_tail(setu), data) != 0) {
                        set_destroy(setu);
                        return -1;
                }
        }

        /*
         * Insert members of second set
         */
        member = list_head(set2);
        for ( ; member != NULL; member = list_next(member)) {
                if (set_is_member(setu, list_data(member)))
                        continue;

                data = list_data(member);

                if (list_ins_next(setu, list_tail(setu), data) != 0) {
                        set_destroy(setu);
                        return -1;
                }
        }

        return 0;
}

int set_intersection(Set *seti, const Set *set1, const Set *set2)
{
        ListElmt *member;
        void *data;

        /*
         * Initialize set
         */
        set_init(seti, set1->match, NULL);

        /*
         * Insert elements that are in both sets
         */
        member = list_head(set1);
        for ( ; member != NULL; member = list_next(member)) {
                if (set_is_member(set2, list_data(member))) {
                        data = list_data(member);

                        if (list_ins_next(seti, list_tail(seti), data) != 0) {
                                set_destroy(seti);
                                return -1;
                        }
                }
        }

        return 0;
}

int set_difference(Set *setd, const Set *set1, const Set *set2)
{
        ListElmt *member;
        void *data;

        /*
         * Initialize set
         */
        set_init(setd, set1->match, NULL);

        /*
         * Insert elements that are in set1 but not set2
         */
        member = list_head(set1);
        for ( ; member != NULL; member = list_next(member)) {
                if (!set_is_member(set2, list_data(member))) {
                        data = list_data(member);

                        if (list_ins_next(setd, list_tail(setd), data) != 0) {
                                set_destroy(setd);
                                return -1;
                        }
                }
        }

        return 0;
}

int set_is_member(const Set *set, const void *data)
{
        ListElmt *member;

        member = list_head(set);
        for ( ; member != NULL; member = list_next(member)) {
                if (set->match(list_data(member), data))
                        return 1;
        }

        return 0;
}

/*
 * Is set1 a subset of set2
 */
int set_is_subset(const Set *set1, const Set *set2)
{
        ListElmt *member;

        if (set_size(set1) > set_size(set2))
                return 0;

        member = list_head(set1);
        for ( ; member != NULL; member = list_next(member)) {
                if (!set_is_member(set2, list_data(member)))
                        return 0;
        }
        return 1;
}

