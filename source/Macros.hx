package;

import haxe.macro.Type;
import haxe.macro.Context;
import haxe.macro.Expr;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

using Lambda;
using StringTools;

class Macros
{
	/**taken from haxe cookbook, such a useful function smh
		instead of having to do this.cum = cum; just call this. it automatically sets everything to the function field
		no fancy docs just talking to you as a friend lol!!
	 */
	macro public static function initLocals():Expr
	{
		var locals = Context.getLocalVars();
		var fields = Context.getLocalClass().get().fields.get();

		var exprs:Array<Expr> = [];
		for (local in locals.keys())
			(fields.exists(function(field) return field.name == local))
		?exprs.push
		(macro this.$local = $i{local}) : throw
		new Error(Context.getLocalClass() + " has no field " + local, Context.currentPos());

		// Generates a block expression from the given expression array
		return macro $b{exprs};
	}

	private static final exceptions:Array<String> = ["lime", "d3d", "d3d11", "dxgi", "Macros.hx", "cpp", "engine"];

	macro public static function fillClasses():Array<Field>
	{
		final fields = Context.getBuildFields();
		var leClasses:Array<String> = [];

		inline function pushType(name:String):Void
		{
			final typesInFile:Array<Type> = Context.getModule(name.replace(".hx", "").replace("/", "."));

			for (type in typesInFile)
			{
				if (type.getName() == "TInst")
				{
					final classDef:ClassType = cast(type.getParameters()[0].get());

					if (!classDef.isAbstract && !classDef.isInterface && !classDef.isExtern && classDef.name != "Action_Impl_")
					{
						leClasses.push(classDef.module);
					}
				}
			}
		}

		function checkInDirectory(name:String):Void
		{
			for (fileOrDirectory in FileSystem.readDirectory('source/${name}'))
			{
				if (FileSystem.isDirectory('source/${name}/${fileOrDirectory}'))
				{
					checkInDirectory('${name}/${fileOrDirectory}');
					continue;
				}

				pushType('$name/$fileOrDirectory');
			}
		}

		for (fileOrFolder in FileSystem.readDirectory("source"))
		{
			if (exceptions.contains(fileOrFolder))
				continue;

			if (/**if file**/ !FileSystem.isDirectory('source/$fileOrFolder'))
				pushType(fileOrFolder);
			else if (/**is directory**/ FileSystem.isDirectory('source/$fileOrFolder'))
				// new for loop to scan directory
				// k we're in source rn, we're on source folder, go in states folder, if theres a directory, we go in the directory and rob it,
				// if the next loop isnt a directory, we push types in module if there are
				checkInDirectory(fileOrFolder);
		}

		// filter repeated elements
		leClasses = leClasses.filter(function(input:String):Bool
		{
			if (leClasses.has(input))
			{
				// check if after removing it, it exists
				leClasses.remove(input);
				if (leClasses.has(input))
				{
					trace("duplicate, ignoring");
				}
				return true;
			}
			return true;
		});

		trace(leClasses);

		fields.push({
			pos: Context.currentPos(),
			name: "ClassesToBeAdded",
			kind: FieldType.FVar(macro :Array<String>, macro($v{leClasses})),
			access: [Access.APrivate]
		});

		return fields;
	}
}
