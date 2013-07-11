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


// TODO: Add filenames

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

        /*
         * Construct frame for medium message
         */
        START_SET("Extract medium message");
        load_data(med126, 126, med126txt);
        frame = ws_make_text_frame(med126, NULL);
        pass(0x81 == frame[0], "Check first byte of med126 frame");
        pass(0x7e == frame[1], "Check second byte of med126 frame");
        pass(0x00 == frame[2], "Check 1st len byte of med126 frame");
        pass(0x7e == frame[3], "Check 2nd len byte of med126 frame");
        pass(0x54 == frame[4], "Check 1st msg byte 'T' of med126 frame");
        pass(0xa == frame[129], "Check last msg byte '\\n' of med126 frame");

        END_SET("Extract medium message");

        return 0;
}
