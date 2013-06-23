#include <string.h>
#include <err.h>

#import "Testing.h"

#include "../work.h"

#define NUM_WORK_ITEMS 10

static Work m_work[NUM_WORK_ITEMS];

/* TODO: Validate input strings */
void test_create_work()
{
        START_SET("Create work");
        work_init(&m_work[0], 
                      "Item 1",
                      "Prod:1,Eng:2",
                      "Native:2L,Web:M,Server:Q,BB:S",
                      "track:Track1,pm:John");

        pass(strcmp("Item 1", m_work[0].name) == 0, "Name matches");
        /* TODO: Check other fields */
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
