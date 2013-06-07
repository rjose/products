local Select = {}

-- This takes an array of items and a filter function that can be called on
-- each element. This returns only the items for which the filter is true
function Select.select_items(items, filter)
	local result = {}
	for i = 1,#items do
		if filter(items[i]) then
			result[#result+1] = items[i]
		end
	end
	return result
end

return Select
