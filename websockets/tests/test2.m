#include <err.h>
#include <stdlib.h>
#include <string.h>

#include "../ws.h"

#import "Testing.h"

typedef unsigned char uchar;

/* ============================================================================
 * Static functions
 */
static int check_frame(const uchar *, size_t, const uchar *);


/* ============================================================================
 * Test data
 */
static char empty_message[] = "";

static char hello_message[] = "Hello";

/* 125 chars is the biggest short message we can handle */
static char big_short_message[] =
        "Now is the time for all good men to come to to the aid of their "
        "party. How many more characters will it take to reach 125 !!!"
;


/* ============================================================================
 * Expected results
 */


/*
 * Byte 0: 10000001
 *      Bit 0    (FIN):         1     (final fragment)
 *      Bits 4-7 (OPCODE):      00001 (text frame)
 *
 * Byte 1: 00000101 
 *      Bit 0    (Mask):        0     (unmasked)
 *      Bits 1-7 (Payload len): 0x05
 *
 * Bytes 2-6: Payload           'H', 'e', 'l', 'l', 'o'
 */
uchar hello_message_frame[] = {0x81, 0x05, 0x48, 0x65, 0x6c, 0x6c, 0x6f};

uchar empty_message_frame[] = {0x81, 0x00};

uchar big_short_frame_start[] = {0x81, 0x7d}; 


static int check_frame(const uchar *expected, size_t len, const uchar *actual)
{
        int i;
        for (i = 0; i < len; i++) {
                if (*expected++ != *actual++)
                        return 0;
        }
        return 1;
}

/* ============================================================================
 * Main
 */

int main()
{
        const uchar *frame = NULL;

        /*
         * Build frame for small message
         */
        START_SET("Build small message");
        frame = ws_make_text_frame(hello_message, NULL);
        pass(1 == check_frame(hello_message_frame, 7, frame), "Hello message");
        free(frame);

        frame = ws_make_text_frame(empty_message, NULL);
        pass(1 == check_frame(empty_message_frame, 2, frame), "'' message");
        free(frame);

        frame = ws_make_text_frame(big_short_message, NULL);
        pass(1 == check_frame(big_short_frame_start, 2, frame), "big short message");
        // Check first and last chars of message body
        pass(0x4e == frame[2], "First letter should be 'N'");
        pass(0x21 == frame[126], "Last letter should be '!'");
        free(frame);

        END_SET("Build small message");

        return 0;
}
