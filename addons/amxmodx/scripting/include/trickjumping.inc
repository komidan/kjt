#if defined _TJ_INCLUDE
    #endinput
#endif
#define _TJ_INCLUDE

#if !defined _amxmodx_included
    #define _amxmodx_included
    #include <amxmodx>
#endif

#if !defined _json_included
    #define _json_included
    #include <json>
#endif

/**
 * Print a string of >256 chars to the console.
 *
 * @param id        User ID to print to
 * @param input     Long string to print
 */
stock PrintLongString(id, const input[])
{
    const MAX_CHUNK_SIZE = 128;
    new len = strlen(input);
    new chunk[MAX_CHUNK_SIZE];

    for (new i = 0; i < len; i += MAX_CHUNK_SIZE)
    {
        copy(chunk, charsmax(chunk), input[i]);
        console_print(id, "%s", chunk);
    }
}

/**
 * Check if server is private IP, if this is the case, it's likely a lan server.
 *
 * @param ip        ip to check
 *
 * @return          true/false
 */
stock bool:IsPrivateIp(const ip[])
{
    return (contain(ip, "192.168.") == 0 ||
            contain(ip, "10.") == 0 ||
            contain(ip, "172.16.") == 0 ||
            contain(ip, "127.") == 0);
}

/**
 * Returns if the map exists in the db already
 *
 * @param Object            main json object
 * @param MapName           name of map
 *
 * @return                  true: exists; false: doesn't exist
 */
stock bool:HasMapObject(JSON:Object, const MapName[])
{
    return json_object_has_value(Object, MapName);
}

/**
 * Get the map object from jumps_db
 *
 * @param Object           main json object
 * @param MapName          name of the map to find
 * @param JsonFile         name of the json file to search
 *
 * @return                 map json object, else Invalid_JSON
 */
stock JSON:GetMapObject(JSON:Object, const MapName[])
{
    if (!HasMapObject(Object, MapName))
    {
        return Invalid_JSON;
    }

    return json_object_get_value(Object, MapName);
}

/**
 * Returns if the jump exists in the db already
 *
 * @param Object            main json object
 * @param MapName           name of map
 * @param JumpName          name of jump
 *
 * @return                  true: exists; false: doesn't exist
 */
stock bool:HasJumpObject(JSON:Object, const MapName[], const JumpName[])
{
    if (!HasMapObject(Object, MapName))
    {
        return false;
    }

    new JSON:map_object = GetMapObject(Object, MapName);
    if (!json_object_has_value(map_object, JumpName))
    {
        return false;
    }

    json_free(map_object);
    return true;
}

/**
 * Returns the jump data of the specified JumpName
 *
 * @param Object            main json object
 * @param MapName           name of map
 * @param JumpName          name of jump
 *
 * @return                  jump data; else Invalid_JSON
 */
stock JSON:GetJumpObject(JSON:Object, const MapName[], const JumpName[])
{
    new JSON:map_object = GetMapObject(Object, MapName);
    if (map_object == Invalid_JSON)
    {
        return Invalid_JSON;
    }

    return json_object_get_value(map_object, JumpName);
}

/**
 * Writes a JSON object to <Object>:
 *
 * @param Object        main json object
 * @param MapName       name of the map
 * @param JumpName      name of the jump
 * @param JumpData      jump data to save under JumpName
 *
 * @return              true: written successfully; false: failed
 */
stock bool:WriteJump(JSON:Object, const MapName[], const JumpName[], JSON:JumpData)
{
    // If the map already exists inside Object, write to that, if not create it.
    new JSON:map_object = json_object_has_value(Object, MapName)
        ? json_object_get_value(Object, MapName)
        : json_init_object();

    if (!json_object_set_value(map_object, JumpName, JumpData))
    {
        return false;
    }

    if (!json_object_set_value(Object, MapName, map_object))
    {
        return false;
    }

    json_free(map_object);

    return true;
}

/**
 * Saves JSON object to specified file path
 *
 * @param Object        json object to save
 * @param FilePath      file path string
 *
 * @return              true: saved; false: failed
 */
stock bool:SaveDB(JSON:Object, const FilePath[])
{
    return json_serial_to_file(Object, FilePath);
}

/**
 * Gets user weapon
 *
 * @param id        user id
 * @param buffer    buffer for storing name
 * @param len       buffer length
 *
 * @noreturn
 */
stock GetUserWeapon(id, buffer[], len)
{
    new weapon_id = get_user_weapon(id);
    get_weaponname(weapon_id, buffer, len);
}