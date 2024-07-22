#if D3D
package d3d;

import haxe.PosInfos;
import haxe.Exception;
import dxgi.constants.DxgiError;
import d3d.CPPTypes;

/*@:unreflective
	@:keep
	@:include("DirectXHelpers.h") */
// soon, we make this native DirectXHelpers
class DirectXTK
{
	// not a part of the toolkit but whatever
	public static function ThrowIfFailed(hr:HRESULT, ?posInfo:PosInfos):Void
	{
		if (hr != Ok)
		{
			throw new Exception('An exception has occured in a DirectX class. Throwing an exception with hresult: $hr.\nInfo about the exception:\nClass name: ${posInfo.className} (File: ${posInfo.fileName})\nLine Number: ${posInfo.lineNumber}\nFunction name: ${posInfo.methodName}');
		}
	}
}
#end
