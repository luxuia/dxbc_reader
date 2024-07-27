local _format = string.format
local DataDump = require 'table_dumper'


local m = {}

local var_mask_idx = {x=1, y=2, z=3, w=4}
local var_mask_map = {x=0, y=4,z=8,w=12}

local bind_map

function m:init(parse_data)

    local res_data = parse_data[1]

    local var_mask =  {'x', 'y', 'z', 'w'}


    local cbuff_map = {}
    for _, cbuffer in pairs(res_data.cbuff_data) do
        cbuff_map[cbuffer.cbuffer_name] = cbuffer.vars
        for _, var in pairs(cbuffer.vars) do
            var.idx = var.offset//16
            var.mask_start = var_mask[(var.offset - var.idx*16)//4 + 1]
        end
    end

    --print(DataDump(cbuff_map))

    bind_map = {}

    for _, bind in pairs(res_data.binding_data) do
        bind_map[bind.bind] = {name = bind.name, desc = cbuff_map[bind.name]}
    end

    for _, bind in pairs(res_data.input_data) do
        local name = bind.name
        if name == 'TEXCOORD' then
            name = name .. bind.register
            bind.name = name
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
end

local function cal_offset(register)
    local name = register.name
    local bind_data = bind_map[name]
    if bind_data and register.idx then
        return register.idx*16 + var_mask_map[string.sub(register.suffix, 1, 1)]
    end
    return 0
end

local function get_var_mask(register, mask_register)
    if not mask_register.suffix then return register.suffix end

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

local function get_vec_mask(vals, mask_register)
    if not mask_register.suffix then return vals end

    local mask = mask_register.suffix
    local mask_idx = {}
    for i=1, #mask do
        mask_idx[i] = var_mask_idx[mask:sub(i, i)]
    end
    local suffix = {}

    local last_com = vals[#vals]
    for i=1, #mask_idx do
        local idx = mask_idx[i]
        if idx > #vals then
            suffix[i] = last_com
        else
            suffix[i] = vals[idx]
        end
    end
    return suffix
end

local function get_var_name(register, swizzle, sep_suffix)
    local name = register.name
    local bind_data = bind_map[name]
    local reg_com = register.suffix
    if swizzle and reg_com then
        reg_com = get_var_mask(register, swizzle)
    end
    local suffix
    local suffix_dot = '.'
    -- print('---------', DataDump(register), DataDump(bind_data))
    if bind_data then
        name = bind_data.name
        local desc = bind_data.desc
        if register.idx then
            if type(register.idx) == 'number' then
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
    elseif register.idx then
    -- CBUSE [param].x
        suffix = _format('[%s]', register.idx)
        suffix_dot = ''
    end

    if suffix and reg_com then
    -- CBUSE . param.x
        suffix = suffix .. '.' .. reg_com
    elseif suffix then
    -- CBUSE . param
        suffix = suffix
    elseif reg_com then
        --CBUSE . x
        suffix = reg_com
    else
        suffix_dot = ''
    end

    if register.vals then
        local vals = swizzle and get_vec_mask(register.vals, swizzle) or register.vals
        local val_count = #vals
        if val_count == 1 then
            name = tostring(vals[1])
        else
            name = _format('float%s(%s)', val_count, table.concat(vals, ', '))
        end
    end

    if sep_suffix then
        return name, suffix
    end

    local ret
    if suffix then
        ret = _format('%s%s%s', name, suffix_dot, suffix)
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

m.shader_def = {
    ['dp%d(.*)'] = function(op_args, a, b, c)
        local namea = get_var_name(a)
        local nameb = get_var_name(b)
        local namec = get_var_name(c)
        if op_args._sat then
            return _format('%s = saturate(dot(%s, %s))', namea, nameb, namec)
        else
            return _format('%s = dot(%s, %s)', namea, nameb, namec)
        end
    end,
    ['[d]?mov(.*)'] = function(op_args, a, b)
        if op_args._sat then
            return _format('%s = saturate(%s)', get_var_name(a), get_var_name(b, a))
        else
            return _format('%s = %s', get_var_name(a), get_var_name(b, a))
        end
    end,
    ['[d]?movc'] = function(op_args, dest, cond, a, b)
        local n_dest= get_var_name(dest)
        local n_cond = get_var_name(cond, dest)
        local n_a = get_var_name(a, dest)
        local n_b = get_var_name(b, dest)
        return _format('%s = %s ? %s : %s', n_dest, n_cond, n_a, n_b)
    end,
    ['[di]?add(.*)'] = function(op_args, a, b, c)
        local namea = get_var_name(a)
        local nameb = get_var_name(b, a)
        local namec = get_var_name(c, a)
        local ret
        if namec:sub(1,1) == '-' then
            ret = _format('%s%s', nameb, namec)
        else
            ret = _format('%s + %s', nameb, namec)
        end
        if op_args._sat then
            return _format('%s = saturate(%s)', namea, ret)
        else
            return _format('%s = %s', namea, ret)
        end
    end,
    ['[uid]?mul(.*)'] = function(op_args, a, b, c)
        local namea = get_var_name(a)
        local nameb = get_var_name(b, a)
        local namec = get_var_name(c, a)
        if op_args._sat then
            return _format('%s = saturate(%s * %s)', namea, nameb, namec)
        else
            return _format('%s = %s * %s', namea, nameb, namec)
        end
    end,
    ['[uid]?min'] = function(op_args, a, b, c)
        local namea = get_var_name(a)
        local nameb = get_var_name(b, a)
        local namec = get_var_name(c, a)
        return _format('%s = min(%s, %s)', namea, nameb, namec)
    end,
    ['[uid]?max'] = function(op_args, a, b, c)
        local namea = get_var_name(a)
        local nameb = get_var_name(b, a)
        local namec = get_var_name(c, a)
        return _format('%s = max(%s, %s)', namea, nameb, namec)
    end,
    ['sincos(.*)'] = function(op_args, a, b, c)
        local namea = get_var_name(a)
        local nameb = get_var_name(b, a)
        local namec = get_var_name(c, a)
        if op_args._sat then
            return _format('%s = saturate(sin(%s)); %s = saturate(cos(%s))', nameb, namea, namec, namea)
        else
            return _format('%s = sin(%s); %s=cos(%s)', nameb, namea, namec, namea)
        end
    end,
    ['log'] = function(op_args, a, b, c)
        local namea = get_var_name(a)
        local nameb = get_var_name(b, a)
        return _format('%s = log2(%s)', namea, nameb)
    end,
    ['sample.*'] = function(op_args, dest, addr, texture, sampler)
        -- load texture data with sampler
        -- dest = (texture[addr]+texture[addr+1])/2 -- example: linear sampler
        local n_dest = get_var_name(dest)
        local n_addr, com_addr = get_var_name(addr, nil, true)
        local n_texture, com_texture = get_var_name(texture, dest, true)
        local n_sampler = get_var_name(sampler)
        return _format('%s = tex2D(%s, %s.%s).%s //sample_state %s',
                    n_dest, n_texture, n_addr, com_addr:sub(1, 2), com_texture, n_sampler)
    end,
    ['ld_indexable.*'] = function(op_args, dest, addr, texture)
        -- load texture data
        --  dest = texture[addr]
        local n_dest = get_var_name(dest)
        local n_addr, com_addr = get_var_name(addr, nil, true)
        local n_texture, com_texture = get_var_name(texture, dest, true)
        return _format('%s = tex2D(%s, %s.%s).%s //ld_indexable',
                    n_dest, n_texture, n_addr, com_addr:sub(1, 2), com_texture)
    end,

    ['[ui]?mad(.*)'] = function(op_args, a, b, c, d)
        local namea = get_var_name(a)
        local nameb = get_var_name(b, a)
        local namec = get_var_name(c, a)
        local named = get_var_name(d, a)
        local ret
        if named:sub(1,1) == '-' then
            ret = _format('%s%s', namec, named)
        else
            ret = _format('%s + %s', namec, named)
        end
        if op_args._sat then
            return _format('%s = saturate(%s*%s)', namea, nameb, ret)
        else
            return _format('%s = %s*%s', namea, nameb, ret)
        end
    end,
    ['[du]?div(.*)'] = function(op_args, a, b, c)
        local namea = get_var_name(a)
        local nameb = get_var_name(b, a)
        local namec = get_var_name(c, a)
        if op_args._sat then
            return _format('%s = saturate(%s/%s)', namea, nameb, namec)
        else
            return _format('%s = %s/%s', namea, nameb, namec)
        end
    end,
    ['deriv_rt(.)(.*)'] = function(op_args, a, b)
        local namea = get_var_name(a)
        local nameb = get_var_name(b, a)
        local axis = op_args[1]
        local suffix=''
        if op_args._coarse then
            suffix = '_coarse'
        end
        return _format('%s = dd%s%s(%s)', namea, axis, suffix, nameb)
    end,
    ['[di]?eq'] = function(op_args, a, b, c)
        local namea = get_var_name(a)
        local nameb = get_var_name(b, a)
        local namec = get_var_name(c, a)
        return _format('%s = %s == %s', namea, nameb, namec)
    end,
    ['[di]?ne'] = function(op_args, a, b, c)
        local namea = get_var_name(a)
        local nameb = get_var_name(b, a)
        local namec = get_var_name(c, a)
        return _format('%s = %s != %s', namea, nameb, namec)
    end,
    ['not'] = function(op_args, a, b)
        local namea = get_var_name(a)
        local nameb = get_var_name(b)
        return _format('%s = !%s', namea, nameb)
    end,
    ['[uid]?lt'] = function(op_args, a, b, c)
        local namea = get_var_name(a)
        local nameb = get_var_name(b, a)
        local namec = get_var_name(c, a)
        return _format('%s = %s < %s', namea, nameb, namec)
    end,
    ['[uid]?ge'] = function(op_args, a, b, c)
        local namea = get_var_name(a)
        local nameb = get_var_name(b, a)
        local namec = get_var_name(c, a)
        return _format('%s = %s >= %s', namea, nameb, namec)
    end,
    ['[ui]?shl'] = function(op_args, a, b, c)
        local namea = get_var_name(a)
        local nameb = get_var_name(b)
        local namec = get_var_name(c)
        return _format('%s = %s << %s', namea, nameb, namec)
    end,
    ['[ui]?shr'] = function(op_args, a, b, c)
        local namea = get_var_name(a)
        local nameb = get_var_name(b)
        local namec = get_var_name(c)
        return _format('%s = %s >> %s', namea, nameb, namec)
    end,
    ['discard(.*)'] = function(op_args, a)
        local namea = get_var_name(a)
        if op_args._z then
            return string.format('if (%s == 0) discard', namea)
        elseif op_args._nz then
            return string.format('if (%s != 0) discard', namea)
        else
            return 'discard'
        end
    end,
    ['if(.*)'] = function(op_args, a)
        local namea = get_var_name(a)
        if op_args._z then
            return _format('if (%s == 0) {', namea), 'if'
        elseif op_args._nz then
            return _format('if (%s != 0) {', namea), 'if'
        end
    end,
    ['else'] = function(op_args)
        return '} else {', 'else'
    end,
    ['endif'] = function(op_args, a)
        return '}', 'endif'
    end,
    ['break(.*)'] = function(op_args, a, b)
        if not a then
            return 'break', 'break'
        end
        local namea = get_var_name(a)
        if op_args.c_z then
            return _format('if (%s == 0) break', namea)
        elseif op_args.c_nz then
            return _format('if (%s != 0) break', namea)
        else
            assert(false, 'break with args' .. DataDump(op_args))
        end
    end,
    ['loop'] = function(op_args)
        return 'while(true) {', 'loop'
    end,
    ['endloop'] = function(op_args)
        return '}', 'endloop'
    end,
    ['continue(.*)'] = function(op_args, a)
        if not a then
            return 'continue'
        end
        local namea = get_var_name(a)
        if op_args.c_z then
            return _format('if (%s == 0) continue', namea)
        elseif op_args.c_nz then
            return _format('if (%s != 0) continue', namea)
        else
            assert(false, 'continue with args' .. DataDump(op_args))
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
    ['[d]?rcp'] = function(op_args, a, b)
        local namea = get_var_name(a)
        local nameb = get_var_name(b, a)
        return _format('%s = rcp(%s)', namea, nameb)
    end,
    exp = function(op_args, a, b)
        local namea = get_var_name(a)
        local nameb = get_var_name(b)
        return _format('%s = exp2(%s)', namea, nameb)
    end,
    round_ni = function(op_args, a, b)
        local namea = get_var_name(a)
        local nameb = get_var_name(b)
        return _format('%s = floor(%s) //round_ni', namea, nameb)
    end,
    round_pi = function(op_args, a, b)
        local namea = get_var_name(a)
        local nameb = get_var_name(b)
        return _format('%s = ceil(%s) //round_pi', namea, nameb)
    end,
    round_ne = function(op_args, a, b)
        local namea = get_var_name(a)
        local nameb = get_var_name(b)
        return _format('%s = floor(%s) //round_ne, nearest even', namea, nameb)
    end,
    round_z = function(op_args, a, b)
        local namea = get_var_name(a)
        local nameb = get_var_name(b)
        return _format('%s = floor(%s) //round_z, round towards zero', namea, nameb)
    end,
    ftoi = function(op_args, a, b)
        local namea = get_var_name(a)
        local nameb = get_var_name(b)
        return _format('%s = floor(%s) //ftoi', namea, nameb)
    end,
    ftou = function(op_args, a, b)
        local namea = get_var_name(a)
        local nameb = get_var_name(b)
        return _format('%s = floor(%s) //ftou', namea, nameb)
    end,
    ['[uid]?tof'] = function(op_args, a, b)
        local namea = get_var_name(a)
        local nameb = get_var_name(b)
        return _format('%s = %s // itof', namea, nameb)
    end,
    ['and'] = function(op_args, a, b, c)
        local namea = get_var_name(a)
        local nameb = get_var_name(b, a)
        local namec = get_var_name(c, a)
        local comment = ''
        if namec:find('0x3f800000') then
            comment = _format('// 0x3f800000=1.0, maybe means: if (%s==0xFFFFFFFF) %s=1.0', nameb, namea)
        end
        return _format('%s = %s & %s %s', namea, nameb, namec, comment)
    end,
    ['or'] = function(op_args, a, b, c)
        local namea = get_var_name(a)
        local nameb = get_var_name(b, a)
        local namec = get_var_name(c, a)
        return _format('%s = %s | %s', namea, nameb, namec)
    end,
    ['xor'] = function(op_args, a, b, c)
        local namea = get_var_name(a)
        local nameb = get_var_name(b, a)
        local namec = get_var_name(c, a)
        return _format('%s = %s ^ %s', namea, nameb, namec)
    end,
    ['ret(.*)'] = function(op_args, a)
        if op_args.c_z then
            local namea = get_var_name(a)
            return _format('if (%s == 0) return', namea)
        elseif op_args.c_nz then
            local namea = get_var_name(a)
            return _format('if (%s != 0) return', namea)
        end
        return 'return'
    end,

    ['vs_%d_%d'] = false,
    ['ps_%d_%d'] = false,
    ['cs_%d_%d'] = false,
    ['dcl_.*'] = false,
}

-- sm5
m.shader_def5 = {
    bfi = function(op_args, width, offset, src2, src3)
        return _format([[
            bitmask = (((1 << %s)-1) << %s) & 0xffffffff
            dest = ((%s << %s) & bitmask) | (%s & ~bitmask)]], width, offset, src2, offset, src3)
    end,
    bfrev = function(op_args, dest, src)
        return _format('%s = reverse_bit(%s) ', dest, src)
    end,
    countbits = function(op_args, dest, src)
        return _format('%s = countbits(%s)', dest, src)
    end,
}


m.modifier_def = {
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

m.shader_def_cs = {
    ['ld_structured.*'] = function(op_args, dest, addr, offset, texture)
        -- load buffer data
        -- dest = texture[addr+offset]
        local n_dest = get_var_name(dest)
        local n_addr, com_addr = get_var_name(addr, nil, true)
        local n_offset, com_offset = get_var_name(offset, nil, true)
        local n_texture, com_texture = get_var_name(texture, dest, true)
        return _format('%s = %s[%s.%s][%s].%s //ld_structured',
                    n_dest, n_texture, n_addr, com_addr:sub(1, 2), n_offset, com_texture)
    end,
    ['store_structured'] = function(op_args, a, b, c, d)
        local namea, a_com = get_var_name(a, nil, true)
        local nameb = get_var_name(b)
        local namec = get_var_name(c)
        local named = get_var_name(d, a)
        return _format('%s[%s][%s].%s = %s // store_structured', namea, nameb, namec, a_com, named)
    end,
    ['store_uav_typed'] = function(op_args, a, b, c)
        local namea = get_var_name(a)
        local nameb = get_var_name(b)
        local namec = get_var_name(c)
        return _format('%s[%s] = %s', namea, nameb, namec)
    end,
    ['sync(.*)'] = function(op_args)
        return 'sync'
    end,
}

for _, defs in pairs({m.shader_def5, m.shader_def_cs, m.modifier_def}) do
    for key, func in pairs(defs) do
        m.shader_def[key] = func
    end
end


return m