class ScriptObject :  plAngelScriptClass
{
    plHashedString ButtonName;

    void OnMsgGenericEvent(plMsgGenericEvent@ msg)
    {
        if (msg.Message != "Use")
            return;
         
        plGameObject@ button = GetOwner().FindChildByName("Button");

        plTransformComponent@ slider;
        if (!button.TryGetComponentOfBaseType(@slider))
            return;

        if (slider.Running)
            return;

        slider.SetDirectionForwards(true);
        slider.Running = true;

        plMsgGenericEvent newMsg;
        newMsg.Message = ButtonName;

        GetOwnerComponent().BroadcastEventMsg(newMsg);
    }
}

