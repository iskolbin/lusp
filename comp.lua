scm = {
	logicops = {['>'] = true, ['<'] = true, ['>='] = true, ['<='] = true, ['='] = true, ['~='] = true, },
	arithmops = {['+'] = true, ['-'] = true, ['*'] = true, ['/'] = true, ['//'] = true },

	compile = function( t, l )
		local l = l or 1
		if type( t ) == 'table' then
			if t[1] == 'lambda' then
				return ('function(%s) return (%s) end'):format( table.concat( t[2], ',' ), scm.compile( t[3], l+1 ))
			elseif t[1] == 'define' then
				local result = scm.compile( t[3] )
				if result == t[3] or result:sub(1,8) == 'function' then
					return ('local %s=%s'):format( t[2], result )
				else
					return ('local __result%d__\n%s\nlocal %s=__result%d__'):format( l, result, t[2], l )
				end
			elseif t[1] == 'if' then
				return ('%s and %s%s'):format( scm.compile( t[2], l+1 ), scm.compile( t[3] ), t[4] and (' or ' .. scm.compile( t[4], l + 1 )) or '' )
			elseif scm.logicops[t[1]] then
				assert( t[3] ~= nil )
				local args = {}
				for i = 2, #t-1 do 
					args[i-1] = ('(%s%s%s)'):format( scm.compile( t[i], l + 1), t[1], scm.compile( t[i+1], l + 1)) 
				end
				return table.concat( args, 'and' )
			elseif scm.arithmops[t[1]] then
				if t[1] == '-' and t[3] == nil then
					return ('-(%s)'):format( scm.compile( t[2], l + 1 ))
				else
					assert( t[3] ~= nil )
					local args = {}
					for i = 2, #t do 
						args[i-1] = ('%s'):format( scm.compile( t[i], l + 1 )) 
					end
					return '(' .. table.concat( args, t[1] ) .. ')'
				end
			elseif t[1] == 'set!' then
				return ('%s=%s'):format( t[2], scm.compile( t[3], l + 1 ))
			elseif t[1] == 'begin' then
				local args = {}
				for i = 2, #t-1 do
					args[i-1] = ('%s'):format( scm.compile( t[i], l + 1 ))
				end
				return ('do\n%s\n%s=%s\nend'):format( table.concat(args,'\n'), ('__result%d__'):format(l),scm.compile( t[#t], l + 1))
			elseif t[1] == 'let' then
				local args = {}
				for i = 1, #t[2] do
					args[i] = ('local %s=%s'):format( t[2][i][1], scm.compile( t[2][i][2], l + 1 ))
				end
				return ('do\n%s\n%s=%s\nend'):format( table.concat( args, '\n' ), ('__result%d__'):format(l),scm.compile( t[3], l + 1)) 
			elseif t[1] == 'quote' then
				local args = {}
				for i = 2, #t do
					args[i] = t[i]
				end
				return args
			elseif t[1] == 'vector' then
				local args = {}
				for i = 2, #t do
					args[i-1] = scm.compile( t[i], l+1 )
				end
				return '{' .. table.concat( args, ',' ) .. '}' 
			else
				local args = {}
				for i = 2, #t do
					args[i-1] = ('%s'):format( scm.compile( t[i], l + 1 ))
				end
				return ('%s(%s)'):format( t[1], table.concat( args, ',' ))
			end
		else
			return t
		end
	end,

	interpret = function( t )
		if type( t ) == 'table' then
			if ( t[1] ) == 'define' then
				_G[t[2]] = loadstring( 'return ' .. scm.compile( t[3] ))()
			else
				print( loadstring( 'return ' .. scm.compile( t ))())
			end
		end
	end,

	parse = function( s )
		local strings = {}
		local function adds( k )
			if not strings[k] then
				strings[#strings+1] = k
				strings[k] = '##<string'..#strings..'>##'
			end
			return strings[k]
		end
		local function gets( i )
			return strings[tonumber(i)]
		end
		local function putv( s )
			if tonumber( s ) then
				return s .. ','
			else
				return "'" .. s .. "',"
			end
		end
		return s:gsub('\\"', '\\' .. ('"'):byte()):gsub('".-"',adds):gsub( '%(', '{' ):gsub( '%)', '}' ):gsub( '([^ {}\t\n\r]+)', putv ):gsub( '##<string(%d)>##', gets )  
	end,

	repl = function(  )
		while true do
			scm.interpret( loadstring('return ' .. scm.parse( io.read()))())
		end
	end,
}

scm.repl()
print( scm.parse( '(define x "(let somethine())\\"and other")' ))
print( scm.parse( '(define abs (lambda (x) (if (> x 0) x (- x))))'))
print( scm.parse( '(define y "abbba")' ))
--print( scm.compile{'define','sq',{'lambda',{'x'},{'*','x','x'}}} )
--print( scm.compile{'define','abs',{'lambda',{'x'},{'if',{'>','x',0},'x',{'-', 'x'}}}} )
--print( scm.compile{'+',1,2,3,4} )
--print( scm.compile{'define', 'y', {'begin', {'define', 'x', 2}, {'-', 'x', 3}}} )
--print( scm.compile{'define', 'z', {'let',{{'x',2},{'y',{'+','x',4}}},{'*', 'x', 'y', 25}}} )
