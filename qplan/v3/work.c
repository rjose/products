#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "work.h"

int work_init(Work *w, const char *name, const char *triage,
                                        const char *estimates, const char *tags)
{
        size_t name_len = strlen(name);
        if ((w->name = (char *)malloc(name_len + 1)) == NULL)
                return -1;

        strncpy(w->name, name, name_len + 1);


        /* TODO: Implement this */
        return 0;
}

