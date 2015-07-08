unpack = unpack or table.unpack

local Lusp = {	
	strings = setmetatable( {}, {__mode = 'kv'} ),
	
	onSyntaxError = function( self, message )
		error( message )
	end,
	
	tokenize = function( self, s )
		local function addString( s )
			self.strings.n = (self.strings.n or 0) + 1
			local name = '<@string' .. self.strings.n .. '@>' 
			self.strings[name] = s
			return name		
		end
		return s:gsub('".-"', addString ):gsub('%(', ' ( '):gsub('%)', ' ) '):gmatch( '%S+' )
	end,

	atom = function( self, token )
		local n = tonumber( token )
		return n or self.strings[token] or tostring( token )
	end,

	readFromTokens = function( self, tokens, processInner, strings )
		local token = tokens()
		if not token then
			self:onSyntaxError( 'Unexpeceted end of input')
		end
		
		if token == '(' then
			local L = {}
			local var = self:readFromTokens( tokens, true )
			while var do
				L[#L+1] = var			
				var = self:readFromTokens( tokens, true )
			end
			return L
		elseif token == ')' then
			if processInner then
				return false
			else
				self:onSyntaxError( 'Unexpected ")"')
			end
		else
			return self:atom( token )
		end
	end,

	parse = function( self,program )
		local parsed =  self:readFromTokens( self:tokenize( program ), 0 )
		return parsed
	end,

	standartEnv = {},

	makeLuaSyntax = function( self, code, env )
		return self:makeLuaProcedure( code, env )
	end,

	syntax = {
		load = function( self, args, env )
			local f, err = io.open( args[2]:sub(2,-2), 'r' )
			if not f then
				self:onFileError( 'Cannot read file ' .. args[2] .. '. ' .. err )
			end
			self:eval( self:parse( f:read('*all')), env )
		end,
		lambda = function( self, args, env ) return self:makeProcedure( args[2], args[3], env ) end,
		['lua-lambda'] = function( self, args, env ) return self:makeLuaProcedure( args[2], env ) end,
		['lua-syntax'] = function( self, args, env ) self.syntax[args[2]] = self:makeLuaSyntax( args[3], env ) end,
		begin = function( self, args, env ) 
			for i = 2, #args-1 do
				self:eval( args[i], env )
			end
			return self:eval( args[#args], env )
		end,
	},

	makeEnv = function( self, params, outer, args )
		local env = setmetatable( {}, {__index = outer} )
		for i = 1, #params do
			env[params[i]] = args[i+1]
		end
		return env
	end,

	procedureMt = {
		__call = function( procedure, ... ) 
			local self = procedure[4]
			local _,args, env = ...
			return self:eval( procedure[2], self:makeEnv( procedure[1], procedure[3], args ))
		end, 
	},

	makeProcedure = function( self, params, body, env )
		return setmetatable( {params,body,env,self}, self.procedureMt )
	end,

	makeLuaProcedure = function( self, code, env )
		local f, err = loadstring( 'return function(self,args,env) ' .. code:sub(2,-2) .. ' end' )
		if not f then
			self:onSyntaxError( "Error during lua compilation " .. err )
		end
		return f()
	end,

	isSymbol = function( self, v ) return type( v ) == 'string' and v:sub(1,1) ~= '"' end,
	isList   = function( self, v ) return type( v ) == 'table' end,

	onFileError = function( self, s )
		error( s )
	end,

	repl = function( self, args )
		io.write( args.welcome )
		if args.init then
			self:eval( self:parse( args.init ))
		end
		while true do
			io.write( args.promt )
			local line = io.read()
			if #line > 0 then
				local res = self:eval( self:parse( line ))
				if res ~= nil then print( res ) end
			end
		end
	end,

	eval = function( self, x, env )
		local env = env or self.standartEnv
		if self:isSymbol( x ) then
			return env[x]
		elseif not self:isList( x ) then
			return x
		else
			local op = x[1]
			if self.syntax[op] then
				return self.syntax[op]( self, x, env )
			else
				local proc = self:eval( op, env )
				local args = {proc}
				for i = 2, #x do 
					args[i] = self:eval( x[i], env ) 
				end
				return proc( self, args, env )
			end
		end
	end,
}

return Lusp
