---@type UTPSGameInstance
require("LuaPanda").start("127.0.0.1", 8818);
local M = UnLua.Class()

function M:ReceiveInit()
	print("TPSGameInstance:ReceiveInit")
end

function M:ReceiveShutdown()
    print("TPSGameInstance:ReceiveShutdown")
end

return M