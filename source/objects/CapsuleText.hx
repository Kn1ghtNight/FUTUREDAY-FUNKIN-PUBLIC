package objects;

import openfl.filters.BitmapFilterQuality;
import flixel.text.FlxText;
import flixel.group.FlxSpriteGroup;
import shaders.GaussianBlur;

class CapsuleText extends FlxSpriteGroup
{
  public var blurredText:FlxText;

  var whiteText:FlxText;

  public var text(default, set):String;

  var songTextScales:Array<Float> = [1, 380, 225];

  public function new(x:Float, y:Float, songTitle:String, size:Float)
  {
    super(x, y);

    blurredText = initText(songTitle, size);
    //blurredText.shader = new GaussianBlur(1); shader crashes, dunno why maybe im a retard but
    whiteText = initText(songTitle, size);
    text = songTitle;

    blurredText.color = 0xFF00ccff;
    whiteText.color = 0xFFFFFFFF;
    add(blurredText);
    add(whiteText);
  }

  function initText(songTitle, size:Float):FlxText
  {
    var text:FlxText = new FlxText(0, 0, 0, songTitle, Std.int(size));
    text.font = "5by7";
    return text;
  }

  function set_text(value:String):String
  {
    if (value == null) return value;
    if (blurredText == null || whiteText == null)
    {
      trace('WARN: Capsule not initialized properly');
      return text = value;
    }

    for (i in [blurredText, whiteText]) {
      i.text = value;
    }

    whiteText.textField.filters = [
      new openfl.filters.GlowFilter(0x00ccff, 1, 5, 5, 210, BitmapFilterQuality.MEDIUM),
      // new openfl.filters.BlurFilter(5, 5, BitmapFilterQuality.LOW)
    ];

    return text = value;
  }

  public function reloadScaling()
  {
    for (i in [blurredText, whiteText]) {
      i.scale.x = Math.min(1, i.width / songTextScales[this.ID]);
      i.updateHitbox();
    }
  }
}