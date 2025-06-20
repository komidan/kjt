#include <amxmodx>
#include <fakemeta>
#include <string>

#pragma semicolon 1

#define PLUGIN "komi's TrickJumps"
#define VERSION "0.1u"
#define AUTHOR "komidan"

#define TAG "[KJT]"

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    register_concmd("createjump", "Jump_Create");
    register_concmd("deletejump", "Jump_Delete");
    register_concmd("setjump", "Jump_Set");

    register_event("ResetHUD", "autoload", "b");
}

public Jump_Create(id)
{
    new jumpname[32];
    read_argv(0, jumpname, charsmax(jumpname));

    if (equal(jumpname, ""))
    {
        client_print(id, print_console, "%s Usage: createjump <name>", TAG);
        return PLUGIN_HANDLED;
    }

    new author[32];
    get_user_name(id, author, charsmax(author));

    new Float:origin[3];
    new Float:v_angles[3];

    pev(id, pev_origin, origin);
    pev(id, pev_v_angle, v_angles);

    // TODO: Open file and write a json object containing this information!

    client_print(id, print_console, "%s Jump `%s` created. (%f, %f, %f) yaw: %f, pitch %f", TAG, jumpname, origin[0], origin[1], origin[2], v_angles[1], v_angles[0]);
    return PLUGIN_HANDLED;
}

public Jump_Delete(id)
{
    return PLUGIN_HANDLED;
}

public Jump_Set(id)
{
    return PLUGIN_HANDLED;
}

public autoload(id)
{
    if (!is_user_connected(id)) return;

    new name[32];
    get_user_name(id, name, charsmax(name));

    client_print_color(id, print_chat,
        "^4%s^1 Welcome ^3%s^1. Thanks for installing.", TAG, name
    );
}