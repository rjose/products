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
        pass(0x81 == frame[0], "Check first byte of med126 frame");
        pass(0x7e == frame[1], "Check second byte of med126 frame");
        pass(0x00 == frame[2], "Check 1st len byte of med126 frame");
        pass(0x7e == frame[3], "Check 2nd len byte of med126 frame");
        pass(0x54 == frame[4], "Check 1st msg byte 'T' of med126 frame");
        pass(0xa == frame[129], "Check last msg byte '\\n' of med126 frame");
        free(frame);
        END_SET("Extract medium message");

        START_SET("Extract long message");
        load_data(long66000, 66000, long66000txt);
        frame = ws_make_text_frame(long66000, NULL);
        pass(0x81 == frame[0], "Check first byte of long frame");
        pass(0x7f == frame[1], "Check second byte of long frame");
        pass(0x00 == frame[2], "Check 1st len byte of long frame");
        pass(0x00 == frame[3], "Check 2nd len byte of long frame");
        pass(0x00 == frame[4], "Check 3rd len byte of long frame");
        pass(0x00 == frame[5], "Check 4th len byte of long frame");
        pass(0x00 == frame[6], "Check 5th len byte of long frame");
        pass(0x01 == frame[7], "Check 6th len byte of long frame");
        pass(0x01 == frame[8], "Check 7th len byte of long frame");
        pass(0xd0 == frame[9], "Check 8th len byte of long frame");
        pass(0x35 == frame[10], "Check 1st msg byte long frame");
        pass(0xa == frame[66009], "Check last msg byte long frame");
        END_SET("Extract long message");
        return 0;
}
