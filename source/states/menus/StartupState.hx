package states.menus;

//THIS ISNT INIT.HX!!!! SIMPLY DECORATIVE FOR WHEN YOU FIRST START UP THE GAME!!!
import openfl.filters.ShaderFilter;
import util.CoolUtil;
import song.Song;
import data.WeekData;
import states.game.PlayState;
import data.ClientPrefs;
import flixel.FlxSprite;
import data.Paths;
import engine.info.Framerate;
import flixel.math.FlxMath;
import flixel.group.FlxSpriteGroup;
import haxe.Timer;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;
import openfl.utils.Assets;
import flixel.addons.transition.FlxTransitionableState;
import flixel.FlxG;
import flixel.text.FlxText;

class StartupMenuIntro extends MusicBeatState
{
	var textField:FlxText;
	var terminalMessages:Array<Dynamic> = [
		["Unable to load MENU.com (Error Code: 1Fh)", 1.1, false],
		["Loading FALLBACK.dll ...", 0.8, false],
		["[----------------------]", 1.35, true],
		["[#---------------------]", 2.47, true],
		["[##--------------------]", 0.9, true],
		["[####------------------]", 2.4, true],
		["[########--------------]", 2.9, true],
		["[################------]", 3.4, true],
		["[####################--]", 1.74, true],
		["[#####################-]", 1.6, true],
		["[######################]", 2.4, true]
	];

	override public function create()
	{
		super.create();

		FlxG.sound.play(Paths.sound('boot'));

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

        Framerate.debugMode = 0;
		FlxG.mouse.visible = false;
		FlxG.sound.soundTrayEnabled = false;

		textField = new FlxText(0, 0, 0, '', 8);
		textField.setFormat(Paths.font('ibm.ttf'), 16, FlxColor.WHITE, FlxTextAlign.LEFT);
		textField.antialiasing = false;

		var textFormat = textField.textField.getTextFormat();
		textFormat.leading = -2;
		textField.textField.setTextFormat(textFormat);
		textField.updateHitbox();
		// textField.setPosition(0, -50);
		add(textField);

		textWait(terminalMessages);
	}

	var lastTextLength:Int;

	var renderTimer = new FlxTimer();
	function renderText(array:Array<Dynamic>, message:Array<Dynamic>)
	{
		function render()
		{
			if (array[array.indexOf(message) - 1] != null ? array[array.indexOf(message) - 1][2] : false)
				textField.text = textField.text.substring(0, lastTextLength);

			textField.text += message[0] + "\n";

			lastTextLength = Std.int(textField.text.length - message[0].length - 1);
		};

		/*if (FlxG.save.data.flashing == true)
			Timer.delay(render, 1);
		else*/
			render();
	}

	var waitTime:Float = 0;

	function textWait(array:Array<Dynamic>)
	{
		for (message in array)
		{
			waitTime += array[array.indexOf(message) - 1] != null ? array[array.indexOf(message) - 1][1] : 0;

			new FlxTimer().start(waitTime, function(_)
			{
				renderText(array, message);

				if (array.indexOf(message) == array.length - 1)
				{
					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;
					FlxG.switchState(new StartupMenuState());
				}
			});
		}
	}
}

class StartupMenuState extends MusicBeatState
{
	var canInteract:Bool = true;
	var settingKey:Bool = false;
	var curMenu:String = 'main';
	var curSelected:Int = 0;
	var selectMax:Int = 1;

	var textPrefix:Array<String> = [
		'',
		'',
		'    ##################',
		'    ##              ##',
		'    ##  QT OS V3.6  ##',
		'    ##              ##',
		'    ##################',
		'',
		''
	];

	var curDisplayText:Array<String> = [];
	var textField:FlxText;

	function renderText(array:Array<String>, ?includePrefix:Bool = true)
	{
		// textprefix is copied to prevent variable weirdness
		if (includePrefix) array = textPrefix.copy().concat(array);
		textField.text = array.join('\n');
		textField.screenCenter();
		textField.x -= 16; // its SLIGHTLY TO THE RIGHT >:[
	}

	var win:FlxSpriteGroup;

	override public function create()
	{
		super.create();

		FlxG.sound.play(Paths.sound('dosBeep'));

		textField = new FlxText(0, 0, 0, '', 8);
		textField.setFormat(Paths.font('ibm.ttf'), 16, FlxColor.WHITE, FlxTextAlign.CENTER);
		textField.antialiasing = false;

		var textFormat = textField.textField.getTextFormat();
		textFormat.leading = -2;
		textField.textField.setTextFormat(textFormat);
		textField.updateHitbox();
		add(textField);

		changeSelection(0);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.DOWN)
			changeSelection(curSelected + 1);
		else if (FlxG.keys.justPressed.UP)
			changeSelection(curSelected - 1);

		if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.SPACE)
		{
			if (!canInteract)
				return;

			switch (curMenu)
			{
				case 'main':
					if (curSelected == 0)
					{
						canInteract = false;
						renderText(['  Loading...'], false);

						//ClientPrefs.saveSettings();
						//ClientPrefs.reloadControls();

                        // uncommented until we get some actual fucking songs
						/* WeekData.reloadWeekFiles(true);
						PlayState.storyPlaylist = [for (song in WeekData.weeksLoaded.get(WeekData.weeksList[0]).songs) song[0]]; // plays the first week
						PlayState.isStoryMode = true;
						PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase(), PlayState.storyPlaylist[0].toLowerCase());
						PlayState.campaignScore = 0;
						PlayState.campaignMisses = 0;
						ThreadHandler.cacheSong(PlayState.SONG.song, PlayState.SONG.needsVoices); */

						new FlxTimer().start(1, (_) ->
						{
							//TitleState.initialized = true;
							//TitleState.closedState = true;
                            Framerate.debugMode = 1;
							FlxG.sound.soundTrayEnabled = true;
							ClientPrefs.hasSeenMinimalMenu = true; // i need you to SHUT UPPPP

							//FlxG.sound.playMusic(Paths.music('freakyMenu'));
                            // redirects to titlestate until we get songs
							MusicBeatState.switchState(new TitleState());
						});
					}
					else
					{
						curMenu = 'options';
						selectMax = 9;
						changeSelection(0);
					}
				case 'options':
					switch (curSelected) {
						case 4:
							ClientPrefs.downScroll = !ClientPrefs.downScroll;
						case 5:
							ClientPrefs.flashing = !ClientPrefs.flashing;
						case 6:
						case 7:
							ClientPrefs.gpuCache = !ClientPrefs.gpuCache;
						case 8:
							curMenu = 'main';
							selectMax = 1;
						default:
							new FlxTimer().start(0.001, (_) -> {settingKey = true; changeSelection(lastSelected);}); // delays it a bit so the enter key press doesnt register
					}
					if (curSelected >= 4)
						changeSelection(lastSelected);
			}
		}

		if (curSelected == 6) {
			var wow = (controls.UI_LEFT_P ? -1 : 0) + (controls.UI_RIGHT_P ? 1 : 0);
			if (wow != 0) {
				ClientPrefs.framerate = Std.int(FlxMath.bound(ClientPrefs.framerate + wow, 60, 240));
				changeSelection(lastSelected);
			}
		}

		if (settingKey == true) {
			var keyPressed:Int = FlxG.keys.firstJustPressed();
			if (keyPressed > -1) {
				var dir = ['note_left', 'note_down', 'note_up', 'note_right'][curSelected];
				ClientPrefs.keyBinds.set(dir, [keyPressed, ClientPrefs.keyBinds[dir][1]]);
				settingKey = false;
				changeSelection(lastSelected);
			}
		}
	}

	var lastSelected = 0;
	function changeSelection(changeTo:Int)
	{
		if (!canInteract)
			return;

		if (settingKey && changeTo != lastSelected) return; 

		lastSelected = changeTo;
		curSelected = FlxMath.wrap(changeTo, 0, selectMax);

		if (curSelected > selectMax)
			curSelected = 0;

		if (0 > curSelected)
			curSelected = selectMax;

		switch (curMenu)
		{
			case 'main':
				curDisplayText = [];
				if (curSelected == 0)
				{
					curDisplayText.push('>   MENUweek.start @PROLOGUE');
					curDisplayText.push('    MENUoptions             ');
				}
				else
				{
					curDisplayText.push('    MENUweek.start @PROLOGUE');
					curDisplayText.push('>   MENUoptions             ');
				}
			case 'options':
				var options = [
					'      LEFT      -    ' + (settingKey && curSelected == 0 ? '' : ClientPrefs.keyBinds.get('note_left')[0].toString()),
					'      DOWN      -    ' + (settingKey && curSelected == 1 ? '' : ClientPrefs.keyBinds.get('note_down')[0].toString()),
					'      UP        -    ' + (settingKey && curSelected == 2 ? '' : ClientPrefs.keyBinds.get('note_up')[0].toString()),
					'      RIGHT     -    ' + (settingKey && curSelected == 3 ? '' : ClientPrefs.keyBinds.get('note_right')[0].toString()),
					'      SCROLL    -    ' + (ClientPrefs.downScroll ? 'DOWN  ' : 'UP    '),
					'      FLASHING  -    ' + (ClientPrefs.flashing ? 'TRUE  ' : 'FALSE '),
					'   FPS       -    ' +  ClientPrefs.framerate,
                    '      GPU CACHE -    ' + (ClientPrefs.gpuCache ? 'TRUE  ' : 'FALSE '),
					'      BACK'
				];

				// keep the spacing CONSISTENT
				for (i in [0,1,2,3,7]) {
					while (options[i].length < 27) options[i] += ' ';
				}

				var strings:Array<String> = [
					'      -------- KEYS --------  ', ''
				];

				for (i in options)
				{
					if (curSelected == options.indexOf(i))
						i =  '   >' + i.substr(4);
					strings.push(i);
				}

				// what is this brah
				strings.insert(6, '');
				strings.insert(6, '      ------- VISUALS -------  ');
				strings.insert(6, '');
				strings.insert(13, '');

				curDisplayText = strings.concat(['', '    Unable to load MENUadditional.options']);
		}

		renderText(curDisplayText);
	}
}
