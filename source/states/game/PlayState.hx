package states.game;

import engine.camera.FunkCamera;
import engine.fancy.FaceOff;
import engine.arrays.CircularBuffer;
import shaders.WiggleEffect;
import shaders.ColorSwap;
import shaders.BarrelDistortionShader;
import openfl.geom.Matrix;
import openfl.system.Capabilities;
import data.*;
import data.Paths;
import data.StageData.StageFile;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.transition.FlxTransitionableState;
import flixel.animation.FlxAnimationController;
import flixel.effects.particles.FlxEmitter;
import flixel.effects.particles.FlxParticle;
import flixel.graphics.FlxGraphic;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxShader;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxSave;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import haxe.Json;
import haxe.io.Path;
import input.*;
import lime.utils.Assets;
import objects.*;
import objects.Note.EventNote;
import openfl.Lib;
import openfl.display.BlendMode;
import openfl.display.StageQuality;
import openfl.events.KeyboardEvent;
import openfl.filters.BitmapFilter;
import openfl.utils.Assets as OpenFlAssets;
import script.Script;
import script.ScriptGroup;
import script.ScriptUtil;
import shaders.ShaderUtil;
import song.*;
import song.Conductor.Rating;
import song.Section.SwagSection;
import song.Song.SwagSong;
import states.editors.CharacterEditorState;
import states.editors.ChartingState;
import states.game.*;
import states.menus.*;
import states.substates.*;
import states.CreditsState;
import util.*;
import engine.gc.GarbageCollector;

using StringTools;

#if DISCORD_ALLOWED
import util.Discord.DiscordClient;
#end
#if !flash
import openfl.filters.ShaderFilter;
import shaders.FlxRunTimeShader;
#end
#if sys
import sys.FileSystem;
import sys.io.File;
#end
#if VIDEOS_ALLOWED
import objects.PsychVideo;
#end

class PlayState extends MusicBeatState
{
	private var gameCamTween:FlxTween;
	public var zoomTween:FlxTween = null;
	private var camCoords:Array<Array<Float>> = [[15, 0], [0, 15], [0, -15], [-15, 0]];
	private var camCoordsDAD:Array<Array<Float>> = [[-15, 0], [0, 15], [0, -15], [15, 0]]; // i dont care if i could flip the arrays iso
	private var camAngles:Array<Float> = [-1, -0.5, 0.5, 1];
	private var beatZoom:Float = 0.0;
	private var beatAngle:Float = 0.0;
	private var cameraMoveBF:Array<Float> = [0, 0];
	private var cameraMoveDAD:Array<Float> = [0, 0];
	private var camAngle:Float = 0;

	public static var STRUM_X = 46.5;
	public static var STRUM_X_MIDDLESCROLL = -278;

	public static var ratingStuff:Array<Dynamic> = [
		['You Suck!', 0.2], // From 0% to 19%
		['Shit', 0.4], // From 20% to 39%
		['Bad', 0.5], // From 40% to 49%
		['Bruh', 0.6], // From 50% to 59%
		['Meh', 0.69], // From 60% to 68%
		['Nice', 0.7], // 69%
		['Good', 0.8], // From 70% to 79%
		['Great', 0.9], // From 80% to 89%
		['Sick!', 1], // From 90% to 99%
		['Perfect!!', 1] // The value on this one isn't used actually, since Perfect is always "1"
	];

	// event variables
	private var isCameraOnForcedPos:Bool = false;

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var noteKillOffset:Float = 350;

	public var playbackRate(default, set):Float = 1;

	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;

	public var boyfriendMap:Map<String, Boyfriend> = new Map<String, Boyfriend>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();

	public static var curStage:String = '';
	public static var isPixelStage:Bool = false;
	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	public var spawnTime:Float = 2000;

	public var vocals:FlxSound;
	// ok actual opp voice support lol
	public var opponentVocals:FlxSound;

	public static var phase:Int = 1;

	var canPause:Bool = false;

	public static var dad:Character = null;
	public static var gf:Character = null;
	public static var boyfriend:Boyfriend = null;

	var actualNotes:Array<Note> = [];
	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:CircularBuffer<Note>;
	public var eventNotes:Array<EventNote> = [];

	var swagCounter:Int = 0;

	private var strumLine:FlxSprite;

	// Handles the new epic mega sexy cam code that i've done
	public var camFollow:FlxPoint;
	public var camFollowPos:FlxObject;

	private static var prevCamFollow:FlxPoint;
	private static var prevCamFollowPos:FlxObject;

	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	public var camZooming:Bool = true;
	public var camZoomingMult:Float = 1;
	public var camZoomingDecay:Float = 1;

	private var curSong:String = "";

	public var gfSpeed:Int = 1;
	public var health:Float = 1;
	private var displayedHealth:Float = 1;
	public var combo:Int = 0;

	public var healthBar:objects.HealthBar;
	public var healthBarGroup:FlxSpriteGroup;

	public var blackBars:FlxSprite;
	var vinyl:FlxSprite;

	var songPercent:Float = 0;

	public var timeBar:FlxBar;

	public var ratingsData:Array<Rating> = [];
	public var sicks:Int = 0;
	public var goods:Int = 0;
	public var bads:Int = 0;
	public var shits:Int = 0;

	private var generatedMusic:Bool = false;

	public var endingSong:Bool = false;
	public var startingSong:Bool = false;

	private var updateTime:Bool = true;

	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;

	public var cpuControlled:Bool = false;
	public var practiceMode:Bool = false;

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxFixedText;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FunkCamera;
	public static var camGame:FunkCamera;
	public var camOther:FunkCamera;
	public var camNOTES:FunkCamera;
    public var camSus:FunkCamera;
    public var camNOTEHUD:FunkCamera;
	public var cameraSpeed:Float = 1;

	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	public var scoreTxt:FlxText;

	public var variables:Map<String, Dynamic> = new Map();

	//ALLEY ASSETS
	var spotlight1:FlxSprite;
	var spotlight2:FlxSprite;
	var moonGrad:FlxSprite;
	var posts:FlxSprite;
	var lights:FlxSprite;


	//SWAG ON
	var wiggleShit:WiggleEffect = new WiggleEffect();
	var susWiggle:ShaderFilter;
	var filtersnotes:Array<BitmapFilter> = [];
	var filterSUSnotes:Array<BitmapFilter> = [];
	var coolors:ColorSwap; // hey kevin cuntz
	var composer:String;
	var credTxt:FlxText;
	var songTxt:FlxText; // urghhg shakes my jumbo tastic ass
	var scoreTxtTween:FlxTween;

	var hasntStartedYet:Bool = true;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	public var defaultCamZoom:Float = 1.05;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;

	private var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public var inCutscene:Bool = false;
	public var skipCountdown:Bool = false;

	var songLength:Float = 0;

	public static var boyfriendCameraOffset:Array<Float> = null;
	public static var opponentCameraOffset:Array<Float> = null;
	public static var girlfriendCameraOffset:Array<Float> = null;

	#if desktop
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	// Achievement shit
	var keysPressed:Array<Bool> = [];
	var boyfriendIdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;

	public static var instance:PlayState;

	// Debug buttons
	private var debugKeysChart:Array<FlxKey>;
	private var debugKeysCharacter:Array<FlxKey>;

	// Less laggy controls
	private var keysArray:Array<Dynamic>;
	private var controlArray:Array<String>;

	var precacheList:Map<String, String> = new Map<String, String>();

	// stores the last judgement object
	public static var lastRating:FlxSprite;
	// stores the last combo sprite object
	public static var lastCombo:FlxSprite;
	// stores the last combo score objects in an array
	public static var lastScore:Array<FlxSprite> = [];

	public var introSoundsSuffix:String = '';

	public var scripts:ScriptGroup;

	var dadTrail:FlxTrail;
	var bfTrail:FlxTrail;


	override public function create()
	{
		Paths.clearStoredMemory();

		// wow it keeps the stuff from the last song in memory if you do story mode wow! its so good
		FlxG.bitmap.clearUnused();
		GarbageCollector.run(true);

		instance = this;

		scripts = new ScriptGroup();
		scripts.onAddScript.push(onAddScript);
		Character.onCreate = initCharScript;

		debugKeysChart = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
		debugKeysCharacter = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_2'));
		PauseSubState.songName = null; // Reset to default

		keysArray = [
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_left')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_down')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_up')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_right'))
		];

		controlArray = ['NOTE_LEFT', 'NOTE_DOWN', 'NOTE_UP', 'NOTE_RIGHT'];

		unspawnNotes = CircularBuffer.fromArray(actualNotes); // im prob retarded for this but this is for null obj prevention

		// Ratings
		ratingsData.push(new Rating('sick')); // default rating

		var rating:Rating = new Rating('good');
		rating.ratingMod = 0.7;
		rating.score = 200;
		rating.noteSplash = false;
		ratingsData.push(rating);

		var rating:Rating = new Rating('bad');
		rating.ratingMod = 0.4;
		rating.score = 100;
		rating.noteSplash = false;
		ratingsData.push(rating);

		var rating:Rating = new Rating('shit');
		rating.ratingMod = 0;
		rating.score = 50;
		rating.noteSplash = false;
		ratingsData.push(rating);

		// For the "Just the Two of Us" achievement
		for (i in 0...keysArray.length)
		{
			keysPressed.push(false);
		}

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		camGame = new FunkCamera();
		camHUD = new FunkCamera();
		camOther = new FunkCamera();
		camSus = new FunkCamera();
		camSus.bgColor.alpha = 0;
		camNOTES = new FunkCamera();
		camNOTES.bgColor = 0;
		camNOTES.alpha = 0;
		camNOTEHUD = new FunkCamera();
		camNOTEHUD.bgColor = 0;
		camNOTEHUD.alpha = 0;
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camNOTEHUD, false);
		FlxG.cameras.add(camSus, false);
		FlxG.cameras.add(camNOTES, false);
		FlxG.cameras.add(camOther, false);
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();

		FlxG.cameras.setDefaultDrawTarget(camGame, true);
		camSus.setFilters(filterSUSnotes); 

		persistentUpdate = true;
		persistentDraw = true;

		camSus.angle = camNOTES.angle;

		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		scripts.setAll("bpm", Conductor.bpm);

		#if desktop
		storyDifficultyText = CoolUtil.difficulties[storyDifficulty];

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode)
		{
			//detailsText = "DEMO 1: " + WeekData.getCurrentWeek().weekName;
			detailsText = "DEMO WEEK 1";
		}
		else
		{
			detailsText = "Freeplay";
		}

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end

		GameOverSubstate.resetVariables();
		var songName:String = Paths.formatToSongPath(SONG.song);

		curStage = SONG.stage;
		// trace('stage is: ' + curStage);
		if (SONG.stage == null || SONG.stage.length < 1)
		{
			switch (songName)
			{
				default:
					curStage = 'stage';
			}
		}
		SONG.stage = curStage;

		var stageData:StageFile = StageData.getStageFile(curStage);
		if (stageData == null)
		{ // Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = {
				directory: "",
				defaultZoom: 0.9,
				isPixelStage: false,

				boyfriend: [770, 100],
				girlfriend: [400, 130],
				opponent: [100, 100],
				hide_girlfriend: false,

				camera_boyfriend: [0, 0],
				camera_opponent: [0, 0],
				camera_girlfriend: [0, 0],
				camera_speed: 1
			};
		}

		defaultCamZoom = stageData.defaultZoom;
		isPixelStage = stageData.isPixelStage;
		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

		if (stageData.camera_speed != null)
			cameraSpeed = stageData.camera_speed;

		boyfriendCameraOffset = stageData.camera_boyfriend;
		if (boyfriendCameraOffset == null) // Fucks sake should have done it since the start :rolling_eyes:
			boyfriendCameraOffset = [0, 0];

		opponentCameraOffset = stageData.camera_opponent;
		if (opponentCameraOffset == null)
			opponentCameraOffset = [0, 0];

		girlfriendCameraOffset = stageData.camera_girlfriend;
		if (girlfriendCameraOffset == null)
			girlfriendCameraOffset = [0, 0];

		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);

		var gfVersion:String = SONG.gfVersion;
		if (gfVersion == null || gfVersion.length < 1)
		{
			switch (curStage)
			{
				default:
					gfVersion = 'gf';
			}

			SONG.gfVersion = gfVersion; // Fix for the Chart Editor
		}

		if (!stageData.hide_girlfriend)
		{
			gf = new Character(0, 0, gfVersion);
			startCharacterPos(gf);
			gf.scrollFactor.set(0.95, 0.95);
			gfGroup.add(gf);
		}

		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);

		boyfriend = new Boyfriend(0, 0, SONG.player1);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);

		initScripts();
		initSongEvents();

		scripts.executeAllFunc("create");

		if (!ScriptUtil.hasPause(scripts.executeAllFunc("createStage", [curStage])))
		{
			switch (curStage)
			{
				case 'stage': // Week 1
					var bg:FlxSprite = new FlxSprite(-600, -200).loadGraphic(Paths.image('stageback'));
					bg.scrollFactor.set(0.9, 0.9);
					add(bg);

					var stageFront:FlxSprite = new FlxSprite(-650, 600).loadGraphic(Paths.image('stagefront'));
					stageFront.scrollFactor.set(0.9, 0.9);
					stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
					stageFront.updateHitbox();
					add(stageFront);

					if (!ClientPrefs.lowQuality)
					{
						var stageLight:FlxSprite = new FlxSprite(-125, -100).loadGraphic(Paths.image('stage_light'));
						stageLight.scrollFactor.set(0.9, 0.9);
						stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
						stageLight.updateHitbox();
						add(stageLight);

						var stageLight:FlxSprite = new FlxSprite(1225, -100).loadGraphic(Paths.image('stage_light'));
						stageLight.scrollFactor.set(0.9, 0.9);
						stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
						stageLight.updateHitbox();
						stageLight.flipX = true;
						add(stageLight);

						var stageCurtains:FlxSprite = new FlxSprite(-500, -300).loadGraphic(Paths.image('stagecurtains'));
						stageCurtains.scrollFactor.set(1.3, 1.3);
						stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
						stageCurtains.updateHitbox();
						add(stageCurtains);
					}
				case 'alley':
					var sky:FlxSprite = new FlxSprite(-570, -100).loadGraphic(Paths.image('backgrounds/alley/sky'));
					sky.scrollFactor.set(0.2, 0.2);
					sky.antialiasing = true;
					add(sky);

					var buildings:FlxSprite = new FlxSprite(-820, -260).loadGraphic(Paths.image('backgrounds/alley/buildings'));
					buildings.scrollFactor.set(0.5, 0.5);
					buildings.antialiasing = true;
					add(buildings);

					var wall:FlxSprite = new FlxSprite(460, 340).loadGraphic(Paths.image('backgrounds/alley/backwall'));
					wall.scrollFactor.set(0.55, 0.55);
					wall.antialiasing = true;
					wall.setGraphicSize(Std.int(wall.width * 1.6));
					add(wall);

					var wallmain:FlxSprite = new FlxSprite(-1155, -120).loadGraphic(Paths.image('backgrounds/alley/main-part'));
					wallmain.scrollFactor.set(1, 1);
					wallmain.antialiasing = true;

					moonGrad = new FlxSprite(-2455, -820).loadGraphic(Paths.image('backgrounds/alley/moongrad'));
					moonGrad.scrollFactor.set(1, 1);
					moonGrad.antialiasing = true;
					moonGrad.blend = ADD;
					moonGrad.alpha = 0.87;

					posts = new FlxSprite(920, 5).loadGraphic(Paths.image('backgrounds/alley/lamp'));
					posts.scrollFactor.set(1, 1);
					posts.antialiasing = true;

					lights = new FlxSprite(440, 55).loadGraphic(Paths.image('backgrounds/alley/lamp-glow'));
					lights.scrollFactor.set(1, 1);
					lights.antialiasing = true;
					lights.blend = ADD;

					add(wallmain);

					if(!ClientPrefs.lowQuality && ClientPrefs.shaders){
						coolors = new ColorSwap();
						var shader = new BarrelDistortionShader();
						shader.barrelDistortion1 = -0.15;
						shader.barrelDistortion2 = -0.15;
						camGame.setFilters([new ShaderFilter(shader), new ShaderFilter(coolors.shader)]);
					}
			}
		}

		add(gfGroup);
		add(dadGroup);
		add(boyfriendGroup);

		if (curStage == 'alley'){
			add(moonGrad);
			add(posts);
			add(lights);
		}

		var camPos:FlxPoint = new FlxPoint(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if (gf != null)
		{
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		}

		if (dad.curCharacter.startsWith('gf'))
		{
			dad.setPosition(GF_X, GF_Y);
			if (gf != null)
				gf.visible = false;
		}

		Conductor.songPosition = -5000 / Conductor.songPosition;

		strumLine = new FlxSprite(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, 50).makeGraphic(FlxG.width, 10);
		if (ClientPrefs.downScroll)
			strumLine.y = FlxG.height - 150;
		strumLine.scrollFactor.set();

		healthBarGroup = new FlxSpriteGroup();
		healthBarGroup.visible = !cpuControlled;
		healthBarGroup.antialiasing = true;
		add(healthBarGroup);

		healthBar = new HealthBar(800, (ClientPrefs.downScroll ? 80 : FlxG.height * 0.81) , Paths.image("hud/backbar"), Paths.image("hud/frontbar"), this, 'displayedHealth', 0, 2);
		healthBar.scrollFactor.set();
		healthBar.alpha = ClientPrefs.healthBarAlpha;
		healthBarGroup.add(healthBar);
		
		blackBars = new FlxSprite(0, 0).loadGraphic(Paths.image('hud/hud bar'));
		add(blackBars);

		var showTime:Bool = (ClientPrefs.timeBarType != 'Disabled');

		updateTime = showTime;

		timeBar = new FlxBar(230, 730, LEFT_TO_RIGHT, 1050, 7, this,
			'songPercent', 0, 1);
		timeBar.scrollFactor.set();
		timeBar.createFilledBar(0xFF000000, 0xFFFFFFFF);
		timeBar.numDivisions = 800; // How much lag this causes?? Should i tone it down to idk, 400 or 200?
		timeBar.alpha = 0;
		timeBar.visible = showTime;
		add(timeBar);

		vinyl = new FlxSprite(-200, 720).loadGraphic(Paths.image('hud/vinylrecfinal'));
		add(vinyl);
		vinyl.antialiasing = true;

		switch (SONG.song.toLowerCase()) // faggot
		{
			case 'kaseyfunk':
				composer = 'Felx Lamp';
			case 'digital-dreamin':
				composer = 'CitricCinder';
			case 'overclocked':
				composer = 'MagBros78';
			default:
				composer = 'IDK LOL';
		}

		songTxt = new FlxText(0, 0, 700, "", 64);
		songTxt.setFormat(Paths.font("calibri-bold.ttf"), 64, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK); // CRYING WONT UNRAPE YOU
		songTxt.scrollFactor.set();
		songTxt.alpha = 0;
		songTxt.borderSize = 4;
		songTxt.screenCenter();
		songTxt.text = SONG.song.toUpperCase();
		add(songTxt);

		credTxt = new FlxText(0, songTxt.y + 54, 700, "", 32);
		credTxt.setFormat(Paths.font("calibri-bold.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK); // :alien:
		credTxt.scrollFactor.set();
		credTxt.alpha = 0;
		credTxt.borderSize = 2;
		credTxt.screenCenter(X);
		credTxt.text = composer;
		add(credTxt);

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		add(strumLineNotes);
		add(grpNoteSplashes);

		// le wiggle
		wiggleShit.waveAmplitude = 0;
		wiggleShit.effectType = WiggleEffectType.DREAMY;
		wiggleShit.waveFrequency = 0;
		wiggleShit.waveSpeed = 1.8; // fasto
		wiggleShit.shader.uTime.value = [(strumLine.y - Note.swagWidth * 4) / FlxG.height]; // from 4mbr0s3 2
		susWiggle = new ShaderFilter(wiggleShit.shader);

		if (ClientPrefs.swagSustains)
		filterSUSnotes.push(susWiggle); // only enable it for snake notes

		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.0;

		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();

		generateSong(SONG.song);

		camFollow = new FlxPoint();
		camFollowPos = new FlxObject(0, 0, 1, 1);

		snapCamFollowToPos(camPos.x, camPos.y);
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		if (prevCamFollowPos != null)
		{
			camFollowPos = prevCamFollowPos;
			prevCamFollowPos = null;
		}
		add(camFollowPos);

		FlxG.camera.follow(camFollowPos, LOCKON, 0.04);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow);

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;
		moveCameraSection();

		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP1.y = healthBar.y - 30;
		iconP1.visible = !ClientPrefs.hideHud;
		iconP1.alpha = ClientPrefs.healthBarAlpha;
		add(iconP1);

		iconP2 = new HealthIcon(dad.healthIcon, false);
		iconP2.y = healthBar.y - 30;
		iconP2.visible = !ClientPrefs.hideHud;
		iconP2.alpha = ClientPrefs.healthBarAlpha;
		add(iconP2);
		reloadHealthBarColors();

		scoreTxt = new FlxText(345, healthBar.y + 80, FlxG.width, "", 15);
		scoreTxt.setFormat(Paths.font("casmono.ttf"), 15, FlxColor.WHITE, CENTER);
		scoreTxt.scrollFactor.set();
		scoreTxt.visible = !ClientPrefs.hideHud;
		add(scoreTxt);

		botplayTxt = new FlxFixedText(400, 320, FlxG.width - 800, "BOTPLAY", 32);
		botplayTxt.setFormat(Paths.font("goodbyeDespair.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled;
		add(botplayTxt);

		strumLineNotes.cameras = [camNOTEHUD];
		grpNoteSplashes.cameras = [camNOTEHUD];
		notes.cameras = [camNOTES];
		healthBar.cameras = [camHUD];
		blackBars.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		scoreTxt.cameras = [camNOTEHUD];
		botplayTxt.cameras = [camHUD];
		timeBar.cameras = [camHUD];
		songTxt.cameras = [camHUD];
		credTxt.cameras = [camHUD];
		vinyl.cameras = [camHUD];

		startingSong = true;

		var daSong:String = Paths.formatToSongPath(curSong);
		if (isStoryMode && !seenCutscene)
		{
			switch (daSong)
			{
				default:
					startCountdown();
			}
			seenCutscene = true;
		}
		else
		{
			startCountdown();
		}
		RecalculateRating();

		// PRECACHING MISS SOUNDS BECAUSE I THINK THEY CAN LAG PEOPLE AND FUCK THEM UP IDK HOW HAXE WORKS
		if (ClientPrefs.hitsoundVolume > 0)
			precacheList.set('hitsound', 'sound');
		precacheList.set('missnote1', 'sound');
		precacheList.set('missnote2', 'sound');
		precacheList.set('missnote3', 'sound');

		if (PauseSubState.songName != null)
		{
			precacheList.set(PauseSubState.songName, 'music');
		}
		else if (ClientPrefs.pauseMusic != 'None')
		{
			precacheList.set(Paths.formatToSongPath(ClientPrefs.pauseMusic), 'music');
		}

		precacheList.set('alphabet', 'image');

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end

		if (!ClientPrefs.controllerMode)
		{
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}

		super.create();

		cacheCountdown();
		for (key => type in precacheList)
		{
			// trace('Key $key is type $type');
			switch (type)
			{
				case 'image':
					Paths.image(key);
				case 'sound':
					Paths.sound(key);
				case 'music':
					Paths.music(key);
			}
		}
		Paths.clearUnusedMemory();

		GarbageCollector.run(true);

		scripts.executeAllFunc("createPost");
	}

	function set_songSpeed(value:Float):Float
	{
		if (generatedMusic)
		{
			var ratio:Float = value / songSpeed; // funny word huh
			for (note in notes)
				note.resizeByRatio(ratio);
			for (note in unspawnNotes)
				note.resizeByRatio(ratio);
		}
		songSpeed = value;
		noteKillOffset = 350 / songSpeed;
		return value;
	}

	function set_playbackRate(value:Float):Float
	{
		if (generatedMusic)
		{
			if (vocals != null) vocals.pitch = value;
			if(opponentVocals != null) opponentVocals.pitch = value;
			FlxG.sound.music.pitch = value;
		}
		playbackRate = value;
		FlxAnimationController.globalSpeed = value;
		Conductor.safeZoneOffset = (ClientPrefs.safeFrames / 60) * 1000 * value;
		return value;
	}

	public function reloadHealthBarColors()
	{
		var dad = FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]);
		var bf = FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]);

		healthBar.setColors(dad, bf);
	}

	public function addCharacterToList(newCharacter:String, type:Int)
	{
		switch (type)
		{
			case 0:
				if (!boyfriendMap.exists(newCharacter))
				{
					var newBoyfriend:Boyfriend = new Boyfriend(0, 0, newCharacter);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
				}

			case 1:
				if (!dadMap.exists(newCharacter))
				{
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
				}

			case 2:
				if (gf != null && !gfMap.exists(newCharacter))
				{
					var newGf:Character = new Character(0, 0, newCharacter);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.00001;
				}
		}
	}

	function startCharacterPos(char:Character, ?gfCheck:Bool = false)
	{
		if (gfCheck && char.curCharacter.startsWith('gf'))
		{ // IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	public function startVideo(name:String, camera:FunkCamera) // hopefully it functions the same lol!
	{
		#if VIDEOS_ALLOWED
		inCutscene = true;

		var filepath:String = Paths.video(name);
		#if sys
		if (!FileSystem.exists(filepath))
		#else
		if (!OpenFlAssets.exists(filepath))
		#end
		{
			FlxG.log.warn('Couldnt find video file: ' + name);
			startAndEnd();
			return;
		}

		var video:PsychVideo = new PsychVideo(); // we load. add. addCallback.
		video.load(filepath);
		video.scrollFactor.set();
    	add(video);
    	video.antialiasing = ClientPrefs.globalAntialiasing;
		video.cameras = [camera];
		video.addCallback('onEnd',()->{
			startAndEnd();
			return;
		});
		#else
		FlxG.log.warn('Platform not supported!');
		startAndEnd();
		return;
		#end
	}

	function startAndEnd()
	{
		if (endingSong)
			endSong();
		else
			startCountdown();
	}

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;

	// For being able to mess with the sprites on Lua
	public var countdownReady:FlxSprite;
	public var countdownSet:FlxSprite;
	public var countdownGo:FlxSprite;

	public static var startOnTime:Float = 0;

	function cacheCountdown()
	{
		var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
		introAssets.set('default', ['ready', 'set', 'go']);
		introAssets.set('pixel', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);

		var introAlts:Array<String> = introAssets.get('default');
		if (isPixelStage)
			introAlts = introAssets.get('pixel');

		for (asset in introAlts)
			Paths.image(asset);

		Paths.sound('intro3' + introSoundsSuffix);
		Paths.sound('intro2' + introSoundsSuffix);
		Paths.sound('intro1' + introSoundsSuffix);
		Paths.sound('introGo' + introSoundsSuffix);
	}

	var newCoutndownCam:FunkCamera;

	public function startCountdown():Void
	{
		if (startedCountdown)
		{
			return;
		}

		inCutscene = false;

		if (ScriptUtil.hasPause(scripts.executeAllFunc("countdown")))
			return;

		if (skipCountdown || startOnTime > 0)
			skipArrowStartTween = true;

		generateStaticArrows(0);
		generateStaticArrows(1);

		FaceOff.init();

		newCoutndownCam = new FunkCamera();
		newCoutndownCam.bgColor.alpha = 0;

		FlxG.cameras.add(newCoutndownCam, false);

		startedCountdown = true;
		Conductor.songPosition = -Conductor.crochet * 5;

		if (startOnTime < 0)
			startOnTime = 0;

		if (startOnTime > 0)
		{
			clearNotesBefore(startOnTime);
			setSongTime(startOnTime - 350);
			hasntStartedYet = true;
			// return;
		}
		else if (skipCountdown)
		{
			hasntStartedYet = false;
			setSongTime(0);
			return;
		}

		startTimer = new FlxTimer().start(Conductor.crochet / 1000 / playbackRate, function(tmr:FlxTimer)
		{
			if (gf != null
				&& tmr.loopsLeft % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0
				&& gf.animation.curAnim != null
				&& !gf.animation.curAnim.name.startsWith("sing")
				&& !gf.stunned)
			{
				gf.dance();
			}
			if (tmr.loopsLeft % boyfriend.danceEveryNumBeats == 0
				&& boyfriend.animation.curAnim != null
				&& !boyfriend.animation.curAnim.name.startsWith("sing")
				&& !boyfriend.stunned)
			{
				boyfriend.dance();
			}
			if (tmr.loopsLeft % dad.danceEveryNumBeats == 0
				&& dad.animation.curAnim != null
				&& !dad.animation.curAnim.name.startsWith("sing")
				&& !dad.stunned)
			{
				dad.dance();
			}

			var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
			introAssets.set('default', ['ready', 'set', 'go']);
			introAssets.set('pixel', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);

			var introAlts:Array<String> = introAssets.get('default');
			var antialias:Bool = ClientPrefs.globalAntialiasing;
			if (isPixelStage)
			{
				introAlts = introAssets.get('pixel');
				antialias = false;
			}

			switch (swagCounter)
			{
				case 0:
					FlxG.sound.play(Paths.sound('intro3' + introSoundsSuffix), 0.6);
					phase = 1;
					FaceOff.faceOff(1);
				case 1:
					phase = 6;
					FaceOff.faceOff(6);
					countdownReady = new FlxSprite().loadGraphic(Paths.image(introAlts[0]));
					countdownReady.cameras = [newCoutndownCam];
					countdownReady.scrollFactor.set();
					countdownReady.updateHitbox();

					if (PlayState.isPixelStage)
						countdownReady.setGraphicSize(Std.int(countdownReady.width * daPixelZoom));

					countdownReady.screenCenter();
					countdownReady.antialiasing = antialias;
					insert(members.indexOf(notes), countdownReady);
					FlxTween.tween(countdownReady, {/*y: countdownReady.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							remove(countdownReady);
							countdownReady.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('intro2' + introSoundsSuffix), 0.6);
				case 2:
					phase = 12;
					FaceOff.faceOff(12);
					countdownSet = new FlxSprite().loadGraphic(Paths.image(introAlts[1]));
					countdownSet.cameras = [newCoutndownCam];
					countdownSet.scrollFactor.set();

					if (PlayState.isPixelStage)
						countdownSet.setGraphicSize(Std.int(countdownSet.width * daPixelZoom));

					countdownSet.screenCenter();
					countdownSet.antialiasing = antialias;
					insert(members.indexOf(notes), countdownSet);
					FlxTween.tween(countdownSet, {/*y: countdownSet.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							remove(countdownSet);
							countdownSet.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('intro1' + introSoundsSuffix), 0.6);
				case 3:
					phase = 16;
					FaceOff.faceOff(16);
					countdownGo = new FlxSprite().loadGraphic(Paths.image(introAlts[2]));
					countdownGo.cameras = [newCoutndownCam];
					countdownGo.scrollFactor.set();

					if (PlayState.isPixelStage)
						countdownGo.setGraphicSize(Std.int(countdownGo.width * daPixelZoom));

					countdownGo.updateHitbox();

					countdownGo.screenCenter();
					countdownGo.antialiasing = antialias;
					insert(members.indexOf(notes), countdownGo);
					FlxTween.tween(countdownGo, {/*y: countdownGo.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							remove(countdownGo);
							countdownGo.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('introGo' + introSoundsSuffix), 0.6);
				case 4:
					hasntStartedYet = false;
					canPause = true;
			}

			notes.forEachAlive(function(note:Note)
			{
				if (ClientPrefs.opponentStrums || note.mustPress)
				{
					note.copyAlpha = false;
					note.alpha = note.multAlpha;
					if (ClientPrefs.middleScroll && !note.mustPress)
					{
						note.alpha *= 0.35;
					}
				}
			});
			scripts.executeAllFunc("countTick", [swagCounter]);

			swagCounter += 1;
		}, 5);
	}

	public function addBehindGF(obj:FlxObject)
	{
		insert(members.indexOf(gfGroup), obj);
	}

	public function addBehindBF(obj:FlxObject)
	{
		insert(members.indexOf(boyfriendGroup), obj);
	}

	public function addBehindDad(obj:FlxObject)
	{
		insert(members.indexOf(dadGroup), obj);
	}

	public function clearNotesBefore(time:Float)
	{
		var i:Int = unspawnNotes.length - 1;
		while (i >= 0)
		{
			var daNote:Note = unspawnNotes[i];
			if (daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				daNote.kill();
				daNote.destroy();
			}
			--i;
		}

		i = notes.length - 1;
		while (i >= 0)
		{
			var daNote:Note = notes.members[i];
			if (daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				daNote.kill();
				notes.remove(daNote, true);
				daNote.destroy();
			}
			--i;
		}
	}

	public function updateScore(miss:Bool = false)
	{
		if (ScriptUtil.hasPause(scripts.executeAllFunc("updateScore", [miss])))
			return;

		scoreTxt.text = 'Score: '
			+ songScore
			+ ' | Misses: '
			+ songMisses
			+ ' | Rating: '
			+ ratingName
			+ (ratingName != '?' ? ' (${Highscore.floorDecimal(ratingPercent * 100, 2)}%)' : '');

		if (ClientPrefs.scoreZoom && !miss && !cpuControlled)
		{
			if (scoreTxtTween != null)
			{
				scoreTxtTween.cancel();
			}
			scoreTxt.scale.x = 1.075;
			scoreTxt.scale.y = 1.075;
			scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {
				onComplete: function(twn:FlxTween)
				{
					scoreTxtTween = null;
				}
			});
		}
	}

	public function setSongTime(time:Float)
	{
		if (time < 0)
			time = 0;

		FlxG.sound.music.pause();
		vocals.pause();
		opponentVocals.pause();

		FlxG.sound.music.time = time;
		FlxG.sound.music.pitch = playbackRate;
		if (!hasntStartedYet) FlxG.sound.music.play();

		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = time;
			vocals.pitch = playbackRate;
			opponentVocals.time = time;
			opponentVocals.pitch = playbackRate;
		}
		
		if (!hasntStartedYet) {
			vocals.play();
			opponentVocals.play();
		} 
		
		Conductor.songPosition = time;
		songTime = time;
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	function startSong():Void
	{
		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength);
		#end

		if (ScriptUtil.hasPause(scripts.executeAllFunc("startSong")))
			return;

		if (hasntStartedYet) return;

		startingSong = false;

		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 1, false);
		FlxG.sound.music.pitch = playbackRate;
		FlxG.sound.music.onComplete = finishSong.bind();
		opponentVocals.play();
		vocals.play();

		if (startOnTime > 0)
		{
			setSongTime(startOnTime - 500);
		}
		startOnTime = 0;

		if (paused)
		{
			// trace('Oopsie doopsie! Paused sound');
			FlxG.sound.music.pause();
			vocals.pause();
			opponentVocals.pause();
		}

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
		// not sorry :P
		FlxTween.tween(timeBar, {alpha: 1, y: 713}, 1.2, {ease: FlxEase.circOut});
		FlxTween.tween(songTxt, {alpha: 1}, 0.8, {ease: FlxEase.circOut});
		FlxTween.tween(credTxt, {alpha: 1}, 0.8, {ease: FlxEase.circOut});
		FlxTween.tween(vinyl, {y: 520}, 1.2, {ease: FlxEase.circOut});
		FlxTween.tween(camNOTES, {alpha: 1}, 0.4, {ease: FlxEase.circOut});
		FlxTween.tween(camNOTEHUD, {alpha: 1}, 0.4, {ease: FlxEase.circOut});

		if (curStep > 32) {
			removeTextManual();
		}
	}

	var debugNum:Int = 0;
	private var noteTypeMap:Map<String, Bool> = new Map<String, Bool>();
	private var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();

	private function generateSong(dataPath:String):Void
	{
		songSpeed = SONG.speed;

		var songData = SONG;
		Conductor.changeBPM(songData.bpm);
		scripts.setAll("bpm", Conductor.bpm);

		curSong = songData.song;

		if (SONG.needsVoices) {
			vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
			opponentVocals = new FlxSound().loadEmbedded(Paths.secVoices(PlayState.SONG.song));
		} else {
			vocals = new FlxSound();
			opponentVocals = new FlxSound();
		}

		opponentVocals.pitch = vocals.pitch = playbackRate;
		vocals.pitch = playbackRate;
		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(opponentVocals);
		FlxG.sound.list.add(new FlxSound().loadEmbedded(Paths.inst(PlayState.SONG.song)));

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var playerCounter:Int = 0;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped

		var songName:String = Paths.formatToSongPath(SONG.song);
		var file:String = Paths.json(songName + '/events');
		if (FileSystem.exists(file))
		{
			var eventsData:Array<Dynamic> = Song.loadFromJson('events', songName).events;
			for (event in eventsData) // Event Notes
			{
				for (i in 0...event[1].length)
				{
					var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
					var subEvent:EventNote = {
						strumTime: newEventNote[0] + ClientPrefs.noteOffset,
						event: newEventNote[1],
						value1: newEventNote[2],
						value2: newEventNote[3],
						value3: newEventNote[4]
					};
					subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
					eventNotes.push(subEvent);
					eventPushed(subEvent);
				}
			}
		}

		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);

				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > 3)
				{
					gottaHitNote = !section.mustHitSection;
				}
				var oldNote:Note;

				if (actualNotes.length > 0)
					oldNote = actualNotes[Std.int(actualNotes.length - 1)];
				else
					oldNote = null;
				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);

				swagNote.mustPress = gottaHitNote;
				swagNote.sustainLength = songNotes[2];
				swagNote.gfNote = (section.gfSection && (songNotes[1] < 4));
				swagNote.noteType = songNotes[3];
				if (!Std.isOfType(songNotes[3], String))
					swagNote.noteType = ChartingState.noteTypeList[songNotes[3]]; // Backward compatibility + compatibility with Week 7 charts
				swagNote.scrollFactor.set();
				var susLength:Float = swagNote.sustainLength;

				actualNotes.push(swagNote);

				susLength = susLength / Conductor.stepCrochet;
				var floorSus:Int = Math.floor(susLength);

				Note.__pool = new FlxTypedGroup<Note>();
				for (i in 0...32)
				{
					var poolObj:Note = new Note(daStrumTime, daNoteData, oldNote);
					poolObj.kill();
		
					Note.__pool.add(poolObj);
				}
		
				NoteSplash.__pool = new FlxTypedGroup<NoteSplash>();
				for (i in 0...8)
				{
					var poolObj:NoteSplash = new NoteSplash();
					poolObj.kill();
		
					NoteSplash.__pool.add(poolObj);
				}

				if (floorSus > 0)
				{
					for (susNote in 0...floorSus + 1)
					{
						oldNote = actualNotes[Std.int(actualNotes.length - 1)];
						var sustainNote:Note = new Note(daStrumTime
							+ (Conductor.stepCrochet * susNote)
							+ (Conductor.stepCrochet / FlxMath.roundDecimal(songSpeed, 2)), daNoteData,
							oldNote, true);

						sustainNote.mustPress = gottaHitNote;
						sustainNote.gfNote = (section.gfSection && (songNotes[1] < 4));
						sustainNote.noteType = swagNote.noteType;
						sustainNote.scrollFactor.set();
						swagNote.tail.push(sustainNote);
						sustainNote.parent = swagNote;
						actualNotes.push(sustainNote);
						if (sustainNote.mustPress)
						{
							sustainNote.x += FlxG.width / 2; // general offset
						}
						else if (ClientPrefs.middleScroll)
						{
							sustainNote.x += 310;
							if (daNoteData > 1) // Up and Right
							{
								sustainNote.x += FlxG.width / 2 + 25;
							}
						}
					}
				}
				if (swagNote.mustPress)
				{
					swagNote.x += FlxG.width / 2; // general offset
				}
				else if (ClientPrefs.middleScroll)
				{
					swagNote.x += 310;
					if (daNoteData > 1) // Up and Right
					{
						swagNote.x += FlxG.width / 2 + 25;
					}
				}
				if (!noteTypeMap.exists(swagNote.noteType))
				{
					noteTypeMap.set(swagNote.noteType, true);
				}
			}
			daBeats += 1;
		}
		for (event in songData.events) // Event Notes
		{
			for (i in 0...event[1].length)
			{
				var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
				var subEvent:EventNote = {
					strumTime: newEventNote[0] + ClientPrefs.noteOffset,
					event: newEventNote[1],
					value1: newEventNote[2],
					value2: newEventNote[3],
					value3: newEventNote[4]
				};
				subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
				eventNotes.push(subEvent);
				eventPushed(subEvent);
			}
		}
		// trace(unspawnNotes.length);
		// playerCounter += 1;
		actualNotes.sort(sortByShit);
		if (eventNotes.length > 1)
		{ // No need to sort if there's a single one or none at all
			eventNotes.sort(sortByTime);
		}
		checkEventNote();
		generatedMusic = true;
	}

	function eventPushed(event:EventNote)
	{
		switch (event.event)
		{
			case 'Change Character':
				var charType:Int = 0;
				switch (event.value1.toLowerCase())
				{
					case 'gf' | 'girlfriend' | '1':
						charType = 2;
					case 'dad' | 'opponent' | '0':
						charType = 1;
					default:
						charType = Std.parseInt(event.value1);
						if (Math.isNaN(charType)) charType = 0;
				}

				var newCharacter:String = event.value2;
				addCharacterToList(newCharacter, charType);
		}

		if (!eventPushedMap.exists(event.event))
		{
			eventPushedMap.set(event.event, true);
		}
	}

	function eventNoteEarlyTrigger(event:EventNote):Float
	{
		var val:Array<Dynamic> = scripts.executeAllFunc("earlyEvent", [event.event]);

		for (_ in val)
		{
			if (_ != null && Std.isOfType(_, Float) && !Math.isNaN(_))
				return _;
		}

		switch (event.event) {}
		return 0;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	function sortByTime(Obj1:EventNote, Obj2:EventNote):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	public var skipArrowStartTween:Bool = false; // for lua

	private function generateStaticArrows(player:Int):Void
	{
		for (i in 0...4)
		{
			// FlxG.log.add(i);
			var targetAlpha:Float = 1;
			if (player < 1)
			{
				if (!ClientPrefs.opponentStrums)
					targetAlpha = 0;
				else if (ClientPrefs.middleScroll)
					targetAlpha = 0.35;
			}

			var babyArrow:StrumNote = new StrumNote(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, strumLine.y, i, player);
			babyArrow.downScroll = ClientPrefs.downScroll;
			if (!isStoryMode && !skipArrowStartTween)
			{
				// babyArrow.y -= 10;
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {/*y: babyArrow.y + 10,*/ alpha: targetAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}
			else
			{
				babyArrow.alpha = targetAlpha;
			}

			if (player == 1)
			{
				playerStrums.add(babyArrow);
			}
			else
			{
				if (ClientPrefs.middleScroll)
				{
					babyArrow.x += 310;
					if (i > 1)
					{ // Up and Right
						babyArrow.x += FlxG.width / 2 + 25;
					}
				}
				opponentStrums.add(babyArrow);
			}

			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();
		}
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
				opponentVocals.pause();
			}

			if (startTimer != null && !startTimer.finished)
				startTimer.active = false;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = false;
			if (songSpeedTween != null)
				songSpeedTween.active = false;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (char in chars)
			{
				if (char != null && char.colorTween != null)
				{
					char.colorTween.active = false;
				}
			}
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (!ScriptUtil.hasPause(scripts.executeAllFunc("resume")))
			{
				if (FlxG.sound.music != null && !startingSong)
				{
					resyncVocals();
				}

				if (startTimer != null && !startTimer.finished)
					startTimer.active = true;
				if (finishTimer != null && !finishTimer.finished)
					finishTimer.active = true;
				if (songSpeedTween != null)
					songSpeedTween.active = true;

				var chars:Array<Character> = [boyfriend, gf, dad];
				for (char in chars)
				{
					if (char != null && char.colorTween != null)
					{
						char.colorTween.active = true;
					}
				}

				paused = false;

				#if DISCORD_ALLOWED
				if (startTimer != null && startTimer.finished)
				{
					DiscordClient.changePresence(detailsText, SONG.song
						+ " ("
						+ storyDifficultyText
						+ ")", iconP2.getCharacter(), true,
						songLength
						- Conductor.songPosition
						- ClientPrefs.noteOffset);
				}
				else
				{
					DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
				}
				#end
			}
		}

		super.closeSubState();
	}

	override public function onFocus():Void
	{
		#if DISCORD_ALLOWED
		if (health > 0 && !paused)
		{
			if (Conductor.songPosition > 0.0)
			{
				DiscordClient.changePresence(detailsText, SONG.song
					+ " ("
					+ storyDifficultyText
					+ ")", iconP2.getCharacter(), true,
					songLength
					- Conductor.songPosition
					- ClientPrefs.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
			}
		}
		#end

		super.onFocus();
	}

	override public function onFocusLost():Void
	{
		#if DISCORD_ALLOWED
		if (health > 0 && !paused)
		{
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		}
		#end

		super.onFocusLost();
	}

	function resyncVocals():Void
	{
		if (finishTimer != null)
			return;

		vocals.pause();
		opponentVocals.pause();

		if (!hasntStartedYet) FlxG.sound.music.play();
		FlxG.sound.music.pitch = playbackRate;
		Conductor.songPosition = FlxG.sound.music.time;
		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = Conductor.songPosition;
			vocals.pitch = playbackRate;
			opponentVocals.time = Conductor.songPosition;
			opponentVocals.pitch = playbackRate;
		}

		if (!hasntStartedYet) {
			vocals.play();
			opponentVocals.play();
		}
	}

	public var paused:Bool = false;
	public var canReset:Bool = true;

	var startedCountdown:Bool = false;
	var limoSpeed:Float = 0;
	var floaty:Float = 0;

	override public function update(elapsed:Float)
	{
		if (scripts != null)
		{
			scripts.update(elapsed);
		}

		if (swagCounter != 0 && unspawnNotes.length > 0)
			{
				for (i in 0...unspawnNotes.length)
				{
					var note:Note = unspawnNotes.get(i);
	
					if (note.strumTime - Conductor.songPosition > 1500)
						break;
	
					var currentNote:Note = Note.__pool.recycle(Note);
					currentNote.revive();
					currentNote.preventDraw = false;
	
					notes.add(currentNote);
					unspawnNotes.remove(unspawnNotes.indexOf(note));
				}
			}

		if(curStage == 'alley'){
			if(ClientPrefs.shaders)
				coolors.saturation = FlxMath.lerp(coolors.saturation, 0, (elapsed / (1/60)) * 0.05);
		}

		vinyl.angle += SONG.bpm * 0.003; // adjust speed to bpm

		displayedHealth = FlxMath.lerp(displayedHealth, health, elapsed*6); // noticable lerp

		wiggleShit.waveAmplitude = FlxMath.lerp(wiggleShit.waveAmplitude, 0, 0.05 / (ClientPrefs.framerate / 60));
		wiggleShit.waveFrequency = FlxMath.lerp(wiggleShit.waveFrequency, 0, 0.05 / (ClientPrefs.framerate / 60));

	   	wiggleShit.update(elapsed);

		if (!inCutscene)
		{
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 3.6 * cameraSpeed * playbackRate, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
			
			if(ClientPrefs.camMoveTilt)
			camGame.angle = FlxMath.lerp(camGame.angle, camAngle, lerpVal);

			if (!startingSong
				&& !endingSong
				&& boyfriend.getAnimationName().startsWith('idle'))
			{
				boyfriendIdleTime += elapsed;
				if (boyfriendIdleTime >= 0.15)
				{ // Kind of a mercy thing for making the achievement easier to get as it's apparently frustrating to some playerss
					boyfriendIdled = true;
				}
			}
			else
			{
				boyfriendIdleTime = 0;
			}
		}

		super.update(elapsed);

		if (botplayTxt.visible)
		{
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}

		if (controls.PAUSE && startedCountdown && canPause)
		{
			if (!ScriptUtil.hasPause(scripts.executeAllFunc("pause"))) {
				openPauseMenu();
			}
		}

		// FlxG.watch.addQuick('VOL', vocals.amplitudeLeft);
		// FlxG.watch.addQuick('VOLRight', vocals.amplitudeRight);

		// make icons scale from the middle instead of the gap or whatever its 4am
		iconP1.offset.set(150, 70);
		iconP2.offset.set(20, 70);

		var mult:Float = FlxMath.lerp(0.8, iconP1.scale.x, CoolUtil.boundTo(1 - (elapsed * 9 * playbackRate), 0, 1));
		iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();

		var mult:Float = FlxMath.lerp(0.8, iconP2.scale.x, CoolUtil.boundTo(1 - (elapsed * 9 * playbackRate), 0, 1));
		iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();

		var iconOffset:Int = 26;

		iconP1.x = healthBar.getMidpoint().x + 130;
		iconP2.x = healthBar.getMidpoint().x - 270;

		if (health > 2)
			health = 2;

		if (healthBar.percent < 20)
			iconP1.animation.curAnim.curFrame = 1;
		else
			iconP1.animation.curAnim.curFrame = 0;

		if (healthBar.percent > 80)
			iconP2.animation.curAnim.curFrame = 1;
		else
			iconP2.animation.curAnim.curFrame = 0;

		if (startedCountdown)
		{
			Conductor.songPosition += FlxG.elapsed * 1000 * playbackRate;
		}

		if (startingSong)
		{
			if (startedCountdown && Conductor.songPosition >= 0 && !hasntStartedYet)
				startSong();
			else if (!startedCountdown)
				Conductor.songPosition = -Conductor.crochet * 5;
		}
		else
		{
			if (!paused)
			{
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				// Interpolation type beat
				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
					// Conductor.songPosition += FlxG.elapsed * 1000;
					// trace('MISSED FRAME');
				}

				if (updateTime)
				{
					var curTime:Float = Conductor.songPosition - ClientPrefs.noteOffset;
					if (curTime < 0)
						curTime = 0;
					songPercent = (curTime / songLength);

					var songCalc:Float = (songLength - curTime);
					if (ClientPrefs.timeBarType == 'Time Elapsed')
						songCalc = curTime;

					var secondsTotal:Int = Math.floor(songCalc / 1000);
					if (secondsTotal < 0)
						secondsTotal = 0;
				}
			}

			// Conductor.lastSongPos = FlxG.sound.music.time;
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * camZoomingDecay * playbackRate), 0, 1));
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * camZoomingDecay * playbackRate), 0, 1));
			camNOTEHUD.zoom = FlxMath.lerp(1, camNOTEHUD.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * camZoomingDecay * playbackRate), 0, 1));
			camNOTES.zoom = FlxMath.lerp(1, camNOTES.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * camZoomingDecay * playbackRate), 0, 1));
		}

		// RESET = Quick Game Over Screen
		if (!ClientPrefs.noReset && controls.RESET && canReset && !inCutscene && startedCountdown && !endingSong)
		{
			health = 0;
		}
		doDeathCheck();

		if (actualNotes[0] != null)
		{
			var time:Float = spawnTime;
			if (songSpeed < 1)
				time /= songSpeed;
			if (actualNotes[0].multSpeed < 1)
				time /= actualNotes[0].multSpeed;

			while (actualNotes.length > 0 && actualNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = actualNotes[0];

				if (!ScriptUtil.hasPause(scripts.executeAllFunc("spawnNote", [dunceNote])))
				{
					notes.insert(0, dunceNote);
					dunceNote.spawned = true;
				}

				var index:Int = actualNotes.indexOf(dunceNote);
				actualNotes.splice(index, 1);
			}
		}

		if (generatedMusic && !inCutscene)
		{
			if (!cpuControlled)
			{
				keyShit();
			}
			else if (boyfriend.animation.curAnim != null
				&& boyfriend.holdTimer > Conductor.stepCrochet * (0.0011 / FlxG.sound.music.pitch) * boyfriend.singDuration
				&& boyfriend.animation.curAnim.name.startsWith('sing')
				&& !boyfriend.animation.curAnim.name.endsWith('miss'))
			{
				boyfriend.dance();
				// boyfriend.animation.curAnim.finish();
			}

			if (startedCountdown)
			{
				if (!ScriptUtil.hasPause(scripts.executeAllFunc("notesUpdate")))
				{
					var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
					notes.forEachAlive(function(daNote:Note)
					{
						var strumGroup:FlxTypedGroup<StrumNote> = playerStrums;
						if (!daNote.mustPress)
							strumGroup = opponentStrums;

						if (daNote.isSustainNote)
							daNote.cameras = [camSus];

						var strumX:Float = strumGroup.members[daNote.noteData].x;
						var strumY:Float = strumGroup.members[daNote.noteData].y;
						var strumAngle:Float = strumGroup.members[daNote.noteData].angle;
						var strumDirection:Float = strumGroup.members[daNote.noteData].direction;
						var strumAlpha:Float = strumGroup.members[daNote.noteData].alpha;
						var strumScroll:Bool = strumGroup.members[daNote.noteData].downScroll;

						strumX += daNote.offsetX;
						strumY += daNote.offsetY;
						strumAngle += daNote.offsetAngle;
						strumAlpha *= daNote.multAlpha;

						if (strumScroll) // Downscroll
						{
							// daNote.y = (strumY + 0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed);
							daNote.distance = (0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed * daNote.multSpeed);
						}
						else // Upscroll
						{
							// daNote.y = (strumY - 0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed);
							daNote.distance = (-0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed * daNote.multSpeed);
						}

						var angleDir = strumDirection * Math.PI / 180;
						if (daNote.copyAngle)
							daNote.angle = strumDirection - 90 + strumAngle;

						if (daNote.copyAlpha)
							daNote.alpha = strumAlpha;

						if (daNote.copyX)
							daNote.x = strumX + Math.cos(angleDir) * daNote.distance;

						if (daNote.copyY)
						{
							daNote.y = strumY + Math.sin(angleDir) * daNote.distance;

							// Jesus fuck this took me so much mother fucking time AAAAAAAAAA
							if (strumScroll && daNote.isSustainNote)
							{
								if (daNote.animation.curAnim.name.endsWith('end'))
								{
									daNote.y += 10.5 * (fakeCrochet / 400) * 1.5 * songSpeed + (46 * (songSpeed - 1));
									daNote.y -= 46 * (1 - (fakeCrochet / 600)) * songSpeed;
									if (PlayState.isPixelStage)
									{
										daNote.y += 8 + (6 - daNote.originalHeightForCalcs) * PlayState.daPixelZoom;
									}
									else
									{
										daNote.y -= 19;
									}
								}
								daNote.y += (Note.swagWidth / 2) - (60.5 * (songSpeed - 1));
								daNote.y += 27.5 * ((SONG.bpm / 100) - 1) * (songSpeed - 1);
							}
						}

						if (!daNote.mustPress && daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
						{
							opponentNoteHit(daNote);
						}

						if (!daNote.blockHit && daNote.mustPress && cpuControlled && daNote.canBeHit)
						{
							if (daNote.isSustainNote)
							{
								if (daNote.canBeHit)
								{
									goodNoteHit(daNote);
								}
							}
							else if (daNote.strumTime <= Conductor.songPosition || daNote.isSustainNote)
							{
								goodNoteHit(daNote);
							}
						}

						var center:Float = strumY + Note.swagWidth / 2;
						if (strumGroup.members[daNote.noteData].sustainReduce
							&& daNote.isSustainNote
							&& (daNote.mustPress || !daNote.ignoreNote)
							&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
						{
							if (strumScroll)
							{
								if (daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center)
								{
									var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
									swagRect.height = (center - daNote.y) / daNote.scale.y;
									swagRect.y = daNote.frameHeight - swagRect.height;

									daNote.clipRect = swagRect;
								}
							}
							else
							{
								if (daNote.y + daNote.offset.y * daNote.scale.y <= center)
								{
									var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
									swagRect.y = (center - daNote.y) / daNote.scale.y;
									swagRect.height -= swagRect.y;

									daNote.clipRect = swagRect;
								}
							}
						}

						// Kill extremely late notes and cause misses
						if (Conductor.songPosition > noteKillOffset + daNote.strumTime)
						{
							if (daNote.mustPress && !cpuControlled && !daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit))
							{
								noteMiss(daNote);
							}

							daNote.active = false;
							daNote.visible = false;

							daNote.kill();
							notes.remove(daNote, true);
							daNote.destroy();
						}
					});
				}
				else
				{
					notes.forEachAlive(function(daNote:Note)
					{
						daNote.canBeHit = false;
						daNote.wasGoodHit = false;
					});
				}
			}
		}
		checkEventNote();

		#if debug
		if (!endingSong && !startingSong)
		{
			if (FlxG.keys.justPressed.ONE)
			{
				KillNotes();
				FlxG.sound.music.onComplete();
			}
			if (FlxG.keys.justPressed.TWO)
			{ // Go 10 seconds into the future :O
				setSongTime(Conductor.songPosition + 10000);
				clearNotesBefore(Conductor.songPosition);
			}
		}
		#end

		if (scripts != null)
			scripts.executeAllFunc("updatePost", [elapsed]);
	}

	function openPauseMenu()
	{
		persistentUpdate = false;
		persistentDraw = true;
		paused = true;

		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.pause();
			vocals.pause();
			opponentVocals.pause();
		}
		openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
		// }

		#if DISCORD_ALLOWED
		DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end
	}

	function openChartEditor()
	{
		persistentUpdate = false;
		paused = true;
		cancelMusicFadeTween();
		MusicBeatState.switchState(new ChartingState());
		chartingMode = true;

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Chart Editor", null, null, true);
		#end
	}

	public var isDead:Bool = false; // Don't mess with this on Lua!!!

	function doDeathCheck(?skipHealthCheck:Bool = false)
	{
		if (((skipHealthCheck && false) || health <= 0) && !practiceMode && !isDead)
		{
			if (ScriptUtil.hasPause(scripts.executeAllFunc("gameOver")))
				return false;

			boyfriend.stunned = true;
			deathCounter++;

			paused = true;

			vocals.stop();
			opponentVocals.stop();
			FlxG.sound.music.stop();

			persistentUpdate = false;
			persistentDraw = false;

			if(zoomTween != null)
				zoomTween.cancel();

			openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x - boyfriend.positionArray[0],
				boyfriend.getScreenPosition().y - boyfriend.positionArray[1], camFollowPos.x, camFollowPos.y));

			// MusicBeatState.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

			#if DISCORD_ALLOWED
			// Game Over doesn't get his own variable because it's only used here
			DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
			#end
			isDead = true;
			return true;
		}
		return false;
	}

	public function checkEventNote()
	{
		while (eventNotes.length > 0)
		{
			var leStrumTime:Float = eventNotes[0].strumTime;
			if (Conductor.songPosition < leStrumTime)
			{
				break;
			}

			var value1:String = '';
			if (eventNotes[0].value1 != null)
				value1 = eventNotes[0].value1;

			var value2:String = '';
			if (eventNotes[0].value2 != null)
				value2 = eventNotes[0].value2;

			var value3:String = '';
			if(eventNotes[0].value3 != null)
				value3 = eventNotes[0].value3;

			triggerEventNote(eventNotes[0].event, value1, value2, value3);
			eventNotes.shift();
		}
	}

	public function getControl(key:String)
	{
		var pressed:Bool = Reflect.getProperty(controls, key);
		// trace('Control result: ' + pressed);
		return pressed;
	}

	public function triggerEventNote(eventName:String, value1:String, value2:String, ?value3:String)
	{
		var flValue1:Null<Float> = Std.parseFloat(value1);
		var flValue2:Null<Float> = Std.parseFloat(value2);
		if(Math.isNaN(flValue1)) flValue1 = null;
		if(Math.isNaN(flValue2)) flValue2 = null;
		switch (eventName)
		{
			case 'Set GF Speed':
				var value:Int = Std.parseInt(value1);
				if (Math.isNaN(value) || value < 1)
					value = 1;
				gfSpeed = value;

			case 'Add Camera Zoom':
				if (ClientPrefs.camZooms && FlxG.camera.zoom < 1.35)
				{
					var camZoom:Float = Std.parseFloat(value1);
					var hudZoom:Float = Std.parseFloat(value2);
					if (Math.isNaN(camZoom))
						camZoom = 0.015;
					if (Math.isNaN(hudZoom))
						hudZoom = 0.03;

					FlxG.camera.zoom += camZoom;
					camHUD.zoom += hudZoom;
					camNOTEHUD.zoom += hudZoom;
					camNOTES.zoom += hudZoom;
				}

			case 'Play Animation':
				// trace('Anim to play: ' + value1);
				var char:Character = dad;
				switch (value2.toLowerCase().trim())
				{
					case 'bf' | 'boyfriend':
						char = boyfriend;
					case 'gf' | 'girlfriend':
						char = gf;
					default:
						var val2:Int = Std.parseInt(value2);
						if (Math.isNaN(val2))
							val2 = 0;

						switch (val2)
						{
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					char.playAnim(value1, true);
					char.specialAnim = true;
				}

			case 'Hey!':
				var value:Int = 2;
				switch(value1.toLowerCase().trim()) {
					case 'bf' | 'boyfriend' | '0':
						value = 0;
					case 'gf' | 'girlfriend' | '1':
						value = 1;
				}

				if(flValue2 == null || flValue2 <= 0) flValue2 = 0.6;

				if(value != 0) {
					if(dad.curCharacter.startsWith('gf')) { //Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = flValue2;
					} else if (gf != null) {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = flValue2;
					}
				}
				if(value != 1) {
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = flValue2;
				}
			case 'Camera Follow Pos':
				if (camFollow != null)
				{
					var val1:Float = Std.parseFloat(value1);
					var val2:Float = Std.parseFloat(value2);
					if (Math.isNaN(val1))
						val1 = 0;
					if (Math.isNaN(val2))
						val2 = 0;

					isCameraOnForcedPos = false;
					if (!Math.isNaN(Std.parseFloat(value1)) || !Math.isNaN(Std.parseFloat(value2)))
					{
						camFollow.x = val1;
						camFollow.y = val2;
						isCameraOnForcedPos = true;
					}
				}

			case 'Alt Idle Animation':
				var char:Character = dad;
				switch (value1.toLowerCase().trim())
				{
					case 'gf' | 'girlfriend':
						char = gf;
					case 'boyfriend' | 'bf':
						char = boyfriend;
					default:
						var val:Int = Std.parseInt(value1);
						if (Math.isNaN(val))
							val = 0;

						switch (val)
						{
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					char.idleSuffix = value2;
					char.recalculateDanceIdle();
				}

			case 'Screen Shake':
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FunkCamera> = [camGame, camHUD];
				for (i in 0...targetsArray.length)
				{
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = 0;
					var intensity:Float = 0;
					if (split[0] != null)
						duration = Std.parseFloat(split[0].trim());
					if (split[1] != null)
						intensity = Std.parseFloat(split[1].trim());
					if (Math.isNaN(duration))
						duration = 0;
					if (Math.isNaN(intensity))
						intensity = 0;

					if (duration > 0 && intensity != 0)
					{
						targetsArray[i].shake(intensity, duration);
					}
				}

			case 'Change Character':
				var charType:Int = 0;
				switch (value1.toLowerCase().trim())
				{
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						charType = Std.parseInt(value1);
						if (Math.isNaN(charType)) charType = 0;
				}

				switch (charType)
				{
					case 0:
						if (boyfriend.curCharacter != value2)
						{
							if (!boyfriendMap.exists(value2))
							{
								addCharacterToList(value2, charType);
							}

							var lastAlpha:Float = boyfriend.alpha;
							boyfriend.alpha = 0.00001;
							boyfriend = boyfriendMap.get(value2);
							boyfriend.alpha = lastAlpha;
							iconP1.changeIcon(boyfriend.healthIcon);
						}

					case 1:
						if (dad.curCharacter != value2)
						{
							if (!dadMap.exists(value2))
							{
								addCharacterToList(value2, charType);
							}

							var wasGf:Bool = dad.curCharacter.startsWith('gf');
							var lastAlpha:Float = dad.alpha;
							dad.alpha = 0.00001;
							dad = dadMap.get(value2);
							if (!dad.curCharacter.startsWith('gf'))
							{
								if (wasGf && gf != null)
								{
									gf.visible = true;
								}
							}
							else if (gf != null)
							{
								gf.visible = false;
							}
							dad.alpha = lastAlpha;
							iconP2.changeIcon(dad.healthIcon);
						}

					case 2:
						if (gf != null)
						{
							if (gf.curCharacter != value2)
							{
								if (!gfMap.exists(value2))
								{
									addCharacterToList(value2, charType);
								}

								var lastAlpha:Float = gf.alpha;
								gf.alpha = 0.00001;
								gf = gfMap.get(value2);
								gf.alpha = lastAlpha;
							}
						}
				}
				reloadHealthBarColors();

			case 'Change Scroll Speed':
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if (Math.isNaN(val1))
					val1 = 1;
				if (Math.isNaN(val2))
					val2 = 0;

				var newValue:Float = SONG.speed * val1;

				if (val2 <= 0)
				{
					songSpeed = newValue;
				}
				else
				{
					songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, val2 / playbackRate, {
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween)
						{
							songSpeedTween = null;
						}
					});
				}

			case 'Camera Flash':
				{
					var length:Float = Std.parseFloat(value1);
					var color:FlxColor = FlxColor.fromString(value2);

					camGame.flash(color, length);
				}

			case 'Set Default Camera Zoom':
				defaultCamZoom = Std.parseFloat(value1);

				camZooming = true;

			case 'Tween HUD Alpha':
				FlxTween.tween(camHUD, {alpha: Std.parseFloat(value1)}, Std.parseFloat(value2));

			case 'Tween Camera Zoom':
				var val1:Null<Float> = Std.parseFloat(value1);
				var split:Array<String> = value2.split(',');
				var val2:Null<Float> = Std.parseFloat(split[0]);

				if (Math.isNaN(val1))
					val1 = defaultCamZoom; // use stage zoom for resetting lol

				camZooming = false; // turn off camZooming

				if (val1 != null && val2 != null) {
					zoomTween = FlxTween.tween(camGame, {zoom: val1}, val2 / playbackRate, {
						ease: CoolUtil.easeFromString(split[1]),
						onComplete: function(tween:FlxTween)
						{
							defaultCamZoom = val1;
							camZooming = true;
						}
					});
				}

			case 'Swag On':
				var swagAmount:Float = Std.parseFloat(value1);
				var camZoom:Float = Std.parseFloat(value2);
				if (Math.isNaN(swagAmount))
					swagAmount = 0.1;
				if (Math.isNaN(camZoom))
					camZoom = 0.025; // i could make it like cam zoom or whatever but i hate that fuckass event dude its so awful and i want this all in one lol
				if(ClientPrefs.shaders && curStage == 'alley')
					coolors.saturation = swagAmount;

			wiggleShit.waveAmplitude = 0.035; // exact sacorg settings lol
			wiggleShit.waveFrequency = 10;

			FlxG.camera.zoom += camZoom;

			case 'Tween GAME Alpha':
				if (gameCamTween != null)
					gameCamTween.cancel();

				gameCamTween = FlxTween.tween(FlxG.camera, {alpha: Std.parseFloat(value1)}, Std.parseFloat(value2));

			
				case 'Toggle Trail':
					switch (value1)
					{
						case 'dad' | 'Dad' | 'DAD':
							if (dadTrail != null)
							{
								remove(dadTrail);
								dadTrail = null;
							}
							else
							{
								dadTrail = new FlxTrail(dad, null, 7, 5, Std.parseFloat(value2), 0.15);
								add(dadTrail);
							}
						case 'bf' | 'Bf' | 'BF':
							if (bfTrail != null)
							{
								remove(bfTrail);
								bfTrail = null;
							}
							else
							{
								bfTrail = new FlxTrail(boyfriend, null, 7, 5, Std.parseFloat(value2), 0.15);
								add(bfTrail);
							}
					}
			

			case 'Move Window':
				switch (value1)
				{
					case 'random':
						Lib.application.window.x = FlxG.random.int(0, Std.int(Capabilities.screenResolutionX - Lib.application.window.width));
						Lib.application.window.y = FlxG.random.int(0, Std.int(Capabilities.screenResolutionY - Lib.application.window.height));

					case 'set':
						switch (value2)
						{
							case '':
								Lib.application.window.x = Std.int(Capabilities.screenResolutionX / 2 - Lib.application.window.width / 2);
								Lib.application.window.y = Std.int(Capabilities.screenResolutionY / 2 - Lib.application.window.height / 2);
							default:
								var theShit:Array<String> = value2.split(',');
								Lib.application.window.x = Std.int(Std.parseFloat(theShit[0]));
								Lib.application.window.y = Std.int(Std.parseFloat(theShit[1]));
						}
				}

			case 'Change Cam Move Values':
				if (value1 != "")
				{
					value1 = value1.trim();
					var coords = value1.split(",");

					camCoords = [
						[Std.parseFloat(coords[0]), 0],
						[0, Std.parseFloat(coords[1])],
						[0, -Std.parseFloat(coords[2])],
						[-Std.parseFloat(coords[3]), 0]
					];
				}

				if (value2 != "")
				{
					value2 = value2.trim();
					var coords = value2.split(",");

					camAngles = [
						-Std.parseFloat(coords[0]),
						Std.parseFloat(coords[1]),
						-Std.parseFloat(coords[2]),
						Std.parseFloat(coords[3])
					];
				}

			case 'Change Beat Zoom Values':
				beatZoom = value1 == null ? 0 : Std.parseFloat(value1);
				beatAngle = value2 == null ? 0 : Std.parseFloat(value2);

			case 'Set Shaders':
				var shaders:Array<BitmapFilter> = [];

				value1 = value1.trim();
				var ShaderArray:Array<String> = value1.split(',');

				for (shdr in ShaderArray)
				{
					switch (shdr.toLowerCase().trim())
					{
						// hardcode your own shaders here
					}
				}

				FlxG.camera.setFilters(shaders);

			case 'Change Ratio':
				// REDOING THIS SOON
				var ratio:String = "16:9";

				switch (value1)
				{
					case 'default':
						ratio = '16:9';
					case 'genesis':
						ratio = '4:3';
					default:
				}

				FlxG.fullscreen = false; // idc why i did this but it works

				switch (ratio)
				{
					case '4:3':
						if (Capabilities.screenResolutionX >= 1280 && Capabilities.screenResolutionY >= 960)
						{
							// resetStrumPositions(-1);
							Lib.application.window.resizable = false;
							for (cam in FlxG.cameras.list)
							{
								cam.y = -120;
							}
							Lib.application.window.y -= 120;
							FlxG.resizeWindow(1280, 960);
						}
						else
						{
							ratio = '16:9';
						}
					case '16:9':
						// resetStrumPositions(-1);
						for (cam in FlxG.cameras.list)
						{
							cam.y = 0;
						}
						FlxG.resizeWindow(Std.int(Capabilities.screenResolutionX), Std.int(Capabilities.screenResolutionY));
					default:
						// FlxG.log.error('${ratio} is not a vasdlid aspect ratio');
						return;
				}

				var gameWidth:Int;
				var gameHeight:Int;

				if (ratio == '4:3')
				{
					gameWidth = Lib.application.window.width;
					gameHeight = Lib.application.window.height;
				}
				else
				{
					gameWidth = 1280;
					gameHeight = 720;
				}

				FlxG.resizeGame(gameWidth, gameHeight);
				@:privateAccess
				FlxG.width = gameWidth;
				@:privateAccess
				FlxG.height = gameHeight;

				FlxG.log.add("Switched ratio to " + ratio);

				for (cam in FlxG.cameras.list)
				{
					cam.width = FlxG.width;
					cam.height = FlxG.height;
					FlxG.log.add(Std.string(cam.width) + ", " + Std.string(cam.height));
				}

				camAngle = 0;
				cameraMoveDAD = [0, 0];
				cameraMoveBF = [0, 0];

				Lib.application.window.x = Std.int(Capabilities.screenResolutionX / 2 - Lib.application.window.width / 2);
				Lib.application.window.y = Std.int(Capabilities.screenResolutionY / 2 - Lib.application.window.height / 2);
		}

		scripts.executeAllFunc("event", [eventName, value1, value2, value3]);
	}

	function moveCameraSection():Void
	{
		if (SONG.notes[curSection] == null)
			return;

		if (gf != null && SONG.notes[curSection].gfSection)
		{
			camFollow.set(gf.getMidpoint().x, gf.getMidpoint().y);
			camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
			camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];
			tweenCamIn();
			return;
		}

		if (!SONG.notes[curSection].mustHitSection)
		{
			moveCamera(true);
		}
		else
		{
			moveCamera(false);
		}
	}

	var cameraTwn:FlxTween;

	private function cameraMove(data:Int, isBf:Bool)
	{
		camAngle = 0;

		if (isBf)
			cameraMoveBF = camCoords[data];
		else
			cameraMoveDAD = camCoordsDAD[data];

		/*
			if (cameraMoveShared)
			{
				cameraMoveBF = camCoords[data];
				cameraMoveDAD = camCoords[data];
			}
		 */

		camAngle = camAngles[data];

		moveCamera(!SONG.notes[curSection].mustHitSection);
	}

	public function moveCamera(isDad:Bool)
	{
		if (isDad)
		{
			camFollow.set(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			camFollow.x += dad.cameraPosition[0] - opponentCameraOffset[0] + cameraMoveDAD[0];
			camFollow.y += dad.cameraPosition[1] + opponentCameraOffset[1] + cameraMoveDAD[1];
			tweenCamIn();
		}
		else
		{
			camFollow.set(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
			camFollow.x -= boyfriend.cameraPosition[0] - boyfriendCameraOffset[0] + cameraMoveBF[0];
			camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1] + cameraMoveBF[1];

			if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1)
			{
				cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {
					ease: FlxEase.elasticInOut,
					onComplete: function(twn:FlxTween)
					{
						cameraTwn = null;
					}
				});
			}
		}
	}

	function tweenCamIn()
	{
		if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1.3)
		{
			cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {
				ease: FlxEase.elasticInOut,
				onComplete: function(twn:FlxTween)
				{
					cameraTwn = null;
				}
			});
		}
	}

	function snapCamFollowToPos(x:Float, y:Float)
	{
		camFollow.set(x, y);
		camFollowPos.setPosition(x, y);
	}

	public function finishSong(?ignoreNoteOffset:Bool = false):Void
	{
		var finishCallback:Void->Void = endSong; // In case you want to change it in a specific song.

		updateTime = false;
		FlxG.sound.music.volume = 0;
		opponentVocals.volume = 0;
		vocals.volume = 0;
		vocals.pause();
		opponentVocals.pause();
		if (ClientPrefs.noteOffset <= 0 || ignoreNoteOffset)
		{
			finishCallback();
		}
		else
		{
			finishTimer = new FlxTimer().start(ClientPrefs.noteOffset / 1000, function(tmr:FlxTimer)
			{
				finishCallback();
			});
		}
	}

	public var transitioning = false;

	public function endSong():Void
	{
		// Should kill you if you tried to cheat
		if (!startingSong)
		{
			notes.forEach(function(daNote:Note)
			{
				if (daNote.strumTime < songLength - Conductor.safeZoneOffset)
				{
					health -= 0.05;
				}
			});
			for (daNote in unspawnNotes)
			{
				if (daNote.strumTime < songLength - Conductor.safeZoneOffset)
				{
					health -= 0.05;
				}
			}

			if (doDeathCheck())
			{
				return;
			}
		}

		timeBar.visible = false;
		canPause = false;
		endingSong = true;
		camZooming = false;
		inCutscene = false;
		updateTime = false;

		deathCounter = 0;
		seenCutscene = false;

		if (ScriptUtil.hasPause(scripts.executeAllFunc("endSong")))
			return;

		if (SONG.validScore)
		{
			#if !switch
			var percent:Float = ratingPercent;
			if (Math.isNaN(percent))
				percent = 0;
			Highscore.saveScore(SONG.song, songScore, storyDifficulty, percent);
			#end
		}
		playbackRate = 1;

		if (chartingMode)
		{
			openChartEditor();
			return;
		}

		if (isStoryMode)
		{
			campaignScore += songScore;
			campaignMisses += songMisses;

			storyPlaylist.remove(storyPlaylist[0]);

			if (storyPlaylist.length <= 0)
			{
				FlxG.sound.playMusic(Paths.music('futuremenu'));

				cancelMusicFadeTween();

				if (!FlxG.save.data.firstCompletion) {
					MusicBeatState.switchState(new CreditsState());
					FlxG.save.data.firstCompletion = true;
				} else {
					MusicBeatState.switchState(new TitleState());
				}

				StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);

				if (SONG.validScore)
				{
					Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);
				}

				FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
				FlxG.save.flush();

				changedDifficulty = false;
			}
			else
			{
				var difficulty:String = CoolUtil.getDifficultyFilePath();

				trace('LOADING NEXT SONG');
				trace(Paths.formatToSongPath(PlayState.storyPlaylist[0]));

				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;

				prevCamFollow = camFollow;
				prevCamFollowPos = camFollowPos;

				PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0], PlayState.storyPlaylist[0]);
				FlxG.sound.music.stop();

				cancelMusicFadeTween();
				LoadingState.loadAndSwitchState(new PlayState());
			}
		}
		else
		{
			cancelMusicFadeTween();
			MusicBeatState.switchState(new FreeplayState());
			FlxG.sound.playMusic(Paths.music('futuremenu'));
			changedDifficulty = false;
		}
		transitioning = true;
	}

	public function KillNotes()
	{
		while (notes.length > 0)
		{
			var daNote:Note = notes.members[0];
			daNote.active = false;
			daNote.visible = false;

			daNote.kill();
			notes.remove(daNote, true);
			daNote.destroy();
		}
		unspawnNotes = [];
		eventNotes = [];
	}

	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;

	public var showCombo:Bool = false;
	public var showComboNum:Bool = true;
	public var showRating:Bool = true;

	private function cachePopUpScore()
	{
		var pixelShitPart1:String = '';
		var pixelShitPart2:String = '';
		if (isPixelStage)
		{
			pixelShitPart1 = 'pixelUI/';
			pixelShitPart2 = '-pixel';
		}

		Paths.image(pixelShitPart1 + "sick" + pixelShitPart2);
		Paths.image(pixelShitPart1 + "good" + pixelShitPart2);
		Paths.image(pixelShitPart1 + "bad" + pixelShitPart2);
		Paths.image(pixelShitPart1 + "shit" + pixelShitPart2);
		Paths.image(pixelShitPart1 + "combo" + pixelShitPart2);
			
		for (i in 0...10) {
			Paths.image(pixelShitPart1 + 'num' + i + pixelShitPart2);
		}
	}

	private function popUpScore(note:Note = null):Void
		{
			var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.ratingOffset);
	
			vocals.volume = 1;
			opponentVocals.volume = 1;
			var placement:String = Std.string(combo);
	
			var rating:FlxSprite = new FlxSprite();
			var score:Int = 350;
	
			//tryna do MS based judgment due to popular demand
			var daRating:Rating = Conductor.judgeNote(note, noteDiff / playbackRate);
	
			totalNotesHit += daRating.ratingMod;
			note.ratingMod = daRating.ratingMod;
			if(!note.ratingDisabled) daRating.increase();
			note.rating = daRating.name;
			score = daRating.score;
	
			if(daRating.noteSplash && !note.noteSplashDisabled)
			{
				spawnNoteSplashOnNote(note);
			}
	
			if(!practiceMode && !cpuControlled) {
				songScore += score;
				if(!note.ratingDisabled)
				{
					songHits++;
					totalPlayed++;
					RecalculateRating(false);
				}
			}
	
			var pixelShitPart1:String = "";
			var pixelShitPart2:String = '';
	
			if (PlayState.isPixelStage)
			{
				pixelShitPart1 = 'pixelUI/';
				pixelShitPart2 = '-pixel';
			}
	
			rating.loadGraphic(Paths.image(pixelShitPart1 + daRating.image + pixelShitPart2));
			rating.screenCenter();
			rating.y += 30;
			rating.x -= 90;
			rating.acceleration.y = 550 * playbackRate * playbackRate;
			rating.velocity.y -= FlxG.random.int(140, 175) * playbackRate;
			rating.velocity.x -= FlxG.random.int(0, 10) * playbackRate;
			rating.visible = (!ClientPrefs.hideHud && showRating);
			rating.alpha = 0.85;
			rating.angle = FlxG.random.int(-10, 10);
	
			var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'combo' + pixelShitPart2));
			comboSpr.screenCenter();
			comboSpr.x = gf.x + 40;
            comboSpr.y = gf.y + 60;
			comboSpr.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
			comboSpr.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
			comboSpr.visible = (!ClientPrefs.hideHud && showCombo);
			comboSpr.velocity.x += FlxG.random.int(1, 10) * playbackRate;
	
			insert(members.indexOf(strumLineNotes), rating);
			
			if (!ClientPrefs.comboStacking)
			{
				if (lastRating != null) lastRating.kill();
				lastRating = rating;
			}
	
			if (!PlayState.isPixelStage)
			{
				rating.setGraphicSize(Std.int(rating.width * 0.7));
				rating.antialiasing = ClientPrefs.globalAntialiasing;
				comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
				comboSpr.antialiasing = ClientPrefs.globalAntialiasing;
			}
			else
			{
				rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.85));
				comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.85));
			}
	
			comboSpr.updateHitbox();
			rating.updateHitbox();

			var seperatedScore:Array<String> = (combo + "").split('');
	
			var daLoop:Int = 0;
			var xThing:Float = 0;
			if (showCombo)
			{
				insert(members.indexOf(strumLineNotes), comboSpr);
			}
			if (!ClientPrefs.comboStacking)
			{
				if (lastCombo != null) lastCombo.kill();
				lastCombo = comboSpr;
			}
			if (lastScore != null)
			{
				while (lastScore.length > 0)
				{
					lastScore[0].kill();
					lastScore.remove(lastScore[0]);
				}
			}
			for (i in seperatedScore)
			{
				var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'num' + i + pixelShitPart2));
				numScore.screenCenter();
				numScore.y += 100;
				numScore.alpha = 0.85;
                numScore.x += (43 * daLoop) - 90;
				
				if (!ClientPrefs.comboStacking)
					lastScore.push(numScore);
	
				if (!PlayState.isPixelStage)
				{
					numScore.antialiasing = ClientPrefs.globalAntialiasing;
					numScore.setGraphicSize(Std.int(numScore.width * 0.5));
				}
				else
				{
					numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
				}
				numScore.updateHitbox();
	
				numScore.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
				numScore.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
				numScore.velocity.x = FlxG.random.float(-5, 5) * playbackRate;
				numScore.visible = !ClientPrefs.hideHud;
				numScore.angle = FlxG.random.int(-5, 5);
	
				if(showComboNum)
					insert(members.indexOf(strumLineNotes), numScore);
	
				FlxTween.tween(numScore, {"scale.x": 0, "scale.y": 0, alpha: 0}, 0.2 / playbackRate, {ease: FlxEase.quadInOut,
					onComplete: function(tween:FlxTween)
					{
						numScore.destroy();
						remove(numScore, true);
						numScore.kill();
					},
					startDelay: Conductor.crochet * 0.002 / playbackRate
				});
	
				daLoop++;
				if(numScore.x > xThing) xThing = numScore.x;
			}
			comboSpr.x = xThing + 50;
	
			FlxTween.tween(rating, {"scale.x": 0, "scale.y": 0, alpha: 0, angle: 0}, 0.2 / playbackRate, {ease: FlxEase.quadInOut,
				startDelay: Conductor.crochet * 0.002 / playbackRate
			});
	
			FlxTween.tween(comboSpr, {"scale.x": 0, "scale.y": 0, alpha: 0}, 0.2 / playbackRate, {ease: FlxEase.quadInOut,
				onComplete: function(tween:FlxTween)
				{
					remove(comboSpr, true);
					comboSpr.destroy();
	
					remove(rating, true);
					rating.destroy();
				},
				startDelay: Conductor.crochet * 0.002 / playbackRate
			});
		}

	public var strumsBlocked:Array<Bool> = [];

	private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		// trace('Pressed: ' + eventKey);

		if (!cpuControlled
			&& startedCountdown
			&& !paused
			&& key > -1
			&& (FlxG.keys.checkStatus(eventKey, JUST_PRESSED) || ClientPrefs.controllerMode))
		{
			if (!boyfriend.stunned && generatedMusic && !endingSong)
			{
				// more accurate hit time for the ratings?
				var lastTime:Float = Conductor.songPosition;
				Conductor.songPosition = FlxG.sound.music.time;

				var canMiss:Bool = !ClientPrefs.ghostTapping;

				// heavily based on my own code LOL if it aint broke dont fix it
				var pressNotes:Array<Note> = [];
				// var notesDatas:Array<Int> = [];
				var notesStopped:Bool = false;

				var sortedNotesList:Array<Note> = [];
				notes.forEachAlive(function(daNote:Note)
				{
					if (strumsBlocked[daNote.noteData] != true
						&& daNote.canBeHit
						&& daNote.mustPress
						&& !daNote.tooLate
						&& !daNote.wasGoodHit
						&& !daNote.isSustainNote
						&& !daNote.blockHit)
					{
						if (daNote.noteData == key)
						{
							sortedNotesList.push(daNote);
							// notesDatas.push(daNote.noteData);
						}
						canMiss = true;
					}
				});
				sortedNotesList.sort(sortHitNotes);

				if (sortedNotesList.length > 0)
				{
					for (epicNote in sortedNotesList)
					{
						for (doubleNote in pressNotes)
						{
							if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 1)
							{
								doubleNote.kill();
								notes.remove(doubleNote, true);
								doubleNote.destroy();
							}
							else
								notesStopped = true;
						}

						// eee jack detection before was not super good
						if (!notesStopped)
						{
							goodNoteHit(epicNote);
							pressNotes.push(epicNote);
						}
					}
				}
				else
				{
					scripts.executeAllFunc("ghostTap", [key]);
					if (canMiss)
					{
						noteMissPress(key);
					}
				}

				keysPressed[key] = true;

				Conductor.songPosition = lastTime;
			}

			var spr:StrumNote = playerStrums.members[key];
			if (strumsBlocked[key] != true && spr != null && spr.animation.curAnim.name != 'confirm')
			{
				spr.playAnim('pressed');
				spr.resetAnim = 0;
			}
		}
		// trace('pressed: ' + controlArray);
	}

	function sortHitNotes(a:Note, b:Note):Int
	{
		if (a.lowPriority && !b.lowPriority)
			return 1;
		else if (!a.lowPriority && b.lowPriority)
			return -1;

		return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime);
	}

	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		if (!cpuControlled && startedCountdown && !paused && key > -1)
		{
			var spr:StrumNote = playerStrums.members[key];
			if (spr != null)
			{
				spr.playAnim('static');
				spr.resetAnim = 0;
			}
		}
	}

	private function getKeyFromEvent(key:FlxKey):Int
	{
		if (key != NONE)
		{
			for (i in 0...keysArray.length)
			{
				for (j in 0...keysArray[i].length)
				{
					if (key == keysArray[i][j])
					{
						return i;
					}
				}
			}
		}
		return -1;
	}

	// Hold notes
	private function keyShit():Void
	{
		// HOLDING
		var parsedHoldArray:Array<Bool> = parseKeys();

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if (ClientPrefs.controllerMode)
		{
			var parsedArray:Array<Bool> = parseKeys('_P');
			if (parsedArray.contains(true))
			{
				for (i in 0...parsedArray.length)
				{
					if (parsedArray[i] && strumsBlocked[i] != true)
						onKeyPress(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, -1, keysArray[i][0]));
				}
			}
		}

		// FlxG.watch.addQuick('asdfa', upP);
		if (startedCountdown && !boyfriend.stunned && generatedMusic)
		{
			// rewritten inputs???
			notes.forEachAlive(function(daNote:Note)
			{
				// hold note functions
				if (strumsBlocked[daNote.noteData] != true
					&& daNote.isSustainNote
					&& parsedHoldArray[daNote.noteData]
					&& daNote.canBeHit
					&& daNote.mustPress
					&& !daNote.tooLate
					&& !daNote.wasGoodHit
					&& !daNote.blockHit)
				{
					goodNoteHit(daNote);
				}
			});

			if (boyfriend.animation.curAnim != null
				&& boyfriend.holdTimer > Conductor.stepCrochet * (0.0011 / FlxG.sound.music.pitch) * boyfriend.singDuration
					&& boyfriend.animation.curAnim.name.startsWith('sing')
					&& !boyfriend.animation.curAnim.name.endsWith('miss'))
			{
				boyfriend.dance();
				// boyfriend.animation.curAnim.finish();
			}
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if (ClientPrefs.controllerMode || strumsBlocked.contains(true))
		{
			var parsedArray:Array<Bool> = parseKeys('_R');
			if (parsedArray.contains(true))
			{
				for (i in 0...parsedArray.length)
				{
					if (parsedArray[i] || strumsBlocked[i] == true)
						onKeyRelease(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, -1, keysArray[i][0]));
				}
			}
		}
	}

	private function parseKeys(?suffix:String = ''):Array<Bool>
	{
		var ret:Array<Bool> = [];
		for (i in 0...controlArray.length)
		{
			ret[i] = Reflect.getProperty(controls, controlArray[i] + suffix);
		}
		return ret;
	}

	function noteMiss(daNote:Note):Void
	{ // You didn't hit the key and let it go offscreen, also used by Hurt Notes
		// Dupe note remove
		notes.forEachAlive(function(note:Note)
		{
			if (daNote != note
				&& daNote.mustPress
				&& daNote.noteData == note.noteData
				&& daNote.isSustainNote == note.isSustainNote
				&& Math.abs(daNote.strumTime - note.strumTime) < 1)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		});

		if (combo > 5 && gf != null && gf.animOffsets.exists('cry')) // holy shit we UNLOCKED FUNKY KONG
		{
			gf.playAnim('cry');
			gf.specialAnim = true;
		}

		songMisses++;
		combo = 0;
		health -= daNote.missHealth;

		vocals.volume = 0;
		if (!practiceMode)
			songScore -= 10;

		totalPlayed++;
		RecalculateRating(true);

		var char:Character = boyfriend;
		if (daNote.gfNote)
		{
			char = gf;
		}

		if (char != null && !daNote.noMissAnimation && char.hasMissAnimations)
		{
			var animToPlay:String = singAnimations[Std.int(Math.abs(daNote.noteData))] + 'miss' + daNote.animSuffix;
			char.playAnim(animToPlay, true);
		}

		scripts.executeAllFunc("missNote", [daNote]);
	}

	function noteMissPress(direction:Int = 1):Void // You pressed a key when there was no notes to press for this key
	{
		if (ClientPrefs.ghostTapping)
			return; // fuck it

		if (!boyfriend.stunned)
		{
			health -= 0.05;

			if (combo > 5 && gf != null && gf.animOffsets.exists('cry')) // holy shit we UNLOCKED FUNKY KONG
			{
				gf.playAnim('cry', true); // please work holy shit
				gf.specialAnim = true;
			}
			combo = 0;

			if (!practiceMode)
				songScore -= 10;
			if (!endingSong)
			{
				songMisses++;
			}
			totalPlayed++;
			RecalculateRating(true);

			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
			// FlxG.sound.play(Paths.sound('missnote1'), 1, false);
			// FlxG.log.add('played imss note');

			/*boyfriend.stunned = true;

				// get stunned for 1/60 of a second, makes you able to
				new FlxTimer().start(1 / 60, function(tmr:FlxTimer)
				{
					boyfriend.stunned = false;
			});*/

			if (boyfriend.hasMissAnimations)
			{
				boyfriend.playAnim(singAnimations[Std.int(Math.abs(direction))] + 'miss', true);
			}
			vocals.volume = 0;
		}
	}

	function opponentNoteHit(note:Note):Void
	{

		if (note.noteType == 'Hey!' && dad.animOffsets.exists('hey'))
		{
			dad.playAnim('hey', true);
			dad.specialAnim = true;
			dad.heyTimer = 0.6;
		}
		else if (!note.noAnimation)
		{
			var altAnim:String = note.animSuffix;

			if (SONG.notes[curSection] != null)
			{
				if (SONG.notes[curSection].altAnim && !SONG.notes[curSection].gfSection)
				{
					altAnim = '-alt';
				}
			}

			var char:Character = dad;
			var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))] + altAnim;
			if (note.gfNote)
			{
				char = gf;
			}

			if (char != null)
			{
				cameraMove(note.noteData, false);
				char.playAnim(animToPlay, true);
				char.holdTimer = 0;
			}
		}

		if (SONG.needsVoices) {
			vocals.volume = 1;
			opponentVocals.volume = 1;
		}

		var time:Float = 0.15;
		if (note.isSustainNote && !note.animation.curAnim.name.endsWith('end'))
		{
			time += 0.15;
		}
		StrumPlayAnim(true, Std.int(Math.abs(note.noteData)), time);
		note.hitByOpponent = true;

		scripts.executeAllFunc("oppHitNote", [note]);

		if (!note.isSustainNote)
		{
			note.kill();
			notes.remove(note, true);
			note.destroy();
		}
	}

	var heyParticles:FlxSprite;

	function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			if (cpuControlled && (note.ignoreNote || note.hitCausesMiss))
				return;

			if (ClientPrefs.hitsoundVolume > 0 && !note.hitsoundDisabled)
			{
				FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.hitsoundVolume);
			}

			if (note.hitCausesMiss)
			{
				noteMiss(note);
				if (!note.noteSplashDisabled && !note.isSustainNote)
				{
					spawnNoteSplashOnNote(note);
				}

				if (!note.noMissAnimation)
				{
					switch (note.noteType)
					{
						case 'Hurt Note': // Hurt note
							if (boyfriend.animOffsets.exists('hurt'))
							{
								boyfriend.playAnim('hurt', true);
								boyfriend.specialAnim = true;
							}
						case 'Hey!':
							if (note.noteType == 'Hey!' && boyfriend.animOffsets.exists('hey'))
							{
								boyfriend.playAnim('hey', true);
								boyfriend.specialAnim = true;
								boyfriend.heyTimer = 0.6;
							}
						for (i in 0...8) {
						heyParticles.loadGraphic(Paths.image('particles/heyPart' + FlxG.random.int(1, 3)));
						heyParticles.screenCenter();
						heyParticles.y = boyfriend.y - 80;
						heyParticles.x = boyfriend.x + 20;
						heyParticles.acceleration.y = 550 * playbackRate * playbackRate;
						heyParticles.velocity.y -= FlxG.random.int(140, 175) * playbackRate;
						heyParticles.velocity.x -= FlxG.random.int(0, 10) * playbackRate;
						heyParticles.alpha = 0.85;
						heyParticles.angle = FlxG.random.int(-50, 50);
						add(heyParticles); // add random particles to the screen
						}
					}
				}

				note.wasGoodHit = true;
				if (!note.isSustainNote)
				{
					note.kill();
					notes.remove(note, true);
					note.destroy();
				}
				return;
			}

			if (!note.isSustainNote)
			{
				combo += 1;
				if (combo > 9999)
					combo = 9999;
				popUpScore(note);
			}

			health += note.hitHealth;

			if (!note.noAnimation)
			{
				var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))];

				if (note.gfNote)
				{
					if (gf != null)
					{
						gf.playAnim(animToPlay + note.animSuffix, true);
						gf.holdTimer = 0;
					}
				}
				else
				{
					cameraMove(note.noteData, true);
					boyfriend.playAnim(animToPlay + note.animSuffix, true);
					boyfriend.holdTimer = 0;
				}
			}

			if (cpuControlled)
			{
				var time:Float = 0.15;
				if (note.isSustainNote && !note.animation.curAnim.name.endsWith('end'))
				{
					time += 0.15;
				}
				StrumPlayAnim(false, Std.int(Math.abs(note.noteData)), time);
			}
			else
			{
				var spr = playerStrums.members[note.noteData];
				if (spr != null)
				{
					spr.playAnim('confirm', true);
				}
			}
			note.wasGoodHit = true;
			vocals.volume = 1;
			opponentVocals.volume = 1;

			scripts.executeAllFunc("noteHit", [note]);

			if (!note.isSustainNote)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}
	}

	public function spawnNoteSplashOnNote(note:Note)
	{
		if (ClientPrefs.noteSplashes && note != null)
		{
			var strum:StrumNote = playerStrums.members[note.noteData];
			if (strum != null)
			{
				spawnNoteSplash(strum.x, strum.y, note.noteData, note);
			}
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null)
	{
		var skin:String = 'noteSplashes';
		if (PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0)
			skin = PlayState.SONG.splashSkin;

		var hue:Float = 0;
		var sat:Float = 0;
		var brt:Float = 0;
		if (data > -1 && data < ClientPrefs.arrowHSV.length)
		{
			hue = ClientPrefs.arrowHSV[data][0] / 360;
			sat = ClientPrefs.arrowHSV[data][1] / 100;
			brt = ClientPrefs.arrowHSV[data][2] / 100;
			if (note != null)
			{
				skin = note.noteSplashTexture;
				hue = note.noteSplashHue;
				sat = note.noteSplashSat;
				brt = note.noteSplashBrt;
			}
		}

		var splash:NoteSplash = NoteSplash.__pool.recycle(NoteSplash); // pool and recycle note splashes lol
		splash.revive();
		splash.setupNoteSplash(x, y, data, skin, hue, sat, brt);
		splash.animation.finishCallback = function(name)
		{
			grpNoteSplashes.remove(splash);
		}
		grpNoteSplashes.add(splash);
	}

	override function destroy()
	{
		if (!ClientPrefs.controllerMode)
		{
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}
		FlxAnimationController.globalSpeed = 1;
		FlxG.sound.music.pitch = 1;

		Character.onCreate = null;

		for (event in eventsPushed)
		{
			ChartingState.eventStuff.remove(event);
			eventsPushed.remove(event);
		}

		scripts.destroy();

		super.destroy();
	}

	public static function cancelMusicFadeTween()
	{
		if (FlxG.sound.music.fadeTween != null)
		{
			FlxG.sound.music.fadeTween.cancel();
		}
		FlxG.sound.music.fadeTween = null;
	}
	
	function removeTextManual()
		{
			new FlxTimer().start(1.8 * playbackRate, function(tmr:FlxTimer) {
				FlxTween.tween(songTxt, {alpha: 0}, 0.5, {ease: FlxEase.circOut});
				FlxTween.tween(credTxt, {alpha: 0}, 0.5, {
					ease: FlxEase.circOut,
					onComplete: function(twn:FlxTween)
					{
						remove(songTxt);
						remove(credTxt);
						credTxt.destroy();
						songTxt.destroy();
						songTxt.kill();
						credTxt.kill();
					}
				});
			});
		}

	var lastStepHit:Int = -1;

	override function stepHit()
	{
		super.stepHit();
		if (Math.abs(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate)
			|| (SONG.needsVoices && Math.abs(vocals.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate)))
		{
			resyncVocals();
		}

		if (curStep == 32)
		{
			FlxTween.tween(songTxt, {alpha: 0}, 0.5, {ease: FlxEase.circOut});
			FlxTween.tween(credTxt, {alpha: 0}, 0.5, {
				ease: FlxEase.circOut,
				onComplete: function(twn:FlxTween)
				{
					remove(songTxt);
					remove(credTxt);
					credTxt.destroy();
					songTxt.destroy();
					songTxt.kill();
					credTxt.kill();
				}
			});
		}

		if (curStep == lastStepHit)
		{
			return;
		}

		// ! CODE AFTER HERE STUPID LUNAR

		// THANKS :)) - LUNAR

		scripts.setAll("curStep", curStep);
		scripts.executeAllFunc("stepHit", [curStep]);

		lastStepHit = curStep;
	}

	var lastBeatHit:Int = -1;

	override function beatHit()
	{
		super.beatHit();

		if (lastBeatHit >= curBeat)
		{
			return;
		}

		if (beatZoom != 0)
			FlxG.camera.zoom += beatZoom;

		if (beatAngle != 0)
			FlxG.camera.angle += ((curBeat - curSection * 4) % 2) == 0 ? -beatAngle : beatAngle;

		if (generatedMusic)
		{
			notes.sort(FlxSort.byY, ClientPrefs.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
		}

		iconP1.scale.set(1, 1);
		iconP2.scale.set(1, 1);

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		if (curStage == 'alley' && curBeat % 4 == 0 && ClientPrefs.shaders)
			coolors.saturation = 0.1;

		if(curBeat % 2 == 0){
			wiggleShit.waveAmplitude = 0.035; // exact sacorg settings lol
			wiggleShit.waveFrequency = 10;
		}

		if (gf != null
			&& curBeat % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0
			&& gf.animation.curAnim != null
			&& !gf.getAnimationName().startsWith('sing')
			&& !gf.stunned)
		{
			gf.dance();
		}
		if (curBeat % boyfriend.danceEveryNumBeats == 0
			&& boyfriend.animation.curAnim != null
			&& !boyfriend.getAnimationName().startsWith('sing')
			&& !boyfriend.stunned)
		{
			boyfriend.dance();
		}
		if (curBeat % dad.danceEveryNumBeats == 0
			&& dad.animation.curAnim != null
			&& !dad.getAnimationName().startsWith('sing')
			&& !dad.stunned)
		{
			dad.dance();
		}

		scripts.setAll("curBeat", curBeat);
		scripts.executeAllFunc("beatHit", [beatHit]);

		lastBeatHit = curBeat;
	}

	override function sectionHit()
	{
		super.sectionHit();

		if (SONG.notes[curSection] != null)
		{
			if (generatedMusic && !endingSong && !isCameraOnForcedPos)
			{
				moveCameraSection();
			}

			if (camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms)
			{
				FlxG.camera.zoom += 0.015 * camZoomingMult;
				camHUD.zoom += 0.03 * camZoomingMult;
				camNOTEHUD.zoom += 0.03 * camZoomingMult;
				camNOTES.zoom += 0.03 * camZoomingMult;
			}

			if (SONG.notes[curSection].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[curSection].bpm);
				scripts.setAll("bpm", Conductor.bpm);
			}
		}
	}

	function StrumPlayAnim(isDad:Bool, id:Int, time:Float)
	{
		var spr:StrumNote = null;
		if (isDad)
		{
			spr = strumLineNotes.members[id];
		}
		else
		{
			spr = playerStrums.members[id];
		}

		if (spr != null)
		{
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}

	public var ratingName:String = '?';
	public var ratingPercent:Float;
	public var ratingFC:String;

	public function RecalculateRating(badHit:Bool = false)
	{
		if (!ScriptUtil.hasPause(scripts.executeAllFunc("recalcRating")))
		{
			if (totalPlayed < 1) // Prevent divide by 0
				ratingName = '?';
			else
			{
				// Rating Percent
				ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
				// trace((totalNotesHit / totalPlayed) + ', Total: ' + totalPlayed + ', notes hit: ' + totalNotesHit);

				// Rating Name
				if (ratingPercent >= 1)
				{
					ratingName = ratingStuff[ratingStuff.length - 1][0]; // Uses last string
				}
				else
				{
					for (i in 0...ratingStuff.length - 1)
					{
						if (ratingPercent < ratingStuff[i][1])
						{
							ratingName = ratingStuff[i][0];
							break;
						}
					}
				}
			}

			// Rating FC
			ratingFC = "";
			if (sicks > 0)
				ratingFC = "SFC";
			if (goods > 0)
				ratingFC = "GFC";
			if (bads > 0 || shits > 0)
				ratingFC = "FC";
			if (songMisses > 0 && songMisses < 10)
				ratingFC = "SDCB";
			else if (songMisses >= 10)
				ratingFC = "Clear";
		}
		updateScore(badHit); // score will only update after rating is calculated, if it's a badHit, it shouldn't bounce -Ghost
	}

	function initScripts()
	{
		if (scripts == null)
			return;

		var scriptData:Map<String, String> = [];

		// SONG && GLOBAL SCRIPTS
		var files:Array<String> = SONG.song == null ? [] : ScriptUtil.findScriptsInDir(Paths.getPreloadPath("data/" + Paths.formatToSongPath(SONG.song)));

		if (FileSystem.exists("assets/scripts/global"))
		{
			for (_ in ScriptUtil.findScriptsInDir("assets/scripts/global"))
				files.push(_);
		}

		for (file in files)
		{
			var hx:Null<String> = null;

			if (FileSystem.exists(file))
				hx = File.getContent(file);

			if (hx != null)
			{
				var scriptName:String = CoolUtil.getFileStringFromPath(file);

				if (!scriptData.exists(scriptName))
				{
					scriptData.set(scriptName, hx);
				}
			}
		}

		// STAGE SCRIPTS
		if (SONG.stage != null)
		{
			var hx:Null<String> = null;

			for (extn in ScriptUtil.extns)
			{
				var path:String = Paths.getPreloadPath('stages/' + SONG.stage + '.$extn');

				if (FileSystem.exists(path))
				{
					hx = File.getContent(path);
					break;
				}
			}

			if (hx != null)
			{
				if (!scriptData.exists("stage"))
					scriptData.set("stage", hx);
			}
		}

		for (scriptName => hx in scriptData)
		{
			if (scripts.getScriptByTag(scriptName) == null)
				scripts.addScript(scriptName).executeString(hx);
			else
			{
				scripts.getScriptByTag(scriptName).error("Duplacite Script Error!", '$scriptName: Duplicate Script');
			}
		}
	}

	private var eventsPushed:Array<Dynamic> = [];

	public function initSongEvents()
	{
		if (!FileSystem.exists("assets/scripts/events"))
			return;

		var jsonFiles:Array<String> = CoolUtil.findFilesInPath("assets/scripts/events", ["json"], true, false);

		var hxFiles:Map<String, String> = [];

		if (FileSystem.exists('assets/scripts/events/${Paths.formatToSongPath(SONG.song)}'))
		{
			for (file in CoolUtil.findFilesInPath('assets/scripts/events/${Paths.formatToSongPath(SONG.song)}', ["json"], true, true))
				jsonFiles.push(file);
		}

		for (file in jsonFiles)
		{
			var json:{val1:String, val2:String} = {val1: null, val2: null};
			if (FileSystem.exists(file))
			{
				try
				{
					json = cast Json.parse(File.getContent(file));
				}
				catch (e)
				{
					trace(e);
				}
			}

			var eventName:String = CoolUtil.getFileStringFromPath(file);

			eventsPushed.push([eventName, '${json.val1}\n${json.val2}']);
			ChartingState.eventStuff.push([eventName, '${json.val1}\n${json.val2}']);

			for (extn in ScriptUtil.extns)
			{
				var path:String = file.replace(".json", '.$extn');
				if (FileSystem.exists(path))
				{
					hxFiles.set(CoolUtil.getFileStringFromPath(path), File.getContent(path));
					break;
				}
			}
		}

		for (scriptName => hxData in hxFiles)
		{
			if (scripts.getScriptByTag(scriptName) == null)
				scripts.addScript(scriptName).executeString(hxData);
			else
			{
				scripts.getScriptByTag(scriptName).error("Duplacite Script Error!", '$scriptName: Duplicate Script');
			}
		}
	}

	function initEventScript(name:String) {}

	function initCharScript(char:Character)
	{
		if (char == null || scripts == null)
			return;

		var name:String = char.curCharacter;
		var hx:Null<String> = null;

		for (extn in ScriptUtil.extns)
		{
			var path = Paths.getPreloadPath('characters/' + name + '.$extn');

			if (FileSystem.exists(path))
			{
				hx = File.getContent(path);
				break;
			}
		}

		if (hx != null)
		{
			if (scripts.getScriptByTag(name) == null)
				scripts.addScript(name).executeString(hx);
			else
			{
				scripts.getScriptByTag(name).error("Duplacite Script Error!", '$name: Duplicate Script');
			}
		}
	}

	function onAddScript(script:Script)
	{
		script.set("PlayState", PlayState);
		script.set("game", PlayState.instance);

		// FUNCTIONS

		//  CREATION FUNCTIONS
		script.set("create", function() {});
		script.set("createStage", function(?stage:String) {}); // ! HAS PAUSE
		script.set("createPost", function() {});

		//  COUNTDOWN
		script.set("countdown", function() {});
		script.set("countTick", function(?tick:Int) {});

		//  SONG FUNCTIONS
		script.set("startSong", function() {}); // ! HAS PAUSE
		script.set("endSong", function() {}); // ! HAS PAUSE
		script.set("beatHit", function(?beat:Int) {});
		script.set("stepHit", function(?step:Int) {});

		//  NOTE FUNCTIONS
		script.set("spawnNote", function(?note:Note) {}); // ! HAS PAUSE
		script.set("hitNote", function(?note:Note) {});
		script.set("oppHitNote", function(?note:Note) {});
		script.set("missNote", function(?note:Note) {});

		script.set("notesUpdate", function() {}); // ! HAS PAUSE

		script.set("ghostTap", function(?direction:Int) {});

		//  EVENT FUNCTIONS
		script.set("event", function(?event:String, ?val1:Dynamic, ?val2:Dynamic) {}); // ! HAS PAUSE
		script.set("earlyEvent", function(event:String) {});

		//  PAUSING / RESUMING
		script.set("pause", function() {}); // ! HAS PAUSE
		script.set("resume", function() {}); // ! HAS PAUSE

		//  GAMEOVER
		script.set("gameOver", function() {}); // ! HAS PAUSE

		//  MISC
		script.set("updatePost", function(?elapsed:Float) {});
		script.set("recalcRating", function(?badHit:Bool = false) {}); // ! HAS PAUSE
		script.set("updateScore", function(?miss:Bool = false) {}); // ! HAS PAUSE

		// VARIABLES

		script.set("curStep", 0);
		script.set("curBeat", 0);
		script.set("bpm", 0);

		// OBJECTS
		script.set("camGame", camGame);
		script.set("camHUD", camHUD);
		script.set("camOther", camOther);

		script.set("camFollow", camFollow);
		script.set("camFollowPos", camFollowPos);

		// CHARACTERS
		script.set("boyfriend", boyfriend);
		script.set("dad", dad);
		script.set("gf", gf);

		script.set("boyfriendGroup", boyfriendGroup);
		script.set("dadGroup", dadGroup);
		script.set("gfGroup", gfGroup);

		// NOTES
		script.set("notes", notes);
		script.set("strumLineNotes", strumLineNotes);
		script.set("playerStrums", playerStrums);
		script.set("opponentStrums", opponentStrums);

		script.set("unspawnNotes", unspawnNotes);

		// MISC
		script.set("add", function(obj:FlxBasic, ?front:Bool = false)
		{
			if (front)
			{
				getInstance().add(obj);
			}
			else
			{
				if (PlayState.instance.isDead)
				{
					GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.instance.boyfriend), obj);
				}
				else
				{
					var position:Int = PlayState.instance.members.indexOf(PlayState.instance.gfGroup);
					if (PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup) < position)
					{
						position = PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup);
					}
					else if (PlayState.instance.members.indexOf(PlayState.instance.dadGroup) < position)
					{
						position = PlayState.instance.members.indexOf(PlayState.instance.dadGroup);
					}
					PlayState.instance.insert(position, obj);
				}
			}
		});
	}

	public static inline function getInstance()
	{
		return PlayState.instance.isDead ? GameOverSubstate.instance : PlayState.instance;
	}
}
