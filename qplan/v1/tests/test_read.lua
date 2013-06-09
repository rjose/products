local Work = require('work')
local Plan = require('plan')

local Reader = require('reader')


TestRead = {}

function TestRead:test_parseTags()
	local tag_string = "Apps:1"
	local tag_table = Reader.parse_tags(tag_string)
	assertEquals(tag_table["Apps"], 1)
end

function TestRead:test_parseTags2()
	local tag_string = "Apps:1,Server:0"
	local tag_table = Reader.parse_tags(tag_string)
	assertEquals(tag_table["Apps"], 1)
	assertEquals(tag_table["Server"], 0)
end
