package engine.ui;

import flixel.util.FlxColor;
import flixel.FlxG;
import util.CoolUtil;
import data.Paths;
import flixel.system.ui.FlxSoundTray;
import flixel.tweens.FlxTween;
import flixel.system.FlxAssets;
import flixel.tweens.FlxEase;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.utils.Assets;

class FunkSoundTray extends FlxSoundTray
{
  var graphicScale:Float = 0.30;
  var lerpYPos:Float = 0;
  var alphaTarget:Float = 0;

  public function new()
  {
    // calls super, then removes all children to add our own
    // graphics
    super();
    removeChildren();

    var bg:Bitmap = new Bitmap(Assets.getBitmapData('assets/images/soundtray.png')); // dont use paths because it uses flxgraphic for bitmap caching
    bg.scaleX = graphicScale;
    bg.scaleY = graphicScale;
    bg.smoothing = true;
    addChild(bg);

    var tmp:Bitmap = new Bitmap(new BitmapData(1, 1, true, 0x00FFFFFF));
    addChild(tmp);

    y = -height;
    visible = false;

    // clear the bars array entirely, it was initialized
    // in the super class
    var bx:Int = 10;
    var by:Int = 20;
    _bars = [];

    for (i in 0...10)
		{
			tmp = new Bitmap(new BitmapData(4, i + 5, false, FlxColor.WHITE));
			tmp.x = bx;
			tmp.y = by;
			addChild(tmp);
			_bars.push(tmp);
			bx += 6;
			by--;
		}

    y = -height;
    screenCenter();

    volumeUpSound = 'assets/sounds/volumeAdjust';
    volumeDownSound = 'assets/sounds/volumeAdjust';

    trace("Custom tray added!");
  }

  override public function update(MS:Float):Void
  {
    y = CoolUtil.fpsLerp(y, lerpYPos, 0.1);
    alpha = CoolUtil.fpsLerp(alpha, alphaTarget, 0.25);

    // Animate sound tray thing
    if (_timer > 0)
    {
      _timer -= (MS / 1000);
      alphaTarget = 1;
    }
    else if (y >= -height)
    {
      lerpYPos = -height - 10;
      alphaTarget = 0;
    }

    if (y <= -height)
    {
      visible = false;
      active = false;

      #if FLX_SAVE
      // Save sound preferences
      if (FlxG.save.isBound)
      {
        FlxG.save.data.mute = FlxG.sound.muted;
        FlxG.save.data.volume = FlxG.sound.volume;
        FlxG.save.flush();
      }
      #end
    }
  }

  /**
   * Makes the little volume tray slide out.
   *
   * @param	up Whether the volume is increasing.
   */
  override public function show(up:Bool = false):Void
  {
    _timer = 1;
    lerpYPos = 10;
    visible = true;
    active = true;
    var globalVolume:Int = Math.round(FlxG.sound.volume * 10);

    if (FlxG.sound.muted)
    {
      globalVolume = 0;
    }

    if (!silent)
    {
        var sound = FlxAssets.getSound(up ? volumeUpSound : volumeDownSound);
        if (sound != null)
            FlxG.sound.load(sound).play();
    }

    for (i in 0..._bars.length)
    {
      if (i < globalVolume)
      {
        _bars[i].visible = true;
      }
      else
      {
        _bars[i].visible = false;
      }
    }
  }
}