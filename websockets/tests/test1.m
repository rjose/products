#include <err.h>
#include <string.h>

#import "Testing.h"

int main()
{
        char *message = "HOWDY";
        char *old_message;

        START_SET("Is websocket handshake");

        pass(0 == 0, "Sample test");

        END_SET("Is websocket handshake");
        
        return 0;
}
