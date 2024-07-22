package cpp.utils;

import cpp.Star;
import cpp.Pointer;
import cpp.AutoCast;
import cpp.Reference;
import cpp.RawPointer;
import cpp.NativeArray;
import cpp.ConstPointer;
import haxe.extern.AsVar;

@:coreType
@:native("cpp.Pointer")
@:include("cpp/Pointer.h")
@:semantics(variable)
extern class VarPointer<T> extends ConstPointer<T> implements ArrayAccess<T>
{
	var ref(get, set):Reference<T>;

	function get_ref():Reference<T>;
	function set_ref(_t:T):Reference<T>;

	function setAt(_inIndex:Int, _value:T):Void;

	static function fromRaw<T>(_ptr:RawPointer<T>):Pointer<T>;

	@:native("::cpp::Pointer_obj::fromRaw")
	static function fromStar<T>(_star:Star<T>):Pointer<T>;

	@:native("::cpp::Pointer_obj::fromHandle")
	static function nativeFromHandle<T>(_inHandle:Dynamic, ?_inKind:String):AutoCast;
	inline static function fromHandle<T>(_inHandle:Dynamic, ?_inKind:String):Pointer<T>
	{
		return cast nativeFromHandle(_inHandle, _inKind);
	}

	static function fromPointer<T>(_inNativePointer:Dynamic):Pointer<T>;

	static function addressOf<T>(_inVariable:AsVar<cpp.Reference<T>>):VarPointer<T>;

	static function endOf<T:{}>(_inVariable:T):Pointer<cpp.Void>;

	@:native("::cpp::Pointer_obj::arrayElem")
	static function nativeArrayElem<T>(_array:AsVar<Array<T>>, _inElem:Int):AutoCast;
	inline static function arrayElem<T>(_array:AsVar<Array<T>>, _inElem:Int):Pointer<T>
	{
		return cast nativeArrayElem(_array, _inElem);
	}

	@:native("::cpp::Pointer_obj::ofArray")
	static function nativeOfArray<T>(_array:AsVar<Array<T>>):AutoCast;
	inline static function ofArray<T>(_array:AsVar<Array<T>>):Pointer<T>
	{
		return cast nativeOfArray(_array);
	}

	inline function toUnmanagedArray(_elementCount:Int):Array<T>
	{
		var result = new Array<T>();

		NativeArray.setUnmanagedData(result, this, _elementCount);

		return result;
	}

	inline function toUnmanagedVector(_elementCount:Int):haxe.ds.Vector<T>
	{
		return cast toUnmanagedArray(_elementCount);
	}

	override function inc():Pointer<T>;
	override function dec():Pointer<T>;
	override function incBy(_inT:Int):Pointer<T>;
	override function decBy(_inT:Int):Pointer<T>;
	override function add(_inT:Int):Pointer<T>;
	override function sub(_inT:Int):Pointer<T>;

	function postIncRef():Reference<T>;

	function destroy():Void;
	function destroyArray():Void;
}
