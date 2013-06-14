Person = require('person')
Plan = require('plan')
Work = require('work')
Reader = require('reader')
Writer = require('writer')
func = require('functional')

-- TODO: Talk about naming conventions

-- DATA READ/WRITE ------------------------------------------------------------
--

local data_dir = "./data/"

-- Used to figure out the next work id
local num_work_items


function load_data(prefix)
	local prefix = prefix or ""

	-- NOTE: Right now, we don't write people out
	local ppl = Reader.read_people(data_dir .. "people" .. ".txt")

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
		print(string.format("#%-4s\t%3s\t%20s\t%s", rank, w.id, w.name,
			Writer.tags_to_string(w.tags)))
	end
end


-- TRIAGING WORK ITEMS --------------------------------------------------------
--
-- TODO: Explain triaging a bit more
--

-- This is an internal helper function to support different types of work
-- triage.
function triage_work(rank, level, tag_key)
	local work = r(rank)
	if not work then
		return
	end

	work.tags[tag_key] = level
end

-- Triage work for Product
function twp(rank, level)
	triage_work(rank, level, 'ProdTriage')
end

-- Triage work for Engineering
function twe(rank, level)
	triage_work(rank, level, 'EngTriage')
end

-- Triage work (overall)
function tw(rank, level)
	triage_work(rank, level, 'Triage')
end


-- TRIAGE FILTERS -------------------------------------------------------------
-- These are used for filtering work items by triage grouping.
--

function is_triage1(work_item)
	local value = work_item.tags.Triage
	if not value then value = 100 end
	return (value >= 1) and (value < 2)
end

function is_triage2(work_item)
	local value = work_item.tags.Triage
	if not value then value = 100 end
	return (value >= 2) and (value < 3)
end

function is_prod_triage1(work_item)
	local value = work_item.tags.ProdTriage
	if not value then value = 100 end
	return (value >= 1) and (value < 2)
end

function is_prod_triage2(work_item)
	local value = work_item.tags.ProdTriage
	if not value then value = 100 end
	return (value >= 2) and (value < 3)
end

function is_eng_triage1(work_item)
	local value = work_item.tags.EngTriage
	if not value then value = 100 end
	return (value >= 1) and (value < 2)
end

function is_eng_triage2(work_item)
	local value = work_item.tags.EngTriage
	if not value then value = 100 end
	return (value >= 2) and (value < 3)
end

-- Returns true if there's a conflict between the Eng and Product 1 priorities
function is_conflict1(work_item)
	local prod_triage = work_item.tags.ProdTriage
	local eng_triage = work_item.tags.EngTriage

	if (prod_triage == 1) and (eng_triage == nil) then
		return false
	elseif (prod_triage == 1) and (eng_triage ~= 1) then
		return true
	elseif (prod_triage == nil) and (eng_triage == 1) then
		return false
	elseif (prod_triage ~= 1) and (eng_triage == 1) then
		return true
	else
		return false
	end
end


-- WORK SELECTION -------------------------------------------------------------
-- These functions are used to select work items.
--

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
function w1()
	return pl:get_work_items{["filter"] = is_triage1}
end

-- Returns all work items whose Triage value is 1
function w2()
	return pl:get_work_items{["filter"] = is_triage2}
end

-- Returns all work items whose ProdTriage value is 1
function wprod1()
	return pl:get_work_items{["filter"] = is_prod_triage1}
end

-- Returns all work items whose ProdTriage value is 1
function wprod2()
	return pl:get_work_items{["filter"] = is_prod_triage2}
end

-- Returns all work items whose EngTriage value is 1
function weng1()
	return pl:get_work_items{["filter"] = is_eng_triage1}
end

-- Returns all work items whose EngTriage value is 1
function weng2()
	return pl:get_work_items{["filter"] = is_eng_triage2}
end

-- Returns all items where there is conflict between Prod and Eng over 1s
function wc1()
	return pl:get_work_items{["filter"] = is_conflict1}
end



-- ESTIMATING WORK ------------------------------------------------------------
--

-- These are the various skill types we have
SA = "Apps"
SN = "Native"
SW = "Web"
SS = "SET"
SU = "UX"
SB = "BB"

-- Sets the estimate for a work item. This takes the rank of the work item in
-- question and a set of pairs of the form (skill, estimate).
function est(rank, ...)
	local work = r(rank)
	if not work then
		return
	end

	local est_pairs = table.pack(...)

	if (#est_pairs % 2) == 1 then
		io.stderr:write("Must have an even number of estimate pairs")
		return
	end

	for i = 1, #est_pairs-1, 2 do
		local skill = est_pairs[i]
		local estimate = est_pairs[i+1]
		work:set_estimate(skill, estimate)
	end

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

-- Add work
function aw(name)
	-- Add work to work_table
	local new_id = num_work_items+1
	local new_work = Work.new{
		id = new_id .. "",
		name = name
	}
	-- TODO: Maybe move this to a function to hide the current hackiness
	num_work_items = num_work_items + 1
	pl.work_table[new_work.id] = new_work

	-- Add work to plan's ranked work_items
	pl.work_items[#pl.work_items+1] = new_work.id
end

-- "triage sort". This just pulls all of the items Triaged to 1 to the top of the list
function tsort()
	-- Get IDs of all 1s
	local ids = get_ids(w1())
	pl:rank(ids)
end


-- QPLAN REPORTS --------------------------------------------------------------
--

-- "Report feasible line"
function rfl()
	local fl, demand, supply = pl:find_feasible_line()
	-- TODO: Pretty this up
	print(string.format("Feasible line: %d", fl))
	print(string.format("Cutline: %d", pl.cutline))
	print(string.format("Items below feasible line: %d", #pl.work_items-fl))

	local total_supply = supply[#supply]
	print("People Left")
	print("-----------")
	for skill, net in pairs(total_supply) do
		print(string.format("%10s %.1f", skill, net/pl.num_weeks))
	end
end

-- Converts skill_totals in man-weeks into num-people
function to_num_people(skill_totals, num_weeks)
	for k, _ in pairs(skill_totals) do
		skill_totals[k] = string.format("%.1f", skill_totals[k] / num_weeks)
	end
	return skill_totals
end

-- "Report running totals"
function rrt()
	print(string.format("%-5s|%-9s|%-20s|%-30s|%-30s",
		"Rank", "Track", "Item", "Estimate", "Supply left"))
	print("-----|---------|--------------------|------------------------------|--------------------------")
	local work = pl:get_work_items()
	local feasible_line, _, supply_totals = pl:find_feasible_line()

	for i = 1,#work do
		local w = work[i]
		print(string.format("%-5s|%-9s|%-20s|%-30s|%-30s",
			"#" .. w.rank,
			w.tags.track,
			w.name,
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


-- TODO: Report totals only by those above the cutline
-- "Report by track"
function rbt()
	-- Identify tracks, and put work into tracks
	local work = pl:get_work_items()
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
		local demand = Work.sum_demand(track_items)
		local demand_str = Writer.tags_to_string(
			to_num_people(demand, pl.num_weeks), ", ")

		print("== " .. track)

		print(string.format("     %-5s|%-20s|%6s", "Rank", "Item", "Triage"))
		print("     -----|--------------------|------")
		for i = 1,#track_items do
			local w = track_items[i]
			if w.rank > pl.cutline and cutline_shown == false then
				print("     ----- CUTLINE -----------")
				cutline_shown = true
			end
			print(string.format("     %-5s|%-20s|%-10s",
				"#" .. w.rank,
				w.name,
				w.tags.Triage))
		end
		print("     ---------------------------------")
		print(string.format("     Required people: %s", demand_str))
		print()
	end
	
	-- Print overall demand total
	local total_demand = Work.sum_demand(work)
	print(string.format("TOTAL Required People: %s", Writer.tags_to_string(
		to_num_people(total_demand, pl.num_weeks), ", "
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

-- Printing
p():		Alias for print
pw(ws):		Print work items "ws"

-- Triage
twp(r,l):	Triage work at rank 'r' and level 'l' (1, 2, 3) for Product
twe(r,l):	Triage work at rank 'r' and level 'l' (1, 2, 3) for Eng
tw(r,l):	Triage work at rank 'r' and level 'l' (1, 2, 3) for Overall

-- Select work
r(rank):	Selects work item at rank 'rank'. May also take an array of ranks.
wall():		Selects all work in plan
wac():		Selects work above cutline
w1():		Work with overall triage of 1
w2():		Work with overall triage of 2
wprod1():	Work with Product triage of 1
wprod2():	Work with Product triage of 2
weng1():	Work with Eng triage of 1
weng2():	Work with Eng triage of 2
wc1():		Work with conflicts of 1s between Prod and Eng

-- Updating work
est(r, s, e):	Set estimate of work ranked at 'r'. Takes pairs of skill/T-shirt pairs

-- Updating plan
rank(ws, p):	Ranks work items "ws" at position "p". May use work items or IDs.
aw(name):	Adds work to plan.

-- Reports
rfl():		Report feasible line.
rrt():		Report running totals
rbt():		Report by track
]]
	)
end
