#if D3D
package dxgi.interfaces;

#if windows
import com.Unknown;
import com.GUID;
import dxgi.constants.DxgiUsage;
import com.Unknown.NativeIUnknown;
import dxgi.enumerations.DxgiAlphaMode;
import dxgi.structures.DxgiSurfaceDesc;
import dxgi.structures.DxgiSurfaceDesc.NativeSurfaceDesc;
import d3d.SharedResource;
import dxgi.interfaces.DxgiObject;
import dxgi.interfaces.DxgiObject.NativeIDXGIObject;
import d3d.SharedResource.NativeSharedResource;
import dxgi.interfaces.DxgiAdapter.NativeIDXGIAdapter;
import dxgi.interfaces.DxgiAdapter;
import dxgi.interfaces.DxgiSurface;
import dxgi.interfaces.DxgiSurface.NativeDxgiSurface;
import d3d.DirectXTK.ThrowIfFailed;
#end
#if cpp
import d3d.CPPTypes;
import cpp.Star;

using cpp.Native;
#end

/**
	* DXGI_RESIDENCY_FULLY_RESIDENT
	Value: 1
	The resource is located in video memory.
	DXGI_RESIDENCY_RESIDENT_IN_SHARED_MEMORY
	Value: 2
	At least some of the resource is located in CPU memory.
	DXGI_RESIDENCY_EVICTED_TO_DISK
	Value: 3
	At least some of the resource has been paged out to the hard drive.
 */
enum abstract DXGI_RESIDENCY(Int) to Int
{
	var DXGI_RESIDENCY_FULLY_RESIDENT = 1;
	var DXGI_RESIDENCY_RESIDENT_IN_SHARED_MEMORY = 2;
	var DXGI_RESIDENCY_EVICTED_TO_DISK = 3;
}

@:unreflective @:keep
@:include('dxgi.h') @:native('DXGI_RESIDENCY')
extern class NativeResidency {}

class DxgiDevice extends DxgiObject
{
	public function new()
	{
		super();
	}

	public function createSurface(desc:DxgiSurfaceDesc, numSurfaces:UINT, usage:DxgiUsage, sharedResource:SharedResource, surface:DxgiSurface):HRESULT
	{
		@:privateAccess
		return (cast ptr : Star<NativeDxgiDevice>).CreateSurface(desc.backing, numSurfaces, usage, sharedResource.backing,
			(cast(surface.ptr.addressOf()) : Star<Star<NativeDxgiSurface>>));
	}

	public function getAdapter(adapter:DxgiAdapter):HRESULT
	{
		return (cast ptr : Star<NativeDxgiDevice>).GetAdapter((cast(adapter.ptr.addressOf()) : Star<Star<NativeIDXGIAdapter>>));
	}

	public function getGPUThreadPriority():Int
	{
		var i:Int = -1;
		ThrowIfFailed((cast ptr : Star<NativeDxgiDevice>).GetGPUThreadPriority(i.addressOf()));
		i == -1?throw 'Couldn\'t retrieve GPU thread priority!':return
		i;
	}

	public function queryResourceResidency(resource:Unknown, numResources:UINT):DXGI_RESIDENCY
	{
		var residency:DXGI_RESIDENCY = DXGI_RESIDENCY_FULLY_RESIDENT;
		ThrowIfFailed((cast ptr : Star<NativeDxgiDevice>).QueryResourceResidency(cast(resource.ptr.addressOf()), cast residency.addressOf(), numResources));
		return residency;
	}

	public function setGPUThreadPriority(Priority:Int):HRESULT
	{
		return (cast ptr : Star<NativeDxgiDevice>).SetGPUThreadPriority(Priority);
	}
}

@:unreflective @:keep
@:include('dxgi.h')
@:native("IDXGIDevice")
@:structAccess
extern class NativeDxgiDevice extends NativeIDXGIObject
{
	static inline function uuid():GUID
	{
		return untyped __cpp__('__uuidof(IDXGIDevice)');
	}

	@:native("CreateSurface")
	function CreateSurface(pDesc:Star<NativeSurfaceDesc>, NumSurfaces:UINT, Usage:DxgiUsage, pSharedResource:Star<NativeSharedResource>,
		ppSurface:Star<Star<NativeDxgiSurface>>):HRESULT;
	@:native("GetAdapter")
	function GetAdapter(pAdapter:Star<Star<NativeIDXGIAdapter>>):HRESULT;
	@:native("GetGPUThreadPriority")
	function GetGPUThreadPriority(pPriority:Star<Int>):HRESULT;
	@:native("QueryResourceResidency")
	function QueryResourceResidency(ppResources:Star<Star<NativeIUnknown>>, pResidencyStatus:Star<NativeResidency>, NumResources:UINT):HRESULT;
	@:native("SetGPUThreadPriority")
	function SetGPUThreadPriority(Priority:Int):HRESULT;
}
#end
