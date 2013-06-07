local Person = require('person')
local Select = require('select')

TestPerson = {}

-- SETUP ----------------------------------------------------------------------
--
function TestPerson:setUp()
	self.person = Person.new{
		name = "P1",
		skills = {["Native"] = 0.8, ["Apps"] = 0.2},
		tags = {["NCG"] = 1}
	}
	self.person2 = Person.new{
		name = "P2",
		skills = {["Native"] = 0.8, ["Apps"] = 0.2},
		tags = {}
	}
	self.people = {self.person, self.person2}
end

-- HELPERS --------------------------------------------------------------------
--

-- This takes arguments of the form {["Skill1"] = 2, ["Skill2"] = 4} and
-- makes sure they are the same.
function check_skills(actual, expected)
	for skill, val in pairs(expected) do
		assertEquals(actual[skill], val)
	end
end

-- This is a filter used to select people with an NCG tag
function is_ncg(person)
	if person.tags["NCG"] == 1 then
		return true
	else
		return false
	end
end

-- BANDWIDTH TESTS ------------------------------------------------------------
--

function TestPerson:test_getBandwidth()
	local expected = {
		["Native"] = 0.8*13, ["Apps"] = 0.2*13
	}
	local avail = self.person:get_skill_avail(13)
	check_skills(avail, expected)
end

function TestPerson:test_sumBandwidth()
	local expected = {
		["Native"] = 0.8*13, ["Apps"] = 0.2*13
	}
	local avail = Person.sum_bandwidth({self.person}, 13)
	check_skills(avail, expected)
end

function TestPerson:test_sumBandwidth2()
	local expected = {
		["Native"] = 2*0.8*13, ["Apps"] = 2*0.2*13
	}
	local avail = Person.sum_bandwidth({self.person, self.person}, 13)
	check_skills(avail, expected)
end

-- TAGS TESTS -----------------------------------------------------------------
-- TODO: Move the functionality to a selection module
-- TODO: In the selection module, we should be able to select n items

function TestPerson:test_tags()
	local ncg_people = Select.select_items(self.people, is_ncg)
	assertEquals(#ncg_people, 1)
	assertEquals(ncg_people[1].name, "P1")
end
