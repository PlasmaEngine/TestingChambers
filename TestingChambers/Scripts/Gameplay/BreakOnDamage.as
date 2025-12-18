class ScriptObject : plAngelScriptClass
{
    float Health = 10;

    void OnMsgDamage(plMsgDamage@ msg)
    {
        if (Health <= 0) 
            return;

        Health -= msg.Damage;

        if (Health > 0)
            return;

        auto spawnNode = GetOwner().FindChildByName("OnBreakSpawn");
        if (@spawnNode != null)
        {
            plSpawnComponent@ spawnComp;
            if (spawnNode.TryGetComponentOfBaseType(@spawnComp))
            {
                auto offset = plVec3::MakeRandomPointInSphere(GetWorld().GetRandomNumberGenerator());
                offset *= 0.3;
                spawnComp.TriggerManualSpawn(true, offset);
            }
        }

        GetWorld().DeleteObjectDelayed(GetOwner().GetHandle());
    }
}

