-- NOTE: Everything here is global so we can access it from the shell
require('shell_functions')

-- TODO: Add some commandline options here

-- Load data (at some point, use a prefix to specify a version)
pl, ppl = load_data()

print("READY")
