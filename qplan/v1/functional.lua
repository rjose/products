-- TODO: Document this
local func = {}

-- Returns an array of keys being the union of t1 and t2
function func.key_union(t1, t2)
        local result = {}
        local keymap = {}
        for _, t in pairs({t1, t2}) do
                for k, _ in pairs(t) do
                        keymap[k] = true
                end
        end

        for k, _ in pairs(keymap) do
                result[#result+1] = k
        end

        return result
end

-- This applies a function of 2 variables key-wise to two tables. The function f
-- should handle nil values in a way that makes sense.
function func.apply_keywise_2(f, t1, t2)
        local keys = func.key_union(t1, t2)

	local result = {}
        for _, key in pairs(keys) do
                result[key] = f(t1[key], t2[key])
        end

        return result
end

function func.add(w1, w2)
        w1 = w1 or 0
        w2 = w2 or 0
	return w1 + w2
end

function func.subtract(w1, w2)
        w1 = w1 or 0
        w2 = w2 or 0
	return w1 - w2
end


return func
