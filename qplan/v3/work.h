#ifndef WORK_H
#define WORK_H

typedef struct Work_ {
        char *name;
} Work;


int work_init(Work *w, const char *name, const char *triage,
                                        const char *estimates, const char *tags);

#endif
