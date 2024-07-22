package engine.fancy;

import flixel.FlxG;
import flixel.FlxSprite;
import data.Paths;

class FunkCursor extends FlxSprite
{
    public function new(){
        super();

        FlxG.mouse.visible = false;

        // grabs from preload??? i think???
		frames = Paths.getSparrowAtlas("cursor");
		animation.addByPrefix("idle", "idle", 24, true);
        animation.addByPrefix("click", "click", 24, false);

        // play idle anim by  default
		animation.play('idle');
		updateHitbox();
		antialiasing = true;
    }

    override function update(elapsed:Float){

        x = FlxG.mouse.screenX;
		y = FlxG.mouse.screenY;

        super.update(elapsed);

        // play click anim on mouse press
        if(FlxG.mouse.justPressed) {
            FlxG.sound.play(Paths.sound('click'));
            animation.play('click', true); // force anim for multiple clicks
        }

    }
}