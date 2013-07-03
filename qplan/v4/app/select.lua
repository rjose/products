local Select = {}

function Select.all_work(plan)
	return plan:get_work_items()
end

-- TODO: Implement
function Select.apply_filters(work_item, filters)
end

-- TODO: Implement
function Select.merge_work(work_item_arrays)
end

return Select
