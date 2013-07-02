RequestParser = require('request_parser')
RequestRouter = require('request_router')
json = require('json')

local Web = {}

APP_INDEX = 2
DEVICE_INDEX = 3
RESOURCE_INDEX = 4

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

        local total_bandwidth = Person.sum_bandwidth(people, num_weeks)

        return people_by_skill, skill_tags, total_bandwidth

--         -- This prints people by skill
-- 	for i = 1,#skill_tags do
--                 local skill = skill_tags[i]
--                 local people_list = people_by_skill[skill]
--                 print(string.format("%s ==", skill))
--                 for j = 1,#people_list do
--                         print(string.format("     %3d. %-30s %.1f", j, people_list[j].name,
--                                                              people_list[j].skills[skill]))
--                 end
--         end
-- 
--         -- This prints total bandwidth
-- 	print(string.format("TOTAL Skill Supply: %s", Writer.tags_to_string(
-- 		to_num_people(total_bandwidth, pl.num_weeks), ", "
-- 	)))
end

function handle_app_web_staff(req)
        local people_by_skill, skill_tags, bandwidth = get_people_by_skill(ppl)

        local result = {}
        result.skills = skill_tags
        result.people_by_skill = people_by_skill

        return RequestRouter.construct_response(200, "application/json", json.encode(result))
end

-- TODO: Move this to its own set of files
function handle_app_web_request(req)
        if req.path_pieces[RESOURCE_INDEX] == 'staff' then
                return handle_app_web_staff(req)
        end
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
