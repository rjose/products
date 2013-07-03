-- Usage: lua -i shell.lua [version]
-- The "version" refers to the save version

package.path = package.path .. ";app/?.lua;modules/?.lua"

-- NOTE: Everything here is global so we can access it from the shell
require('shell_functions')

version = arg[1]

if version then
        print("Loading version: " .. version)
end


-- TODO: Make these local
-- Load data (at some point, use a prefix to specify a version)
pl, ppl = load_data(version)



print("READY")
