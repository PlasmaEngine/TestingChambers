#include "Weapon.as"
#include "../../Gameplay/GameDecls.as"

class RocketLauncher : WeaponBaseClass
{
    void OnSimulationStarted()
    {
        WeaponBaseClass::OnSimulationStarted();
        
        singleShotPerTrigger = true;
    }

    void FireWeapon(MsgWeaponInteraction@ msg) override
    {
        plSpawnComponent@ spawn;
        if (!GetOwner().FindChildByName("Spawn").TryGetComponentOfBaseType(@spawn))
            return;

        if (!spawn.CanTriggerManualSpawn())
            return;

        msg.weaponInfo.iAmmoInClip -= 1;

        spawn.TriggerManualSpawn(true, plVec3::MakeZero());

        PlayShootSound();
    }
}