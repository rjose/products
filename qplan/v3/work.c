#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "work.h"

static int construct_triage_tags(Work *w, const char *triage_string)
{
        int i;
        AssocArrayElem *elem;
        Tag *tag;

        tag_parse_string(triage_string, &w->triage_tags);
        aa_sort_keys(&w->triage_tags);

        for (i = 0; i < work_num_triage(w); i++) {
                elem = work_triage_elem(w, i);
                tag = (Tag *)elem->val.vval;
                tag_store_value(tag, TAG_DOUBLE);
        }
        return 0;
}


static int construct_estimate_tags(Work *w, const char *estimate_string)
{
        int i;
        AssocArrayElem *elem;
        Tag *tag;

        tag_parse_string(estimate_string, &w->estimate_tags);
        aa_sort_keys(&w->estimate_tags);

        for (i = 0; i < work_num_estimates(w); i++) {
                elem = work_estimate_elem(w, i);
                tag = (Tag *)elem->val.vval;
                tag->val.dval = work_translate_estimate(tag->sval);
        }

        return 0;
}

static int construct_tags(Work *w, const char *tag_string)
{
        tag_parse_string(tag_string, &w->tags);
        return 0;
}

/*
 * This initializes a Work structure. Memory for the structure must have been
 * allocated prior to calling this function.
 */
int work_init(Work *w, const char *name, const char *triage_string,
                            const char *estimate_string, const char *tag_string)
{
        /* Copy name into work structure */
        size_t name_len = strlen(name);
        if ((w->name = (char *)malloc(name_len + 1)) == NULL)
                return -1;
        strncpy(w->name, name, name_len);
        w->name[name_len] = '\0';

        /* Initialize assoc arrays */
        aa_init(&w->triage_tags, 5, aa_string_compare);
        aa_init(&w->estimate_tags, 5, aa_string_compare);

        /* Construct fields */
        construct_triage_tags(w, triage_string);
        construct_estimate_tags(w, estimate_string);
        // construct_tags(w, tag_string);

        return 0;
}

double work_translate_estimate(const char *est_string)
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
