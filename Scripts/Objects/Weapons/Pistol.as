#include "Weapon.as"
#include "../../Gameplay/GameDecls.as"

class Pistol : WeaponBaseClass
{
    private plTime nextAmmoPlus1Time;

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

        plClock@ clk = GetWorld().GetClock();
        nextAmmoPlus1Time = clk.GetAccumulatedTime() + plTime::Seconds(0.75);
        msg.weaponInfo.iAmmoInClip -= 1;

        spawn.TriggerManualSpawn(false, plVec3::MakeZero());

        PlayShootSound();
    }

    void UpdateWeapon(MsgWeaponInteraction@ msg) override
    {
        plClock@ clk = GetWorld().GetClock();
        if (nextAmmoPlus1Time <= clk.GetAccumulatedTime())
        {
            nextAmmoPlus1Time = clk.GetAccumulatedTime() + plTime::Seconds(0.75);

            msg.weaponInfo.iAmmoInClip = plMath::Min(msg.weaponInfo.iAmmoInClip + 1, msg.weaponInfo.iClipSize);
        }
    }
}