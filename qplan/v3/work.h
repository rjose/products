#ifndef WORK_H
#define WORK_H

#include "tag.h"

typedef struct Work_ {
        char *name;
        Tag *triage_tags;
        Tag *estimate_tags;
        Tag *tags;
} Work;


int work_init(Work *w, const char *name, const char *triage_string,
                            const char *estimate_string, const char *tag_string);

#endif
