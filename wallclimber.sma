#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <reapi>

new g_iWallClimber[MAX_PLAYERS + 1] = {0, ...};

public plugin_init()
{
    register_plugin("WallClimber","1.1","Karaulov");
    RegisterHookChain(RG_PM_Move, "PM_Move", .post=false);
    RegisterHookChain(RG_PM_AirMove, "PM_Move", .post =false);
    set_task(0.1,"WallClimbSearch");
}

public plugin_natives()
{
    // При первой активации API , плагин отключается для всех игроков и начинает работать только от API
    register_native("wallclimber_give", "native_wallclimber_give");
    register_native("wallclimber_remove", "native_wallclimber_remove");
}

public native_wallclimber_give()
{
    new id = get_param(1);

    if(id <= 0 || id > MAX_PLAYERS)
    {
        return;
    }

    if (g_iWallClimber[0] == 0)
    {
        for(new i = 1; i < MAX_PLAYERS + 1;i++)
        {
            g_iWallClimber[i] = -1;
        }
    }

    g_iWallClimber[id] = 0;
}

public native_wallclimber_remove()
{
    new id = get_param(1);

    if(id <= 0 || id > MAX_PLAYERS)
    {
        return;
    }

    if (g_iWallClimber[0] == 0)
    {
        for(new i = 1; i < MAX_PLAYERS + 1;i++)
        {
            g_iWallClimber[i] = -1;
        }
    }

    g_iWallClimber[id] = -1;
}

public WallClimbSearch()
{
    for(new i = 1; i < MAX_PLAYERS + 1;i++)
    {
        if (g_iWallClimber[i] == 0)
            g_iWallClimber[i] = 3;
        if (g_iWallClimber[i] == 1)
            g_iWallClimber[i] = 2;
        if (g_iWallClimber[i] == 4)
            g_iWallClimber[i] = 5;
        if (g_iWallClimber[i] == 5)
            g_iWallClimber[i] = 1;
    }
    set_task(0.1,"WallClimbSearch");
}

public PM_Move(const id)
{
    if (g_iWallClimber[id] == 1 || g_iWallClimber[id] == 2)
    {
        new cmd = get_pmove( pm_cmd );
  
        set_pmove(pm_gravity,0.0);
        set_ucmd(cmd, ucmd_forwardmove, 0.0);
        set_ucmd(cmd, ucmd_sidemove, 0.0);
  
        new buttons = get_entvar(id, var_button);
        new Float:flVelocity[3] = {0.0, ...};
  
        new Float:flSpeed = 500.0;
  
        if (buttons & (IN_MOVELEFT|IN_MOVERIGHT))
        {
            entity_get_vector(id,EV_VEC_angles,flVelocity);
            engfunc(EngFunc_MakeVectors,flVelocity);
            new Float:flDirection[3];
            global_get(glb_v_right, flDirection);
            flVelocity[0] = flDirection[0] * (buttons & IN_MOVELEFT ? -flSpeed : flSpeed);
            flVelocity[1] = flDirection[1] * (buttons & IN_MOVELEFT ? -flSpeed : flSpeed);
        }
  
        if (buttons & (IN_FORWARD|IN_BACK))
        {
            flVelocity[2] = buttons & IN_FORWARD ? flSpeed : -flSpeed;
        }
      
        set_pmove(pm_velocity,flVelocity);
  
        if (get_entvar(id,var_flags) & FL_ONGROUND)
        {
            g_iWallClimber[id] = 0;
        }
    }
    if (g_iWallClimber[id] == 6)
    {
        g_iWallClimber[id] = 1;
  
        new Float:flUserOrigin[3];
        get_pmove(pm_origin,flUserOrigin);
  
        if (is_hull_vacant(flUserOrigin))
        {
            flUserOrigin[0] += 16.0;
            if (is_hull_vacant(flUserOrigin))
            {
                flUserOrigin[0] -= 32.0;
                if (is_hull_vacant(flUserOrigin))
                {
                    flUserOrigin[0] += 16.0;
                    flUserOrigin[1] += 16.0;
                    if (is_hull_vacant(flUserOrigin))
                    {
                        flUserOrigin[1] -= 32.0;
                        if (is_hull_vacant(flUserOrigin))
                        {
                            g_iWallClimber[id] = 0;
                        }
                    }
                }
            }
        }
    }
    if (g_iWallClimber[id] == 2)
    {
        g_iWallClimber[id] = 6;
    }
    if (g_iWallClimber[id] == 3 && is_user_alive(id))
    {
        g_iWallClimber[id] = 0;
  
        new iOriginStart[3];
        new iOriginEnd[3];
  
        get_user_origin( id, iOriginStart, Origin_Eyes );
        get_user_origin( id, iOriginEnd, Origin_AimEndEyes );
  
        new iMaxDistance = get_distance(iOriginStart,iOriginEnd);
        if (iMaxDistance < 40)
        {
      
            new Float:fOriginEnd[3];
            fOriginEnd[0] = iOriginEnd[0] * 1.0;
            fOriginEnd[1] = iOriginEnd[1] * 1.0;
            fOriginEnd[2] = iOriginEnd[2] * 1.0;
      
            new Float:flUserOrigin[3];
            get_entvar(id,var_origin,flUserOrigin);
            if (engfunc(EngFunc_PointContents, fOriginEnd) == CONTENTS_EMPTY && !(get_entvar(id,var_flags) & FL_ONGROUND))
            {
                g_iWallClimber[id] = 4;
            }
        }
    }
}

stock bool:is_hull_vacant(const Float:origin[3])
{
    new tr = 0;
    engfunc(EngFunc_TraceHull, origin, origin, IGNORE_MONSTERS, HULL_HUMAN, 0, tr);
    if(!get_tr2(tr, TR_StartSolid) && !get_tr2(tr, TR_AllSolid) && get_tr2(tr, TR_InOpen))
    {
        return true;
    }
    return false;
}
