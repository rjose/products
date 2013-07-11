#include <err.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <stdio.h>
#include <errno.h>

#include "../ws.h"

#import "Testing.h"

/* ============================================================================
 * Static declarations
 */
static void load_data(uint8_t *, size_t, const char *);

/* ============================================================================
 * Test data
 */

static const char med126txt[] = "./data/med-126.txt";
static char med126[126 + 1];


static const char long66000txt[] = "./data/long-66000.txt";
static char long66000[66000 + 1];

/* ============================================================================
 * Main
 */

/*
 * NOTE: Assuming dst has enough capacity for len + 1
 */
static void load_data(uint8_t *dst, size_t len, const char *filename)
{
        FILE *file;

        if ((file = fopen(filename, "r")) == NULL) {
                printf(strerror(errno));
                exit(errno);
        }

        if (fread((void *)dst, sizeof(char), len, file) != len)
                exit(-1);

        if (fclose(file) != 0) {
                printf(strerror(errno));
                exit(errno);
        }

        dst[len] = '\0';

        return;
}

int main()
{
        const char *message_body = NULL;
        const uint8_t *frame = NULL;

        START_SET("Extract medium message");
        load_data(med126, 126, med126txt);
        frame = ws_make_text_frame(med126, NULL);
        free(frame);
        END_SET("Extract medium message");

//        START_SET("Extract long message");
//        load_data(long66000, 66000, long66000txt);
//        frame = ws_make_text_frame(long66000, NULL);
//        END_SET("Extract long message");
        return 0;
}
