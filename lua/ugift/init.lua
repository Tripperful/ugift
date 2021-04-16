util.AddNetworkString( "ugift.fullUpdate" )
util.AddNetworkString( "ugift.updateGiftStatus" )
util.AddNetworkString( "ugift.wrap" )
util.AddNetworkString( "ugift.unwrap" )

net.Receive( "ugift.wrap", function( len, ply )
	local gift = net.ReadEntity()
	if not ugift.canWrap( gift, ply ) then
		-- TODO: Notify the player that he can't wrap this entity into gift
		return
	end
	ugift.updateGiftStatus( gift, ugift.GIFT_BOX )
end )

net.Receive( "ugift.unwrap", function( len, ply )
	local gift = net.ReadEntity()
	if not ugift.canUnwrap( gift, ply ) then
		-- TODO: Notify the player that he can't unwrap this gift
		return
	end
	ugift.updateGiftStatus( gift, ugift.gifts[gift] == ugift.GIFT_BOX and ugift.GIFT_BUNDLE or ugift.GIFT_NONE )
end )

function ugift.canPickup( ply, gift )
	if ugift.gifts[gift] then return false end
	if gift.ugiftPickupTime then
		if gift.ugiftPickupTime > CurTime() then
			return false
		else
			gift.ugiftPickupTime = nil
		end
	end
end

hook.Add( "PlayerCanPickupItem", "ugift", ugift.canPickup )
hook.Add( "PlayerCanPickupWeapon", "ugift", ugift.canPickup )

hook.Add( "EntityRemoved", "ugift", function( gift )
	if ugift.gifts[gift] then
		ugift.gifts[gift] = nil
		net.Start( "ugift.updateGiftStatus" )
		net.WriteUInt( gift:EntIndex(), 16 )
		net.WriteUInt( ugift.GIFT_NONE, 2 )
		net.Broadcast()
	end
end )

hook.Add( "PlayerInitialSpawn", "ugift", function( ply )
	local c = table.Count( ugift.gifts )
	if c > 0 then
		net.Start( "ugift.fullUpdate" )
		net.WriteUInt( c, 16 )
		for gift, status in pairs( ugift.gifts ) do
			net.WriteUInt( gift:EntIndex(), 16 )
			net.WriteUInt( status, 2 )
		end
		net.Send( ply )
	end
end )