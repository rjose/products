-- NOTE: Everything here is global so we can access it from the shell
Person = require('person')
Plan = require('plan')
Work = require('work')
Reader = require('reader')
Writer = require('writer')

-- Make copies of files
data_dir = "./data/"
data_files = {'people.txt', 'plan.txt', 'work.txt'}
for _, file in pairs(data_files) do
	os.execute(string.format("cp %s%s %s%s.bak",
		data_dir, file,
		data_dir, file
	))
end

-- Load data
ppl = Reader.read_people(data_dir .. "people.txt")
pl = Reader.read_plans(data_dir .. "plan.txt")[1]
work_array = Reader.read_work(data_dir .. "work.txt")
num_work_items = #work_array
local work_table = {}
for i = 1,#work_array do
	work_table[work_array[i].id] = work_array[i]
end
-- TODO: Find a better way to hook this up
pl.work_table = work_table

-- Compute default skill supply
pl.default_supply = Person.sum_bandwidth(ppl, 13)



-- TODO: Move shell functions to a shell_funcs.lua file
p = print

-- Print tags
function pt(tags)
	print(Writer.tags_to_string(tags))
end

-- Get work by ranking in plan
function r(rank)
	return pl:get_work(rank)
end


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

-- Triage work
function tw(rank, level)
	triage_work(rank, level, 'Triage')
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

-- Add estimates
SA = "Apps"
SN = "Native"
SW = "Web"
SS = "SET"
SU = "UX"
SB = "BB"

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

-- Selection

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

-- Returns all work items whose ProdTriage value is 1
function w1()
	return pl:get_work_items{["filter"] = is_triage1}
end

-- Returns all work items whose ProdTriage value is 1
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


function get_ids(work_items)
	local result = {}
	for i = 1,#work_items do
		result[#result+1] = work_items[i].id
	end
	return result
end

-- This just pulls all of the items Triaged to 1 to the top of the list
function tsort()
	-- Get IDs of all 1s
	local ids = get_ids(w1())
	pl:rank(ids)
end

-- Work above cutline
function wac()
	return pl:get_work_items{["ABOVE_CUT"] = 1}
end

-- Printing
function pw(work_items)
	for i = 1,#work_items do
		local w = work_items[i]
		print(string.format("ID:%3s %20s %s", w.id, w.name,
			Writer.tags_to_string(w.tags)))
	end
end

print("READY")
