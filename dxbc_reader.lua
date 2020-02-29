

local DataDump = require 'table_dumper'


local argparse = require 'argparse'
local arg_parse = argparse('dxbc_reader')

arg_parse:argument('input', 'input file')
arg_parse:option('-o --output', 'output file', false)
arg_parse:option('-d --debug', 'print debug info', false)
arg_parse:option('-p --print', 'std print', true)

local args = arg_parse:parse()

if not args.input then
    args.input = 'fragment4.txt'
end
if not args.output then
    args.output = args.input .. '.hlsl'
end

if args.print == 'false' then
    args.print = false
end

local DEBUG=args.debug

local parser = require 'dxbc_parse'
local dxbc_def = require 'dxbc_def'

--local file_name = 'fragment.dxbc'
local file_name = args.input

local _format = string.format

local file = io.open(file_name, 'r')
local str = file:read('*a')

local parse_data = parser(str)

dxbc_def:init(parse_data)

--print(DataDump(parse_data))

local function get_op(op)
    if not op then return end

    local capture
    local target_op
    for op_def in  pairs(dxbc_def.shader_def) do
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

local BLOCK_DEF = {
    ['if'] = {
        start = 'if',
        close = {['else']=true, endif=true},
    },
    ['else'] = {
        start = 'else',
        close = {endif=true},
    },
    ['loop'] = {
        start = 'loop',
        close = {endloop=true},
    },
    ['switch'] = {
        start = 'switch',
        close = {endswitch=true},
    },
    ['case'] = {
        --[[
            case can closed by self
            switch a
                case a
                case b
                    break
            endswitch
        ]]--
        start = 'case',
        close = {case=true, ['break']=true},
    }
}

local function pre_process_command(command)
    if command.args then
        for _, reg in pairs(command.args) do
            if reg.idx then
                if tonumber(reg.idx) then
                    reg.idx = tonumber(reg.idx)
                end
            end
        end
    end
end

local translate = {}
local idx = 2
local line_id = 1
local blocks = {}

local res_def = parse_data[1]

local function append(msg)
    translate[#translate+1] = msg
end

if DEBUG == 't' then
    append(DataDump(res_def.binding_data))
end

------------  CBUFFER DEFINE
for _, cbuff in pairs(res_def.cbuff_data) do
    append('class ' .. cbuff.cbuffer_name .. '{')
    for _, var in pairs(cbuff.vars) do
        append(_format('\t%s\t%s;', var.type, var.name))
    end
    append('}')
end

local _tex_reg_cnt = 1
append('class INPUT {')
for _, var in pairs(res_def.input_data) do
    if var.name == 'TEXCOORD' then
        append('\t' .. var.name .. _tex_reg_cnt .. ';')
        _tex_reg_cnt = _tex_reg_cnt+1
    else
        append('\t' .. var.name.. ';')
    end
end
append('}')

_tex_reg_cnt=1
append('class OUT {')
for _, var in pairs(res_def.output_data) do
    if var.name == 'TEXCOORD' then
        append('\t' .. var.name .. _tex_reg_cnt.. ';')
        _tex_reg_cnt = _tex_reg_cnt+1
    else
        append('\t' .. var.name .. ';')
    end
end
append('}')
------------ CBUFFER DEFINE END

append("void main(INPUT in) {")
blocks[1] = {close = {}}
while idx <= #parse_data do
    local command = parse_data[idx]
    if command.op then
        local op_name, op_param = get_op(command.op)

        if op_name then
            local op_func = dxbc_def.shader_def[op_name]
            if op_func then
                pre_process_command(command)
                op_param = op_param and arr2dic( op_param) or {}
                local op_str, block_tag = op_func(op_param, table.unpack(command.args))

                local last_block = blocks[#blocks]
                if last_block and last_block.close[block_tag] then
                    table.remove(blocks, #blocks)
                end

                if DEBUG then
                    append('')
                    if DEBUG == 't' then
                        append(string.rep('\t', #blocks) .. DataDump(command))
                    end
                    append(string.rep('\t', #blocks) .. command.src)
                end
                local last_gram = op_str:sub(#op_str)
                local end_block = (last_gram == '}' or last_gram == '{' ) and '' or ';'
                append(string.format('%s%s%s', string.rep('\t', #blocks), op_str, end_block))

                if BLOCK_DEF[block_tag] then
                    table.insert(blocks, BLOCK_DEF[block_tag])
                end
                line_id = line_id+1
            end
        else
            assert(false, 'not implement op ' .. command.op)
        end
    end
    idx = idx+1
end
append("}")

local ret = table.concat(translate, '\n')
if args.print then
    print(ret)
end

io.open(args.output, 'w'):write(ret)