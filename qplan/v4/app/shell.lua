-- Usage: lua -i shell.lua [version]
-- The "version" refers to the save version

package.path = package.path .. ";app/?.lua;modules/?.lua"

Cmd = require('app/cmdline')
Data = require('app/data')
func = require('app/functional')

-- NOTE: Everything here is global so we can access it from the shell
-- require('shell_functions')

version = arg[1]

if version then
        print("Loading version: " .. version)
end


-- TODO: Make these local
-- Load data (at some point, use a prefix to specify a version)
pl, ppl = Data.load_data(version)

Cmd.init(pl, ppl)

pw = Cmd.print_work_items


-- CANNED REPORTS -------------------------------------------------------------
--
function w()
        -- Select work items
        local work_items = Select.all_work(Cmd.plan)

        -- Format work items
        local result_string = Cmd.default_work_formatter(work_items)

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
        local result_string = Cmd.default_work_formatter(work_items)

        -- Print result
        print(result_string)
end

function rrt()
        -- Select work items
        local work_items = Select.all_work(Cmd.plan)

        -- Format work items
        local result_string = Cmd.rrt_formatter(work_items)

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
        local result_string = Cmd.default_work_hash_formatter(work_hash, tracks)
        
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

-- "triage sort". This just pulls all of the items Triaged to 1 to the top of the list
-- This ranks items stably.
function tsort()
        -- TODO: Fix this
	-- Get IDs of all 1s and 1.5s
	local ids = get_ids(w1())
	Cmd.plan:rank(ids)
end

function sc(cutline)
        Cmd.plan.cutline = cutline
end

print("READY")
