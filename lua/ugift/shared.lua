ugift.gifts = ugift.gifts or {}

ugift.GIFT_NONE = 0
ugift.GIFT_BUNDLE = 1
ugift.GIFT_BOX = 2

function ugift.doNothing() end

function ugift.canReach( gift, ply )
	local eye = ply:GetShootPos()
	local hitPos, n, frac = util.IntersectRayWithOBB(	eye,
														gift:WorldSpaceCenter() - eye,
														gift:GetPos(), gift:GetAngles(),
														gift:OBBMins(), gift:OBBMaxs() )
	if not hitPos or ( hitPos - eye ):LengthSqr() > ugift.maxDist^2 then return false end
	return true
end

function ugift.canWrap( gift, ply )
	if not IsValid( gift ) then return false end
	local status = ugift.gifts[SERVER and gift or gift:EntIndex()]
	if status == ugift.GIFT_BOX then return false end
	if gift:IsPlayer() then return false end
	if gift:IsNPC() then return false end
	if gift:IsVehicle() then return false end
	if gift:GetClass() == "ugift" then return false end
	if gift:GetSolid() ~= SOLID_VPHYSICS then return false end
	if IsValid( ply ) then
		if not ugift.canReach( gift, ply ) then return false end
	end
	if SERVER then
		if gift:GetMoveType() ~= MOVETYPE_VPHYSICS then return false end
		if gift:GetPhysicsObjectCount() ~= 1 then return false end
		if constraint.HasConstraints( gift ) then return false end
		local phys = gift:GetPhysicsObject()
		if not IsValid( phys ) then return false end
		if not phys:IsMotionEnabled() then return false end
	end
	return true
end

function ugift.canUnwrap( gift, ply )
	if not IsValid( gift ) then return false end
	local status = ugift.gifts[SERVER and gift or gift:EntIndex()]
	if status ~= ugift.GIFT_BOX and status ~= ugift.GIFT_BUNDLE then return false end
	if IsValid( ply ) then
		if not ugift.canReach( gift, ply ) then return false end
	end
	return true
end

function ugift.multiConvexToPointCloud( pieces )
	local hull, cache = {}, {}
	local min, max
	for i, piece in pairs( pieces ) do
		for j, vertex in pairs( piece ) do
			local pos = Vector(	math.Round( vertex.pos.x, 2 ),
								math.Round( vertex.pos.y, 2 ),
								math.Round( vertex.pos.z, 2 ) )
			if not min then min, max = Vector( pos ), Vector( pos ) end
			local ind = pos.x .. "," .. pos.y .. "," .. pos.z
			if not cache[ind] then
				table.insert( hull, pos )
				for i = 1, 3 do
					if pos[i] > max[i] then max[i] = pos[i] end
					if pos[i] < min[i] then min[i] = pos[i] end
				end
				cache[ind] = true
			end
		end
	end
	return hull, min, max
end

function ugift.updateGiftStatus( gift, status )
	if SERVER then
		net.Start( "ugift.updateGiftStatus" )
		net.WriteUInt( gift:EntIndex(), 16 )
		net.WriteUInt( status, 2 )
		net.Broadcast()
	else
		gift.meshes = nil
		local eff = EffectData()
		eff:SetEntity( gift )
		for i = 1, 10 do
			util.Effect( "entity_remove", eff )
		end
		gift:EmitSound( ugift.sounds[math.random( #ugift.sounds )] )
	end
	if status == ugift.GIFT_NONE then
		if SERVER then
			gift:PhysicsInit( SOLID_VPHYSICS )
			gift.ugiftPickupTime = CurTime() + 3
		end
		gift:EnableCustomCollisions( false )
		if CLIENT then
			if gift.meshes then
				for msh, mat in pairs( gift.meshes ) do
					msh:Destroy()
				end
			end
			gift:SetNoDraw( false )
		end
	else
		if gift.meshes then
			for msh, mat in pairs( gift.meshes ) do
				msh:Destroy()
			end
		end
		gift.meshes = {}
		local ghost, phys
		if SERVER then
			phys = gift:GetPhysicsObject()
		else
			ghost = ClientsideModel( gift:GetModel() )
			ghost:PhysicsInit( SOLID_VPHYSICS )
			phys = ghost:GetPhysicsObject()
		end
		if not IsValid( phys ) then return end
		local hull, min, max = ugift.multiConvexToPointCloud( phys:GetMeshConvexes() )
		gift.min, gift.max = min, max
		if status == ugift.GIFT_BOX then
			hull = {
				Vector( min.x, min.y, min.z ),
				Vector( min.x, min.y, max.z ),
				Vector( min.x, max.y, min.z ),
				Vector( min.x, max.y, max.z ),
				Vector( max.x, min.y, min.z ),
				Vector( max.x, min.y, max.z ),
				Vector( max.x, max.y, min.z ),
				Vector( max.x, max.y, max.z ),
			}
			if CLIENT then
				local tapeMesh = ugift.generateTapeMesh( gift.min - Vector( 0.1, 0.1, 0.1 ), gift.max + Vector( 0.1, 0.1, 0.1 ), ugift.tapeMat )
				gift.meshes[tapeMesh] = ugift.tapeMat
			end
		end
		if #hull > ugift.maxVertices then
			hull = {
				Vector( min.x, min.y, min.z ),
				Vector( min.x, min.y, max.z ),
				Vector( min.x, max.y, min.z ),
				Vector( min.x, max.y, max.z ),
				Vector( max.x, min.y, min.z ),
				Vector( max.x, min.y, max.z ),
				Vector( max.x, max.y, min.z ),
				Vector( max.x, max.y, max.z ),
			}
		end
		local oldMass = phys:GetMass()
		gift:PhysicsInitConvex( hull )
		gift:SetSolid( SOLID_VPHYSICS )
		gift:EnableCustomCollisions( true )
		if SERVER then
			gift:SetMoveType( MOVETYPE_VPHYSICS )
			phys = gift:GetPhysicsObject()
			phys:SetMass( oldMass )
		else
			gift:SetRenderBounds( min, max )
			gift.hull = hull
			ghost:PhysicsInitConvex( hull )
			phys = ghost:GetPhysicsObject()
			local vertices = phys:GetMeshConvexes()[1]
			ghost:Remove()
			ugift.bakeVertices( vertices, status == ugift.GIFT_BUNDLE, status == ugift.GIFT_BOX and 64 or 32 )
			gift.skin = ugift.randomSkin()
			local newMesh = Mesh( gift.skin )
			newMesh:BuildFromTriangles( vertices )
			gift.meshes[newMesh] = gift.skin
		end
	end
	if status == ugift.GIFT_NONE then
		ugift.gifts[SERVER and gift or gift:EntIndex()] = nil
	else
		ugift.gifts[SERVER and gift or gift:EntIndex()] = status
	end
end

properties.Add( "ugift_wrap", {
	MenuLabel = "#ugift_wrap",
	Order = -999999,
	MenuIcon = "icon16/box.png",
	Filter = function( self, gift, ply )
		return ugift.canWrap( gift, ply )
	end,
	Action = function( self, gift )
		net.Start( "ugift.wrap" )
		net.WriteEntity( gift )
		net.SendToServer()
	end
} )

properties.Add( "ugift_unwrap", {
	MenuLabel = "#ugift_unwrap",
	Order = -999999,
	MenuIcon = "icon16/star.png",
	Filter = function( self, gift, ply )
		return ugift.canUnwrap( gift, ply )
	end,
	Action = function( self, gift )
		net.Start( "ugift.unwrap" )
		net.WriteEntity( gift )
		net.SendToServer()
	end
} )