package states.menus;

import flixel.util.FlxGradient;
import engine.gc.GarbageCollector;
import openfl.filters.ShaderFilter;
import flixel.addons.display.FlxBackdrop;
import flixel.util.FlxSpriteUtil;
import flixel.addons.text.FlxTypeText;
import flixel.FlxCamera;
#if DISCORD_ALLOWED
import sys.thread.Thread;
import util.Discord.DiscordClient;
#end
import data.ClientPrefs;
import data.Highscore;
import data.Paths;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.sound.FlxSound;
import flixel.system.ui.FlxSoundTray;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import haxe.Json;
import input.PlayerSettings;
import lime.app.Application;
import objects.Alphabet;
import openfl.Assets;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import shaders.ColorSwap;
import song.Conductor;
import states.*;
import sys.FileSystem;
import sys.io.File;
import util.CoolUtil;
import flixel.group.FlxSpriteGroup;
import states.substates.TitleSubState;

using StringTools;

class TitleState extends MusicBeatState
{
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];

	public static var initialized:Bool = false;
	public static var fromOtherState:Bool = false;

	public static var alreadyEnteredOnce:Bool = false;

	var blackScreen:FlxSprite;
	var blackBars1:FlxSprite;
	var blackBars2:FlxSprite;
	var titleBackdrop:FlxBackdrop;
	var kasey:FlxSprite;
	var kaseyTwn:FlxTween;
	public static var penis:Bool = false;

	var canHitEnterYet:Bool = false;

	var mustUpdate:Bool = false;
	public static var mainCam:FlxCamera;
	var daOtherCam:FlxCamera;

	public static var updateVersion:String = '';

	override public function create():Void
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		GarbageCollector.run(true);

		// DEBUG BULLSHIT

		mainCam = new FlxCamera();
		daOtherCam = new FlxCamera();

		daOtherCam.bgColor.alpha = 0;

		FlxG.cameras.reset(mainCam);
		FlxG.cameras.add(daOtherCam, false);

		FlxG.cameras.setDefaultDrawTarget(mainCam, true);

		super.create();

		GarbageCollector.run(true);

		if (!initialized)
		{
			persistentUpdate = true;
			persistentDraw = true;
		}

		if (initialized)
			startIntro();
		else
		{
			new FlxTimer().start(1, function(tmr:FlxTimer)
			{
				startIntro();
			});
		}
	}

	var startText:FlxText;
	var logoBl:FlxSprite;
	var danceLeft:Bool = false;

	public static var videosSupported:Bool = true;

	function startIntro()
	{
		if (!initialized && !alreadyEnteredOnce)
		{
			if (FlxG.sound.music == null)
			{
				FlxG.sound.playMusic(Paths.music('futuremenu'), 0);
			}
		}

		Conductor.changeBPM(192);

		persistentUpdate = true;

		var bgGrad:FlxSprite = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [FlxColor.BLACK, 0xFFFB0069]);
		bgGrad.y + 70;
		add(bgGrad);

		kasey = new FlxSprite(763 + 763).loadGraphic(Paths.image('title/portraits/kaseyPortrait' + FlxG.random.int(1, 4)));
		kasey.setGraphicSize(475);
		kasey.updateHitbox();
		kasey.screenCenter(Y);
		kasey.antialiasing = ClientPrefs.globalAntialiasing;
		add(kasey);

		trace(ClientPrefs.videosUnsupported);
		// set here to check

		logoBl = new FlxSprite(-55, 129.5);
		logoBl.frames = Paths.getSparrowAtlas('logo');
		logoBl.animation.addByPrefix('logo', 'logo', 24, false);
		logoBl.animation.play('logo');
		logoBl.antialiasing = ClientPrefs.globalAntialiasing;
		logoBl.updateHitbox();
		logoBl.screenCenter(Y);
		logoBl.scale.set(0.8, 0.8);

		startText = new FlxText(75, 550, "PRESS ENTER TO START");
		startText.setFormat(Paths.font('title.ttf'), 32, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);

		var textFormat = startText.textField.getTextFormat();
		textFormat.letterSpacing = 5;
		startText.textField.setTextFormat(textFormat);
		startText.borderSize = 1.2;
		startText.updateHitbox();
		//startText.screenCenter(Y);
		//startText.y = FlxG.height - 125;
		add(startText);

		add(logoBl);

		blackBars1 = new FlxSprite(0, -218).loadGraphic(Paths.image('black_bars'));
		add(blackBars1);
		blackBars1.scale.set(1, 6);

		blackBars2 = new FlxSprite(0, 735).loadGraphic(Paths.image('black_bars'));
		add(blackBars2);
		blackBars2.scale.set(1, 3);

		var bg:FlxSprite = new FlxSprite(blackBars2.x, blackBars2.y);
		bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(bg);

		if (initialized)
			skipIntro(false);
		else {
			openSubState(new TitleIntroState());
			initialized = true;
		}

		if (fromOtherState) {
			skipIntro(false);

			FlxTween.cancelTweensOf(startText);

			kasey.alpha = 0;
			startText.alpha = 0;

			closedState = true;
			openSubState(new TitleSubState());
			fromOtherState = false;
			alreadyEnteredOnce = true;
		}
	}

	public static var transitioning:Bool = false;

	private static var playJingle:Bool = false;

	var newTitle:Bool = false;
	var titleTimer:Float = 0;
	var floatNum:Float = 0;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;
		// FlxG.watch.addQuick('amp', FlxG.sound.music.amplitude);

		var pressedEnter:Bool = FlxG.keys.justPressed.ENTER || controls.ACCEPT;

		#if mobile
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed)
			{
				pressedEnter = true;
			}
		}
		#end

		/*

		var debugObj:Dynamic = startText;

		if (FlxG.keys.justPressed.Y && !FlxG.keys.pressed.SHIFT && debugObj != null)
			debugObj.y -= 1;
		else if (FlxG.keys.justPressed.Y && FlxG.keys.pressed.SHIFT && debugObj != null)
			debugObj.y -= 10;
			
		if (FlxG.keys.justPressed.H && !FlxG.keys.pressed.SHIFT && debugObj != null)
			debugObj.y += 1;
		else if (FlxG.keys.justPressed.H && FlxG.keys.pressed.SHIFT && debugObj != null)
			debugObj.y += 10;
			
		if (FlxG.keys.justPressed.G && !FlxG.keys.pressed.SHIFT && debugObj != null) 
			debugObj.x -= 1;
		else if (FlxG.keys.justPressed.G && FlxG.keys.pressed.SHIFT && debugObj != null)
			debugObj.x -= 10;
		
		if (FlxG.keys.justPressed.J && !FlxG.keys.pressed.SHIFT && debugObj != null)
			debugObj.x += 1;
		else if (FlxG.keys.justPressed.J && FlxG.keys.pressed.SHIFT && debugObj != null) 
			debugObj.x += 10;
		
			
		if (FlxG.keys.justPressed.T && debugObj != null) trace(debugObj);

		//*/

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		if (gamepad != null)
		{
			if (gamepad.justPressed.START)
				pressedEnter = true;

			#if switch
			if (gamepad.justPressed.B)
				pressedEnter = true;
			#end
		}

		if (newTitle)
		{
			titleTimer += CoolUtil.boundTo(elapsed, 0, 1);
			if (titleTimer > 2)
				titleTimer -= 2;
		}

		if (initialized && !transitioning && skippedIntro && !closedState)
		{
			if (newTitle && !pressedEnter)
			{
				var timer:Float = titleTimer;
				if (timer >= 1)
					timer = (-timer) + 2;

				timer = FlxEase.quadInOut(timer);
			}

			if (pressedEnter && canHitEnterYet)
			{
				if(kaseyTwn != null && kaseyTwn.active) kaseyTwn.cancel();
				kasey.setPosition(763, kasey.y);

				FlxG.camera.flash(ClientPrefs.flashing ? FlxColor.WHITE : 0x4CFFFFFF, 1);
				FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
				
				/*FlxTween.tween(camera, {zoom: 1.5}, 0.6, {ease: FlxEase.cubeInOut, onComplete: (_) -> {
					FlxTween.tween(camera, {y: FlxG.height * 1.5}, 1.1, {ease: FlxEase.circIn});
				}, startDelay: 0.2});*/

				kaseyTwn = FlxTween.tween(kasey, {alpha: 0}, 1, {startDelay: 0.2, ease: FlxEase.quintIn});
				FlxTween.tween(startText, {alpha: 0}, 1, {startDelay: 0.2, ease: FlxEase.quintIn});

				transitioning = true;
				alreadyEnteredOnce = true;
				// FlxG.sound.music.stop();

				//FlxSpriteUtil.fadeOut(startText, 1);

				new FlxTimer().start(1.3, function(tmr:FlxTimer)
				{
					//MusicBeatState.switchState(new MainMenuState());
					openSubState(new TitleSubState());
					closedState = true;
					transitioning = false;
				});
				// FlxG.sound.play(Paths.music('titleShoot'), 0.7);
			}
		}

		if (initialized && pressedEnter && !skippedIntro)
		{
			skipIntro();
		}

		super.update(elapsed);
	}

	override function closeSubState()
	{
		super.closeSubState();

		if (initialized) {
			closedState = false;
			if (skippedIntro) penis = true;

			if(kaseyTwn != null && kaseyTwn.active) kaseyTwn.cancel();

			if (penis) {
				trace('penits');
				kasey.loadGraphic(Paths.image('title/portraits/kaseyPortrait' + FlxG.random.int(1, 3)));
				kasey.setGraphicSize(475);
				kasey.updateHitbox();
				kasey.screenCenter(Y);
				kasey.setPosition(763, kasey.y);
				kasey.alpha = 0;

				startText.alpha = 0;
			}

			kaseyTwn = FlxTween.tween(kasey, {alpha: 1}, 0.65, {ease: FlxEase.quintIn});
			FlxTween.tween(startText, {alpha: 1}, 0.65, {ease: FlxEase.quintIn});
		}
	}

	private var sickBeats:Int = 0; // Basically curBeat but won't be skipped if you hold the tab or resize the screen

	public static var closedState:Bool = false;

	override function beatHit()
	{
		super.beatHit();

		if (curBeat % 2 == 0 && !transitioning){
			for (i in [mainCam, daOtherCam]) {
				i.zoom = 1.025;
				FlxTween.tween(i, {zoom: 1}, Conductor.crochet / 1000, {ease: FlxEase.quadOut});
			}
		}

		if(logoBl != null) {
			logoBl.animation.play('logo');
		}

		if (!closedState)
		{
			sickBeats++;
			switch (sickBeats)
			{
				case 1:
					FlxG.sound.playMusic(Paths.music('futuremenu'), 0);
					FlxG.sound.music.fadeIn(4, 0, 0.7);
				case 24:
					skipIntro();
			}
		}
	}

	var skippedIntro:Bool = false;
	var increaseVolume:Bool = false;

	public function skipIntro(?flash = true):Void
	{
		if (!skippedIntro)
		{
			if (flash) camera.flash(FlxColor.WHITE, 2, null, true);
			closeSubState();
			skippedIntro = true;
			camera.scroll.y = FlxG.width * (closedState ? 2 : -2);
			// dude expoOut fucking SUCKS THERES A VISIBLE SNAPPING i fixed it :]
			FlxTween.tween(camera.scroll, {y: 0}, 2, {ease: (t) -> {
				return t > 0.8 ? FlxMath.lerp(FlxEase.expoOut(t), 1, (t-0.8)*5) : FlxEase.expoOut(t);
			}});
			new FlxTimer().start(1.5, (_)->{
				canHitEnterYet = true;
			});
			
			var cursor:engine.fancy.FunkCursor = new engine.fancy.FunkCursor();
			cursor.camera = daOtherCam;
			add(cursor);

			if(kaseyTwn != null && kaseyTwn.active) kaseyTwn.cancel();
			kaseyTwn = FlxTween.tween(kasey, {x: kasey.x - 763}, 1.8, {ease: FlxEase.quintOut});
		}
	}
}

class TitleIntroState extends states.substates.MusicBeatSubstate {
	// not using FlxG.random just so the values are consistent
	var r:flixel.math.FlxRandom = new flixel.math.FlxRandom(445);
	var stars:Array<FlxSprite> = [];
	public var cam:FlxCamera;
	var centertext:FlxTypeText;
	public var camVelocity:Float = 17;

	private static final coolPeople:Array<String> = [for (i in [
		"Kn1ghtNight", "goofeeSQUARED", "isophoro", "therealjake_12", "MagBros78", "Binos", "Felx Lamp", "Cinder",
		"Fulanox.Tsu", "cheemsnfriends", "ThouHastLigma", "Fungus",
		"remixmage", "prod_42", "CheriPop", "notabraveboi", "TreePlays",
		"loozenhehe", "applemcfruit", "lunarcleint", "OneAndOnlyEGGU", "Raijin", "Boxyyyy_"
	])  i.toUpperCase()];

	public var unidGroup:FlxSpriteGroup = new FlxSpriteGroup();

	public function new() {
		super();
		r.shuffle(coolPeople);
	}

	override public function create() {
		super.create();

		cam = new FlxCamera();
		cam.bgColor = FlxColor.BLACK;
		FlxG.cameras.add(cam, false);
		camera = cam;

		// my Messy ass code
		var h = 0.0;
		var i = 0;
		while (coolPeople.length > 0) {
			var tx = makeText(coolPeople.shift(), 0, 16);
			var distance = r.float(2, 3);
			tx.angle = r.float(-5, 5);
			tx.scale.set(distance / 2, distance / 2);
			tx.updateHitbox();
			tx.x += (++i % 2 == 0 ? -1 : 1) * r.float(250, 500);
			tx.scrollFactor.set(1, (distance / 3) + 0.4);
			tx.y = h + FlxG.height * 1.7 * tx.scrollFactor.y;
			tx.alpha = distance / 3;
			add(tx);
			h += tx.height * 0.8;
		}

		centertext = makeTypedText("A MOD BY", 0, 52);
		centertext.screenCenter();
		centertext.scrollFactor.set();
		add(centertext);

		var bl = new FlxSprite().makeGraphic(1,1,FlxColor.BLACK);
		bl.scale.set(FlxG.width, FlxG.height);
		bl.updateHitbox();
		unidGroup.add(bl);

		unidGroup.scrollFactor.set();
		unidGroup.visible = false;
		add(unidGroup);

		cam.fade(FlxColor.BLACK, 0.5, true);
		
		FlxTween.tween(this, {camVelocity: 0}, CoolUtil.stepsToSeconds(9), {ease: FlxEase.quadOut, startDelay: CoolUtil.stepsToSeconds(128 - 32)});

		GarbageCollector.run(true);
	}

	private var sickBeats:Int = -1;

	override function beatHit()
	{
		super.beatHit();
		
		@:privateAccess {
			switch (++sickBeats)
			{
				case 1:
					centertext.start(0.03, true);
				case 6:
					centertext.erase(0.03, true);
				case 8: 
					centertext.resetText("A BUNCH OF\nCOOL PEOPLE");
					centertext.start(0.03, true);
				case 13:
					centertext.erase(0.03, true);
				case 16:
					centertext.resetText("FUTUREDAY\nFUNKIN'");
			}
		}
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);
		_parentState.persistentUpdate = true;

		centertext.screenCenter();

		cam.scroll.y += camVelocity * elapsed * 19;
		for (i in stars) {
			if (i.y - (cam.scroll.y * i.scrollFactor.y) < -300) {
				i.y += FlxG.height * 1.5;
			}
		}

		if (Conductor.songPosition >= CoolUtil.stepsToSeconds(128 - 16) * 1000) {
			unidGroup.visible = true;
		}

		if (FlxG.keys.justPressed.F2 || FlxG.keys.justPressed.DELETE) // bios reference lol
			MusicBeatState.switchState(new LogState());

	}

	function makeText(text:String, height:Float = 0, size:Int = 32) {
		var daText = new FlxText(0,0,0,text);
		daText.setFormat(Paths.font('title.ttf'), size, FlxColor.WHITE, CENTER);

		var textFormat = daText.textField.getTextFormat();
		textFormat.letterSpacing = 2;
		daText.textField.setTextFormat(textFormat);
		daText.updateHitbox();
		daText.screenCenter(X);
		daText.y = height;
		daText.scrollFactor.set();
		daText.camera = cam;
		daText.antialiasing = false;
		return daText;
	}

	function makeTypedText(text:String, height:Float = 0, size:Int = 32) {
		var daText = new FlxTypeText(0,0,0,text);
		daText.setFormat(Paths.font('title.ttf'), size, FlxColor.WHITE, CENTER);

		var textFormat = daText.textField.getTextFormat();
		textFormat.letterSpacing = 2;
		daText.textField.setTextFormat(textFormat);
		daText.updateHitbox();
		daText.screenCenter(X);
		daText.y = height;
		daText.scrollFactor.set();
		daText.camera = cam;
		daText.antialiasing = false;
		return daText;
	}

	public static var closedState = false;

	override public function destroy() {
		for (i in members) FlxTween.cancelTweensOf(i);
		FlxG.cameras.remove(cam);
		closedState = true;
		
		GarbageCollector.run(true);
		super.destroy();
	}
}
