RequestParser = require('request_parser')
RequestRouter = require('request_router')

local Web = {}

-- TODO: Set up the routers here
-- TODO: Define the app router

function Web.handle_request(req_string)
        local req = RequestParser.parse_request(req_string)
        return RequestRouter.route_request(req)
end

return Web
