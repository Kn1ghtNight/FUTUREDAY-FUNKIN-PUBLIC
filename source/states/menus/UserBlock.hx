package states.menus;

import flixel.util.FlxColor;
import flixel.FlxG;
import data.Paths;
import objects.PsychVideo;
import flixel.FlxState;
import flixel.tweens.FlxTween;
import flixel.text.FlxText;

class UserBlock extends MusicBeatState {
    override public function create() {
        super.create();

        var pomni:PsychVideo = new PsychVideo();
        pomni.load(Paths.video('pomni'), [':input-repeat=65535']);
        pomni.play();
        add(pomni);
        pomni.scale.set(2.5, 2.5);

        var message:FlxText = new FlxText(0,0, 800, 'you have been blocked from fdf', 32);
        message.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		message.scrollFactor.set();
		message.borderSize = 1.25;
        add(message);
        message.alpha = 0.001;
        message.screenCenter();

        FlxTween.tween(message, {alpha: 1}, 3);
    }
}