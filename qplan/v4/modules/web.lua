RequestParser = require('request_parser')

local Web = {}

function Web.handle_request(req_string)
        print(req_string)
        print(foo[1])
        local req = RequestParser.parse_request(req_string)
        print("Request target", req.request_target)
        print("User agent", req.headers['user-agent'])
end

return Web
