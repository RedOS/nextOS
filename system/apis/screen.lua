local component = require( 'component' )

local function tohex( str )
local str = tostring( str )
local r = ( '%06X' ):format ( str )
	return r
end

function unpack (tab, i)
	i = i or 1
	if tab[i] ~= nil then
		return t[i], unpack(tab, i + 1)
	end
end

local maxWidth, maxHeight =  ( { component.gpu.getResolution() } )[2]

local screen = { resolution = function() return component.gpu.getResolution() end,
	maxWidth = function () return ( { component.gpu.getResolution() } )[1] end,
	maxHeight = function () return ( { component.gpu.getResolution() } )[2] end, }

local native = {
	window = { child = {}, childcount = 0, hasColors = ( component.gpu.getDepth() > 1 and true or false ) },
	width = ( { component.gpu.getResolution() } )[1],
	height = ( { component.gpu.getResolution() } )[2],
	fgColor = 0xFFFFFF,
	bgColor = 0x000000,
	cursorX = 1,
	cursorY = 1,
	x = 1,
	y = 1,
	display = {}
}

for h = 1, native.height do
	native.display[h] = {
	str = string.rep ( ' ', native.width ),
	fg = string.rep ( native.fgColor , native.width ),
	bg = string.rep ( native.bgColor , native.width ) }
end

screen.native = {
	addChild = function ()
		if type ( t ) == 'table' then
			native.window.childcount = native.window.childcount + 1
			table.insert ( native.window.child, native.window.childcount, t )
			return native.window.childcount
		end
		return false
	end,
	blit = function ( text, foreground, background, fast )
		str, fg, bg = text, foreground, background
		local aX, aY = ( native.x + native.cursorX - 1 ), ( native.y + native.cursorY - 1 )
		if ( aY <= screen.maxHeight() ) and ( aY > 0 ) and ( native.cursorY  <= native.height ) then
			local n = 1
			while n < math.min ( #str, native.width, screen.maxWidth() ) do
				local p = ( n - 1 ) * 6 + 1
				if fast then
					fg_color, bg_color = fg:sub( p, n * 6 ), bg:sub( p, n * 6 )
					if ( last_fg ~= fg_color ) then component.gpu.setForeground( tonumber ( fg_color, 16 ) ) end
					if ( last_bg ~= bg_color ) then component.gpu.setBackground( tonumber ( bg_color, 16 ) ) end
					ok = component.gpu.set ( aX + n - 1, aY, str:sub( n, n ) )
					n = n + 1
					local last_fg = fg_color
					local last_bg = bg_color
				else
					fg_color, bg_color = fg:sub( p, n * 6 ), bg:sub( p, n * 6 )
					local l_fg = fg:sub ( p, #fg ):match ( '[' .. fg_color .. ']+' )
					local l_bg = bg:sub ( p, #bg ):match ( '[' .. bg_color .. ']+' )
					local l_str = str:sub ( n, #str ):match ( str:sub( n, n ) .. '+' )
					local length = math.min ( #l_fg/6, #l_bg/6, #l_str )
					if ( last_fg ~= fg_color ) then component.gpu.setForeground( tonumber ( fg_color, 16 ) ) end
					if ( last_bg ~= bg_color ) then component.gpu.setBackground( tonumber ( bg_color, 16 ) ) end
					ok = component.gpu.fill ( aX + n - 1, aY, length, 1, str:sub( n, n ) )
					n = n + length
					local last_fg = fg_color
					local last_bg = bg_color
				end
			end
			native.cursorX = native.cursorX + #str
			return ok
		end
		return false
	end,
	getPosition = function ()
		return native.x, native.y
	end,
	setCursor = function ( new_x, new_y )
		native.cursorX, native.cursorY = native.x - 1 + math.floor ( new_x ), native.y - 1 + math.floor( new_y )
	end,
	setCursorBlink = function ( blink )
		native.cursorBlink = blink and true or false
		return true
	end,
	redraw = function ()
		for n = 1, native.height do
			local line = display[ n ]
			screen.native.setCursor( native.x, native.y + n - 1 )
			ok = screen.native.blit ( line.str, line.fg, line.bg, false )
			if not ok then return false end
		end
		return true
	end,
}

screen.create = function ( parent, x, y, width, height )
	if not parent or not x or not y or not width or not height then error("Missing arg(s)") else
		local window = { child = {}, childcount = 0, hasColors = parent.hasColors }
		local width, height = width, height
		local fgColor, bgColor = 0xFFFFFF, 0x000000
		local cursorX, cursorY = 1, 1
		local x, y = math.floor( x) , math.floor ( y )
		local visible, cursorBlink, display = true, true, {}
		local id = parent.addChild ( window )
		for h = 1, height do
			display[h] = {
			str = string.rep ( ' ', width ),
			fg = string.rep ( tohex ( fgColor ), width ),
			bg = string.rep ( tohex ( bgColor ), width ) }
		end

		local function updateCursorPos ()
			local parent_x, parent_y = parent.getPosition ()
			parent.setCursor ( parent_x - 1 + x - 1 + cursorX, parent_y - 1 + y - 1 + cursorY )
			return true
    	end

		local function redrawLine ( number, fast )
			if display [ number ] then
				local line = display[ number ]
				parent.setCursor( x, y + number - 1 )
				if 6*#line.str == #line.fg and #line.fg == #line.bg then
					line.str = line.str:sub (1 , width )
					line.fg = line.fg:sub ( 1, width * 6 )
					line.bg = line.bg:sub ( 1, width * 6 )
					display[ number ] = line
					ok =screen.native.blit( line.str, line.fg, line.bg, fast )
					updateCursorPos()
					return ok
				end
			end
			return false
		end	

		local function redraw ()
			for h = 1, height do
				local ok = redrawLine ( h )
				if not ok then return false end
			end
			return true
		end

		local function updateCursorBlink ()
	        return parent.setCursorBlink ( cursorBlink )
	    end

	    local function updateCursorColor ()
	    	return window.setFgColor ( fgColor )
	    end
		function window.addChild ( t )
			if type ( t ) == 'table' then
				window.childcount = window.childcount + 1
				table.insert ( window.child, window.childcount, t )
				return window.childcount
			end
			return false
		end

		function window.blit ( text, color, background, fast )
			local l_start = cursorX
			local l_end = cursorX + #text
			if cursorY >= 1 and cursorY <= height and cursorX > -#text and cursorX <= width then
				local line = display[ cursorY ]
				if line then
					if l_start == 1 and l_end - 1 == width then
						line.str = text
						line.fg = color
						line.bg = background
					elseif l_end - 1 > width then
						line.str = line.str:sub ( 1, l_start - 1 ) .. text:sub ( 1, width - l_start + 1 )
						line.fg = line.fg:sub ( 1, ( l_start - 1 ) * 6 ) .. color:sub ( 1, ( width - l_start + 1 ) * 6 )
						line.bg = line.bg:sub ( 1, ( l_start - 1 ) * 6 ) .. background:sub ( 1 , ( width - l_start + 1 ) * 6 )
					elseif l_start < 1 then
						line.str = text:sub ( - ( #text - l_start ), #text ) .. line.str:sub ( l_end + 1, width )
						line.fg = color:sub ( - ( #color - l_start ), #color ) .. line.fg:sub ( l_end + 1, width * 6 )
						line.bg = background:sub ( - ( #text - l_start ), #background ) .. line.bg:sub ( l_end + 1, width * 6 )
					else
						line.str = line.str:sub ( 1, l_start - 1 ) .. text .. line.str:sub ( l_end, width )
						line.fg = line.fg:sub (1, ( l_start - 1 ) * 6 ) .. color .. line.fg:sub ( ( l_end - 1 ) * 6 + 1, width * 6 )
						line.bg = line.bg:sub (1, ( l_start - 1) * 6 ) .. background .. line.bg:sub ( ( l_end - 1 ) * 6 + 1, width * 6 )
					end
					display [ cursorY ] = line
					redrawLine ( cursorY, fast )
					cursorX = cursorX + #text
					updateCursorColor ()
					updateCursorPos ()
					return text, color, background
				end
			end
			return false
		end

		function window.setBgColor ( color )
			if type ( color ) == 'number' then
				bgColor = color
				return true
			end
			return false
		end
		
		function window.getBgColor ()
			return tohex ( bgColor )
		end

		function window.setFgColor ( color )
			if type ( color ) == 'number' then
				fgColor = color
				return true
			end
			return false
		end

		function window.getFgColor()
			return tohex ( fgColor )
		end

		function window.setCursor ( new_x, new_y )
			if type( new_x ) == 'number' and type( new_y ) == 'number' then
				cursorX = math.floor ( new_x )
				cursorY = math.floor ( new_y )
				if visible then
					updateCursorPos ()
				end
				return true
			end
			return false
		end
		
		function window.getCursor ()
			return cursorX, cursorY
		end

		function window.setPosition ( new_x, new_y )
			if type( new_x ) == 'number' and type( new_y ) == 'number' then
				if not ( new_x == x ) or not ( new_y == y ) then
					x = math.floor ( new_x )
					y = math.floor ( new_y )
					updateCursorPos ()
					parent.redraw ()
					window.redraw ()
				end
				return true
			end
			return false
		end
		
		function window.getPosition ()
			return x, y
		end

		function window.setResolution ( new_x, new_y )
			if type( new_x ) == 'number' and type( new_y ) == 'number' then
				width = math.floor ( new_x )
				height = math.floor ( new_x )
				updateCursorPos ()
				window.redraw ()
				return true
			end
			return false
		end
		
		function window.destroy()
			for k, v in pairs( window.child ) do
				v.destroy()
			end
			table.remove ( parent.child, id )
			parent.redraw ()
			window = nil
			return true
		end
		
		function window.getResolution ()
			return width, height
		end
		
		function window.isColor ()
			return hasColors
		end

		function window.isVisible ()
			return visible
		end

		function window.current ()
			return window
		end

		function window.setCursorBlink ( bool )
			if type ( bool ) == "boolean" then
	     	   cursorBlink = bool
	     	   updateCursorBlink ()
			   return true
	   		end
			return false
	    end

		function window.clearLine ( number , bg )
			local fg = fgColor
			local bg = bg or bgColor
			window.setFgColor ( fg )
			window.setBgColor ( bg )
			local number = number or cursorY
			if ( number >= 1 ) and ( number <= height ) then
				display[ number ] = {
					str = string.rep( " ", width ),
					fg = string.rep( tohex ( fg ), width ),
					bg = string.rep ( tohex ( bg ), width ) }
				redrawLine ( number )
				return true
			end
			return false
		end
		
		function window.clear ( color )
			for line = 1, height do
				window.clearLine ( line, color )
			end
			return true
		end

		function window.redraw ()
			redraw()
			for k,v in pairs( window.child ) do
				if v.redraw then
					v.redraw()
				end
			end
			return true
		end

		function window.write ( text, color, background )
			local text = tostring( text ) or ""
			local fg =  color or fgColor 
			local bg = color or bgColor 
			window.setFgColor ( fg )
			window.setBgColor ( bg )
			window.blit ( text, string.rep ( tohex ( fg ), #text ), string.rep ( tohex ( bg ), #text ) )
		end

		function window.scroll ( lines )
			if type(lines) == "number" then
				if lines >= 1 and lines < height then
					for i = 1, height do
						if display[ lines + i ] then
							display[ i ] = display[ lines + i ]
						elseif ( i <= height + 1 ) then
							window.clearLine ( i )
						end
					end
				else
					window.clear ()
				end
				window.redraw ()
				updateCursorColor ()
				updateCursorPos ()
				return true
			end
			return false
		end

		function window.restoreCursor ()
			updateCursorBlink ()
			updateCursorPos ()
			updateCursorColor ()
			return true
		end

		function window.setVisible ( bool )
			if visible ~= bool then
				visible = bool
				if visible then
					window.redraw ()
				end
			end
		end
		
		function window.getDisplay()
			return display
		end
		
		return window
	end
end

return screen