#ifndef SORT_H
#define SORT_H

int issort(void *data, int size, int esize,
                            int (*compare)(const void *key1, const void *key2));


#endif
