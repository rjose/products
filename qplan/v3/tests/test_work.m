#include <err.h>

#import "Testing.h"

void test_create_work()
{
        START_SET("Create work");

        pass(YES == YES, "<description>");
        END_SET("Create work");
}

void test_set_estimate()
{
        START_SET("Set estimate");

        pass(YES == YES, "<description>");
        END_SET("Set estimate");
}


int main()
{
        test_create_work();
        test_set_estimate();
        
        return 0;
}
