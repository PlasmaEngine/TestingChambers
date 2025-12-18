class ScriptObject : plAngelScriptClass
{
    float Health = 50;
    private uint8 CollisionLayer = 0;

    private plGameObjectHandle target;
    private plComponentHandle gunSpawn;
    private plComponentHandle gunSound;

    void OnMsgDamage(plMsgDamage@ msg)
    {
        if (Health <= 0)
            return;

        Health -= msg.Damage;

        if (Health > 0)
            return;

        SetUpdateInterval(plTime::Seconds(60)); // basically deactivate future updates

        auto expObj = GetOwner().FindChildByName("Explosion", true);
        if (@expObj == null)
            return;

        plSpawnComponent@ spawnComp;
        if (expObj.TryGetComponentOfBaseType(@spawnComp))
        {
            spawnComp.TriggerManualSpawn(true, plVec3::MakeZero());
        }
    }

    void OnSimulationStarted()
    {
        SetUpdateInterval(plTime::Milliseconds(500));

        CollisionLayer = plPhysics::GetCollisionLayerByName("Visibility Raycast");

        auto gunObj = GetOwner().FindChildByName("Gun", true);

        plSpawnComponent@ gunSpawnComp;
        if (gunObj.TryGetComponentOfBaseType(@gunSpawnComp))
            gunSpawn = gunSpawnComp.GetHandle();

        plFmodEventComponent@ gunSoundComp;
        if (gunObj.TryGetComponentOfBaseType(@gunSoundComp))
            gunSound = gunSoundComp.GetHandle();
    }

    bool FoundObjectCallback(plGameObject@ go)
    {
        target = go.GetHandle();
        return false;
    }

    void Update(plTime deltaTime)
    {
        if (Health <= 0)
            return;

        if (gunSpawn.IsInvalidated())
            return;

        plGameObject@ owner = GetOwner();

        target.Invalidate();
        plSpatial::FindObjectsInSphere("Player", owner.GetGlobalPosition(), 15, ReportObjectCB(FoundObjectCallback));

        plGameObject@ targetObj;
        if (!GetWorld().TryGetObject(target, @targetObj))
        {
            SetUpdateInterval(plTime::Milliseconds(500));
            return;
        }

        plVec3 dirToTarget = targetObj.GetGlobalPosition() - owner.GetGlobalPosition();

        const float distance = dirToTarget.GetLengthAndNormalize();

        plVec3 vHitPosition;
        plVec3 vHitNormal;
        plGameObjectHandle HitObject;

        if (plPhysics::Raycast(vHitPosition, vHitNormal, HitObject, owner.GetGlobalPosition(), dirToTarget * distance, CollisionLayer, plPhysicsShapeType::Static))
        {
            // obstacle in the way
            return;
        }

        SetUpdateInterval(plTime::Milliseconds(50));

        plQuat targetRotation = plQuat::MakeShortestRotation(plVec3::MakeAxisX(), dirToTarget);

        plQuat newRotation = plQuat::MakeSlerp(owner.GetGlobalRotation(), targetRotation, 0.1);

        owner.SetGlobalRotation(newRotation);

        dirToTarget.Normalize();

        if (dirToTarget.Dot(owner.GetGlobalDirForwards()) > plMath::Cos(plAngle::MakeFromDegree(15)))
        {
            plSpawnComponent@ gunSpawnComp;
            if (GetWorld().TryGetComponent(gunSpawn, @gunSpawnComp))
            {
                gunSpawnComp.ScheduleSpawn();
            }

            plFmodEventComponent@ gunSoundComp;
            if (GetWorld().TryGetComponent(gunSound, @gunSoundComp))
            {
                gunSoundComp.StartOneShot();
            }
        }
    }
}

