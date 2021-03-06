--!The Make-like Build Utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2017, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        main.lua
--

-- define module: main
local main = main or {}

-- load modules
local os            = require("base/os")
local path          = require("base/path")
local utils         = require("base/utils")
local option        = require("base/option")
local profiler      = require("base/profiler")
local deprecated    = require("base/deprecated")
local task          = require("project/task")
local history       = require("project/history")

-- init the option menu
local menu =
{
    -- title
    title = xmake._VERSION .. ", The Make-like Build Utility based on Lua"

    -- copyright
,   copyright = "Copyright (C) 2015-2016 Ruki Wang, ${underline}tboox.org${clear}, ${underline}xmake.io${clear}\nCopyright (C) 2005-2015 Mike Pall, ${underline}luajit.org${clear}"

    -- the tasks: xmake [task]
,   task.menu

}

-- done help
function main._help()

    -- done help
    if option.get("help") then
    
        -- print menu
        option.show_menu(option.taskname())

        -- ok
        return true

    -- done version
    elseif option.get("version") then

        -- print title
        if menu.title then
            utils.cprint(menu.title)
        end

        -- print copyright
        if menu.copyright then
            utils.cprint(menu.copyright)
        end

        -- ok
        return true
    end
end

-- the init function for main
function main._init()

    -- init the project directory
    local projectdir = option.find(xmake._ARGV, "project", "P") or xmake._PROJECT_DIR
    if projectdir and not path.is_absolute(projectdir) then
        projectdir = path.absolute(projectdir)
    elseif projectdir then 
        projectdir = path.translate(projectdir)
    end
    xmake._PROJECT_DIR = projectdir
    assert(projectdir)

    -- init the xmake.lua file path
    local projectfile = option.find(xmake._ARGV, "file", "F") or xmake._PROJECT_FILE
    if projectfile and not path.is_absolute(projectfile) then
        projectfile = path.absolute(projectfile, projectdir)
    end
    xmake._PROJECT_FILE = projectfile
    assert(projectfile)
end

-- the main function
function main.done()

    -- start profiling
--    profiler:start()

    -- init 
    main._init()

    -- init option 
    if not option.init(menu) then 
        return -1
    end

    -- run help?
    if main._help() then
        return 0
    end

    -- save command lines to history
    history.save("cmdlines", option.cmdline())

    -- run task    
    local ok, errors = task.run(option.taskname() or "build")
    if not ok then
        utils.error(errors)
        return -1
    end

    -- dump deprecated entries
    deprecated.dump()

    -- stop profiling
--    profiler:stop()

    -- ok
    return 0
end

-- return module: main
return main
