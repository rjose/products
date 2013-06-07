Object = require('object')

local Person = {}
Person._new = Object._new

function Person.new(options)
	id = options.id or ""
        name = options.name or ""
        skills = options.skills or {}
        tags = options.tags or {}

	return Person:_new{
		id = id .. "", name = name, skills = skills, tags = tags
	}
end

function Person:get_bandwidth(num_weeks)
	local result = {}
	for skill, frac in pairs(self.skills) do
		result[skill] = frac * num_weeks
	end
	return result
end


-- TODO: Convert this into a functional version
function add_bandwidth(a1, a2)
	local result = {}
	for k, v in pairs(a1) do result[k] = v end

        for skill, avail in pairs(a2) do
                if result[skill] then
			result[skill] = result[skill] + avail
                else
                        result[skill] = avail
                end
        end
        return result
end


-- This takes an array of people and the number of weeks over which we're
-- interested in their bandwidth. This returns a table of skills to weeks
-- available for that skill. E.g., {["Apps"] = 13}
function Person.sum_bandwidth(people, num_weeks)
	local result = {}
	for i = 1,#people do
		result = add_bandwidth(result, people[i]:get_bandwidth(num_weeks))
	end
	return result
end


return Person
