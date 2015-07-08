(begin
	(lua-syntax quote "return args[2]")
	(lua-syntax define "env[args[2]] = self:eval(args[3],env)" )
	(lua-syntax if "return self:eval( self:eval( args[2], env ) and args[3] or args[4], env )"))
