#if D3D
package dxgi.structures;

#if windows
import dxgi.enumerations.DxgiFormat;
import dxgi.enumerations.DxgiFormat.NativeDXGIFormat;
import dxgi.structures.DxgiSampleDescription;
#end
#if cpp
import d3d.CPPTypes;
import cpp.Star;
import cpp.vm.Gc;
import cpp.Function;
import cpp.Pointer;
#end

class DxgiSurfaceDesc
{
	private var backing:Star<NativeSurfaceDesc>;

	public var width(get, set):Int;

	private function get_width():Int
		return backing.width;

	private function set_width(n:Int):Int
		return backing.width = n;

	public var height(get, set):Int;

	private function get_height():Int
		return backing.height;

	private function set_height(n:Int):Int
		return backing.height = n;

	// still a DXGIFormat
	public var format(get, set):DxgiFormat;

	private function get_format():DxgiFormat
		return cast backing.format;

	private function set_format(n:DxgiFormat):DxgiFormat
	{
		backing.format = cast n;
		return n;
	}

	public var sampleDesc(get, set):DxgiSampleDescription;

	private function get_sampleDesc():DxgiSampleDescription
	{
		final ret:DxgiSampleDescription = new DxgiSampleDescription();
		ret.quality = backing.sampleDesc.quality;
		ret.count = backing.sampleDesc.count;
		return ret;
	}

	private function set_sampleDesc(n:DxgiSampleDescription):DxgiSampleDescription
	{
		backing.sampleDesc.quality = n.quality;
		backing.sampleDesc.count = n.count;
		return n;
	}

	public function new(_existing:Pointer<NativeSurfaceDesc> = null)
	{
		if (_existing == null)
		{
			backing = NativeSurfaceDesc.createPtr();

			Gc.setFinalizer(this, Function.fromStaticFunction(finalize));
		}
		else
			backing = _existing.ptr;
	}

	@:void
	static function finalize(_obj:DxgiSurfaceDesc)
	{
		Pointer.fromStar(_obj.backing).destroy();
	}
}

@:unreflective @:keep
@:structAccess
@:include('dxgi.h')
@:native("DXGI_SURFACE_DESC")
extern class NativeSurfaceDesc
{
	@:native("Width")
	var width:UINT;

	@:native("Height")
	var height:UINT;

	@:native("Format")
	var format:NativeDXGIFormat;

	@:native("SampleDesc")
	var sampleDesc:DxgiSampleDescription.NativeDXGISampleDescription;

	@:native('DXGI_SURFACE_DESC')
	static function createRef():NativeSurfaceDesc;

	@:native('new DXGI_SURFACE_DESC')
	static function createPtr():Star<NativeSurfaceDesc>;
}
#end
