#include <string.h>
#include <err.h>

#import "Testing.h"

#include "../tag.h"

// "Prod:1,Eng:2",
// "Native:2L,Web:M,Server:Q,BB:S",
// "track:Track1,pm:John");

void test_tag_parse_string()
{
        // TODO: Add tag structure and check values
        START_SET("Parse tag string");
        pass(tag_parse_string("Prod:1,Eng:2") == 2, "Check valid tag 2");
        pass(tag_parse_string("Prod:1") == 1, "Check valid tag 1");
        pass(tag_parse_string("Prod:,Eng:2") == 2, "Check valid tag 3");

        // Check invalid tags
        pass(tag_parse_string(",Eng:2") == 0, "Check invalid tag 1");
        pass(tag_parse_string(":2") == 0, "Check invalid tag 2");
        pass(tag_parse_string("Prod") == 0, "Check invalid tag 3");
        pass(tag_parse_string("") == 0, "Check invalid tag 4");
        END_SET("Parse tag string");
}


int main()
{
        test_tag_parse_string();
        
        return 0;
}

