class ScriptObject :  plAngelScriptClass
{
    private float distance = 0;

    void OnMsgGenericEvent(plMsgGenericEvent@ msg)
    {
        if (msg.Message == "RaycastChanged")
        {
            plGameObject@ beamObj = GetOwner().FindChildByName("Beam");

            plRaycastComponent@ rayComp;
            if (beamObj.TryGetComponentOfBaseType(@rayComp))
            {
                const float newDist = rayComp.GetCurrentDistance();
                if (newDist < distance - 0.01)
                {
                    // allow some slack
                    Explode();
                }

                distance = newDist;
            }
        }
    }

    void Explode()
    {
        plGameObject@ exp = GetOwner().FindChildByName("Explosion");

        if (@exp != null)
        {
            plSpawnComponent@ spawnExpl;
            if (exp.TryGetComponentOfBaseType(@spawnExpl))
            {
                spawnExpl.TriggerManualSpawn(true, plVec3::MakeZero());
            }
        }

        GetWorld().DeleteObjectDelayed(GetOwner().GetHandle());
    }

    void OnMsgDamage(plMsgDamage@ msg)
    {
        // explode on any damage
        Explode();
    }
}

