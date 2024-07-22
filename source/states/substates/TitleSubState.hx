package states.substates;

import data.ClientPrefs;
import data.Highscore;
import data.Paths;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.effects.FlxFlicker;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;
import flixel.util.FlxStringUtil;
import input.Controls.Control;
import objects.*;
import states.menus.TitleState;
import states.options.OptionsState;
import states.menus.FreeplayState;
import states.game.PlayState;
import states.CreditsState;
import song.Song;

import util.CoolUtil;

class TitleSubState extends MusicBeatSubstate
{
	var grpMenuShitText:FlxTypedGroup<FlxText>;
	var grpMenuShit:FlxTypedGroup<FlxSprite>;

	var menuItems:Array<String> = ['Story', 'Freeplay', 'Options', 'Credits'];
	var menuItemsOG:Array<String> = ['Story', 'Freeplay', 'Options', 'Credits'];
	var curSelected:Int = 0;
	var doingAnim:Bool = false;

	var offsetForTheTexts:Array<Float> = [0, 42.5, 32.5, 33.5];

	public function new()
	{
		super();

		grpMenuShit = new FlxTypedGroup<FlxSprite>();
		grpMenuShitText = new FlxTypedGroup<FlxText>();

		grpMenuShit.camera = TitleState.mainCam;
		grpMenuShitText.camera = TitleState.mainCam;

		for (i in 0...4) {
			var daButt:FlxSprite = new FlxSprite(824, 90 + (137.5 * i)).loadGraphic(Paths.image('title/button')); // HAHA! BUTT! ASS! ASS! -Boxy 07/20/24 6:43PM
			daButt.scale.set(0.75, 0.75);
			daButt.updateHitbox();
			daButt.antialiasing = true;
			daButt.ID = i;
			grpMenuShit.add(daButt);

			var daTexto:FlxText = new FlxText(899, 116 + (137.5 * i), 0, menuItemsOG[i].toUpperCase()).setFormat(Paths.font('cocococo.ttf'), 55, FlxColor.BLACK);
			daTexto.updateHitbox();
			daTexto.x -= offsetForTheTexts[i]; // Because for some reason I can't align the text to the center :sob: 
			daTexto.ID = i;
			daTexto.antialiasing = true; 
			grpMenuShitText.add(daTexto);
		} // ANTIALIASING!!!!!!!!! USE IT PLEASE OH MY GOD

		add(grpMenuShit);
		add(grpMenuShitText);

		if (!TitleState.fromOtherState) {
			doingAnim = true;
			for (item in grpMenuShit.members)
				{
					item.alpha = 0;
					FlxTween.tween(item, {alpha: 1}, 1, {ease: FlxEase.quintIn});
				}
	
			for (item in grpMenuShitText.members)
				{
					item.alpha = 0;
					FlxTween.tween(item, {alpha: 1}, 1, {ease: FlxEase.quintIn});
				}
	
			new FlxTimer().start(1, function(tmr:FlxTimer) {
				doingAnim = false;
				changeSelection();
			});
		} else {
			changeSelection();
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		var upP = controls.UI_UP_P;
		var downP = controls.UI_DOWN_P;
		var accepted = controls.ACCEPT;

		if (upP && !doingAnim) changeSelection(-1);

		if (downP && !doingAnim) changeSelection(1);

		// add mouse stuff in the hotfix

		if (controls.BACK && !doingAnim) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			doingAnim = true;

			for (item in grpMenuShit.members)
				{
					FlxTween.tween(item, {alpha: 0}, 1, {ease: FlxEase.quintIn});
				}

			for (item in grpMenuShitText.members)
				{
					FlxTween.tween(item, {alpha: 0}, 1, {ease: FlxEase.quintIn});
				}

			new FlxTimer().start(1, function(tmr:FlxTimer) {
				TitleState.alreadyEnteredOnce = true;
				close();
			});
		}

		if (accepted && !doingAnim) {
			doingAnim = true;
			TitleState.transitioning = true;

			FlxTween.cancelTweensOf(camera);
			FlxTween.tween(camera, {y: FlxG.height * 1.5, zoom: 1.5}, 1.1, {ease: FlxEase.circIn, onComplete:
			function(twn:FlxTween) {
				TitleState.transitioning = false;
			}});

			FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);

			for (item in grpMenuShit.members)
				{
					if (item.ID == curSelected) FlxFlicker.flicker(item, 1.9, 0.06, false, false);
				}

			for (item in grpMenuShitText.members)
				{
					if (item.ID == curSelected) FlxFlicker.flicker(item, 1.9, 0.06, false, false);
				}

			TitleState.fromOtherState = true;

			new FlxTimer().start(1.3, function(tmr:FlxTimer) {
				switch(curSelected) {
					case 0:
						var songArray:Array<String> = ['Kaseyfunk', 'Digital-Dreamin', 'Overclocked'];
			
						// Nevermind that's stupid lmao
						PlayState.storyPlaylist = songArray;
						PlayState.isStoryMode = true;
						PlayState.storyDifficulty = 0;
			
						PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase(), PlayState.storyPlaylist[0].toLowerCase());
						PlayState.campaignScore = 0;
						PlayState.campaignMisses = 0;
						LoadingState.loadAndSwitchState(new PlayState(), true);
						FreeplayState.destroyFreeplayVocals();
					case 1:
						MusicBeatState.switchState(new FreeplayState());
					case 2:
						states.menus.StartState.StartMenu.returnToBoot = false;
						MusicBeatState.switchState(new OptionsState());
					case 3:
						MusicBeatState.switchState(new CreditsState());
				}
			});
		}
	}

	override function kill()
		super.kill();

	override function destroy()
	{
		super.destroy();
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected += change;

		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		if (curSelected < 0)
			curSelected = menuItems.length - 1;
		if (curSelected >= menuItems.length)
			curSelected = 0;

		for (item in grpMenuShit.members)
		{
			item.color = FlxColor.WHITE;
			if (item.ID == curSelected) item.color = 0xFFADADAD;
		}
	}
}
