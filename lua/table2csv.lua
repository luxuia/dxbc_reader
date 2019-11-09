
local filepath = ...

local data = loadfile(filepath)()

if not data then
	os.exit(false)
end

local strs = {"string,string\nID,text\n编号,文本"}
for k, v in pairs(data) do
	if type(v) == "string" then
		-- local val = string.gsub(v, ",", "，")
		table.insert(strs, k..",\""..v.."\"")
	end
end

local csv = table.concat(strs, "\n")

local f = io.open(filepath..".csv","wb")
f:write(csv)
f:close()

