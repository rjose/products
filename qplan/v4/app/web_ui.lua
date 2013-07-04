local Writer = require('writer')
local Person = require('person')
local RequestParser = require('request_parser')
local RequestRouter = require('request_router')
local Select = require('select')
local func = require('functional')
local JsonFormat = require('json_format')

-- TODO get rid of this
local json = require('json')

local WebUI = {}

-- STARTUP --------------------------------------------------------------------
--
local plan = nil
local staff = nil

APP_INDEX = 2
DEVICE_INDEX = 3
RESOURCE_INDEX = 4

function WebUI.init(a_plan, a_staff)
        plan = a_plan
        staff = a_staff
end


-- REQUEST HANDLING -----------------------------------------------------------
--

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

        local total_bandwidth =
          plan:to_num_people(Person.sum_bandwidth(people, num_weeks), num_weeks)

        return people_by_skill, skill_tags, total_bandwidth
end

function handle_app_web_staff(req)
        local people_by_skill, skill_tags, bandwidth = get_people_by_skill(staff)

        local result = {}
        result.skills = skill_tags
        result.people_by_skill = people_by_skill
        result.bandwidth = bandwidth

        return RequestRouter.construct_response(200, "application/json", json.encode(result))
end


function handle_app_web_work(req)
        -- Select work items
        local work = plan:get_work_items()
        

        -- Format results
        local result_str = JsonFormat.format_rrt(work, plan, staff)
        return RequestRouter.construct_response(
                                        200, "application/json", result_str)
end

function handle_app_web_tracks(req)
        -- Select work items
	local work = plan:get_work_items()

        -- Group items
        local track_hash, track_tags = Select.group_by_track(work)

        -- Format results
        local result_str =
            JsonFormat.format_work_by_group(track_hash, track_tags, plan, staff)

        return RequestRouter.construct_response(
                                            200, "application/json", result_str)
end

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



-- REQUEST ROUTING ------------------------------------------------------------
--
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

-- Set routers
RequestRouter.routers = {app_router, RequestRouter.static_file_router}

function WebUI.handle_request(req_string)
        local req = RequestParser.parse_request(req_string)
        return RequestRouter.route_request(req)
end

return WebUI
