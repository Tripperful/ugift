AddCSLuaFile()

ugift = ugift or {}

AddCSLuaFile( "ugift_config.lua" )
AddCSLuaFile( "ugift/shared.lua" )
AddCSLuaFile( "ugift/cl_init.lua" )

include( "ugift_config.lua" )

include( "ugift/shared.lua" )

if SERVER then
	include( "ugift/init.lua" )
else
	include( "ugift/cl_init.lua" )
end