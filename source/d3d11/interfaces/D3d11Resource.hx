#if D3D
package d3d11.interfaces;

import com.GUID;
import com.Unknown;
import cpp.Star;

using cpp.Native;

/**
 * A resource interface provides common actions on all resources.
 */
class D3d11Resource extends Unknown
{
	public function new()
	{
		super();
	}

	public function getType(resourceDimensionOUT:ResourceDimension):Void
	{
		(cast ptr : Star<NativeID3D11Resource>).GetType(cast resourceDimensionOUT.addressOf());
	}
}

enum abstract ResourceDimension(Int) to Int
{
	var Unknown = 0;
	var Buffer = 1;
	var Texture1D = 2;
	var Texture2D = 3;
	var Texture3D = 4;
}

@:keep @:unreflective @:include('d3d11.h')
@:native('D3D11_RESOURCE_DIMENSION')
extern class NativeResourceDimension {}

@:keep
@:unreflective
@:structAccess
@:include('d3d11.h')
@:native('ID3D11Resource')
extern class NativeID3D11Resource extends NativeIUnknown
{
	inline static function uuid():GUID
	{
		return untyped __cpp__('__uuidof(ID3D11Resource)');
	}

	@:native('GetType')
	function GetType(pResourceDimension:Star<NativeResourceDimension>):Void;
}
#end
