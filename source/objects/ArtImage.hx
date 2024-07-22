package objects;

import util.CoolUtil;
import data.Paths;
import data.ClientPrefs;
import flixel.group.FlxSpriteGroup;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMath;
import flixel.util.FlxColor;

using objects.FlxSpriteExt;
using StringTools;

class ArtImage extends FlxSpriteGroup
{
	public var targetItem:Float = 0;

	public var url:String = "";
	public var artist:String = "";

	public var imageSpr:FlxSprite;

	public var index:Int;

	public function new(x:Float, y:Float, image:String = '', category:String = '', isJPG:Bool = false)
	{
		super(x, y);

		var portraitPath = category + '/' + image;

		imageSpr = new FlxSprite().loadGraphic(Paths.image(portraitPath));
		imageSpr.antialiasing = ClientPrefs.globalAntialiasing;
		imageSpr.active = false;
		if (imageSpr.frameHeight > 600)
		{
			imageSpr.setGraphicSize(0, 600);
			imageSpr.updateHitbox();
		}

		selectedScale = imageSpr.scale.x * 0.75;
		defaultScale = imageSpr.scale.x * 0.45;

		add(imageSpr);

		moves = false;
	}

	public var force:Bool = true;

	public var selectedScale = 0.75; // 0.8
	public var defaultScale = 0.65; // 0.6

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		#if FLX_DEBUG flixel.FlxBasic.activeCount++; #end

		// x
		var wantedX = (FlxG.width / 2) - (width / 2);
		wantedX += 530 * targetItem;

		x = FlxMath.lerp(x, wantedX, CoolUtil.boundTo(elapsed * 0.17 * 60, 0, 1));
		if (force)
			x = wantedX;

		// Scale
		var wantedScale = targetItem == 0 ? selectedScale : defaultScale;
		var scl = FlxMath.lerp(scale.x, wantedScale, CoolUtil.boundTo(elapsed * 0.17 * 60, 0, 1));
		if (force)
			scl = wantedScale;
		scale.set(scl, scl);

		var wantedAlpha = targetItem == 0 ? 1 : 0.6;
		var alp = FlxMath.lerp(alpha, wantedAlpha, CoolUtil.boundTo(elapsed * 0.17 * 60, 0, 1));
		if (force)
			alp = wantedAlpha;
		alpha = alp;

		force = false;
	}
}
