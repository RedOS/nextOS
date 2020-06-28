local component = require ( "system/apis/component" )

local function connect ( address )

	if address then 
		if component.proxy( address ) then
			if component.type( address ) == 'stargate' then
				local self = { sg = component.proxy( address ) }
			end
		end
	else
		local self = { sg = component.stargate }
	end
	
	local hasIris = function ()
		return self.sg.irisState () == 'Offline' and false or true
	end

	local getState = function( )
		local status = { self.sg.stargateState () }
		return status[1] == 'Offline' and false or state:lower(), status[2], status[3] == 'Incoming' and 'in' or status[3] == 'Outgoing' and 'out' or false
	end

	local getIrisState = function ( )
		if hasIris then
			return self.sg.irisState():lower()
		else
			return false
		end
	end

	local getAdress = function ()
		return self.sg.localAddress ()
	end

	local getUCID = function ()
		return self.sg.address
	end

	local getConnection = function ()
		if getState () == 'idle' or getState () == 'offline' then return false end
		return self.sg.remoteAddress ()
	end

	local getStoredEnergy = function ()
		return self.sg.energyAvailable () * 80
	end

	local getRequiredEnergy = function ( address )
		return address and self.sg.energyToDial ( address ) or false
	end

	local dial = function( address )
		if address and getRequiredEnergy ( address ) then
			if getStoredEnergy () >= getRequiredEnergy ( address ) then
				self.sg.dial ( address )
				return true
			end
		end
		return false
	end

	local shutdown = function ()
		self.sg.disconnect()
		return true
	end

	local setIris = function ( bool )
		if hasIris () then
			local status = self.sg.irisState ():lower ()
			if status == 'opening' or status == 'open' and bool == false then
				self.sg.closeIris ()
			elseif status == 'closing' or status == 'closed' and bool == true then
				self.sg.openIris ()
			end
			return true
		end
		return false
	end
	
	return {
	hasIris = hasIris,
	getState = getState,
	getIrisState = getIrisState,
	getAddress = getAddress,
	getUCID = getUCID,
	getConnection = getConnection,
	getStoredEnergy = getStoredEnergy,
	getRequiredEnergy = getRequiredEnergy,
	dial = dial,
	shutdown = shutdown,
	setIris = setIris
	}
end

return { connect = connect }