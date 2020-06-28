local elements = {}
local unicode = require( "unicode" )

local function tohex( str )
	return ( '%06X' ):format ( tostring( str ) )
end

local function wrap(str, limit)
	local function splitWords(Lines, limit)
		while #Lines[#Lines] > limit do
			Lines[#Lines+1] = Lines[#Lines]:sub(limit+1)
			Lines[#Lines-1] = Lines[#Lines-1]:sub(1,limit)
		end
	end
	
    local Lines, here, limit, found = {}, 1, limit or 72, str:find("(%s+)()(%S+)()")
    if found then
        Lines[1] = string.sub(str,1,found-1)
    else Lines[1] = str end
    str:gsub("(%s+)()(%S+)()",
        function(sp, st, word, fi)
            splitWords(Lines, limit)
            if fi-here > limit then
                here = st
                Lines[#Lines+1] = word
            else Lines[#Lines] = Lines[#Lines].." "..word end
        end)
    splitWords(Lines, limit)

    return Lines
end

elements.create = function ( window, _type, _x, _y )
	local element = { type = _type, x = _x or 1, y = _y or 1, parent = window, callback = nil, style = { position = "left", offset = 1, BG =0x000000, FG =0xFFFFFF } }
	
	function element.setBG ( bgr )
		if type( bgr ) == "number" then
			element.style.BG = bgr
			return true
		end
		return false
	end
	
	function element.setFG ( fgr )
		if type( fgr ) == "number" then
			element.style.FG = fgr
			return true
		end
		return false
	end
		
	function element.setPos ( x, y )
		if type( x ) == "number" then
			element.x = math.floor ( x )
		end
		if type( y ) == "number" then
			element.y = math.floor ( y )
		end
	end
	
	function element.setCallback ( func )
		if type( func ) == "function" then
			element.callback = func
			return true
		end
		return false
	end
	
	function element.setPosition ( pos )
		if pos == "left" or pos == "center" or pos == "right" then
			element.style.position = pos
			return true
		end
		return false
	end
	
	function element.setOffset ( offset )
		if type( offset ) == "number" then
			element.style.offset = math.floor( offset )
			return true
		end
		return false
	end
	
	function element.resetCallback () element.callback = nil return true end
	
	function element.getType () return element.type end
		
	function element.getPos () return element.x, element.y end
		
	function element.getCallback () return element.callback or false end
	
	function element.getPosition () return element.style.position or false end
	
	function element.getFG () return element.style.FG or false end
	
	function element.getBG () return element.style.BG or false end
	
	function element.getOffset () return element.style.offset or false end
	
	if element.type == "radio" then
		local size, maxlength = 0, 0
		element.label, element.active, element.symbols, element.selected  = {}, { BG =0xFFFFFF, FG =0x000000}, { active = "● ", inactive = "○ "}, 1
		
		function element.setSize ( num )
			if type( num ) == "number" then
				if size > num then
					for i = ( num + 1), size do
						element.label[ i ] = nil
					end
				end
				size = num
				return true
			end
			return false
		end
		
		function element.setLabels ( ... )
			maxlength = 0
			local arguments = {...}
			for i = 1, size do
				element.label[ i ] = arguments[ i ] or ""
				maxlength = math.max( maxlength, unicode.len( element.label[ i ] ) )
			end
			return true
		end
		
		function element.setFG_active ( afg )
			if type( abg ) == "number" then
				element.active.FG = afg
				return true
			end
			return false
		end
				
		function element.setBG_active ( abg )
			if type( abg ) == "number" then
				element.active.BG = abg
				return true
			end
			return false
		end
		
		function element.setSymbols ( active, inactive )
			if type( active ) == "string" and type( inactive ) == "string" then
				element.symbols.active, element.symbols.inactive = active, inactive
			end
			return false
		end
		
		function element.setSelected ( num )
			if type( num ) == "number" and num <= size then
				element.selected = num
				return true
			end
			return false
		end
		
		function element.render ()
			for i = 1, size do
				local line = { str = "", fg ="", bg =""}
				local is_checked = ( element.selected == i and true or false )
				if element.style.position == "left" then
					line.str = string.rep( " ", element.style.offset ) .. ( is_checked and element.symbols.active or element.symbols.inactive ) .. element.label[ i ] .. string.rep( " ", maxlength - unicode.len( element.label[ i ] ) + element.style.offset )
					line.fg = string.rep( tohex( element.style.FG ), element.style.offset ) .. string.rep( tohex( is_checked and element.active.FG or element.style.FG), maxlength + unicode.len( ( is_checked and element.symbols.active or element.symbols.inactive ) ) ) .. string.rep( tohex( element.style.FG ), element.style.offset )
					line.bg = string.rep( tohex( element.style.BG ), element.style.offset ) .. string.rep( tohex( is_checked and element.active.BG or element.style.BG), maxlength + unicode.len( ( is_checked and element.symbols.active or element.symbols.inactive ) ) ) .. string.rep( tohex( element.style.BG ), element.style.offset )
					element.parent.insertBuffer( element.x, element.y + i - 1 , line )
				elseif element.style.position == "right" then
					line.str = string.rep( " ", maxlength - unicode.len( element.label[ i ] ) + element.style.offset ) .. element.label[ i ] .. ( is_checked and element.symbols.active or element.symbols.inactive ) .. string.rep( " ", element.style.offset )
					line.fg = string.rep( tohex( element.style.FG ), element.style.offset ) .. string.rep( tohex( is_checked and element.active.FG or element.style.FG), maxlength + unicode.len( ( is_checked and element.symbols.active or element.symbols.inactive ) ) ) .. string.rep( tohex( element.style.FG ), element.style.offset )
					line.bg = string.rep( tohex( element.style.BG ), element.style.offset ) .. string.rep( tohex( is_checked and element.active.BG or element.style.BG), maxlength + unicode.len( ( is_checked and element.symbols.active or element.symbols.inactive ) ) ) .. string.rep( tohex( element.style.BG ), element.style.offset )
					element.parent.insertBuffer( element.x, element.y + i - 1 , line )
				elseif element.style.position == "center" then
					line.str = string.rep( " ", math.floor( ( maxlength - unicode.len( element.label[ i ] ) ) /2 ) + element.style.offset ) .. ( is_checked and element.symbols.active or element.symbols.inactive ) .. element.label[ i ] .. string.rep( " ", math.floor( ( maxlength - unicode.len( element.label[ i ] ) ) /2 ) + element.style.offset )
					line.fg = string.rep( tohex( element.style.FG ), element.style.offset ) .. string.rep( tohex( is_checked and element.active.FG or element.style.FG), maxlength + unicode.len( ( is_checked and element.symbols.active or element.symbols.inactive ) ) ) .. string.rep( tohex( element.style.FG ), element.style.offset )
					line.bg = string.rep( tohex( element.style.BG ), element.style.offset ) .. string.rep( tohex( is_checked and element.active.BG or element.style.BG), maxlength + unicode.len( ( is_checked and element.symbols.active or element.symbols.inactive ) ) ) .. string.rep( tohex( element.style.BG ), element.style.offset )
					element.parent.insertBuffer( element.x, element.y + i - 1 , line )
				end
			end
			return true
		end
		
		function element.getSize () return size or false end
		
		function element.getLabels () return element.label or false end
		
		function element.getFG_active () return element.active.FG or false end
		
		function element.getBG_active () return element.active.BG or false end
		
		function element.getSymbols () return element.symbols or false end
		
		function element.getSelected () return element.selected or false end
	
	elseif element.type == "bool" then
		local length  = 0
		element.label, element.state, element.active, element.symbols = "", false, { BG =0xFFFFFF, FG =0x000000 }, { active = "● ", inactive = "○ " }
		
		function element.setLabel ( str )
			if type( str ) == "string" then
				element.label = str or ""
				length = unicode.len( element.label )
				return true
			end
			return false
		end
		
		function element.setFG_active ( afg )
			if type( abg ) == "number" then
				element.active.FG = afg
				return true
			end
			return false
		end
				
		function element.setBG_active ( abg )
			if type( abg ) == "number" then
				element.active.BG = abg
				return true
			end
			return false
		end
		
		function element.setSymbols ( active, inactive )
			if type( active ) == "string" and type( inactive ) == "string" then
				element.symbols.active, element.symbols.inactive = active, inactive
			end
			return false
		end
		
		function element.setState ( bool )
			if type( bool ) == "boolean" then
				element.state = bool
				return true
			end
			return false
		end
		
		function element.render ()
			local line = { str = "", fg ="", bg =""}
			if element.style.position == "left" then
				line.str = string.rep( " ", element.style.offset ) .. ( element.state and element.symbols.active or element.symbols.inactive ) .. element.label .. string.rep( " ", length - unicode.len( element.label ) + element.style.offset )
				line.fg = string.rep( tohex( element.style.FG ), element.style.offset ) .. string.rep( tohex( element.state and element.active.FG or element.style.FG), length + unicode.len( ( element.state and element.symbols.active or element.symbols.inactive ) ) ) .. string.rep( tohex( element.style.FG ), element.style.offset )
				line.bg = string.rep( tohex( element.style.BG ), element.style.offset ) .. string.rep( tohex( element.state and element.active.BG or element.style.BG), length + unicode.len( ( element.state and element.symbols.active or element.symbols.inactive ) ) ) .. string.rep( tohex( element.style.BG ), element.style.offset )
				element.parent.insertBuffer( element.x, element.y , line )
			elseif element.style.position == "right" then
				line.str = string.rep( " ", length - unicode.len( element.label ) + element.style.offset ) .. element.label .. ( element.state and element.symbols.active or element.symbols.inactive ) .. string.rep( " ", element.style.offset )
				line.fg = string.rep( tohex( element.style.FG ), element.style.offset ) .. string.rep( tohex( element.state and element.active.FG or element.style.FG), length + unicode.len( ( element.state and element.symbols.active or element.symbols.inactive ) ) ) .. string.rep( tohex( element.style.FG ), element.style.offset )
				line.bg = string.rep( tohex( element.style.BG ), element.style.offset ) .. string.rep( tohex( element.state and element.active.BG or element.style.BG), length + unicode.len( ( element.state and element.symbols.active or element.symbols.inactive ) ) ) .. string.rep( tohex( element.style.BG ), element.style.offset )
				element.parent.insertBuffer( element.x, element.y , line )
			elseif element.style.position == "center" then
				line.str = string.rep( " ", math.floor( ( length - unicode.len( element.label ) ) /2 ) + element.style.offset ) .. ( element.state and element.symbols.active or element.symbols.inactive ) .. element.label .. string.rep( " ", math.floor( ( length - unicode.len( element.label ) ) /2 ) + element.style.offset )
				line.fg = string.rep( tohex( element.style.FG ), element.style.offset ) .. string.rep( tohex( element.state and element.active.FG or element.style.FG), length + unicode.len( ( element.state and element.symbols.active or element.symbols.inactive ) ) ) .. string.rep( tohex( element.style.FG ), element.style.offset )
				line.bg = string.rep( tohex( element.style.BG ), element.style.offset ) .. string.rep( tohex( element.state and element.active.BG or element.style.BG), length + unicode.len( ( element.state and element.symbols.active or element.symbols.inactive ) ) ) .. string.rep( tohex( element.style.BG ), element.style.offset )
				element.parent.insertBuffer( element.x, element.y , line )
			end
			return true
		end
		
		function element.getLabel () return element.label or false end
		
		function element.getFG_active () return element.active.FG or false end
		
		function element.getBG_active () return element.active.BG or false end
		
		function element.getSymbols () return element.symbols or false end
		
		function element.getState () return element.state or nil end
	
	elseif element.type == "check" then
		local size, maxlength = 0, 0
		element.label, element.active, element.symbols, element.checked  = {}, { BG =0xFFFFFF, FG =0x000000}, { active = "▣ ", inactive = "□ "}, {}
		 
		function element.setSize ( num )
			if type( num ) == "number" then
				if size > num then
					for i = ( num + 1), size do
						element.label[ i ] = nil
					end
				end
				size = num
				return true
			end
			return false
		end
		
		function element.setLabels ( ... )
			maxlength = 0
			local arguments = {...}
			for i = 1, size do
				element.label[ i ] = arguments[ i ] or ""
				maxlength = math.max( maxlength, unicode.len( element.label[ i ] ) )
			end
			return true
		end
		
		function element.setFG_active ( afg )
			if type( abg ) == "number" then
				element.active.FG = afg
				return true
			end
			return false
		end
				
		function element.setBG_active ( abg )
			if type( abg ) == "number" then
				element.active.BG = abg
				return true
			end
			return false
		end
		
		function element.setSymbols ( active, inactive )
			if type( active ) == "string" and type( inactive ) == "string" then
				element.symbols.active, element.symbols.inactive = active, inactive
			end
			return false
		end

		function element.setState ( num, bool )
			if type( num ) == "number" and num <= size and type( bool ) == "boolean" then
				element.checked[ num ] = bool
				return true
			end
			return false
		end

		function element.render ()
			for i = 1, size do
				local line = { str = "", fg ="", bg =""}
				local is_checked = ( element.checked[ i ] and true or false )
				if element.style.position == "left" then
					line.str = string.rep( " ", element.style.offset ) .. ( is_checked and element.symbols.active or element.symbols.inactive ) .. element.label[ i ] .. string.rep( " ", maxlength - unicode.len( element.label[ i ] ) + element.style.offset )
					line.fg = string.rep( tohex( element.style.FG ), element.style.offset ) .. string.rep( tohex( is_checked and element.active.FG or element.style.FG), maxlength + unicode.len( ( is_checked and element.symbols.active or element.symbols.inactive ) ) ) .. string.rep( tohex( element.style.FG ), element.style.offset )
					line.bg = string.rep( tohex( element.style.BG ), element.style.offset ) .. string.rep( tohex( is_checked and element.active.BG or element.style.BG), maxlength + unicode.len( ( is_checked and element.symbols.active or element.symbols.inactive ) ) ) .. string.rep( tohex( element.style.BG ), element.style.offset )
					element.parent.insertBuffer( element.x, element.y + i - 1 , line )
				elseif element.style.position == "right" then
					line.str = string.rep( " ", maxlength - unicode.len( element.label[ i ] ) + element.style.offset ) .. element.label[ i ] .. ( is_checked and element.symbols.active or element.symbols.inactive ) .. string.rep( " ", element.style.offset )
					line.fg = string.rep( tohex( element.style.FG ), element.style.offset ) .. string.rep( tohex( is_checked and element.active.FG or element.style.FG), maxlength + unicode.len( ( is_checked and element.symbols.active or element.symbols.inactive ) ) ) .. string.rep( tohex( element.style.FG ), element.style.offset )
					line.bg = string.rep( tohex( element.style.BG ), element.style.offset ) .. string.rep( tohex( is_checked and element.active.BG or element.style.BG), maxlength + unicode.len( ( is_checked and element.symbols.active or element.symbols.inactive ) ) ) .. string.rep( tohex( element.style.BG ), element.style.offset )
					element.parent.insertBuffer( element.x, element.y + i - 1 , line )
				elseif element.style.position == "center" then
					line.str = string.rep( " ", math.floor( ( maxlength - unicode.len( element.label[ i ] ) ) /2 ) + element.style.offset ) .. ( is_checked and element.symbols.active or element.symbols.inactive ) .. element.label[ i ] .. string.rep( " ", math.floor( ( maxlength - unicode.len( element.label[ i ] ) ) /2 ) + element.style.offset )
					line.fg = string.rep( tohex( element.style.FG ), element.style.offset ) .. string.rep( tohex( is_checked and element.active.FG or element.style.FG), maxlength + unicode.len( ( is_checked and element.symbols.active or element.symbols.inactive ) ) ) .. string.rep( tohex( element.style.FG ), element.style.offset )
					line.bg = string.rep( tohex( element.style.BG ), element.style.offset ) .. string.rep( tohex( is_checked and element.active.BG or element.style.BG), maxlength + unicode.len( ( is_checked and element.symbols.active or element.symbols.inactive ) ) ) .. string.rep( tohex( element.style.BG ), element.style.offset )
					element.parent.insertBuffer( element.x, element.y + i - 1 , line )
				end
			end
			return true
		end
		
		function element.getSize () return size or false end

		function element.getLabels () return element.label or false end

		function element.getFG_active () return element.active.FG or false end

		function element.getBG_active () return element.active.BG or false end

		function element.getSymbols () return element.symbols or false end

		function element.getState ( num ) return element.state[ num ] or nil end
	
	elseif element.type == "input" then
		local i_type, label, input, wrap = "normal", "", "", true
		
		function element.setInputType ( i_type )
			if i_type == "normal" or i_type == "password" or i_type == "number" then
			end
		end
	
	elseif element.type == "button" then
		local length  = 0
		element.label, element.state, element.active = "", false, { BG =0xFFFFFF, FG =0x000000 }
		
		function element.setLabel ( str )
			if type( str ) == "string" then
				element.label = str or ""
				length = unicode.len( element.label )
				return true
			end
			return false
		end
		
		function element.setFG_active ( afg )
			if type( abg ) == "number" then
				element.active.FG = afg
				return true
			end
			return false
		end
				
		function element.setBG_active ( abg )
			if type( abg ) == "number" then
				element.active.BG = abg
				return true
			end
			return false
		end
				
		function element.activate ()
			element.state = true
			element.render ()
			os.sleep ( 0.15 )
			element.state = false
			element.render ()
			return true
		end
		
		function element.render ()
			local line = { str = "", fg ="", bg =""}
			if element.style.position == "left" then
				line.str = string.rep( " ", element.style.offset ) .. element.label .. string.rep( " ", length - unicode.len( element.label ) + element.style.offset )
				line.fg = string.rep( tohex( element.style.FG ), element.style.offset ) .. string.rep( tohex( element.state and element.active.FG or element.style.FG), length ) .. string.rep( tohex( element.style.FG ), element.style.offset )
				line.bg = string.rep( tohex( element.style.BG ), element.style.offset ) .. string.rep( tohex( element.state and element.active.BG or element.style.BG), length ) .. string.rep( tohex( element.style.BG ), element.style.offset )
				element.parent.insertBuffer( element.x, element.y , line )
			elseif element.style.position == "right" then
				line.str = string.rep( " ", length - unicode.len( element.label ) + element.style.offset ) .. element.label .. ( element.state and element.symbols.active or element.symbols.inactive ) .. string.rep( " ", element.style.offset )
				line.fg = string.rep( tohex( element.style.FG ), element.style.offset ) .. string.rep( tohex( element.state and element.active.FG or element.style.FG), length ) .. string.rep( tohex( element.style.FG ), element.style.offset )
				line.bg = string.rep( tohex( element.style.BG ), element.style.offset ) .. string.rep( tohex( element.state and element.active.BG or element.style.BG), length ) .. string.rep( tohex( element.style.BG ), element.style.offset )
				element.parent.insertBuffer( element.x, element.y , line )
			elseif element.style.position == "center" then
				line.str = string.rep( " ", math.floor( ( length - unicode.len( element.label ) ) /2 ) + element.style.offset ) .. ( element.state and element.symbols.active or element.symbols.inactive ) .. element.label .. string.rep( " ", math.floor( ( length - unicode.len( element.label ) ) /2 ) + element.style.offset )
				line.fg = string.rep( tohex( element.style.FG ), element.style.offset ) .. string.rep( tohex( element.state and element.active.FG or element.style.FG), length ) .. string.rep( tohex( element.style.FG ), element.style.offset )
				line.bg = string.rep( tohex( element.style.BG ), element.style.offset ) .. string.rep( tohex( element.state and element.active.BG or element.style.BG), length ) .. string.rep( tohex( element.style.BG ), element.style.offset )
				element.parent.insertBuffer( element.x, element.y , line )
			end
			return true
		end
		
		function element.getLabel () return element.label or false end
		
		function element.getFG_active () return element.active.FG or false end
		
		function element.getBG_active () return element.active.BG or false end
	
	elseif element.type == "h-slider" then
	
	elseif element.type == "v-slider" then
	
	elseif element.type == "label" then
		element.label, element.wrap, element.width, element.symbol = "", true, 0, ""
		
		function element.setLabel ( str )
			if type( str ) == "string" then
				element.label = str or ""
				length = unicode.len( element.label )
				return true
			end
			return false
		end
		
		function element.setWrap ( bool )
			if type( bool ) == "boolean" then
				element.wrap = bool
				return true
			end
			return false
		end
		
		function element.setWidth ( num )
			if type( num ) == "number" then
				element.width = math.floor( num )
				return true
			end
			return false
		end
		
		function element.setSymbol ( symbol )
			if type( symbol ) == "string" then
				element.symbol = symbol
				return true
			end
			return false
		end
		
		function element.render ()
			local wrapped_lines = wrap( element.label, element.width - 2 * element.style.offset )
			for i = 1, #wrapped_lines do
				local line = { str = "", fg ="", bg =""}
				if element.style.position == "left" then
					line.str = string.rep( " ", element.style.offset ) .. element.symbol .. wrapped_lines[ i ] .. string.rep( " ", element.width - unicode.len( wrapped_lines[ i ] ) + element.style.offset )
					line.fg = string.rep( tohex( element.style.FG ), element.style.offset ) .. string.rep( tohex( is_checked and element.active.FG or element.style.FG), element.width + unicode.len( element.symbol ) ) .. string.rep( tohex( element.style.FG ), element.style.offset )
					line.bg = string.rep( tohex( element.style.BG ), element.style.offset ) .. string.rep( tohex( is_checked and element.active.BG or element.style.BG), element.width + unicode.len( element.symbol ) ) .. string.rep( tohex( element.style.BG ), element.style.offset )
					element.parent.insertBuffer( element.x, element.y + i - 1 , line )
				elseif element.style.position == "right" then
					line.str = string.rep( " ", element.width - unicode.len( wrapped_lines[ i ] ) + element.style.offset ) .. wrapped_lines[ i ] .. element.symbol .. string.rep( " ", element.style.offset )
					line.fg = string.rep( tohex( element.style.FG ), element.style.offset ) .. string.rep( tohex( is_checked and element.active.FG or element.style.FG), element.width + unicode.len( element.symbol ) ) .. string.rep( tohex( element.style.FG ), element.style.offset )
					line.bg = string.rep( tohex( element.style.BG ), element.style.offset ) .. string.rep( tohex( is_checked and element.active.BG or element.style.BG), element.width + unicode.len( element.symbol ) ) .. string.rep( tohex( element.style.BG ), element.style.offset )
					element.parent.insertBuffer( element.x, element.y + i - 1 , line )
				elseif element.style.position == "center" then
					line.str = string.rep( " ", math.floor( ( element.width - unicode.len( wrapped_lines[ i ] ) ) /2 ) + element.style.offset ) .. element.symbol .. wrapped_lines[ i ] .. string.rep( " ", math.floor( ( element.width - unicode.len( wrapped_lines[ i ] ) ) /2 ) + element.style.offset )
					line.fg = string.rep( tohex( element.style.FG ), element.style.offset ) .. string.rep( tohex( is_checked and element.active.FG or element.style.FG), element.width + unicode.len( element.symbol ) ) .. string.rep( tohex( element.style.FG ), element.style.offset )
					line.bg = string.rep( tohex( element.style.BG ), element.style.offset ) .. string.rep( tohex( is_checked and element.active.BG or element.style.BG), element.width + unicode.len( element.symbol ) ) .. string.rep( tohex( element.style.BG ), element.style.offset )
					element.parent.insertBuffer( element.x, element.y + i - 1 , line )
				end
			end
			return true
		end
		
		function element.getLabel () return element.label or false end
		
		function element.getFG_active () return element.active.FG or false end
		
		function element.getBG_active () return element.active.BG or false end
		
		function element.getWrap () return element.wrap or nil end
		
		function element.getWidth () return element.width or nil end
		
		function element.getSymbol () return element.symbol or false end
	
	elseif element.type == "list" then
		local size, maxlength = 1, 0
		element.label, element.indent = {}, "● "
		
		function element.setSize ( num )
			if type( num ) == "number" then
				if size > num then
					for i = ( num + 1), size do
						element.label[ i ] = nil
					end
				end
				size = num
				return true
			end
			return false
		end
		
		function element.setLabels ( ... )
			maxlength = 0
			local arguments = {...}
			for i = 1, size do
				element.label[ i ] = arguments[ i ] or ""
				maxlength = math.max( maxlength, unicode.len( element.label[ i ] ) )
			end
			return true
		end
		
		function element.setIndent ( indent )
			if type ( indent ) == "string" then
				element.indent = indent
			end
			return false
		end

		function element.render ()
			for i = 1, size do
				local line = { str = "", fg ="", bg =""}
				if element.style.position == "left" then
					line.str = string.rep( " ", element.style.offset ) .. element.indent .. element.label[ i ] .. string.rep( " ", maxlength - unicode.len( element.label[ i ] ) + element.style.offset )
					line.fg = string.rep( tohex( element.style.FG ), element.style.offset ) .. string.rep( tohex( element.indent ), maxlength + unicode.len( element.indent ) ) .. string.rep( tohex( element.style.FG ), element.style.offset )
					line.bg = string.rep( tohex( element.style.BG ), element.style.offset ) .. string.rep( tohex( element.indent ), maxlength + unicode.len( element.indent ) ) .. string.rep( tohex( element.style.BG ), element.style.offset )
					element.parent.insertBuffer( element.x, element.y + i - 1 , line )
				elseif element.style.position == "right" then
					line.str = string.rep( " ", maxlength - unicode.len( element.label[ i ] ) + element.style.offset ) .. element.label[ i ] .. element.indent .. string.rep( " ", element.style.offset )
					line.fg = string.rep( tohex( element.style.FG ), element.style.offset ) .. string.rep( tohex( element.indent ), maxlength + unicode.len( element.indent ) ) .. string.rep( tohex( element.style.FG ), element.style.offset )
					line.bg = string.rep( tohex( element.style.BG ), element.style.offset ) .. string.rep( tohex( element.indent ), maxlength + unicode.len( element.indent ) ) .. string.rep( tohex( element.style.BG ), element.style.offset )
					element.parent.insertBuffer( element.x, element.y + i - 1 , line )
				elseif element.style.position == "center" then
					line.str = string.rep( " ", math.floor( ( maxlength - unicode.len( element.label[ i ] ) ) /2 ) + element.style.offset ) .. element.indent .. element.label[ i ] .. string.rep( " ", math.floor( ( maxlength - unicode.len( element.label[ i ] ) ) /2 ) + element.style.offset )
					line.fg = string.rep( tohex( element.style.FG ), element.style.offset ) .. string.rep( tohex( element.indent ), maxlength + unicode.len( element.indent ) ) .. string.rep( tohex( element.style.FG ), element.style.offset )
					line.bg = string.rep( tohex( element.style.BG ), element.style.offset ) .. string.rep( tohex( element.indent ), maxlength + unicode.len( element.indent ) ) .. string.rep( tohex( element.style.BG ), element.style.offset )
					element.parent.insertBuffer( element.x, element.y + i - 1 , line )
				end
			end
			return true
		end
		
		function element.getSize () return size or false end

		function element.getLabels () return element.label or false end

		function element.getIndent () return element.symbols or false end

	elseif element.type == "bar" then

	elseif element.type == "loader" then
		element.label, element.progress, element.width, element.active, element.halves  = "", 0, 0, { BG =0xFFFFFF, FG =0x66FF66 }, { left = "▌", right = "▐"  }
		
		function element.setLabel ( str )
			if type( str ) == "string" then
				element.label = str or ""
				return true
			end
			return false
		end
		
		function element.setFG_active ( afg )
			if type( abg ) == "number" then
				element.active.FG = afg
				return true
			end
			return false
		end
				
		function element.setBG_active ( abg )
			if type( abg ) == "number" then
				element.active.BG = abg
				return true
			end
			return false
		end
		
		function element.setWidth ( num )
			if type( num ) == "number" then
				element.width = math.floor( num )
				return true
			end
			return false
		end
		
		function element.setProgress ( num )
			if type( num ) == "number" then
				if num > 0 and num <= 1 then
					element.progress = num
					return true
				end
			end
			return false
		end
		
		function element.render ()
			local line = { str = "", fg ="", bg =""}
			local percentage = element.progress * element.width
			if element.style.position == "left" then
				line.str = string.rep ( " ", element.style.offset ) .. element.label .. string.rep ("█", math.ceil ( percentage ) - 1 ) .. ( ( percentage - math.floor ( percentage ) ) > 0.5 and element.halves.left or " " ) .. string.rep ( " ", element.width - math.ceil ( percentage ) ) .. string.rep ( " ", element.style.offset )
				line.fg = string.rep ( tohex( element.style.FG ), element.style.offset + unicode.len ( element.label ) ) .. string.rep( tohex ( element.active.FG ), element.width ) .. string.rep ( tohex ( element.style.FG ), element.style.offset )
				line.bg = string.rep ( tohex( element.style.BG ), element.style.offset + unicode.len ( element.label ) ) .. string.rep( tohex ( element.active.BG ), element.width ) .. string.rep ( tohex ( element.style.BG ), element.style.offset )
				element.parent.insertBuffer( element.x, element.y , line )
			elseif element.style.position == "right" then
				line.str = string.rep ( " ", element.style.offset ) .. ( ( percentage - math.ceil ( percentage ) ) > 0.5 and element.halves.right or " " ) .. string.rep ("█", math.ceil ( percentage ) - 1 ) .. element.label ..string.rep ( " ", element.style.offset )
				line.fg = string.rep ( tohex ( element.style.FG ), element.style.offset ) .. string.rep( tohex ( element.active.FG ), element.width ) .. string.rep ( tohex( element.style.FG ), element.style.offset + unicode.len ( element.label ) )
				line.fg = string.rep ( tohex ( element.style.BG ), element.style.offset ) .. string.rep( tohex ( element.active.BG ), element.width ) .. string.rep ( tohex( element.style.BG ), element.style.offset + unicode.len ( element.label ) )
				element.parent.insertBuffer( element.x, element.y , line )
			end
			return true
		end
		
		function element.getLabel () return element.label or false end
		
		function element.getFG_active () return element.active.FG or false end
		
		function element.getBG_active () return element.active.BG or false end
		
		function element.getWidth () return element.width or false end
		
		function element.getProgress () return element.progress or nil end

	elseif element.type == "scrollbar" then
		element.length, element.position, element.width, element.active, element.halves  = 0, 0, 0, { BG =0xFFFFFF, FG =0x66FF66 }, { upper = "▀", lower = "▄"  }
		
		

	elseif element.type == "vector-img" then

	elseif element.type == "pixel-img" then
		element.img, element.width, element.height = {}, 0, 0
		
		function element.setImage ( img )
			if type ( img ) == "table" then
				element.img = img
				return true
			end
			return false
		end
		
		function element.setWidth ( width )
			if type ( width ) == "number " then
				element.width = math.floor ( width )
				return true
			end
			return false
		end

		function element.setHeight ( height )
			if type ( height ) == "number " then
				element.height = math.floor ( height )
				return true
			end
			return false
		end

		function element.render ()
			for i = 1, #element.img do
				local line = { str = element.img[ i ].str, fg = element.img[ i ].fg, bg = element.img[ i ].bg }
				element.parent.insertBuffer( element.x, element.y + i - 1 , line )
			end
			return true
		end
	end
	
	return element
	
end
return elements