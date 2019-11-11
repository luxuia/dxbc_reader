

local DataDump = require 'table_dumper'


local argparse = require 'argparse'
local arg_parse = argparse('dxbc_reader')

arg_parse:argument('input', 'input file')
arg_parse:option('-o --output', 'output file', 'dxbc.out')
arg_parse:option('-d --debug', 'print debug info', false)

local args = arg_parse:parse()

local DEBUG=args.debug

local parser = require 'dxbc_parse'
local dxbc_def = require 'dxbc_def'

--local file_name = 'fragment.dxbc'
local file_name = args.input or 'fragment4.txt'

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

local translate = {}
local idx = 2
local line_id = 1
local blocks = {}

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

while idx <= #parse_data do
    local command = parse_data[idx]
    if command.op then
        local op_name, op_param = get_op(command.op)
           
        if op_name then
            local op_func = dxbc_def.shader_def[op_name]
            if op_func then
                --pre_process_command(command)
                --print(DataDump(command))
                op_param = op_param and arr2dic( op_param) or {}
                local op_str, block_tag = op_func(op_param, table.unpack(   command.args))

                local last_block = blocks[#blocks]
                if last_block and last_block.close[block_tag] then
                    table.remove(blocks, #blocks)
                end

                if DEBUG then
                    translate[#translate+1] = ''
                    translate[#translate+1] = command.src
                end
                translate[#translate+1] = string.format('%s%s', string.rep('\t', #blocks), op_str)
                --print(translate[#translate])
                                
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

local ret = table.concat(translate, '\n')
print(ret)

io.open(args.output, 'w'):write(ret)