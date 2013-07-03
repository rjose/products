local Select = {}

function Select.all_work(plan)
	return plan:get_work_items()
end

-- Rank can be a single number or an array of numbers
function Select.work_with_rank(plan, rank)
        local result = {}

	if type(rank) == "number" then
		result = {plan:get_work(rank)}
                print("Number", rank, #result)
	elseif type(rank) == "table" then
		result = plan:get_work_array(rank)
	else
		print("Couldn't interpret input")
	end

        return result
end


function Select.apply_filters(work_items, filters)
        local result = {}
        for i, w in ipairs(work_items) do
                for _, filter in ipairs(filters) do
                        if filter(w, i) then
                                result[#result+1] = w
                                break
                        end
                end
        end
        return result
end

function Select.merge_work(work_item_arrays)
        local result = {}
        for _, work_items in ipairs(work_item_arrays) do
                for _, w in ipairs(work_items) do
                        result[#result+1] = w
                end
        end
        return result
end

-- FILTER FUNCTIONS -----------------------------------------------------------
--

function Select.invert_filter(filter)
        local result = function(work_item, index)
                return not filter(work_item, index)
        end
end

function Select.make_above_cutline_filter(plan)
        local result = function(work_item)
                if not work_item.rank then
                        return false
                else
                        return work_item.rank <= plan.cutline
                end
        end
        return result
end


function Select.make_below_cutline_filter(plan)
        return Select.invert_filter(Select.make_above_cutline_filter(plan))
end



return Select
