local Work = require("work")

TestWork = {}

-- SETUP ----------------------------------------------------------------------
--
function TestWork:setUp()
        self.work = {}
        self.work[1] = Work.new{name = "Do work item 1",
                                track = "Track1",
				tags = {["track"] = "Track1",
				        ["PP"] = 1,
                                        ["EP"] = 2},
                                estimates = {["Native"] = "2L",
                                             ["Web"] = "M",
                                             ["Server"] = "Q",
                                             ["BB"] = "S"}}

        -- Add a few more work items
        for i = 2, 4 do
                self.work[i] = Work.new{name = "Task" .. i,
				tags = {["track"] = "Track1",
				        ["PP"] = 2,
                                        ["EP"] = 3},
                                estimates = {["Native"] = "L",
                                             ["Web"] = i .. "M",
                                             ["Server"] = "Q",
                                             ["BB"] = "S"}}
        end

end


-- ESTIMATE TESTS -------------------------------------------------------------
--

function TestWork:test_setEstimate1()
	self.work[1]:set_estimate("Native", "S")
	assertEquals(self.work[1].estimates["Native"], "S")
end


-- Make sure we handle bad input properly
function TestWork:test_setEstimate2()
	self.work[1]:set_estimate("Native", "!S")
	assertEquals(self.work[1].estimates["Native"], "2L")
end


-- PARSING TESTS --------------------------------------------------------------
--

-- Used to translate the estimate string for a work item (like "4L")
function TestWork:test_translateEstimate()
        assertEquals(Work.translate_estimate("S"), 1)
        assertEquals(Work.translate_estimate("M"), 2)
        assertEquals(Work.translate_estimate("L"), 3)
        assertEquals(Work.translate_estimate("Q"), 13)
        assertEquals(Work.translate_estimate("3L"), 9)
        assertEquals(Work.translate_estimate("2Q"), 26)
end

function TestWork:test_translateBlankEstimate()
        assertEquals(Work.translate_estimate(""), 0)
end

function TestWork:test_skillDemand()
        local skill_demand = self.work[1]:get_skill_demand()
        local expected = {["Native"] = 6, ["Web"] = 2,
                          ["Server"] = 13, ["BB"] = 1}
        for skill, estimate in pairs(expected) do
                assertEquals(skill_demand[skill], expected[skill])
        end
end

-- SUMMING TESTS --------------------------------------------------------------
--
function TestWork:test_sumWorkDemand()
        -- Try just a single item
        local sum1 = Work.sum_demand({self.work[1]})
        local expected1 = {["Native"] = 6, ["Web"] = 2,
                          ["Server"] = 13, ["BB"] = 1}
        for skill, estimate in pairs(expected1) do
                assertEquals(sum1[skill], expected1[skill])
        end

        -- Try a bunch of items
        local expected2 = {["Native"] = 6+9, ["Web"] = 2+4+6+8,
                          ["Server"] = 13+39, ["BB"] = 1+3}
        local sum2 = Work.sum_demand(self.work)
        for skill, estimate in pairs(expected1) do
                assertEquals(sum2[skill], expected2[skill])
        end
end

function TestWork:test_runningDemand()
        local expected = {
                {["Native"] = 6, ["Web"] = 2, ["Server"] = 13, ["BB"] = 1},
                {["Native"] = 6+3, ["Web"] = 2+4, ["Server"] = 2*13, ["BB"] = 2},
                {["Native"] = 6+6, ["Web"] = 6+6, ["Server"] = 3*13, ["BB"] = 3},
                {["Native"] = 6+9, ["Web"] = 12+8, ["Server"] = 4*13, ["BB"] = 4}
        }
        local totals = Work.running_demand(self.work)

        assertEquals(#totals, #expected)
        for i = 1,#expected do
                for skill, value in pairs(expected[i]) do
                        print(skill, totals[i][skill], value)
                        assertEquals(totals[i][skill], value)
                end
        end
end
