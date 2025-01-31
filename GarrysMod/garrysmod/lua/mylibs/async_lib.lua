--name async_cl_lib
--author ESF
--Source: Async Public Starfall Lib from Aeralius
--Note: Modified version of the public Starfall Async Lib from Aeralius to work with glua

-- Define prototype
local Async = setmetatable({}, {__call = function(t, ...) return t.create(...) end})
Async.__index = Async

-- Variables for Async
Async.thread = {}
Async.thread.pool = {}
Async.thread.running = coroutine.running
Async.wait = coroutine.wait
Async.yield = coroutine.yield

-- perf. Same as used in expression 2. perf( max usage in % ).
-- Checks if the quota used exceeds the specified usage percentage.
-- If it does, yields the coroutine.
-- @param use: The usage percentage threshold.
-- @param optimal: Boolean flag to determine if optimal performance is required.
-- @return: Returns true if the coroutine yields, otherwise false.
function Async.perf(use, optimal)
    local maxFrameTime = (1 / 60) * (use / 100) -- Assume 60 FPS as baseline
    if FrameTime() >= maxFrameTime then
        pcall(function() coroutine.yield() end, function()
            if optimal == false then	
                error("Must be in a thread to run. ")    
            end
        end)
        return true
    else
        return false
    end
end

-- perf2. Similar as normal perf, but it takes cpu time instead.
-- @param cpu: The CPU time threshold in microseconds.
-- @param optimal: Boolean flag to determine if optimal performance is required.
-- @return: Returns true if the coroutine yields, otherwise false.
function Async.perf2(cpu, optimal)
    if SysTime() >= cpu then
        pcall(function() coroutine.yield() end, function()
            if optimal == false then
                error("Must be in a thread to run. ")    
            end
        end)
        return true
    else
        return false
    end
end

-- Async.thread.create. Creates a new thread with the specified function.
-- @param func: The function to be executed in the thread.
-- @return: Returns a thread object.
function Async.thread.create(func)
    local thr =
    {
        args = {},
        running = false,
        co = coroutine.create(func),
        name = "unnamed_thread",
        
        -- run. Starts the thread with the provided arguments.
        -- @param ...: Arguments to be passed to the thread function.
        run = function(this, ...)
            if this.running == false then
                this.args = {...}
                this.running = true
                Async.thread.pool[tostring(this.co)] = this
            end
        end,
        
        -- stop. Stops the thread if it is running.
        stop = function(this)
            if this.running == true then
                this.running = false
                Async.thread.pool[tostring(this.co)] = nil
            end
        end,
        
        -- update. Updates the arguments for the thread function.
        -- @param ...: New arguments to be passed to the thread function.
        update = function(this, ...)
            this.args = {...}
        end,
        
        -- onExit, onYield, onReturn. Placeholder functions for thread events.
        onExit = function( ) end,
        onYield = function( ) end,
        onReturn = function( ) end
    }
    return thr
end

-- startThreading. Begins the threading system by hooking into the "tick" event.
function Async.startThreading()
    hook.Add("Tick","async_threading", function()
        for k, v in pairs(Async.thread.pool) do
            if v.args == nil then continue end
            if coroutine.status(v.co) ~= "suspended" then
				Async.thread.pool[k].onExit(Async.thread.pool[k].Return) Async.thread.pool[k] = nil continue
            end
            if coroutine.status(v.co) == "suspended" then
                Async.thread.pool[k].onYield(Async.thread.pool[k].Return)
                if Async.thread.pool[k].Return ~= nil then
                    Async.thread.pool[k].onReturn(Async.thread.pool[k].Return)
                end
            end
            pcall(function() Async.thread.pool[k].Return = coroutine.resume(v.co, unpack(v.args)) end, function(err) 
                print(err)
            end)
        end
    end)
end

-- stopThreading. Stops the threading system by removing the "tick" event hook.
function Async.stopThreading()
    hook.Remove("tick", "async_threading")
end

-- Return the module
return Async
