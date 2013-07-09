local Writer = require('writer')
local Person = require('person')
local RequestParser = require('request_parser')
local RequestRouter = require('request_router')
local Select = require('select')
local func = require('functional')
local JsonFormat = require('json_format')
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
function handle_app_web_staff(req)
        -- "select" staff
        local staff = staff

        -- Group by skill
        local people_by_skill, skill_tags = Select.group_people_by_skill(staff)

        -- Format results
        local result_str = JsonFormat.format_people_hash(
                                       people_by_skill, skill_tags, plan, staff)

        -- Return response
        return RequestRouter.construct_response(200, "application/json", result_str)
end


function handle_app_web_work(req)
        local track = 'All'
        if req.qparams['track'] then
                track = req.qparams['track'][1]
        end

        local triage = 1.5
        if req.qparams['triage'] then
                triage = req.qparams['triage'][1] + 0
        end
        print(triage)

        -- Select work items
        local work_items = Select.all_work(plan)        

        -- Filter out unneeded tracks
        if track ~= 'All' then
                local filters = {Select.make_track_filter(track)}
                work_items = Select.apply_filters(work_items, filters)
        end

        -- Create list of work items above or equal to "triage"
        local triage_filter = Select.make_downto_triage_filter(triage)
        local triage_work_items = Select.apply_filters(work_items,
                                                           {triage_filter})
        local demand = plan:to_num_people(Work.sum_demand(triage_work_items))
        local skills = func.get_table_keys(demand)

        local result = {}

        -- TODO: These should come in a different call
        result.tracks = {"Contacts", "Austin"}

        -- TODO: Come up with number of people assigned
        local available = {}
        local net_left = {}
        for _, skill in ipairs(skills) do
                local avail = available[skill] or 0
                net_left[skill] = avail - demand[skill]
        end

        -- TODO: Come up with feasible line
        feasible_line = 10

        result.staffing_stats = {
                ["skills"]= skills,
                ["required"]= func.map_table(format_number, demand),
                ["available"]= func.map_table(format_number, available),
                ["net_left"]= func.map_table(format_number, net_left),
                ["feasible_line"]= feasible_line
        }

        -- TODO: Move to formatting function
        result.work_items = {}
        for _, w in ipairs(work_items) do
                local new_item = {}
                new_item.rank = w.rank
                new_item.triage = w:merged_triage()
                new_item.name = w.name
                new_item.track = w.tags.track
                new_item.estimate = Writer.tags_to_string(w.estimates, ", ")
                result.work_items[#result.work_items+1] = new_item
        end

        -- Return response
        return RequestRouter.construct_response(
                                        200, "application/json", json.encode(result))
end

function handle_app_web_tracks(req)
        -- Select work items
	local work = plan:get_work_items()

        -- Group items
        local track_hash, track_tags = Select.group_by_track(work)

        -- Format results
        local result_str =
            JsonFormat.format_work_by_group(track_hash, track_tags, plan, staff)

        -- Return response
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
