#if D3D
package d3d;

#if cpp
import d3d.CPPTypes;
import cpp.Star;
import cpp.Pointer;
import cpp.Function;
import cpp.vm.Gc;
#end

@:unreflective @:keep
@:structAccess @:native('HANDLE')
extern class HANDLE
{
	//
}

class SharedResource
{
	private var backing:Star<NativeSharedResource>;

	public var handle(get, set):HANDLE;

	private function get_handle():HANDLE
		return backing.Handle;

	private function set_handle(n:HANDLE):HANDLE
		return backing.Handle = n;

	public function new(_existin:Pointer<NativeSharedResource> = null)
	{
		if (_existin == null)
		{
			backing = NativeSharedResource.createPtr();

			Gc.setFinalizer(this, Function.fromStaticFunction(finalizer));
		}
	}

	@:void
	static function finalizer(_obj:SharedResource)
	{
		Pointer.fromStar(_obj.backing).destroy();
	}
}

@:unreflective @:keep
@:structAccess
@:include('dxgi.h')
@:native('DXGI_SHARED_RESOURCE')
extern class NativeSharedResource
{
	@:native('Handle')
	var Handle:HANDLE;

	@:native('DXGI_SHARED_RESOURCE')
	static function createRef():NativeSharedResource;
	@:native('new DXGI_SHARED_RESOURCE')
	static function createPtr():Star<NativeSharedResource>;
}
#end
