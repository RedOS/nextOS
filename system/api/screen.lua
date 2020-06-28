local component = require( 'component' )
local unicode = require( "unicode" )

local function tohex( str )
	local str = tostring( str )
	local r = ( '%06X' ):format ( str )
	return r
end

function string.insert ( str_original, str_inserted, position, limit )
	local part_a, part_b = unicode.sub( str_original, 0, position - 1 ), unicode.sub( str_original, position + unicode.len( str_inserted ), limit or nil )
	return unicode.sub ( part_a .. str_inserted .. part_b, 1, limit or nil )
end

function unpack (tab, i)
	i = i or 1
	if tab[i] ~= nil then
		return t[i], unpack(tab, i + 1)
	end
end

local screen = { gpu = component.gpu }

screen.resolution = function()
	return screen.gpu.getResolution()
end

screen.maxWidth = function()
	return ( { screen.resolution() } )[1]
end

screen.maxHeight = function()
	return ( { screen.resolution() } )[2]
end

screen.create = function ( parent, _x, _y, _width, _height )
	if not ( parent or not screen.native ) or not _x or not _y or not _width or not _height then error("Missing arg(s)") else
		local window = { child = {}, childcount = 0, frame = {}, x = _x, y = _y, cursor = { x = 1, y = 1, blink = true }, title = "",
		width = _width, height = _height, BG = 0x000000, FG = 0xFFFFFF, hasColors = ( parent and parent.hasColors or ( component.gpu.getDepth() > 1 and true or false ) ),
		visible = true, id = ( parent and parent.addChild ( window ) or 1 ), native = ( parent and false or true ) }
		for h = 1, window.height do
			window.frame [ h ] = {
			str = string.rep ( ' ', window.width ),
			fg = string.rep ( tohex ( window.FG ), window.width ),
			bg = string.rep ( tohex ( window.BG ), window.width ) }
		end

		local function updateCursorPos ()
			if not window.native then
				local parent_x, parent_y = parent.getPosition ()
				parent.setCursor ( parent_x - 1 + window.x - 1 + window.cursor.x, parent_y - 1 + window.y - 1 + window.cursor.y )
			end
			return true
    	end
		
		local function updateCursorBlink () return ( not window.native and parent.setCursorBlink ( window.cursor.blink ) or window.cursor.blink ) end

		local function updateCursorColor () return ( not window.native and parent.setFG ( window.FG ) or window.FG ) end
		
		function window.addChild ( t )
			if type ( t ) == 'table' then
				window.childcount = window.childcount + 1
				table.insert ( window.child, window.childcount, t )
				return window.childcount
			end
			return false
		end

		local function redrawLine ( h )
			if window.frame[ h ] then
				local line = window.frame[ h ]
				if 6 * unicode.len( line.str ) == unicode.len( line.fg ) and unicode.len( line.fg ) == unicode.len( line.bg ) and unicode.len( line.str ) == window.width then
					line.str = unicode.sub ( line.str, 1 , window.width )
					line.fg = line.fg:sub ( 1, window.width * 6 )
					line.bg = line.bg:sub ( 1, window.width * 6 )
					window.setCursor( 1, h )
					local ok = window.blit( line.str, line.fg, line.bg)
					updateCursorPos()
					return ok
				end
			end
			return false
		end	

		local function redraw ()
			for h = 1, window.height do
				local ok = redrawLine ( h )
				if not ok then return false end
			end
			return true
		end
		
		function window.blit ( _str, _fg, _bg, forced )
			if not window.frame [ window.cursor.y ] then return false end
			local old_bg, old_fg = screen.gpu.getBackground (), screen.gpu.getForeground ()
			local old_line, new_line, diff, line = window.frame [ window.cursor.y ], { str = _str, fg = _fg, bg = _bg }, string.rep ( forced and "1" or "0" , unicode.len( _str ) ), {}
			line.str = string.insert ( old_line.str, new_line.str, window.cursor.x , window.width )
			line.fg = string.insert ( old_line.fg, new_line.fg, 6 * ( window.cursor.x - 1 ) + 1, 6 * window.width )
			line.bg = string.insert ( old_line.bg, new_line.bg, 6 * ( window.cursor.x - 1 ) + 1, 6 * window.width )
			if window.visible then
				if not window.native then
					parent.setCursor ( window.x + window.cursor.x - 1 , window.y + window.cursor.y - 1 )
					local ok = parent.blit ( unpack ( new_line ) )
				else
					local _ind = { "fg", "bg" }
					if not forced then
						for k, v in pairs(_ind) do
							for ch = 1, #diff do
								diff = string.insert( diff, ( diff:sub( ch, ch ) == "0" and ( unicode.sub( new_line[v], ch, ch + 5 ) == unicode.sub( old_line[v], ch + window.cursor.x - 1, ch + window.cursor.x + 5 ) and "0" or "1" ) or "1" ), ch )
							end
						end
					end
					if ( window.cursor.y <= screen.maxHeight() ) and ( window.cursor.y > 0 ) and ( window.cursor.y  <= window.height ) then
						local n = 1
						while n <= #diff do
							local ch = diff:find( "1", n ) or #diff
							local fg_color, bg_color = new_line.fg:sub( 6 * ( n - 1 ) + 1, n * 6 ), new_line.bg:sub( ( n - 1 ) * 6 + 1, n * 6 )
							screen.gpu.setForeground( tonumber ( fg_color, 16 ) )
							screen.gpu.setBackground( tonumber ( bg_color, 16 ) )
							local ok = screen.gpu.set ( window.x + window.cursor.x - 1 + n - 1, window.y + window.cursor.y - 1, unicode.sub( new_line.str, n, ch - ( ch == n and 0 or 1 ) ) )
							n = math.min( ch + ( ch == n and 1 or 0 ), #diff + 1 )
						end
						screen.gpu.setBackground( old_bg )
						screen.gpu.setForeground( old_fg )
					end
				end
			end
			window.frame[ window.cursor.y ] = line
			window.setCursor( window.cursor.x + unicode.len( new_line.str ), window.cursor.y )
			return ok or false
		end
		
		function window.insertBuffer ( x_pos, y_pos, data )
			if type( y_pos ) == "number" and type( x_pos ) == "number" and type( data ) == "table" then
				if window.frame[ y_pos ] then
					window.setCursor ( x_pos, y_pos )
					window.blit ( data.str, data.fg, data.bg )
					return true
				end
				return false
			end
			return false
		end

		function window.setBG ( color )
			if type ( color ) == 'number' then
				window.BG = color
				return true
			end
			return false
		end
		
		function window.setFG ( color )
			if type ( color ) == 'number' then
				window.FG = color
				return true
			end
			return false
		end

		function window.setCursor ( new_x, new_y )
			if type( new_x ) == 'number' and type( new_y ) == 'number' then
				window.cursor.x = math.floor ( new_x )
				window.cursor.y = math.floor ( new_y )
				if window.visible then
					updateCursorPos ()
				end
				return true
			end
			return false
		end
		
		function window.setCursorBlink ( bool )
			if type ( bool ) == "boolean" then
			   window.cursor.blink = bool
			   updateCursorBlink ()
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

		function window.setPosition ( new_x, new_y )
			if type( new_x ) == 'number' and type( new_y ) == 'number' then
				if not ( new_x == x ) or not ( new_y == y ) then
					window.x = math.floor ( new_x )
					window.y = math.floor ( new_y )
					updateCursorPos ()
					if not window.native then parent.redraw () end
					window.render ()
				end
				return true
			end
			return false
		end

		function window.setResolution ( new_x, new_y )
			if type( new_x ) == 'number' and type( new_y ) == 'number' then
				window.width = math.floor ( new_x )
				window.height = math.floor ( new_x )
				updateCursorPos ()
				window.render ()
				return true
			end
			return false
		end

		function window.setVisible ( bool )
			if type ( bool ) == "boolean" then
				if bool then
					window.visible = bool
					window.render ()
					return true
				end
			end
			return false
		end
		
		function window.setTitle ( title )
			window.title = tostring ( title )
			return true
		end
		
		function window.destroy()
			if not window.native then
				for k, v in pairs( window.child ) do
					v.destroy()
				end
				table.remove ( parent.child, window.id )
				window = nil
				return true
			end
			return false
		end

		function window.current ()
			return window
		end

		function window.clearLine ( h , bg )
			window.setBG ( bg or window.BG )
			local h = h or window.cursor.y
			if ( h >= 1 ) and ( h <= window.height ) then
				window.setCursor( 1, h )
				local line = { str = string.rep( " ", window.width ), fg = string.rep( tohex ( window.FG ), window.width ), bg = string.rep ( tohex ( window.BG ), window.width ) }
				window.blit( line.str, line.fg, line.bg )
				return true
			end
			return false
		end
		
		function window.clear ( color )
			for line = 1, window.height do
				window.clearLine ( line, color )
			end
			return true
		end

		function window.render ( forced )
			redraw( forced )
			for k,v in pairs( window.child ) do
				if v.redraw then
					v.redraw( forced )
				end
			end
			return true
		end

		function window.write ( text, color, background )
			window.setFgColor ( color or window.FG )
			window.setBgColor ( background or window.BG )
			window.blit ( tostring( text ), string.rep ( tohex ( window.FG ), #text ), string.rep ( tohex ( window.BG ), #text ) )
			return tostring( text ), true
		end

		function window.scroll ( lines )
			if type(lines) == "number" then
				if lines >= 1 and lines < window.height then
					for i = 1, window.height do
						if window.frame[ lines + i ] then
							window.frame[ i ] = window.frame[ lines + i ]
						elseif ( i <= window.height + 1 ) then
							window.clearLine ( i )
						end
					end
				else
					window.clear ()
				end
				window.render ()
				updateCursorColor ()
				updateCursorPos ()
				return true
			end
			return false
		end
		
		function window.getFG () return tohex ( window.FG ) end

		function window.getBG () return tohex ( window.BG ) end

		function window.getCursor () return window.cursor.x, window.cursor.y end
		
		function window.getCursorBlink () return window.cursor.blink end

		function window.getPosition () return window.x, window.y end

		function window.getResolution () return window.width, window.height end
		
		function window.getTitle () return window.title end

		function window.isColor () return window.hasColors end

		function window.isVisible () return window.visible end
		
		function window.getID () return window.id end
		
		function window.getFrame ( line ) return window.frame end
		
		return window
	end
end

screen.native = screen.create ( nil, 1, 1, 40, 40 )

return screen