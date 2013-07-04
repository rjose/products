RequestParser = require('request_parser')
RequestRouter = require('request_router')
func = require('modules/functional')
json = require('json')

local Web = {}

-- These are things that must be set via an init function
Web.plan = nil
Web.staff = nil

APP_INDEX = 2
DEVICE_INDEX = 3
RESOURCE_INDEX = 4

function Web.init(plan, staff)
        Web.plan = plan
        Web.staff = staff
end


-- TODO: Share this with rs()
function get_people_by_skill(people)
        local people_by_skill = {}
        local num_weeks = 13            -- TODO: Figure out how to pass this in

        for _, person in ipairs(people) do
                local skill_tag = Writer.tags_to_string(person.skills):split(":")[1]
                skill_tag = skill_tag or "_UNSPECIFIED"
                people_list = people_by_skill[skill_tag] or {}
                people_list[#people_list+1] = person
                people_by_skill[skill_tag] = people_list
        end

	local skill_tags = func.get_table_keys(people_by_skill)
	table.sort(skill_tags)

        local total_bandwidth = to_num_people(Person.sum_bandwidth(people, num_weeks), num_weeks)

        return people_by_skill, skill_tags, total_bandwidth
end

function handle_app_web_staff(req)
        local people_by_skill, skill_tags, bandwidth = get_people_by_skill(Web.staff)

        local result = {}
        result.skills = skill_tags
        result.people_by_skill = people_by_skill
        result.bandwidth = bandwidth

        return RequestRouter.construct_response(200, "application/json", json.encode(result))
end


function handle_app_web_work(req)
        local work = pl:get_work_items()
	local feasible_line, _, supply_totals = pl:find_feasible_line()

        local result = {}
        result.work = work
        result.feasible_line = feasible_line
        result.cutline = Web.plan.cutline

        -- Adjust net totals to be people
        result.net_totals = {}
        for i, t in ipairs(supply_totals) do
                result.net_totals[i] = to_num_people(supply_totals[i], Web.plan.num_weeks)
        end

        return RequestRouter.construct_response(200, "application/json", json.encode(result))
end

function handle_app_web_tracks(req)
	local work = pl:get_work_items()
        local track_hash, track_tags = func.group_items(work, get_track)
        local result = {}
        result.tracks = track_tags
        result.work_by_track = track_hash
        result.cutline = Web.plan.cutline

        return RequestRouter.construct_response(200, "application/json", json.encode(result))
end

-- TODO: Move this to its own set of files
function handle_app_web_request(req)
        if req.path_pieces[RESOURCE_INDEX] == 'staff' then
                return handle_app_web_staff(req)
        elseif req.path_pieces[RESOURCE_INDEX] == 'work' then
                return handle_app_web_work(req)
        elseif req.path_pieces[RESOURCE_INDEX] == 'tracks' then
                return handle_app_web_tracks(req)
        end

        return RequestRouter.construct_response(400, "application/json", "")
end


function app_router(req)
        -- Need something like "/app/web/rbt"
        if #req.path_pieces < 4 or req.path_pieces[APP_INDEX] ~= "app" then
                return nil
        end

        if req.path_pieces[DEVICE_INDEX] == "web" then
                return handle_app_web_request(req)
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
