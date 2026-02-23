#!/usr/bin/env lua
-- Golden regression tests for dxbc_reader
-- Run from project root: lua run_tests.lua  or  .\lua\lua.exe run_tests.lua

local function run_dxbc_reader(input_path, output_path)
    local dxbc_reader = loadfile('dxbc_reader.lua', 't', _G)
    if not dxbc_reader then
        return nil, "Failed to load dxbc_reader.lua"
    end
    -- Use LUA env var, or bundled lua/lua.exe (Windows), or 'lua' from PATH
    local lua = os.getenv('LUA')
    if not lua then
        local sep = package.config:sub(1, 1)
        local exe = (sep == '\\') and 'lua\\lua.exe' or 'lua/lua'
        local f = io.open(exe, 'r')
        if f then
            f:close()
            lua = exe
        else
            lua = 'lua'
        end
    end
    local cmd = string.format('%s dxbc_reader.lua %s -o %s -p false', lua, input_path, output_path)
    local handle = io.popen(cmd)
    if not handle then
        return nil, "Failed to run dxbc_reader"
    end
    local output = handle:read('*a')
    handle:close()
    return output
end

local function read_file(path)
    local f = io.open(path, 'r')
    if not f then return nil end
    local content = f:read('*a')
    f:close()
    return content
end

-- All .txt files in example/ (exclude .hlsl)
local example_list = {
    'example/fragment.txt', 'example/fragment2.txt', 'example/fragment3.txt',
    'example/fragment4.txt', 'example/vertex.txt', 'example/vertex2.txt',
    'example/bl3.txt', 'example/issue8.txt',
    'example/nino/vertex1.txt', 'example/nino/overlay_outline_p.txt',
    'example/nino/outline_p.txt', 'example/nino/merge_v.txt', 'example/nino/outline_v.txt',
    'example/nino/export_mat_v.txt', 'example/nino/merge_p.txt', 'example/nino/frag1.txt',
    'example/nino/export_mat_p.txt',
}

local function is_compute_shader(path)
    local f = io.open(path, 'r')
    if not f then return false end
    local content = f:read('*a')
    f:close()
    return content and content:find('cs_5_0')
end

local tests = {}
for _, input_path in ipairs(example_list) do
    local f = io.open(input_path, 'r')
    if f then
        f:close()
        local name = input_path:gsub('.*/', ''):gsub('.*\\', '')
        local expect = is_compute_shader(input_path)
            and { "void main(", "numthreads", "groupshared" }
            or { "void main(", "class INPUT", "class OUT" }
        tests[#tests + 1] = {
            name = name,
            input = input_path,
            output = "test_output_" .. name:gsub('%.txt$', '') .. ".hlsl",
            expect_contains = expect,
        }
    end
end

local passed = 0
local failed = 0

for _, t in ipairs(tests) do
    io.write(string.format("Test %s ... ", t.name))
    local ok, err = pcall(function()
        run_dxbc_reader(t.input, t.output)
        local content = read_file(t.output)
        if not content then
            error("Output file not created: " .. t.output)
        end
        for _, pattern in ipairs(t.expect_contains) do
            if not content:find(pattern, 1, true) then
                error("Output missing expected content: " .. pattern)
            end
        end
        os.remove(t.output)
    end)
    if ok then
        io.write("PASS\n")
        passed = passed + 1
    else
        io.write("FAIL: " .. tostring(err) .. "\n")
        failed = failed + 1
    end
end

io.write(string.format("\n%d passed, %d failed\n", passed, failed))
os.exit(failed > 0 and 1 or 0)
