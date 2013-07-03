package.path = package.path .. ";app/?.lua;modules/?.lua"

Cmd = require('app/cmdline')
Web = require('app/web')

function s(version)
        -- TODO: Make these local
        pl, ppl = load_data(version)

        Cmd.init(pl, ppl)
        Web.init(pl, ppl)
end

