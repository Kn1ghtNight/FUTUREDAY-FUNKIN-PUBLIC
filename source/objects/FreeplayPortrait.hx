package objects;

import data.ClientPrefs;
import flixel.FlxSprite;

class FreeplayPortrait extends FlxSprite
{
    public function new(x:Float, y:Float, portraitPath:String)
    {
        super(x, y);

        antialiasing = ClientPrefs.globalAntialiasing;

        loadGraphic(data.Paths.image('freeplay/portraits/' + portraitPath));
    }
}