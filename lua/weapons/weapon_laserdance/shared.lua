
AddCSLuaFile( "shared.lua" )

SWEP.Author			= "DarkZone(Edit: CHOPPER)"
SWEP.Contact		= "dark-zone@live.de"
SWEP.Purpose		= ""
SWEP.Instructions	= ""

if ( CLIENT ) then

SWEP.DrawWeaponInfoBox	= false					// Should draw the weapon info box
SWEP.BounceWeaponIcon   = false					// Should the weapon icon bounce?
SWEP.SwayScale			= 1.0					// The scale of the viewmodel sway
SWEP.BobScale			= 1.0					// The scale of the viewmodel bob
SWEP.WepSelectIcon		= surface.GetTextureID( "gmod/SWEP/weapon_laserdance" )

end

SWEP.ViewModelFOV	= 62
SWEP.ViewModelFlip	= false
SWEP.ViewModel		= "models/weapons/v_rif_famas.mdl"
SWEP.WorldModel		= "models/weapons/w_rif_famas.mdl"
SWEP.AnimPrefix		= "python"

SWEP.Spawnable			= true
SWEP.AdminSpawnable		= true

SWEP.Primary.ClipSize		= -1				// Size of a clip
SWEP.Primary.DefaultClip	= -1				// Default number of bullets in a clip
SWEP.Primary.Automatic		= true				// Automatic/Semi Auto
SWEP.Primary.Ammo			= "none"

SWEP.Secondary.ClipSize		= 8					// Size of a clip
SWEP.Secondary.DefaultClip	= 32				// Default number of bullets in a clip
SWEP.Secondary.Automatic	= true				// Automatic/Semi Auto
SWEP.Secondary.Ammo			= "none"

function SWEP:Initialize()
	self:SetHoldType("ar2")
end

sound.Add( {
	name = "laserdance_shoot",
	channel = CHAN_STATIC,
	volume = 1.0,
	level = 75,
	pitch = 100 ,
	sound = "weapons/laserdance/echo1.wav"
} )

local cvar_pushforce = CreateConVar("laserdance_pushforce", "2000", {FCVAR_NOTIFY, FCVAR_SERVER_CAN_EXECUTE}, "Push force amount on primary fire")
local cvar_laserdamage = CreateConVar("laserdance_damage", "120", {FCVAR_NOTIFY, FCVAR_SERVER_CAN_EXECUTE}, "Damage dealt on primary fire")
local cvar_healsound = CreateConVar("laserdance_healsounds", "1", {FCVAR_NOTIFY, FCVAR_SERVER_CAN_EXECUTE}, "1: Play sounds when healed, 0: Disable healing sounds")

if SERVER then

	-- NETWORKING --
	
	net.Receive("LaserDanceHeal", function()
		local ply = net.ReadEntity()
		if IsValid(ply) then
			if ply:IsPlayer() then
				if ply:Health() < 150 then
					ply:SetHealth( ply:Health() + 1)
					if cvar_healsound:GetBool() then
					
						local pitch = (ply:Health() / 150.0) * 100 + 50;
						if pitch < 50 then
							pitch = 50
						end
						
						ply:EmitSound("items/medshot4.wav", 75, pitch, 0.5, CHAN_STATIC)
						if(ply:Health() == 150) then
							ply:EmitSound("hl1/fvox/medical_repaired.wav", 75, 100, 1, CHAN_STATIC)
						end
					end
				end
			end
		else
			print("[LASERDANCE] Healed player is not valid")
		end
	end)

end

/*---------------------------------------------------------
   Name: SWEP:PrimaryAttack( )
   Desc: +attack1 has been pressed
---------------------------------------------------------*/
function SWEP:PrimaryAttack()
	
	// Play shoot sound
	self.Weapon:EmitSound("laserdance_shoot")
	
	self:ShootBullet( cvar_laserdamage:GetInt(), 1, 0.0 )
	
	// Punch the player's view
	self.Owner:ViewPunch( Angle( -0.5, -0.5, -0.5 ) )
	
	self:SetNextPrimaryFire( CurTime() + 0.6 )
	
	// Make the player fly backwards..
	self.Owner:SetGroundEntity( NULL )
	self.Owner:SetLocalVelocity( self.Owner:GetAimVector() * -cvar_pushforce:GetInt() )
		

end


/*---------------------------------------------------------
   Name: SWEP:SecondaryAttack( )
   Desc: +attack2 has been pressed
---------------------------------------------------------*/
function SWEP:SecondaryAttack()

	// Todo.. increase health..
	
	self:ShootSecondaryBullet( 0.001, 1, 0.0 )

	self:SetNextSecondaryFire( CurTime() + 0.1 )

end

/*---------------------------------------------------------
   Name: SWEP:ShootBullet( )
   Desc: A convenience function to shoot bullets
---------------------------------------------------------*/
function SWEP:ShootEffects()

	self.Weapon:SendWeaponAnim( ACT_VM_PRIMARYATTACK ) 		// View model animation
	self.Owner:MuzzleFlash()								// Crappy muzzle light
	self.Owner:SetAnimation( PLAYER_ATTACK1 )				// 3rd Person Animation

end


/*---------------------------------------------------------
   Name: SWEP:ShootBullet( )
   Desc: A convenience function to shoot bullets
---------------------------------------------------------*/
function SWEP:ShootBullet( damage, num_bullets, aimcone )
	
	local bullet = {}
	bullet.Num 		= num_bullets
	bullet.Src 		= self.Owner:GetShootPos()			// Source
	bullet.Dir 		= self.Owner:GetAimVector()			// Dir of bullet
	bullet.Spread 	= Vector( aimcone, aimcone, 0 )		// Aim Cone
	bullet.Tracer	= 1									// Show a tracer on every x bullets 
	bullet.Force	= 100								// Amount of force to give to phys objects
	bullet.Damage	= damage
	bullet.AmmoType = "Pistol"
	bullet.HullSize = 2
	bullet.TracerName = "laserdancetracer"
	
	self.Owner:FireBullets( bullet )
	
	self:ShootEffects()
	
end

/*---------------------------------------------------------
   Name: SWEP:ShootSecondaryBullet( )
   Desc: A convenience function to shoot bullets upon secondary fire
---------------------------------------------------------*/
function SWEP:ShootSecondaryBullet( damage, num_bullets, aimcone )
	
	local bullet = {}
	bullet.Num 		= 1
	bullet.Src 		= self.Owner:GetShootPos()			// Source
	bullet.Dir 		= self.Owner:GetAimVector()			// Dir of bullet
	bullet.Spread 	= Vector( aimcone, aimcone, 0 )		// Aim Cone
	bullet.Tracer	= 1									// Show a tracer on every x bullets 
	bullet.Force	= 0								// Amount of force to give to phys objects
	bullet.Damage	= damage
	bullet.AmmoType = "none"
	bullet.HullSize = 2
	bullet.TracerName = "laserdancehealer"
	bullet.Callback = function(att, tr, dmginfo)
		if tr["Hit"] then
			if IsValid(tr["Entity"]) and IsValid(att) then
				if tr["Entity"]:GetClass() == "player" then
					-- Networked healing
					net.Start("LaserDanceHeal")
						net.WriteEntity( tr["Entity"] )
					net.SendToServer()
				end
			end
		end
		
		dmginfo:SetDamage( 0 )
		dmginfo:SetDamageCustom( 0 )
		dmginfo:SetDamageForce( Vector(0,0,0) )
		dmginfo:SetDamageBonus( 0 )
		dmginfo:SetMaxDamage( 0 )
	end
	
	self.Owner:FireBullets( bullet )
	
	self:ShootEffects()
	
end