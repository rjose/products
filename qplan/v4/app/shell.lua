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

function w()
        local work_items = Select.all_work(Cmd.plan)
        Cmd.print_work_items(work_items)
end


print("READY")
