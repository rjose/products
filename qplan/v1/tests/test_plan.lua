local Work = require("work")
local Plan = require("plan")

TestPlan = {}

--[[
- Adding a work item to a plan should take an existing work item. It shouldn't
  create one. It's OK to have a shell function that does both steps
- Get ranked items shouldn't return a cutline object in the result. The
  reporting function can use the plan data to do this when creating output.
- When adding work to a plan, should be able to specify position in the list.
  Should use same semantics as ranking.
- When adding work to a plan, should be able to specify a tag (like triaging
  info)
- When creating work items for a test, use the Work constructor
- Come up with better naming convention for running_totals functions
- Need to add tests for adding work items to plan, especially at a given position
--]]
--
-- SETUP ----------------------------------------------------------------------
--
function TestPlan:setUp()
        -- Set up some work
        local work = {}
        for i = 1, 10 do
                local id = i .. ""
                work[id] = Work.new{
                        id = id,
                        name = "Task" .. i,
                        tags = {["track"] = "Saturn", ["pri"] = 1},
                        estimates = {
                                ["Native"] = "L",
                                ["Web"] = "M",
                                ["Server"] = "Q",
                                ["BB"] = "S"
                        }
                }
        end
        work['1'].tags.pri = 2
        work['1'].tags.track = 'Penguin'
        work['4'].tags.pri = 2
        work['4'].tags.track = 'Penguin'

        self.plan = Plan.new{
                id = 1,
                name = "MobileQ3",
                num_weeks = 13,
                team_id = 0,
                work_items = {'1', '2', '3', '4', '5', '6', '7', '8', '9', '10'},
                tags = {},
                work_table = work,
                cutline = 5
        }
end

function TestPlan.check_rankings(ranked_items, expected_rankings)
        local ranked_string = ""
        for i = 1,#ranked_items do
                ranked_string = ranked_string .. ranked_items[i].id
        end

        local expected_string = ""
        for i = 1,#expected_rankings do
                expected_string = expected_string .. expected_rankings[i]
        end

        assertEquals(ranked_string, expected_string)
end

function TestPlan:test_initialRankings()
        local expected_rankings = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
        local ranked_items = self.plan:get_work_items()
        TestPlan.check_rankings(ranked_items, expected_rankings)
end

function TestPlan:test_applyRanking1()
        local expected_rankings = {7, 8, 9, 1, 2, 3, 4, 5, 6, 10}
        self.plan:rank({7, 8, 9})
        local ranked_items = self.plan:get_work_items()
        TestPlan.check_rankings(ranked_items, expected_rankings)
end

function TestPlan:test_applyRanking2()
        local expected_rankings = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
        self.plan:rank({1, 2, 3})
        local ranked_items = self.plan:get_work_items()
        TestPlan.check_rankings(ranked_items, expected_rankings)
end

function TestPlan:test_applyRanking3()
        local expected_rankings = {7, 8, 9, 1, 2, 3, 4, 5, 6, 10}
        self.plan:rank({7, 8, 9})
        self.plan:rank({7, 8, 9})
        local ranked_items = self.plan:get_work_items()
        TestPlan.check_rankings(ranked_items, expected_rankings)
end

-- TODO: Test edge cases for ranking

function TestPlan:test_applyRanking4()
        local expected_rankings = {1, 2, 3, 7, 8, 9, 4, 5, 6, 10}
        self.plan:rank({7, 8, 9}, {at = 4})
        local ranked_items = self.plan:get_work_items()
        TestPlan.check_rankings(ranked_items, expected_rankings)
end

function TestPlan:test_applyRanking5()
        local expected_rankings = {1, 3, 2, 7, 8, 9, 4, 5, 6, 10}
        self.plan:rank({7, 8, 9}, {at = 4})
        self.plan:rank({3, 2}, {at = 2})
        local ranked_items = self.plan:get_work_items()
        TestPlan.check_rankings(ranked_items, expected_rankings)
end

function TestPlan:test_applyRanking6()
        local expected_rankings = {4, 5, 6, 7, 8, 9, 10, 2, 1, 3}
        self.plan:rank({2, 1, 3}, {at = 8})
        local ranked_items = self.plan:get_work_items()
        TestPlan.check_rankings(ranked_items, expected_rankings)
end

function TestPlan:test_applyRanking7()
        local expected_rankings = {1, 3, 5, 2, 4, 10, 6, 7, 8, 9}
        self.plan:rank({2, 4, 10, 6}, {at = 4})
        local ranked_items = self.plan:get_work_items()
        TestPlan.check_rankings(ranked_items, expected_rankings)
end
