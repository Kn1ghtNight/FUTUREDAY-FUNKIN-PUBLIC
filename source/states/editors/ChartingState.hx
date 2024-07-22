package states.editors;

import flixel.util.FlxStringUtil;
import flixel.addons.text.ui.FlxUITextInput;
#if desktop
import util.Discord.DiscordClient;
#end
import flixel.text.FlxText.FlxTextBorderStyle;
import flash.geom.Rectangle;
import haxe.Json;
import haxe.format.JsonParser;
import haxe.io.Bytes;
import song.*;
import flixel.FlxG;
import util.CoolUtil;
import objects.*;
import song.Section.SwagSection;
import data.StageData;
import data.ClientPrefs;
import util.Prompt;
import song.Song.SwagSong;
import data.Paths;
import song.Conductor.BPMChangeEvent;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.text.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUISlider;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUITooltip.FlxUITooltipStyle;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.sound.FlxSound;
import objects.FlxFixedText;
import states.game.PlayState;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxButton;
import flixel.ui.FlxSpriteButton;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import lime.media.AudioBuffer;
import lime.utils.Assets;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.media.Sound;
import openfl.net.FileReference;
import openfl.utils.Assets as OpenFlAssets;
import openfl.utils.ByteArray;

using StringTools;
#if sys
import flash.media.Sound;
import sys.FileSystem;
import sys.io.File;
#end


@:access(flixel.system.FlxSound._sound)
@:access(openfl.media.Sound.__buffer)

class ChartingState extends MusicBeatState
{
	public static var noteTypeList:Array<String> = //Used for backwards compatibility with 0.1 - 0.3.2 charts, though, you should add your hardcoded custom note types here too.
	[
		'',
		'Vibrato',
		'Alt Animation',
		'Hey!',
		'Hurt Note',
		'GF Sing',
		'No Animation'
	];
	private var displayNameList:Array<String> = [];
	private var noteTypeIntMap:Map<Int, String> = new Map<Int, String>();
	private var noteTypeMap:Map<String, Null<Int>> = new Map<String, Null<Int>>();
	public var ignoreWarnings = false;
	var undos = [];
	var redos = [];
	public static var eventStuff:Array<Dynamic> =
	[
		['', "Nothing. Yep, that's right."],
		['Dadbattle Spotlight', "Used in Dad Battle,\nValue 1: 0/1 = ON/OFF,\n2 = Target Dad\n3 = Target BF"],
		['Hey!', "Plays the \"Hey!\" animation from Bopeebo,\nValue 1: BF = Only Boyfriend, GF = Only Girlfriend,\nSomething else = Both.\nValue 2: Custom animation duration,\nleave it blank for 0.6s"],
		['Set GF Speed', "Sets GF head bopping speed,\nValue 1: 1 = Normal speed,\n2 = 1/2 speed, 4 = 1/4 speed etc.\nUsed on Fresh during the beatbox parts.\n\nWarning: Value must be integer!"],
		['Add Camera Zoom', "Used on MILF on that one \"hard\" part\nValue 1: Camera zoom add (Default: 0.015)\nValue 2: UI zoom add (Default: 0.03)\nLeave the values blank if you want to use Default."],
		['Play Animation', "Plays an animation on a Character,\nonce the animation is completed,\nthe animation changes to Idle\n\nValue 1: Animation to play.\nValue 2: Character (Dad, BF, GF)"],
		['Camera Follow Pos', "Value 1: X\nValue 2: Y\n\nThe camera won't change the follow point\nafter using this, for getting it back\nto normal, leave both values blank."],
		['Alt Idle Animation', "Sets a specified suffix after the idle animation name.\nYou can use this to trigger 'idle-alt' if you set\nValue 2 to -alt\n\nValue 1: Character to set (Dad, BF or GF)\nValue 2: New suffix (Leave it blank to disable)"],
		['Screen Shake', "Value 1: Camera shake\nValue 2: HUD shake\n\nEvery value works as the following example: \"1, 0.05\".\nThe first number (1) is the duration.\nThe second number (0.05) is the intensity."],
		['Change Character', "Value 1: Character to change (Dad, BF, GF)\nValue 2: New character's name"],
		['Change Scroll Speed', "Value 1: Scroll Speed Multiplier (1 is default)\nValue 2: Time it takes to change fully in seconds."],
		['Set Property', "Value 1: Variable name\nValue 2: New value"],
		[
			'Camera Flash',
			'Cus yknow u need it\nValue1:Length\nValue2: Color in hex code (default white)'
		],
		[
			'Set Default Camera Zoom',
			'Cus yea\nValue1:camGame\nValue2: Literally nothing wtf are you doing'
		],
		['Tween HUD Alpha', 'Cus ok\nValue1: Alpha\nValue2: Time'],
		['Tween GAME Alpha', 'Cus sure\nValue1: Alpha\nValue2: Time'],
		['Toggle Trail', 'Cus whatever\nValue1: Character, \nValue2: Alpha'],
		[
			'Move Window',
			'Cus its awesome\nValue1: random or set, \nValue2: if set then  coords (x,y format), default to center if set to none'
		],
		[
			'Change Cam Move Values',
			'Cus its okay\nValue1: Cam Move Coords (Left, Down, Up, Right) \nValue2: Cam Angle Coords (Left, Down, Up, Right)'
		],
		['Change Beat Zoom Values', 'Cus idfk\nValue1: Zoom Value'],
		['Set Shaders', 'mhm'],
		['Swag On', 'Resets the saturation value for the ColorSwap shader.\n It also makes sustains (if enabled), "bump"'],
		['Tween Camera Zoom', 'Tweens the camGame zoom value. \nValue 1 is what controls the zoom amount. \nValue 2 controls the duration, \nValue 3 controls the easing.']
	];

	var _file:FileReference;

	var UI_box:FlxUITabMenu;
	var SEC_box:FlxUITabMenu;

	public static var goToPlayState:Bool = false;
	/**
	 * Array of notes showing when each section STARTS in STEPS
	 * Usually rounded up??
	 */
	public static var curSec:Int = 0;
	public static var secAmt:Int = 0;
	public static var lastSection:Int = 0;
	private static var lastSong:String = '';
	private var canReturn:Bool = false;

	var helpTxt:FlxTypedGroup<FlxFixedText>;
	var keybindBG:FlxSprite;

	var bpmTxt:FlxFixedText;
	var secTxt:FlxFixedText;
	var beatTxt:FlxFixedText;
	var stepTxt:FlxFixedText;
	var zoomTxt:FlxFixedText;
	var quantTxt:FlxFixedText;

	var camPos:FlxObject;
	var strumLine:FlxSprite;
	var quant:AttachedSprite;
	var strumLineNotes:FlxTypedGroup<StrumNote>;
	var curSong:String = 'Test';
	var curDifficulty:String = "Normal";
	var amountSteps:Int = 0;
	var bullshitUI:FlxGroup;

	var highlight:FlxSprite;

	public static var GRID_SIZE:Int = 40;
	public static var LANE_OFF:Int = 0;
	var CAM_OFFSET:Int = 360;

	var dummyArrow:FlxSprite;

	var curRenderedSustains:FlxTypedGroup<Note>;
	var curRenderedNotes:FlxTypedGroup<Note>;
	var curRenderedNoteType:FlxTypedGroup<FlxFixedText>;

	var prevRenderedSustains:FlxTypedGroup<Note>;
	var prevRenderedNotes:FlxTypedGroup<Note>;

	var nextRenderedSustains:FlxTypedGroup<Note>;
	var nextRenderedNotes:FlxTypedGroup<Note>;

	var eventGrid:FlxSprite;
	var prevEventGrid:FlxSprite;
	var nextEventGrid:FlxSprite;

	var leftGrid:FlxSprite;
	var prevLeftGrid:FlxSprite;
	var nextLeftGrid:FlxSprite;

	var rightGrid:FlxSprite;
	var prevRightGrid:FlxSprite;
	var nextRightGrid:FlxSprite;

	var daquantspot = 0;
	var curEventSelected:Int = 0;
	var curUndoIndex = 0;
	var curRedoIndex = 0;
	var _song:SwagSong;
	/*
	 * WILL BE THE CURRENT / LAST PLACED NOTE
	**/
	var curSelectedNote:Array<Dynamic> = null;
	var recentNote:Array<Dynamic>;

	var tempBpm:Float = 0;
	var playbackSpeed:Float = 1;

	var pvocals:FlxSound = null;
	var ovocals:FlxSound = null;

	var leftIcon:HealthIcon;
	var rightIcon:HealthIcon;

	var value1InputText:FlxUITextInput;
	var value2InputText:FlxUITextInput;
	var sectionInputText:FlxUITextInput;
	var multiInputText:FlxUITextInput;
	var currentSongName:String;

	var copyMultiSec:Bool = false;

	var zoomList:Array<Float> = [
		0.25,
		0.5,
		1,
		2,
		3,
		4,
		6,
		8,
		12,
		16,
		24
	];
	var curZoom:Int = 2;

	private var blockPressWhileTypingOn:Array<FlxUITextInput> = [];
	private var blockPressWhileTypingOnStepper:Array<FlxUINumericStepper> = [];
	private var blockPressWhileScrolling:Array<FlxUIDropDownMenuCustom> = [];

	var waveformSprite:FlxSprite;
	var gridLayer:FlxTypedGroup<FlxSprite>;

	public static var quantization:Int = 16;
	public static var curQuant = 3;

	public var quantizations:Array<Int> = [
		4,
		8,
		12,
		16,
		20,
		24,
		32,
		48,
		64,
		96,
		192
	];



	var text:String = "";
	public static var vortex:Bool = false;
	public var mouseQuant:Bool = false;

	var bgcolour:FlxSprite;
	var bg:FlxSprite;
	var intendedColor:Int;
	var colorTween:FlxTween;

	override function create()
	{
		LANE_OFF = Std.int((FlxG.width / 2) - (GRID_SIZE * 5));
		if (PlayState.SONG != null) {
			_song = PlayState.SONG;
			curDifficulty = CoolUtil.difficulties[PlayState.storyDifficulty];
		} else {
			CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();

			_song = {
				song: 'Kasey',
				notes: [],
				events: [],
				bpm: 150.0,
				needsVoices: true,
				arrowSkin: '',
				splashSkin: 'noteSplashes',//idk it would crash if i didn't
				player1: 'bf',
				player2: 'dad',
				gfVersion: 'gf',
				speed: 1,
				stage: 'alley',
				validScore: false
			};
			addSection();
			PlayState.SONG = _song;
		}

		// Paths.clearMemory();

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Chart Editor", StringTools.replace(_song.song, '-', ' '));
		#end

		vortex = FlxG.save.data.chart_vortex;
		ignoreWarnings = FlxG.save.data.ignoreWarnings;

		bgcolour = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width), Std.int(FlxG.height), FlxColor.WHITE);
		bgcolour.updateHitbox();
		bgcolour.screenCenter();
		bgcolour.scrollFactor.set();
		bgcolour.antialiasing = ClientPrefs.globalAntialiasing;
		add(bgcolour);

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.setGraphicSize(Std.int(bg.width * 1.25));
		bg.updateHitbox();
		bg.screenCenter();
		bg.scrollFactor.set();
		bg.color = 0xFF171717;
		bg.alpha = 0.67;
		add(bg);

		gridLayer = new FlxTypedGroup<FlxSprite>();
		add(gridLayer);

		waveformSprite = new FlxSprite(LANE_OFF + (GRID_SIZE * 1.5), 0).makeGraphic(FlxG.width, FlxG.height, 0x00FFFFFF); // im jorking my  weenor <:)
		add(waveformSprite);

		var eventIcon:FlxSprite = new FlxSprite(LANE_OFF - (GRID_SIZE * 2.5), 10).loadGraphic(Paths.image('eventArrow'));
		eventIcon.alpha = 0.5;
		leftIcon = new HealthIcon('bf');
		rightIcon = new HealthIcon('dad', true);
		eventIcon.scrollFactor.set();
		leftIcon.scrollFactor.set();
		rightIcon.scrollFactor.set();

		eventIcon.setGraphicSize(0, 45);
		leftIcon.setGraphicSize(0, 45);
		rightIcon.setGraphicSize(0, 45);

		add(eventIcon);
		add(leftIcon);
		add(rightIcon);

		bgcolour.color = FlxColor.fromInt(CoolUtil.dominantColor(leftIcon));
		intendedColor = CoolUtil.dominantColor(leftIcon);

		leftIcon.setPosition(506, 0);
		rightIcon.setPosition(689, 0);


		curRenderedSustains = new FlxTypedGroup<Note>();
		curRenderedNotes = new FlxTypedGroup<Note>();
		curRenderedNoteType = new FlxTypedGroup<FlxFixedText>();

		prevRenderedSustains = new FlxTypedGroup<Note>();
		prevRenderedNotes = new FlxTypedGroup<Note>();

		nextRenderedSustains = new FlxTypedGroup<Note>();
		nextRenderedNotes = new FlxTypedGroup<Note>();

		secAmt = generateSections();
		if(curSec > secAmt) curSec = secAmt;

		FlxG.mouse.visible = true;
		//FlxG.save.bind('funkin' #if (flixel < "5.0.0"), 'ninjamuffin99' #end);

		tempBpm = _song.bpm;

		addSection();

		// sections = _song.notes;

		currentSongName = Paths.formatToSongPath(_song.song);
		loadSong();
		reloadGridLayer();
		Conductor.changeBPM(_song.bpm);
		Conductor.mapBPMChanges(_song);

		bpmTxt = new FlxFixedText(1000, 10, 0, "", 20);
		bpmTxt.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, RIGHT);
		bpmTxt.scrollFactor.set();
		add(bpmTxt);
		secTxt = new FlxFixedText(1000, bpmTxt.y + 25, 0, "", 20);
		secTxt.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, RIGHT);
		secTxt.scrollFactor.set();
		add(secTxt);
		beatTxt = new FlxFixedText(1000, secTxt.y + 25, 0, "", 20);
		beatTxt.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, RIGHT);
		beatTxt.scrollFactor.set();
		add(beatTxt);
		stepTxt = new FlxFixedText(1000, beatTxt.y + 25, 0, "", 20);
		stepTxt.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, RIGHT);
		stepTxt.scrollFactor.set();
		add(stepTxt);

		strumLine = new FlxSprite(LANE_OFF - 10, 50).makeGraphic(Std.int(GRID_SIZE * 10) + 20, 4);
		add(strumLine);

		quant = new AttachedSprite('chart_quant','chart_quant');
		quant.animation.addByPrefix('q','chart_quant',0,false);
		quant.animation.play('q', true, false, 0);
		quant.sprTracker = strumLine;
		quant.xAdd = -32;
		quant.yAdd = 8;
		add(quant);

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		for (i in 0...8){
			var weirdX:Int = LANE_OFF + (GRID_SIZE * (i+1) + 20);
			var note:StrumNote = new StrumNote(i < 4 ? weirdX : weirdX + 20, strumLine.y, i % 4, 0);
			note.setGraphicSize(GRID_SIZE, GRID_SIZE);
			note.updateHitbox();
			note.playAnim('static', true);
			strumLineNotes.add(note);
			note.scrollFactor.set(1, 1);
		}
		add(strumLineNotes);

		camPos = new FlxObject(0, 0, 1, 1);
		camPos.setPosition(Std.int(FlxG.width / 2), strumLine.y);

		dummyArrow = new FlxSprite().makeGraphic(GRID_SIZE, GRID_SIZE);
		add(dummyArrow);

		var tabs = [
			{name: "Song", label: 'Song'},
			{name: "Note", label: 'Note'},
			{name: "Events", label: 'Events'},
			{name: "Charting", label: 'Charting'}
		];

		UI_box = new FlxUITabMenu(null, tabs, true);
		UI_box.resize(300, 400);
		UI_box.x = 40 + GRID_SIZE / 2;
		UI_box.y = 135;
		UI_box.scrollFactor.set();

		SEC_box = new FlxUITabMenu(null, [{name: "Section", label: 'Section'}], true);
		SEC_box.resize(350, 400);
		SEC_box.x = Std.int(FlxG.width * 0.6) + 100 + GRID_SIZE / 2;
		SEC_box.y = 150;
		SEC_box.scrollFactor.set();

		add(UI_box);
		add(SEC_box);

		text =
		"Left/Right Click - Add or remove a note, drag to make sustains
		\nW/S or Mouse Wheel - Change Conductor's strum time
		\nA/D - Go to the previous/next section
		\nLeft/Right - Change Snap
		\nUp/Down - Change Conductor's Strum Time with Snapping
		\nLeft/Right Bracket - Change Song Playback Rate (SHIFT to go Faster)
		\nALT + Left/Right Bracket - Reset Song Playback Rate
		\nHold Shift to move 4x faster
		\nHold Control and click on an arrow to select it
		\nZ/X - Zoom in/out
		\nF - Toggle Must Hit Section
		\nG - Toggle Duet Section
		\nO/P - Toggle Opponent/Player Section Copying
		\n
		\nCTRL + Z - Undo Last Action
		\nCTRL + C - Copy Current Section
		\nCTRL + V - Paste Copied Section
		\n
		\nEsc - Play your chart (SHIFT to play at the beginning section)
		\nQ/E - Decrease/Increase Note Sustain Length
		\nSpace - Stop/Resume song";

		keybindBG = new FlxSprite().makeGraphic(Std.int(FlxG.width / 2), FlxG.height, 0x99000000);
		keybindBG.x -= 500;
		keybindBG.alpha = 0;
		keybindBG.scrollFactor.set();

		helpTxt = new FlxTypedGroup<FlxFixedText>();
		var tipTextArray:Array<String> = text.split('\n');
		for (i in 0...tipTextArray.length) {
			var tipText:FlxFixedText = new FlxFixedText(20, 50, 0, tipTextArray[i], 16);
			tipText.y += i * 12;
			tipText.x -= 500;
			tipText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			tipText.borderSize = 2;
			tipText.scrollFactor.set();
			tipText.alpha = 0;
			tipText.ID = i;
			helpTxt.add(tipText);
		}

		var helpButton:FlxButton = new FlxButton(FlxG.width - 20, FlxG.height - 20, "Keybinds", function(){showKeybinds();});
		helpButton.x -= helpButton.width;
		helpButton.y -= helpButton.height;
		add(helpButton);

		addSongUI();
		addSectionUI();
		addNoteUI();
		addEventsUI();
		addChartingUI();
		updateHeads();
		updateWaveform();
		//UI_box.selected_tab = 4;

		add(curRenderedSustains);
		add(curRenderedNotes);
		add(curRenderedNoteType);
		add(prevRenderedSustains);
		add(prevRenderedNotes);
		add(nextRenderedSustains);
		add(nextRenderedNotes);

		if(lastSong != currentSongName) {
			changeSection();
		}
		lastSong = currentSongName;

		quantTxt = new FlxFixedText(10, FlxG.height - 2, 0, "Beat Snap: " + quantization + "th", 20);
		quantTxt.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, LEFT);
		quantTxt.updateHitbox();
		quantTxt.y -= quantTxt.height + 10;
		quantTxt.scrollFactor.set();
		add(quantTxt);

		zoomTxt = new FlxFixedText(10, FlxG.height - 5, 0, "Zoom: 1 / 1", 20);
		zoomTxt.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, LEFT);
		zoomTxt.updateHitbox();
		zoomTxt.y = quantTxt.y - 30;
		zoomTxt.scrollFactor.set();
		add(zoomTxt);

		updateGrid();
		add(keybindBG); // render keybinds screen on top lol
		add(helpTxt); // render keybind text correctly
		super.create();
	}

	var keybindsShown:Bool = false;
	var keybindBGtween:FlxTween = null;
	var keybindTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	function showKeybinds() {
		if (!keybindsShown) {
			keybindBGtween = FlxTween.tween(keybindBG, {x: 0, alpha: 1}, 1, {ease: FlxEase.cubeOut, onComplete:
				function (twn:FlxTween) {
					keybindBGtween = null;
				}
			});
			for (help in helpTxt) {
				var cool = help.ID;
				keybindTweens.set('keybind $cool', FlxTween.tween(help, {alpha: 1, x: 20}, 1, {ease: FlxEase.cubeOut}));
			}
		} else {
			keybindBGtween = FlxTween.tween(keybindBG, {x: -500, alpha: 0}, 1, {ease: FlxEase.cubeOut, onComplete:
				function (twn:FlxTween) {
					keybindBGtween = null;
				}
			});
			for (help in helpTxt.members) {
				var cool = help.ID;
				keybindTweens.set('keybind $cool', FlxTween.tween(help, {alpha: 0, x: -520}, 1, {ease: FlxEase.cubeOut}));
			}
		}
		keybindsShown = !keybindsShown;
	}
	
	var check_mute_inst:FlxUICheckBox = null;
	var check_mute_ovocals:FlxUICheckBox = null;
	var check_mute_pvocals:FlxUICheckBox = null;
	var check_vortex:FlxUICheckBox = null;
	var check_warnings:FlxUICheckBox = null;
	var playSoundBf:FlxUICheckBox = null;
	var playSoundDad:FlxUICheckBox = null;
	var UI_songTitle:FlxUITextInput;
	var noteSkinInputText:FlxUITextInput;
	var noteSplashesInputText:FlxUITextInput;
	var stageDropDown:FlxUIDropDownMenuCustom;
	var sliderRate:FlxUISlider;
	var sliderTime:FlxUISlider;
	function addSongUI():Void
	{
		UI_songTitle = new FlxUITextInput(10, 10, 70, _song.song, 8);
		blockPressWhileTypingOn.push(UI_songTitle);

		var check_voices = new FlxUICheckBox(10, 25, null, null, "Has voice track", 100);
		check_voices.checked = _song.needsVoices;
		// _song.needsVoices = check_voices.checked;
		check_voices.callback = function()
		{
			_song.needsVoices = check_voices.checked;
			//trace('CHECKED!');
		};

		var saveButton:FlxButton = new FlxButton(110, 8, "Save", function()
		{
			saveLevel();
		});

		var reloadSong:FlxButton = new FlxButton(saveButton.x + 90, saveButton.y, "Reload Audio", function()
		{
			currentSongName = Paths.formatToSongPath(UI_songTitle.text);
			loadSong();
			updateWaveform();
		});

		var reloadSongJson:FlxButton = new FlxButton(reloadSong.x, saveButton.y + 30, "Reload JSON", function()
		{
			openSubState(new Prompt('This action will clear current progress.\n\nProceed?', 0, function(){loadJson(_song.song.toLowerCase()); }, null,ignoreWarnings));
		});

		var loadAutosaveBtn:FlxButton = new FlxButton(reloadSongJson.x, reloadSongJson.y + 30, 'Load Autosave', function()
		{
			PlayState.SONG = Song.parseJSONshit(FlxG.save.data.autosave);
			MusicBeatState.resetState();
		});

		var loadEventJson:FlxButton = new FlxButton(loadAutosaveBtn.x, loadAutosaveBtn.y + 30, 'Load Events', function()
		{

			var songName:String = Paths.formatToSongPath(_song.song);
			var file:String = Paths.json(songName + '/events');
			#if sys
			if (#if MODS_ALLOWED FileSystem.exists(Paths.modsJson(songName + '/events')) || #end FileSystem.exists(file))
			#else
			if (OpenFlAssets.exists(file))
			#end
			{
				clearEvents();
				var events:SwagSong = Song.loadFromJson('events', songName);
				_song.events = events.events;
				changeSection(curSec);
			}
		});

		var saveEvents:FlxButton = new FlxButton(110, reloadSongJson.y, 'Save Events', function ()
		{
			saveEvents();
		});

		var clear_events:FlxButton = new FlxButton(200, 310, 'Clear events', function()
			{
				openSubState(new Prompt('This action will clear current progress.\n\nProceed?', 0, clearEvents, null,ignoreWarnings));
			});
		clear_events.color = FlxColor.RED;
		clear_events.label.color = FlxColor.WHITE;

		var clear_notes:FlxButton = new FlxButton(200, clear_events.y + 30, 'Clear notes', function()
			{
				openSubState(new Prompt('This action will clear current progress.\n\nProceed?', 0, function(){for (sec in 0..._song.notes.length) {
					_song.notes[sec].sectionNotes = [];
				}
				updateGrid();
			}, null,ignoreWarnings));

			});
		clear_notes.color = FlxColor.RED;
		clear_notes.label.color = FlxColor.WHITE;

		var stepperBPM:FlxUINumericStepper = new FlxUINumericStepper(10, 80, 1, 1, 1, 400, 3);
		stepperBPM.value = Conductor.bpm;
		stepperBPM.name = 'song_bpm';
		blockPressWhileTypingOnStepper.push(stepperBPM);

		var stepperSpeed:FlxUINumericStepper = new FlxUINumericStepper(stepperBPM.x + 70, stepperBPM.y, 0.1, 1, 0.1, 10, 1);
		stepperSpeed.value = _song.speed;
		stepperSpeed.name = 'song_speed';
		blockPressWhileTypingOnStepper.push(stepperSpeed);
		#if MODS_ALLOWED
		var directories:Array<String> = [Paths.mods('characters/'), Paths.mods(Paths.currentModDirectory + '/characters/'), Paths.getPreloadPath('characters/')];
		for(mod in Paths.getGlobalMods())
			directories.push(Paths.mods(mod + '/characters/'));
		#else
		var directories:Array<String> = [Paths.getPreloadPath('characters/')];
		#end

		var tempMap:Map<String, Bool> = new Map<String, Bool>();
		var characters:Array<String> = CoolUtil.coolTextFile(Paths.txt('characterList'));
		for (i in 0...characters.length) {
			tempMap.set(characters[i], true);
		}
		
		var difficulties:Array<String> = CoolUtil.defaultDifficulties;
		if (CoolUtil.difficulties != null && CoolUtil.difficulties.length >= 1)
			difficulties = CoolUtil.difficulties;

		for (i in 0...directories.length)
			{
				var directory:String = directories[i];
				if (FileSystem.exists(directory))
				{
					for (file in FileSystem.readDirectory(directory))
					{
						var path = haxe.io.Path.join([directory, file]);
						if (!FileSystem.isDirectory(path) && file.endsWith('.json'))
						{
							var charToCheck:String = file.substr(0, file.length - 5);
							if (!charToCheck.endsWith('-dead') && !tempMap.exists(charToCheck))
							{
								tempMap.set(charToCheck, true);
								characters.push(charToCheck);
							}
						}
					}
				}
			}

		var player1DropDown = new FlxUIDropDownMenuCustom(10, stepperSpeed.y + 100, FlxUIDropDownMenuCustom.makeStrIdLabelArray(characters, true), function(character:String)
		{
			_song.player1 = characters[Std.parseInt(character)];
			updateHeads();
		});
		player1DropDown.selectedLabel = _song.player1;
		blockPressWhileScrolling.push(player1DropDown);

		var gfVersionDropDown = new FlxUIDropDownMenuCustom(player1DropDown.x + 140, player1DropDown.y + 40, FlxUIDropDownMenuCustom.makeStrIdLabelArray(characters, true), function(character:String)
		{
			_song.gfVersion = characters[Std.parseInt(character)];
			updateHeads();
		});
		gfVersionDropDown.selectedLabel = _song.gfVersion;
		blockPressWhileScrolling.push(gfVersionDropDown);

		var player2DropDown = new FlxUIDropDownMenuCustom(player1DropDown.x, gfVersionDropDown.y, FlxUIDropDownMenuCustom.makeStrIdLabelArray(characters, true), function(character:String)
		{
			_song.player2 = characters[Std.parseInt(character)];
			updateHeads();
		});
		player2DropDown.selectedLabel = _song.player2;
		blockPressWhileScrolling.push(player2DropDown);

		var directories:Array<String> = [Paths.getPreloadPath('stages/')];

		tempMap.clear();
		var stageFile:Array<String> = CoolUtil.coolTextFile(Paths.txt('stageList'));
		var stages:Array<String> = [];
		for (i in 0...stageFile.length)
		{ // Prevent duplicates
			var stageToCheck:String = stageFile[i];
			if (!tempMap.exists(stageToCheck))
			{
				stages.push(stageToCheck);
			}
			tempMap.set(stageToCheck, true);
		}

		for (i in 0...directories.length)
		{
			var directory:String = directories[i];
			if (FileSystem.exists(directory))
			{
				for (file in FileSystem.readDirectory(directory))
				{
					var path = haxe.io.Path.join([directory, file]);
					if (!FileSystem.isDirectory(path) && file.endsWith('.json'))
					{
						var stageToCheck:String = file.substr(0, file.length - 5);
						if (!tempMap.exists(stageToCheck))
						{
							tempMap.set(stageToCheck, true);
							stages.push(stageToCheck);
						}
					}
				}
			}
		}

		if(stages.length < 1) stages.push('stage');

		stageDropDown = new FlxUIDropDownMenuCustom(player1DropDown.x + 140, player1DropDown.y, FlxUIDropDownMenuCustom.makeStrIdLabelArray(stages, true), function(character:String)
		{
			_song.stage = stages[Std.parseInt(character)];
		});
		stageDropDown.selectedLabel = _song.stage;
		blockPressWhileScrolling.push(stageDropDown);

		var difficultyDropDown = new FlxUIDropDownMenuCustom(10, stepperSpeed.y + 35, FlxUIDropDownMenuCustom.makeStrIdLabelArray(difficulties, true), function(character:String)
		{
			curDifficulty = difficulties[Std.parseInt(character)];
			PlayState.storyDifficulty = Std.parseInt(character);
			loadSong();
			updateWaveform();
		});
		difficultyDropDown.selectedLabel = curDifficulty;
		blockPressWhileScrolling.push(difficultyDropDown);

		var skin = PlayState.SONG.arrowSkin;
		if(skin == null) skin = '';
		noteSkinInputText = new FlxUITextInput(player2DropDown.x, player2DropDown.y + 50, 150, skin, 8);
		blockPressWhileTypingOn.push(noteSkinInputText);

		noteSplashesInputText = new FlxUITextInput(noteSkinInputText.x, noteSkinInputText.y + 35, 150, _song.splashSkin, 8);
		blockPressWhileTypingOn.push(noteSplashesInputText);

		var reloadNotesButton:FlxButton = new FlxButton(noteSplashesInputText.x + 5, noteSplashesInputText.y + 20, 'Change Notes', function() {
			_song.arrowSkin = noteSkinInputText.text;
			updateGrid();
		});

		var tab_group_song = new FlxUI(null, UI_box);
		tab_group_song.name = "Song";
		tab_group_song.add(UI_songTitle);

		tab_group_song.add(check_voices);
		tab_group_song.add(clear_events);
		tab_group_song.add(clear_notes);
		tab_group_song.add(saveButton);
		tab_group_song.add(saveEvents);
		tab_group_song.add(reloadSong);
		tab_group_song.add(reloadSongJson);
		tab_group_song.add(loadAutosaveBtn);
		tab_group_song.add(loadEventJson);
		tab_group_song.add(stepperBPM);
		tab_group_song.add(stepperSpeed);
		tab_group_song.add(reloadNotesButton);
		tab_group_song.add(noteSkinInputText);
		tab_group_song.add(noteSplashesInputText);
		tab_group_song.add(new FlxFixedText(stepperBPM.x, stepperBPM.y - 15, 0, 'Song BPM:'));
		tab_group_song.add(new FlxFixedText(stepperSpeed.x, stepperSpeed.y - 15, 0, 'Song Speed:'));
		tab_group_song.add(new FlxFixedText(difficultyDropDown.x, difficultyDropDown.y - 15, 0, 'Difficulty:'));
		tab_group_song.add(new FlxFixedText(player2DropDown.x, player2DropDown.y - 15, 0, 'Opponent:'));
		tab_group_song.add(new FlxFixedText(gfVersionDropDown.x, gfVersionDropDown.y - 15, 0, 'Girlfriend:'));
		tab_group_song.add(new FlxFixedText(player1DropDown.x, player1DropDown.y - 15, 0, 'Boyfriend:'));
		tab_group_song.add(new FlxFixedText(stageDropDown.x, stageDropDown.y - 15, 0, 'Stage:'));
		tab_group_song.add(new FlxFixedText(noteSkinInputText.x, noteSkinInputText.y - 15, 0, 'Note Texture:'));
		tab_group_song.add(new FlxFixedText(noteSplashesInputText.x, noteSplashesInputText.y - 15, 0, 'Note Splashes Texture:'));
		tab_group_song.add(player2DropDown);
		tab_group_song.add(gfVersionDropDown);
		tab_group_song.add(player1DropDown);
		tab_group_song.add(stageDropDown);
		tab_group_song.add(difficultyDropDown);

		UI_box.addGroup(tab_group_song);

		FlxG.camera.follow(camPos);
	}

	var stepperBeats:FlxUINumericStepper;
	var check_mustHitSection:FlxUICheckBox;
	var check_gfSection:FlxUICheckBox;
	var check_duetSection:FlxUICheckBox;
	var check_changeBPM:FlxUICheckBox;
	var stepperSectionBPM:FlxUINumericStepper;
	var check_altAnim:FlxUICheckBox;

	var check_eventsSec:FlxUICheckBox;
	var check_plrSec:FlxUICheckBox;
	var check_oppSec:FlxUICheckBox;

	var check_copyMulti:FlxUICheckBox;
	var secButton:FlxButton;
	var returnSecButton:FlxButton;
	var cancelSecButton:FlxButton;
	var secToReturn:Int = 0;

	var sectionToCopy:Int = 0;
	var sectionToEnd:Int = 0;
	var notesCopied:Array<Dynamic>;
	var notesCopiedMulti:Array<Array<Dynamic>>;

	function addSectionUI():Void
	{
		var tab_group_section = new FlxUI(null, SEC_box);
		tab_group_section.name = 'Section';

		check_mustHitSection = new FlxUICheckBox(10, 15, null, null, "Must hit section", 100);
		check_mustHitSection.name = 'check_mustHit';
		check_mustHitSection.checked = _song.notes[curSec].mustHitSection;

		check_gfSection = new FlxUICheckBox(check_mustHitSection.x + 120, check_mustHitSection.y, null, null, "GF section", 100);
		check_gfSection.name = 'check_gf';
		check_gfSection.checked = _song.notes[curSec].gfSection;

		check_duetSection = new FlxUICheckBox(check_gfSection.x + 120, check_mustHitSection.y, null, null, "Duet section", 100);
		check_duetSection.name = 'check_duet';
		check_duetSection.checked = _song.notes[curSec].duetSection;
		// _song.needsVoices = check_mustHit.checked;

		check_altAnim = new FlxUICheckBox(check_gfSection.x, check_gfSection.y + 22, null, null, "Alt Animation", 100);
		check_altAnim.checked = _song.notes[curSec].altAnim;

		stepperBeats = new FlxUINumericStepper(10, check_mustHitSection.y + 42, 1, 4, 1, 6, 2);
		stepperBeats.value = getSectionBeats();
		stepperBeats.name = 'section_beats';
		blockPressWhileTypingOnStepper.push(stepperBeats);
		check_altAnim.name = 'check_altAnim';

		check_changeBPM = new FlxUICheckBox(check_duetSection.x, check_duetSection.y + 22, null, null, 'Change BPM', 100);
		check_changeBPM.checked = _song.notes[curSec].changeBPM;
		check_changeBPM.name = 'check_changeBPM';

		stepperSectionBPM = new FlxUINumericStepper(check_changeBPM.x, check_changeBPM.y + 20, 1, Conductor.bpm, 0, 999, 1);
		if(check_changeBPM.checked) {
			stepperSectionBPM.value = _song.notes[curSec].bpm;
		} else {
			stepperSectionBPM.value = Conductor.bpm;
		}
		stepperSectionBPM.name = 'section_bpm';
		blockPressWhileTypingOnStepper.push(stepperSectionBPM);

		sectionInputText = new FlxUITextInput(130, 113, 80, "");
		blockPressWhileTypingOn.push(sectionInputText);
		
		check_copyMulti = new FlxUICheckBox(130, 153, null, null, '  .', 1);
		check_copyMulti.checked = copyMultiSec;
		check_copyMulti.name = 'check_copyMulti';		

		multiInputText = new FlxUITextInput(150, 153, 60, "");
		multiInputText.alpha = copyMultiSec ? 1 : 0.25;
		blockPressWhileTypingOn.push(multiInputText);

		secButton = new FlxButton(10, 110, "Go", function()
		{
			if (sectionInputText.text != null && sectionInputText.text != "" && Std.parseInt(sectionInputText.text.trim()) != curSec) {
				secToReturn = curSec;
				canReturn = true;
				changeSection(Std.parseInt(sectionInputText.text.trim()));
			}
		});

		returnSecButton = new FlxButton(secButton.x + 25, secButton.y, 'Return', function()
		{
			if (secToReturn > -1 && secToReturn != curSec) {
				canReturn = false;
				changeSection(secToReturn);
			}
		});
		returnSecButton.color = FlxColor.PURPLE;
		returnSecButton.label.color = FlxColor.WHITE;
		returnSecButton.setGraphicSize(55, 20);
		returnSecButton.updateHitbox();
		setAllLabelsOffset(returnSecButton, -13, 2);

		cancelSecButton = new FlxButton(secButton.x, secButton.y, 'X', function(){canReturn = false;});
		cancelSecButton.color = FlxColor.RED;
		cancelSecButton.label.color = FlxColor.WHITE;
		cancelSecButton.setGraphicSize(20, 20);
		cancelSecButton.updateHitbox();
		setAllLabelsOffset(cancelSecButton, -30, 2);
		
		var copyButton:FlxButton = new FlxButton(10, secButton.y + 30, "Copy", function()
		{
			notesCopied = [];
			sectionToCopy = curSec;
			if (Std.parseInt(sectionInputText.text.trim()) != null && (Std.parseInt(sectionInputText.text.trim()) != curSec || copyMultiSec))
				sectionToCopy = Std.parseInt(sectionInputText.text.trim());

			if (Std.parseInt(multiInputText.text.trim()) != null && copyMultiSec)
				sectionToEnd = Std.parseInt(multiInputText.text.trim());
			
			var startThing:Float = sectionStartTime();
			var endThing:Float = sectionStartTime(1);
			if (Std.parseInt(sectionInputText.text.trim()) != null && Std.parseInt(sectionInputText.text.trim()) != curSec) {
				startThing = sectionStartTime(Std.parseInt(sectionInputText.text.trim()) - curSec);
				endThing = sectionStartTime(Std.parseInt(sectionInputText.text.trim()) - curSec + 1);
			}

			if (copyMultiSec && sectionToEnd > sectionToCopy) {		
				notesCopiedMulti = [];

				startThing = sectionStartTime(Std.parseInt(sectionInputText.text.trim()) - curSec);
				endThing = sectionStartTime(Std.parseInt(multiInputText.text.trim()) - curSec + 1);	
				for (i in sectionToCopy...sectionToEnd+1){
					var section:Array<Dynamic> = [];
					for (j in 0..._song.notes[i].sectionNotes.length)
					{
						var note:Array<Dynamic> = _song.notes[i].sectionNotes[j];
						section.push(note);
					}	
					
					for (event in _song.events)
					{
						var strumTime:Float = event[0];
						if(endThing > event[0] && event[0] >= startThing)
						{
							var copiedEventArray:Array<Dynamic> = [];
							for (i in 0...event[1].length)
							{
								var eventToPush:Array<Dynamic> = event[1][i];
								copiedEventArray.push([eventToPush[0], eventToPush[1], eventToPush[2]]);
							}
							section.push([strumTime, -1, copiedEventArray]);
						}
					}
					notesCopiedMulti.push(section);				
				}
			} else {
				for (i in 0..._song.notes[sectionToCopy].sectionNotes.length)
				{
					var note:Array<Dynamic> = _song.notes[sectionToCopy].sectionNotes[i];
					notesCopied.push(note);
				}
				
				for (event in _song.events)
				{
					var strumTime:Float = event[0];
					if(endThing > event[0] && event[0] >= startThing)
					{
						var copiedEventArray:Array<Dynamic> = [];
						for (i in 0...event[1].length)
						{
							var eventToPush:Array<Dynamic> = event[1][i];
							copiedEventArray.push([eventToPush[0], eventToPush[1], eventToPush[2]]);
						}
						notesCopied.push([strumTime, -1, copiedEventArray]);
					}
				}
			}
		});

		var pasteButton:FlxButton = new FlxButton(copyButton.x, copyButton.y + 30, "Paste", function()
		{
			if((!copyMultiSec && (notesCopied == null || notesCopied.length < 1)) || (copyMultiSec && (notesCopiedMulti == null || notesCopiedMulti.length < 1)))
			{
				return;
			}

			var addToTime:Float = Conductor.stepCrochet * (getSectionBeats() * 4 * (curSec - sectionToCopy));
			//trace('Time to add: ' + addToTime);
			if (copyMultiSec) {
				for (sect in 0...notesCopiedMulti.length) {
				for (note in notesCopiedMulti[sect])
				{
					var copiedNote:Array<Dynamic> = [];
					var newStrumTime:Float = note[0] + addToTime;
					if(note[1] < 0)
					{
						if(check_eventsSec.checked)
						{
							var copiedEventArray:Array<Dynamic> = [];
							for (i in 0...note[2].length)
							{
								var eventToPush:Array<Dynamic> = note[2][i];
								copiedEventArray.push([eventToPush[0], eventToPush[1], eventToPush[2]]);
							}
							_song.events.push([newStrumTime, copiedEventArray]);
						}
					}
					else
					{
						if((check_plrSec.checked && note[1] > 3) || (check_oppSec.checked && note[1] < 4))
						{
							if(note[4] != null) {
								copiedNote = [newStrumTime, note[1], note[2], note[3], note[4]];
							} else {
								copiedNote = [newStrumTime, note[1], note[2], note[3]];
							}
							_song.notes[curSec + sect].sectionNotes.push(copiedNote);
						}
					}
				}
				}
			} else {
				for (note in notesCopied) {
					var copiedNote:Array<Dynamic> = [];
					var newStrumTime:Float = note[0] + addToTime;
					if(note[1] < 0)
					{
						if(check_eventsSec.checked)
						{
							var copiedEventArray:Array<Dynamic> = [];
							for (i in 0...note[2].length)
							{
								var eventToPush:Array<Dynamic> = note[2][i];
								copiedEventArray.push([eventToPush[0], eventToPush[1], eventToPush[2]]);
							}
							_song.events.push([newStrumTime, copiedEventArray]);
						}
					}
					else
					{
						if((check_plrSec.checked && note[1] > 3) || (check_oppSec.checked && note[1] < 4))
						{
							if(note[4] != null) {
								copiedNote = [newStrumTime, note[1], note[2], note[3], note[4]];
							} else {
								copiedNote = [newStrumTime, note[1], note[2], note[3]];
							}
							_song.notes[curSec].sectionNotes.push(copiedNote);
						}
					}
				}
			}
			updateGrid();
		});

		var clearSectionButton:FlxButton = new FlxButton(pasteButton.x, pasteButton.y + 30, "Clear", function()
		{
			var theSec:Int = curSec;
			if (Std.parseInt(sectionInputText.text.trim()) != null && Std.parseInt(sectionInputText.text.trim()) != curSec) 
				theSec = Std.parseInt(sectionInputText.text.trim());
			for (i in 0..._song.notes[theSec].sectionNotes.length) {
			for (note in _song.notes[theSec].sectionNotes) {
				if ((check_plrSec.checked && note[1] <= 3) || (check_oppSec.checked && note[1] >= 4)) {
					_song.notes[theSec].sectionNotes.remove(note);
				}
			}
			}					

			if(check_eventsSec.checked)
			{
				var i:Int = _song.events.length - 1;
				var startThing:Float = sectionStartTime();
				var endThing:Float = sectionStartTime(1);
				if (Std.parseInt(sectionInputText.text.trim()) != null && Std.parseInt(sectionInputText.text.trim()) != curSec) {
					startThing = sectionStartTime(Std.parseInt(sectionInputText.text.trim()) - curSec);
					endThing = sectionStartTime(Std.parseInt(sectionInputText.text.trim()) - curSec + 1);
				}
				while(i > -1) {
					var event:Array<Dynamic> = _song.events[i];
					if(event != null && endThing > event[0] && event[0] >= startThing)
					{
						_song.events.remove(event);
					}
					--i;
				}
			}
			updateGrid();
			updateNoteUI();
		});
		clearSectionButton.color = FlxColor.RED;
		clearSectionButton.label.color = FlxColor.WHITE;
		
		check_oppSec = new FlxUICheckBox(clearSectionButton.x, clearSectionButton.y + 30, null, null, "Opponent Notes", 75);
		check_oppSec.checked = true;
		check_plrSec = new FlxUICheckBox(check_oppSec.x + 120, check_oppSec.y, null, null, "Player Notes", 75);
		check_plrSec.checked = true;
		check_eventsSec = new FlxUICheckBox(check_plrSec.x + 120, check_plrSec.y, null, null, "Events", 100);
		check_eventsSec.checked = true;

		var stepperCopy:FlxUINumericStepper = null;
		var copyLastButton:FlxButton = new FlxButton(clearSectionButton.x + 240, copyButton.y, "Copy last section", function()
		{
			var value:Int = Std.int(stepperCopy.value);
			if(value == 0) return;

			var daSec = FlxMath.maxInt(curSec, value);
			for (note in _song.notes[daSec - value].sectionNotes)
			{
				if ((check_plrSec.checked && note[1] > 3) || (check_oppSec.checked && note[1] < 4)){
					var strum = note[0] + Conductor.stepCrochet * (getSectionBeats(daSec) * 4 * value);

					var copiedNote:Array<Dynamic> = [strum, note[1], note[2], note[3]];
					_song.notes[daSec].sectionNotes.push(copiedNote);
				}
			}

			var startThing:Float = sectionStartTime(-value);
			var endThing:Float = sectionStartTime(-value + 1);
			if(check_eventsSec.checked)
			{
				for (event in _song.events)
				{
					var strumTime:Float = event[0];
					if(endThing > event[0] && event[0] >= startThing)
					{
						strumTime += Conductor.stepCrochet * (getSectionBeats(daSec) * 4 * value);
						var copiedEventArray:Array<Dynamic> = [];
						for (i in 0...event[1].length)
						{
							var eventToPush:Array<Dynamic> = event[1][i];
							copiedEventArray.push([eventToPush[0], eventToPush[1], eventToPush[2]]);
						}
						_song.events.push([strumTime, copiedEventArray]);
					}
				}
			}
			updateGrid();
		});
		copyLastButton.setGraphicSize(80, 30);
		copyLastButton.updateHitbox();
		
		stepperCopy = new FlxUINumericStepper(copyLastButton.x, copyLastButton.y + 40, 1, 1, -999, 999, 0);
		blockPressWhileTypingOnStepper.push(stepperCopy);

		var duetButton:FlxButton = new FlxButton(10, clearSectionButton.y + 130, "Duet Notes", function()
		{
			var duetNotes:Array<Array<Dynamic>> = [];
			for (note in _song.notes[curSec].sectionNotes)
			{
				var boob = note[1];
				if (boob>3){
					boob -= 4;
				}else{
					boob += 4;
				}

				var copiedNote:Array<Dynamic> = [note[0], boob, note[2], note[3]];
				duetNotes.push(copiedNote);
			}

			for (i in duetNotes){
			_song.notes[curSec].sectionNotes.push(i);

			}

			updateGrid();
		});
		var mirrorButton:FlxButton = new FlxButton(duetButton.x + 120, duetButton.y, "Mirror Notes", function()
		{
			var duetNotes:Array<Array<Dynamic>> = [];
			for (note in _song.notes[curSec].sectionNotes)
			{
				var boob = note[1]%4;
				boob = 3 - boob;
				if (note[1] > 3) boob += 4;

				note[1] = boob;
				var copiedNote:Array<Dynamic> = [note[0], boob, note[2], note[3]];
				//duetNotes.push(copiedNote);
			}

			for (i in duetNotes){
			//_song.notes[curSec].sectionNotes.push(i);

			}

			updateGrid();
		});

		
		var swapSection:FlxButton = new FlxButton(mirrorButton.x + 120, duetButton.y, "Swap section", function()
		{
			for (i in 0..._song.notes[curSec].sectionNotes.length)
			{
				var note:Array<Dynamic> = _song.notes[curSec].sectionNotes[i];
				note[1] = (note[1] + 4) % 8;
				_song.notes[curSec].sectionNotes[i] = note;
			}
			updateGrid();
		});
	

		tab_group_section.add(new FlxFixedText(stepperBeats.x, stepperBeats.y - 15, 0, 'Section Beats:'));
		tab_group_section.add(stepperBeats);
		tab_group_section.add(stepperSectionBPM);
		tab_group_section.add(check_mustHitSection);
		tab_group_section.add(check_gfSection);
		tab_group_section.add(check_duetSection);
		tab_group_section.add(check_altAnim);
		tab_group_section.add(check_changeBPM);
		tab_group_section.add(sectionInputText);
		tab_group_section.add(check_copyMulti);
		tab_group_section.add(multiInputText);
		tab_group_section.add(new FlxFixedText(check_copyMulti.x, multiInputText.y - 15, 0, 'Copy Multiple Sections'));
		tab_group_section.add(secButton);
		tab_group_section.add(returnSecButton);
		tab_group_section.add(cancelSecButton);
		tab_group_section.add(copyButton);
		tab_group_section.add(pasteButton);
		tab_group_section.add(clearSectionButton);
		tab_group_section.add(check_plrSec);
		tab_group_section.add(check_oppSec);
		tab_group_section.add(check_eventsSec);
		tab_group_section.add(swapSection);
		tab_group_section.add(stepperCopy);
		tab_group_section.add(copyLastButton);
		tab_group_section.add(duetButton);
		tab_group_section.add(mirrorButton);

		secButton.visible = true;
		returnSecButton.visible = false;
		cancelSecButton.visible = false;

		SEC_box.addGroup(tab_group_section);
	}

	var stepperSusLength:FlxUINumericStepper;
	var strumTimeInputText:FlxUITextInput; //I wanted to use a stepper but we can't scale these as far as i know :(
	var leftClickDropDown:FlxUIDropDownMenuCustom;
	var rightClickDropDown:FlxUIDropDownMenuCustom;
	var noteTypeDropDown:FlxUIDropDownMenuCustom;
	var leftClickType:Int = 0;
	var rightClickType:Int = 0;
	var currentType:Int = 0;

	function addNoteUI():Void
	{
		var tab_group_note = new FlxUI(null, UI_box);
		tab_group_note.name = 'Note';

		stepperSusLength = new FlxUINumericStepper(10, 25, Conductor.stepCrochet / 2, 0, 0, Conductor.stepCrochet * 64);
		stepperSusLength.value = 0;
		stepperSusLength.name = 'note_susLength';
		blockPressWhileTypingOnStepper.push(stepperSusLength);

		strumTimeInputText = new FlxUITextInput(stepperSusLength.x + 140, stepperSusLength.y, 120, "0");
		tab_group_note.add(strumTimeInputText);
		blockPressWhileTypingOn.push(strumTimeInputText);

		var key:Int = 0;
		displayNameList = [];
		while (key < noteTypeList.length) {
			displayNameList.push(noteTypeList[key]);
			noteTypeMap.set(noteTypeList[key], key);
			noteTypeIntMap.set(key, noteTypeList[key]);
			key++;
		}

		#if LUA_ALLOWED
		var directories:Array<String> = [];

		#if MODS_ALLOWED
		directories.push(Paths.mods('custom_notetypes/'));
		directories.push(Paths.mods(Paths.currentModDirectory + '/custom_notetypes/'));
		for(mod in Paths.getGlobalMods())
			directories.push(Paths.mods(mod + '/custom_notetypes/'));
		#end

		for (i in 0...directories.length) {
			var directory:String =  directories[i];
			if(FileSystem.exists(directory)) {
				for (file in FileSystem.readDirectory(directory)) {
					var path = haxe.io.Path.join([directory, file]);
					if (!FileSystem.isDirectory(path) && file.endsWith('.lua')) {
						var fileToCheck:String = file.substr(0, file.length - 4);
						if(!noteTypeMap.exists(fileToCheck)) {
							displayNameList.push(fileToCheck);
							noteTypeMap.set(fileToCheck, key);
							noteTypeIntMap.set(key, fileToCheck);
							key++;
						}
					}
				}
			}
		}
		#end

		for (i in 1...displayNameList.length) {
			displayNameList[i] = i + '. ' + displayNameList[i];
		}

		var key:Int = 0;
		var clickNameList:Array<String> = [];
		while (key < displayNameList.length) {
			clickNameList.push(displayNameList[key]);
			key++;
		}
		clickNameList.push(displayNameList.length + '. Last Selected Note');
		clickNameList.push((displayNameList.length + 1) + '. Nothing');

		leftClickType = clickNameList.length - 2;
		rightClickType = clickNameList.length - 1;

		leftClickDropDown = new FlxUIDropDownMenuCustom(10, 65, FlxUIDropDownMenuCustom.makeStrIdLabelArray(clickNameList, true), function(character:String)
		{
			leftClickType = Std.parseInt(character);
		});
		leftClickDropDown.selectedLabel = clickNameList[leftClickType];

		rightClickDropDown = new FlxUIDropDownMenuCustom(150, 65, FlxUIDropDownMenuCustom.makeStrIdLabelArray(clickNameList, true), function(character:String)
		{
			rightClickType = Std.parseInt(character);
		});
		rightClickDropDown.selectedLabel = clickNameList[rightClickType];
		
		noteTypeDropDown = new FlxUIDropDownMenuCustom(10, 105, FlxUIDropDownMenuCustom.makeStrIdLabelArray(displayNameList, true), function(character:String)
		{
			currentType = Std.parseInt(character);
			if(curSelectedNote != null && curSelectedNote[1] > -1) {
				curSelectedNote[3] = noteTypeIntMap.get(currentType);
				updateGrid();
			}
		});

		blockPressWhileScrolling.push(leftClickDropDown);
		blockPressWhileScrolling.push(rightClickDropDown);
		blockPressWhileScrolling.push(noteTypeDropDown);

		tab_group_note.add(new FlxFixedText(10, 10, 0, 'Sustain length:'));
		tab_group_note.add(new FlxFixedText(150, 10, 0, 'Strum time (in MS):'));
		tab_group_note.add(new FlxFixedText(10, 50, 0, "Left Click:"));
		tab_group_note.add(new FlxFixedText(150, 50, 0, "Right Click:"));
		tab_group_note.add(new FlxFixedText(10, 90, 0, "Selected Note's type:"));
		tab_group_note.add(stepperSusLength);
		tab_group_note.add(strumTimeInputText);
		tab_group_note.add(noteTypeDropDown);
		tab_group_note.add(leftClickDropDown);
		tab_group_note.add(rightClickDropDown);

		UI_box.addGroup(tab_group_note);
	}

	var eventDropDown:FlxUIDropDownMenuCustom;
	var descText:FlxFixedText;
	var selectedEventText:FlxFixedText;
	var copiedEvent:Array<Dynamic> = [];
	function addEventsUI():Void
	{
		var tab_group_event = new FlxUI(null, UI_box);
		tab_group_event.name = 'Events';

		#if LUA_ALLOWED
		var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();
		var directories:Array<String> = [];

		#if MODS_ALLOWED
		directories.push(Paths.mods('custom_events/'));
		directories.push(Paths.mods(Paths.currentModDirectory + '/custom_events/'));
		for(mod in Paths.getGlobalMods())
			directories.push(Paths.mods(mod + '/custom_events/'));
		#end

		for (i in 0...directories.length) {
			var directory:String =  directories[i];
			if(FileSystem.exists(directory)) {
				for (file in FileSystem.readDirectory(directory)) {
					var path = haxe.io.Path.join([directory, file]);
					if (!FileSystem.isDirectory(path) && file != 'readme.txt' && file.endsWith('.txt')) {
						var fileToCheck:String = file.substr(0, file.length - 4);
						if(!eventPushedMap.exists(fileToCheck)) {
							eventPushedMap.set(fileToCheck, true);
							eventStuff.push([fileToCheck, File.getContent(path)]);
						}
					}
				}
			}
		}
		eventPushedMap.clear();
		eventPushedMap = null;
		#end

		descText = new FlxFixedText(20, 200, 0, eventStuff[0][0]);

		var leEvents:Array<String> = [];
		for (i in 0...eventStuff.length) {
			leEvents.push(eventStuff[i][0]);
		}

		var text:FlxFixedText = new FlxFixedText(20, 30, 0, "Event:");
		tab_group_event.add(text);
		eventDropDown = new FlxUIDropDownMenuCustom(20, 50, FlxUIDropDownMenuCustom.makeStrIdLabelArray(leEvents, true), function(pressed:String) {
			var selectedEvent:Int = Std.parseInt(pressed);
			descText.text = eventStuff[selectedEvent][1];
				if (curSelectedNote != null &&  eventStuff != null) {
				if (curSelectedNote != null && curSelectedNote[2] == null){
				curSelectedNote[1][curEventSelected][0] = eventStuff[selectedEvent][0];

				}
				updateGrid();
			}
		});
		blockPressWhileScrolling.push(eventDropDown);

		var text:FlxFixedText = new FlxFixedText(20, 90, 0, "Value 1:");
		tab_group_event.add(text);
		value1InputText = new FlxUITextInput(20, 110, 100, "");
		blockPressWhileTypingOn.push(value1InputText);

		var text:FlxFixedText = new FlxFixedText(20, 130, 0, "Value 2:");
		tab_group_event.add(text);
		value2InputText = new FlxUITextInput(20, 150, 100, "");
		blockPressWhileTypingOn.push(value2InputText);

		// New event buttons
		var removeButton:FlxButton = new FlxButton(eventDropDown.x + eventDropDown.width + 10, eventDropDown.y, '-', function()
		{
			if(curSelectedNote != null && curSelectedNote[2] == null) //Is event note
			{
				if(curSelectedNote[1].length < 2)
				{
					_song.events.remove(curSelectedNote);
					curSelectedNote = null;
				}
				else
				{
					curSelectedNote[1].remove(curSelectedNote[1][curEventSelected]);
				}

				var eventsGroup:Array<Dynamic>;
				--curEventSelected;
				if(curEventSelected < 0) curEventSelected = 0;
				else if(curSelectedNote != null && curEventSelected >= (eventsGroup = curSelectedNote[1]).length) curEventSelected = eventsGroup.length - 1;

				changeEventSelected();
				updateGrid();
			}
		});
		removeButton.setGraphicSize(Std.int(removeButton.height), Std.int(removeButton.height));
		removeButton.updateHitbox();
		removeButton.color = FlxColor.RED;
		removeButton.label.color = FlxColor.WHITE;
		removeButton.label.size = 12;
		setAllLabelsOffset(removeButton, -30, 0);
		tab_group_event.add(removeButton);

		var addButton:FlxButton = new FlxButton(removeButton.x + removeButton.width + 10, removeButton.y, '+', function()
		{
			if(curSelectedNote != null && curSelectedNote[2] == null) //Is event note
			{
				var eventsGroup:Array<Dynamic> = curSelectedNote[1];
				eventsGroup.push(['', '', '']);

				changeEventSelected(1);
				updateGrid();
			}
		});
		addButton.setGraphicSize(Std.int(removeButton.width), Std.int(removeButton.height));
		addButton.updateHitbox();
		addButton.color = FlxColor.GREEN;
		addButton.label.color = FlxColor.WHITE;
		addButton.label.size = 12;
		setAllLabelsOffset(addButton, -30, 0);
		tab_group_event.add(addButton);

		var copyEventButton:FlxButton = new FlxButton(removeButton.x, removeButton.y + 50, 'Copy', function()
		{
			if(curSelectedNote != null && curSelectedNote[2] == null) //Is event note
			{
				var eventsGroup:Array<Dynamic> = curSelectedNote[1];
				copiedEvent = eventsGroup[curEventSelected];
			}
		});
		tab_group_event.add(copyEventButton);

		var pasteEventButton:FlxButton = new FlxButton(copyEventButton.x, copyEventButton.y + 30, 'Paste', function()
		{
			if(curSelectedNote != null && curSelectedNote[2] == null) //Is event note
			{
				var eventsGroup:Array<Dynamic> = curSelectedNote[1];
				eventsGroup[curEventSelected] = copiedEvent;

				updateGrid();
			}
		});
		tab_group_event.add(pasteEventButton);

		var PANEButton:FlxButton = new FlxButton(pasteEventButton.x, pasteEventButton.y + 30, 'Paste As New', function()
		{
			if(curSelectedNote != null && curSelectedNote[2] == null) //Is event note
			{
				var eventsGroup:Array<Dynamic> = curSelectedNote[1];
				eventsGroup.push(copiedEvent);

				changeEventSelected(1);
				updateGrid();
			}
		});
		tab_group_event.add(PANEButton);

		var moveLeftButton:FlxButton = new FlxButton(addButton.x + addButton.width + 20, addButton.y, '<', function()
		{
			changeEventSelected(-1);
		});
		moveLeftButton.setGraphicSize(Std.int(addButton.width), Std.int(addButton.height));
		moveLeftButton.updateHitbox();
		moveLeftButton.label.size = 12;
		setAllLabelsOffset(moveLeftButton, -30, 0);
		tab_group_event.add(moveLeftButton);

		var moveRightButton:FlxButton = new FlxButton(moveLeftButton.x + moveLeftButton.width + 10, moveLeftButton.y, '>', function()
		{
			changeEventSelected(1);
		});
		moveRightButton.setGraphicSize(Std.int(moveLeftButton.width), Std.int(moveLeftButton.height));
		moveRightButton.updateHitbox();
		moveRightButton.label.size = 12;
		setAllLabelsOffset(moveRightButton, -30, 0);
		tab_group_event.add(moveRightButton);

		selectedEventText = new FlxFixedText(addButton.x - 100, addButton.y + addButton.height + 6, (moveRightButton.x - addButton.x) + 186, 'Selected Event: None');
		selectedEventText.alignment = CENTER;
		tab_group_event.add(selectedEventText);

		tab_group_event.add(descText);
		tab_group_event.add(value1InputText);
		tab_group_event.add(value2InputText);
		tab_group_event.add(eventDropDown);

		UI_box.addGroup(tab_group_event);
	}

	function changeEventSelected(change:Int = 0)
	{
		if(curSelectedNote != null && curSelectedNote[2] == null) //Is event note
		{
			curEventSelected += change;
			if(curEventSelected < 0) curEventSelected = Std.int(curSelectedNote[1].length) - 1;
			else if(curEventSelected >= curSelectedNote[1].length) curEventSelected = 0;
			selectedEventText.text = 'Selected Event: ' + (curEventSelected + 1) + ' / ' + curSelectedNote[1].length;
		}
		else
		{
			curEventSelected = 0;
			selectedEventText.text = 'Selected Event: None';
		}
		updateNoteUI();
	}

	function setAllLabelsOffset(button:FlxButton, x:Float, y:Float)
	{
		for (point in button.labelOffsets)
		{
			point.set(x, y);
		}
	}

	var metronome:FlxUICheckBox;
	var mouseScrollingQuant:FlxUICheckBox;
	var metronomeStepper:FlxUINumericStepper;
	var metronomeOffsetStepper:FlxUINumericStepper;
	var disableAutoScrolling:FlxUICheckBox;
	#if desktop
	var waveformUseInstrumental:FlxUICheckBox;
	var waveformUsePVoices:FlxUICheckBox;
	var waveformUseOVoices:FlxUICheckBox;
	#end
	var instVolume:FlxUINumericStepper;
	var pVoicesVolume:FlxUINumericStepper;
	var oVoicesVolume:FlxUINumericStepper;
	function addChartingUI() {
		var tab_group_chart = new FlxUI(null, UI_box);
		tab_group_chart.name = 'Charting';

		#if desktop
		if (FlxG.save.data.chart_waveformInst == null) FlxG.save.data.chart_waveformInst = false;
		if (FlxG.save.data.chart_waveformPVoices == null) FlxG.save.data.chart_waveformPVoices = false;
		if (FlxG.save.data.chart_waveformOVoices == null) FlxG.save.data.chart_waveformVOoices = false;

		waveformUseInstrumental = new FlxUICheckBox(10, 90, null, null, "Waveform for Instrumental", 100);
		waveformUseInstrumental.checked = FlxG.save.data.chart_waveformInst;
		waveformUseInstrumental.callback = function()
		{
			waveformUsePVoices.checked = false;
			waveformUseOVoices.checked = false;
			FlxG.save.data.chart_waveformVoices = false;
			FlxG.save.data.chart_waveformInst = waveformUseInstrumental.checked;
			updateWaveform();
		};

		waveformUsePVoices = new FlxUICheckBox(waveformUseInstrumental.x + 120, waveformUseInstrumental.y, null, null, "Waveform for Player", 100);
		waveformUsePVoices.checked = FlxG.save.data.chart_waveformPVoices;
		waveformUsePVoices.callback = function()
		{
			FlxG.save.data.chart_waveformPVoices = waveformUsePVoices.checked;
			updateWaveform();
		};

		waveformUseOVoices = new FlxUICheckBox(waveformUseInstrumental.x + 120, 120, null, null, "Waveform for Opponent", 100);
		waveformUseOVoices.checked = FlxG.save.data.chart_waveformOVoices;
		waveformUseOVoices.callback = function()
		{
			FlxG.save.data.chart_waveformOVoices = waveformUseOVoices.checked;
			updateWaveform();
		};
		#end

		check_mute_inst = new FlxUICheckBox(10, 260, null, null, "Mute Instrumental (in editor)", 100);
		check_mute_inst.checked = false;
		check_mute_inst.callback = function()
		{
			var vol:Float = 1;

			if (check_mute_inst.checked)
				vol = 0;

			FlxG.sound.music.volume = vol;
		};
		mouseScrollingQuant = new FlxUICheckBox(10, 170, null, null, "Mouse Scrolling Quantization", 100);
		if (FlxG.save.data.mouseScrollingQuant == null) FlxG.save.data.mouseScrollingQuant = false;
		mouseScrollingQuant.checked = FlxG.save.data.mouseScrollingQuant;

		mouseScrollingQuant.callback = function()
		{
			FlxG.save.data.mouseScrollingQuant = mouseScrollingQuant.checked;
			mouseQuant = FlxG.save.data.mouseScrollingQuant;
		};

		check_vortex = new FlxUICheckBox(10, 140, null, null, "Vortex Editor (BETA)", 100);
		if (FlxG.save.data.chart_vortex == null) FlxG.save.data.chart_vortex = false;
		check_vortex.checked = FlxG.save.data.chart_vortex;

		check_vortex.callback = function()
		{
			FlxG.save.data.chart_vortex = check_vortex.checked;
			vortex = FlxG.save.data.chart_vortex;
			reloadGridLayer();
		};

		check_warnings = new FlxUICheckBox(10, 120, null, null, "Ignore Progress Warnings", 100);
		if (FlxG.save.data.ignoreWarnings == null) FlxG.save.data.ignoreWarnings = false;
		check_warnings.checked = FlxG.save.data.ignoreWarnings;

		check_warnings.callback = function()
		{
			FlxG.save.data.ignoreWarnings = check_warnings.checked;
			ignoreWarnings = FlxG.save.data.ignoreWarnings;
		};

		check_mute_pvocals = new FlxUICheckBox(check_mute_inst.x + 120, check_mute_inst.y, null, null, "Mute Player Vocals (in editor)", 100);
		check_mute_pvocals.checked = false;
		check_mute_pvocals.callback = function()
		{
			if(pvocals != null) {
				var vol:Float = 1;

				if (check_mute_pvocals.checked)
					vol = 0;

				pvocals.volume = vol;
			}
		};

		check_mute_ovocals = new FlxUICheckBox(check_mute_inst.x, check_mute_inst.y + 30, null, null, "Mute Opponent Vocals (in editor)", 100);
		check_mute_ovocals.checked = false;
		check_mute_ovocals.callback = function()
		{
			if(ovocals != null) {
				var vol:Float = 1;

				if (check_mute_ovocals.checked)
					vol = 0;

				ovocals.volume = vol;
			}
		};

		playSoundBf = new FlxUICheckBox(check_mute_inst.x, check_mute_ovocals.y + 30, null, null, 'Play Sound (Player notes)', 100,
			function() {
				FlxG.save.data.chart_playSoundBf = playSoundBf.checked;
			}
		);
		if (FlxG.save.data.chart_playSoundBf == null) FlxG.save.data.chart_playSoundBf = false;
		playSoundBf.checked = FlxG.save.data.chart_playSoundBf;

		playSoundDad = new FlxUICheckBox(check_mute_inst.x + 120, playSoundBf.y, null, null, 'Play Sound (Opponent notes)', 100,
			function() {
				FlxG.save.data.chart_playSoundDad = playSoundDad.checked;
			}
		);
		if (FlxG.save.data.chart_playSoundDad == null) FlxG.save.data.chart_playSoundDad = false;
		playSoundDad.checked = FlxG.save.data.chart_playSoundDad;

		metronome = new FlxUICheckBox(10, 15, null, null, "Metronome Enabled", 100,
			function() {
				FlxG.save.data.chart_metronome = metronome.checked;
			}
		);
		if (FlxG.save.data.chart_metronome == null) FlxG.save.data.chart_metronome = false;
		metronome.checked = FlxG.save.data.chart_metronome;

		metronomeStepper = new FlxUINumericStepper(15, 55, 5, _song.bpm, 1, 1500, 1);
		metronomeOffsetStepper = new FlxUINumericStepper(metronomeStepper.x + 100, metronomeStepper.y, 25, 0, 0, 1000, 1);
		blockPressWhileTypingOnStepper.push(metronomeStepper);
		blockPressWhileTypingOnStepper.push(metronomeOffsetStepper);

		disableAutoScrolling = new FlxUICheckBox(metronome.x + 120, metronome.y, null, null, "Disable Autoscroll (Not Recommended)", 120,
			function() {
				FlxG.save.data.chart_noAutoScroll = disableAutoScrolling.checked;
			}
		);
		if (FlxG.save.data.chart_noAutoScroll == null) FlxG.save.data.chart_noAutoScroll = false;
		disableAutoScrolling.checked = FlxG.save.data.chart_noAutoScroll;

		instVolume = new FlxUINumericStepper(metronomeStepper.x, 220, 0.1, FlxG.sound.music.volume, 0, 1, 1);
		instVolume.name = 'inst_volume';
		blockPressWhileTypingOnStepper.push(instVolume);

		pVoicesVolume = new FlxUINumericStepper(instVolume.x + 90, instVolume.y, 0.1, pvocals.volume, 0, 1, 1);
		pVoicesVolume.name = 'pvoices_volume';
		blockPressWhileTypingOnStepper.push(pVoicesVolume);

		oVoicesVolume = new FlxUINumericStepper(pVoicesVolume.x + 90, instVolume.y, 0.1, ovocals.volume, 0, 1, 1);
		oVoicesVolume.name = 'ovoices_volume';
		blockPressWhileTypingOnStepper.push(oVoicesVolume);
		
		#if !html5
		sliderRate = new FlxUISlider(this, 'playbackSpeed', 120, 150, 0.5, 3, 150, null, 5, FlxColor.WHITE, FlxColor.BLACK);
		sliderRate.nameLabel.text = 'Playback Rate';
		tab_group_chart.add(sliderRate);
		#end
		sliderTime = new FlxUISlider(FlxG.sound.music, 'time', 30, 400, 0, FlxG.sound.music.length, 220, null, 5, FlxColor.WHITE, FlxColor.RED);
		sliderTime.nameLabel.text = 'Song Time';
		sliderTime.minLabel.text = '0:00.00';
		sliderTime.maxLabel.text = FlxStringUtil.formatTime(Math.max(FlxG.sound.music.length / 1000, 0), true);
		sliderTime.valueLabel.color = FlxColor.WHITE;
		sliderTime.name = 'song_time';
		tab_group_chart.add(sliderTime);
		sliderTime.callback = (value) -> {
			changeSection(sectionFromTime(value * FlxG.sound.music.length));
			
			var pl = (FlxG.sound.music.playing && value <= 0.99);
			FlxG.sound.music.pause();
			FlxG.sound.music.time = value * FlxG.sound.music.length;
			if (pl) FlxG.sound.music.play();

			if (pvocals != null) {
				pvocals.pause();
				pvocals.time = value * FlxG.sound.music.length;
				if (pl) pvocals.play();
			}
			if (ovocals != null) {
				ovocals.pause();
				ovocals.time = value * FlxG.sound.music.length;
				if (pl) ovocals.play();
			}

		}

		tab_group_chart.add(new FlxFixedText(metronomeStepper.x, metronomeStepper.y - 15, 0, 'BPM:'));
		tab_group_chart.add(new FlxFixedText(metronomeOffsetStepper.x, metronomeOffsetStepper.y - 15, 0, 'Offset (ms):'));
		tab_group_chart.add(new FlxFixedText(instVolume.x, instVolume.y - 15, 0, 'Inst Volume'));
		tab_group_chart.add(new FlxFixedText(pVoicesVolume.x, pVoicesVolume.y - 15, 0, 'Player Volume'));
		tab_group_chart.add(new FlxFixedText(oVoicesVolume.x, oVoicesVolume.y - 15, 0, 'Opponent Volume'));
		tab_group_chart.add(metronome);
		tab_group_chart.add(disableAutoScrolling);
		tab_group_chart.add(metronomeStepper);
		tab_group_chart.add(metronomeOffsetStepper);
		#if desktop
		tab_group_chart.add(waveformUseInstrumental);
		tab_group_chart.add(waveformUsePVoices);
		tab_group_chart.add(waveformUseOVoices);
		#end
		tab_group_chart.add(instVolume);
		tab_group_chart.add(pVoicesVolume);
		tab_group_chart.add(oVoicesVolume);
		tab_group_chart.add(check_mute_inst);
		tab_group_chart.add(check_mute_pvocals);
		tab_group_chart.add(check_mute_ovocals);
		tab_group_chart.add(check_vortex);
		tab_group_chart.add(mouseScrollingQuant);
		tab_group_chart.add(check_warnings);
		tab_group_chart.add(playSoundBf);
		tab_group_chart.add(playSoundDad);
		UI_box.addGroup(tab_group_chart);
	}

	function loadSong():Void
	{
		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.stop();
			// vocals.stop();
		}

		pvocals = new FlxSound();
		try
		{
			var pfile:Dynamic = Paths.voices(currentSongName);
			if (pfile != null) pvocals.loadEmbedded(pfile);
		}
		FlxG.sound.list.add(pvocals);

		ovocals = new FlxSound();
		try
		{
			var ofile:Dynamic = Paths.secVoices(currentSongName);
			if (ofile != null) ovocals.loadEmbedded(ofile);
		}

		FlxG.sound.list.add(ovocals);
		
		secAmt = generateSections();

		generateSong();
		FlxG.sound.music.pause();
		Conductor.songPosition = sectionStartTime();
		FlxG.sound.music.time = Conductor.songPosition;
	}

	function generateSong() {
		FlxG.sound.playMusic(Paths.inst(currentSongName), 0.6/*, false*/);
		if (FlxG.save.data != null)
		{
			if(FlxG.save.data.chart_instVolume != null) FlxG.sound.music.volume = FlxG.save.data.chart_instVolume;
			if(check_mute_inst != null && check_mute_inst.checked) FlxG.sound.music.volume = 0;

			if(FlxG.save.data.chart_ovocalsVolume != null) ovocals.volume = FlxG.save.data.chart_ovocalsVolume;
			if(check_mute_ovocals != null && check_mute_ovocals.checked) ovocals.volume = 0;

			if(FlxG.save.data.chart_pvocalsVolume != null) pvocals.volume = FlxG.save.data.chart_pvocalsVolume;
			if(check_mute_pvocals != null && check_mute_pvocals.checked) pvocals.volume = 0;
		}

		FlxG.sound.music.onComplete = function()
		{
			FlxG.sound.music.pause();
			Conductor.songPosition = 0;
			if(pvocals != null) {
				pvocals.pause();
				pvocals.time = 0;
			}
			if(ovocals != null) {
				ovocals.pause();
				ovocals.time = 0;
			}
			changeSection();
			curSec = 0;
			updateGrid();
			updateSectionUI();
			pvocals.play();
			ovocals.play();
		};
	}

	function generateUI():Void
	{
		while (bullshitUI.members.length > 0)
		{
			bullshitUI.remove(bullshitUI.members[0], true);
		}

		// general shit
		var title:FlxFixedText = new FlxFixedText(UI_box.x + 20, UI_box.y + 20, 0);
		bullshitUI.add(title);
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
	{
		if (id == FlxUICheckBox.CLICK_EVENT)
		{
			var check:FlxUICheckBox = cast sender;
			var label = check.getLabel().text;
			switch (label)
			{
				case '  .':
					copyMultiSec = check_copyMulti.checked;
					multiInputText.alpha = copyMultiSec ? 1 : 0.25;

				case 'Must hit section':
					_song.notes[curSec].mustHitSection = check.checked;

					updateGrid();
					updateHeads();

				case 'GF section':
					_song.notes[curSec].gfSection = check.checked;

					updateGrid();
					updateHeads();

				case 'Duet section':
					_song.notes[curSec].duetSection = check.checked;

					updateGrid();
					updateHeads();

				case 'Change BPM':
					_song.notes[curSec].changeBPM = check.checked;
					FlxG.log.add('changed bpm shit');
				case "Alt Animation":
					_song.notes[curSec].altAnim = check.checked;
			}
		}
		else if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper))
		{
			var nums:FlxUINumericStepper = cast sender;
			var wname = nums.name;
			FlxG.log.add(wname);
			if (wname == 'section_beats')
			{
				_song.notes[curSec].sectionBeats = nums.value;
				reloadGridLayer();
			}
			else if (wname == 'song_speed')
			{
				_song.speed = nums.value;
			}
			else if (wname == 'song_bpm')
			{
				tempBpm = nums.value;
				Conductor.mapBPMChanges(_song);
				Conductor.changeBPM(nums.value);
			}
			else if (wname == 'note_susLength')
			{
				if(curSelectedNote != null && curSelectedNote[2] != null) {
					curSelectedNote[2] = Math.max(nums.value, 0);
					updateGrid();
				}
			}
			else if (wname == 'section_bpm')
			{
				_song.notes[curSec].bpm = nums.value;
				updateGrid();
			}
			else if (wname == 'inst_volume')
			{
				var val:Float = nums.value;
				FlxG.sound.music.volume = val;
				FlxG.save.data.chart_instVolume = val;
				FlxG.save.flush();
			}
			else if (wname == 'pvoices_volume')
			{
				var val:Float = nums.value;
				pvocals.volume = val;
				FlxG.save.data.chart_pvocalsVolume = val;
				FlxG.save.flush();
			}
			else if (wname == 'ovoices_volume')
			{
				var val:Float = nums.value;
				ovocals.volume = val;
				FlxG.save.data.chart_ovocalsVolume = val;
				FlxG.save.flush();
			}
		}
		else if(id == FlxUITextInput.CHANGE_EVENT && (sender is FlxUITextInput)) {
			if(sender == noteSplashesInputText) {
				_song.splashSkin = noteSplashesInputText.text;
			}
			else if(curSelectedNote != null)
			{
				if(sender == value1InputText) {
					if(curSelectedNote[1][curEventSelected] != null)
					{
						curSelectedNote[1][curEventSelected][1] = value1InputText.text;
						updateGrid();
					}
				}
				else if(sender == value2InputText) {
					if(curSelectedNote[1][curEventSelected] != null)
					{
						curSelectedNote[1][curEventSelected][2] = value2InputText.text;
						updateGrid();
					}
				}
				else if(sender == strumTimeInputText) {
					var value:Float = Std.parseFloat(strumTimeInputText.text);
					if(Math.isNaN(value)) value = 0;
					curSelectedNote[0] = value;
					updateGrid();
				}
			}
		}
		else if (id == FlxUISlider.CHANGE_EVENT && (sender is FlxUISlider))
		{
			switch (sender)
			{
				case 'playbackSpeed':
					playbackSpeed = Std.int(sliderRate.value);
			}
		}

		// FlxG.log.add(id + " WEED " + sender + " WEED " + data + " WEED " + params);
	}

	var updatedSection:Bool = false;

	function generateSections():Int {
		var daBPM:Float = _song.bpm;
		var estAmtOfSec:Int = Math.ceil(FlxG.sound.music.length / ((1000 * 60 / daBPM) * 4));
		var daSecs:Int = 0;
		for (i in 0...estAmtOfSec + 1) {
			if (sectionStartTime(0, i) < FlxG.sound.music.length) {
				if(_song.notes[i] == null) {
					addSection();
				}
				daSecs++;
			}
		}
		daSecs--;
		return daSecs;
	}

	function sectionStartTime(add:Int = 0, ?daSec:Int):Float
	{
		if (daSec == null) daSec = curSec;
		var daBPM:Float = _song.bpm;
		var daPos:Float = 0;
		for (i in 0...daSec + add)
		{
			if(_song.notes[i] != null)
			{
				if (_song.notes[i].changeBPM)
				{
					daBPM = _song.notes[i].bpm;
				}
				daPos += getSectionBeats(i) * (1000 * 60 / daBPM);
			}
		}
		return daPos;
	}

	function sectionFromTime(time:Float = 0):Int
	{
		var daBPM:Float = _song.bpm;
		var daPos:Float = 0;
		for (i in 0..._song.notes.length)
		{
			while (_song.notes[i] == null) addSection();

			if (_song.notes[i].changeBPM)
			{
				daBPM = _song.notes[i].bpm;
			}
			daPos += getSectionBeats(i) * (1000 * 60 / daBPM);
			if (daPos >= time) return i;
		}
		return curSec;
	}

	var lastMousePos:FlxPoint = FlxPoint.get();

	var lastConductorPos:Float;
	var colorSine:Float = 0;
	override function update(elapsed:Float)
	{
		curStep = recalculateSteps();

		if(FlxG.sound.music.time < 0) {
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
		}
		else if(FlxG.sound.music.time > FlxG.sound.music.length) {
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
			changeSection();
		}
		Conductor.songPosition = FlxG.sound.music.time;
		_song.song = UI_songTitle.text;

		strumLineUpdateY();
		for (i in 0...8){
			strumLineNotes.members[i].y = strumLine.y;
		}

		FlxG.mouse.visible = true;//cause reasons. trust me
		camPos.y = strumLine.y;
		
		secButton.visible = !canReturn;
		returnSecButton.visible = canReturn;
		cancelSecButton.visible = canReturn;

		if(!disableAutoScrolling.checked) {
			if (Math.ceil(strumLine.y) >= eventGrid.height)
			{
				if (_song.notes[curSec + 1] == null)
				{
					addSection();
				}

				changeSection(curSec + 1, false);
			} else if(strumLine.y < -10) {
				changeSection(curSec - 1, false);
			}
		}
		FlxG.watch.addQuick('daBeat', curBeat);
		FlxG.watch.addQuick('daStep', curStep);


		if (((FlxG.mouse.x > eventGrid.x && FlxG.mouse.x < eventGrid.x + eventGrid.width)
			|| (FlxG.mouse.x > leftGrid.x && FlxG.mouse.x < leftGrid.x + leftGrid.width)
			|| (FlxG.mouse.x > rightGrid.x && FlxG.mouse.x < rightGrid.x + rightGrid.width))
			&& FlxG.mouse.y > eventGrid.y
			&& FlxG.mouse.y < rightGrid.y + (GRID_SIZE * getSectionBeats() * 4) * zoomList[curZoom])
		{
			dummyArrow.visible = true;
			dummyArrow.x = Math.floor(FlxG.mouse.x / GRID_SIZE) * GRID_SIZE;
			if (FlxG.mouse.x > leftGrid.x && FlxG.mouse.x < rightGrid.x) dummyArrow.x = (Math.floor((FlxG.mouse.x - 20) / GRID_SIZE) * GRID_SIZE) + 20;

			if (FlxG.keys.pressed.SHIFT)
				dummyArrow.y = FlxG.mouse.y;
			else
			{
				var gridmult = GRID_SIZE / (quantization / 16);
				dummyArrow.y = Math.floor(FlxG.mouse.y / gridmult) * gridmult;
			}
		} else {
			dummyArrow.visible = false;
		}

		if ((leftClickType != displayNameList.length + 1 && FlxG.mouse.justPressed) || (rightClickType != displayNameList.length + 1 && FlxG.mouse.justPressedRight))
		{
			if (FlxG.mouse.overlaps(curRenderedNotes))
			{
				curRenderedNotes.forEachAlive(function(note:Note)
				{
					if (FlxG.mouse.overlaps(note))
					{
						if (FlxG.keys.pressed.CONTROL)
						{
							selectNote(note);
						}
						else if (FlxG.keys.pressed.ALT)
						{
							selectNote(note);
							curSelectedNote[3] = noteTypeIntMap.get(currentType);
							updateGrid();
						}
						else
						{
							//trace('tryin to delete note...');
							deleteNote(note);
						}
					}
				});
			}
			else
			{
				if (((FlxG.mouse.x > eventGrid.x && FlxG.mouse.x < eventGrid.x + eventGrid.width)
					|| (FlxG.mouse.x > leftGrid.x && FlxG.mouse.x < leftGrid.x + leftGrid.width)
					|| (FlxG.mouse.x > rightGrid.x && FlxG.mouse.x < rightGrid.x + rightGrid.width))
					&& FlxG.mouse.y > eventGrid.y
					&& FlxG.mouse.y < rightGrid.y + (GRID_SIZE * getSectionBeats() * 4) * zoomList[curZoom])
				{
					FlxG.log.add('added note');
					addNote(FlxG.mouse.justPressedRight);
				}
			}
		}
		
		if(FlxG.mouse.justReleased || FlxG.mouse.justReleasedRight){
			recentNote=null;
		}else if(FlxG.mouse.pressed || FlxG.mouse.pressedRight){
			if(recentNote!=null){
				if(lastMousePos.y!=dummyArrow.y){
					lastMousePos.set(dummyArrow.x,dummyArrow.y);
					var length = getStrumTime(dummyArrow.y)-(recentNote[0]-sectionStartTime());
					setNoteSustain(length,recentNote);
				}
			}
		}

		var blockInput:Bool = false;
		for (inputText in blockPressWhileTypingOn) {
			if(inputText.focus) {
				FlxG.sound.muteKeys = [];
				FlxG.sound.volumeDownKeys = [];
				FlxG.sound.volumeUpKeys = [];
				blockInput = true;
				break;
			}
		}

		if(!blockInput) {
			for (stepper in blockPressWhileTypingOnStepper) {
				@:privateAccess
				var leText:Dynamic = stepper.textInput;
				var leText:FlxUITextInput = leText;
				if(leText.focus) {
					FlxG.sound.muteKeys = [];
					FlxG.sound.volumeDownKeys = [];
					FlxG.sound.volumeUpKeys = [];
					blockInput = true;
					break;
				}
			}
		}

		if(!blockInput) {
			FlxG.sound.muteKeys = states.menus.TitleState.muteKeys;
			FlxG.sound.volumeDownKeys = states.menus.TitleState.volumeDownKeys;
			FlxG.sound.volumeUpKeys = states.menus.TitleState.volumeUpKeys;
			for (dropDownMenu in blockPressWhileScrolling) {
				if(dropDownMenu.dropPanel.visible) {
					blockInput = true;
					break;
				}
			}
		}

		if (!blockInput)
		{
			if (FlxG.keys.justPressed.ESCAPE) // fuck off
			{
				autosaveSong();
				FlxG.mouse.visible = false;
				PlayState.SONG = _song;
				FlxG.sound.music.stop();
				if(pvocals != null) pvocals.stop();
				if(ovocals != null) ovocals.stop();

				//if(_song.stage == null) _song.stage = stageDropDown.selectedLabel;
				StageData.loadDirectory(_song);
				LoadingState.loadAndSwitchState(new PlayState());
				if (FlxG.keys.pressed.SHIFT) {
					PlayState.startOnTime = sectionStartTime();
				}
			}

			if(curSelectedNote != null && curSelectedNote[1] > -1) {
				if (FlxG.keys.justPressed.E)
				{
					changeNoteSustain(Conductor.stepCrochet);
				}
				if (FlxG.keys.justPressed.Q)
				{
					changeNoteSustain(-Conductor.stepCrochet);
				}
			}


			if (FlxG.keys.justPressed.BACKSPACE) {
				PlayState.chartingMode = false;
				MusicBeatState.switchState(new states.editors.MasterEditorMenu());
				FlxG.sound.playMusic(Paths.music('futuremenu'));
				FlxG.mouse.visible = false;
				return;
			}

			if(FlxG.keys.justPressed.Z && curZoom > 0 && !FlxG.keys.pressed.CONTROL) {
				--curZoom;
				updateZoom();
			}
			if(FlxG.keys.justPressed.X && curZoom < zoomList.length-1) {
				curZoom++;
				updateZoom();
			}

			if (FlxG.keys.justPressed.TAB)
			{
				if (FlxG.keys.pressed.SHIFT)
				{
					UI_box.selected_tab -= 1;
					if (UI_box.selected_tab < 0)
						UI_box.selected_tab = 2;
				}
				else
				{
					UI_box.selected_tab += 1;
					if (UI_box.selected_tab >= 3)
						UI_box.selected_tab = 0;
				}
			}

			if (FlxG.keys.justPressed.SPACE)
			{
				if (FlxG.sound.music.playing)
				{
					FlxG.sound.music.pause();
					if(pvocals != null) pvocals.pause();
					if(ovocals != null) ovocals.pause();
				}
				else
				{
					if(pvocals != null) {
						pvocals.play();
						pvocals.pause();
						pvocals.time = FlxG.sound.music.time;
						pvocals.play();
					}
					if(ovocals != null) {
						ovocals.play();
						ovocals.pause();
						ovocals.time = FlxG.sound.music.time;
						ovocals.play();
					}
					FlxG.sound.music.play();
				}
			}

			if (!FlxG.keys.pressed.ALT && FlxG.keys.justPressed.R)
			{
				if (FlxG.keys.pressed.SHIFT)
					resetSection(true);
				else
					resetSection();
			}
			
			if (FlxG.keys.justPressed.O){
				check_oppSec.checked = !check_oppSec.checked;
			}
			if (FlxG.keys.justPressed.P){
				check_plrSec.checked = !check_plrSec.checked;
			}

			if (FlxG.keys.justPressed.F){
				check_mustHitSection.checked = !check_mustHitSection.checked;
				_song.notes[curSec].mustHitSection = check_mustHitSection.checked;
				
				updateGrid();
				updateHeads();
			}
			if (FlxG.keys.justPressed.G){
				check_duetSection.checked = !check_duetSection.checked;
				_song.notes[curSec].duetSection = check_duetSection.checked;
			}

			if (FlxG.keys.pressed.CONTROL){
				if(FlxG.keys.justPressed.Z) {
					undo();
				}
				if (FlxG.keys.justPressed.C) {
					notesCopied = [];
					sectionToCopy = curSec;
					for (i in 0..._song.notes[sectionToCopy].sectionNotes.length)
					{
						var note:Array<Dynamic> = _song.notes[sectionToCopy].sectionNotes[i];
						notesCopied.push(note);
					}
						
					for (event in _song.events)
					{
						var strumTime:Float = event[0];
						if(sectionStartTime(1) > event[0] && event[0] >= sectionStartTime())
						{
							var copiedEventArray:Array<Dynamic> = [];
							for (i in 0...event[1].length)
							{
								var eventToPush:Array<Dynamic> = event[1][i];
								copiedEventArray.push([eventToPush[0], eventToPush[1], eventToPush[2]]);
							}
							notesCopied.push([strumTime, -1, copiedEventArray]);
						}
					}
				}
				if (FlxG.keys.justPressed.V) {
					for (note in notesCopied) {
						var copiedNote:Array<Dynamic> = [];
						var newStrumTime:Float = note[0] + Conductor.stepCrochet * (getSectionBeats() * 4 * (curSec - sectionToCopy));
						if(note[1] < 0)
						{
							if(check_eventsSec.checked)
							{
								var copiedEventArray:Array<Dynamic> = [];
								for (i in 0...note[2].length)
								{
									var eventToPush:Array<Dynamic> = note[2][i];
									copiedEventArray.push([eventToPush[0], eventToPush[1], eventToPush[2]]);
								}
								_song.events.push([newStrumTime, copiedEventArray]);
							}
						}
						else
						{
							if((check_plrSec.checked && note[1] > 3) || (check_oppSec.checked && note[1] < 4))
							{
								if(note[4] != null) {
									copiedNote = [newStrumTime, note[1], note[2], note[3], note[4]];
								} else {
									copiedNote = [newStrumTime, note[1], note[2], note[3]];
								}
								_song.notes[curSec].sectionNotes.push(copiedNote);
							}
						}
					}
					updateGrid();
				}
			}


			if (FlxG.mouse.wheel != 0)
			{
				FlxG.sound.music.pause();
				if (!mouseQuant)
					FlxG.sound.music.time -= (FlxG.mouse.wheel * Conductor.stepCrochet*0.8);
				else
					{
						var time:Float = FlxG.sound.music.time;
						var beat:Float = curDecBeat;
						var snap:Float = quantization / 4;
						var increase:Float = 1 / snap;
						if (FlxG.mouse.wheel > 0)
						{
							var fuck:Float = CoolUtil.quantize(beat, snap) - increase;
							FlxG.sound.music.time = Conductor.beatToSeconds(fuck);
						}else{
							var fuck:Float = CoolUtil.quantize(beat, snap) + increase;
							FlxG.sound.music.time = Conductor.beatToSeconds(fuck);
						}
					}
					if(pvocals != null) {
						pvocals.pause();
						pvocals.time = FlxG.sound.music.time;
					}
					if(ovocals != null) {
						ovocals.pause();
						ovocals.time = FlxG.sound.music.time;
					}
			}

			//ARROW VORTEX SHIT NO DEADASS



			if (FlxG.keys.pressed.W || FlxG.keys.pressed.S)
			{
				FlxG.sound.music.pause();

				var holdingShift:Float = 1;
				if (FlxG.keys.pressed.CONTROL) holdingShift = 0.25;
				else if (FlxG.keys.pressed.SHIFT) holdingShift = 4;

				var daTime:Float = 700 * FlxG.elapsed * holdingShift;

				if (FlxG.keys.pressed.W)
				{
					FlxG.sound.music.time -= daTime;
				}
				else
					FlxG.sound.music.time += daTime;

				if(pvocals != null) {
					pvocals.pause();
					pvocals.time = FlxG.sound.music.time;
				}
				if(ovocals != null) {
					ovocals.pause();
					ovocals.time = FlxG.sound.music.time;
				}
			}

			if(!vortex){
				if (FlxG.keys.justPressed.UP || FlxG.keys.justPressed.DOWN  )
				{
					FlxG.sound.music.pause();
					updateCurStep();
					var time:Float = FlxG.sound.music.time;
					var beat:Float = curDecBeat;
					var snap:Float = quantization / 4;
					var increase:Float = 1 / snap;
					if (FlxG.keys.pressed.UP)
					{
						var fuck:Float = CoolUtil.quantize(beat, snap) - increase; //(Math.floor((beat+snap) / snap) * snap);
						FlxG.sound.music.time = Conductor.beatToSeconds(fuck);
					}else{
						var fuck:Float = CoolUtil.quantize(beat, snap) + increase; //(Math.floor((beat+snap) / snap) * snap);
						FlxG.sound.music.time = Conductor.beatToSeconds(fuck);
					}
				}
			}

			var style = currentType;

			if (FlxG.keys.pressed.SHIFT){
				style = 3;
			}

			var conductorTime = Conductor.songPosition; //+ sectionStartTime();Conductor.songPosition / Conductor.stepCrochet;

			//AWW YOU MADE IT SEXY <3333 THX SHADMAR

			if(!blockInput){
				if(FlxG.keys.justPressed.RIGHT){
					curQuant++;
					if(curQuant>quantizations.length-1)
						curQuant = 0;

					quantization = quantizations[curQuant];
					quantTxt.text = "Beat Snap: " + quantization + "th";
				}

				if(FlxG.keys.justPressed.LEFT){
					curQuant--;
					if(curQuant<0)
						curQuant = quantizations.length-1;

					quantization = quantizations[curQuant];
					quantTxt.text = "Beat Snap: " + quantization + "th";
				}
				quant.animation.play('q', true, false, curQuant);
			}
			if(vortex && !blockInput){
				var controlArray:Array<Bool> = [FlxG.keys.justPressed.ONE, FlxG.keys.justPressed.TWO, FlxG.keys.justPressed.THREE, FlxG.keys.justPressed.FOUR,
											   FlxG.keys.justPressed.FIVE, FlxG.keys.justPressed.SIX, FlxG.keys.justPressed.SEVEN, FlxG.keys.justPressed.EIGHT];

				if(controlArray.contains(true))
				{
					for (i in 0...controlArray.length)
					{
						if(controlArray[i])
							doANoteThing(conductorTime, i, style);
					}
				}

				var feces:Float;
				if (FlxG.keys.justPressed.UP || FlxG.keys.justPressed.DOWN  )
				{
					FlxG.sound.music.pause();


					updateCurStep();
					//FlxG.sound.music.time = (Math.round(curStep/quants[curQuant])*quants[curQuant]) * Conductor.stepCrochet;

						//(Math.floor((curStep+quants[curQuant]*1.5/(quants[curQuant]/2))/quants[curQuant])*quants[curQuant]) * Conductor.stepCrochet;//snap into quantization
					var time:Float = FlxG.sound.music.time;
					var beat:Float = curDecBeat;
					var snap:Float = quantization / 4;
					var increase:Float = 1 / snap;
					if (FlxG.keys.pressed.UP)
					{
						var fuck:Float = CoolUtil.quantize(beat, snap) - increase;
						feces = Conductor.beatToSeconds(fuck);
					}else{
						var fuck:Float = CoolUtil.quantize(beat, snap) + increase; //(Math.floor((beat+snap) / snap) * snap);
						feces = Conductor.beatToSeconds(fuck);
					}
					FlxTween.tween(FlxG.sound.music, {time:feces}, 0.1, {ease:FlxEase.circOut});
					if(pvocals != null) {
						pvocals.pause();
						pvocals.time = FlxG.sound.music.time;
					}
					if(ovocals != null) {
						ovocals.pause();
						ovocals.time = FlxG.sound.music.time;
					}

					var dastrum = 0;

					if (curSelectedNote != null){
						dastrum = curSelectedNote[0];
					}

					var secStart:Float = sectionStartTime();
					var datime = (feces - secStart) - (dastrum - secStart); //idk math find out why it doesn't work on any other section other than 0
					if (curSelectedNote != null)
					{
						var controlArray:Array<Bool> = [FlxG.keys.pressed.ONE, FlxG.keys.pressed.TWO, FlxG.keys.pressed.THREE, FlxG.keys.pressed.FOUR,
													   FlxG.keys.pressed.FIVE, FlxG.keys.pressed.SIX, FlxG.keys.pressed.SEVEN, FlxG.keys.pressed.EIGHT];

						if(controlArray.contains(true))
						{

							for (i in 0...controlArray.length)
							{
								if(controlArray[i])
									if(curSelectedNote[1] == i) curSelectedNote[2] += datime - curSelectedNote[2] - Conductor.stepCrochet;
							}
							updateGrid();
							updateNoteUI();
						}
					}
				}
			}
			var shiftThing:Int = 1;
			if (FlxG.keys.pressed.SHIFT)
				shiftThing = 4;

			if (FlxG.keys.justPressed.D)
				changeSection(curSec + shiftThing);
			if (FlxG.keys.justPressed.A) {
				if(curSec <= 0) {
					changeSection(_song.notes.length-1);
				} else {
					changeSection(curSec - shiftThing);
				}
			}
		} else if (FlxG.keys.justPressed.ENTER) {
			for (i in 0...blockPressWhileTypingOn.length) {
				if(blockPressWhileTypingOn[i].focus) {
					blockPressWhileTypingOn[i].focus = false;
				}
			}
		}

		_song.bpm = tempBpm;

		strumLineNotes.visible = quant.visible = vortex;

		if(FlxG.sound.music.time < 0) {
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
		}
		else if(FlxG.sound.music.time > FlxG.sound.music.length) {
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
			changeSection();
		}
		Conductor.songPosition = FlxG.sound.music.time;
		strumLineUpdateY();
		camPos.y = strumLine.y;
		for (i in 0...8){
			strumLineNotes.members[i].y = strumLine.y;
			strumLineNotes.members[i].alpha = FlxG.sound.music.playing ? 1 : 0.35;
		}

		// PLAYBACK SPEED CONTROLS //
		var holdingShift = FlxG.keys.pressed.SHIFT;
		var holdingLB = FlxG.keys.pressed.LBRACKET;
		var holdingRB = FlxG.keys.pressed.RBRACKET;
		var pressedLB = FlxG.keys.justPressed.LBRACKET;
		var pressedRB = FlxG.keys.justPressed.RBRACKET;

		if (!holdingShift && pressedLB || holdingShift && holdingLB)
			playbackSpeed -= 0.01;
		if (!holdingShift && pressedRB || holdingShift && holdingRB)
			playbackSpeed += 0.01;
		if (FlxG.keys.pressed.ALT && (pressedLB || pressedRB || holdingLB || holdingRB))
			playbackSpeed = 1;
		//

		if (playbackSpeed <= 0.5)
			playbackSpeed = 0.5;
		if (playbackSpeed >= 3)
			playbackSpeed = 3;

		FlxG.sound.music.pitch = playbackSpeed;
		pvocals.pitch = playbackSpeed;
		ovocals.pitch = playbackSpeed;

		bpmTxt.text = Std.string(FlxMath.roundDecimal(Conductor.songPosition / 1000, 2)) + " / " + Std.string(FlxMath.roundDecimal(FlxG.sound.music.length / 1000, 2));
		bpmTxt.x = Std.int(FlxG.width - (bpmTxt.width + 10));
		secTxt.text = "Section: " + curSec + " / " + secAmt;
		secTxt.x = Std.int(FlxG.width - (secTxt.width + 10));
		beatTxt.text = "Beat: " + Std.string(curDecBeat).substring(0,4);
		beatTxt.x = Std.int(FlxG.width - (beatTxt.width + 10));
		stepTxt.text = "Step: " + curStep;
		stepTxt.x = Std.int(FlxG.width - (stepTxt.width + 10));

		var playedSound:Array<Bool> = [false, false, false, false]; //Prevents ouchy GF sex sounds
		curRenderedNotes.forEachAlive(function(note:Note) {
			note.alpha = 1;
			if(curSelectedNote != null) {
				var noteDataToCheck:Int = note.noteData;
				if(noteDataToCheck > -1 && note.mustPress != _song.notes[curSec].mustHitSection) noteDataToCheck += 4;

				if (curSelectedNote[0] == note.strumTime && ((curSelectedNote[2] == null && noteDataToCheck < 0) || (curSelectedNote[2] != null && curSelectedNote[1] == noteDataToCheck)))
				{
					colorSine += elapsed;
					var colorVal:Float = 0.7 + Math.sin(Math.PI * colorSine) * 0.3;
					note.color = FlxColor.fromRGBFloat(colorVal, colorVal, colorVal, 0.999); //Alpha can't be 100% or the color won't be updated for some reason, guess i will die
				}
			}

			if(note.strumTime <= Conductor.songPosition) {
				note.alpha = 0.4;
				if(note.strumTime > lastConductorPos && FlxG.sound.music.playing && note.noteData > -1) {
					var data:Int = note.noteData % 4;
					var noteDataToCheck:Int = note.noteData;
					if(noteDataToCheck > -1 && note.mustPress != _song.notes[curSec].mustHitSection) noteDataToCheck += 4;
						strumLineNotes.members[noteDataToCheck].playAnim('confirm', true);
						strumLineNotes.members[noteDataToCheck].resetAnim = (note.sustainLength / 1000) + 0.15;
					if(!playedSound[data]) {
						if((playSoundBf.checked && note.mustPress) || (playSoundDad.checked && !note.mustPress)){
							var soundToPlay = 'hitsound';
							if(_song.player1 == 'gf') { //Easter egg
								soundToPlay = 'GF_' + Std.string(data + 1);
							}

							FlxG.sound.play(Paths.sound(soundToPlay)).pan = note.noteData < 4? -0.3 : 0.3; //would be coolio
							playedSound[data] = true;
						}

						data = note.noteData;
						if(note.mustPress != _song.notes[curSec].mustHitSection)
						{
							data += 4;
						}
					}
				}
			}
		});

		if(metronome.checked && lastConductorPos != Conductor.songPosition) {
			var metroInterval:Float = 60 / metronomeStepper.value;
			var metroStep:Int = Math.floor(((Conductor.songPosition + metronomeOffsetStepper.value) / metroInterval) / 1000);
			var lastMetroStep:Int = Math.floor(((lastConductorPos + metronomeOffsetStepper.value) / metroInterval) / 1000);
			if(metroStep != lastMetroStep) {
				FlxG.sound.play(Paths.sound('metronome'));
				//trace('Ticked');
			}
		}
		lastConductorPos = Conductor.songPosition;
		super.update(elapsed);
		sliderTime.valueLabel.text = Std.string(FlxStringUtil.formatTime(Math.max(FlxG.sound.music.time / 1000, 0), true));
	}

	function updateZoom() {
		var daZoom:Float = zoomList[curZoom];
		var zoomThing:String = '1 / ' + daZoom;
		if(daZoom < 1) zoomThing = Math.round(1 / daZoom) + ' / 1';
		zoomTxt.text = 'Zoom: ' + zoomThing;
		reloadGridLayer();
	}

	/*
	function loadAudioBuffer() {
		if(audioBuffers[0] != null) {
			audioBuffers[0].dispose();
		}
		audioBuffers[0] = null;
		#if MODS_ALLOWED
		if(FileSystem.exists(Paths.modFolders('songs/' + currentSongName + '/Inst.ogg'))) {
			audioBuffers[0] = AudioBuffer.fromFile(Paths.modFolders('songs/' + currentSongName + '/Inst.ogg'));
			//trace('Custom vocals found');
		}
		else { #end
			var leVocals:String = Paths.getPath(currentSongName + '/Inst.' + Paths.SOUND_EXT, SOUND, 'songs');
			if (OpenFlAssets.exists(leVocals)) { //Vanilla inst
				audioBuffers[0] = AudioBuffer.fromFile('./' + leVocals.substr(6));
				//trace('Inst found');
			}
		#if MODS_ALLOWED
		}
		#end

		if(audioBuffers[1] != null) {
			audioBuffers[1].dispose();
		}
		audioBuffers[1] = null;
		#if MODS_ALLOWED
		if(FileSystem.exists(Paths.modFolders('songs/' + currentSongName + '/Voices.ogg'))) {
			audioBuffers[1] = AudioBuffer.fromFile(Paths.modFolders('songs/' + currentSongName + '/Voices.ogg'));
			//trace('Custom vocals found');
		} else { #end
			var leVocals:String = Paths.getPath(currentSongName + '/Voices.' + Paths.SOUND_EXT, SOUND, 'songs');
			if (OpenFlAssets.exists(leVocals)) { //Vanilla voices
				audioBuffers[1] = AudioBuffer.fromFile('./' + leVocals.substr(6));
				//trace('Voices found, LETS FUCKING GOOOO');
			}
		#if MODS_ALLOWED
		}
		#end
	}
	*/

	var lastSecBeats:Float = 0;
	var lastSecBeatsNext:Float = 0;
	function reloadGridLayer() {
		gridLayer.clear();
		eventGrid = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE, Std.int(GRID_SIZE * getSectionBeats() * 4 * zoomList[curZoom]), true, 0xFFB3B3B3, 0xFF7D7D7D);
		eventGrid.x = LANE_OFF;
		leftGrid = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * 4, Std.int(eventGrid.height), true, 0xFFB3B3B3, 0xFF7D7D7D);
		leftGrid.x = Std.int(eventGrid.x + eventGrid.width + 20);
		rightGrid = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * 4, Std.int(eventGrid.height), true, 0xFFB3B3B3, 0xFF7D7D7D);
		rightGrid.x = Std.int(leftGrid.x + leftGrid.width + 20);		
		
		eventGrid.alpha = 0.75;	
		leftGrid.alpha = 0.75;
		rightGrid.alpha = 0.75;

		#if desktop
		if(FlxG.save.data.chart_waveformInst || FlxG.save.data.chart_waveformPVoices || FlxG.save.data.chart_waveformOVoices) {
			updateWaveform();
		}
		#end

		var leHeight:Int = Std.int(eventGrid.height);
		var foundPrevSec:Bool = false;
		if(sectionStartTime() > 0)
		{
			prevEventGrid = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE, Std.int(GRID_SIZE * getSectionBeats(curSec + 1) * 4 * zoomList[curZoom]), true, 0xFFB3B3B3, 0xFF7D7D7D);
			prevLeftGrid = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * 4, Std.int(GRID_SIZE * getSectionBeats(curSec + 1) * 4 * zoomList[curZoom]), true, 0xFFB3B3B3, 0xFF7D7D7D);
			prevRightGrid = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * 4, Std.int(GRID_SIZE * getSectionBeats(curSec + 1) * 4 * zoomList[curZoom]), true, 0xFFB3B3B3, 0xFF7D7D7D);

			prevEventGrid.alpha = 0.3;
			prevLeftGrid.alpha = 0.3;
			prevRightGrid.alpha = 0.3;

			leHeight += Std.int(prevEventGrid.height);
			foundPrevSec = true;
		} else  {
			prevEventGrid = new FlxSprite().makeGraphic(1, 1, FlxColor.TRANSPARENT);
			prevLeftGrid = new FlxSprite().makeGraphic(1, 1, FlxColor.TRANSPARENT);
			prevRightGrid = new FlxSprite().makeGraphic(1, 1, FlxColor.TRANSPARENT);
		}
		prevEventGrid.x = eventGrid.x;
		prevLeftGrid.x = leftGrid.x;
		prevRightGrid.x = rightGrid.x;
		prevEventGrid.y = eventGrid.y - prevEventGrid.height;
		prevLeftGrid.y = prevEventGrid.y;
		prevRightGrid.y = prevEventGrid.y;

		var foundNextSec:Bool = false;
		if(sectionStartTime(1) <= FlxG.sound.music.length)
		{
			nextEventGrid = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE, Std.int(GRID_SIZE * getSectionBeats(curSec + 1) * 4 * zoomList[curZoom]), true, 0xFFB3B3B3, 0xFF7D7D7D);
			nextLeftGrid = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * 4, Std.int(GRID_SIZE * getSectionBeats(curSec + 1) * 4 * zoomList[curZoom]), true, 0xFFB3B3B3, 0xFF7D7D7D);
			nextRightGrid = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * 4, Std.int(GRID_SIZE * getSectionBeats(curSec + 1) * 4 * zoomList[curZoom]), true, 0xFFB3B3B3, 0xFF7D7D7D);			

			nextEventGrid.alpha = 0.3;
			nextLeftGrid.alpha = 0.3;
			nextRightGrid.alpha = 0.3;
			
			leHeight += Std.int(nextEventGrid.height);
			foundNextSec = true;
		} else  {
			nextEventGrid = new FlxSprite().makeGraphic(1, 1, FlxColor.TRANSPARENT);
			nextLeftGrid = new FlxSprite().makeGraphic(1, 1, FlxColor.TRANSPARENT);
			nextRightGrid = new FlxSprite().makeGraphic(1, 1, FlxColor.TRANSPARENT);
		}
		nextEventGrid.x = eventGrid.x;
		nextLeftGrid.x = leftGrid.x;
		nextRightGrid.x = rightGrid.x;
		nextEventGrid.y = eventGrid.height;
		nextLeftGrid.y = nextEventGrid.y;
		nextRightGrid.y = nextEventGrid.y;
		
		gridLayer.add(prevEventGrid);
		gridLayer.add(prevLeftGrid);
		gridLayer.add(prevRightGrid);
		gridLayer.add(nextEventGrid);
		gridLayer.add(nextLeftGrid);
		gridLayer.add(nextRightGrid);
		gridLayer.add(eventGrid);
		gridLayer.add(leftGrid);
		gridLayer.add(rightGrid);

		var gridWhiteLine:FlxSprite = new FlxSprite(eventGrid.x - 2, foundPrevSec ? -prevEventGrid.height : 0).makeGraphic(2, leHeight, FlxColor.WHITE);
		gridLayer.add(gridWhiteLine);
		var gridWhiteLine:FlxSprite = new FlxSprite(eventGrid.x + eventGrid.width, foundPrevSec ? -prevEventGrid.height : 0).makeGraphic(2, leHeight, FlxColor.WHITE);
		gridLayer.add(gridWhiteLine);
		var gridWhiteLine:FlxSprite = new FlxSprite(leftGrid.x - 2, foundPrevSec ? -prevEventGrid.height : 0).makeGraphic(2, leHeight, FlxColor.WHITE);
		gridLayer.add(gridWhiteLine);
		var gridWhiteLine:FlxSprite = new FlxSprite(leftGrid.x + leftGrid.width, foundPrevSec ? -prevEventGrid.height : 0).makeGraphic(2, leHeight, FlxColor.WHITE);
		gridLayer.add(gridWhiteLine);
		var gridWhiteLine:FlxSprite = new FlxSprite(rightGrid.x - 2, foundPrevSec ? -prevEventGrid.height : 0).makeGraphic(2, leHeight, FlxColor.WHITE);
		gridLayer.add(gridWhiteLine);
		var gridWhiteLine:FlxSprite = new FlxSprite(rightGrid.x + rightGrid.width, foundPrevSec ? -prevEventGrid.height : 0).makeGraphic(2, leHeight, FlxColor.WHITE);
		gridLayer.add(gridWhiteLine);

		var beatsuh:Int = Std.int(getSectionBeats());
		for (i in 1...beatsuh) {
			var beatsep0:FlxSprite = new FlxSprite(eventGrid.x, ((GRID_SIZE * (2 * curZoom)) * i) - 1).makeGraphic(Std.int(eventGrid.width), 2, 0x7AFF0000);
			gridLayer.add(beatsep0);
			var beatsep1:FlxSprite = new FlxSprite(leftGrid.x, ((GRID_SIZE * (2 * curZoom)) * i) - 1).makeGraphic(Std.int(leftGrid.width), 2, 0x7AFF0000);
			gridLayer.add(beatsep1);
			var beatsep2:FlxSprite = new FlxSprite(rightGrid.x, ((GRID_SIZE * (2 * curZoom)) * i) - 1).makeGraphic(Std.int(rightGrid.width), 2, 0x7AFF0000);
			gridLayer.add(beatsep2);
		}

		updateGrid();

		lastSecBeats = getSectionBeats();
		if(sectionStartTime(1) > FlxG.sound.music.length) lastSecBeatsNext = 0;
		else getSectionBeats(curSec + 1);
	}

	function strumLineUpdateY()
	{
		strumLine.y = getYfromStrum((Conductor.songPosition - sectionStartTime()) / zoomList[curZoom] % (Conductor.stepCrochet * 16)) / (getSectionBeats() / 4);
	}

	var waveformPrinted:Bool = true;
	var wavData:Array<Array<Array<Float>>> = [[[0], [0]], [[0], [0]]];
	function updateWaveform() {
		#if desktop
		if(waveformPrinted) {
			waveformSprite.makeGraphic(Std.int(GRID_SIZE * 8.5), Std.int(eventGrid.height), 0x00FFFFFF);
			waveformSprite.pixels.fillRect(new Rectangle(0, 0, GRID_SIZE * 8.5, eventGrid.height), 0x00FFFFFF);
		}
		waveformPrinted = false;

		if(!FlxG.save.data.chart_waveformInst && !FlxG.save.data.chart_waveformPVoices && !FlxG.save.data.chart_waveformOVoices) {
			//trace('Epic fail on the waveform lol');
			return;
		}

		wavData[0][0] = [];
		wavData[0][1] = [];
		wavData[1][0] = [];
		wavData[1][1] = [];

		var steps:Int = Math.round(getSectionBeats() * 4);
		var st:Float = sectionStartTime();
		var et:Float = st + (Conductor.stepCrochet * steps);

		@:privateAccess {
		if (FlxG.save.data.chart_waveformInst) {
			var sound:FlxSound = FlxG.sound.music;
			if (sound._sound != null && sound._sound.__buffer != null) {
				var bytes:Bytes = sound._sound.__buffer.data.toBytes();

				wavData = waveformData(
					sound._sound.__buffer,
					bytes,
					st,
					et,
					1,
					wavData,
					Std.int(eventGrid.height)
				);
			}
		}

		if (FlxG.save.data.chart_waveformPVoices) {
			var sound:FlxSound = pvocals;
			if (sound._sound != null && sound._sound.__buffer != null) {
				var bytes:Bytes = sound._sound.__buffer.data.toBytes();

				wavData = waveformData(
					sound._sound.__buffer,
					bytes,
					st,
					et,
					1,
					wavData,
					Std.int(eventGrid.height)
				);
			}
		}

		if (FlxG.save.data.chart_waveformOVoices) {
			var sound:FlxSound = ovocals;
			if (sound._sound != null && sound._sound.__buffer != null) {
				var bytes:Bytes = sound._sound.__buffer.data.toBytes();

				wavData = waveformData(
					sound._sound.__buffer,
					bytes,
					st,
					et,
					1,
					wavData,
					Std.int(eventGrid.height)
				);
			}
		}
	}

		// Draws
		var gSize:Int = Std.int(GRID_SIZE * 8.5);
		var hSize:Int = Std.int(GRID_SIZE * 4);

		var lmin:Float = 0;
		var lmax:Float = 0;

		var rmin:Float = 0;
		var rmax:Float = 0;

		var size:Float = 1;

		var leftLength:Int = (
			wavData[0][0].length > wavData[0][1].length ? wavData[0][0].length : wavData[0][1].length
		);

		var rightLength:Int = (
			wavData[1][0].length > wavData[1][1].length ? wavData[1][0].length : wavData[1][1].length
		);

		var length:Int = leftLength > rightLength ? leftLength : rightLength;

		var index:Int;
		for (i in 0...length) {
			index = i;

			lmin = FlxMath.bound(((index < wavData[0][0].length && index >= 0) ? wavData[0][0][index] : 0) * (gSize / 1.12), -hSize, hSize) / 2;
			lmax = FlxMath.bound(((index < wavData[0][1].length && index >= 0) ? wavData[0][1][index] : 0) * (gSize / 1.12), -hSize, hSize) / 2;

			rmin = FlxMath.bound(((index < wavData[1][0].length && index >= 0) ? wavData[1][0][index] : 0) * (gSize / 1.12), -hSize, hSize) / 2;
			rmax = FlxMath.bound(((index < wavData[1][1].length && index >= 0) ? wavData[1][1][index] : 0) * (gSize / 1.12), -hSize, hSize) / 2;

			waveformSprite.pixels.fillRect(new Rectangle(hSize - (lmin + rmin), i * size, (lmin + rmin) + (lmax + rmax), size), FlxColor.BLUE);
		}

		waveformPrinted = true;
		#end
	}

	function waveformData(buffer:AudioBuffer, bytes:Bytes, time:Float, endTime:Float, multiply:Float = 1, ?array:Array<Array<Array<Float>>>, ?steps:Float):Array<Array<Array<Float>>>
	{
		#if (lime_cffi && !macro)
		if (buffer == null || buffer.data == null) return [[[0], [0]], [[0], [0]]];

		var khz:Float = (buffer.sampleRate / 1000);
		var channels:Int = buffer.channels;

		var index:Int = Std.int(time * khz);

		var samples:Float = ((endTime - time) * khz);

		if (steps == null) steps = 1280;

		var samplesPerRow:Float = samples / steps;
		var samplesPerRowI:Int = Std.int(samplesPerRow);

		var gotIndex:Int = 0;

		var lmin:Float = 0;
		var lmax:Float = 0;

		var rmin:Float = 0;
		var rmax:Float = 0;

		var rows:Float = 0;

		var simpleSample:Bool = true;//samples > 17200;
		var v1:Bool = false;

		if (array == null) array = [[[0], [0]], [[0], [0]]];

		while (index < (bytes.length - 1)) {
			if (index >= 0) {
				var byte:Int = bytes.getUInt16(index * channels * 2);

				if (byte > 65535 / 2) byte -= 65535;

				var sample:Float = (byte / 65535);

				if (sample > 0) {
					if (sample > lmax) lmax = sample;
				} else if (sample < 0) {
					if (sample < lmin) lmin = sample;
				}

				if (channels >= 2) {
					byte = bytes.getUInt16((index * channels * 2) + 2);

					if (byte > 65535 / 2) byte -= 65535;

					sample = (byte / 65535);

					if (sample > 0) {
						if (sample > rmax) rmax = sample;
					} else if (sample < 0) {
						if (sample < rmin) rmin = sample;
					}
				}
			}

			v1 = samplesPerRowI > 0 ? (index % samplesPerRowI == 0) : false;
			while (simpleSample ? v1 : rows >= samplesPerRow) {
				v1 = false;
				rows -= samplesPerRow;

				gotIndex++;

				var lRMin:Float = Math.abs(lmin) * multiply;
				var lRMax:Float = lmax * multiply;

				var rRMin:Float = Math.abs(rmin) * multiply;
				var rRMax:Float = rmax * multiply;

				if (gotIndex > array[0][0].length) array[0][0].push(lRMin);
					else array[0][0][gotIndex - 1] = array[0][0][gotIndex - 1] + lRMin;

				if (gotIndex > array[0][1].length) array[0][1].push(lRMax);
					else array[0][1][gotIndex - 1] = array[0][1][gotIndex - 1] + lRMax;

				if (channels >= 2) {
					if (gotIndex > array[1][0].length) array[1][0].push(rRMin);
						else array[1][0][gotIndex - 1] = array[1][0][gotIndex - 1] + rRMin;

					if (gotIndex > array[1][1].length) array[1][1].push(rRMax);
						else array[1][1][gotIndex - 1] = array[1][1][gotIndex - 1] + rRMax;
				}
				else {
					if (gotIndex > array[1][0].length) array[1][0].push(lRMin);
						else array[1][0][gotIndex - 1] = array[1][0][gotIndex - 1] + lRMin;

					if (gotIndex > array[1][1].length) array[1][1].push(lRMax);
						else array[1][1][gotIndex - 1] = array[1][1][gotIndex - 1] + lRMax;
				}

				lmin = 0;
				lmax = 0;

				rmin = 0;
				rmax = 0;
			}

			index++;
			rows++;
			if(gotIndex > steps) break;
		}

		return array;
		#else
		return [[[0], [0]], [[0], [0]]];
		#end
	}
	function changeNoteSustain(value:Float, ?note):Void
	{
		if(note == null) note = curSelectedNote;
		if(note == null) return;
		setNoteSustain(note[2]+value);
	}
	
	function setNoteSustain(value:Float, ?note):Void
	{
		if(note == null) note = curSelectedNote;

		if (note != null)
		{
			if (note[2] != null)
			{
				note[2] = Math.max(value, 0);
			}
		}

		updateNoteUI();
		updateGrid();
	}
	
	function recalculateSteps(add:Float = 0):Int
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (FlxG.sound.music.time > Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		curStep = lastChange.stepTime + Math.floor((FlxG.sound.music.time - lastChange.songTime + add) / Conductor.stepCrochet);
		updateBeat();

		return curStep;
	}

	function resetSection(songBeginning:Bool = false):Void
	{
		updateGrid();

		FlxG.sound.music.pause();
		// Basically old shit from changeSection???
		FlxG.sound.music.time = sectionStartTime();

		if (songBeginning)
		{
			FlxG.sound.music.time = 0;
			curSec = 0;
		}

		if(pvocals != null) {
			pvocals.pause();
			pvocals.time = FlxG.sound.music.time;
		}
		if(ovocals != null) {
			ovocals.pause();
			ovocals.time = FlxG.sound.music.time;
		}
		updateCurStep();

		updateGrid();
		updateSectionUI();
		updateWaveform();
	}

	function changeSection(sec:Int = 0, ?updateMusic:Bool = true):Void
	{
		if (_song.notes[sec] != null)
		{
			curSec = sec;
			if (updateMusic)
			{
				FlxG.sound.music.pause();

				FlxG.sound.music.time = sectionStartTime();
				if(pvocals != null) {
					pvocals.pause();
					pvocals.time = FlxG.sound.music.time;
				}
				if(ovocals != null) {
					ovocals.pause();
					ovocals.time = FlxG.sound.music.time;
				}
				updateCurStep();
			}

			var blah1:Float = getSectionBeats();
			var blah2:Float = getSectionBeats(curSec + 1);
			if(sectionStartTime(1) > FlxG.sound.music.length) blah2 = 0;
	
			if(blah1 != lastSecBeats || blah2 != lastSecBeatsNext)
			{
				reloadGridLayer();
			}
			else
			{
				updateGrid();
			}
			updateSectionUI();
		}
		else
		{
			changeSection();
		}
		Conductor.songPosition = FlxG.sound.music.time;
		updateWaveform();
	}

	function updateSectionUI():Void
	{
		var sec = _song.notes[curSec];

		stepperBeats.value = getSectionBeats();
		check_mustHitSection.checked = sec.mustHitSection;
		check_gfSection.checked = sec.gfSection;
		check_duetSection.checked = sec.duetSection;
		check_altAnim.checked = sec.altAnim;
		check_changeBPM.checked = sec.changeBPM;
		stepperSectionBPM.value = sec.bpm;

		updateHeads();
	}

	function updateHeads():Void
	{
		var healthIconP1:String = loadHealthIconFromCharacter(_song.player1);
		var healthIconP2:String = loadHealthIconFromCharacter(_song.player2);
		var oppHasNotes:Bool = false;
		var focNoteCount:Int = 0;
		var nonNoteCount:Int = 0;
		for (i in _song.notes[curSec].sectionNotes) {
			if (i[1] > 3) {
				oppHasNotes = true;
				nonNoteCount++;
			} else {
				focNoteCount++;
			}
		}
		var bpmSpeed:Float = (60 / Conductor.bpm) / playbackSpeed;
		if (_song.notes[curSec].mustHitSection) {
			leftIcon.changeIcon(healthIconP1);
			rightIcon.changeIcon(healthIconP2);
			if (_song.notes[curSec].gfSection) leftIcon.changeIcon(_song.gfVersion);
		} else {
			leftIcon.changeIcon(healthIconP2);
			rightIcon.changeIcon(healthIconP1);
			if (_song.notes[curSec].gfSection) leftIcon.changeIcon(_song.gfVersion);
		}
		
		FlxTween.tween(leftIcon, {alpha: 1, "scale.x": 0.45, "scale.y": 0.45}, bpmSpeed / 2, {ease: FlxEase.quadInOut, onComplete: function(twn:FlxTween) {leftIcon.animation.curAnim.curFrame = 0;}});
		if ((nonNoteCount < focNoteCount - 4 && nonNoteCount < 8) || !oppHasNotes)
			FlxTween.tween(rightIcon, {alpha: 0.6, "scale.x": 0.45 * 0.9, "scale.y": 0.45 * 0.9}, bpmSpeed / 2, {ease: FlxEase.quadInOut, onComplete: function(twn:FlxTween) {if (!oppHasNotes) rightIcon.animation.curAnim.curFrame = 1;}});
		else 
			FlxTween.tween(rightIcon, {alpha: 1, "scale.x": 0.45, "scale.y": 0.45}, bpmSpeed / 2, {ease: FlxEase.quadInOut, onComplete: function(twn:FlxTween) {rightIcon.animation.curAnim.curFrame = 0;}});

		var newColor:Int = CoolUtil.dominantColor(leftIcon);
		if(newColor != intendedColor) {
			if(colorTween != null) 
				colorTween.cancel();
			intendedColor = newColor;
			colorTween = FlxTween.color(bgcolour, bpmSpeed / 2, bgcolour.color, intendedColor, {
				onComplete: function(twn:FlxTween) {
					colorTween = null;
				}
			});
		}
	}

	function loadHealthIconFromCharacter(char:String) {
		var characterPath:String = 'characters/' + char + '.json';
		#if MODS_ALLOWED
		var path:String = Paths.modFolders(characterPath);
		if (!FileSystem.exists(path)) {
			path = Paths.getPreloadPath(characterPath);
		}

		if (!FileSystem.exists(path))
		#else
		var path:String = Paths.getPreloadPath(characterPath);
		if (!OpenFlAssets.exists(path))
		#end
		{
			path = Paths.getPreloadPath('characters/' + Character.DEFAULT_CHARACTER + '.json'); //If a character couldn't be found, change him to BF just to prevent a crash
		}

		#if MODS_ALLOWED
		var rawJson = File.getContent(path);
		#else
		var rawJson = OpenFlAssets.getText(path);
		#end

		var json:Character.CharacterFile = cast Json.parse(rawJson);
		return json.healthicon;
	}

	function updateNoteUI():Void
	{
		if (curSelectedNote != null) {
			if(curSelectedNote[2] != null) {
				stepperSusLength.value = curSelectedNote[2];
				if(curSelectedNote[3] != null) {
					currentType = noteTypeMap.get(curSelectedNote[3]);
					if(currentType <= 0) {
						noteTypeDropDown.selectedLabel = '';
					} else {
						noteTypeDropDown.selectedLabel = currentType + '. ' + curSelectedNote[3];
					}
				}
			} else {
				eventDropDown.selectedLabel = curSelectedNote[1][curEventSelected][0];
				var selected:Int = Std.parseInt(eventDropDown.selectedId);
				if(selected > 0 && selected < eventStuff.length) {
					descText.text = eventStuff[selected][1];
				}
				value1InputText.text = curSelectedNote[1][curEventSelected][1];
				value2InputText.text = curSelectedNote[1][curEventSelected][2];
			}
			strumTimeInputText.text = '' + curSelectedNote[0];
		}
	}

	function updateGrid():Void
	{
		curRenderedNotes.clear();
		curRenderedSustains.clear();
		curRenderedNoteType.clear();
		prevRenderedNotes.clear();
		prevRenderedSustains.clear();
		nextRenderedNotes.clear();
		nextRenderedSustains.clear();

		if (_song.notes[curSec].changeBPM && _song.notes[curSec].bpm > 0)
		{
			Conductor.changeBPM(_song.notes[curSec].bpm);
			//trace('BPM of this section:');
		}
		else
		{
			// get last bpm
			var daBPM:Float = _song.bpm;
			for (i in 0...curSec)
				if (_song.notes[i].changeBPM)
					daBPM = _song.notes[i].bpm;
			Conductor.changeBPM(daBPM);
		}

		// CURRENT SECTION
		var beats:Float = getSectionBeats();
		for (i in _song.notes[curSec].sectionNotes)
		{
			var note:Note = setupNoteData(i, false);
			curRenderedNotes.add(note);
			if (note.sustainLength > 0)
			{
				var sus = setupSusNote(i, note, note.sustainLength / Conductor.stepCrochet, false);
				for(sussy in sus)
					curRenderedSustains.add(sussy);
			}

			if(i[3] != null && note.noteType != null && note.noteType.length > 0) {
				var typeInt:Null<Int> = noteTypeMap.get(i[3]);
				var theType:String = '' + typeInt;
				if(typeInt == null) theType = '?';

				var daText:AttachedFlxFixedText = new AttachedFlxFixedText(0, 0, 100, theType, 24);
				daText.setFormat(Paths.font("redd.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				daText.xAdd = -27;
				daText.yAdd = 10;
				daText.borderSize = 1;
				curRenderedNoteType.add(daText);
				daText.sprTracker = note;
			}
			note.mustPress = _song.notes[curSec].mustHitSection;
			if(i[1] > 3) note.mustPress = !note.mustPress;
		}

		// CURRENT EVENTS
		var startThing:Float = sectionStartTime();
		var endThing:Float = sectionStartTime(1);
		for (i in _song.events)
		{
			if(endThing > i[0] && i[0] >= startThing)
			{
				var note:Note = setupNoteData(i, false);
				curRenderedNotes.add(note);

				var text:String = 'Event: ' + note.eventName + ' (' + Math.floor(note.strumTime) + ' ms)' + '\nValue 1: ' + note.eventVal1 + '\nValue 2: ' + note.eventVal2;
				if(note.eventLength > 1) text = note.eventLength + ' Events:\n' + note.eventName;

				var daText:AttachedFlxFixedText = new AttachedFlxFixedText(0, 0, 400, text, 12);
				daText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
				daText.xAdd = -410;
				daText.borderSize = 1;
				if(note.eventLength > 1) daText.yAdd += 8;
				curRenderedNoteType.add(daText);
				daText.sprTracker = note;
				//trace('test: ' + i[0], 'startThing: ' + startThing, 'endThing: ' + endThing);
			}
		}

		// PREV SECTION
		var beats:Float = getSectionBeats(-1);
		if(curSec > 0) {
			for (i in _song.notes[curSec-1].sectionNotes)
			{
				var note:Note = setupNoteData(i, false, true);
				note.alpha = 0.4;
				prevRenderedNotes.add(note);
				if (note.sustainLength > 0)
				{
					var sus = setupSusNote(i, note, note.sustainLength / Conductor.stepCrochet, false, true);
					for(sussy in sus)
						prevRenderedSustains.add(sussy);
				}
			}
		}

		// PREV EVENTS
		var startThing:Float = sectionStartTime(-1);
		var endThing:Float = sectionStartTime();
		for (i in _song.events)
		{
			if(endThing > i[0] && i[0] >= startThing)
			{
				var note:Note = setupNoteData(i, false, true);
				note.alpha = 0.4;
				prevRenderedNotes.add(note);
			}
		}

		// NEXT SECTION
		var beats:Float = getSectionBeats(1);
		if(curSec < _song.notes.length-1) {
			for (i in _song.notes[curSec+1].sectionNotes)
			{
				var note:Note = setupNoteData(i, true);
				note.alpha = 0.4;
				nextRenderedNotes.add(note);
				if (note.sustainLength > 0)
				{
					var sus = setupSusNote(i, note, note.sustainLength / Conductor.stepCrochet, true);
					for(sussy in sus)
						nextRenderedSustains.add(sussy);
				}
			}
		}

		// NEXT EVENTS
		var startThing:Float = sectionStartTime(1);
		var endThing:Float = sectionStartTime(2);
		for (i in _song.events)
		{
			if(endThing > i[0] && i[0] >= startThing)
			{
				var note:Note = setupNoteData(i, true);
				note.alpha = 0.6;
				nextRenderedNotes.add(note);
			}
		}
	}

	function setupNoteData(i:Array<Dynamic>, isNextSection:Bool, isPrevSection:Bool = false):Note
	{
		var daNoteInfo = i[1];
		var daStrumTime = i[0];
		var daSus:Dynamic = i[2];

		var note:Note = new Note(daStrumTime, daNoteInfo % 4, null, null, true);
		if(daSus != null) { //Common note
			if(!Std.isOfType(i[3], String)) //Convert old note type to new note type format
			{
				i[3] = noteTypeIntMap.get(i[3]);
			}
			if(i.length > 3 && (i[3] == null || i[3].length < 1))
			{
				i.remove(i[3]);
			}
			note.sustainLength = daSus;
			note.noteType = i[3];
		} else { //Event note
			note.loadGraphic(Paths.image('eventArrow'));
			note.eventName = getEventName(i[1]);
			note.eventLength = i[1].length;
			if(i[1].length < 2)
			{
				note.eventVal1 = i[1][0][1];
				note.eventVal2 = i[1][0][2];
			}
			note.noteData = -1;
			daNoteInfo = -1;
		}

		note.setGraphicSize(GRID_SIZE, GRID_SIZE);
		note.updateHitbox();
		note.x = Math.floor(GRID_SIZE * (daNoteInfo + 1) + 20) + LANE_OFF;
		if(daNoteInfo > 3) note.x += 20;
		if (daSus == null) note.x -= 20;
		if((isNextSection && _song.notes[curSec].mustHitSection != _song.notes[curSec+1].mustHitSection) || (isPrevSection && _song.notes[curSec].mustHitSection != _song.notes[curSec-1].mustHitSection)) {
			if(daNoteInfo > 3) {
				note.x -= (GRID_SIZE * 4) + 20;
			} else if(daSus != null) {
				note.x += (GRID_SIZE * 4) + 20;
			}
		}

		var beats:Float = getSectionBeats(isNextSection ? 1 : 0);
		if (isPrevSection) beats = getSectionBeats(-1);
		note.y = getYfromStrumNotes(daStrumTime - sectionStartTime(), beats);
		//if(isNextSection) note.y += eventGrid.height;
		return note;
	}

	function getEventName(names:Array<Dynamic>):String
	{
		var retStr:String = '';
		var addedOne:Bool = false;
		for (i in 0...names.length)
		{
			if(addedOne) retStr += ', ';
			retStr += names[i][0];
			addedOne = true;
		}
		return retStr;
	}

	function setupSusNote(i:Array<Dynamic>, baseNote:Note, daSus:Float, isNextSection:Bool, isPrevSection:Bool = false){
		var daNoteInfo = i[1];
		var daStrumTime = i[0];
		var sus:Array<Note> = [];
		var oldNote:Note = baseNote;
		var swagNote = baseNote;
  		var func = Math.round;
		for (susNote in 0...func(daSus))
		{
			var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + Conductor.stepCrochet, daNoteInfo % 4, oldNote, true, true);
			sustainNote.setGraphicSize(GRID_SIZE, GRID_SIZE);
			sustainNote.updateHitbox();
			sustainNote.x = Math.floor(GRID_SIZE * (daNoteInfo + 1) + 20) + LANE_OFF;
			sustainNote.y = oldNote.y + GRID_SIZE;
			sustainNote.flipY = false;
			sustainNote.scale.y = 1;
			sustainNote.noteType = swagNote.noteType;
			sustainNote.parent = swagNote;
			oldNote = sustainNote;
			sus.push(sustainNote);
		}
		for(i in sus){
			switch(i.noteType){
				default:
					if(i.animation.curAnim!=null && i.animation.curAnim.name.endsWith("end") ){
						i.setGraphicSize(Std.int(GRID_SIZE*.35), Std.int((GRID_SIZE)/2)+2);
						i.updateHitbox();
						i.offset.x = 5;
						i.offset.y = (GRID_SIZE)/2+2;
					}else{
						i.setGraphicSize(Std.int(GRID_SIZE*.35), GRID_SIZE+1);
						i.updateHitbox();
						i.offset.x = 5;					
					}

					i.x = Math.floor(GRID_SIZE * (daNoteInfo + 1) + 20) + LANE_OFF;
					if(daNoteInfo > 3) i.x += 20;
					if((isNextSection && _song.notes[curSec].mustHitSection != _song.notes[curSec+1].mustHitSection) || (isPrevSection && _song.notes[curSec].mustHitSection != _song.notes[curSec-1].mustHitSection)) {
						if(daNoteInfo > 3) {
							i.x -= (GRID_SIZE * 4) + 20;
						} else {
							i.x += (GRID_SIZE * 4) + 20;
						}
					}
				}
		}
		return sus;
	}

	private function addSection(sectionBeats:Float = 4):Void
	{
		var sec:SwagSection = {
			sectionBeats: sectionBeats,
			bpm: _song.bpm,
			changeBPM: false,
			mustHitSection: true,
			gfSection: false,
			duetSection: false,
			sectionNotes: [],
			typeOfSection: 0,
			altAnim: false
		};

		_song.notes.push(sec);
	}

	function selectNote(note:Note):Void
	{
		var noteDataToCheck:Int = note.noteData;

		if(noteDataToCheck > -1)
		{
			if(note.mustPress != _song.notes[curSec].mustHitSection) noteDataToCheck += 4;
			for (i in _song.notes[curSec].sectionNotes)
			{
				if (i != curSelectedNote && i.length > 2 && i[0] == note.strumTime && i[1] == noteDataToCheck)
				{
					curSelectedNote = i;
					lastMousePos.set(dummyArrow.x,dummyArrow.y);
					if(FlxG.mouse.pressed)
						recentNote = i;
					break;
				}
			}
		}
		else
		{
			for (i in _song.events)
			{
				if(i != curSelectedNote && i[0] == note.strumTime)
				{
					curSelectedNote = i;
					curEventSelected = Std.int(curSelectedNote[1].length) - 1;
					break;
				}
			}
		}
		changeEventSelected();

		updateGrid();
		updateNoteUI();
	}

	function deleteNote(note:Note):Void
	{
		var noteDataToCheck:Int = note.noteData;
		if(noteDataToCheck > -1 && note.mustPress != _song.notes[curSec].mustHitSection) noteDataToCheck += 4;

		if(note.noteData > -1) //Normal Notes
		{
			for (i in _song.notes[curSec].sectionNotes)
			{
				if (i[0] == note.strumTime && i[1] == noteDataToCheck)
				{
					if(i == curSelectedNote) curSelectedNote = null;
					//FlxG.log.add('FOUND EVIL NOTE');
					_song.notes[curSec].sectionNotes.remove(i);
					break;
				}
			}
		}
		else //Events
		{
			for (i in _song.events)
			{
				if(i[0] == note.strumTime)
				{
					if(i == curSelectedNote)
					{
						curSelectedNote = null;
						changeEventSelected();
					}
					//FlxG.log.add('FOUND EVIL EVENT');
					_song.events.remove(i);
					break;
				}
			}
		}

		updateGrid();
	}

	public function doANoteThing(cs, d, style){
		var delnote = false;
		if(strumLineNotes.members[d].overlaps(curRenderedNotes))
		{
			curRenderedNotes.forEachAlive(function(note:Note)
			{
				if (note.overlapsPoint(new FlxPoint(strumLineNotes.members[d].x + 1,strumLine.y+1)) && note.noteData == d%4)
				{
						//trace('tryin to delete note...');
						if(!delnote) deleteNote(note);
						delnote = true;
				}
			});
		}

		if (!delnote){
			addNote(false, cs, d, style);
		}
	}
	function clearSong():Void
	{
		for (daSection in 0..._song.notes.length)
		{
			_song.notes[daSection].sectionNotes = [];
		}

		updateGrid();
	}

	private function addNote(rightClick:Bool = false, strum:Null<Float> = null, data:Null<Int> = null, type:Null<Int> = null):Void
	{
		//curUndoIndex++;
		//var newsong = _song.notes;
		//	undos.push(newsong);
		var noteStrum = getStrumTime(dummyArrow.y * (getSectionBeats() / 4), false) + sectionStartTime();
		var noteData = Math.floor((FlxG.mouse.x - LANE_OFF - GRID_SIZE) / GRID_SIZE);
		if (FlxG.mouse.x >= rightGrid.x) noteData = Math.floor((FlxG.mouse.x - LANE_OFF - (GRID_SIZE * 2)) / GRID_SIZE);
		else if (FlxG.mouse.x >= leftGrid.x) noteData = Math.floor((FlxG.mouse.x - LANE_OFF - (GRID_SIZE * 1.5)) / GRID_SIZE);

		var noteSus = 0;
		var daAlt = false;
		var daType = currentType;
		if (leftClickType < displayNameList.length && !rightClick)
			daType = leftClickType;
		else if (rightClickType < displayNameList.length && rightClick)
			daType = rightClickType;

		if (strum != null) noteStrum = strum;
		if (data != null) noteData = data;
		if (type != null) daType = type;

		if(noteData > -1)
		{
			_song.notes[curSec].sectionNotes.push([noteStrum, noteData, noteSus, noteTypeIntMap.get(daType)]);
			curSelectedNote = _song.notes[curSec].sectionNotes[_song.notes[curSec].sectionNotes.length - 1];
		}
		else
		{
			var event = eventStuff[Std.parseInt(eventDropDown.selectedId)][0];
			var text1 = value1InputText.text;
			var text2 = value2InputText.text;
			_song.events.push([noteStrum, [[event, text1, text2]]]);
			curSelectedNote = _song.events[_song.events.length - 1];
			curEventSelected = 0;
		}
		changeEventSelected();

		recentNote = curSelectedNote;

		if (FlxG.keys.pressed.CONTROL && noteData > -1)
		{
			_song.notes[curSec].sectionNotes.push([noteStrum, (noteData + 4) % 8, noteSus, noteTypeIntMap.get(daType)]);
		}

		//trace(noteData + ', ' + noteStrum + ', ' + curSec);
		strumTimeInputText.text = '' + curSelectedNote[0];

		updateGrid();
		updateNoteUI();
	}

	// will figure this out l8r
	function redo()
	{
		//_song = redos[curRedoIndex];
	}

	function undo()
	{
		//redos.push(_song);
		undos.pop();
		//_song.notes = undos[undos.length - 1];
		///trace(_song.notes);
		//updateGrid();
	}

	function getStrumTime(yPos:Float, doZoomCalc:Bool = true):Float
	{
		var leZoom:Float = zoomList[curZoom];
		if(!doZoomCalc) leZoom = 1;
		return FlxMath.remapToRange(yPos, eventGrid.y, eventGrid.y + eventGrid.height * leZoom, 0, 16 * Conductor.stepCrochet);
	}

	function getYfromStrum(strumTime:Float, doZoomCalc:Bool = true):Float
	{
		var leZoom:Float = zoomList[curZoom];
		if(!doZoomCalc) leZoom = 1;
		return FlxMath.remapToRange(strumTime, 0, 16 * Conductor.stepCrochet, eventGrid.y, eventGrid.y + eventGrid.height * leZoom);
	}
	
	function getYfromStrumNotes(strumTime:Float, beats:Float):Float
	{
		var value:Float = strumTime / (beats * 4 * Conductor.stepCrochet);
		return GRID_SIZE * beats * 4 * zoomList[curZoom] * value + eventGrid.y;
	}

	function getNotes():Array<Dynamic>
	{
		var noteData:Array<Dynamic> = [];

		for (i in _song.notes)
		{
			noteData.push(i.sectionNotes);
		}

		return noteData;
	}

	function loadJson(song:String):Void
	{
		if (CoolUtil.defaultDifficulty != curDifficulty)
			PlayState.SONG = Song.loadFromJson(song.toLowerCase() + "-" + curDifficulty.toLowerCase(), song.toLowerCase());
		else
			PlayState.SONG = Song.loadFromJson(song.toLowerCase(), song.toLowerCase());
		MusicBeatState.resetState();
	}

	function autosaveSong():Void
	{
		FlxG.save.data.autosave = Json.stringify({
			"song": _song
		});
		FlxG.save.flush();
	}

	function clearEvents() {
		_song.events = [];
		updateGrid();
	}

	private function saveLevel()
	{
		if(_song.events != null && _song.events.length > 1) _song.events.sort(sortByTime);
		var json = {
			"song": _song
		};
		var savedifficulty:String = '';
		var data:String = Json.stringify(json, "\t");
		if (CoolUtil.defaultDifficulty != curDifficulty)
			savedifficulty = "-" + curDifficulty.toLowerCase().replace(' ', '-');
		if ((data != null) && (data.length > 0))
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), Paths.formatToSongPath(_song.song) + savedifficulty + ".json");
		}
	}

	function sortByTime(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);
	}

	private function saveEvents()
	{
		if(_song.events != null && _song.events.length > 1) _song.events.sort(sortByTime);
		var eventsSong:Dynamic = {
			events: _song.events
		};
		var json = {
			"song": eventsSong
		}

		var data:String = Json.stringify(json, "\t");

		if ((data != null) && (data.length > 0))
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), "events.json");
		}
	}

	function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved LEVEL DATA.");
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	function onSaveCancel(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
	 * Called if there is an error while saving the gameplay recording.
	 */
	function onSaveError(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving Level data");
	}

	function getSectionBeats(?section:Null<Int> = null)
	{
		if (section == null) section = curSec;
		var val:Null<Float> = null;
		
		if(_song.notes[section] != null) val = _song.notes[section].sectionBeats;
		return val != null ? val : 4;
	}
}

class AttachedFlxFixedText extends objects.FlxFixedText
{
	public var sprTracker:FlxSprite;
	public var xAdd:Float = 0;
	public var yAdd:Float = 0;

	public function new(X:Float = 0, Y:Float = 0, FieldWidth:Float = 0, ?Text:String, Size:Int = 8, EmbeddedFont:Bool = true) {
		super(X, Y, FieldWidth, Text, Size, EmbeddedFont);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null) {
			setPosition(sprTracker.x + xAdd, sprTracker.y + yAdd);
			angle = sprTracker.angle;
			alpha = sprTracker.alpha;
		}
	}
}