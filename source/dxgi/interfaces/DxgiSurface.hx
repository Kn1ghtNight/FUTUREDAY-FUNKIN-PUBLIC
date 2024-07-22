#if D3D
package dxgi.interfaces;

#if windows
import dxgi.structures.DxgiSurfaceDesc;
import dxgi.structures.DxgiSurfaceDesc.NativeSurfaceDesc;
import dxgi.structures.DxgiMappedRect.NativeMappedRect;
import dxgi.structures.DxgiMappedRect;
import dxgi.interfaces.DxgiDeviceSubObject;
import dxgi.interfaces.DxgiDeviceSubObject.NativeDxgiDeviceSubObject;
import d3d.DirectXTK.ThrowIfFailed;
#end
#if cpp
import d3d.CPPTypes;
import cpp.Star;

using cpp.Native;
#end

class DxgiSurface extends DxgiDeviceSubObject
{
	public function new()
	{
		super();
	}

	public function getDesc():DxgiSurfaceDesc
	{
		var ref:DxgiSurfaceDesc = new DxgiSurfaceDesc();
		@:privateAccess
		final hr:HRESULT = (cast ptr : Star<NativeDxgiSurface>).GetDesc(cast ref.backing);
		ThrowIfFailed(hr);
		return ref;
	}

	public function map(lockedRect:DxgiMappedRect, MapFlags:UINT):HRESULT
	{
		@:privateAccess
		return (cast ptr : Star<NativeDxgiSurface>).Map(lockedRect.backing, MapFlags);
	}

	public function unmap():HRESULT
	{
		return (cast ptr : Star<NativeDxgiSurface>).Unmap();
	}
}

@:unreflective @:keep
@:structAccess
@:include('dxgi.h')
@:native("IDXGISurface")
extern class NativeDxgiSurface extends NativeDxgiDeviceSubObject
{
	@:native('GetDesc')
	function GetDesc(pDesc:Star<NativeSurfaceDesc>):HRESULT;
	@:native('Map')
	function Map(pLockedRect:Star<NativeMappedRect>, MapFlags:UINT):HRESULT;
	@:native('Unmap')
	function Unmap():HRESULT;
}
#end
