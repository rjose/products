package.path = package.path .. ";app/?.lua;modules/?.lua"

Cmd = require('app/text_format')
Web = require('app/web')
Data = require('app/data')


-- TODO: Rename and call from qplan.c
function s(version)
        -- TODO: Make these local
        pl, ppl = Data.load_data(version)

        Cmd.init(pl, ppl)
        Web.init(pl, ppl)
end
