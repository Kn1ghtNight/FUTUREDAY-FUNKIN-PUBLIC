package objects;

import flixel.FlxG;
import flixel.math.FlxMath;
import data.Paths;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;

// referenced off of funkin 0.3.0 code
class FreeplayCapsule extends FlxSpriteGroup
{
    public var capsule:FlxSprite;
    public var songTxt:CapsuleText;
    public var targetY:Int = 0;
    public var icon:FlxSprite;

    public var realScaled:Float = 0.8;

    public function new(x:Float, y:Float, text:String, iconPath:String)
    {
        super(x, y);

        capsule = new FlxSprite().loadGraphic(Paths.image('freeplay/freeplayCapsule'));
        add(capsule);

        songTxt = new CapsuleText(capsule.width * 0.265, 45, text, Std.int(40 * realScaled));
        add(songTxt);

        icon = new FlxSprite(capsule.width * 0.8, -35).loadGraphic(Paths.image('freeplay/icons/' + iconPath));
        add(icon);
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        var scaledY = FlxMath.remapToRange(targetY, 0, 1, 0, 1.3);
		y = FlxMath.lerp(y, (scaledY * 180) + (FlxG.height * 0.45), 0.16);
	
				x = FlxMath.lerp(x, Math.exp(scaledY * 0.8) * -70 + (FlxG.width * 0.47), 0.16);
				if (scaledY < 0)
					x = FlxMath.lerp(x, Math.exp(scaledY * -0.8) * -70 + (FlxG.width * 0.47), 0.16);
	
				if (x < -900)
					x = -900;
    }
}