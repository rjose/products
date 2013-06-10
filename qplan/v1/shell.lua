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
		io.stderr:write(string.format("Couldn't find work for rank: %d\n", rank))
		return
	end

	work.tags[tag_key] = level
end

-- Triage work for Product
function twp(rank, level)
	triage_work(rank, level, 'ProductTriage')
end

-- Triage work for Engineering
function twe(rank, level)
	triage_work(rank, level, 'EngTriage')
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

print("READY")
