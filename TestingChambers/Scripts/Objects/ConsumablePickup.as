#include "../Gameplay/GameDecls.as"

class ConsumablePickup : plAngelScriptClass
{
    int ObjectType = 0;
    int Amount = 0;

    void OnMsgTriggerTriggered(plMsgTriggerTriggered@ msg)
    {
        if (msg.TriggerState == plTriggerState::Activated && msg.Message == "Pickup")
        {
            MsgAddConsumable hm;
            hm.consumableType = ConsumableType(ObjectType);
            hm.amount = Amount;

            GetWorld().SendMessageRecursive(msg.GameObject, hm);

            if (hm.return_consumed == false)
                return;

            plFmodEventComponent@ sound;
            if (GetOwner().TryGetComponentOfBaseType(@sound))
            {
                sound.StartOneShot();
            }

            plMsgDeleteGameObject del;
            GetOwner().PostMessage(del, plTime::Seconds(0.1));
        }
    }
}

