class ScriptObject : plAngelScriptClass
{
    bool RadialShatter = true;
    int MaxImpacts = 10;
    private int Counter = 0;

    void OnImpact(plVec3 pos, plVec3 dir, bool radial, float size)
    {
        ++Counter;

        plJoltBreakableSlabComponent@ slab;
        if (GetOwner().TryGetComponentOfBaseType(@slab))
        {
            slab.ContactReportForceThreshold = 5;
    
            if (Counter < MaxImpacts)
            { 
                if (RadialShatter && radial)
                    slab.ShatterRadial(pos, size, dir, 0.5);
                else
                    slab.ShatterCellular(pos, size, dir, 1.0);
            }
            else
            {
                slab.ShatterAll(0.5, dir * 0.5);
            }
        }
    }
    
    void OnMsgDamage(plMsgDamage@ msg) 
    {
        OnImpact(msg.GlobalPosition, msg.ImpactDirection * msg.Damage * 0.5, true, 0.15);
     }

     void OnMsgPhysicContact(plMsgPhysicContact@ msg)
     {
        OnImpact(msg.GlobalPosition, msg.Normal * plMath::Sqrt(msg.ImpactSqr), true, 0.4);
     }

     void OnMsgPhysicCharacterContact(plMsgPhysicCharacterContact@ msg)
     {
        OnImpact(msg.GlobalPosition, msg.Normal * msg.Impact, false, 0.4);
     }
}