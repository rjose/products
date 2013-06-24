#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "work.h"

static int construct_triage_tags(Work *w, const char *triage_string)
{
        Tag *tmp;

        Tag_parse_string(triage_string, &w->triage_tags);
        tmp = w->triage_tags;
        while (tmp) {
                Tag_store_value(tmp, DOUBLE);
                tmp = tmp->next;
        }
        return 0;
}


static int construct_estimate_tags(Work *w, const char *estimate_string)
{
        Tag *tmp;

        Tag_parse_string(estimate_string, &w->estimate_tags);
        tmp = w->estimate_tags;
        while (tmp) {
                // TODO: translate estimate tags
                //Tag_store_value(tmp, DOUBLE);
                tmp = tmp->next;
        }
        return 0;
}

static int construct_tags(Work *w, const char *tag_string)
{
        Tag_parse_string(tag_string, &w->tags);
        return 0;
}

/*
 * This initializes a Work structure. Memory for the structure must have been
 * allocated prior to calling this function.
 */
int Work_init(Work *w, const char *name, const char *triage_string,
                            const char *estimate_string, const char *tag_string)
{
        /* Copy name into work structure */
        size_t name_len = strlen(name);
        if ((w->name = (char *)malloc(name_len + 1)) == NULL)
                return -1;
        strncpy(w->name, name, name_len);
        w->name[name_len] = '\0';

        /* Construct fields */
        construct_triage_tags(w, triage_string);
        construct_estimate_tags(w, estimate_string);
        construct_tags(w, tag_string);

        return 0;
}

double Work_translate_estimate(const char *est_string)
{
        double scale;
        char *stop;
        double base;

        /*
         * Get the scale factor
         */
        scale = strtod(est_string, &stop);
        if (est_string == stop)
                scale = 1.0;

        /*
         * Get base
         */
        switch(*stop) {
                case 'S':
                        base = 1.0;
                        break;

                case 'M':
                        base = 2.0;
                        break;

                case 'L':
                        base = 3.0;
                        break;

                case 'Q':
                        base = 13.0;
                        break;

                default:
                        base = 0.0;
                        break;
        }

        return scale * base;
}
