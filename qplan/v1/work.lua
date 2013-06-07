--[[


]]--

Object = require('object')

local Work = {}
Work._new = Object._new

function Work.new(options)
	id = options.id or ""
	estimates = options.estimates or {}
        name = options.name or ""
        track = options.track or ""
	tags = options.tags or {}

	return Work:_new{id = id .. "", name = name, track = track,
	                 estimates = estimates, tags = tags}
end

-- TODO: Move this to Writer
-- function Work:get_estimate_string()
-- 	local result = ""
-- 	estimates = self.estimates or {}
-- 	for skill, estimate in pairs(estimates) do
-- 		result = result .. string.format("%s: %s, ", skill, estimate)
-- 	end
-- 
-- 	-- Strip trailing comma
-- 	return result:sub(1, -3)
-- end

-- TODO: Add a test for this
-- function Work.add_work(work_item)
-- 	local new_id = max_work_item_id + 1
-- 	max_work_item_id = new_id
-- 	work_item.id = new_id .. ""
-- 
-- 	-- Add to global work list
-- 	Work.work[work_item.id] = work_item
-- end

-- function Work.delete_work(id)
-- 	-- Delete work item from table
-- 	Work.work[id] = nil
-- end


-- TODO: Add tests for this
-- function Work:add_estimate(skill_name, estimate_string)
-- 	self.estimates[skill_name] = estimate_string
-- end
-- 
-- function Work:clear_estimate()
-- 	self.estimates = {}
-- end

-- This converts a T-shirt estimate label into a number of weeks
function Work.translate_estimate(est_string)
        local scalar = 1
        local unit
        local units = {["S"] = 1, ["M"] = 2, ["L"] = 3, ["Q"] = 13}

        -- Look for something like "4L"
        for u, _ in pairs(units) do
                scalar, unit = string.match(est_string, "^(%d*)(" .. u .. ")")
                if unit then break end
        end

        -- If couldn't find a unit, then return 0
        if unit == nil then
                io.stderr:write("Unable to parse: ", est_string)
                return 0
        end

        -- If couldn't find a scalar, it's 1
        if scalar == "" then scalar = 1 end

        return scalar * units[unit]
end

function Work:get_skill_demand()
        local result = {}
        for skill, est_str in pairs(self.estimates) do
                result[skill] = Work.translate_estimate(est_str)
        end
        return result
end


-- TODO: Find the right lisp function name for this and rename
function apply_op_to_work_arrays(op, a1, a2)
	-- Start by copying a1 into result
	local result = {}
	for k, v in pairs(a1) do result[k] = v end

        for skill, num_weeks in pairs(a2) do
                if result[skill] then
			result[skill] = op(result[skill], num_weeks)
                else
                        result[skill] = num_weeks
                end
        end
        return result
end

function add_weeks(w1, w2)
	return w1 + w2
end

function subtract_weeks(w1, w2)
	return w1 - w2
end

function Work.add_estimates(est1, est2)
	return apply_op_to_work_arrays(add_weeks, est1, est2)
end

function Work.subtract_estimates(est1, est2)
	return apply_op_to_work_arrays(subtract_weeks, est1, est2)
end


-- TODO: Have this return the running demand as well
function Work.sum_demand(work_items)
        local result = {}
        for i = 1,#work_items do
                result = Work.add_estimates(result,
                                            work_items[i]:get_skill_demand())
        end
        return result
end

function Work.running_demand(work_items)
        -- Get an array of estimates
        local estimates = {}

	for i = 1,#work_items do
                estimates[#estimates+1] = work_items[i]:get_skill_demand()
	end

        -- Compute running totals
        local result = {}
        local cur_total = {}

	for i = 1,#estimates do
                cur_total = Work.add_estimates(cur_total, estimates[i])
                result[#result+1] = cur_total
	end

        return result
end


-- TODO: Move this to a reports module
-- function Work.print_work_item(work_item)
-- 	io.write(string.format("%3s - %-40s %s\n", work_item.id,
-- 	                       work_item.name, work_item:get_estimate_string()))
-- end
-- 
-- function Work.print_work_items(work_items)
-- 	for i = 1,#work_items do
-- 		if type(work_items[i]) == "string" then
-- 			print(work_items[i])
-- 		else
-- 			Work.print_work_item(work_items[i])
-- 		end
-- 	end
-- end

return Work
