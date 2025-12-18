class ScriptObject :  plAngelScriptClass
{
    private bool ragdollFinished = false;

    void OnMsgDamage(plMsgDamage@ msg)
    {
        if (ragdollFinished)
            return;
            
        plJoltHitboxComponent@ col;
        if (GetOwner().TryGetComponentOfBaseType(@col))
        {
            // if present, deactivate the bone collider component, it isn't needed anymore
            col.Active = false;
        }
        
        plJoltDynamicActorComponent@ da;
        if (GetOwner().TryGetComponentOfBaseType(@da))
        {
            // if present, deactivate the dynamic actor component, it isn't needed anymore
            da.Active = false;
        }            
        
        plJoltRagdollComponent@ rdc;
        if (GetOwner().TryGetComponentOfBaseType(@rdc))
        {
            if (rdc.IsActiveAndSimulating())
            {
                ragdollFinished = true;
                return;
            }

            rdc.StartMode = plJoltRagdollStartMode::WithCurrentMeshPose;
            rdc.Active = true;

            // we want the ragdoll to get a kick, so send an impulse message
            plMsgPhysicsAddImpulse imp;
            imp.Impulse = msg.ImpactDirection;
            imp.Impulse *= plMath::Min(msg.Damage, 5) * 10;
            imp.GlobalPosition = msg.GlobalPosition;
            rdc.SendMessage(imp);
        }
    }
}

