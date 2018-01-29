local component = require ( "system/apis/component" )

local stargate = {}

function connect ( address )

	if address then 
		if component.proxy( address ) then
			if component.type( address ) == 'stargate' then
				local self = { sg = component.proxy( address ) }
			end
		end
	else
		local self = { sg = component.stargate }
	end
	
	hasIris = function ()
		return self.sg.irisState () == 'Offline' and false or true
	end

	getState = function( )
		local status = { self.sg.stargateState () }
		return status[1] == 'Offline' and false or state:lower(), status[2], status[3] == 'Incoming' and 'in' or status[3] == 'Outgoing' and 'out' or false
	end

	getIrisState = function ( )
		if hasIris then
			return self.sg.irisState():lower()
		else
			return false
		end
	end

	getAdress = function ()
		return self.sg.localAddress ()
	end

	getUCID = function ()
		return self.sg.address
	end

	getConnection = function ()
		if getState () == 'idle' or getState () == 'offline' then return false end
		return self.sg.remoteAddress ()
	end

	getStoredEnergy = function ()
		return self.sg.energyAvailable () * 80
	end

	getRequiredEnergy = function ( address )
		return address and self.sg.energyToDial ( address ) or false
	end

	dial = function( address )
		if address and getRequiredEnergy ( address ) then
			if getStoredEnergy () >= getRequiredEnergy ( address ) then
				self.sg.dial ( address )
				return true
			end
		end
		return false
	end

	shutdown = function ()
		self.sg.disconnect()
		return true
	end

	setIris = function ( bool )
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