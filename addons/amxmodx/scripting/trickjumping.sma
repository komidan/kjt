#include <amxmodx>
#include <fakemeta>
#include <string>
#include <json>
#define CC_COLORS_TYPE CC_COLORS_STANDARD
#include <cromchat>

#include <trickjumping>

#pragma semicolon 1

#define PLUGIN "komidan's Trickjumping"
#define VERSION "0.6.0r"
#define AUTHOR "komidan"

#define P_TAG "[TJ]"
#define P_FILE "addons/amxmodx/data/tj_db.json"

new JSON:g_db = Invalid_JSON;
new g_current_map[32];

public plugin_init()
{
    server_print("");
    server_print("%s Trickjumping Plugin Initialization", P_TAG);
    new ip[32];
    get_user_ip(0, ip, charsmax(ip), 1);
    if (IsPrivateIp(ip))
    {
        server_print("%s Server IP is private! Good, don't run this on a server. It won't work, or possibly break!", P_TAG, ip);
    }

    get_mapname(g_current_map, charsmax(g_current_map));

    register_plugin(PLUGIN, VERSION, AUTHOR);

    register_clcmd("say", "chat_command_handler");
    register_clcmd("say_team", "chat_command_handler");

    register_concmd("exportjump", "jump_export", -1, "<jump_name>");
    register_concmd("importjump", "jump_import", -1, "<encoded_jump>");
    register_concmd("renamejump", "jump_rename", -1, "<old_name> <new_name>");

    // Creating the P_FILE and assigning it to g_db
    if (!file_exists(P_FILE))
    {
        server_print("%s Plugin file does not exist, creating...", P_TAG);
        new JSON:temp = json_init_object();

        if (!json_serial_to_file(temp, P_FILE))
        {
            server_print("%s '%s' failed to be created", P_TAG, P_FILE);
            server_print("%s Terminating Plugin", P_TAG);
            return PLUGIN_HANDLED;
        }

        json_free(temp);
        server_print("%s '%s' was created successfully.", P_TAG, P_FILE);
    }
    server_print("%s Found file '%s'", P_TAG, P_FILE);
    g_db = json_parse(P_FILE, true);
    if (g_db == Invalid_JSON)
    {
        server_print("%s '%s' contained invalid JSON, contact plugin owner", P_TAG, P_FILE);
        server_print("%s Terminating Plugin", P_TAG);
        return PLUGIN_HANDLED;
    }
    server_print("%s You are good to go!", P_TAG);
    server_print("");

    return PLUGIN_HANDLED;
}

public plugin_end()
{
    if (!SaveDB(g_db, P_FILE))
    {
        server_print("%s Failed to save to '%s', rip.", P_TAG, P_FILE);
        return PLUGIN_HANDLED;
    }

    if (g_db != Invalid_JSON)
    {
        json_free(g_db);
    }

    server_print("%s Plugin Ended", P_TAG);

    return PLUGIN_HANDLED;
}

public chat_command_handler(id)
{
    new full_args[128];
    read_args(full_args, charsmax(full_args));
    remove_quotes(full_args);

    new cmd[32], args[96];
    argbreak(full_args, cmd, charsmax(cmd), args, charsmax(args));

    if (equal(cmd, "/createjump"))
    {
        jump_create(id, args);
        return PLUGIN_HANDLED;
    }
    else if (equal(cmd, "/deletejump"))
    {
        jump_delete(id, args);
        return PLUGIN_HANDLED;
    }
    else if (equal(cmd, "/setjump"))
    {
        jump_set(id, args);
        return PLUGIN_HANDLED;
    }
    else if (equal(cmd, "/renamejump"))
    {
        jump_rename(id, args);
        return PLUGIN_HANDLED;
    }
    else if (equal(cmd, "/tj"))
    {
        about(id);
        return PLUGIN_HANDLED;
    }
    else
    {
        return PLUGIN_CONTINUE;
    }
}

public jump_create(id, const args[])
{
    if (!is_user_alive(id)) return PLUGIN_HANDLED;

    new jump_name[32], overwrite[4];
    parse(args, jump_name, charsmax(jump_name), overwrite, charsmax(overwrite));

    if (equal(jump_name, ""))
    {
        CC_SendMessage(id, "^4%s^1 Usage: ^5/createjump <jump_name>^1", P_TAG);
        return PLUGIN_HANDLED;
    }

    new JSON:jump_data = json_init_object();
    new JSON:pos = json_init_array();
    new JSON:rotation = json_init_array();
    new Float:origin[3];
    new Float:v_angle[3];
    new weapon[24];

    // Get Data
    pev(id, pev_origin, origin);
    pev(id, pev_v_angle, v_angle);
    GetUserWeapon(id, weapon, charsmax(weapon));

    // Set Data
    json_array_append_real(pos, origin[0]);
    json_array_append_real(pos, origin[1]);
    json_array_append_real(pos, origin[2]);

    json_array_append_real(rotation, v_angle[0]);
    json_array_append_real(rotation, v_angle[1]);

    json_object_set_value(jump_data, "pos", pos);
    json_object_set_value(jump_data, "rotation", rotation);
    json_object_set_string(jump_data, "weapon", weapon);

    // Safeguards, ability to overwrite.
    if (HasJumpObject(g_db, g_current_map, jump_name))
    {
        if (equal(overwrite, "1"))
        {
            CC_SendMessage(id, "^4%s^1 Jump ^3%s^1 overwritten.", P_TAG, jump_name);
        }
        else
        {
            CC_SendMessage(id, "^4%s^1 Jump ^3%s^1 already exists. Add '1' after command to overwrite.", P_TAG, jump_name);
            return PLUGIN_HANDLED;
        }
    }

    if (!WriteJump(g_db, g_current_map, jump_name, jump_data))
    {
        server_print("%s Failed to write jump '%s'", jump_name);
        return PLUGIN_HANDLED;
    }

    if (!SaveDB(g_db, P_FILE))
    {
        server_print("%s Failed to save 'g_db'");
        return PLUGIN_HANDLED;
    }

    if (equal(overwrite, ""))
    {
        CC_SendMessage(id, "^4%s^1 Created jump ^3%s^1", P_TAG, jump_name);
    }

    json_free(jump_data);
    json_free(pos);
    json_free(rotation);

    return PLUGIN_HANDLED;
}

public jump_set(id, const args[])
{
    if (!is_user_alive(id)) return PLUGIN_HANDLED;

    new jump_name[32];
    parse(args, jump_name, charsmax(jump_name));

    if (equal(jump_name, ""))
    {
        set_jump_menu(id);
        return PLUGIN_HANDLED;
    }

    if (!HasJumpObject(g_db, g_current_map, jump_name))
    {
        CC_SendMessage(id, "^4%s^1 Jump ^3%s^1 doesn't exist.");
        return PLUGIN_HANDLED;
    }

    new JSON:jump_data = GetJumpObject(g_db, g_current_map, jump_name);
    new JSON:pos = json_object_get_value(jump_data, "pos");
    new JSON:rotation = json_object_get_value(jump_data, "rotation");
    new Float:jump_pos[3];
    new Float:jump_rotation[3];

    jump_pos[0] = json_array_get_real(pos, 0);
    jump_pos[1] = json_array_get_real(pos, 1);
    jump_pos[2] = json_array_get_real(pos, 2);

    jump_rotation[0] = json_array_get_real(rotation, 0);
    jump_rotation[1] = json_array_get_real(rotation, 1);
    jump_rotation[2] = 0.0;

    set_pev(id, pev_origin, jump_pos);
    set_pev(id, pev_v_angle, jump_rotation);

    set_pev(id, pev_velocity, {0.0, 0.0, 0.0});
    set_pev(id, pev_angles, jump_rotation);
    set_pev(id, pev_fixangle, 1);

    CC_SendMessage(id, "^4%s^1 Jump ^3%s^1 has been set.", P_TAG, jump_name);

    json_free(jump_data);
    json_free(pos);
    json_free(rotation);

    return PLUGIN_HANDLED;
}

public jump_delete(id, const args[])
{
    if (!is_user_alive(id)) return PLUGIN_HANDLED;

    new jump_name[32];
    parse(args, jump_name, charsmax(jump_name));

    if (equal(jump_name, ""))
    {
        delete_jump_menu(id);
        return PLUGIN_HANDLED;
    }

    if (!HasMapObject(g_db, g_current_map))
    {
        server_print("%s Map doesn't exist.", P_TAG);
        return PLUGIN_HANDLED;
    }
    new JSON:map_object = GetMapObject(g_db, g_current_map);

    if (!HasJumpObject(g_db, g_current_map, jump_name))
    {
        CC_SendMessage(id, "^4%s^1 Jump ^3%s^1 doesn't exist.", P_TAG, jump_name);
        return PLUGIN_HANDLED;
    }

    if (json_object_remove(map_object, jump_name))
    {
        CC_SendMessage(id, "^4%s^1 Jump ^3%s^1 deleted.", P_TAG, jump_name);
        return PLUGIN_HANDLED;
    }

    SaveDB(g_db, P_FILE);
    json_free(map_object);

    return PLUGIN_HANDLED;
}

public jump_rename(id, const args[])
{
    new old_jump_name[32], new_jump_name[32];
    parse(args, old_jump_name, charsmax(old_jump_name), new_jump_name, charsmax(new_jump_name));

    if (!is_user_alive(id)) return PLUGIN_HANDLED;

    if (equal(old_jump_name, "") || equal(new_jump_name, ""))
    {
        CC_SendMessage(id, "^4%s^1 Usage: /renamejump <old_jump_name> <new_jump_name>", P_TAG);
        return PLUGIN_HANDLED;
    }

    new JSON:map_object = GetMapObject(g_db, g_current_map);
    if (map_object == Invalid_JSON)
    {
        CC_SendMessage(id, "^4%s^1 No data found for map ^3%s^1", P_TAG, g_current_map);
        return PLUGIN_HANDLED;
    }

    new JSON:jump_data = GetJumpObject(g_db, g_current_map, old_jump_name);
    if (jump_data == Invalid_JSON)
    {
        CC_SendMessage(id, "^4%s^1 Jump ^3%s^1 does not exist on map ^3%s^1.", P_TAG, old_jump_name, g_current_map);
        return PLUGIN_HANDLED;
    }

    json_object_set_value(map_object, new_jump_name, jump_data);
    json_object_remove(map_object, old_jump_name);

    json_free(map_object);
    json_free(jump_data);
    SaveDB(g_db, P_FILE);

    CC_SendMessage(id, "^4%s^1 Jump ^3%s^1 renamed to ^3%s^1", P_TAG, old_jump_name, new_jump_name);

    return PLUGIN_HANDLED;
}

// Menus
public delete_jump_menu(id)
{
    new menu = menu_create("[K-TJ] Delete Jump", "delete_jump_menu_handler");

    new key[64]; // Jump name

    new JSON:map_data = GetMapObject(g_db, g_current_map);
    new count = json_object_get_count(map_data);
    if (map_data == Invalid_JSON || count == 0)
    {
        CC_SendMessage(id, "^4%s^1 No jumps found for ^3%s^1.", P_TAG, g_current_map);
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

    delete_jump_menu(id);
    return PLUGIN_HANDLED;
}

public set_jump_menu(id)
{
    new menu = menu_create("[TJ] Jumps Menu", "set_jump_menu_handler");

    new key[64]; // Jump name

    new JSON:map_data = GetMapObject(g_db, g_current_map);
    new count;
    if (map_data == Invalid_JSON || json_object_get_count(map_data) == 0)
    {
        CC_SendMessage(id, "^4%s^1 No jumps found on ^3%s^1.", P_TAG, g_current_map);
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
    json_free(map_data);

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

    set_jump_menu(id);
    return PLUGIN_HANDLED;
}

public jump_export(id)
{
    new jump_name[32];
    read_argv(1, jump_name, charsmax(jump_name));
    remove_quotes(jump_name);

    if (equal(jump_name, ""))
    {
        client_print(id, print_console, "%s Usage: jumpexport <jump_name>", P_TAG);
        return PLUGIN_HANDLED;
    }

    new JSON:result = json_init_object();
    new bool:found = false;
    // TODO: For loop search through all maps and jumps to find the one.
    new maps_count = json_object_get_count(g_db);
    new map_key[32];
    new JSON:map_object;

    for (new i = 0; i < maps_count; i++)
    {
        json_object_get_name(g_db, i, map_key, charsmax(map_key));
        map_object = json_object_get_value(g_db, map_key);

        if (map_object == Invalid_JSON)
        {
            client_print(id, print_console, "%s No maps found(?)", P_TAG);
            return PLUGIN_HANDLED;
        }

        if (json_object_has_value(map_object, jump_name))
        {
            new JSON:jump_data = json_object_get_value(map_object, jump_name);
            new JSON:jump_wrapper = json_init_object();
            json_object_set_value(jump_wrapper, jump_name, jump_data);
            json_object_set_value(result, map_key, jump_wrapper);

            json_free(jump_data);
            json_free(jump_wrapper);

            found = true;
        }
    }

    if (!found)
    {
        json_free(result);
        client_print(id, print_console, "%s Jump '%s' not found.", P_TAG, jump_name);
        return PLUGIN_HANDLED;
    }

    new json_string[512];
    json_serial_to_string(result, json_string, charsmax(json_string));

    client_print(id, print_console, "%s Exported jump: '%s' | Copy the JSON text below.", P_TAG, jump_name);
    client_print(id, print_console, "");
    PrintLongString(id, json_string);

    json_free(result);

    return PLUGIN_HANDLED;
}

public jump_import(id)
{
    return PLUGIN_HANDLED;
}
public about(id)
{
    CC_SendMessage(id, "^4%s^1 %s (^3v%s^1)", P_TAG, PLUGIN, VERSION);
    return PLUGIN_HANDLED;
}