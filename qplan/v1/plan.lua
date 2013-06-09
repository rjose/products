--[[

A Plan is used to figure out how much work a team can commit to. A Plan has
access to information about relevant Work items and maintains information about
the relative priority of each work item. This is stored in the work_items field,
which is a ranked list of work IDs. A Plan also has a cutline that separates the
list into things that will be committed to and things that won't be.

A Plan provides an array of work items in priority order via get_work_items. We
pass an options table to this function to filter the selected work items. For
instance, by passing in {["ABOVE_CUT" = 1}, we select work that's above the
cutline. This is a convention we follow for all types of selections.

An important feature of Plans is that they enable us to re-rank items. We rank
items by specifying an array of work IDs (not necessarily contiguous) and a
position that the first item should start at. By default, items are placed at
the top of the list. The rest of the list maintains its relative order.

Another feature of Plans is that they can compute running demand totals (by
skill) and net supply totals (also by skill). The demand totals are presented in
the work item ranking order. This information can be used to determine if a plan
is feasible (i.e., the net supply of items above the cutline is >= 0 for all
skills). This can also be used to determine the "feasible line" -- the lowest
feasible cutline.

]]--


local func = require('functional')
local Work = require('work')

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
        default_supply = options.default_supply or {}

	return Plan:_new{
                id = id .. "",
                name = name,
                num_weeks = num_weeks,
	        cutline = cutline,
                work_items = work_items,
                team_id = team_id .. "",
                default_supply = default_supply,
                work_table = work_table
        }
end

-- SELECTING WORK ITEMS -------------------------------------------------------
--

-- Should be able to specify a predicate
function Plan:get_work_items(options)
	local work_ids = self.work_items or {}
	local result = {}
        options = options or {}

        local stop_index = #work_ids
        
        -- If specified, return work items above the cutline
        if options.ABOVE_CUT then
                stop_index = self.cutline
        end

        for i = 1, stop_index do
                result[#result+1] = self.work_table[work_ids[i]]
        end

	return result
end


-- COMPUTE RUNNING TOTALS -----------------------------------------------------
--

function Plan:get_demand_totals(options)
        local work_items = self:get_work_items(options)
        return Work.sum_demand(work_items)
end

function Plan:get_supply_totals(options)
        local demand_total, running_demand = self:get_demand_totals(options)

        local running_supply = {}
	for i = 1,#running_demand do
		running_supply[#running_supply+1]= Work.subtract_skill_demand(
                        self.default_supply,
                        running_demand[i]
                )
	end

	return running_supply[#running_supply], running_supply, running_demand
end


-- PRIORITIZING WORK ----------------------------------------------------------
--

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


-- PLAN FEASIBILITY -----------------------------------------------------------
--

function is_any_skill_negative(skills)
	local result = false
	for skill, avail in pairs(skills) do
		if avail < 0 then
			result = true
			break
		end
	end
	return result
end

function Plan:is_feasible()
	local net_supply = self:get_supply_totals({["ABOVE_CUT"] = 1})
	local is_feasible = not is_any_skill_negative(net_supply)
	return is_feasible, net_supply
end

function Plan:find_feasible_line()
	local work_items = self:get_work_items()
	local feasible_line = #work_items

	local _, running_supply, running_demand = self:get_supply_totals()

	for i = 1,#running_supply do
		if is_any_skill_negative(running_supply[i]) then
			feasible_line = i - 1
			break
		end
	end

	return feasible_line, running_demand, running_supply
end


return Plan
