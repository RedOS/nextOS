local component = require("system/apis/component")
local event = require("event")
local ser = require("/system/apis/serialization")
local computer = require("computer")
--local log = require("log")

local transnet = { modem = component.modem, encrypt = component.data, ports = { tcs = 128 }, timeout = 5 }

local function unpack (t, i)
	i = i or 1
	if t[i] ~= nil then
		return t[i], unpack(t, i + 1)
	end
end

local function tohex( str )
	local r = ''
	for n = 1, #str do
		r = r .. ( '%X' ):format ( str:sub( n , n ):byte() )
	end
	return r
end

local isListening = function ( port )
	if not transnet.modem.isOpen ( port or transnet.ports.tcs ) then
		transnet.modem.open ( port or transnet.ports.tcs )
	end
end

local listenFor = function ( id, port, seconds, ... )
	local function condition ( a, b ) 
		return ( not a and true or ( a == b and true or false) )
	end
	
	local seconds = seconds or transnet.timeout
	local t = computer.uptime()
	if seconds > 0 then
		isListening ( port )
		local resp = { event.pull ( seconds, 'modem_message' ) }
		if resp then
			--for v in ipairs ( resp ) do
			--	log.download ( #v )
			--end
			local response = { resp[3], resp[4] }
			for n=6,#resp do
				table.insert(response,n-3,resp[n])
			end
			local args = { ... }
			for n = 1, #args do
				if not condition ( args[n], response[n+2] ) then return listenFor( id, port, seconds - ( computer.uptime() -t ), unpack ( args ) ) end
			end
			return unpack ( response )
		end
	end
	return false
end

local post = function ( id, port, ... )
	if id then
		isListening ( port )
		local message = { ... }
		
		for k,v in ipairs ( message ) do
			if type ( v ) == 'table' then message[k] = ser.serialize ( v ) end
			--log.upload ( #v )
		end
		
		transnet.modem.send( id, port, unpack( message ) )
		os.sleep(0.01)
		return true
	else
		return false
	end
end

transnet.modem.maxPacketSize = function ()
	return transnet.modem.maxPacketSize()
end

transnet.send = function ( args, ... )
	local message = { ... }
	if type(args) == 'table' then
		if args.action and args.id then
			local seconds = args.seconds or transnet.timeout
			data = {}
			response = {}
			data.id, data.finalHash, data.blocksize = tohex ( transnet.encrypt.crc32( tostring( os.time() ) ) )
			data.action = args.action
			data.message = ser.serialize( message )
			data.finalHash = tohex ( transnet.encrypt.crc32( data.message ) )
			data.packetsize = transnet.modem.maxPacketSize()-512
			data.blocksize =  math.ceil( #data.message / data.packetsize )
			data.messagesize = #data.message
			post ( args.id, args.port or transnet.ports.tcs , data.id, data.action )
			response.id, response.port = listenFor ( args.id, args.port or transnet.ports.tcs, seconds, data.id, data.action, 'OK' )
			if not response.id then return false end
			post ( response.id, response.port, data.id, 'HEAD', data.blocksize, data.messagesize)
			response.id = listenFor ( response.id, response.port, seconds, data.id, 'HEAD', 'OK' )
			if not response.id then return false end
			
			for n = 1, data.blocksize do
				data.messagepart = data.message:sub ( (n - 1)*data.packetsize + 1, n*data.packetsize)
				post ( response.id, response.port, data.id, 'BODY', n, data.messagepart, tohex ( transnet.encrypt.crc32 ( data.messagepart ) ) )
				response.id = listenFor ( response.id, response.port, seconds, data.id, 'BODY', n, 'OK' )
				if not response.id then return false end
			end
			
			post ( response.id, response.port, data.id, 'END')
			response.id = listenFor ( response.id, response.port, seconds, data.id, 'END', 'OK')
			if response.id then return true end
		end
	end
	return false
end

transnet.get = function ( args )
	local received = ''
	if not args or type(args) ~= table then args = {} end
	local seconds = args.seconds or transnet.timeout
	data = {}
	response = {}
	response.id, response.port, data.id, data.action = listenFor ( args.id, args.port or transnet.ports.tcs, seconds, args.action )
	if not data.id or not data.action then return false end
	post ( response.id, response.port, data.id, data.action, 'OK' )
	response.id, _, _, _, data.blocksize, data.messagesize = listenFor ( response.id, response.port, seconds, data.id, 'HEAD' )
	if not data.blocksize or not data.messagesize then return false end
	post ( response.id, response.port, data.id, 'HEAD', 'OK' )
	
	for n = 1, data.blocksize do
		response.id, _, _, _, _, data.messagepart, data.messagehash = listenFor ( response.id, response.port, seconds, data.id, 'BODY', n )
		if not ( tohex ( transnet.encrypt.crc32 ( data.messagepart ) ) == data.messagehash ) then return false end
		received = received .. data.messagepart
		post ( response.id, response.port, data.id, 'BODY', n, 'OK' )
	end

	response.id = listenFor ( response.id, response.port, seconds, data.id, 'END' )
	if not response.id then return false end
	post ( response.id, response.port, data.id, 'END', 'OK')
	return response.id, data.action, data.id, unpack ( ser.unserialize ( received ) )
end

return transnet