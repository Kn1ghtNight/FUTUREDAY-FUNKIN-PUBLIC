package states.menus;

import flixel.addons.display.FlxBackdrop;
import shaders.MenuPewd;
import engine.NotifToastHandler;
import engine.gc.GarbageCollector;
#if DISCORD_ALLOWED
import util.Discord.DiscordClient;
#end
import data.ClientPrefs;
import data.Paths;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;
import states.editors.MasterEditorMenu;
import states.options.OptionsState;
import util.CoolUtil;

using StringTools;

class MainMenuState extends MusicBeatState
{
	public static var curSelected:Int = 0;

	var menuItems:FlxTypedGroup<FlxSprite>;
	private var camGame:FlxCamera;
	private var camAchievement:FlxCamera;

	public var selectedScale = 0.75; // 0.8
	public var defaultScale = 0.65; // 0.6
	public var force:Bool = true;
	public var targetItem:Float = 0;

	var optionShit:Array<String> = ['story', 'freeplay', 'credits', 'options', 'gallery', 'logs'];

	var magenta:FlxSprite;
	var camFollow:FlxObject;
	var camFollowPos:FlxObject;
	var debugKeys:Array<FlxKey>;
	var pewd:MenuPewd = new MenuPewd();

	override function create()
	{
		Paths.clearUnusedMemory();
		Paths.clearStoredMemory();

		GarbageCollector.run(true);

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end
		debugKeys = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));

		camGame = new FlxCamera();
		camAchievement = new FlxCamera();
		camAchievement.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camAchievement, false);
		FlxG.cameras.setDefaultDrawTarget(camGame, true);

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		var offse:Array<Int> = [20, 120];

		var pewdBg:FlxSprite = new FlxSprite().makeGraphic(1590, 1240);
		pewdBg.screenCenter();
		pewdBg.x -= 640;
		pewdBg.y -= 240;
		add(pewdBg);
		pewdBg.shader = pewd;

		var checker:FlxBackdrop = new FlxBackdrop(Paths.image('mainmenu/menucheck'));
		checker.velocity.x = 15;
		checker.velocity.y = 12;
		checker.blend = ADD;
		checker.alpha = 0.02;
		checker.scale.set(4, 4);
		add(checker);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);

		magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		magenta.setGraphicSize(Std.int(magenta.width * 1.175));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.antialiasing = ClientPrefs.globalAntialiasing;
		magenta.color = 0xFFfd719b;
		//add(magenta);

		// magenta.scrollFactor.set();

		var box:FlxSprite = new FlxSprite(-725, -270).makeGraphic(565, 820, FlxColor.BLACK);
		add(box);

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		var scale:Float = 1;
		/*if(optionShit.length > 6) {
			scale = 6 / optionShit.length;
		}*/

		for (i in 0...optionShit.length)
		{
			var menuItem:FlxText = new FlxText(offse[0], (i * 90) + offse[1], 0, optionShit[i].toUpperCase(), 12);
			menuItem.scrollFactor.set();
			menuItem.setFormat(Paths.font("neuro.ttf"), 64, FlxColor.WHITE, LEFT);
			menuItem.offset.y += 25;
			menuItem.antialiasing = false;
			menuItem.ID = i;
			menuItems.add(menuItem);
		}

		var kasey:FlxSprite = new FlxSprite(60,-360).loadGraphic(Paths.image('mainmenu/kaseymenu'));
		kasey.scale.set(0.6, 0.6);
		kasey.antialiasing = true;
		add(kasey);

		var bar:FlxSprite = new FlxSprite(-639,-350).loadGraphic(Paths.image('mainmenu/bar'));
		add(bar);

		var topBar:FlxSprite = new FlxSprite(-639,-360).loadGraphic(Paths.image('mainmenu/bar'));
		topBar.flipY = true;
		topBar.flipX = true;
		add(topBar);

		FlxG.camera.follow(camFollowPos, null, 1);

		changeItem();

		super.create();
				
		var cursor:engine.fancy.FunkCursor = new engine.fancy.FunkCursor();
		add(cursor);
		cursor.cameras = [camAchievement];

		GarbageCollector.run(true);
	}

	var selectedSomethin:Bool = false;

	function giveFakeError()
	{
		add(new NotifToastHandler('black tar heroin', 'error', camAchievement));
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
	}

	function giveFakeWarn()
	{
		add(new NotifToastHandler('at the club straight up \n "jorking it" and by it... \n heh... i mean my peanits', 'warn', camAchievement));
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
	}

	override function update(elapsed:Float)
	{
		menuItems.forEach(function(spr:FlxSprite)
		{
			if (curSelected != spr.ID)
			{
				spr.alpha = 0.6;
			}
			else
			{
				spr.alpha = 1;
			}
		});
		pewd.update(elapsed);

		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
			if (FreeplayState.vocals != null)
				FreeplayState.vocals.volume += 0.5 * elapsed;
		}

		var lerpVal:Float = CoolUtil.boundTo(elapsed * 7.5, 0, 1);
		//camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		if (!selectedSomethin)
		{
			if (controls.UI_UP_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(-1);
				trace("SELECTED:" + curSelected);
			}

			if (controls.UI_DOWN_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(1);
				trace("SELECTED:" + curSelected);
			}

			if (FlxG.keys.justPressed.P)
				giveFakeError();

			if (FlxG.keys.justPressed.ONE)
				MusicBeatState.switchState(new states.menus.StartupState.StartupMenuIntro());

			if (FlxG.keys.justPressed.J)
				giveFakeWarn();

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT)
			{
					selectedSomethin = true;
					FlxG.sound.play(Paths.sound('confirmMenu'));

					menuItems.forEach(function(spr:FlxSprite)
					{
						if (curSelected != spr.ID)
						{
							FlxTween.tween(spr, {alpha: 0}, 0.4, {
								ease: FlxEase.quadOut,
								onComplete: function(twn:FlxTween)
								{
									spr.kill();
								}
							});
						}
						else
						{
							FlxFlicker.flicker(spr, 1, 0.06, false, false, function(flick:FlxFlicker)
							{
								var daChoice:String = optionShit[curSelected];

								switch (daChoice)
								{
									case 'freeplay':
										MusicBeatState.switchState(new FreeplayState());
									case 'credits':
										MusicBeatState.switchState(new CreditsState());
									case 'options':
										LoadingState.loadAndSwitchState(new OptionsState());
									case 'gallery':
										MusicBeatState.switchState(new ArtGalleryState());
									case 'logs':
										MusicBeatState.switchState(new LogState());
								}
							});
						}
					});
			}
			#if desktop
			else if (FlxG.keys.anyJustPressed(debugKeys))
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			#end
		}

		super.update(elapsed);
	}

	function changeItem(huh:Int = 0)
	{
		curSelected += huh;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;

		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.updateHitbox();

			if (spr.ID == curSelected)
			{
				var add:Float = 0;
				if (menuItems.length > 4)
				{
					add = menuItems.length * 8;
				}
				camFollow.setPosition(spr.getGraphicMidpoint().x, spr.getGraphicMidpoint().y - add);
				spr.centerOffsets();
			}
			else {
				spr.centerOffsets();
			}
		});
	}
}
