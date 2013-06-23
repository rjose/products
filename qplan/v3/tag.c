#include <string.h>

#include "tag.h"

#define TAG_SEP ','
#define PAIR_SEP ':'


static int find_pair_sep_index(const char *tag_string, int start, int end)
{
        int i;
        int result = -1;
        for (i = start; i <= end; i++) {
                /* Separator can't be at beginning */
                if (tag_string[i] == PAIR_SEP && i == start)
                        break;
                else if (tag_string[i] == PAIR_SEP) {
                        result = i;
                        break;
                }
        }
        return result;
}

static int find_tag_sep_index(const char *tag_string, int start)
{
        int result = start;
        while (tag_string[result]) {
                if (tag_string[result] == TAG_SEP)
                        break;
                result++;
        }
        return result;
}

// TODO: Add tag structure result
int tag_parse_string(const char *tag_string)
{
        int num_tags = 0;
        int tag_start = 0;
        int tag_end;
        int pair_sep_index;

        /*
         * Find separation between tags and then construct tags from pairs until
         * we reach the end of the string.
         */
        do {
                tag_end = find_tag_sep_index(tag_string, tag_start);
                pair_sep_index = 
                        find_pair_sep_index(tag_string, tag_start, tag_end - 1);

                if (pair_sep_index <= tag_start)
                        return 0;

                // TODO: Create tag from key and value
                num_tags++;
                tag_start = tag_end + 1;

        } while (tag_string[tag_end] != '\0');

        return num_tags;
}
