-- For many of these functions to work, we need to have a work table set up and
-- added to plan.

local Object = require('object')

local Plan = {}
Plan._new = Object._new

function Plan.new(options)
	id = options.id or ""
	name = options.name or ""
	num_weeks = num_weeks or 13 	-- Default to a quarter
	team_id = options.team_id or ""
	work_items = options.work_items or {}
	cutline = options.cutline or 1
        work_table = options.work_table or {}

	return Plan:_new{
                id = id .. "",
                name = name,
                num_weeks = num_weeks,
	        cutline = cutline,
                work_items = work_items,
                team_id = team_id .. "",
                work_table = work_table
        }
end

function Plan:get_work_items()
	local work_ids = self.work_items or {}
	local result = {}

        for i = 1,#work_ids do
                result[#result+1] = self.work_table[work_ids[i]]
        end

	return result
end

function position_from_options(options)
	local result = 1
	if options == nil then
		return result
	end

	if type(options.at) == "number" then
		result = options.at
	end

	return result
end

-- TODO: Move this to functional
function concat(...)
        local arrays = {...}
        local result = {}

        for i = 1,#arrays do
                local a = arrays[i]
                for j = 1,#a do
                        result[#result+1] = a[j]
                end
        end

        return result
end

-- TODO: Move this to functional
function split_at(n, a)
        local result1, result2 = {}, {}
        if n > #a then n = #a end

        for i = 1,n do
                result1[#result1+1] = a[i]
        end
        for i = n+1, #a do
                result2[#result2+1] = a[i]
        end
        return result1, result2
end

function Plan:rank(input_items, options)
        -- Make sure item elements are all strings and then add them to an
        -- input_set so we can look them up.
	local input_set = {}
	for i = 1,#input_items do
		input_items[i] = input_items[i] .. ""
		input_set[input_items[i]] = true
	end

        -- Separate work items into unchanged and changed items.  We're
        -- iterating over the self.work_items and check against the input_set in
        -- order to filter out garbage.
	local unchanged_array = {}
	local changed_set = {}
	for rank, id in pairs(self.work_items) do
		if input_set[id] then
			changed_set[id] = true
		else
			unchanged_array[#unchanged_array+1] = id
		end
	end

	-- Put changed items back into order they were specified
	local changed_array = {}
        for i = 1,#input_items do
                local id = input_items[i]
		if changed_set[id] then
			changed_array[#changed_array+1] = id
		end
        end

	-- Put changed items into position
        -- Figure out where to put the items in the list.
	local position = position_from_options(options)
        local front, back = split_at(position-1, unchanged_array)
        self.work_items = concat(front, changed_array, back)
end

return Plan
