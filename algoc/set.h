#ifndef SET_H
#define SET_H

#include <stdlib.h>
#include "list.h"

typedef List Set;

#define set_init list_init_with_match

#define set_destroy list_destroy

int set_insert(Set *set, const void *data);

int set_remove(Set *set, void **data);

int set_union(Set *setu, const Set *s1, const Set *set2);

int set_intersection(Set *seti, const Set *s1, const Set *set2);

int set_difference(Set *setd, const Set *s1, const Set *set2);

int set_is_member(const Set *set, const void *data);

int set_is_subset(const Set *set1, const Set *set2);

#define set_size list_size

#endif
