new const BASE64_CHARS[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

/**
 * Helper that converts characters to base64 counterpart.
 *
 * @param c         Character to encode
 */
stock base64_char_value(c)
{
    if (c >= 'A' && c <= 'Z') return c - 'A';
    if (c >= 'a' && c <= 'z') return c - 'a' + 26;
    if (c >= '0' && c <= '9') return c - '0' + 52;
    if (c == '+') return 62;
    if (c == '/') return 63;
    return -1;
}

/**
 * Base64 encodes a string.
 *
 * @param input     String
 * @param buffer    Buffer to copy string to
 * @param maxlen    Maximum size of buffer
 */
stock base64_encode(const input[], buffer[], const maxlen)
{
    new len = strlen(input);
    new i, c, outlen = 0;

    while (i < len && outlen + 4 < maxlen)
    {
        new val = 0, padding = 0;

        for (c = 0; c < 3; c++)
        {
            val <<= 8;
            if (i < len)
                val |= input[i++];
            else
                padding++;
        }

        for (c = 0; c < 4; c++)
        {
            if (c > 3 - padding)
                buffer[outlen++] = '=';
            else
                buffer[outlen++] = BASE64_CHARS[(val >> (18 - 6 * c)) & 0x3F];
        }
    }

    buffer[outlen] = 0;
    return outlen;
}

/**
 * Base64 encodes a string.
 *
 * @param input     String
 * @param buffer    Buffer to copy string to
 * @param maxlen    Maximum size of buffer
 */
stock base64_decode(const input[], buffer[], const maxlen)
{
    new i = 0, val = 0, valb = -8;
    new c, outlen = 0;

    while ((c = input[i++]) != 0 && outlen + 1 < maxlen)
    {
        if (c == '=') break;

        c = base64_char_value(c);
        if (c == -1) continue;

        val = (val << 6) | c;
        valb += 6;

        if (valb >= 0)
        {
            buffer[outlen++] = (val >> valb) & 0xFF;
            valb -= 8;
        }
    }

    buffer[outlen] = 0;
    return outlen;
}
