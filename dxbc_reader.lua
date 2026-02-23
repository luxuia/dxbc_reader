

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

-- Normalize print option to boolean (argparse may return string)
args.print = (args.print ~= false and args.print ~= 'false')

local parser = require 'dxbc_parse'
local dxbc_def = require 'dxbc_def'

local _format = string.format

-- Ordered op patterns: longer/more specific first for deterministic matching
local shader_def_keys
do
    local keys = {}
    for k in pairs(dxbc_def.shader_def) do
        keys[#keys + 1] = k
    end
    table.sort(keys, function(a, b) return #a > #b end)
    shader_def_keys = keys
end

local function format_io_vars(var_list)
    local lines = {}
    local tex_reg_cnt = 1
    for _, var in pairs(var_list) do
        if var.name == 'TEXCOORD' then
            lines[#lines + 1] = '\t' .. var.name .. tex_reg_cnt .. ';'
            tex_reg_cnt = tex_reg_cnt + 1
        else
            lines[#lines + 1] = '\t' .. var.name .. ';'
        end
    end
    return lines
end

local function run(options)
    local file_name = options.input
    local DEBUG = options.debug

    local file = io.open(file_name, 'r')
    if not file then
        io.stderr:write(string.format("Error: cannot open input file '%s'\n", file_name))
        os.exit(1)
    end
    local str = file:read('*a')
    file:close()

    local parse_data = parser(str)
    if not parse_data or type(parse_data) ~= 'table' or not parse_data[1] then
        io.stderr:write("Error: failed to parse DXBC or invalid parse result\n")
        os.exit(1)
    end
    local res_def = parse_data[1]
    if not res_def.cbuff_data or not res_def.input_data or not res_def.output_data then
        io.stderr:write("Error: parse result missing required fields (cbuff_data, input_data, output_data)\n")
        os.exit(1)
    end

    dxbc_def:init(parse_data)

    local function get_op(op)
        if not op then return end

        local capture
        local target_op
        for i = 1, #shader_def_keys do
            local op_def = shader_def_keys[i]
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
            close = {['else'] = true, endif = true},
        },
        ['else'] = {
            start = 'else',
            close = {endif = true},
        },
        ['loop'] = {
            start = 'loop',
            close = {endloop = true},
        },
        ['switch'] = {
            start = 'switch',
            close = {endswitch = true},
        },
        ['case'] = {
            start = 'case',
            close = {case = true, ['break'] = true},
        },
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

    local function append(msg)
        translate[#translate + 1] = msg
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

    append('class INPUT {')
    for _, line in ipairs(format_io_vars(res_def.input_data)) do
        append(line)
    end
    append('}')

    append('class OUT {')
    for _, line in ipairs(format_io_vars(res_def.output_data)) do
        append(line)
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
                    op_param = op_param and arr2dic(op_param) or {}
                    if DEBUG then
                        append('')
                        if DEBUG == 't' then
                            append(string.rep('\t', #blocks) .. DataDump(command))
                        end
                    end
                    local ok, op_str, block_tag = pcall(function()
                        return op_func(op_param, table.unpack(command.args or {}))
                    end)
                    if not ok then
                        io.stderr:write(string.format("Warning: %s - %s\n", command.src or command.op, tostring(op_str)))
                        append(string.rep('\t', #blocks) .. '// ' .. (command.src or command.op))
                    else
                        local last_block = blocks[#blocks]
                        if last_block and last_block.close[block_tag] then
                            table.remove(blocks, #blocks)
                        end

                        if DEBUG then
                            append(string.rep('\t', #blocks) .. command.src)
                        end
                        local last_gram = op_str and op_str:sub(#op_str) or ''
                        local end_block = (last_gram == '}' or last_gram == '{') and '' or ';'
                        append(string.format('%s%s%s', string.rep('\t', #blocks), op_str or '', end_block))

                        if block_tag and BLOCK_DEF[block_tag] then
                            table.insert(blocks, BLOCK_DEF[block_tag])
                        end
                        line_id = line_id + 1
                    end
                else
                    io.stderr:write(string.format("Warning: unimplemented op '%s'\n", command.op))
                    append(string.rep('\t', #blocks) .. '// ' .. (command.src or command.op))
                end
            else
                io.stderr:write(string.format("Warning: unimplemented op '%s'\n", command.op))
                append(string.rep('\t', #blocks) .. '// ' .. (command.src or command.op))
            end
        end
        idx = idx + 1
    end
    append("}")

    local ret = table.concat(translate, '\n')

    local out_file = io.open(options.output, 'w')
    if not out_file then
        io.stderr:write(string.format("Error: cannot open output file '%s'\n", options.output))
        os.exit(1)
    end
    out_file:write(ret)
    out_file:close()

    return ret
end

local ret = run(args)
if args.print then
    print(ret)
end
