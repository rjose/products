#include <string.h>
#include <err.h>

#import "Testing.h"

#include "../work.h"

#define NUM_WORK_ITEMS 10

static Work m_work[NUM_WORK_ITEMS];

static void test_create_work()
{
        AssocArrayElem *elem;
        Tag *tag;

        START_SET("Create work");
        work_init(&m_work[0], "Item 1",
                      "Prod:1,Eng:2",
                      "Native:2L,Web:M,Server:Q,BB:S",
                      "track:Track1,pm:John");

        /* Check triage tags */
        pass(strcmp("Item 1", m_work[0].name) == 0, "Name matches");
        pass(2 == work_num_triage(&m_work[0]), "Know number of triage elements");

        elem = work_triage_elem(&m_work[0], 0);
        tag = (Tag *)elem->val.vval;
        pass(strcmp("Eng", elem->key.sval) == 0, "Know first triage element");
        pass(EQ(2, tag->val.dval), "Know first triage value");


        /* Test estimate tags */
        pass(4 == work_num_estimates(&m_work[0]), "Know number of estimate elements");
        elem = work_estimate_elem(&m_work[0], 2);
        tag = (Tag *)elem->val.vval;
        pass(strcmp("Server", elem->key.sval) == 0, "Know third estimate element");
        pass(EQ(13, tag->val.dval), "Know third estimate value");
        pass(strcmp("Q", tag->sval) == 0, "Know third estimate string val");

//        tag = m_work[0].tags;
//        pass(strcmp("pm", tag->key) == 0, "Tag key matches");
//        pass(strcmp("John", tag->val) == 0, "Tag val matches");
//
//        tag = m_work[0].estimate_tags->next->next->next;
//        pass(EQ(6, tag->v.dval), "Estimate is auto computed");

        END_SET("Create work");

        // TODO: Clean up memory
}

static void test_translate_estimate()
{
        START_SET("Translate work estimates");
        pass(EQ(1, work_translate_estimate("S")), "Translate S");
        pass(EQ(2, work_translate_estimate("M")), "Translate M");
        pass(EQ(3, work_translate_estimate("L")), "Translate L");
        pass(EQ(13, work_translate_estimate("Q")), "Translate Q");
        pass(EQ(9, work_translate_estimate("3L")), "Translate 3L");
        pass(EQ(0, work_translate_estimate("")), "Translate ''");
        END_SET("Translate work estimates");
}

static void test_sum_estimates()
{
        work_init(&m_work[1], "Item 1",
                      "",
                      "Native:2L,Web:M,Apps:Q",
                      "");
        work_init(&m_work[2], "Item 2",
                      "",
                      "Native:5L,Web:2M,Apps:S",
                      "");

        START_SET("Sum estimates");
        //Work_sum_estimates(&m_work[1], 2);
        END_SET("Sum estimates");
}

int main()
{
        test_create_work();
//         test_translate_estimate();
//         test_sum_estimates();
        
        return 0;
}
