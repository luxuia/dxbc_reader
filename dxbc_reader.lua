
local DEBUG=true

local parser = require 'dxbc_parse'
local DataDump = require 'table_dumper'

--local file_name = 'fragment.dxbc'
local file_name = 'fragment2.txt'

local _format = string.format

local file = io.open(file_name, 'r')
local str = file:read('*a')

local parse_data = parser(str)

--print(DataDump(parse_data))

local res_data = parse_data[1]

local var_mask =  {'x', 'y', 'z', 'w'}
local var_mask_idx = {x=1, y=2, z=3, w=4}
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

--print(DataDump(bind_map))

local function cal_offset(register)
    local name = register.name
    local bind_data = bind_map[name]
    local suffix = register.suffix
    if bind_data and register.idx then
        return register.idx*16 + var_mask_map[string.sub(register.suffix, 1, 1)]
    end
    return 0
end

local function get_var_mask(register, mask_register)
    local mask = mask_register.suffix
    local mask_idx = {}
    for i=1, #mask do
        mask_idx[i] = var_mask_idx[mask:sub(i, i)]
    end
    local suffix = {}

    local reg_suffix = register.suffix
    local last_com = reg_suffix:sub(#reg_suffix, #reg_suffix)
    for i=1, #mask_idx do
        local idx = mask_idx[i]
        if idx > #reg_suffix then
            suffix[i] = last_com
        else
            suffix[i] = reg_suffix:sub(idx, idx)
        end
    end
    return table.concat(suffix)
end

local function get_var_name(register, swizzle, sep_suffix)
    local name = register.name
    local bind_data = bind_map[name]
    local reg_com = register.suffix
    if swizzle and reg_com then
        reg_com = get_var_mask(register, swizzle)
    end
    local suffix
    if bind_data then
        name = bind_data.name
        local desc = bind_data.desc
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
                suffix = _format('%s[%s]', suffix, (target_offset-desc[target_idx].offset)//16)
            end
        end
    end
    suffix = suffix and suffix .. '.' .. reg_com or reg_com

    if register.vals then
        local val_count = #register.vals
        if val_count == 1 then
            name = tostring(register.vals[1])
        else
            name = _format('float%s(%s)', val_count, table.concat(register.vals, ','))
        end
    end

    if sep_suffix then
        return name, suffix
    end

    local ret
    if suffix then
        ret = _format('%s.%s', name, suffix)
    else
        ret = name
    end

    if register.abs then
        ret = _format('abs(%s)', ret)
    end
    if register.neg then
        ret = '-' .. ret
    end

    return ret
end

local shader_def = {
    ['dp%d(.*)'] = function(op_args, a, b, c)
        local namea = get_var_name(a)
        local nameb = get_var_name(b, a)
        local namec = get_var_name(c, a)
        if op_args._sat then
            return _format('%s = saturate(dot(%s, %s))', namea, nameb, namec)
        else
            return _format('%s = dot(%s, %s)', namea, nameb, namec)
        end
    end,
    mov = function(op_args, a, b)
        return _format('%s = %s', get_var_name(a), get_var_name(b, a))
    end,
    movc = function(op_args, dest, cond, a, b)
        local n_dest= get_var_name(dest)
        local n_cond = get_var_name(cond, dest)
        local n_a = get_var_name(a, dest)
        local n_b = get_var_name(b, dest)
        return _format('%s=%s?%s:%s', n_dest, n_cond, n_a, n_b)
    end,
    add = function(op_args, a, b, c)
        local namea = get_var_name(a)
        local nameb = get_var_name(b, a)
        local namec = get_var_name(c, a)
        if namec:sub(1,1) == '-' then
            return _format('%s = %s%s', namea, nameb, namec)
        else
            return _format('%s = %s+%s', namea, nameb, namec)
        end
    end,
    ['mul(.*)'] = function(op_args, a, b, c)
        local namea = get_var_name(a)
        local nameb = get_var_name(b, a)
        local namec = get_var_name(c, a)
        if op_args._sat then
            return _format('%s = saturate(%s*%s)', namea, nameb, namec)
        else
            return _format('%s = %s*%s', namea, nameb, namec)
        end
    end,
    min = function(op_args, a, b, c)
        local namea = get_var_name(a)
        local nameb = get_var_name(b)
        local namec = get_var_name(c)
        return _format('%s = min(%s, %s)', namea, nameb, namec)
    end,
    max = function(op_args, a, b, c)
        local namea = get_var_name(a)
        local nameb = get_var_name(b)
        local namec = get_var_name(c)
        return _format('%s = max(%s, %s)', namea, nameb, namec)
    end,
    ['sample.*'] = function(op_args, dest, addr, texture, sampler)
        local n_dest = get_var_name(dest)
        local n_addr, com_addr = get_var_name(addr, nil, true)
        local n_texture, com_texture = get_var_name(texture, dest, true)
        local n_sampler = get_var_name(sampler)
        return _format('%s = tex2D(%s, %s.%s).%s //sample_state %s',
                    n_dest, n_texture, n_addr, com_addr:sub(1, 2), com_texture, n_sampler)
    end,
    mad = function(op_args, a, b, c, d)
        local namea = get_var_name(a)
        local nameb = get_var_name(b, a)
        local namec = get_var_name(c, a)
        local named = get_var_name(d, a)
        if named:sub(1,1) == '-' then
            return _format('%s = %s*%s%s', namea, nameb, namec, named)
        else
            return _format('%s = %s*%s+%s', namea, nameb, namec, named)
        end
    end,
    div = function(op_args, a, b, c)
        local namea = get_var_name(a)
        local nameb = get_var_name(b, a)
        local namec = get_var_name(c, a)
        return _format('%s = %s/%s', namea, nameb, namec)
    end,
    ['deriv_rt(.)(.*)'] = function(op_args, a, b)
        local namea = get_var_name(a)
        local nameb = get_var_name(b, a)
        local axis = op_args[1]
        local suffix=''
        if op_args._coarse then
            suffix = '_coarse'
        end
        return _format('%s=dd%s%s(%s)', namea, axis, suffix, nameb)
    end,
    lt = function(op_args, a, b, c)
        local namea = get_var_name(a)
        local nameb = get_var_name(b)
        local namec = get_var_name(c)
        return _format('%s = %s < %s', namea, nameb, namec)
    end,
    ge = function(op_args, a, b, c)
        local namea = get_var_name(a)
        local nameb = get_var_name(b)
        local namec = get_var_name(c)
        return _format('%s = %s >= %s', namea, nameb, namec)
    end,
    ['discard(.*)'] = function(op_args, a)
        local namea = get_var_name(a)
        if op_args._z == '_z' then
            return string.format([[
if (%s == 0) then
    discard;
end]], namea)
        elseif op_args._nz then
            return string.format([[
if (%s != 0) then
    discard;
end]], namea)
        else
            return 'discard'
        end
    end,
    rsq = function(op_args, a, b)
        local namea = get_var_name(a)
        local nameb = get_var_name(b, a)
        return _format('%s = rsqrt(%s)', namea, nameb)
    end,
    sqrt = function(op_args, a, b)
        local namea = get_var_name(a)
        local nameb = get_var_name(b, a)
        return _format('%s = sqrt(%s)', namea, nameb)
    end,
    frc = function(op_args, a, b)
        local namea = get_var_name(a)
        local nameb = get_var_name(b, a)
        return _format('%s = frac(%s)', namea, nameb)
    end,
    exp = function(op_args, a, b)
        local namea = get_var_name(a)
        local nameb = get_var_name(b)
        return _format('%s = exp2(%s)', namea, nameb)
    end,
    ['and'] = function(op_args, a, b, c)
        local namea = get_var_name(a)
        local nameb = get_var_name(b)
        local namec = get_var_name(c)
        return _format('%s = %s&%s', namea, nameb, namec)
    end,
    ret = function()
        return 'return out'
    end,
    ['vs_%d_%d'] = false,
    ['ps_%d_%d'] = false,
    ['dcl_.*'] = false,
}

local modifier_def = {
    sat = function(a)
        return _format('saturate(%s)', a)
    end,
    neg = function(a)
        return _format('-%s', a)
    end,
    abs = function(a)
        return _format('abs(%s)', a)
    end,
}

local function get_op(op)
    if not op then return end

    local capture
    local target_op
    for op_def in  pairs(shader_def) do
        if op:gsub('^' .. op_def .. '$', function(...) capture = {...} end) and capture then
            target_op = op_def
            break
        end
    end
    return target_op, capture
end

local function arr2dic(list)
    local dic = {}
    for idx, v in pairs(list) do
        dic[v] = true
        dic[idx] = v
    end
    return dic
end

local translate = {}
local idx = 2
local line_id = 1
while idx <= #parse_data do
    local command = parse_data[idx]
    if command.op then
        local op_name, op_param = get_op(command.op)
            print(DataDump(command))
        if op_name then
            local op_func = shader_def[op_name]
            if op_func then
                op_param = op_param and arr2dic( op_param) or {}
                local op_str = op_func(op_param, table.unpack(   command.args))
                translate[#translate+1] = string.format('%s\t%s', line_id, op_str)
                print(op_str)
                if DEBUG then
                    translate[#translate+1] = command.src
                end
                line_id = line_id+1
            end
        else
            assert(false, 'not implement op ' .. command.op)
        end
    end
    idx = idx+1
end

local ret = table.concat(translate, '\n')
print(ret)

--[[
local str = 'sample_indexable(float)(float,float)'
string.gsub(str, 'sample(.*)', print)
--]]


io.open(file_name .. '.out', 'w'):write(ret)