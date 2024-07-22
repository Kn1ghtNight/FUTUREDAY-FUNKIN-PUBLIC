package engine.plugin;

import data.Paths;
import flixel.util.FlxTimer;
import lime.graphics.Image;
import sys.FileSystem;
import openfl.utils.ByteArray;
import openfl.display.Sprite;
import flixel.tweens.FlxTween;
import flixel.FlxG;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;
import openfl.geom.Matrix;
import flixel.input.keyboard.FlxKey;
import flixel.input.FlxInput.FlxInputState;

using StringTools;

// this likes to crash! a lot! it works once flawlessly and then shat itself at the second screenshot. i have no idea why. send help. could be flx sound related????

class ScreenshotPlugin extends flixel.FlxBasic {
    private static var initialized:Bool = false;
    private var container:Sprite;
    private var flashSprite:Sprite;
    private var flashBitmap:Bitmap;
    private var screenshotSprite:Sprite;
    private var shotDisplayBitmap:Bitmap;
    private var outlineBitmap:Bitmap;
    public static var enabled:Bool = true;
    public static var screenshotKey:FlxKey = FlxKey.F2;
    public static var saveFormat(default, set):FileFormatOption = PNG;
    public static function set_saveFormat(v:FileFormatOption) {
        if (v != JPEG && v != PNG) {
            throw new haxe.Exception("Unsupported value for saveFormat: " + v);
            return saveFormat = PNG;
        }
        return saveFormat = v;
    }

	public static var onScreenshot:Void->Void = null;

    override public function new():Void {
        super();

        if (initialized) {
            FlxG.plugins.remove(this);
            destroy();
            return;
        }

        initialized = true;
        container = new Sprite();
        FlxG.stage.addChild(container);
        flashSprite = new Sprite();
        flashSprite.alpha = 0;
        flashBitmap = new Bitmap(new BitmapData(FlxG.width, FlxG.height, true, 0xFFFFFFFF));
        flashSprite.addChild(flashBitmap);
        screenshotSprite = new Sprite();
        screenshotSprite.alpha = 0;
        container.addChild(screenshotSprite);
        outlineBitmap = new Bitmap(new BitmapData(Std.int(FlxG.width / 5) + 10, Std.int(FlxG.height / 5) + 10, true, 0xffffffff));
        outlineBitmap.x = 5;
        outlineBitmap.y = 5;
        screenshotSprite.addChild(outlineBitmap);
        shotDisplayBitmap = new Bitmap();
        shotDisplayBitmap.scaleX /= 5;
        shotDisplayBitmap.scaleY /= 5;
        screenshotSprite.addChild(shotDisplayBitmap);
        container.addChild(flashSprite);
        @:privateAccess openfl.Lib.application.window.onResize.add((w, h) -> {
            flashBitmap.bitmapData = new BitmapData(w, h, true, 0xFFFFFFFF);
            outlineBitmap.bitmapData = new BitmapData(Std.int(w / 5) + 10, Std.int(h / 5) + 10, true, 0xffffffff);
        });
    }
    
    override public function update(elapsed:Float):Void {
        if (FlxG.keys.checkStatus(screenshotKey, JUST_PRESSED) && enabled) {
            screenshot();
        }
    }

    private function screenshot():Void {
        FlxG.sound.play(Paths.sound('screenshot'));
        FlxTween.cancelTweensOf(flashSprite);
        FlxTween.cancelTweensOf(screenshotSprite);
        flashSprite.alpha = 0;
        screenshotSprite.alpha = 0;
        
        if (onScreenshot != null)
            onScreenshot();


        new FlxTimer().start(0.1, function (tmr:FlxTimer) {
            var image:Image = FlxG.stage.window.readPixels();
            var shot:Bitmap = new Bitmap(BitmapData.fromImage(image));
            var png:ByteArray = shot.bitmapData.encode(shot.bitmapData.rect, (saveFormat == PNG ? new openfl.display.PNGEncoderOptions() : new openfl.display.JPEGEncoderOptions()));
            png.position = 0;
            var path = "screenshots/Screenshot " + Date.now().toString().split(":").join("-") + saveFormat;
            if (!sys.FileSystem.exists("./screenshots/"))
                sys.FileSystem.createDirectory("./screenshots/");
            sys.io.File.saveBytes(path, png);
            flashSprite.alpha = 1;
            FlxTween.tween(flashSprite, {alpha: 0}, 0.25);
            shotDisplayBitmap.bitmapData = shot.bitmapData;
            shotDisplayBitmap.x = outlineBitmap.x + 5;
            shotDisplayBitmap.y = outlineBitmap.y + 5;
            screenshotSprite.alpha = 1;
            FlxTween.tween(screenshotSprite, {alpha: 0}, 0.5, {startDelay: .5});
            //TODO: open image in mac and linux
            #if windows
            Sys.command('"' + Sys.getCwd() + path + '"');
            #end

            if (onScreenshot != null)
                onScreenshot();
        });
    }
}

enum abstract FileFormatOption(String) {
    var JPEG = ".jpg";
    var PNG = ".png";
}