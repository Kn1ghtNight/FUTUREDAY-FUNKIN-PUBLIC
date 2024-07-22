package cpp.utils;

import cpp.Char;
import cpp.RawConstPointer;
import haxe.extern.AsVar;

extern abstract VarConstCharStar(RawConstPointer<Char>) to (RawConstPointer<Char>)
{
	inline function new(_string:AsVar<String>)
	{
		this = cpp.NativeString.raw(_string);
	}

	@:from static public inline function fromString(_string:String):VarConstCharStar
	{
		return new VarConstCharStar(_string);
	}

	@:to extern public inline function toString():String
	{
		return new String(untyped this);
	}

	@:to extern public inline function toPointer():RawConstPointer<Char>
	{
		return this;
	}
}
