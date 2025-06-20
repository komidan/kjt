#include <amxmodx>
#include <fakemeta>
#include <string>
#include <json>

#pragma semicolon 1

#define PLUGIN "komi's TrickJumps"
#define VERSION "0.1u"
#define AUTHOR "komidan"

#define PLUGIN_TAG "[KJT]"

new g_jumpname[64];
new JSON:g_kjt_jumps = Invalid_JSON;

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    register_clcmd("say", "Chat_Command_Handler");
    register_clcmd("say_team", "Chat_Command_Handler");

    register_event("ResetHUD", "autoload", "b");

    // Create file if doesn't exist.
    if (!file_exists("addons/amxmodx/data/kjt_jumps.json"))
    {
        new JSON:data = json_init_object();

        if (!json_serial_to_file(data, "addons/amxmodx/data/kjt_jumps.json"))
        {
            server_print("[KJT] File Failed to be created.");
        }
    }
    else
    {
        g_kjt_jumps = json_parse("addons/amxmodx/data/kjt_jumps.json", true);
        if (g_kjt_jumps == Invalid_JSON)
        {
            g_kjt_jumps = json_init_object();
        }
    }

}

public plugin_end()
{
    if (g_kjt_jumps != Invalid_JSON)
    {
        json_free(g_kjt_jumps);
        g_kjt_jumps = Invalid_JSON;
    }
}

public Chat_Command_Handler(id)
{
    new args[128];
    read_args(args, charsmax(args));
    remove_quotes(args);

    new cmd[64], jumpname[64];
    parse(args, cmd, charsmax(cmd), jumpname, charsmax(jumpname));

    if (equal(cmd, "/createjump"))
    {
        g_jumpname = jumpname;
        Jump_Create(id);
    }
    else if (equal(cmd, "/deletejump"))
    {
        g_jumpname = jumpname;
        Jump_Delete(id);
    }
    else if (equal(cmd, "/setjump"))
    {
        g_jumpname = jumpname;
        Jump_Set(id);
    }

    return PLUGIN_HANDLED;
}

public Jump_Create(id)
{
    if (!is_user_alive(id)) return PLUGIN_HANDLED;

    if (equal(g_jumpname, ""))
    {
        client_print_color(id, print_chat, "^4%s^1 Usage: /createjump <name>", PLUGIN_TAG);
        return PLUGIN_HANDLED;
    }

    if (json_object_has_value(g_kjt_jumps, g_jumpname))
    {
        client_print_color(id, print_chat, "^4%s^1 Warning: Jump %s already existed, it will be overwritten.", PLUGIN_TAG, g_jumpname);
    }

    new author[32];
    get_user_name(id, author, charsmax(author));

    new Float:origin[3];
    new Float:v_angles[3];

    pev(id, pev_origin, origin);
    pev(id, pev_v_angle, v_angles);

    // Dev Logs
    // client_print_color(id, print_chat, "^4%s^1 Jump ^3%s^1 created. (%f, %f, %f) pitch: %f, yaw: %f", PLUGIN_TAG, g_jumpname, origin[0], origin[2], origin[1], v_angles[0], v_angles[1]);
    // client_print_color(id, print_chat, "^4%f %f %f^1", v_angles[0], v_angles[1], v_angles[2]);

    // Write JSON
    new JSON:jump_data = json_init_object();

    json_object_set_string(jump_data, "author", author);
    json_object_set_real(jump_data, "posx", origin[0]);
    json_object_set_real(jump_data, "posy", origin[2]);
    json_object_set_real(jump_data, "posz", origin[1]);

    json_object_set_real(jump_data, "yaw", v_angles[1]);
    json_object_set_real(jump_data, "pitch", v_angles[0]);
    // Don't set ROLL value here, don't need it!

    json_object_set_value(g_kjt_jumps, g_jumpname, jump_data);

    if (!json_serial_to_file(g_kjt_jumps, "addons/amxmodx/data/kjt_jumps.json"))
    {
        client_print_color(id, print_chat, "^4%s^1 JSON Failed to Save");
    }

    json_free(jump_data);

    return PLUGIN_HANDLED;

}

public Jump_Delete(id)
{
    if (!is_user_alive(id)) return PLUGIN_HANDLED;

    if (equal(g_jumpname, ""))
    {
        client_print_color(id, print_chat, "^4%s^1 Usage: /deletejump <name>", PLUGIN_TAG);
        return PLUGIN_HANDLED;
    }

    if (!json_object_has_value(g_kjt_jumps, g_jumpname))
    {
        client_print_color(id, print_chat, "^4%s%1 Jump ^3%s^1 does not exist.", PLUGIN_TAG, g_jumpname);
    }

    if (json_object_remove(g_kjt_jumps, g_jumpname))
    {
        client_print_color(id, print_chat, "^4%s^1 Jump ^3%s^1 deleted successfully.", PLUGIN_TAG, g_jumpname);
    }

    // Rewrite the json object.
    if (!json_serial_to_file(g_kjt_jumps, "addons/amxmodx/data/kjt_jumps.json"))
    {
        client_print_color(id, print_chat, "^4%s^1 JSON Failed to Save");
    }

    return PLUGIN_HANDLED;
}

public Jump_Set(id)
{
    if (!is_user_alive(id)) return PLUGIN_HANDLED;

    if (equal(g_jumpname, ""))
    {
        client_print_color(id, print_chat, "^4%s^1 Usage: /deletejump <name>", PLUGIN_TAG);
        return PLUGIN_HANDLED;
    }

    if (!json_object_has_value(g_kjt_jumps, g_jumpname))
    {
        client_print_color(id, print_chat, "^4%s%1 Jump ^3%s^1 does not exist.", PLUGIN_TAG, g_jumpname);
    }

    new Float:jump_origin[3];
    new Float:jump_v_angle[3];
    new author[32];

    new JSON:jump_data = json_object_get_value(g_kjt_jumps, g_jumpname);

    if (jump_data != Invalid_JSON)
    {
        json_object_get_string(jump_data, "author", author, charsmax(author));

        jump_origin[0] = json_object_get_real(jump_data, "posx");
        jump_origin[1] = json_object_get_real(jump_data, "posz");
        jump_origin[2] = json_object_get_real(jump_data, "posy");

        jump_v_angle[0] = json_object_get_real(jump_data, "pitch");
        jump_v_angle[1] = json_object_get_real(jump_data, "yaw");
        jump_v_angle[2] = 0.0;

        set_pev(id, pev_origin, jump_origin);
        set_pev(id, pev_v_angle, jump_v_angle);
        set_pev(id, pev_velocity, {0.0, 0.0, 0.0});

        set_pev(id, pev_angles, jump_v_angle);
        set_pev(id, pev_fixangle, 1);

        // Dev Logs
        // client_print_color(id, print_chat, "^4%s^1 Jump ^3%s^1 (created by ^3%s^1) has been set.", PLUGIN_TAG, g_jumpname, author);
        // client_print_color(id, print_chat, "^4%s^1 (%f, %f, %f) yaw: %f, pitch %f", PLUGIN_TAG, jump_origin[0], jump_origin[2], jump_origin[1], jump_v_angle[0], jump_v_angle[1]);

        json_free(jump_data);
    }

    return PLUGIN_HANDLED;
}

public autoload(id)
{
    if (!is_user_connected(id)) return;

    new name[32];
    get_user_name(id, name, charsmax(name));

    client_print_color(id, print_chat,
        "^4%s^1 Welcome ^3%s^1", PLUGIN_TAG, name
    );
}