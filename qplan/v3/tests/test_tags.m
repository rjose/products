#include <string.h>
#include <err.h>

#import "Testing.h"

#include "../tag.h"

// "Prod:1,Eng:2",
// "Native:2L,Web:M,Server:Q,BB:S",
// "track:Track1,pm:John");

void test_tag_parse_string()
{
        Tag *tags;

        // TODO: Free memory
        START_SET("Parse tag string");
        pass(Tag_parse_string("Prod:1,Eng:2", &tags) == 2, "Check valid tag 2");
        pass(strcmp("Eng", tags->key) == 0, "Check key 1");
        pass(strcmp("2", tags->val) == 0, "Check val 1");
        pass(strcmp("Prod", tags->next->key) == 0, "Check key 2");
        pass(strcmp("1", tags->next->val) == 0, "Check val 2");
        pass(tags->next->next == NULL, "Check tag list termination");

        pass(Tag_parse_string("Prod:1", &tags) == 1, "Check valid tag 1");
        pass(Tag_parse_string("Prod:,Eng:2", &tags) == 2, "Check valid tag 3");

        // Check invalid tags
        pass(Tag_parse_string(",Eng:2", &tags) == 0, "Check invalid tag 1");
        pass(Tag_parse_string(":2", &tags) == 0, "Check invalid tag 2");
        pass(Tag_parse_string("Prod", &tags) == 0, "Check invalid tag 3");
        pass(Tag_parse_string("", &tags) == 0, "Check invalid tag 4");
        END_SET("Parse tag string");
}

// TODO: Test freeing tags
// TODO: Test converting tag values


int main()
{
        test_tag_parse_string();
        
        return 0;
}

