local Person = require('person')
local Select = require('select')

TestSelect = {}

-- SETUP ----------------------------------------------------------------------
--
function TestSelect:setUp()
	-- Create some people
	self.people = {}

	-- Create some NCGs
	for i = 1,2 do
		self.people[#self.people+1] = Person.new{
			name = "P" .. i,
			skills = {["Native"] = 0.8, ["Apps"] = 0.2},
			tags = {["NCG"] = 1}
		}
	end

	-- Create some non NCGs
	for i = 3,5 do
		self.people[#self.people+1] = Person.new{
			name = "P" .. i,
			skills = {["Native"] = 0.8, ["Apps"] = 0.2},
			tags = {}
		}
	end
end

-- HELPERS --------------------------------------------------------------------
--

function is_ncg(person)
	if person.tags["NCG"] == 1 then
		return true
	else
		return false
	end
end

-- TAGS TESTS -----------------------------------------------------------------
-- TODO: In the selection module, we should be able to select n items

function TestSelect:test_selectByTags()
	local ncg_people = Select.select_items(self.people, is_ncg)
	assertEquals(#ncg_people, 2)
	assertEquals(ncg_people[1].name, "P1")
end

