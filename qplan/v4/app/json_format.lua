local json = require('json')

local JsonFormat = {}

function JsonFormat.format_work_by_group(work_hash, keys, plan, staff, options)
        local object = {}
        object.groups = keys
        object.work_hash = work_hash
        object.cutline = plan.cutline

        return json.encode(object)
end

return JsonFormat
