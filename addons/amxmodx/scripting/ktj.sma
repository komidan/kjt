#include <amxmodx>
#include <fakemeta>
#include <string>
#include <json>
#include <ktj>

#pragma semicolon 1

#define PLUGIN "komi's TrickJumps"
#define VERSION "0.5.0"
#define AUTHOR "komidan"

#define PLUGIN_TAG "[K-TJ]"
#define PLUGIN_FILE "addons/amxmodx/data/ktj_jumps.json"

new g_args[64];
new current_map[32];
new JSON:g_ktj_jumps = Invalid_JSON;

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    register_clcmd("say", "chat_command_handler");
    register_clcmd("say_team", "chat_command_handler");

    register_concmd("exportjump", "jump_export");
    register_concmd("importjump", "jump_import");

    get_mapname(current_map, charsmax(current_map));

    // Create file if doesn't exist.
    if (!file_exists(PLUGIN_FILE))
    {
        server_print("%s Plugin file does not exist, creating...", PLUGIN_TAG);
        new JSON:data = json_init_object();

        if (!json_serial_to_file(data, PLUGIN_FILE))
        {
            server_print("%s File failed to be created.", PLUGIN_TAG);
        }
    }
    g_ktj_jumps = json_parse(PLUGIN_FILE, true);
    if (g_ktj_jumps == Invalid_JSON)
    {
        server_print("%s Invalid_JSON on g_ktj_jumps", PLUGIN_TAG);
    }
}

public plugin_end()
{
    if (g_ktj_jumps != Invalid_JSON)
    {
        json_free(g_ktj_jumps);
        g_ktj_jumps = Invalid_JSON;
    }

    log_amx("Thanks for using my plugin and have a lovely day. -komi");
    return PLUGIN_HANDLED;
}

public chat_command_handler(id)
{
    new args[128];
    read_args(args, charsmax(args));
    remove_quotes(args);

    new cmd[64], arg1[64];
    parse(args, cmd, charsmax(cmd), arg1, charsmax(arg1));

    // Handler for say commands, checks cmd argument.
    g_args = arg1;
    if (equal(cmd, "/createjump"))
    {
        jump_create(id);
    }
    else if (equal(cmd, "/deletejump"))
    {
        jump_delete(id);
    }
    else if (equal(cmd, "/setjump"))
    {
        jump_set(id);
    }
    else if (equal(cmd, "/ktj"))
    {
        client_print_color(id, print_chat, "^4%s^1 komi's TrickJumping ^3v%s^1", PLUGIN_TAG, VERSION);
    }

    return PLUGIN_HANDLED;
}

public jump_create(id)
{
    if (!is_user_alive(id)) return PLUGIN_HANDLED;

    if (equal(g_args, ""))
    {
        client_print_color(id, print_chat, "^4%s^1 Usage: /createjump <jump_name>", PLUGIN_TAG);
        return PLUGIN_HANDLED;
    }

    if (ktj_jump_exists(g_ktj_jumps, current_map, g_args))
    {
        client_print_color(id, print_chat, "^4%s^1 Warning: Jump %s already existed, it will be overwritten.", PLUGIN_TAG, g_args);
    }

    new Float:origin[3];
    new Float:v_angles[3];

    // Get the player's world position, and view angles.
    pev(id, pev_origin, origin);
    pev(id, pev_v_angle, v_angles);

    // Write JSON
    new JSON:map_level = json_object_has_value(g_ktj_jumps, current_map)
        ? json_object_get_value(g_ktj_jumps, current_map)
        : json_init_object();

    // Need multiple objects for multiple levels to json.
    new JSON:jump_data = json_init_object();

    json_object_set_real(jump_data, "posx", origin[0]);
    json_object_set_real(jump_data, "posy", origin[2]);
    json_object_set_real(jump_data, "posz", origin[1]);

    json_object_set_real(jump_data, "yaw", v_angles[1]);
    json_object_set_real(jump_data, "pitch", v_angles[0]);

    json_object_set_value(map_level, g_args, jump_data);

    if (!json_object_has_value(g_ktj_jumps, current_map))
    {
        json_object_set_value(g_ktj_jumps, current_map, map_level);
    }

    if (!json_serial_to_file(g_ktj_jumps, PLUGIN_FILE))
    {
        client_print_color(id, print_chat, "^4%s^1 JSON Failed to Save");
        return PLUGIN_HANDLED;
    }

    client_print_color(id, print_chat, "^4%s^1 Jump ^3%s^1 created.", PLUGIN_TAG, g_args);

    json_free(jump_data);
    json_free(map_level);
    return PLUGIN_HANDLED;

}

public jump_delete(id)
{
    if (!is_user_alive(id)) return PLUGIN_HANDLED;

    if (equal(g_args, ""))
    {
        delete_jump_menu(id);
        return PLUGIN_HANDLED;
    }

    new JSON:map_level = json_object_get_value(g_ktj_jumps, current_map);

    if (!json_object_has_value(map_level, g_args))
    {
        client_print_color(id, print_chat, "^4%s^1 Jump ^3%s^1 does not exist.", PLUGIN_TAG, g_args);
    }

    if (json_object_remove(map_level, g_args))
    {
        client_print_color(id, print_chat, "^4%s^1 Jump ^3%s^1 deleted successfully.", PLUGIN_TAG, g_args);
    }

    // Rewrite the json object.
    if (!json_serial_to_file(g_ktj_jumps, PLUGIN_FILE))
    {
        client_print_color(id, print_chat, "^4%s^1 JSON Failed to Save");
    }

    json_free(map_level);
    return PLUGIN_HANDLED;
}

public jump_set(id)
{
    if (!is_user_alive(id))
        return PLUGIN_HANDLED;

    if (equal(g_args, ""))
    {
        set_jump_menu(id);
        return PLUGIN_HANDLED;
    }

    new JSON:jump_data = ktj_jump_get(g_ktj_jumps, current_map, g_args);

    // Set player position and view angle
    new Float:jump_origin[3];
    new Float:jump_v_angle[3];

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

    client_print_color(id, print_chat, "^4%s^1 Jump ^3%s^1 has been set.", PLUGIN_TAG, g_args);
    json_free(jump_data);
    return PLUGIN_HANDLED;
}

/**
 * TODO: Maybe make these menu's use a stock function
 * to populate the menu... don't repeat code fr bro.
 */
public delete_jump_menu(id)
{
    new menu = menu_create("[K-TJ] Delete Jump", "delete_jump_menu_handler");

    new key[64]; // Jump name

    new JSON:map_data = json_object_get_value(g_ktj_jumps, current_map);
    new count = json_object_get_count(map_data);
    if (map_data == Invalid_JSON || count == 0)
    {
        client_print_color(id, print_chat, "^4%s^1 No jumps found for this map.", PLUGIN_TAG);
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }

    for (new i = 0; i < count; i++)
    {
        json_object_get_name(map_data, i, key, charsmax(key));
        menu_additem(menu, key, key);
    }

    menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
    menu_display(id, menu, 0);
    return PLUGIN_HANDLED;
}

public delete_jump_menu_handler(id, menu, item)
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
    amxclient_cmd(id, "say", "/deletejump", data);

    menu_destroy(menu);
    return PLUGIN_HANDLED;
}

public set_jump_menu(id)
{
    new menu = menu_create("[K-TJ] Jumps Menu", "set_jump_menu_handler");

    new key[64]; // Jump name

    new JSON:map_data = json_object_get_value(g_ktj_jumps, current_map);
    new count;
    if (map_data == Invalid_JSON || json_object_get_count(map_data) == 0)
    {
        client_print_color(id, print_chat, "^4%s^1 No jumps found for this map.", PLUGIN_TAG);
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }
    count = json_object_get_count(map_data);

    for (new i = 0; i < count; i++)
    {
        json_object_get_name(map_data, i, key, charsmax(key));
        menu_additem(menu, key, key);
    }

    menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
    menu_display(id, menu, 0);
    return PLUGIN_HANDLED;
}

public set_jump_menu_handler(id, menu, item)
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
 * how to get around this engine limitation. Oh 1.6!
 */
public jump_export(id)
{
    new arg[32]; // Name of the jump to export.
    read_argv(id, arg, charsmax(arg));
    remove_quotes(arg);

    if (equal(arg, ""))
    {
        client_print(id, print_console, "%s Usage: jumpexport <jump_name>", PLUGIN_TAG);
        return PLUGIN_HANDLED;
    }

    new JSON:jump_data = ktj_jump_get(g_ktj_jumps, current_map, arg);
    new JSON:jump_name = json_init_object();
    new JSON:final_json = json_init_object();
    json_object_set_value(jump_name, arg, jump_data);
    json_object_set_value(final_json, current_map, jump_name);

    new json_string[1024];
    json_serial_to_string(final_json, json_string, charsmax(json_string));

    client_print(id, print_console, "%s Exported jump: %s | Copy the JSON text below.", PLUGIN_TAG, arg);
    print_long_string(id, json_string);

    json_free(jump_data);
    json_free(jump_name);
    json_free(final_json);
    return PLUGIN_HANDLED;
}

public jump_import(id)
{
    new arg[1024];
    read_args(arg, charsmax(arg));

    new jump_key[64];
    new map_key[64];

    server_print("ARG : %s", arg);

    if (equal(arg, ""))
    {
        client_print(id, print_console, "%s Usage: jumpimport <json>", PLUGIN_TAG);
        return PLUGIN_HANDLED;
    }

    // Verify arg is valid JSON
    new JSON:imported_json = json_parse(arg);
    if (imported_json == Invalid_JSON)
    {
        client_print(id, print_console, "%s Failed to parse JSON.", PLUGIN_TAG);
        return PLUGIN_HANDLED;
    }

    // Extract the map key from imported json.
    json_object_get_name(imported_json, 0, map_key, charsmax(map_key));

    if (equal(map_key, ""))
    {
        client_print(id, print_console, "%s No map key found in JSON.", PLUGIN_TAG);
        json_free(imported_json);
        return PLUGIN_HANDLED;
    }

    // Get the imported json's map object.
    new JSON:imported_map_level = json_object_get_value(imported_json, map_key);
    if (!json_object_has_value(g_ktj_jumps, map_key))
    {
        json_object_set_value(g_ktj_jumps, map_key, imported_map_level);
    }
    else
    {
        // Map already exists inside file
        json_object_get_name(imported_map_level, 0, jump_key, charsmax(jump_key));

        new JSON:map_level = json_object_get_value(g_ktj_jumps, map_key);
        new JSON:jump_data = ktj_jump_get(imported_json, map_key, jump_key);

        json_object_set_value(map_level, jump_key, jump_data);
        json_object_set_value(g_ktj_jumps, map_key, map_level);

        json_free(jump_data);
        json_free(map_level);
    }

    // Save file.
    if (!json_serial_to_file(g_ktj_jumps, PLUGIN_FILE))
    {
        client_print_color(id, print_chat, "^4%s^1 JSON Failed to Save");
        return PLUGIN_HANDLED;
    }

    client_print(id, print_console, "%s Jump %s was imported to map %s.", PLUGIN_TAG, jump_key, map_key);
    json_free(imported_map_level);
    json_free(imported_json);
    return PLUGIN_HANDLED;
}