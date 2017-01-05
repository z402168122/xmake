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
-- @file        main.lua
--

-- imports
import("core.base.option")
import("core.project.task")
import("core.project.config")
import("core.project.global")
import("core.project.project")
import("core.platform.platform")
import("core.tool.debugger")

-- run binary target
function _run_binary(target)

    -- debugging?
    if option.get("debug") then

        -- debug it
        debugger.run(target:targetfile(), option.get("arguments"))
    else

        -- run it
        os.execv(target:targetfile(), option.get("arguments"))
    end
end

-- run target 
function _run_target(target)

    -- get kind
    local kind = target:get("kind")

    -- get script 
    local scripts =
    {
        binary = _run_binary
    }

    -- check
    assert(scripts[kind], "this target(%s) with kind(%s) can not be executed!", target:name(), kind)

    -- run it
    scripts[kind](target) 
end

-- run the given target 
function _run(target)

    -- the target scripts
    local scripts =
    {
        target:get("run_before")
    ,   target:get("run") or _run_target
    ,   target:get("run_after")
    }

    -- run the target scripts
    for i = 1, 3 do
        local script = scripts[i]
        if script ~= nil then
            script(target)
        end
    end
end

-- main
function main()

    -- get the target name
    local targetname = option.get("target")

    -- build it first
    task.run("build", {target = targetname})

    -- enter project directory
    local olddir = os.cd(project.directory())

    -- get target
    local target = nil
    if targetname then
        target = project.target(targetname)
    else
        -- find the first binary target
        for _, t in pairs(project.targets()) do
            if t:get("kind") == "binary" then
                target = t
                break
            end
        end
    end
    assert(target, "target(%s) not found!", targetname or "unknown")

    -- run the given target
    _run(target) 

    -- leave project directory
    os.cd(olddir)
end
