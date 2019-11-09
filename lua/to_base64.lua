
local crypt = require "crypt"

local src, tar=...
if not tar then
	tar = src..".64"
end

local f = io.open(src, "rb")
local binary = f:read("*a")
f:close()

local b64 = crypt.base64encode(binary)
f = io.open(tar, "w")
f:write(b64)
f:close()
