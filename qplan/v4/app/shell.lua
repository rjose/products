-- Usage: lua -i shell.lua [version]
-- The "version" refers to the save version

package.path = package.path .. ";app/?.lua;modules/?.lua"

Cmd = require('app/cmdline_format')
Data = require('app/data')
func = require('app/functional')

-- STARTUP --------------------------------------------------------------------
--
version = arg[1]

if version then
        print("Loading version: " .. version)
end

local pl, ppl = Data.load_data(version)
Cmd.init(pl, ppl)


-- ALIASES --------------------------------------------------------------------
--
p = print
pw = Cmd.print_work_items
export = Data.export
wrd = Data.wrd


-- CANNED REPORTS -------------------------------------------------------------
--
function w()
        -- Select work items
        local work_items = Select.all_work(Cmd.plan)

        -- Format work items
        local result_string = Cmd.default_format_work(work_items)

        -- Print result
        print(result_string)
end

function wac()
        -- Select work items
        local work_items = Select.all_work(Cmd.plan)

        -- Filter work items
        local above_cutline_filter = Select.make_above_cutline_filter(Cmd.plan)
        work_items = Select.apply_filters(work_items, {above_cutline_filter})

        -- Format work items
        local result_string = Cmd.default_format_work(work_items)

        -- Print result
        print(result_string)
end

function rrt()
        -- Select work items
        local work_items = Select.all_work(Cmd.plan)

        -- Format work items
        local result_string = Cmd.format_rrt(work_items)

        -- Print result
        print(result_string)
end

function rbt(t, triage)
        -- Select work items
        local work_items = Select.all_work(Cmd.plan)

        -- Filter items
        local filters = Select.get_track_and_triage_filters(t, triage)
        work_items = Select.apply_filters(work_items, filters)

        -- Group items
        local work_hash, tracks = Select.group_by_track(work_items)

        -- Format result items
        local result_string = Cmd.default_format_work_hash(work_hash, tracks)
        
        -- Print result
        print(result_string)
end



function rde()
        -- Get work items
	local work_items = pl:get_work_items()

        -- Group work items by triage then track
        local triage_hash, triage_tags = Select.group_by_triage(work_items)
        for _, triage in ipairs(triage_tags) do
                triage_hash[triage] = table.pack(Select.group_by_track(triage_hash[triage]))
        end

        -- Apply map over work items by triage then track to sum required skills
        local demand_hash = {}
        for _, triage in ipairs(triage_tags) do
                demand_hash[triage] = demand_hash[triage] or {}
                local track_hash, track_tags = unpack(triage_hash[triage])
                for _, track in pairs(track_tags) do
                        demand_hash[triage][track] =
                      Cmd.plan:to_num_people(Work.sum_demand(track_hash[track]))
                      print(triage, track, #track_hash[track])
                end
        end

        -- Format required demand by triage then track
        local result_string = Cmd.rde_formatter(demand_hash, triage_tags)
        print(result_string)
end

-- TODO: Convert these into formatters
-- Prints available people by skill
function rs()
        local people_by_skill = {}

        for _, person in ipairs(ppl) do
                local skill_tag =
                        Writer.tags_to_string(person.skills):split(":")[1]
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
                        print(string.format("     %3d. %-30s %.1f",
                                             j, people_list[j].name,
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

-- UTILITY FUNCTIONS ----------------------------------------------------------
--

-- Rank can be a single number or an array of numbers
function r(rank)
        return Select.work_with_rank(Cmd.plan, rank)
end

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
	Cmd.plan:rank(work_items, {["at"] = position})
end


function sc(cutline)
        Cmd.plan.cutline = cutline
end

-- HELP -----------------------------------------------------------------------
--

function help()
	print(
[[
-- Reading/Writing
wrd(n):		Writes data to file with suffix "n"
export():	Writes data to "data/output.txt" in a form for Google Docs

-- Printing
p():		Alias for print

-- Select work
r(rank):	Selects work item at rank 'rank'. May also take an array of ranks.
wall():		Prints all work in plan
wac():		Prints work above cutline

-- Updating plan
sc(num):	Sets cutline

-- Reports
rrt():		Report running totals
rbt(tra, tri):	Report by track. Takes optional track(s) "t" to filter on and triage.
                Using a triage of 1 selects all 1s. Using 1.5 selects 1s and 1.5s.
rde():		Report data export (demand by triage and track)
rs():		Report available supply
]]
	)
end

print("READY")
