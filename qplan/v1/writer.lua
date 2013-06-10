string_utils = require('string_utils')
local Writer = {}


function tags_to_string(tags)
        if not tags then
                return ""
        end

        local result = ""
        for key, value in pairs(tags) do
                result = result .. string.format("%s:%s,", key, value)
        end

        -- Strip trailing comma
        return result:sub(1, -2)
end

function Writer.write_plans(plans, filename)
	local file = assert(io.open(filename, "w"))

	-- Write headers first
	file:write("ID\tName\tNumWeeks\tTeamID\tCutline\tWorkItems\tTags\n")
	file:write("-----\n")

	-- Write plans next
	for _, plan in pairs(plans) do
		file:write(string.format("%s\t%s\t%d\t%s\t%d\t%s\t%s\n", 
			plan.id,
                        plan.name,
                        plan.num_weeks,
                        plan.team_id,
			plan.cutline,
                        string_utils.join(plan.work_items, ","),
                        tags_to_string(plan.tags)
		))
	end
	file:close()
end

function Writer.write_work(work_items, filename)
	local file = assert(io.open(filename, "w"))

	-- Write headers first
	file:write("ID\tName\tTrack\tEstimate\tTags\n")
	file:write("-----\n")

	-- Write work next
	for _, w in pairs(work_items) do
		file:write(string.format("%s\t%s\t%s\t%s\t%s\n", 
			w.id,
                        w.name,
                        w.track,
                        tags_to_string(w.estimates),
                        tags_to_string(w.tags)
		))
	end
	file:close()
end


return Writer
