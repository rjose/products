-- For many of these functions to work, we need to have a work table set up and
-- added to plan.

local func = require('functional')

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


function Plan:rank(input_items, options)
        -- Make sure item elements are all strings and then add them to an
        -- input_set so we can look them up.
	local input_set = {}
	for i = 1,#input_items do
		input_items[i] = input_items[i] .. ""
		input_set[input_items[i]] = true
	end

        -- Separate work items into unchanged and changed items.  We're
        -- iterating over the self.work_items and checking against the input_set
        -- so we can filter out garbage.
	local unchanged_array = {}
	local changed_set = {}
	for rank, id in pairs(self.work_items) do
		if input_set[id] then
			changed_set[id] = true
		else
			unchanged_array[#unchanged_array+1] = id
		end
	end

	-- Put changed items back in order they were specified
	local changed_array = {}
        for i = 1,#input_items do
                local id = input_items[i]
		if changed_set[id] then
			changed_array[#changed_array+1] = id
		end
        end

        -- Insert the ranked items into position
	local position = position_from_options(options)
        local front, back = func.split_at(position-1, unchanged_array)
        self.work_items = func.concat(front, changed_array, back)
end

return Plan
