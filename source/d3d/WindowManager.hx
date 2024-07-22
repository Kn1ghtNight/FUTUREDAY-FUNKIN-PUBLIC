#if D3D
package d3d;

import com.HWND;

@:include("windows.h")
class WindowManager
{
	public static function GetHWND():HWND
	{
		return WindowFunctions.getActiveWin();
	}
}

@:unreflective @:keep
@:include('windows.h')
extern private final class WindowFunctions
{
	@:native('GetActiveWindow')
	static function getActiveWin():HWND;
}
#end
