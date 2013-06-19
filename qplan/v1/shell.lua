-- Usage: lua -i shell.lua [version]
-- The "version" refers to the save version

-- NOTE: Everything here is global so we can access it from the shell
require('shell_functions')

version = arg[1]

if version then
        print("Loading version: " .. version)
end


-- Load data (at some point, use a prefix to specify a version)
pl, ppl = load_data(version)

-- Set up areas
phone = {"austin", "felix", "soprano", "money"}
tablet = {"tablet"}
rel = {"rapportive", "contacts"}


function rbte(prod_triage)
        -- Construct options
        local options = {}
        if prod_triage then
                options.filter = make_triage_filter(prod_triage)
        end

	-- Identify tracks, and put work into tracks
	local work = pl:get_work_items(options)
	local track_hash = {}
	for i = 1,#work do
		local track = work[i].tags.track
		if not track then
			track = "<no track>"
		end

		track_hash[track] = track_hash[track] or {}
		local work_array = track_hash[track]
		work_array[#work_array+1] = work[i]
	end

	-- Sort track tags
	local track_tags = func.get_table_keys(track_hash)
	table.sort(track_tags)

	for j = 1,#track_tags do
		local cutline_shown = false
		local track = track_tags[j]
		local track_items = track_hash[track]

		-- Sum the track items
		local demand = Work.sum_demand(func.filter(track_items, is_above_cutline))
		local demand_str = Writer.tags_to_string(
			to_num_people(demand, pl.num_weeks), ", ")

		print(track)
		local demand_array = demand_str:split(", ")
		for _, val in ipairs(demand_array) do
			print(val)
		end
		-- print(unpack(demand_array))
	end


	-- Print overall demand total
	-- local total_demand = Work.sum_demand(func.filter(work, is_above_cutline))
	-- local demand_string = Writer.tags_to_string( to_num_people(total_demand, pl.num_weeks))

	-- print(string.format("%-30s %s", "TOTAL Required (for cutline):", Writer.tags_to_string(
	-- 	to_num_people(total_demand, pl.num_weeks), ", "
	-- )))

end

print("READY")
