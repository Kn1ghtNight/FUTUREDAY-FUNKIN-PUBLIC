package states;

import flixel.FlxG;

#if D3D
class D3DBase extends MusicBeatState
{
	override function create()
	{
		// deactivate flixel and any potential updates that could write over our own updater
		// when extending D3DBase, call super.create() on top of the create function
		// THIS IS REQUIRED SO THAT IT DOESNT DO WEIRD FLICKERY SHITT
		FlxG.game.visible = false;
		FlxG.game.mouseEnabled = false;
		FlxG.mouse.visible = false;
		is3DEnabled = true;
	}
}
#end
