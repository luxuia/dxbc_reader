local tinsert   = table.insert
local tconcat   = table.concat
local tsort     = table.sort
local sformat   = string.format
local srep      = string.rep
local tostring  = tostring
local type      = type
local pairs     = pairs

local INDENT_STR = "    "

local _table2str

local abnormal_key = {}

local function _value2str(v, indent, result_table, n)
    local tpv = type(v)
    if tpv == "table" then
        n=n+1; result_table[n] = "{\n"

        -- recursive
        n = _table2str(v, indent+1, result_table, n)

        for i=1,indent do
            n=n+1; result_table[n] = INDENT_STR
        end
        n=n+1; result_table[n] = "},\n"
    else
        n=n+1; result_table[n] = (tpv == "string" and sformat("%q", v) or tostring(v))
        n=n+1; result_table[n] = ",\n"
    end

    return n
end

_table2str = function(lua_table, indent, result_table, n)
    indent = indent or 0

    local keys = {}
    local x = 0
    local is_array = true
    local max_index = 0
    local expect_index = 1
    for k, _ in pairs(lua_table) do
        x=x+1; keys[x] = k
        if is_array then
            if math.type(k) ~= 'integer' or k <= 0 then
                is_array = false
            else
                if k > max_index then
                    max_index = k
                end
                if k == expect_index then
                    expect_index = k + 1
                end
            end
        end
    end
    if is_array then
        for i = expect_index, max_index do
            if lua_table[i] == nil then
                is_array = false
                break
            end
        end
    end

    -- 纯数组
    if is_array then
        for i = 1, max_index do
            for i=1,indent do
                n=n+1; result_table[n] = INDENT_STR
            end
            n = _value2str(lua_table[i], indent, result_table, n)
        end
        return n
    end

    -- 非纯数组

    tsort(keys, function(a,b)
        if type(a) == type(b) then
            return a < b
        end
        if type(a) == "string" then
            return false
        elseif type(b) == "string" then
            return true
        else
            return a < b
        end
    end)
    for _,key in ipairs(keys) do
        if type(key) == 'number' and key >= 2^32 then
            table.insert(abnormal_key, key)
        end
    end

    for i = 1, x do
        local k = keys[i]
        local v = lua_table[k]

        -- indent
        for i=1,indent do
            n=n+1; result_table[n] = INDENT_STR
        end

        -- key
        n=n+1; result_table[n] = "["
        n=n+1; result_table[n] = (type(k) == "string" and sformat("%q", k) or tostring(k))
        n=n+1; result_table[n] = "] = "

        -- value
        n = _value2str(v, indent, result_table, n)
    end

    return n
end

local function serialize(lua_table)
    local _seri_table = {}
    local n = 0  -- length of _seri_table
    n=n+1; _seri_table[n] = '{\n'
    n = _table2str(lua_table, 1, _seri_table, n)
    n=n+1; _seri_table[n] = '}'

    return tconcat(_seri_table, ''), abnormal_key
end

return serialize

