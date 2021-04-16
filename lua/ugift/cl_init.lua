ugift.patterns = ugift.patterns or {}
ugift.skins = ugift.skins or {}
ugift.queue = ugift.queue or {}

ugift.tapeMat = CreateMaterial( "ugift/tape", "VertexLitGeneric", {
	["$basetexture"] = "cable/cable",
	["$color"] = "[1.0 0.0 0.0]",
} )

function ugift.randomSkin()
	local ind = math.random( ugift.maxSkins )
	if not ugift.skins[ind] then
		ugift.skins[ind] = ugift.generateSkin( string.format( "ugift/skin%d" .. CurTime(), ind ) )
	end
	return ugift.skins[ind]
end

function ugift.randomPattern()
	local ind = math.random( #ugift.patternImages )
	if not ugift.patterns[ind] then
		ugift.patterns[ind] = Material( ugift.patternImages[ind] )
	end
	return ugift.patterns[ind]
end

function ugift.generateSkin( name )
	local bgColor = HSVToColor( math.random( 0, 360 ), 1, 0.5 )
	local mat = CreateMaterial( name, "VertexLitGeneric", {
		["$basetexture"] = name,
		["$envmap"] = "env_cubemap",
		["$envmaptint"] = "[" .. bgColor.r / 512 .. " " .. bgColor.g / 512 .. " " .. bgColor.b / 512 .. "]",
	} )
	local tex = GetRenderTargetEx( name, 512, 512,
	RT_SIZE_DEFAULT, MATERIAL_RT_DEPTH_SHARED, 0,
	CREATERENDERTARGETFLAGS_HDR, IMAGE_FORMAT_DEFAULT )
	render.PushRenderTarget( tex )
	render.Clear( bgColor.r, bgColor.g, bgColor.b, 255, true, true )
	cam.Start2D()
	render.PushFilterMag( TEXFILTER.NONE )
	render.PushFilterMin( TEXFILTER.NONE )
	for y = 64, 512 - 64, 128 do
		for x = 64, 512 - 64, 128 do
			local a = math.random( 64, 128 )
			surface.SetDrawColor( 255, 255, 255, ugift.patternAlpha / 4 )
			surface.SetMaterial( ugift.randomPattern() )
			surface.DrawTexturedRectRotated( x, y, a, a, math.random( 360 ) )
		end
	end
	for y = 32, 512 - 32, 64 do
		for x = 32, 512 - 32, 64 do
			local a = math.random( 32, 64 )
			surface.SetDrawColor( 255, 255, 255, ugift.patternAlpha )
			surface.SetMaterial( ugift.randomPattern() )
			surface.DrawTexturedRectRotated( x, y, a, a, math.random( 360 ) )
		end
	end
	render.PopFilterMag()
	render.PopFilterMin()
	cam.End2D()
	render.PopRenderTarget()
	mat:Recompute()
	return mat
end

function ugift.generateTapeMesh( min, max, mat )
	local center = ( min + max ) / 2
	local hl, hw, hh = ( max.x - min.x ) / 2, ( max.y - min.y ) / 2, ( max.z - min.z ) / 2
	local w = math.Clamp( math.min( hl, hw, hh ) / 8, 0.25, 3 )
	local verts = {
		{ pos = center + Vector(  hl,  w,  hh ), u = 1, v = 1, normal = Vector( 0, 0, 1 ) },
		{ pos = center + Vector(  hl, -w,  hh ), u = 0, v = 1, normal = Vector( 0, 0, 1 ) },
		{ pos = center + Vector( -hl,  w,  hh ), u = 1, v = 0, normal = Vector( 0, 0, 1 ) },
		{ pos = center + Vector( -hl, -w,  hh ), u = 0, v = 0, normal = Vector( 0, 0, 1 ) },
		{ pos = center + Vector( -hl,  w,  hh ), u = 1, v = 0, normal = Vector( 0, 0, 1 ) },
		{ pos = center + Vector(  hl, -w,  hh ), u = 0, v = 1, normal = Vector( 0, 0, 1 ) },

		{ pos = center + Vector(  hl,  w, -hh ), u = 1, v = 1, normal = Vector( 1, 0, 0 ) },
		{ pos = center + Vector(  hl, -w, -hh ), u = 0, v = 1, normal = Vector( 1, 0, 0 ) },
		{ pos = center + Vector(  hl,  w,  hh ), u = 1, v = 0, normal = Vector( 1, 0, 0 ) },
		{ pos = center + Vector(  hl, -w,  hh ), u = 0, v = 0, normal = Vector( 1, 0, 0 ) },
		{ pos = center + Vector(  hl,  w,  hh ), u = 1, v = 0, normal = Vector( 1, 0, 0 ) },
		{ pos = center + Vector(  hl, -w, -hh ), u = 0, v = 1, normal = Vector( 1, 0, 0 ) },

		{ pos = center + Vector(  hl, -w, -hh ), u = 0, v = 0, normal = Vector( 0, 0, -1 ) },
		{ pos = center + Vector(  hl,  w, -hh ), u = 1, v = 0, normal = Vector( 0, 0, -1 ) },
		{ pos = center + Vector( -hl,  w, -hh ), u = 1, v = 1, normal = Vector( 0, 0, -1 ) },
		{ pos = center + Vector( -hl,  w, -hh ), u = 1, v = 1, normal = Vector( 0, 0, -1 ) },
		{ pos = center + Vector( -hl, -w, -hh ), u = 0, v = 1, normal = Vector( 0, 0, -1 ) },
		{ pos = center + Vector(  hl, -w, -hh ), u = 0, v = 0, normal = Vector( 0, 0, -1 ) },

		{ pos = center + Vector( -hl, -w, -hh ), u = 1, v = 1, normal = Vector( -1, 0, 0 ) },
		{ pos = center + Vector( -hl,  w, -hh ), u = 0, v = 1, normal = Vector( -1, 0, 0 ) },
		{ pos = center + Vector( -hl,  w,  hh ), u = 0, v = 0, normal = Vector( -1, 0, 0 ) },
		{ pos = center + Vector( -hl,  w,  hh ), u = 0, v = 0, normal = Vector( -1, 0, 0 ) },
		{ pos = center + Vector( -hl, -w,  hh ), u = 1, v = 0, normal = Vector( -1, 0, 0 ) },
		{ pos = center + Vector( -hl, -w, -hh ), u = 1, v = 1, normal = Vector( -1, 0, 0 ) },

		{ pos = center + Vector( -w,  hw,  hh + 0.05 ), u = 1, v = 1, normal = Vector( 0, 0, 1 ) },
		{ pos = center + Vector(  w,  hw,  hh + 0.05 ), u = 0, v = 1, normal = Vector( 0, 0, 1 ) },
		{ pos = center + Vector(  w, -hw,  hh + 0.05 ), u = 0, v = 0, normal = Vector( 0, 0, 1 ) },
		{ pos = center + Vector(  w, -hw,  hh + 0.05 ), u = 0, v = 0, normal = Vector( 0, 0, 1 ) },
		{ pos = center + Vector( -w, -hw,  hh + 0.05 ), u = 1, v = 0, normal = Vector( 0, 0, 1 ) },
		{ pos = center + Vector( -w,  hw,  hh + 0.05 ), u = 1, v = 1, normal = Vector( 0, 0, 1 ) },

		{ pos = center + Vector(  w, -hw, -hh ), u = 1, v = 1, normal = Vector( 0, -1, 0 ) },
		{ pos = center + Vector( -w, -hw, -hh ), u = 0, v = 1, normal = Vector( 0, -1, 0 ) },
		{ pos = center + Vector(  w, -hw,  hh ), u = 1, v = 0, normal = Vector( 0, -1, 0 ) },
		{ pos = center + Vector( -w, -hw,  hh ), u = 0, v = 0, normal = Vector( 0, -1, 0 ) },
		{ pos = center + Vector(  w, -hw,  hh ), u = 1, v = 0, normal = Vector( 0, -1, 0 ) },
		{ pos = center + Vector( -w, -hw, -hh ), u = 0, v = 1, normal = Vector( 0, -1, 0 ) },

		{ pos = center + Vector(  w,  hw, -hh - 0.05 ), u = 1, v = 1, normal = Vector( 0, 0, -1 ) },
		{ pos = center + Vector( -w,  hw, -hh - 0.05 ), u = 0, v = 1, normal = Vector( 0, 0, -1 ) },
		{ pos = center + Vector(  w, -hw, -hh - 0.05 ), u = 1, v = 0, normal = Vector( 0, 0, -1 ) },
		{ pos = center + Vector( -w, -hw, -hh - 0.05 ), u = 0, v = 0, normal = Vector( 0, 0, -1 ) },
		{ pos = center + Vector(  w, -hw, -hh - 0.05 ), u = 1, v = 0, normal = Vector( 0, 0, -1 ) },
		{ pos = center + Vector( -w,  hw, -hh - 0.05 ), u = 0, v = 1, normal = Vector( 0, 0, -1 ) },

		{ pos = center + Vector( -w,  hw, -hh ), u = 1, v = 1, normal = Vector( 0, 1, 0 ) },
		{ pos = center + Vector(  w,  hw, -hh ), u = 0, v = 1, normal = Vector( 0, 1, 0 ) },
		{ pos = center + Vector(  w,  hw,  hh ), u = 0, v = 0, normal = Vector( 0, 1, 0 ) },
		{ pos = center + Vector(  w,  hw,  hh ), u = 0, v = 0, normal = Vector( 0, 1, 0 ) },
		{ pos = center + Vector( -w,  hw,  hh ), u = 1, v = 0, normal = Vector( 0, 1, 0 ) },
		{ pos = center + Vector( -w,  hw, -hh ), u = 1, v = 1, normal = Vector( 0, 1, 0 ) },

		{ pos = center + Vector( -w,  4 * w,  hh + 2 * w ), u = 1, v = 1, normal = Vector( 0, 0, 1 ) },
		{ pos = center + Vector(  w,  4 * w,  hh + 2 * w ), u = 0, v = 1, normal = Vector( 0, 0, 1 ) },
		{ pos = center + Vector(  w,  w,  hh + 0.05 ), u = 0, v = 0, normal = Vector( 0, 0, 1 ) },
		{ pos = center + Vector(  w,  w,  hh + 0.05 ), u = 0, v = 0, normal = Vector( 0, 0, 1 ) },
		{ pos = center + Vector( -w,  w,  hh + 0.05 ), u = 1, v = 0, normal = Vector( 0, 0, 1 ) },
		{ pos = center + Vector( -w,  4 * w,  hh + 2 * w ), u = 1, v = 1, normal = Vector( 0, 0, 1 ) },

		{ pos = center + Vector(  w,  4 * w,  hh + 2 * w ), u = 0, v = 1, normal = Vector( 0, 0, -1 ) },
		{ pos = center + Vector( -w,  4 * w,  hh + 2 * w ), u = 1, v = 1, normal = Vector( 0, 0, -1 ) },
		{ pos = center + Vector(  w,  w,  hh + 0.05 ), u = 0, v = 0, normal = Vector( 0, 0, -1 ) },
		{ pos = center + Vector( -w,  w,  hh + 0.05 ), u = 1, v = 0, normal = Vector( 0, 0, -1 ) },
		{ pos = center + Vector(  w,  w,  hh + 0.05 ), u = 0, v = 0, normal = Vector( 0, 0, -1 ) },
		{ pos = center + Vector( -w,  4 * w,  hh + 2 * w ), u = 1, v = 1, normal = Vector( 0, 0, -1 ) },

		{ pos = center + Vector( -w,  -w,  hh + 0.05 ), u = 1, v = 1, normal = Vector( 0, 0, 1 ) },
		{ pos = center + Vector(  w,  -w,  hh + 0.05 ), u = 0, v = 1, normal = Vector( 0, 0, 1 ) },
		{ pos = center + Vector(  w,  -4 * w,  hh + 2 * w ), u = 0, v = 0, normal = Vector( 0, 0, 1 ) },
		{ pos = center + Vector(  w,  -4 * w,  hh + 2 * w ), u = 0, v = 0, normal = Vector( 0, 0, 1 ) },
		{ pos = center + Vector( -w,  -4 * w,  hh + 2 * w ), u = 1, v = 0, normal = Vector( 0, 0, 1 ) },
		{ pos = center + Vector( -w,  -w,  hh + 0.05 ), u = 1, v = 1, normal = Vector( 0, 0, 1 ) },

		{ pos = center + Vector(  w,  -w,  hh + 0.05 ), u = 0, v = 1, normal = Vector( 0, 0, -1 ) },
		{ pos = center + Vector( -w,  -w,  hh + 0.05 ), u = 1, v = 1, normal = Vector( 0, 0, -1 ) },
		{ pos = center + Vector(  w,  -4 * w,  hh + 2 * w ), u = 0, v = 0, normal = Vector( 0, 0, -1 ) },
		{ pos = center + Vector(  w,  -4 * w,  hh + 2 * w ), u = 0, v = 0, normal = Vector( 0, 0, -1 ) },
		{ pos = center + Vector( -w,  -w,  hh + 0.05 ), u = 1, v = 1, normal = Vector( 0, 0, -1 ) },
		{ pos = center + Vector( -w,  -4 * w,  hh + 2 * w ), u = 1, v = 0, normal = Vector( 0, 0, -1 ) },

		{ pos = center + Vector( 4 * w, -w,  hh + 2 * w ), u = 1, v = 1, normal = Vector( 0, 0, -1 ) },
		{ pos = center + Vector( 4 * w,  w,  hh + 2 * w ), u = 0, v = 1, normal = Vector( 0, 0, -1 ) },
		{ pos = center + Vector( w,  w,  hh + 0.05 ), u = 0, v = 0, normal = Vector( 0, 0, -1 ) },
		{ pos = center + Vector( w,  w,  hh + 0.05 ), u = 0, v = 0, normal = Vector( 0, 0, -1 ) },
		{ pos = center + Vector( w, -w,  hh + 0.05 ), u = 1, v = 0, normal = Vector( 0, 0, -1 ) },
		{ pos = center + Vector( 4 * w, -w,  hh + 2 * w ), u = 1, v = 1, normal = Vector( 0, 0, -1 ) },

		{ pos = center + Vector( 4 * w,  w,  hh + 2 * w ), u = 0, v = 1, normal = Vector( 0, 0, 1 ) },
		{ pos = center + Vector( 4 * w, -w,  hh + 2 * w ), u = 1, v = 1, normal = Vector( 0, 0, 1 ) },
		{ pos = center + Vector( w,  w,  hh + 0.05 ), u = 0, v = 0, normal = Vector( 0, 0, 1 ) },
		{ pos = center + Vector( w, -w,  hh + 0.05 ), u = 1, v = 0, normal = Vector( 0, 0, 1 ) },
		{ pos = center + Vector( w,  w,  hh + 0.05 ), u = 0, v = 0, normal = Vector( 0, 0, 1 ) },
		{ pos = center + Vector( 4 * w, -w,  hh + 2 * w ), u = 1, v = 1, normal = Vector( 0, 0, 1 ) },

		{ pos = center + Vector( -w, -w,  hh + 0.05 ), u = 1, v = 1, normal = Vector( 0, 0, -1 ) },
		{ pos = center + Vector( -w,  w,  hh + 0.05 ), u = 0, v = 1, normal = Vector( 0, 0, -1 ) },
		{ pos = center + Vector( -4 * w,  w,  hh + 2 * w ), u = 0, v = 0, normal = Vector( 0, 0, -1 ) },
		{ pos = center + Vector( -4 * w,  w,  hh + 2 * w ), u = 0, v = 0, normal = Vector( 0, 0, -1 ) },
		{ pos = center + Vector( -4 * w, -w,  hh + 2 * w ), u = 1, v = 0, normal = Vector( 0, 0, -1 ) },
		{ pos = center + Vector( -w, -w,  hh + 0.05 ), u = 1, v = 1, normal = Vector( 0, 0, -1 ) },

		{ pos = center + Vector( -w,  w,  hh + 0.05 ), u = 0, v = 1, normal = Vector( 0, 0, 1 ) },
		{ pos = center + Vector( -w, -w,  hh + 0.05 ), u = 1, v = 1, normal = Vector( 0, 0, 1 ) },
		{ pos = center + Vector( -4 * w,  w,  hh + 2 * w ), u = 0, v = 0, normal = Vector( 0, 0, 1 ) },
		{ pos = center + Vector( -4 * w,  w,  hh + 2 * w ), u = 0, v = 0, normal = Vector( 0, 0, 1 ) },
		{ pos = center + Vector( -w, -w,  hh + 0.05 ), u = 1, v = 1, normal = Vector( 0, 0, 1 ) },
		{ pos = center + Vector( -4 * w, -w,  hh + 2 * w ), u = 1, v = 0, normal = Vector( 0, 0, 1 ) },
	}
	local m = Mesh( mat )
	m:BuildFromTriangles( verts )
	return m
end

function ugift.bakeVertices( vertices, smooth, texScale )
	local count = #vertices
	local shift = 0
	while shift < count - 2 do
		triangle = { vertices[shift + 1].pos, vertices[shift + 2].pos, vertices[shift + 3].pos }
		local n = ( triangle[3] - triangle[2] ):Cross( triangle[2] - triangle[1] ):GetNormalized()
		local t = Vector( n )
		t:Rotate( Angle( 90, 90, 0 ) )
		local s = n:Cross( t ):GetNormalized()
		for i, v in ipairs( triangle ) do
			local u, v = -v:Dot( t ) / texScale or 32, v:Dot( s ) / texScale or 32
			vertices[shift + i].u = u
			vertices[shift + i].v = v
			vertices[shift + i].normal = n
		end
		shift = shift + 3
	end
	if smooth then
		local normalCache = {}
		for i, vertex in pairs( vertices ) do
			vertex.pos = Vector( math.Round( vertex.pos.x, 5 ), math.Round( vertex.pos.y, 5 ), math.Round( vertex.pos.z, 5 ) )
			local ind = vertex.pos.x .. "," .. vertex.pos.y .. "," .. vertex.pos.z
			if normalCache[ind] then
				table.insert( normalCache[ind], i )
			else
				normalCache[ind] = { i }
			end
		end
		for ind, indList in pairs( normalCache ) do
			local middle = Vector( 0, 0, 0 )
			for i, vertexInd in pairs( indList ) do
				middle = middle + vertices[vertexInd].normal
			end
			middle:Normalize()
			for i, vertexInd in pairs( indList ) do
				vertices[vertexInd].normal = middle
			end
		end
	end
end

function ugift.drawMesh( m, mat )
	render.SetMaterial( mat )
	m:Draw()
	if LocalPlayer():FlashlightIsOn() then
		render.PushFlashlightMode( true )
		m:Draw()
		render.PopFlashlightMode()
	end
end

function ugift.drawGift( gift )
	gift:SetMoveType( MOVETYPE_NONE )
	if not IsValid( gift:GetPhysicsObject() ) then
		gift:PhysicsInitConvex( gift.hull )
	end
	if gift.meshes then
		local pos, ang = gift:GetPos(), gift:GetAngles()
		gift:SetNoDraw( true )
		render.SetBlend( 0 )
		gift:DrawShadow( false )
		gift:DrawModel()
		render.SetBlend( 1 )
		local m = Matrix()
		m:SetAngles( ang )
		m:SetTranslation( pos )
		cam.PushModelMatrix( m )
		local drawTie
		for msh, mat in pairs( gift.meshes ) do
			render.ResetModelLighting( 0.5, 0.5, 0.5 )
			render.SetLightingOrigin( gift:WorldSpaceCenter() )
			ugift.drawMesh( msh, mat )
			if mat == ugift.tapeMat then
				drawTie = true
			end
		end
		cam.PopModelMatrix()
	end
end

net.Receive( "ugift.updateGiftStatus", function( len )
	local giftInd = net.ReadUInt( 16 )
	local newStatus = net.ReadUInt( 2 )
	local gift = Entity( giftInd )
	if IsValid( gift ) then
		local currentStatus = ugift.gifts[giftInd]
		if newStatus ~= currentStatus then
			ugift.updateGiftStatus( gift, newStatus )
		end
	else
		if newStatus == ugift.GIFT_NONE then
			ugift.queue[giftInd] = nil
			ugift.gifts[giftInd] = nil
		else
			ugift.queue[giftInd] = newStatus
		end
	end
end )

net.Receive( "ugift.fullUpdate", function( len )
	local c = net.ReadUInt( 16 )
	for i = 1, c do
		ugift.queue[net.ReadUInt( 16 )] = net.ReadUInt( 2 )
	end
end )

hook.Add( "Think", "ugift", function()
	for giftInd, queuingStatus in pairs( ugift.queue ) do
		local gift = Entity( giftInd )
		if IsValid( gift ) or queuingStatus == ugift.GIFT_NONE then
			if queuingStatus ~= ugift.GIFT_NONE then
				ugift.updateGiftStatus( gift, queuingStatus )
			end
			ugift.queue[giftInd] = nil
		end
	end
end )

hook.Add( "PostDrawOpaqueRenderables", "ugift", function()
	for giftInd, status in pairs( ugift.gifts ) do
		local gift = Entity( giftInd )
		if IsValid( gift ) then
			ugift.drawGift( gift )
		end
	end
end )

concommand.Add( "ugift_wrap", function()
	local tr = LocalPlayer():GetEyeTrace()
	local gift = tr.Entity
	if gift and ugift.canWrap( gift, ply ) then
		net.Start( "ugift.wrap" )
		net.WriteEntity( gift )
		net.SendToServer()
	end
end )

concommand.Add( "ugift_unwrap", function()
	local tr = LocalPlayer():GetEyeTrace()
	local gift = tr.Entity
	if gift and ugift.canUnwrap( gift, ply ) then
		net.Start( "ugift.unwrap" )
		net.WriteEntity( gift )
		net.SendToServer()
	end
end )


local chatCommands = {
	["/wrapgift"] = "ugift_wrap",
	["/unwrapgift"] = "ugift_unwrap",
}

hook.Add( "OnPlayerChat", "ugift", function( ply, cmd, team, dead )
	cmd = string.lower( cmd )
	if chatCommands[cmd] then
		RunConsoleCommand( chatCommands[cmd] )
		return true
	end
end )

language.Add( "ugift_wrap", "Wrap gift in paper" )
language.Add( "ugift_unwrap", "Unwrap gift" )