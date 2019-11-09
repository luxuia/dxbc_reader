
local parser = require 'dxbc_parse'

local DataDump = require 'table_dumper'

--local file_name = 'fragment.dxbc'
local file_name = 'vertex.dxbc'

local file = io.open(file_name, 'r')
local str = file:read('*a')

local parse_data = parser(str)

print(DataDump(parse_data))

local res_data = parse_data[1]

local var_mask =  {'x', 'y', 'z', 'w'}
local var_mask_map = {x=0, y=4,z=8,w=12}

local cbuff_map = {}
for _, cbuffer in pairs(res_data.cbuff_data) do
    cbuff_map[cbuffer.cbuffer_name] = cbuffer.vars
    for _, var in pairs(cbuffer.vars) do
        var.idx = var.offset//16
        var.mask_start = var_mask[(var.offset - var.idx*16)//4 + 1]
    end
end

--print(DataDump(cbuff_map))

local bind_map = {}

for _, bind in pairs(res_data.binding_data) do
    bind_map[bind.bind] = {name = bind.name, desc = cbuff_map[bind.name]}
end

for _, bind in pairs(res_data.input_data) do
    local name = bind.name
    if name == 'TEXCOORD' then
        name = name .. bind.register
    end
    bind_map[bind.bind] = {name = 'in.' .. name, desc = bind}
end

for _, bind in pairs(res_data.output_data) do
    local name = bind.name
    if name == 'TEXCOORD' then
        name = name .. bind.register
    end
    bind_map[bind.bind] = {name = 'out.' .. name, desc = bind}
end

print(DataDump(bind_map))

local function cal_offset(register)
    local name = register.name
    local bind_data = bind_map[name]
    local suffix = register.suffix
    if bind_data and register.idx then
        return register.idx*16 + var_mask_map[string.sub(register.suffix, 1, 1)]
    end
    return 0
end

local function get_var_name(register)
    local name = register.name
    local bind_data = bind_map[name]
    local suffix = register.suffix
    if bind_data then
        name = bind_data.name
        local desc = bind_data.desc
        suffix = nil
        if register.idx then
            local target_offset = cal_offset(register)
            local target_idx
            for i=#desc, 1, -1 do
                if desc[i].offset <= target_offset then
                    target_idx = i
                    break
                end
            end
            assert(target_idx, 'cant find var offset' .. name)
            suffix = desc[target_idx].name
            if desc[target_idx].size > 16 then
                suffix = string.format('%s[%s]', suffix, (target_offset-desc[target_idx].offset)//16)
            end
        end
        if register.suffix then
            if suffix then
                suffix = suffix .. '.' .. register.suffix
            else
                suffix = register.suffix
            end
        end
    end

    local ret
    if register.vals then
        local val_count = #register.vals
        if val_count == 1 then
            ret = register.vals[1]
        else
            ret = string.format('float%s(%s)', val_count, table.concat(register.vals, ','))
        end
    else
        ret = string.format('%s.%s', name, suffix)
    end
    if register.neg then
        ret = '-' .. ret
    end
    return ret
end

local shader_def = {
    dp4 = function(a, b, c)
        local op = 'dot'
        local namea = get_var_name(a)
        local nameb = get_var_name(b)
        local namec = get_var_name(c)
        return string.format('%s = %s(%s, %s)', namea, op, nameb, namec)
    end,
    dp3 = function(a, b, c)
        local op = 'dot'
        local namea = get_var_name(a)
        local nameb = get_var_name(b)
        local namec = get_var_name(c)
        return string.format('%s = %s(%s, %s)', namea, op, nameb, namec)
    end,
    mov = function(a, b)
        return string.format('%s = %s', get_var_name(a), get_var_name(b))
    end,
    add = function(a, b, c)
        local namea = get_var_name(a)
        local nameb = get_var_name(b)
        local namec = get_var_name(c)
        return string.format('%s = %s+%s', namea, nameb, namec)
    end,
    mul = function(a, b, c)
        local namea = get_var_name(a)
        local nameb = get_var_name(b)
        local namec = get_var_name(c)
        return string.format('%s = %s*%s', namea, nameb, namec)
    end,
    min = function(a, b, c)
        local namea = get_var_name(a)
        local nameb = get_var_name(b)
        local namec = get_var_name(c)
        return string.format('%s = min(%s,%s)', namea, nameb, namec)
    end,
    ret = function()
        return 'return out'
    end
}

local translate = {}
local idx = 2
while idx <= #parse_data do
    local command = parse_data[idx]
    local op_func = shader_def[command.op]
    if op_func then
        translate[#translate+1] = op_func(table.unpack(command.args))
    end
    idx = idx+1
end

local ret = table.concat(translate, '\n')
print(ret)