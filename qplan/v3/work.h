#ifndef WORK_H
#define WORK_H

#include "tag.h"

typedef struct Work_ {
        char *name;
        Tag *triage_tags;
        Tag *estimate_tags;
        Tag *tags;
} Work;


int Work_init(Work *w, const char *name, const char *triage_string,
                            const char *estimate_string, const char *tag_string);

double Work_translate_estimate(const char *est_string);

#endif
