#include <err.h>
#include <string.h>

#include "../list.h"

#import "Testing.h"

int main()
{
        char *message = "HOWDY";
        char *old_message;
        List list1;

        START_SET("List test");

        list_init(&list1, NULL);
        pass(0 == (list_size(&list1)), "Check list size at beginning");

        list_ins_next(&list1, NULL, message);
        pass(1 == (list_size(&list1)), "Check list size");

        list_rem_next(&list1, NULL, (void **) &old_message);
        pass(message == old_message, "Checking data after removal");

        END_SET("List test");
        
        return 0;
}
