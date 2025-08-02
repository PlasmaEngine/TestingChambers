shared class MsgSwitchMonitor : plAngelScriptMessage
{
    plString renderTarget;
    plString screenMaterial;
}

class Monitor : plAngelScriptClass
{
    void OnMsgSwitchMonitor(MsgSwitchMonitor@ msg)
    {
        auto display = GetOwner().FindChildByName("Display");

        plMsgSetMeshMaterial mat;
        mat.MaterialSlot = 0;
        mat.Material = msg.screenMaterial;

        display.SendMessage(mat);

        plRenderTargetActivatorComponent@ activator;
        if (display.TryGetComponentOfBaseType(@activator))
        {
            activator.RenderTarget = msg.renderTarget;
        }
    }
}

