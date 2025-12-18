enum BallMineState
{
    Init,
    Idle,
    Alert,
    Approaching,
    Attacking
}

class ScriptObject : plAngelScriptClass
{
    float AlertDistance = 15;
    float ApproachDistance = 10;
    float AttackDistance = 1.5;
    float RollForce = 40;
    float Health = 20;
    
    private plGameObjectHandle _player;
    private BallMineState _state = BallMineState::Init;
    private uint32 _forceID = 0;
 
    void OnSimulationStarted()
    {
        plGameObject@ obj;
        if (GetWorld().TryGetObjectWithGlobalKey("Player", obj))
        {
            _player = obj.GetHandle();
        }

        Update(plTime::MakeZero());
    }

    bool QueryForNPC(plGameObject@ go)
    {
         // just accept the first object that was found
         _player = go.GetHandle();
         return false;
    }

    void Update(plTime deltaTime)
    {
        auto oldState = _state;
        auto owner = GetOwner();

        if (_player.IsInvalidated())
        {
            plSpatial::FindObjectsInSphere("Player", owner.GetGlobalPosition(), AlertDistance, ReportObjectCB(QueryForNPC));
            return;
        }

        plGameObject@ playerObj;
        if (GetWorld().TryGetObject(_player, playerObj))
        {
            auto playerPos = playerObj.GetGlobalPosition();
            auto ownPos = GetOwner().GetGlobalPosition();
            auto diffPos = playerPos - ownPos;
            auto distToPlayer = diffPos.GetLength();

            // plLog::Info("Distance to Player: {}", distToPlayer);

            if (distToPlayer <= ApproachDistance) 
            {
                _state = BallMineState::Approaching;

                plJoltDynamicActorComponent@ actor;
                if (GetOwner().TryGetComponentOfBaseType(@actor))
                {
                    diffPos.Normalize();
                    diffPos *= RollForce;

                    _forceID = actor.AddOrUpdateForce(_forceID, plTime::Seconds(0.5), diffPos);
                }
            }
            else if (distToPlayer <= AlertDistance)
            {
                _state = BallMineState::Alert;
            }
            else
            {
                _state = BallMineState::Idle;
            }

            if (distToPlayer <= AttackDistance)
            {
                _state = BallMineState::Attacking;
            }
        }
        else
        {
            _state = BallMineState::Idle;
            _player.Invalidate();
        }

        if (oldState != _state)
        {
            switch (_state)
            {
            case BallMineState::Idle:
                {
                    plMsgSetMeshMaterial matMsg;
                    matMsg.Material = "{ d615cd66-0904-00ca-81f9-768ff4fc24ee }";
                    GetOwner().SendMessageRecursive(matMsg);

                    SetUpdateInterval(plTime::MakeFromMilliseconds(1000));
                    return;
                }
            case BallMineState::Alert:
                {
                    plMsgSetMeshMaterial matMsg;
                    matMsg.Material = "{ 6ae73fcf-e09c-1c3f-54a8-8a80498519fb }";
                    GetOwner().SendMessageRecursive(matMsg);

                    SetUpdateInterval(plTime::MakeFromMilliseconds(500));
                    return;
                }
            case BallMineState::Approaching:
                {
                    plMsgSetMeshMaterial matMsg;
                    matMsg.Material = "{ 49324140-a093-4a75-9c6c-efde65a39fc4 }";
                    GetOwner().SendMessageRecursive(matMsg);

                    SetUpdateInterval(plTime::MakeFromMilliseconds(50));
                    return;
                }
            case BallMineState::Attacking:
                {
                    Explode();
                    return;
                }
            }
        }
    }

    void Explode()
    {
        plSpawnComponent@ spawnExpl;
        if (GetOwner().TryGetComponentOfBaseType(@spawnExpl))
        {
            spawnExpl.TriggerManualSpawn(true, plVec3::MakeZero());
        }

        GetWorld().DeleteObjectDelayed(GetOwner().GetHandle());
    }

    void OnMsgDamage(plMsgDamage@ msg)
    {
        if (Health > 0) 
        {
            Health -= msg.Damage;

            if (Health <= 0)
            {
                Explode();
            }
        }
    }
}