local component = require ( "system/apis/component" )

function connect ( address )

	if address then 
		if component.proxy( address ) then
			if component.type( address ) == 'stargate' then
				local sg = component.proxy( address )
			end
		end
	else
		local sg = component.stargate
	end
	
	local stargate = {}

	stargate.hasIris = function ()
		return sg.irisState () == 'Offline' and false or true
	end

	stargate.getState = function()
		local status = { sg.stargateState () }
		return status[1] == 'Offline' and false or state:lower(), status[2], status[3] == 'Incoming' and 'in' or status[3] == 'Outgoing' and 'out' or false
	end

	stargate.getIrisState = function ()
		if stargate.hasIris then
			return sg.irisState():lower()
		else
			return false
		end
	end

	stargate.getAdress = function ()
		return sg.localAddress ()
	end
	
	stargate.getUCID = function ()
		return sg.address
	end

	stargate.getConnection = function ()
		if stargate.getState () == 'idle' or stargate.getState () == 'offline' then return false end
		return sg.remoteAddress ()
	end

	stargate.getStoredEnergy = function ()
		return sg.energyAvailable () * 80
	end
	
	stargate.getRequiredEnergy = function ( address )
		return address and sg.energyToDial ( address ) or false
	end
	
	stargate.dial = function( address )
		if address and stargate.getRequiredEnergy ( address ) then
			if stargate.getStoredEnergy () >= stargate.getRequiredEnergy ( address )
				sg.dial ( address )
				return true
			end
		end
		return false
	end
	
	stargate.shutdown = function ()
		sg.disconnect()
		return true
	end
	
	stargate.setIris( bool )
		if stargate.hasIris () then
			local status = sg.irisState ():lower ()
			if status == 'opening' or status == 'open' and bool == false then
				sg.closeIris ()
			elseif status == 'closing' or status == 'closed' and bool == true then
				sg.openIris ()
			end
			return true
		end
		return false
	end
	
	return sg and stargate or false
end