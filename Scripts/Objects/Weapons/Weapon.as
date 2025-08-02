#include "../../Gameplay/GameDecls.as"

abstract class WeaponBaseClass : plAngelScriptClass
{
    protected bool singleShotPerTrigger = false;
    private bool requireSingleShotReset = false;

    void OnSimulationStarted()
    {
        HolsterWeapon();
    }

    void OnMsgGunInteraction(MsgWeaponInteraction@ msg)
    {
        switch(msg.interaction)
        {
        case WeaponInteraction::Fire:
            {
                if (msg.keyState == plTriggerState::Deactivated)
                {
                    requireSingleShotReset = false;
                    return;
                }

                if (msg.weaponInfo.iAmmoInClip <= 0)
                {
                    FireEmptyWeapon(msg);
                    return;
                }
    
                if (singleShotPerTrigger)
                {
                    if (msg.keyState == plTriggerState::Activated)
                    {
                        if (!requireSingleShotReset)
                        {
                            requireSingleShotReset = true;
                            FireWeapon(msg);
                        }
                    }
                }
                else
                {
                    FireWeapon(msg);
                }

                break;
            }
        case WeaponInteraction::DrawWeapon:
            DrawWeapon();
            break;
        case WeaponInteraction::HolsterWeapon:
            HolsterWeapon();
            break;

        case WeaponInteraction::Reload:
            if (msg.weaponInfo.iAmmoInClip >= msg.weaponInfo.iClipSize)
                return;
    
            Reload(msg);
            break;

        case WeaponInteraction::Update:
            UpdateWeapon(msg);
            break;
        }
    }

    void FireWeapon(MsgWeaponInteraction@ msg)
    {
        // abstract
    }

    void FireEmptyWeapon(MsgWeaponInteraction@ msg)
    {
        // override this function to make an empty gun sound or something like that
        Reload(msg);
    }

    void PlayShootSound()
    {
        auto owner = GetOwner();

        auto node = owner.FindChildByName("ShootSound", true);
        if (@node != null)
        {
            plFmodEventComponent@ fmodComp;
            if (node.TryGetComponentOfBaseType(@fmodComp))
            {
                fmodComp.StartOneShot();
            }
        }

        @node = owner.FindChildByName("Muzzleflash", true);
        if (@node != null)
        {
            plParticleComponent@ particleComp;
            if (node.TryGetComponentOfBaseType(@particleComp))
            {
                particleComp.StartEffect();
            }
        }
    }

    void DrawWeapon()
    {
        auto graphics = GetOwner().FindChildByName("Graphics", true);

        if (@graphics == null)
            return;

        graphics.SetActiveFlag(true);
    }

    void HolsterWeapon()
    {
        auto graphics = GetOwner().FindChildByName("Graphics", true);

        if (@graphics == null)
            return;

        graphics.SetActiveFlag(false);
    }    

    void Reload(MsgWeaponInteraction@ msg)
    {
        if (msg.weaponInfo.eAmmoType == ConsumableType::Ammo_None)
            return;

        int needed = msg.weaponInfo.iClipSize - msg.weaponInfo.iAmmoInClip;
        int take = plMath::Min(needed, msg.ammoPouch.getAmmoType(msg.weaponInfo.eAmmoType));

        msg.ammoPouch.getAmmoType(msg.weaponInfo.eAmmoType) -= take;
        msg.weaponInfo.iAmmoInClip += take;
    }

    void UpdateWeapon(MsgWeaponInteraction@ msg)
    {
        plVec2 resolution = plDebug::GetResolution();
        plVec2 screenCenter = resolution;
        screenCenter *= 0.5;

        plColor col = plColor::White;

        float w = 10.0f;
        plVec3 start = plVec3(screenCenter.x, screenCenter.y - w, 0);
        plVec3 end = plVec3(screenCenter.x, screenCenter.y + w, 0);
        plDebug::Draw2DLine(start, end, col, col);
        
        start = plVec3(screenCenter.x - w, screenCenter.y, 0);
        end = plVec3(screenCenter.x + w, screenCenter.y, 0);
        plDebug::Draw2DLine(start, end, col, col);
    }
}
