#if defined _PDS_included
    #endinput
#endif
#define _PDS_included

#pragma reqlib PersistentDataStorage
#if !defined AMXMODX_NOAUTOLOAD
    #pragma loadlib PersistentDataStorage
#endif

/**
 * Set data only here
 * @note: executing before plugins unloading
 */
forward PDS_Save();

/**
 * Sets data as cell
 *
 * @param key               Identifier for data
 * @param data              Data to be set
 *
 * @noreturn
 */
native PDS_SetCell(const key[], any:data);

/**
 * Gets data as cell
 *
 * @param key               Identifier for data
 * @param data              Variable to put data in
 *
 * @return                  true if data identified by |key| exists, false otherwise
 */
native bool:PDS_GetCell(const key[], &any:data);

/**
 * Sets data as array
 *
 * @param key               Identifier for data
 * @param data              Data to be set
 * @param size              Size of the data array
 *
 * @noreturn
 */
native PDS_SetArray(const key[], const any:data[], size);

/**
 * Gets data as array
 *
 * @param key               Identifier for data
 * @param data              Array to fill with data
 * @param size              Maximum size of |data| array
 *
 * @return                  true if data identified by |key| exists, false otherwise
 */
native bool:PDS_GetArray(const key[], any:data[], size);

/**
 * Sets data as string
 *
 * @param key               Identifier for data
 * @param buffer            Data to be set
 *
 * @noreturn
 */
native PDS_SetString(const key[], const buffer[]);

/**
 * Gets data as string
 *
 * @param key               Identifier for data
 * @param buffer            Buffer to put string data in
 * @param maxLength         Maximum length of |buffer| buffer
 *
 * @return                  true if data identified by |key| existed, false otherwise
 */
native bool:PDS_GetString(const key[], buffer[], maxLength);
