-- ==========================================
-- 圣奥里反作弊综合拦截层 (FMR Hook Core)
-- ==========================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- 1. 定义反作弊关键词与拦截名单
local BlacklistMethods = {
    "TeleportDetect", "CHECKER_1", "CHECKER", "GUI_CHECK", 
    "OneMoreTime", "checkingSPEED", "BANREMOTE", "PERMAIDBAN", 
    "KICKREMOTE", "BR_KICKPC", "BR_KICKMOBILE"
}
local BlacklistNames = {"AntiCheat", "Detector", "BypassCheck", "Log", "Report"}

-- 2. Hook __namecall (拦截检测指令与发包)
local oldNamecall
pcall(function()
    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    oldNamecall = mt.__namecall
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        -- 拦截 Kick
        if method == "Kick" and self == LocalPlayer then
            return nil
        end
        
        -- 拦截敏感方法调用
        if method == "FireServer" or method == "InvokeServer" then
            local targetName = tostring(args[1])
            for _, blocked in ipairs(BlacklistMethods) do
                if targetName == blocked then
                    return nil
                end
            end
        end
        return oldNamecall(self, ...)
    end)
    setreadonly(mt, true)
end)

-- 3. Hook Instance.__index (隐藏 GUI 与异常模块)
local oldIndex
pcall(function()
    local instanceMt = getrawmetatable("Instance")
    if instanceMt then
        setreadonly(instanceMt, false)
        oldIndex = instanceMt.__index
        instanceMt.__index = newcclosure(function(self, key)
            -- 拦截 FindFirstChild / GetChildren / GetDescendants
            if key == "FindFirstChild" or key == "GetChildren" or key == "GetDescendants" then
                return newcclosure(function(_, ...)
                    local originalResult = self[key](self, ...)
                    -- 如果反作弊在找我们的 GUI，返回 nil
                    if key == "FindFirstChild" then
                        local nameToFind = tostring((...))
                        for _, bannedName in ipairs(BlacklistNames) do
                            if nameToFind:find(bannedName) then
                                return nil
                            end
                        end
                    end
                    return originalResult
                end)
            end
            return oldIndex(self, key)
        end)
        setreadonly(instanceMt, true)
    end
end)

-- 4. 断开反作弊连接 (利用 getconnections)
if getconnections then
    for _, conn in pairs(getconnections(RunService.Heartbeat)) do
        pcall(function()
            local func = conn.Function
            if func then
                local info = debug.getinfo(func)
                if info and info.short_src then
                    local src = tostring(info.short_src)
                    for _, blocked in ipairs(BlacklistNames) do
                        if src:find(blocked) then
                            conn:Disable() -- 或 conn:Disconnect()
                            break
                        end
                    end
                end
            end
        end)
    end
end

print("[Anti-Cheat] FMR 拦截层已激活，圣奥里检测已静默。")