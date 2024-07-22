package objects;

import flixel.math.FlxRect;
import flixel.util.FlxColor;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.FlxSprite;
import flixel.ui.FlxBar;
import flixel.group.FlxSpriteGroup;

class HealthBar extends FlxSpriteGroup
{
	public var left:FlxSprite;
	public var right:FlxSprite;
	public var bg:FlxSprite;
	public var helperBar:FlxBar;

	public var percent(get, set):Float;

	function set_percent(v:Float):Float
		return helperBar.percent = v;

	function get_percent():Float
		return helperBar.percent;

	var _initialized = false;

	public function new(x:Float = 0, y:Float = 0, ?front:FlxGraphicAsset, ?back:FlxGraphicAsset, ?parentRef:Dynamic, variable:String = "", min:Float = 0,
			max:Float = 100)
	{
		super(x, y);

		bg = new FlxSprite();
		bg.loadGraphic(back);
		bg.antialiasing = true;

		helperBar = new FlxBar(0, 0, null, Std.int(bg.width), 1, parentRef, variable, min, max);
		helperBar.numDivisions *= 5; // for lerping

		left = new FlxSprite();
		left.loadGraphic(front);
		add(left);

		right = new FlxSprite();
		right.loadGraphic(front);
		add(right);

		add(bg);

		_initialized = true;

		setColors();
	}

	var lastpercent:Float = -1;

	public override function update(elapsed:Float)
	{
		super.update(elapsed);
		helperBar.update(elapsed);

		if (percent != lastpercent)
		{
			var p = helperBar.percent * -0.01;
			p++;
			left.clipRect = new FlxRect(0, 0, p * left.frameWidth, left.frameHeight);
			right.clipRect = new FlxRect(left.clipRect.width, 0, right.frameWidth - left.clipRect.width, right.frameHeight);
		}

		lastpercent = percent;
	}

	public function setColors(?l:FlxColor = FlxColor.GREEN, ?r:FlxColor = FlxColor.LIME)
	{
		if (!_initialized)
			return;
		left.color = l;
		right.color = r;
	}
}
