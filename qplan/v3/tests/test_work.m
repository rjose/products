#include <string.h>
#include <err.h>

#import "Testing.h"

#include "../work.h"

#define NUM_WORK_ITEMS 10

static Work m_work[NUM_WORK_ITEMS];

static void test_create_work()
{
        Tag *tag;

        START_SET("Create work");
        Work_init(&m_work[0], "Item 1",
                      "Prod:1,Eng:2",
                      "Native:2L,Web:M,Server:Q,BB:S",
                      "track:Track1,pm:John");

        pass(strcmp("Item 1", m_work[0].name) == 0, "Name matches");
        pass(strcmp("Eng", m_work[0].triage_tags->key) == 0, "Triage key matches");
        pass(EQ(2, m_work[0].triage_tags->v.dval), "Triage value matches");

        tag = m_work[0].estimate_tags;
        tag = tag->next;
        pass(strcmp("Server", tag->key) == 0, "Estimate key matches");
        pass(strcmp("Q", tag->val) == 0, "Estimate val matches");

        tag = m_work[0].tags;
        pass(strcmp("pm", tag->key) == 0, "Tag key matches");
        pass(strcmp("John", tag->val) == 0, "Tag val matches");

        tag = m_work[0].estimate_tags->next->next->next;
        pass(EQ(6, tag->v.dval), "Estimate is auto computed");

        END_SET("Create work");

        // TODO: Clean up memory
}

static void test_translate_estimate()
{
        START_SET("Translate work estimates");
        pass(EQ(1, Work_translate_estimate("S")), "Translate S");
        pass(EQ(2, Work_translate_estimate("M")), "Translate M");
        pass(EQ(3, Work_translate_estimate("L")), "Translate L");
        pass(EQ(13, Work_translate_estimate("Q")), "Translate Q");
        pass(EQ(9, Work_translate_estimate("3L")), "Translate 3L");
        pass(EQ(0, Work_translate_estimate("")), "Translate ''");
        END_SET("Translate work estimates");
}

static void test_sum_estimates()
{
        Work_init(&m_work[1], "Item 1",
                      "",
                      "Native:2L,Web:M,Apps:Q",
                      "");
        Work_init(&m_work[2], "Item 2",
                      "",
                      "Native:5L,Web:2M,Apps:S",
                      "");

        START_SET("Sum estimates");
        Work_sum_estimates(&m_work[1], 2);
        END_SET("Sum estimates");
}

int main()
{
        test_create_work();
        test_translate_estimate();
        test_sum_estimates();
        
        return 0;
}