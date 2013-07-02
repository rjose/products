RequestParser = require('request_parser')
RequestRouter = require('request_router')

local Web = {}


-- TODO: Move this to its own set of files
function handle_web_app_request(req)
        local content = string.format([[{
                "track_names": ["T1", "T2", "T3"],
                "cutline": %d
        }
        ]], pl.cutline)

        result = RequestRouter.construct_response(200, "application/json", content)
        return result
end

function app_router(req)
        -- Need something like "/app/web/rbt"
        if #req.path_pieces < 4 or req.path_pieces[2] ~= "app" then
                return nil
        end

        if req.path_pieces[3] == "web" then
                return handle_web_app_request(req)
        end

        return nil
end

-- Set up routers
RequestRouter.routers = {app_router, RequestRouter.static_file_router}

function Web.handle_request(req_string)
        local req = RequestParser.parse_request(req_string)
        return RequestRouter.route_request(req)
end

return Web
