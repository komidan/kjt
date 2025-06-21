#include <amxmodx>
#include <fakemeta>
#include <string>
#include <json>

#pragma semicolon 1

#define PLUGIN "komi's TrickJumps"
#define VERSION "0.2u"
#define AUTHOR "komidan"

#define PLUGIN_TAG "[KJT]"

new g_args[64];
new JSON:g_ktj_jumps = Invalid_JSON;

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    register_clcmd("say", "Chat_Command_Handler");
    register_clcmd("say_team", "Chat_Command_Handler");

    register_concmd("exportjump", "Jump_Export");
    register_concmd("importjump", "Jump_Import");

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
        g_ktj_jumps = json_parse("addons/amxmodx/data/kjt_jumps.json", true);
        if (g_ktj_jumps == Invalid_JSON)
        {
            g_ktj_jumps = json_init_object();
        }
    }

}

public plugin_end()
{
    if (g_ktj_jumps != Invalid_JSON)
    {
        json_free(g_ktj_jumps);
        g_ktj_jumps = Invalid_JSON;
    }
}

public Chat_Command_Handler(id)
{
    new args[128];
    read_args(args, charsmax(args));
    remove_quotes(args);

    new cmd[64], arg1[64];
    parse(args, cmd, charsmax(cmd), arg1, charsmax(arg1));

    g_args = arg1;
    if (equal(cmd, "/createjump"))
    {
        Jump_Create(id);
    }
    else if (equal(cmd, "/deletejump"))
    {
        Jump_Delete(id);
    }
    else if (equal(cmd, "/setjump"))
    {
        Jump_Set(id);
    }
    else if (equal(cmd, "/jumps"))
    {
        Jump_List(id);
    }

    return PLUGIN_HANDLED;
}

public Jump_Create(id)
{
    if (!is_user_alive(id)) return PLUGIN_HANDLED;

    if (equal(g_args, ""))
    {
        client_print_color(id, print_chat, "^4%s^1 Usage: /createjump <name>", PLUGIN_TAG);
        return PLUGIN_HANDLED;
    }

    if (json_object_has_value(g_ktj_jumps, g_args))
    {
        client_print_color(id, print_chat, "^4%s^1 Warning: Jump %s already existed, it will be overwritten.", PLUGIN_TAG, g_args);
    }

    new Float:origin[3];
    new Float:v_angles[3];

    pev(id, pev_origin, origin);
    pev(id, pev_v_angle, v_angles);

    // Write JSON
    new JSON:jump_data = json_init_object();

    json_object_set_real(jump_data, "posx", origin[0]);
    json_object_set_real(jump_data, "posy", origin[2]);
    json_object_set_real(jump_data, "posz", origin[1]);

    json_object_set_real(jump_data, "yaw", v_angles[1]);
    json_object_set_real(jump_data, "pitch", v_angles[0]);
    // Don't set ROLL value here, don't need it!

    json_object_set_value(g_ktj_jumps, g_args, jump_data);

    if (!json_serial_to_file(g_ktj_jumps, "addons/amxmodx/data/kjt_jumps.json"))
    {
        client_print_color(id, print_chat, "^4%s^1 JSON Failed to Save");
        return PLUGIN_HANDLED;
    }

    client_print_color(id, print_chat, "^4%s^1 Jump ^3%s^1 created.", PLUGIN_TAG, g_args);
    json_free(jump_data);

    return PLUGIN_HANDLED;

}

public Jump_Delete(id)
{
    if (!is_user_alive(id)) return PLUGIN_HANDLED;

    if (equal(g_args, ""))
    {
        client_print_color(id, print_chat, "^4%s^1 Usage: /deletejump <name>", PLUGIN_TAG);
        return PLUGIN_HANDLED;
    }

    if (!json_object_has_value(g_ktj_jumps, g_args))
    {
        client_print_color(id, print_chat, "^4%s^1 Jump ^3%s^1 does not exist.", PLUGIN_TAG, g_args);
    }

    if (json_object_remove(g_ktj_jumps, g_args))
    {
        client_print_color(id, print_chat, "^4%s^1 Jump ^3%s^1 deleted successfully.", PLUGIN_TAG, g_args);
    }

    // Rewrite the json object.
    if (!json_serial_to_file(g_ktj_jumps, "addons/amxmodx/data/kjt_jumps.json"))
    {
        client_print_color(id, print_chat, "^4%s^1 JSON Failed to Save");
    }

    return PLUGIN_HANDLED;
}

public Jump_Set(id)
{
    if (!is_user_alive(id)) return PLUGIN_HANDLED;

    if (equal(g_args, ""))
    {
        Jump_List(id);
        return PLUGIN_HANDLED;
    }

    if (!json_object_has_value(g_ktj_jumps, g_args))
    {
        client_print_color(id, print_chat, "^4%s^1 Jump ^3%s^1 does not exist.", PLUGIN_TAG, g_args);
        return PLUGIN_HANDLED;
    }

    new Float:jump_origin[3];
    new Float:jump_v_angle[3];

    new JSON:jump_data = json_object_get_value(g_ktj_jumps, g_args);

    if (jump_data != Invalid_JSON)
    {
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

        // client_print_color(id, print_chat, "^4%s^1 (%f, %f, %f) yaw: %f, pitch %f", PLUGIN_TAG, jump_origin[0], jump_origin[2], jump_origin[1], jump_v_angle[0], jump_v_angle[1]);

        client_print_color(id, print_chat, "^4%s^1 Jump ^3%s^1 has been set.", PLUGIN_TAG, g_args);
        json_free(jump_data);
    }

    return PLUGIN_HANDLED;
}

public Jump_List(id)
{
    new menu = menu_create("[KTJ] Jumps Menu", "Menu_Handler");

    new key[64]; // jump name

    for (new i = 0; i < json_object_get_count(g_ktj_jumps); i++)
    {
        json_object_get_name(g_ktj_jumps, i, key, charsmax(key));

        menu_additem(menu, key, key);
    }

    menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
    menu_display(id, menu, 0);

    return PLUGIN_HANDLED;
}

public Menu_Handler(id, menu, item)
{
    if (item == MENU_EXIT)
    {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }

    new data[64], access;
    menu_item_getinfo(menu, item, access, data, charsmax(data));

    new name_user[32];
    get_user_name(id, name_user, charsmax(name_user));
    amxclient_cmd(id, "say", "/setjump", data);

    menu_destroy(menu);
    return PLUGIN_HANDLED;
}

/**
 * Problems I've faced with these functions are engine constraints.
 * Can't print >256 characters to the console (?). No idea
 * how to get around this engine limitation. Oh Brainstorming!
 */
public Jump_Export(id)
{
    return PLUGIN_HANDLED;
}

public Jump_Import(id)
{
    return PLUGIN_HANDLED;
}