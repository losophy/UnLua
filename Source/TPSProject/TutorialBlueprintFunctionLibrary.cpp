#include "TutorialBlueprintFunctionLibrary.h"
#include "Kismet/KismetSystemLibrary.h"

#include "UnLua.h"

static void PrintScreen(const FString& Msg)
{
    UKismetSystemLibrary::PrintString(nullptr, Msg, true, false, FLinearColor(0, 0.66, 1), 100);
}

void UTutorialBlueprintFunctionLibrary::CallLuaByGlobalTable()
{
    PrintScreen(TEXT("[C++]CallLuaByGlobalTable 开始"));

    UnLua::FLuaEnv Env;
    const auto bSuccess = Env.DoString("G_08_CppCallLua = require 'Tutorials.08_CppCallLua'");
    check(bSuccess);

    const auto RetValues = UnLua::CallTableFunc(Env.GetMainState(), "G_08_CppCallLua", "CallMe", 1.1f, 2.2f);
    check(RetValues.Num() == 1);

    const auto Msg = FString::Printf(TEXT("[C++]收到来自Lua的返回，结果=%f"), RetValues[0].Value<float>());
    PrintScreen(Msg);
    PrintScreen(TEXT("[C++]CallLuaByGlobalTable 结束"));
}

void UTutorialBlueprintFunctionLibrary::CallLuaByFLuaTable()
{
    PrintScreen(TEXT("[C++]CallLuaByFLuaTable 开始"));
    UnLua::FLuaEnv Env;

    const auto Require = UnLua::FLuaFunction(&Env, "_G", "require");
    const auto RetValues1 = Require.Call("Tutorials.08_CppCallLua");
    check(RetValues1.Num() == 2);

    const auto RetValue = RetValues1[0];
    const auto LuaTable = UnLua::FLuaTable(&Env, RetValue);
    const auto RetValues2 = LuaTable.Call("CallMe", 3.3f, 4.4f);
    check(RetValues2.Num() == 1);

    const auto Msg = FString::Printf(TEXT("[C++]收到来自Lua的返回，结果=%f"), RetValues2[0].Value<float>());
    PrintScreen(Msg);
    PrintScreen(TEXT("[C++]CallLuaByFLuaTable 结束"));
}

bool CustomLoader1(UnLua::FLuaEnv& Env, const FString& RelativePath, TArray<uint8>& Data, FString& FullPath)
{
    // 将点分隔的路径转换为斜杠分隔的路径（如"Game.Module" → "Game/Module"）
    const auto SlashedRelativePath = RelativePath.Replace(TEXT("."), TEXT("/"));
    // 构造第一种可能的文件路径格式：BasePath/Path/To/Module.lua
    FullPath = FString::Printf(TEXT("%s%s.lua"), *GLuaSrcFullPath, *SlashedRelativePath);

    // 尝试加载第一种路径格式的文件
    if (FFileHelper::LoadFileToArray(Data, *FullPath, FILEREAD_Silent))
        return true;

    // 如果第一种路径失败，尝试第二种路径格式：BasePath/Path/To/Module/Index.lua
    FullPath.ReplaceInline(TEXT(".lua"), TEXT("/Index.lua"));
    // 尝试加载第二种路径格式的文件
    if (FFileHelper::LoadFileToArray(Data, *FullPath, FILEREAD_Silent))
        return true;

    return false;
}

bool CustomLoader2(UnLua::FLuaEnv& Env, const FString& RelativePath, TArray<uint8>& Data, FString& FullPath)
{
    // 将点分隔的路径转换为斜杠分隔的路径（如"Game.Module" → "Game/Module"）
    const auto SlashedRelativePath = RelativePath.Replace(TEXT("."), TEXT("/"));
    // 获取Lua主状态机
    const auto L = Env.GetMainState();
    // 获取Lua的package表
    lua_getglobal(L, "package");
    // 获取package.path字段（Lua模块搜索路径）
    lua_getfield(L, -1, "path");
    // 转换为C字符串
    const char* Path = lua_tostring(L, -1);
    // 弹出path和package表（清理栈）
    lua_pop(L, 2);
    // 如果没有找到package.path，直接返回失败
    if (!Path)
        return false;

    // 将package.path按分号分割成多个搜索路径
    TArray<FString> Parts;
    FString(Path).ParseIntoArray(Parts, TEXT(";"), false);

    for (auto& Part : Parts)
    {
        // 将路径中的问号(?)替换为模块路径
        Part.ReplaceInline(TEXT("?"), *SlashedRelativePath);
        // 规范化路径（移除多余的./或../等）
        FPaths::CollapseRelativeDirectories(Part);
        
        // 处理相对路径和绝对路径
        if (FPaths::IsRelative(Part))
            FullPath = FPaths::ConvertRelativePathToFull(GLuaSrcFullPath, Part);
        else
            FullPath = Part;// 已经是绝对路径，直接使用

        // 尝试加载文件
        if (FFileHelper::LoadFileToArray(Data, *FullPath, FILEREAD_Silent))
            return true;
    }

    return false;
}

void UTutorialBlueprintFunctionLibrary::SetupCustomLoader(int Index)
{
    switch (Index)
    {
    case 0:
        FUnLuaDelegates::CustomLoadLuaFile.Unbind();
        break;
    case 1:
        FUnLuaDelegates::CustomLoadLuaFile.BindStatic(CustomLoader1);
        break;
    case 2:
        FUnLuaDelegates::CustomLoadLuaFile.BindStatic(CustomLoader2);
        break;
    }
}
