/*!The Automatic Cross-platform Build Tool
 * 
 * XMake is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 * 
 * XMake is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with XMake; 
 * If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
 * 
 * Copyright (C) 2009 - 2015, ruki All rights reserved.
 *
 * @author      ruki
 * @file        load_xproj.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "load_xproj"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_char_t const* xm_preprocessor_load_xproj_to_string(tb_stream_ref_t stream, tb_string_ref_t string)
{
    // check
    tb_assert_and_check_return_val(stream && string, tb_null);

    // init value
    tb_string_t value;
    if (!tb_string_init(&value)) return tb_null;

    // init temporary value
    tb_string_t value_temp;
    if (!tb_string_init(&value_temp)) return tb_null;

    // done
    tb_bool_t is_value = tb_false;
    tb_bool_t is_values = tb_false;
    while (!tb_stream_beof(stream))
    {
        // read character
        tb_char_t ch = (tb_char_t)tb_stream_bread_u8(stream);
        if (ch)
        {
            // is values?
            if (is_values)
            {
                // is value?
                if (is_value && ch != ',' && ch != ':' && ch != '{' && ch != '}' && ch != '\r' && ch != '\n')
                {
                    // append to value
                    tb_string_chrcat(&value, ch);
                }
                // ',' or ':' or '{' or newline?
                else if (ch == ',' || ch == ':' || ch == '{' || ch == '}' || ch == '\r' || ch == '\n') 
                {
                    // has value?
                    if (is_value)
                    {
                        // values end? append ')' and newline first
                        if (ch == ':') tb_string_cstrcat(string, ")\n");
                        else
                        {
                            // trim the left spaces
                            tb_string_ltrim(&value);

                            // trim the right spaces
                            tb_string_rtrim(&value);

                            // wrap "xxx" 
                            if (tb_string_size(&value))
                            {
                                // it has been "xxx"? only copy it
                                if (tb_string_charat(&value, 0) == '\"')
                                    tb_string_strcpy(&value_temp, &value);
                                // wrap it
                                else
                                {
                                    tb_string_clear(&value_temp);
                                    tb_string_chrcat(&value_temp, '\"');
                                    tb_string_strcat(&value_temp, &value);
                                    tb_string_chrcat(&value_temp, '\"');
                                }
                                
                                // clear value first
                                tb_string_clear(&value);

                                // copy and replace '\"' to "\\""
                                tb_char_t const*    s = tb_string_cstr(&value_temp);
                                tb_size_t           n = tb_string_size(&value_temp);
                                tb_size_t           i = 0;
                                for (i = 0; i < n; i++)
                                {
                                    // replace '\"' to "\\""
                                    if (i && i != n - 1 && s[i] == '\"') tb_string_cstrcat(&value, "\\\"");
                                    // only copy iy
                                    else tb_string_chrcat(&value, s[i]);
                                }
                            }
                        }

                        // append value to string
                        if (tb_string_size(&value)) tb_string_strcat(string, &value);

                        // clear value
                        tb_string_clear(&value);

                        // not value now
                        is_value = tb_false;
                    }

                    // continue to enter values? onyl replace ':' to '('
                    if (ch == ':') tb_string_chrcat(string, '(');
                    // '{' ?
                    else if (ch == '{') 
                    {
                        // not values now
                        is_values = tb_false;

                        // append ')' and newline
                        tb_string_cstrcat(string, ")\n");
                    }
                    // '}' ?
                    else if (ch == '}') 
                    {
                        // not values now
                        is_values = tb_false;

                        // append ')' and replace '}' to scopend 
                        tb_string_cstrcat(string, ")\nscopend()");
                    }
                    // skip newline
                    else if (ch == '\r' || ch == '\n') ;
                    // append to string
                    else tb_string_chrcat(string, ch);
                }
                else
                {
                    // value now
                    is_value = tb_true;

                    // append to value
                    tb_string_chrcat(&value, ch);
                }
            }
            // enter values?
            else if (ch == ':')
            {
                // values now
                is_values = tb_true;

                // replace ':' to '('
                tb_string_chrcat(string, '(');
            }
            // replace '}' and newline to scopend 
            else if (ch == '}') tb_string_cstrcat(string, "\nscopend()");
            // append it
            else tb_string_chrcat(string, ch);
        }
        else
        {
            // end
            break;
        }
    }

    // exit value
    tb_string_exit(&value);

    // exit temporary value
    tb_string_exit(&value_temp);

    // ok?
    return tb_string_size(string)? tb_string_cstr(string) : tb_null;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_int_t xm_preprocessor_load_xproj(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get the xmake.xproj path 
    tb_char_t const* path = luaL_checkstring(lua, 1);
    tb_check_return_val(path, 0);

    // done
    tb_int_t        ok = 0;
    tb_stream_ref_t stream = tb_null;
    tb_string_t     string;
    do
    {
        // init string
        if (!tb_string_init(&string)) break;

        // init stream
        stream = tb_stream_init_from_file(path, TB_FILE_MODE_RO);
        tb_assert_and_check_break(stream);

        // open stream
        if (!tb_stream_open(stream)) break;

        // load xmake.xproj to the string and preprocess it
        tb_char_t const* xproj = xm_preprocessor_load_xproj_to_string(stream, &string);
        tb_assert_and_check_break(xproj);

        tb_printf("%s", xproj);

        // load xmake.xproj string to script
        //if (luaL_loadstring(lua, "project(\"console\")\nscopend()")) 
        if (luaL_loadstring(lua, xproj)) 
        {
            // error
            tb_printf("error: %s\n", lua_tostring(lua, -1));

            // failed
            break;
        }
       
        // ok
        ok = 1;

    } while (0);

    // exit stream
    if (stream) tb_stream_exit(stream);
    stream = tb_null;

    // exit string
    tb_string_exit(&string);

    // ok?
    return ok;
}