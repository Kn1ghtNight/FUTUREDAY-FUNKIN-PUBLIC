#if D3D
package dxgi.interfaces;

#if windows
import dxgi.interfaces.DxgiObject;
import dxgi.interfaces.DxgiObject.NativeIDXGIObject;
import com.GUID;
#end
#if cpp
import cpp.Star;
import d3d.CPPTypes;

using cpp.Native;
#end

class DxgiDeviceSubObject extends DxgiObject
{
	public function new()
	{
		super();
	}

	public function getDevice(uuid:GUID, Type:DxgiObject)
	{
		final ssT:Star<Star<DxgiObject>> = cast Type.ptr.addressOf();

		return (cast ptr : Star<NativeDxgiDeviceSubObject>).GetDevice(uuid, cast ssT);
	}
}

@:unreflective @:keep
@:include('dxgi.h')
@:structAccess @:native('IDXGIDeviceSubObject')
extern class NativeDxgiDeviceSubObject extends NativeIDXGIObject
{
	static inline function uuid():GUID
		return untyped __cpp__('__uuidof(IDXGIDeviceSubObject)');

	@:native('GetDevice')
	function GetDevice(uuid:GUID, ppObject:Star<Star<cpp.Void>>):HRESULT;
}
#end
