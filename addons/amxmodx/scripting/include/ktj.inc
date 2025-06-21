#if !defined _INLCUDE_JSON
    #define _INCLUDE_JSON
    #include <json>
#endif

#define MAX_CHUNK_SIZE 128
/**
 * Print a string of >256 chars to the console.
 *
 * @param id        User ID to print to
 * @param input     Long string to print
 */
stock print_long_string(id, const input[])
{
    new len = strlen(input);
    new chunk[MAX_CHUNK_SIZE]

    for (new i = 0; i < len; i += MAX_CHUNK_SIZE)
    {
        copy(chunk, charsmax(chunk), input[i]);
        client_print(id, print_console, "%s", chunk);
    }
}

/**
 * Returns the jump_data JSON object from top_level_json[map_name][jump_name]
 *
 * @param top_level_json        The root JSON object (e.g., g_ktj_jumps)
 * @param map_name              Map name to look under
 * @param jump_name             Jump name to fetch
 *
 * @return                      JSON object if found, or Invalid_JSON
 */
stock JSON:ktj_jump_get(JSON:top_level_json, const map_name[], const jump_name[])
{
    if (!json_object_has_value(top_level_json, map_name))
    {
        return Invalid_JSON;
    }

    new JSON:map_obj = json_object_get_value(top_level_json, map_name);
    if (map_obj == Invalid_JSON)
    {
        return Invalid_JSON;
    }

    if (!json_object_has_value(map_obj, jump_name))
    {
        return Invalid_JSON;
    }

    return json_object_get_value(map_obj, jump_name); // Do not json_free() this unless you create a new object
}

/**
 * Checks if a jump exists for a given map and jump name in g_ktj_jumps.
 *
 * @param top_level_json   The root JSON object (e.g., g_ktj_jumps)
 * @param map_name         The name of the map
 * @param jump_name        The name of the jump
 *
 * @return                 true if the jump exists, false otherwise
 */
stock bool:ktj_jump_exists(JSON:top_level_json, const map_name[], const jump_name[])
{
    if (!json_object_has_value(top_level_json, map_name))
    {
        return false;
    }

    new JSON:map_jumps = json_object_get_value(top_level_json, map_name);
    if (map_jumps == Invalid_JSON)
    {
        return false;
    }

    if (!json_object_has_value(map_jumps, jump_name))
    {
        return false;
    }

    return true;
}