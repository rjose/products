require('string_utils')

local Reader = {}

function Reader.parse_tags(tag_string)
	local result = {}

	-- First split on multiple tags
	tags = tag_string:split(",")
	for _, str in pairs(tags) do
		local tag, value = unpack(str:split(":"))

                -- Try converting value to a number
                local num = tonumber(value)
                if num then value = num end

		result[tag] = value
	end

	return result
end

return Reader
