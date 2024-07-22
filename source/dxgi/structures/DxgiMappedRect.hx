#if D3D
package dxgi.structures;

import haxe.io.Bytes;
#if cpp
import cpp.Star;
import cpp.Pointer;
import cpp.vm.Gc;
import cpp.Function;
import cpp.UInt8;

using cpp.Native;
#end

class DxgiMappedRect
{
	private var backing:Star<NativeMappedRect>;

	public var widthPitch(get, set):Int;

	private function get_widthPitch():Int
		return backing.Pitch;

	private function set_widthPitch(n:Int):Int
		return backing.Pitch = n;

	public var imageBytes(get, set):Bytes;

	private var l:Int;

	private function get_imageBytes():Bytes
	{
		final arr:Array<UInt8> = Pointer.fromStar(backing.pBits).toUnmanagedArray(l);

		@:privateAccess
		final r = new Bytes(l, arr);
		return r;
	}

	private function set_imageBytes(n:Bytes):Bytes
	{
		backing.pBits = Pointer.ofArray(n.getData()).ptr;

		return n;
	}

	public function new(_existing:Pointer<NativeMappedRect> = null)
	{
		if (_existing == null)
		{
			backing = NativeMappedRect.createPtr();

			Gc.setFinalizer(this, Function.fromStaticFunction(finalizer));
		}
		else
			backing = _existing.ptr;
	}

	@:void
	static function finalizer(_obj:DxgiMappedRect)
	{
		Pointer.fromStar(_obj.backing).destroy();
	}
}

@:unreflective @:keep
@:include('dxgi.h')
@:native('DXGI_MAPPED_RECT')
@:structAccess
extern class NativeMappedRect
{
	@:native('Pitch')
	var Pitch:Int;
	@:native('pBits')
	var pBits:Star<UInt8>;

	@:native('DXGI_MAPPED_RECT')
	static function createRef():NativeMappedRect;
	@:native('new DXGI_MAPPED_RECT')
	static function createPtr():Star<NativeMappedRect>;
}
#end
