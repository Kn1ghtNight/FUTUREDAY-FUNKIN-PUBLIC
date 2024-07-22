package objects;

import flixel.util.FlxAxes;
import flixel.FlxObject;
import flixel.graphics.FlxGraphic;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.FlxSprite;

class FlxSpriteExt
{
	public static function centerTo(s:FlxSprite, sprite:FlxObject, ?axes:FlxAxes)
	{
		if (axes == null)
			axes = FlxAxes.XY;

		if (axes != FlxAxes.Y)
			s.x = (sprite.width / 2) - (s.width / 2);
		if (axes != FlxAxes.X)
			s.y = (sprite.height / 2) - (s.height / 2);

		return s;
	}
}
