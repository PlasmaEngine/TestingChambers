#include "GameDecls.as"

class UnlockWeapon : plAngelScriptClass
{
    int weaponType = 0;

    void OnMsgTriggerTriggered(plMsgTriggerTriggered@ msg)
    {
        if (msg.TriggerState == plTriggerState::Activated && msg.Message == "Pickup")
        {
            MsgUnlockWeapon hm;
            hm.weaponType = WeaponType(weaponType);

            GetWorld().SendMessageRecursive(msg.GameObject, hm);

            if (!hm.return_consumed)
                return;

            plFmodEventComponent@ sound;
            if (GetOwner().TryGetComponentOfBaseType(@sound))
                sound.StartOneShot();

            // delete yourself
            plMsgDeleteGameObject del;
            GetOwner().PostMessage(del, plTime::Seconds(0.1));
        }
    }
}

