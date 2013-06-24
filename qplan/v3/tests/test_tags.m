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

        // NOTE: *Not* freeing memory here. In production code, use Tag_free
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


void test_tag_free()
{
        Tag *tags = NULL;
        int num_tags = 0;

        START_SET("Tag free");
        
        num_tags = Tag_parse_string("Prod:1,Eng:2", &tags);
        pass(tags != NULL, "Should have some tags");

        pass(Tag_free(&tags) == 0, "Tag_free should run properly");
        pass(tags == NULL, "After freeing tags, pointer should be NULL");

        END_SET("Tag free");
}

void test_tag_store_value()
{
        Tag *tags = NULL;
        Tag *t;

        START_SET("Tag store value");
        
        Tag_parse_string("Prod:1,Native:0.15", &tags);

        /* Store tag value as int */
        t = tags;
        Tag_store_value(t, DOUBLE); 
        pass(EQ(t->v.dval, 0.15), "Check double value");

        /* Store tag value as double */
        t = t->next;
        Tag_store_value(t, LONG);
        pass(t->v.lval == 1, "Check int value");

        Tag_free(&tags);

        END_SET("Tag store value");
}


int main()
{
        test_tag_parse_string();
        test_tag_store_value();
        test_tag_free();
        
        return 0;
}

