--!The Make-like Build Utility based on Lua
-- 
-- XMake is free software; you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation; either version 2.1 of the License, or
-- (at your option) any later version.
-- 
-- XMake is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.
-- 
-- You should have received a copy of the GNU Lesser General Public License
-- along with XMake; 
-- If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
-- 
-- Copyright (C) 2015 - 2016, ruki All rights reserved.
--
-- @author      ruki
-- @file        xmake.lua
--

-- define platform
platform("linux")

    -- set os
    set_os("linux")

    -- set hosts
    set_hosts("macosx", "linux", "windows")

    -- set archs
    set_archs("i386", "x86_64")

    -- set tooldirs
    set_tooldirs("/usr/bin", "/usr/local/bin", "/opt/bin", "/opt/local/bin")

    -- on install
    on_install("install")

    -- on uninstall
    on_uninstall("uninstall")

    -- on check
    on_check("check")

    -- on load
    on_load("load")



