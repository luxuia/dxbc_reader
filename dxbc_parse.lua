
local DataDump = require 'table_dumper'

local lpeg = require 'lpeg'

local match = lpeg.match
local R, P, C, Cp, S, V, Ct, Cmt, Carg =
    lpeg.R, lpeg.P, lpeg.C, lpeg.Cp, lpeg.S, lpeg.V, lpeg.Ct, lpeg.Cmt, lpeg.Carg


local eof = P(-1)
local space = S(' \r\t')
local line = Cmt(P"\n"*Carg(1),
    function(_, pos, state)
        local line = state.line
        state.cur_line = line[pos] or state.cur_line+1
        line[pos] = state.cur_line
        return true
    end)
line = P'\n'

local pass = (space+line)^0

local _dec = R('09')
local _int = _dec^1
local _float = P('-')^-1 * _dec^1 * (P('.')^-1 * _dec^0)^-1

local _alpha = R('az', 'AZ')
local _alpnum = _alpha+_dec

local number = C(_float)/function(...)
        return tonumber(...)
    end

local _hex = (P('0x') + P('0X')) * (_alpnum^1)
local hex = C(_hex)/function(...)
        return ...
    end

local variable = (_alpnum + S'_$')^1

local comment = P'//' * C(P(1-P'\n')^0) / function(comment)
        return {comment = comment}
    end

local function any_patt(expect)
    return P(1-P(expect))^1
end

-- add|dcl_resource_texture2d (float,float,float,float)|sample_indexable(texture2d)(float,float,float,float)
local op = C(variable * (space^-1 * (P'('*any_patt(')')*P')')
    + ' linear'
    + ' noperspective'
    + ' constant'
    + ' linearcentroid')^0)

local _negtive = C('-') / function (neg)
        if neg then
            return {neg=true}
        else
            return {neg=false}
        end
    end

local _var_name = C(variable) / function(var_name)
        return {name = var_name}
    end

local _var_idx_patt = C((_alpnum+S'_+ .')^1)
local _var_idx = P'[' * _var_idx_patt * P']' / function(var_idx)
        return {idx = var_idx}
    end

local _var_suffix = P'.' * C(_alpha^1) / function(var_suffix)
        return {suffix = var_suffix}
    end

local _vector = P'l(' * (hex+number) * (pass*P','*pass * (hex+number))^0 *P')' / function(...)
        return {vals = {...}}
    end

local function merge_tbl(...)
    local ret = {}
    for _, tbl in ipairs({...}) do
        for k, v in pairs(tbl) do
            ret[k] = v
        end
    end
    return ret
end

local _abs = C'|' / function()
        return {abs=true}
    end

-- TODO abs process
local var = (_negtive^-1*_vector + _negtive^-1 * _abs^-1
                * _var_name * _var_idx^-1 * _var_suffix^-1 * _abs^-1) / merge_tbl

local args = var * (space^0*P(",")*space^0 *var + space^0*P("|")*space^0 *var)^0

local command = C(op * space ^0 * args^-1) / function(...)
        local data = {...}
        local src = data[1]
        local op_name = data[2]
        table.remove(data, 1)
        table.remove(data, 1)
        return {
            op = op_name,
            args = data,
            src = src,
        }
    end

--print(DataDump({lpeg.match(command, 'vs_5_0')}))

local trunk = ((comment+command)*pass)^0

----------------- CBUFFER START
local function patt(p, name)
    return P(pass*C(p)*pass)/function(v)
            local numv = tonumber(v)
            return {[name] = numv or v}
        end
end
local cbuffer_var = patt('row_major', 'prefix')^-1 * patt(variable, 'type')* patt(variable, 'name')
            * P('['*(patt(number, 'size')*P']'))^-1 * P';'* pass * P'// Offset:' * pass * patt(number, 'offset')
            * P'Size:' * pass * patt(number, 'size') * P('[unused]')^-1 / merge_tbl
local cbclass = pass*P('cbuffer') * patt(variable, 'cbuffer_name') *
                    pass * P'{' * pass * cbuffer_var^1 *pass * '}' / function(...)
                    local data = {...}
                    local cbuffer = data[1]
                    cbuffer.vars = {}
                    for i=2, #data do
                        cbuffer.vars[i-1] = data[i]
                    end
                    return cbuffer
                end
---------------- CBUFFER END

--[=[
local input = [[
cbuffer GlobalPS
{
  float4 CameraPosPS;                // Offset:    0 Size:    16 [unused]
  float4 CameraInfoPS;               // Offset:   16 Size:    16 [unused]
}
 ]]

print(DataDump({lpeg.match(cbclass^0, input)}))

 --]=]


local function process_cbuffer(str)
    return {lpeg.match(cbclass^0, str)}
end

local function split(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

local function process_binding(list, start_idx, end_idx)
    local data = {}
    for i=start_idx, end_idx do
        local tokens = split(list[i])
        data[#data+1] = {
            name = tokens[1],
            bind = tokens[5],
        }
    end
    return data
end

local function process_input(list, start_idx, end_idx)
    local data = {}
    for i=start_idx, end_idx do
        local tokens = split(list[i])
        if #tokens >= 4 then
            data[#data+1] = {
                name = tokens[1],
                bind = 'v' .. tokens[4],
                mask = tokens[3],
                register = tokens[4],
            }
        end
    end
    return data
end

local function process_output(list, start_idx, end_idx)
    local data = {}
    for i=start_idx, end_idx do
        local tokens = split(list[i])
        if #tokens >= 4 then
            data[#data+1] = {
                name = tokens[1],
                bind = 'o' .. tokens[4],
                mask = tokens[3],
                register = tokens[4],
            }
        end
    end
    return data
end

return function(input)
        local _ret = {lpeg.match(trunk, input)}
        local ret = {}
        local first_op
        local comms = {}
        for _, _line in ipairs(_ret) do
            if type(_line) ~= 'table' or _line.comment ~= '' then
                if not first_op and type(_line) == 'table' and _line.comment then
                    comms[#comms+1] = _line.comment
                else
                    first_op = true
                    table.insert(ret, _line)
                end
            end
        end
        --print(DataDump(ret))
        local block_data = {}
        local set_block_data = function(block_name, idx)
            for _, v in pairs(block_data) do
                if not v.last_idx then
                    v.last_idx = idx-1
                    break
                end
            end

            block_data[block_name] = {idx = idx}
        end
        for idx=1, #comms do
            if comms[idx]:find('Buffer Definitions:') then
                set_block_data('idx_cbuffer', idx)
            elseif comms[idx]:find('Resource Bindings:') then
                set_block_data('idx_binding', idx)
            elseif comms[idx]:find('Input signature:') then
                set_block_data('idx_input', idx)
            elseif comms[idx]:find('Output signature:') then
                set_block_data('idx_output', idx)
            end
        end
        for _, v in pairs(block_data) do
            if not v.last_idx then
                v.last_idx = #comms
            end
        end
        local cbuff_data = block_data.idx_cbuffer and process_cbuffer(table.concat(comms, '\n', block_data.idx_cbuffer.idx+1, block_data.idx_cbuffer.last_idx)) or {}

        local binding_data = block_data.idx_binding and process_binding(comms, block_data.idx_binding.idx+3, block_data.idx_binding.last_idx) or {}
        local input_data = block_data.idx_input and process_input(comms, block_data.idx_input.idx+3, block_data.idx_input.last_idx) or {}
        local output_data = block_data.idx_output and process_output(comms, block_data.idx_output.idx+3, block_data.idx_output.last_idx) or {}

        --print(DataDump(block_data))

        table.insert(ret, 1, {
                cbuff_data = cbuff_data,
                binding_data = binding_data,
                input_data = input_data,
                output_data = output_data,
            })

        return ret
    end