-- Usage: lua -i shell.lua [version]
-- The "version" refers to the save version

package.path = package.path .. ";app/?.lua;modules/?.lua"

Cmd = require('app/cmdline')
Data = require('app/data')

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
        local work_items = Select.all_work(Cmd.plan)
        Cmd.print_work_items(work_items)
end

function wac()
        local work_items = Select.all_work(Cmd.plan)

        local above_cutline_filter = Select.make_above_cutline_filter(Cmd.plan)
        work_items = Select.apply_filters(work_items, {above_cutline_filter})

        Cmd.print_work_items(work_items)
end

function rrt()
        -- Get work items
        local work_items = Select.all_work(Cmd.plan)

        -- Format and print work items
        Cmd.print_work_items(work_items, Cmd.rrt_formatter)
end

function rbt(t, triage)
        -- Get work items
        local work_items = Select.all_work(Cmd.plan)

        -- Filter items
        local filters = Select.get_track_and_triage_filters(t, triage)
        work_items = Select.apply_filters(work_items, filters)

        -- Group items
        local work_hash, tracks = Select.group_by_track(work_items)

        -- Format and print items using default formatter
        Cmd.print_work_hash(work_hash, tracks)
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
