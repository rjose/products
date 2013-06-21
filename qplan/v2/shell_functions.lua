Person = require('person')
Plan = require('plan')
Work = require('work')
Reader = require('reader')
Writer = require('writer')
func = require('functional')

require('string_utils')

-- TODO: Talk about naming conventions

-- READ/WRITE DATA ------------------------------------------------------------
--

local data_dir = "./data/"

-- Used to figure out the next work id
local num_work_items


function load_data(prefix)
	local prefix = prefix or ""

	-- NOTE: Right now, we don't write people out
	local ppl = Reader.read_people(data_dir .. "people" .. prefix .. ".txt")

	-- NOTE: For now, assuming only one plan
	local pl = Reader.read_plans(data_dir .. "plan" .. prefix .. ".txt")[1]

	-- Load work items and put them into a table
	local work_array = Reader.read_work(data_dir .. "work" .. prefix .. ".txt")
	num_work_items = #work_array
	local work_table = {}
	for i = 1,#work_array do
		work_table[work_array[i].id] = work_array[i]
	end
	pl.work_table = work_table
	pl.default_supply = Person.sum_bandwidth(ppl, 13)

	return pl, ppl
end

-- "write data"
function wrd(prefix)
	if prefix == nil then
		print("Please specify an explicit prefix")
		return
	end

	-- NOTE: Assuming pl, ppl are global
	Writer.write_plans({pl}, data_dir .. "plan" .. prefix .. ".txt")
	Writer.write_work(pl.work_table, data_dir .. "work" .. prefix .. ".txt")
end

function tagvalue_to_string(tagvalue)
        local result = tagvalue
        if tagvalue == 0 then
                result = ""
        end
        return result
end


-- Export into a form that's suitable for Google Docs
function export()
        local file = assert(io.open("./data/output.txt", "w"))
        file:write("Product Priority\tEngineering Priority\t" ..
                   "Merged Priority\tMobile Track\tProject Name\t" ..
                   "Description\tRequesting Team\tDependencies\t" ..
                   "Tee Shirt Sizes\tNative Wks\tWeb Wks\tApps Wks\t" ..
                   "Notes\n")

        for _, work_id in ipairs(pl.work_items) do
                work = pl.work_table[work_id]
                file:write(string.format("%s\t%s\t%s\t%s\t%s\t" ..
                     "%s\t%s\t%s\t\t%s\t%s\t%s\t%s\n", 
                           tagvalue_to_string(work.triage.ProdTriage),
                           tagvalue_to_string(work.triage.EngTriage),
                           tagvalue_to_string(work.triage.Triage),
                           work.tags.track,
                           work.name,

                           work.tags.Description,
                           work.tags.RequestingTeam,
                           work.tags.Dependencies,
                           work.estimates.Native,
                           work.estimates.Web,
                           work.estimates.Apps,
                           work.tags.Notes
                           ))
        end
        file:close()
end


-- LOW LEVEL PRINTING ---------------------------------------------------------
-- These functions are used to print objects and arrays for inspection. These
-- shouldn't really be used by a typical user.
--

-- Print alias
p = print

-- Print tags (or estimates)
function pt(tags)
	print(Writer.tags_to_string(tags))
end

-- "Print workitems"
function pw(work_items)
	print("Rank\tID\tName\tTags")
	for i = 1,#work_items do
		local w = work_items[i]
		local rank = w.rank or "--"
		print(string.format("#%-4s\t%3s\t%20s\t%s\t%s", rank, w.id, w.name,
                        Writer.tags_to_string(w.triage),
			Writer.tags_to_string(w.tags)))
	end
end





-- WORK SELECTION -------------------------------------------------------------
-- These functions are used to select work items.
--

function above_cutline_filter(work_item)
	if not work_item.rank then
		return false
	else
		return work_item.rank <= pl.cutline
	end
end

-- Selects all "work above cutline"
function wac()
	return pl:get_work_items{["ABOVE_CUT"] = 1}
end

-- Selects all work
function wall()
	return pl:get_work_items{}
end

-- Select work items by rank. If an array is specified, returns an array of
-- work items (ignoring any value out of range)
function r(rank)
	if type(rank) == "number" then
		return pl:get_work(rank)
	elseif type(rank) == "table" then
		return pl:get_work_array(rank)
	else
		print("Couldn't interpret input")
	end
end



-- Returns all work items whose Triage value is 1
function wfilter(filter)
	return pl:get_work_items{["filter"] = filter}
end

function w1()
        local f = function(work_item)
                return Work.triage_xx_filter(1, work_item)
        end
        return wfilter(f)
end

-- Returns all work items whose Triage value is 2
function w2()
        local f = function(work_item)
                return Work.triage_xx_filter(2, work_item)
        end
        return wfilter(f)
end

-- Returns all work items whose Triage value is 3
function w2()
        local f = function(work_item)
                return Work.triage_xx_filter(3, work_item)
        end
        return wfilter(f)
end




-- UPDATING THE PLAN ----------------------------------------------------------
-- These functions are used to update the plan. These are mainly used for
-- changing the relative priority of the work items.
--

-- This is a helper function that essentially maps "get_id" over a set of work
-- items. This is necessary when we need to work with actual work IDs rather
-- than work rankings.
function get_ids(work_items)
	local result = {}
	for i = 1,#work_items do
		result[#result+1] = work_items[i].id
	end
	return result
end

-- Rank work. work_items can be either ids or work objects
function rank(work_items, position)
	if #work_items == 0 then return end

	-- If we have work objects, get the ids
	if type(work_items[1]) == "table" then
		work_items = get_ids(work_items)
	end
	pl:rank(work_items, {["at"] = position})
end


-- "triage sort". This just pulls all of the items Triaged to 1 to the top of the list
-- This ranks items stably.
function tsort()
	-- Get IDs of all 1s and 1.5s
	local ids = get_ids(w1())
	pl:rank(ids)
end

function sc(cutline)
        pl.cutline = cutline
end


-- QPLAN REPORTS --------------------------------------------------------------
--

-- Converts skill_totals in man-weeks into num-people
function to_num_people(skill_totals, num_weeks)
        if skill_totals == nil then
                return {}
        end

	for k, _ in pairs(skill_totals) do
		skill_totals[k] = string.format("%.1f", skill_totals[k] / num_weeks)
	end
	return skill_totals
end


-- "Report running totals"
function rrt()
	print(string.format("%-5s|%-9s|%-40s|%-30s|%-30s",
		"Rank", "Track", "Item", "Estimate", "Supply left"))
	print("-----|---------|----------------------------------------|" ..
              "------------------------------|--------------------------")
	local work = pl:get_work_items()
	local feasible_line, _, supply_totals = pl:find_feasible_line()

	for i = 1,#work do
		local w = work[i]
		print(string.format("%-5s|%-9s|%-40s|%-30s|%-30s",
			"#" .. w.rank,
			w.tags.track,
			w.name:truncate(40, {["ellipsis"] = true}),
			Writer.tags_to_string(w.estimates),
			Writer.tags_to_string(to_num_people(supply_totals[i], pl.num_weeks))
		))

		if (i == pl.cutline) and (i == feasible_line) then
			print("CUTLINE/FEASIBLE LINE -----")
		elseif i == pl.cutline then
			print("----- CUTLINE -----------")
		elseif i == feasible_line then
			print("----- FEASIBLE LINE -----")
		end
	end
end


function make_track_filter(t, triage)
        local tracks = {}
        if type(t) == "table" then
                tracks = t
        else
                tracks[#tracks+1] = t
        end

        result = function(work_item)
                for _, track in pairs(tracks) do
                        if (work_item.tags.track:lower():find(track:lower()) and
                            (triage == nil or
                            (work_item.tags.ProdTriage == triage or
                             work_item.tags.EngTriage == triage))) then
                                return true
                        end
                end
                return false
        end

        return result
end


-- TODO: Make this more generic
-- TODO: Add filter by triage
-- "Report by track". Takes an optional track or array of tracks.
function rbt(t, triage)
        -- Construct options
        local options = {}
        if t then
                options.filter = make_track_filter(t, triage)
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
		local demand = Work.sum_demand(func.filter(track_items, above_cutline_filter))
		local demand_str = Writer.tags_to_string(
			to_num_people(demand, pl.num_weeks), ", ")

		print("== " .. track)

		print(string.format("     %-5s|%-40s|%6s|", "Rank", "Item", "Triage"))
		print("     -----|----------------------------------------|" ..
                      "----------|")
		for i = 1,#track_items do
			local w = track_items[i]
			if w.rank > pl.cutline and cutline_shown == false then
				print("     ----- CUTLINE -----------")
				cutline_shown = true
			end
			print(string.format("     %-5s|%-40s|%-10s|%s",
				"#" .. w.rank,
				w.name:truncate(40, {["ellipsis"] = true}),
				w:merged_triage(),
                                Writer.tags_to_string(w.estimates, ", ")))
		end
		print("     ---------------------------------")
		print(string.format("     Required people: %s", demand_str))
		print()
	end


	-- Print overall demand total
	local total_demand = Work.sum_demand(func.filter(work, above_cutline_filter))
	print(string.format("%-30s %s", "TOTAL Required (for cutline):", Writer.tags_to_string(
		to_num_people(total_demand, pl.num_weeks), ", "
	)))

        -- If we're filtering the results, return now since there's no point in
        -- printing total supply stats.
        if options.filter ~= nil then
                return
        end
	
        -- Print total supply
        local total_bandwidth = Person.sum_bandwidth(ppl, pl.num_weeks)
	print(string.format("%-30s %s", "TOTAL Skill Supply:", Writer.tags_to_string(
		to_num_people(total_bandwidth, pl.num_weeks), ", "
	)))

        -- Print net supply
        -- NOTE: This is a hack, but to_num_people has already converted
        -- total_bandwidth and total_demand to num people!
        local net_supply = Work.subtract_skill_demand(total_bandwidth, total_demand);
	print(string.format("%-30s %s", "TOTAL Net Supply:", Writer.tags_to_string(net_supply, ", ")))
        
end

function make_triage_filter(triage)
        result = function(work_item)
		if work_item.tags.ProdTriage == triage or 
                   work_item.tags.EngTriage == triage then
                	return true
		else
			return false
                end
        end

        return result
end


-- TODO: Make this more generic
function rbts(prod_triage)
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
		local demand = Work.sum_demand(func.filter(track_items, above_cutline_filter))
		local demand_str = Writer.tags_to_string(
			to_num_people(demand, pl.num_weeks), ", ")

		-- print(string.format('%s', track))
		-- print("     ---------------------------------")
		-- print(string.format("     Required people: %s", demand_str))
                
                
	end


	-- Print overall demand total
	local total_demand = Work.sum_demand(func.filter(work, above_cutline_filter))
	print(string.format("%-30s %s", "TOTAL Required (for cutline):", Writer.tags_to_string(
		to_num_people(total_demand, pl.num_weeks), ", "
	)))

	-- TODO: Figure out how to handle supply
	
end

-- TODO: Tie this into a more generic call
-- TODO: Make this export more nicely (esp with missing fields)
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
        local track_string = "" 
        local demand_string_table = {}

	for j = 1,#track_tags do
		local track = track_tags[j]
		local track_items = track_hash[track]

		-- Sum the track items
		local demand = Work.sum_demand(func.filter(track_items, above_cutline_filter))
		local demand_str = Writer.tags_to_string(
			to_num_people(demand, pl.num_weeks), ", ")

                track_string = track_string .. track .. "\t"
		local demand_array = demand_str:split(", ")
		for _, val in ipairs(demand_array) do
                        local demand_pair = val:split(":")
                        local d = demand_string_table[demand_pair[1]]
                        if d then
                                d = d .. demand_pair[2] .. "\t"
                        else
                                d = demand_pair[2] .. "\t"
                        end
                        demand_string_table[demand_pair[1]] = d
		end
	end

        -- Print result and also export to rbte.txt
        prod_triage = prod_triage or ""
        local file = assert(io.open("./data/rbte" .. prod_triage .. ".txt", "w"))
        file:write(string.format("%s\n", track_string))
        print(track_string)
        for t, s in pairs(demand_string_table) do
                local str = string.format("%s\t%s\n", t, s)
                file:write(str)
                print(str)
        end
        file:close()
end


-- Prints available people by skill
function rs()
        local people_by_skill = {}

        for _, person in ipairs(ppl) do
                local skill_tag = Writer.tags_to_string(person.skills):split(":")[1]
                skill_tag = skill_tag or "_UNSPECIFIED"
                people_list = people_by_skill[skill_tag] or {}
                people_list[#people_list+1] = person
                people_by_skill[skill_tag] = people_list
        end

	local skill_tags = func.get_table_keys(people_by_skill)
	table.sort(skill_tags)

	for i = 1,#skill_tags do
                local skill = skill_tags[i]
                local people_list = people_by_skill[skill]
                print(string.format("%s ==", skill))
                for j = 1,#people_list do
                        print(string.format("     %3d. %s", j, people_list[j].name))
                end
        end

        local total_bandwidth = Person.sum_bandwidth(ppl, pl.num_weeks)
	print(string.format("TOTAL Skill Supply: %s", Writer.tags_to_string(
		to_num_people(total_bandwidth, pl.num_weeks), ", "
	)))
end


-- HELP -----------------------------------------------------------------------
--

function help()
	print(
[[
-- Reading/Writing
load(n):	Loads data from disk. Suffix "n" is optional.
wrd(n):		Writes data to file with suffix "n"
export():	Writes data to "data/output.txt" in a form for Google Docs

-- Printing
p():		Alias for print
pw(ws):		Print work items "ws"

-- Select work
r(rank):	Selects work item at rank 'rank'. May also take an array of ranks.
wall():		Selects all work in plan
wac():		Selects work above cutline
w1():		Work with overall triage of 1
w2():		Work with overall triage of 2

-- Updating plan
rank(ws, p):	Ranks work items "ws" at position "p". May use work items or IDs.
sc(num):	Sets cutline

-- Reports
rfl():		Report feasible line.
rrt():		Report running totals
rbt(t):		Report by track. Takes optional track(s) "t" to filter on
rbte(p):	Report by track export with optional triage "p"
rs():		Report available supply
]]
	)
end
