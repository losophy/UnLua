---@type UMG_Main_C
local M = UnLua.Class()

function M:Construct()
	self.ExitButton.OnClicked:Add(self, M.OnClicked_ExitButton)	
	--self.ExitButton.OnClicked:Add(self, function(Widget) UE.UKismetSystemLibrary.ExecuteConsoleCommand(Widget, "exit") end )
end

function M:OnClicked_ExitButton()
	--KismetSystemLibrary，这是一个全局可用的功能库，提供了多种实用功能，如打印堆栈跟踪、验证对象有效性、碰撞检测等
	UE.UKismetSystemLibrary.ExecuteConsoleCommand(self, "exit")

	--这个就是蓝图中包装好的QuitGame函数，和上一句的作用是一样的，上面是exit命令，这里是quit命令
	-- UE.UKismetSystemLibrary.QuitGame(self,null,UE.EQuitPreference.Quit,false)
	
end

return M
