package.path = package.path .. ";app/?.lua;modules/?.lua"

Person = require('person')
Plan = require('plan')
Work = require('work')
Reader = require('reader')
Writer = require('writer')
func = require('functional')
Select = require('app/select')

require('string_utils')

local Cmd = {}
Cmd.plan = nil
Cmd.staff = nil

function Cmd.init(plan, staff)
        Cmd.plan = plan
        Cmd.staff = staff
end


-- Global environment
env = {}
env.summaries = true




function tagvalue_to_string(tagvalue)
        local result = tagvalue
        if tagvalue == 0 then
                result = ""
        end
        return result
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

-- REPORTING FUNCTIONS --------------------------------------------------------
--
function format_number(num)
        return string.format("%.1f", num)
end

function Cmd.default_work_formatter(work_items)
        local tmp = {}
        tmp[#tmp+1] = "Rank\tID\tName\tTags"
	for i = 1,#work_items do
		local w = work_items[i]
		local rank = w.rank or "--"
		tmp[#tmp+1] = (string.format("#%-4s\t%3s\t%20s\t%s\t%s", rank, w.id, w.name,
                        Writer.tags_to_string(w.triage),
			Writer.tags_to_string(w.tags)))
	end
        return table.concat(tmp, "\n")
end

-- Assuming that work items are in ranked order
function Cmd.rrt_formatter(work_items)
        local tmp = {}
        tmp[#tmp+1] = string.format("%-5s|%-15s|%-40s|%-30s|%-30s",
                             "Rank", "Track", "Item", "Estimate", "Supply left")
	tmp[#tmp+1] =
           ("-----|---------------|----------------------------------------|" ..
                    "------------------------------|--------------------------")

	local feasible_line, _, supply_totals =
                      Work.find_feasible_line(work_items, Cmd.plan.default_supply)

	for i = 1,#work_items do
		local w = work_items[i]
                local totals = Cmd.plan:to_num_people(supply_totals[i])
                totals = func.map_table(format_number, totals)
                tmp[#tmp+1] = string.format("%-5s|%-15s|%-40s|%-30s|%-30s",
                        "#" .. w.rank,
                        w.tags.track:truncate(15),
                        w.name:truncate(40, {["ellipsis"] = true}),
                        Writer.tags_to_string(w.estimates),
                        Writer.tags_to_string(totals)
                        )

		if (w.rank == Cmd.plan.cutline) and (w.rank == feasible_line) then
			tmp[#tmp+1] = "----- CUTLINE/FEASIBLE LINE -----"
		elseif w.rank == Cmd.plan.cutline then
			tmp[#tmp+1] = "----- CUTLINE -----------"
		elseif w.rank == feasible_line then
			tmp[#tmp+1] = "----- FEASIBLE LINE -----"
		end
	end

        return table.concat(tmp, "\n")
end

function Cmd.print_work_items(work_items, work_formatter)
        if work_formatter == nil then
                print(Cmd.default_work_formatter(work_items))
        else
                print(work_formatter(work_items))
        end
end

-- TODO: Add functions that combine functions from Select and the reporting
-- functions





-- -- Returns all work items whose Triage value is 1
-- function wfilter(filter)
-- 	return pl:get_work_items{["filter"] = filter}
-- end
-- 
-- function w1()
--         local f = function(work_item)
--                 return Work.triage_xx_filter(1, work_item)
--         end
--         return wfilter(f)
-- end
-- 
-- -- Returns all work items whose Triage value is 2
-- function w2()
--         local f = function(work_item)
--                 return Work.triage_xx_filter(2, work_item)
--         end
--         return wfilter(f)
-- end
-- 
-- -- Returns all work items whose Triage value is 3
-- function w2()
--         local f = function(work_item)
--                 return Work.triage_xx_filter(3, work_item)
--         end
--         return wfilter(f)
-- end

-- -- Returns true if work is below cutline
-- function wbc_filter(work_item)
--         -- Find rank in plan
--         work_rank = nil
--         for r, work_id in ipairs(pl.work_items) do
--                 if work_id .. '' == work_item.id then
--                         work_rank = r
--                 end
--         end
-- 
--         if work_rank and work_rank > pl.cutline then
--                 return true
--         else
--                 return false
--         end
-- end



-- QPLAN REPORTS --------------------------------------------------------------
--

-- Filters on one or more track labels
function make_track_filter(t)
        local tracks = {}
        if type(t) == "table" then
                tracks = t
        else
                tracks[1] = t
        end

        local result
        result = function(work_item)
                for _, track in pairs(tracks) do
                        if (work_item.tags.track:lower():find(track:lower())) then
                                return true
                        end
                end
                return false
        end

        return result
end

function get_track(work_item)
        return work_item.tags.track
end

function print_work_by_grouping(groupings, work_hash)
	for j = 1,#groupings do
		local cutline_shown = false
		local group = groupings[j]
		local group_items = work_hash[group]

		-- Sum the group items
		local demand = Work.sum_demand(func.filter(group_items, above_cutline_filter))
		local demand_str = Writer.tags_to_string(
			to_num_people(demand, pl.num_weeks), ", ")

		print("== " .. group)

                if env.summaries then
                        print(string.format("     %-5s|%-40s|%6s|", "Rank", "Item", "Triage"))
                        print("     -----|----------------------------------------|" ..
                              "----------|")
                        for i = 1,#group_items do
                                local w = group_items[i]
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
                end
                print(string.format("     Required people: %s", demand_str))
                print()
	end


end

function rbt(t, triage)
        -- Construct options
        local options = {}
        options.filter = {}

        -- Make a track filter, if necessary
        if t then
                if type(t) == "number" then
                        triage = t
                else
                        options.filter[#options.filter+1] = make_track_filter(t)
                end
        end

        -- Make a triage filter, if necessary
        if triage then
                -- Check for 1 vs 1.5, e.g.
                fractional_part = triage % 1
                if fractional_part > 0 then
                        options.filter[#options.filter+1] = function(work_item)
                                return Work.triage_xx_filter(triage - fractional_part, work_item)
                        end
                else
                        options.filter[#options.filter+1] = function(work_item)
                                return Work.triage_filter(triage, work_item)
                        end
                end
        end

        -- Get relevant work
	local work = pl:get_work_items(options)

        -- Group work
        local track_hash, track_tags = func.group_items(work, get_track)

        -- Print work by grouping
        print_work_by_grouping(track_tags, track_hash, options)


	-- Print overall demand total
	local total_demand = Work.sum_demand(func.filter(work, above_cutline_filter))
	print(string.format("%-30s %s", "TOTAL Required (for cutline):", Writer.tags_to_string(
		to_num_people(total_demand, pl.num_weeks), ", "
	)))

        -- If we're filtering the results, return now since there's no point in
        -- printing total supply stats.
        if options.filter ~= {} then
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

-- Report below cutline
function rbc(t, triage)
        -- Construct options
        local options = {}
        options.filter = {}

        -- Make a track filter, if necessary
        if t then
                if type(t) == "number" then
                        triage = t
                else
                        options.filter[#options.filter+1] = make_track_filter(t)
                end
        end

        -- Make a triage filter, if necessary
        if triage then
                -- Check for 1 vs 1.5, e.g.
                fractional_part = triage % 1
                if fractional_part > 0 then
                        options.filter[#options.filter+1] = function(work_item)
                                return Work.triage_xx_filter(triage - fractional_part, work_item)
                        end
                else
                        options.filter[#options.filter+1] = function(work_item)
                                return Work.triage_filter(triage, work_item)
                        end
                end
        end

        -- Filter by below cutline
        options.filter[#options.filter+1] = wbc_filter

        -- Get relevant work
	local work = pl:get_work_items(options)

        -- Group work
        local track_hash, track_tags = func.group_items(work, get_track)

        -- Print work by grouping
        print_work_by_grouping(track_tags, track_hash, options)


	-- Print overall demand total for work below cutline
	local total_demand = Work.sum_demand(work)
	print(string.format("%-40s %s", "TOTAL Required:", Writer.tags_to_string(
		to_num_people(total_demand, pl.num_weeks), ", "
	)))

	-- Print supply left after doing above cutline
	local total_above_cut_demand = Work.sum_demand(wac())
        local total_bandwidth = Person.sum_bandwidth(ppl, pl.num_weeks)
        local net_supply = Work.subtract_skill_demand(total_bandwidth, total_above_cut_demand);
	print(string.format("%-40s %s", "TOTAL Supply (after cutline work):", Writer.tags_to_string(
                to_num_people(net_supply, pl.num_weeks), ", ")))
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


function get_triage(work_item)
        return work_item:merged_triage()
end

function print_by_triage_and_track(file, triage_tags, all_tracks, demand_hash)
        for _, tri in ipairs(triage_tags) do
                -- Print triage

                -- Print track column headings
                file:write(string.format("Triage: %s\t", tri))
                for _, track in ipairs(all_tracks) do
                        file:write(string.format("%s\t", track))
                end
                file:write("\n")

                -- Print Native values
                for _, skill in ipairs{"Apps", "Native", "Web"} do
                        file:write(string.format("%s\t", skill))
                        for _, track in ipairs(all_tracks) do
                                local val = demand_hash[tri][track][skill] or 0
                                file:write(string.format("%.1f\t", val))
                        end
                        file:write("\n")
                end
		file:write("\n")
        end
end

-- This reports demand by triage and track and exports it to disk (to
-- "export.txt")
function rde()
        -- 
        -- Get work items and group by triage and by track
        --
	local work = pl:get_work_items()
        local triage_hash, triage_tags = func.group_items(work, get_triage)

        for _, t in ipairs(triage_tags) do
                local track_hash, track_tags =
                                     func.group_items(triage_hash[t], get_track)

                -- Stuff track groupings back into triage_hash
                triage_hash[t] = {track_hash, track_tags}
        end

        --
        -- Get the union of all track tags
        --
        local all_tracks = {}
        for _, t in ipairs(triage_tags) do
                local track_tags = triage_hash[t][2]
                for _, tag in ipairs(track_tags) do
                        all_tracks[tag] = 1
                end
        end
	all_tracks = func.get_table_keys(all_tracks)
	table.sort(all_tracks)

        --
        -- Map work items into total demand
        --
        local demand_hash = {}
        for _, tri in ipairs(triage_tags) do
                demand_hash[tri] = demand_hash[tri] or {}
                for _, track in ipairs(all_tracks) do
                        demand_hash[tri][track] = demand_hash[tri][track] or {}
                        local work_items = triage_hash[tri][1][track] or {}
                        for _, work in ipairs(work_items) do
                                demand_hash[tri][track] = 
                                to_num_people(Work.sum_demand(work_items), pl.num_weeks)
                        end
                end
        end


        -- Print demand by triage/track
        print_by_triage_and_track(io.stdout, triage_tags, all_tracks, demand_hash)

        -- Also print to file
        local file = assert(io.open("./data/export.txt", "w"))
        print_by_triage_and_track(file, triage_tags, all_tracks, demand_hash)
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
                        print(string.format("     %3d. %-30s %.1f", j, people_list[j].name,
                                                             people_list[j].skills[skill]))
                end
        end

        local total_bandwidth = Person.sum_bandwidth(ppl, pl.num_weeks)
	print(string.format("TOTAL Skill Supply: %s", Writer.tags_to_string(
		to_num_people(total_bandwidth, pl.num_weeks), ", "
	)))
end

function rss()
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
rbt(t):		Report by track. Takes optional track(s) "t" to filter on and triage.
                Using a triage of 1 selects all 1s. Using 1.5 selects 1s and 1.5s.
rde():		Report data export (demand by triage and track)
rs():		Report available supply
]]
	)
end

return Cmd
