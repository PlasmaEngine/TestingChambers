class ScriptObject :  plAngelScriptClass
{
    private float capHealth = 5;
    private float bodyHealth = 50;
    private uint32 capForce = 0;

    void OnSimulationStarted()
    {
        // no update needed by default
        SetUpdateInterval(plTime::MakeFromSeconds(10));
    }

    void Update(plTime deltaTime)
    {
        if (capHealth <= 0) 
        {
            auto owner = GetOwner();
            auto cap = owner.FindChildByName("Cap");

            plJoltDynamicActorComponent@ actor;
            if (owner.TryGetComponentOfBaseType(@actor))
            {
                plVec3 force = cap.GetGlobalDirUp();

                auto randomDir = plVec3::MakeRandomDirection(GetWorld().GetRandomNumberGenerator());
                randomDir *= 0.4;
    
                force += randomDir;
                force *= -2;

                actor.AddOrUpdateForce(capForce, plTime::Seconds(0.5f), force);
            }
        }
    }

    void OnMsgDamage(plMsgDamage@ msg)
    {
        bodyHealth -= msg.Damage;

        if (bodyHealth <= 0)
        {
            Explode();
            return;
        }

        if (msg.HitObjectName == "Cap")
        {
            if (capHealth > 0) 
            {
                capHealth -= msg.Damage;

                if (capHealth <= 0) 
                {
                    // update every frame, to apply regularly the physics force
                    SetUpdateInterval(plTime::MakeZero());

                    auto leakObj = GetOwner().FindChildByName("LeakEffect");
                    if (@leakObj != null)
                    {
                        plParticleComponent@ leakFX;
                        if (leakObj.TryGetComponentOfBaseType(@leakFX))
                        {
                            leakFX.StartEffect();
                        }
                        else
                        {
                            plLog::Error("Failed to start particle effect!");
                        }

                        plFmodEventComponent@ leakSound;
                        if (leakObj.TryGetComponentOfBaseType(@leakSound))
                        {
                            leakSound.Play();
                        }
                    }

                    // trigger code path below
                    msg.HitObjectName = "Tick";
                }
            }
        }

        if (msg.HitObjectName == "Tick")
        {
            plMsgDamage tickDmg;
            tickDmg.Damage = 1;
            tickDmg.HitObjectName = "Tick";
            GetOwner().PostMessage(tickDmg, plTime::MakeFromMilliseconds(100));
        }
    }

    void Explode()
    {
        auto owner = GetOwner();
        auto exp = owner.FindChildByName("Explosion");

        if (@exp != null)
        {
            plSpawnComponent@ spawnExpl;
            if (exp.TryGetComponentOfBaseType(@spawnExpl))
            {
                spawnExpl.TriggerManualSpawn(false, plVec3::MakeZero());
            }
        }

        GetWorld().DeleteObjectDelayed(GetOwner().GetHandle());
    }
}
