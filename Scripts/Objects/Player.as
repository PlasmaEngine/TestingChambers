#include "../Gameplay/GameDecls.as"
#include "Weapons/Weapon.as"

class Player : plAngelScriptClass
{
    bool GiveAllWeapons = false;
    bool Invincible = false;

    private plGameObjectHandle hCameraObj;
    private plComponentHandle hCharacterComp;
    private plComponentHandle hInputComp;
    private plComponentHandle hGrabComp;
    private plGameObjectHandle hFlashlightObj;
    private plGameObjectHandle hDamageIndicatorObj;

    private array<WeaponInfo> weaponInfos(WeaponType::COUNT);


    private int iPlayerHealth = 100;
    private float fDamageIndicatorValue = 0;
    private bool bRequireNoShoot = false;
    private WeaponType eActiveWeapon = WeaponType::None;
    private WeaponType eHolsteredWeapon = WeaponType::None;
    private AmmoPouch ammoPouch;

    void OnSimulationStarted()
    {
        auto owner = GetOwner();

        hCameraObj = owner.FindChildByName("Camera", true).GetHandle();
        hFlashlightObj = owner.FindChildByName("Flashlight", true).GetHandle();
        hDamageIndicatorObj = owner.FindChildByName("DamageIndicator").GetHandle();
        plGameObject@ grabObj = owner.FindChildByName("GrabObject", true);

        weaponInfos[WeaponType::Pistol].hObject = owner.FindChildByName("Pistol", true).GetHandle();
        weaponInfos[WeaponType::Shotgun].hObject = owner.FindChildByName("Shotgun", true).GetHandle();
        weaponInfos[WeaponType::MachineGun].hObject = owner.FindChildByName("MachineGun", true).GetHandle();
        weaponInfos[WeaponType::PlasmaRifle].hObject = owner.FindChildByName("PlasmaRifle", true).GetHandle();
        weaponInfos[WeaponType::RocketLauncher].hObject = owner.FindChildByName("RocketLauncher", true).GetHandle();

        weaponInfos[WeaponType::Pistol].eAmmoType = ConsumableType::Ammo_None;
        weaponInfos[WeaponType::Shotgun].eAmmoType = ConsumableType::Ammo_Shotgun;
        weaponInfos[WeaponType::MachineGun].eAmmoType = ConsumableType::Ammo_MachineGun;
        weaponInfos[WeaponType::PlasmaRifle].eAmmoType = ConsumableType::Ammo_Plasma;
        weaponInfos[WeaponType::RocketLauncher].eAmmoType = ConsumableType::Ammo_Rocket;

        weaponInfos[WeaponType::Pistol].iClipSize = 8;
        weaponInfos[WeaponType::Shotgun].iClipSize = 8;
        weaponInfos[WeaponType::MachineGun].iClipSize = 30;
        weaponInfos[WeaponType::PlasmaRifle].iClipSize = 30;
        weaponInfos[WeaponType::RocketLauncher].iClipSize = 3;

        if (GiveAllWeapons)
        {
            weaponInfos[WeaponType::Pistol].bUnlocked = true;
            weaponInfos[WeaponType::Shotgun].bUnlocked = true;
            weaponInfos[WeaponType::MachineGun].bUnlocked = true;
            weaponInfos[WeaponType::PlasmaRifle].bUnlocked = true;
            weaponInfos[WeaponType::RocketLauncher].bUnlocked = true;

            ammoPouch.AmmoMachineGun = 9999;
            ammoPouch.AmmoPistol = 9999;
            ammoPouch.AmmoPlasmaRifle = 9999;
            ammoPouch.AmmoRocketLauncher = 9999;
            ammoPouch.AmmoShotgun = 9999;
        }

        plJoltDefaultCharacterComponent@ characterComp;
        if (owner.TryGetComponentOfBaseType(@characterComp))
        {
            hCharacterComp = characterComp.GetHandle();
        }

        plInputComponent@ inputComp;
        if (owner.TryGetComponentOfBaseType(@inputComp))
        {
            hInputComp = inputComp.GetHandle();
        }

        if (@grabObj != null)
        {
            plJoltGrabObjectComponent@ grabComp;
            if (grabObj.TryGetComponentOfBaseType(@grabComp))
            {
                hGrabComp = grabComp.GetHandle();
            }
        }
    }

    void Update(plTime deltaTime)
    {
        plGameObject@ cameraObj;
        if (!GetWorld().TryGetObject(hCameraObj, @cameraObj))
            return;

        plJoltDefaultCharacterComponent@ characterComp;
        if (!GetWorld().TryGetComponent(hCharacterComp, @characterComp))
            return;

        plInputComponent@ inputComp;
        if (!GetWorld().TryGetComponent(hInputComp, @inputComp))
            return;

        if (!weaponInfos[WeaponType::None].bUnlocked)
        {
            weaponInfos[WeaponType::None].bUnlocked = true;
            weaponInfos[WeaponType::Pistol].bUnlocked = true;

            // weapon to start with
            SwitchToWeapon(WeaponType::Pistol);
        }

        
        if (iPlayerHealth > 0)
        {
            plStringBuilder text;
            text.SetFormat("Health: {}", plMath::Ceil(iPlayerHealth));
            plDebug::DrawInfoText(text, plDebugTextPlacement::TopLeft, "Player", plColor::White);
            
            if (eActiveWeapon != WeaponType::None)
            {
                WeaponInfo@ weaponInfo = weaponInfos[eActiveWeapon];

                if (weaponInfo.eAmmoType == ConsumableType::Ammo_None)
                {
                    text.SetFormat("Ammo: {}", weaponInfo.iAmmoInClip);
                    plDebug::DrawInfoText(text, plDebugTextPlacement::TopLeft, "Player", plColor::White);
                }
                else
                {
                    const int ammoOfType = ammoPouch.getAmmoType(weaponInfo.eAmmoType);
                    text.SetFormat("Ammo: {} / {}", weaponInfo.iAmmoInClip, ammoOfType);
                    plDebug::DrawInfoText(text, plDebugTextPlacement::TopLeft, "Player", plColor::White);
                }
    
                MsgWeaponInteraction msgInteract;
                @msgInteract.ammoPouch = @ammoPouch;
                @msgInteract.weaponInfo = @weaponInfo;
                msgInteract.interaction = WeaponInteraction::Update;
                GetWorld().SendMessageRecursive(weaponInfo.hObject, msgInteract);
            }            

            // character controller update
            {
                plMsgMoveCharacterController msgMove;
                msgMove.Jump = inputComp.GetCurrentInputState("Jump", true) > 0.5;
                msgMove.MoveForwards = inputComp.GetCurrentInputState("MoveForwards", false);
                msgMove.MoveBackwards = inputComp.GetCurrentInputState("MoveBackwards", false);
                msgMove.StrafeLeft = inputComp.GetCurrentInputState("StrafeLeft", false);
                msgMove.StrafeRight = inputComp.GetCurrentInputState("StrafeRight", false);
                msgMove.RotateLeft = inputComp.GetCurrentInputState("RotateLeft", false);
                msgMove.RotateRight = inputComp.GetCurrentInputState("RotateRight", false);
                msgMove.Run = inputComp.GetCurrentInputState("Run", false) > 0.5;
                msgMove.Crouch = inputComp.GetCurrentInputState("Crouch", false) > 0.5;

                GetOwner().SendMessageRecursive(msgMove);
                
                // look up / down
                plHeadBoneComponent@ headBoneComp;
                if (cameraObj.TryGetComponentOfBaseType(@headBoneComp))
                {
                    float up = inputComp.GetCurrentInputState("LookUp", false);
                    float down = inputComp.GetCurrentInputState("LookDown", false);
                    
                    headBoneComp.ChangeVerticalRotation(down - up);
                }

                plBlackboardComponent@ blackboardComp;
                if (GetOwner().TryGetComponentOfBaseType(@blackboardComp))
                {
                    // this is used to control the animation playback on the 'shadow proxy' mesh
                    // currently we only sync basic movement
                    // also note that the character mesh currently doesn't have crouch animations
                    // so we can't have a proper shadow there

                    blackboardComp.SetEntryValue("MoveForwards", msgMove.MoveForwards);
                    blackboardComp.SetEntryValue("MoveBackwards", msgMove.MoveBackwards);
                    blackboardComp.SetEntryValue("StrafeLeft", msgMove.StrafeLeft);
                    blackboardComp.SetEntryValue("StrafeRight", msgMove.StrafeRight);
                    blackboardComp.SetEntryValue("TouchingGround", characterComp.IsStandingOnGround());
                }
            }

            // reduce damage indicator value over time
            fDamageIndicatorValue = plMath::Max(fDamageIndicatorValue - GetWorld().GetClock().GetTimeDiff().AsFloatInSeconds(), 0);
        }
        else
        {
            fDamageIndicatorValue = 3;
        }

        if (!hDamageIndicatorObj.IsInvalidated())
        {
            plMsgSetColor msg;
            msg.Color = plColor(1, 1, 1, fDamageIndicatorValue);

            GetWorld().SendMessage(hDamageIndicatorObj, msg);
        }
    }

    void OnMsgInputActionTriggered(plMsgInputActionTriggered@ msg)
    {
        if (iPlayerHealth <= 0)
            return;

        if (msg.TriggerState == plTriggerState::Activated)
        {
            plJoltGrabObjectComponent@ grabComp;
            if (!GetWorld().TryGetComponent(hGrabComp, @grabComp))
                return;

            if (msg.InputAction == "SwitchWeapon0")
                SwitchToWeapon(WeaponType::None);

            if (msg.InputAction == "SwitchWeapon1")
                SwitchToWeapon(WeaponType::Pistol);

            if (msg.InputAction == "SwitchWeapon2")
                SwitchToWeapon(WeaponType::Shotgun);

            if (msg.InputAction == "SwitchWeapon3")
                SwitchToWeapon(WeaponType::MachineGun);

            if (msg.InputAction == "SwitchWeapon4")
                SwitchToWeapon(WeaponType::PlasmaRifle);

            if (msg.InputAction == "SwitchWeapon5")
                SwitchToWeapon(WeaponType::RocketLauncher);

            if (msg.InputAction == "Flashlight")
            {
                plGameObject@ flashlightObj;
                if (GetWorld().TryGetObject(hFlashlightObj, @flashlightObj))
                {
                    plSpotLightComponent@ flashLightComp;
                    if (flashlightObj.TryGetComponentOfBaseType(@flashLightComp))
                    {
                        flashLightComp.Active = !flashLightComp.Active;
                    }
                }
            }

            if (msg.InputAction == "Use")
            {
                plGameObject@ cameraObj;
                if (!GetWorld().TryGetObject(hCameraObj, @cameraObj))
                    return;
        
                if (grabComp.HasObjectGrabbed())
                {
                    grabComp.DropGrabbedObject();
                    SwitchToWeapon(eHolsteredWeapon);
                }
                else if (grabComp.GrabNearbyObject())
                {
                    eHolsteredWeapon = eActiveWeapon;
                    SwitchToWeapon(WeaponType::None);
                }
                else
                {
                    plVec3 vHitPosition;
                    plVec3 vHitNormal;
                    plGameObjectHandle hHitObject;

                    if (plPhysics::Raycast(vHitPosition, vHitNormal, hHitObject, cameraObj.GetGlobalPosition(), cameraObj.GetGlobalDirForwards() * 2.0, plPhysics::GetCollisionLayerByName("Interaction Raycast"), plPhysicsShapeType(plPhysicsShapeType::Static | plPhysicsShapeType::Dynamic)))
                    {
                        plMsgGenericEvent msgUse;
                        msgUse.Message = "Use";

                        plGameObject@ hitObj;
                        if (GetWorld().TryGetObject(hHitObject, @hitObj))
                        {
                            hitObj.SendEventMessage(msgUse, GetOwnerComponent());
                        }
                    }
                }
            }

            if (eActiveWeapon != WeaponType::None && msg.InputAction == "Reload")
            {
                WeaponInfo@ weaponInfo = weaponInfos[eActiveWeapon];

                MsgWeaponInteraction msgInteract;
                msgInteract.keyState = msg.TriggerState;
                @msgInteract.ammoPouch = @ammoPouch;
                @msgInteract.weaponInfo = @weaponInfo;
                msgInteract.interaction = WeaponInteraction::Reload;

                GetWorld().SendMessageRecursive(weaponInfo.hObject, msgInteract);
            }

            if (msg.InputAction == "Teleport")
            {
                plJoltDefaultCharacterComponent@ characterComp;
                if (GetWorld().TryGetComponent(hCharacterComp, @characterComp))
                {
                    plVec3 pos = GetOwner().GetGlobalPosition();
                    plVec3 dir = GetOwner().GetGlobalDirForwards();
                    dir.z = 0;
                    pos += dir.GetNormalized() * 5.0f;

                    characterComp.TeleportCharacter(pos);
                }
            }
        }

        if (msg.InputAction == "Shoot")
        {
            if (bRequireNoShoot)
            {
                if (msg.TriggerState == plTriggerState::Activated)
                {
                    bRequireNoShoot = false;
                }
            }

            if (!bRequireNoShoot)
            {
                plJoltGrabObjectComponent@ grabComp;
                if (!GetWorld().TryGetComponent(hGrabComp, @grabComp))
                    return;

                if (grabComp.HasObjectGrabbed())
                {
                    plVec3 dir(1.0, 0, 0);

                    grabComp.ThrowGrabbedObject(dir, plPhysics::GetImpulseTypeByName("Throw Object"));

                    SwitchToWeapon(eHolsteredWeapon);
                }
                else
                {
                    WeaponInfo@ weaponInfo = weaponInfos[eActiveWeapon];

                    MsgWeaponInteraction msgInteract;
                    msgInteract.keyState = msg.TriggerState;
                    @msgInteract.ammoPouch = @ammoPouch;
                    @msgInteract.weaponInfo = @weaponInfo;
                    msgInteract.interaction = WeaponInteraction::Fire;

                    GetWorld().SendMessageRecursive(weaponInfo.hObject, msgInteract);
                }
            }
        }
    }

    void OnMsgMsgDamage(plMsgDamage@ msg)
    {
        if (Invincible)
            return;

        if (iPlayerHealth <= 0)
            return;

        iPlayerHealth -= int(msg.Damage * 2);

        fDamageIndicatorValue = plMath::Min(fDamageIndicatorValue + msg.Damage * 0.2f, 2.0f);
        
		if (iPlayerHealth <= 0)
        {
            plLog::Warning("Player died.");

            plJoltDefaultCharacterComponent@ characterComp;
            if (GetWorld().TryGetComponent(hCharacterComp, @characterComp))
            {
                // deactivate the character controller, so that it isn't in the way
                characterComp.Active = false;
            }

            auto owner = GetOwner();
            auto cameraObj = owner.FindChildByName("Camera");
            auto camPos = cameraObj.GetGlobalPosition();

            plGameObjectDesc go;
            go.m_LocalPosition = cameraObj.GetGlobalPosition();
            go.m_bDynamic = true;

            plGameObject@ rbCam;
            GetWorld().CreateObject(go, rbCam);
            rbCam.UpdateGlobalTransform();

            plJoltDynamicActorComponent@ rbCamActor;
            rbCam.CreateComponent(@rbCamActor);

            plJoltShapeSphereComponent@ rbCamSphere;
            rbCam.CreateComponent(@rbCamSphere);
            rbCamSphere.Radius = 0.3;

            plPointLightComponent@ rbCamLight;
            rbCam.CreateComponent(@rbCamLight);
            rbCamLight.LightColor = plColor::DarkRed;
            rbCamLight.Intensity = 200;

            rbCamActor.Mass = 30;
            rbCamActor.LinearDamping = 0.7;
            rbCamActor.AngularDamping = 0.9;
            rbCamActor.CollisionLayer = plPhysics::GetCollisionLayerByName("Default");
            rbCamActor.AddAngularImpulse(10 * plVec3::MakeRandomPointInSphere(GetWorld().GetRandomNumberGenerator()));

            cameraObj.SetParent(rbCam.GetHandle());
         }
    }

    void SwitchToWeapon(WeaponType weapon)
    {
        if (eActiveWeapon == weapon)
            return;

        if (weapon != WeaponType::None)
        {
            plJoltGrabObjectComponent@ grabComp;
            if (GetWorld().TryGetComponent(hGrabComp, @grabComp))
            {
                if (grabComp.HasObjectGrabbed())
                    return;
            }
        }

        WeaponInfo@ infoNew = weaponInfos[weapon];

        if (!infoNew.bUnlocked)
            return;

        WeaponInfo@ infoOld = weaponInfos[eActiveWeapon];

        bRequireNoShoot = true;

        MsgWeaponInteraction msg;

        msg.interaction = WeaponInteraction::HolsterWeapon;
        GetWorld().SendMessage(infoOld.hObject, msg);

        msg.interaction = WeaponInteraction::DrawWeapon;
        GetWorld().SendMessage(infoNew.hObject, msg);

         eActiveWeapon = weapon;
    }

    void OnMsgUnlockWeapon(MsgUnlockWeapon@ msg)
    {
        msg.return_consumed = true;

        WeaponInfo@ wi = weaponInfos[msg.weaponType];

        if (wi.bUnlocked == false)
        {
            wi.bUnlocked = true;
            SwitchToWeapon(msg.weaponType);
        }
    }    

    void OnMsgPhysicsJointBroke(plMsgPhysicsJointBroke@ msg)
    {
        // must be the 'object grabber' joint
        SwitchToWeapon(eHolsteredWeapon);
    }

    int GetMaxConsumableAmount(ConsumableType type) const
    {
        switch (type)
        {
        case ConsumableType::Health:
            return 100;
        case ConsumableType::Ammo_Pistol:
            return 50;
        case ConsumableType::Ammo_Shotgun:
            return 40;
        case ConsumableType::Ammo_MachineGun:
            return 150;
        case ConsumableType::Ammo_Plasma:
            return 100;
        case ConsumableType::Ammo_Rocket:
            return 20;
        }
    
        throw("Missing Case");
        return 0;
    }

    void OnMsgAddConsumable(MsgAddConsumable@ msg)
    {
        const int maxAmount = GetMaxConsumableAmount(msg.consumableType);

        if (msg.consumableType == ConsumableType::Health)
        {
            if (iPlayerHealth <= 0 || iPlayerHealth >= maxAmount)
                return;

            msg.return_consumed = true;

            iPlayerHealth = plMath::Clamp(iPlayerHealth + msg.amount, 1, maxAmount);
            return;
        }

        if (msg.consumableType > ConsumableType::AmmoTypes_Start && msg.consumableType < ConsumableType::AmmoTypes_End)
        {
            const int curAmount = ammoPouch.getAmmoType(msg.consumableType);

            if (curAmount >= maxAmount)
                return;

            msg.return_consumed = true;

            const int newAmount = curAmount + msg.amount;

            ammoPouch.getAmmoType(msg.consumableType) = plMath::Clamp(newAmount, 0, maxAmount);
        }
    }    
}