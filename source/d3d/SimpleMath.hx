#if D3D
package d3d;

import cpp.Function;
import cpp.vm.Gc;
import cpp.Pointer;
import cpp.Star;

@:forward
abstract XMFloat(Star<NativeXMFloat>)
{
	public function new(_existing:Pointer<NativeXMFloat> = null)
	{
		if (_existing == null)
			this = NativeXMFloat.createPtr();
		else
			this = _existing.ptr;

		Gc.setFinalizer(this, Function.fromStaticFunction(kms));
	}

	static function kms(self:Star<NativeXMFloat>)
	{
		Pointer.fromStar(self).destroy();
	}
}

@:unreflective @:keep
@:include('directxmath.h')
@:native('DirectX::XMFLOAT4X4')
@:structAccess
extern class NativeXMFloat
{
	@:native('_11')
	var _11:cpp.Float32;

	@:native('new DirectX::XMFLOAT4X4')
	static function createPtr():Star<NativeXMFloat>;
}

@:unreflective @:keep
@:include('SimpleMath.h')
@:native('DirectX::SimpleMath::Matrix')
@:structAccess
extern class NativeMatrix extends NativeXMFloat {}
#end
