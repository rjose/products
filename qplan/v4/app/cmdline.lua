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


-- Print alias
p = print


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

function Cmd.default_work_hash_formatter(work_hash, keys, options)
        local options = options or {}
        local total_demand = {}
        local tmp = {}
        local with_detail = not options.without_detail
        local with_net_supply = not options.without_net_supply

        print("Default formatter", options.with_detail, options.with_net_supply)
	for j = 1,#keys do
		local cutline_shown = false
		local key = keys[j]
		local work_items = work_hash[key]

		-- Sum the key items
		local demand = Work.sum_demand(work_items)
		local demand_str = Writer.tags_to_string(
                        func.map_table(format_number, Cmd.plan:to_num_people(demand)), ", ")
                total_demand = Work.add_skill_demand(total_demand, demand)

		tmp[#tmp+1] = "== " .. key

                if with_detail then
                        tmp[#tmp+1] = string.format("     %-5s|%-40s|%6s|", "Rank", "Item", "Triage")
                        tmp[#tmp+1] = "     -----|----------------------------------------|" ..
                                                                                        "----------|"
                        for i = 1,#work_items do
                                local w = work_items[i]
                                if w.rank > pl.cutline and cutline_shown == false then
                                        tmp[#tmp+1] = "     ----- CUTLINE -----------"
                                        cutline_shown = true
                                end
                                tmp[#tmp+1] = string.format("     %-5s|%-40s|%-10s|%s",
                                        "#" .. w.rank,
                                        w.name:truncate(40, {["ellipsis"] = true}),
                                        w:merged_triage(),
                                        Writer.tags_to_string(w.estimates, ", "))
                        end
                        tmp[#tmp+1] = "     ---------------------------------"
                end
                tmp[#tmp+1] = string.format("     Required people: %s", demand_str)
                tmp[#tmp+1] = ""
	end

	-- Print overall demand total
        tmp[#tmp+1] = string.format("%-30s %s", "TOTAL Required:", Writer.tags_to_string(
                func.map_table(format_number, total_demand), ", "
        ))

	
        if with_net_supply then
                -- Print total supply
                local total_bandwidth = Person.sum_bandwidth(Cmd.staff, Cmd.plan.num_weeks)
                tmp[#tmp+1] = string.format("%-30s %s", "TOTAL Skill Supply:", Writer.tags_to_string(
                        func.map_table(format_number, Cmd.plan:to_num_people(total_bandwidth)), ", "
                ))

                -- Print net supply
                -- NOTE: This is a hack, but to_num_people has already converted
                -- total_bandwidth and total_demand to num people!
                local net_supply = Work.subtract_skill_demand(total_bandwidth, total_demand);
                tmp[#tmp+1] = string.format("%-30s %s", "TOTAL Net Supply:", 
                        Writer.tags_to_string(func.map_table(format_number, net_supply), ", "))
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
        for k, v in pairs(supply_totals[1]) do
                print(k, v)
        end

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

function Cmd.rde_formatter(demand_hash, triage_tags, options)
--function Cmd.rde_formatter(file, triage_tags, all_tracks, demand_hash)

        local tmp = {}
        options = options or {}
        local skills = options.skills or {"Apps", "Native", "Web"}

        -- Gather all tracks
        local all_tracks = {}
        for _, triage in pairs(triage_tags) do
                all_tracks = func.value_union(all_tracks,
                                func.get_table_keys(demand_hash[triage]))
        end
        all_tracks = func.get_table_keys(all_tracks)

        -- Format data
        for _, tri in ipairs(triage_tags) do
                -- Print track column headings
                local row = {}
                row[#row+1] = string.format("Triage: %s", tri)
                for _, track in ipairs(all_tracks) do
                        row[#row+1] = string.format("%s", track)
                end
                tmp[#tmp+1] = table.concat(row, "\t")

                for _, skill in ipairs(skills) do
                        local row = {}
                        row[#row+1] = string.format("%s", skill)
                        for _, track in ipairs(all_tracks) do
                                local val = 0
                                if demand_hash[tri][track] then
                                        val = demand_hash[tri][track][skill] or 0
                                end
                                
                                row[#row+1] = string.format("%.1f", val)
                        end
                        tmp[#tmp+1] = table.concat(row, "\t")
                end
		tmp[#tmp+1] = ""
        end

        return table.concat(tmp, "\n")
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
		Cmd.plan:to_num_people(total_bandwidth), ", "
	)))
end

function rss()
        local total_bandwidth = Person.sum_bandwidth(ppl, pl.num_weeks)
	print(string.format("TOTAL Skill Supply: %s", Writer.tags_to_string(
		Cmd.plan:to_num_people(total_bandwidth), ", "
	)))
end

-- TODO: Move this to shell
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
