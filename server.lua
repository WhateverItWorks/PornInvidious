local socket = require("socket")

local ip = '127.0.0.1'
local port = '8069'

if #arg > 0 then
	local i = 1
	while i <= #arg do
		if arg[i] == "--help" then
			print("Usage: "..arg[0].." [options]\nOptions:\n-i <ip>\n-p <port>")
			os.exit(0)
		elseif arg[i] == "-i" then
			i = i + 1
			if i <= #arg then
				ip = arg[i]
			else
				print("Missing argument for -i")
				os.exit(1)
			end
		elseif arg[i] == "-p" then
			i = i + 1
			if i <= #arg then
				port = arg[i]
			else
				print("Missing argument for -p")
				os.exit(1)
			end
		else
			print("Wrong option")
			os.exit(1)
		end
		i = i + 1
	end
end

local server = assert(socket.bind(ip, port))

print("Connected to "..ip..":"..port)

while 1 do
	local client = server:accept()
	local line, err = client:receive()
	if line ~= nil then
		print(line)
		local filename
		if line == "GET /favicon.ico HTTP/1.1" then
			filename = "res/favicon.png"
		else
			os.execute("./gen.sh \"$(echo \""..line.."\" | cut -d' ' -f2)\"")
			filename = "output.html"
		end
		local file = io.open(filename,"r")
		local content = file:read("*a")
		local contentType = "image/png"
		if filename == "output.html" then
			os.remove("output.html")
			contentType = "text/html"
		end
		if not err then client:send("HTTP/1.1 200 OK\nContent-type: " .. contentType .. "\n\n"..content) end
	end
	client:close()
end
