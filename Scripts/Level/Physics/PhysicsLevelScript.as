class ScriptObject :  plAngelScriptClass
{
    void OnMsgTriggerTriggered(plMsgTriggerTriggered@ msg)
    {
        if (msg.Message == "ActivatePaddleWheel")
        {
            if (msg.TriggerState == plTriggerState::Activated) {

                plGameObject@ spawn;
                if (GetWorld().TryGetObjectWithGlobalKey("PaddleWheelSpawn1", @spawn))
                {
                    spawn.SetActiveFlag(true);
                }

            }
            else if (msg.TriggerState == plTriggerState::Deactivated) {

                plGameObject@ spawn;
                if (GetWorld().TryGetObjectWithGlobalKey("PaddleWheelSpawn1", @spawn))
                {
                    spawn.SetActiveFlag(false);
                }

            }
        }

        if (msg.Message == "ActivateSwing") {

            if (msg.TriggerState == plTriggerState::Activated) 
            {
                plGameObject@ spawn;
                if (GetWorld().TryGetObjectWithGlobalKey("SwingSpawn1", @spawn))
                {
                    spawn.SetActiveFlag(true);
                }

            }
            else if (msg.TriggerState == plTriggerState::Deactivated) 
            {
                plGameObject@ spawn;
                if (GetWorld().TryGetObjectWithGlobalKey("SwingSpawn1", @spawn))
                {
                    spawn.SetActiveFlag(false);
                }
            }
        }
    }
}

