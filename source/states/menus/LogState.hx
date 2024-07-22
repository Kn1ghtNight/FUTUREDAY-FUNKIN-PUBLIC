package states.menus;

import openfl.filters.ShaderFilter;
import objects.PsychVideo;
import engine.info.Framerate;
import data.ClientPrefs;
import util.CoolUtil;
import data.Paths;
import flixel.FlxG;
import flixel.FlxSprite;
import states.substates.MusicBeatSubstate;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxTimer;
import openfl.Assets;
import flixel.math.FlxMath;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import states.menus.TitleState;

using StringTools;

class LogState extends MusicBeatState
{
	// it conserves bitmap data to have multiple flxtexts rather than one just storing alll the bitmap data because theres a lot of empty space
	var allTheTexts:Array<FlxText> = [];
	var inputText:FlxText;

	public static var TEXT_HEIGHT:Float = 16;
	public static var MAX_TEXTS:Float = 44;

	final prefix = '> ';

	var fakeCursor:FlxSprite;

	// each non-alpha character, as well as it's SHIFTed counterpart in an array
	// im too lazy to make the numpad do anything
	static var specialChars:Map<Int, Array<String>> = [
		// numbahs
		FlxKey.ZERO => ['0', ')'],
		FlxKey.ONE => ['1', '!'],
		FlxKey.TWO => ['2', '@'],
		FlxKey.THREE => ['3', '#'],
		FlxKey.FOUR => ['4', '$'],
		FlxKey.FIVE => ['5', '%'],
		FlxKey.SIX => ['6', '^'],
		FlxKey.SEVEN => ['7', '&'],
		FlxKey.EIGHT => ['8', '*'],
		FlxKey.NINE => ['9', '('],
		// other. stuff idk
		FlxKey.COMMA => [',', '<'],
		FlxKey.PERIOD => ['.', '>'],
		FlxKey.SLASH => ['/', '?'],
		FlxKey.SEMICOLON => [';', ':'],
		FlxKey.QUOTE => ['\'', '"'],
		FlxKey.BACKSLASH => ['\\', '|'],
		FlxKey.MINUS => ['-', '_'],
		FlxKey.PLUS => ['=', '+'],
		FlxKey.LBRACKET => ['[', '{'],
		FlxKey.RBRACKET => [']', '}'],
		FlxKey.GRAVEACCENT => ['`', '~'], // aint nobody using this one but whatever
		FlxKey.SPACE => [' ', ' ']
	];

	var commandHistory:Array<String> = [];
	var historyIndex:Int = 0;

	override public function create()
	{
		super.create();

		Paths.setCurrentLevel('embed');

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		FlxG.mouse.visible = false;
		FlxG.sound.soundTrayEnabled = false;
		FlxG.sound.muteKeys = [];
		FlxG.sound.volumeUpKeys = [];
		FlxG.sound.volumeDownKeys = [];
		Framerate.debugMode = 0; // disable framerate by default because you cant see the fucking text

		inputText = new FlxText(0, 0, 0, prefix);
		inputText.wordWrap = false;

		inputText.setFormat(Paths.font('casmono.ttf'), 16, FlxColor.LIME, FlxTextAlign.LEFT);
		inputText.antialiasing = false;
		var textFormat = inputText.textField.getTextFormat();
		textFormat.leading = -3;
		inputText.textField.setTextFormat(textFormat);

		inputText.updateHitbox();
		add(inputText);

		fakeCursor = new FlxSprite(0, 0).makeGraphic(1, 1);
		fakeCursor.scale.set(8, 3);
		fakeCursor.updateHitbox();
		add(fakeCursor);

		addText('QT OS DEV CONSOLE');

		var retroArchVHS:shaders.NtscShader;
		retroArchVHS = new shaders.NtscShader();

		var shader = new shaders.BarrelDistortionShader();
		shader.barrelDistortion1 = 0.10;
		shader.barrelDistortion2 = 0.10;

		camera.setFilters([new ShaderFilter(retroArchVHS), new ShaderFilter(shader)]);
	}

	public var canType:Bool = true;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (canType)
		{
			var firstPressed = FlxG.keys.firstJustPressed();
			if (firstPressed == FlxKey.ENTER)
			{
				var command:String = inputText.text.substr(prefix.length).trim();
				addText(prefix + command);
				commandHistory.push(command);
				historyIndex = commandHistory.length;

				// COMMANDS
				if (command != '')
				{
					var args = command.split(' ');
					while (args.remove('')) {} // remove all empty  spaces
					switch (args[0])
					{
						default:
							addText('[ERROR] ${args[0]} is not recognized as a valid command.');
						case 'israel' | 'isreal':
							addText('FROM THE RIVER TO THE SEA, PALESTINE WILL BE FREE!');
						case 'play':
							canType = false;
							addText('Loading "OVERWORLD PROTO"...');
							var joined = [for (i in 0...args.length - 1) args[i + 1]].join(' ');
						if (joined == 'Jx0' || joined == 'jx0' || joined == 'jxo') { // prob a better way to do this but i dont give a shit!
							new FlxTimer().start(FlxG.random.float(0.8, 1.3), (_) ->
							{
								//openSubState(new LogReaderSubState(Assets.getText(('embed:assets/embed/logs/${joined}.txt')).split('\n')));
								canType = true;
								allTheTexts[allTheTexts.length - 1].text = "Log loaded succesfully!";
							});
						}
						case 'nsfw':
							addText("?");
						case 'edge': //hxvlc wont fucking load the video am i retarded
							var blueberries:PsychVideo;
							
							blueberries = new PsychVideo();
							blueberries.load(Paths.video('blueberries'));
							blueberries.scrollFactor.set();
    						add(blueberries);
    						blueberries.antialiasing = ClientPrefs.globalAntialiasing;
						case 'log':
							if (args[1] == 'harris')
								args[1] = 'bambi'; // muahaha,,
							var joined = [for (i in 0...args.length - 1) args[i + 1]].join(' ');
							if (Assets.exists('embed:assets/embed/logs/${joined}.txt'))
							{
								canType = false;
								addText('Loading...');
								new FlxTimer().start(FlxG.random.float(0.8, 1.3), (_) ->
								{
									openSubState(new LogReaderSubState(Assets.getText(('embed:assets/embed/logs/${joined}.txt')).split('\n')));
									canType = true;
									allTheTexts[allTheTexts.length - 1].text = "Log loaded succesfully!";
								});
							}
							else
							{
								addText('Log not found.');
							}
						case 'exit':
							canType = false;
							MusicBeatState.switchState(new MainMenuState());
						case 'help':
							addText('COMMANDS:');
							addText('help - Shows this menu.');
							addText('edge - Edge.');
							//addText('\n@dev hel,p me with the rest of the command names please...');
							addText('commands without descriptions: log, exit, users, admin');
						case 'users':
							addText('current_users => Kasey, undefined');
					}
				}

				setInputText();
			}
			else if (firstPressed == FlxKey.UP || firstPressed == FlxKey.DOWN)
			{
				historyIndex = Std.int(FlxMath.bound(historyIndex + (firstPressed == FlxKey.DOWN ? 1 : -1), 0, commandHistory.length));
				if (commandHistory[historyIndex] != null)
				{
					setInputText(commandHistory[historyIndex]);
				}
				else
				{
					setInputText();
				}
			}
			else if (firstPressed == FlxKey.DELETE || firstPressed == FlxKey.BACKSPACE)
			{
				setInputText(inputText.text.substr(prefix.length, inputText.text.length - (prefix.length + 1)));
			}
			else
			{
				addToInputText(inputStuff(firstPressed));
			}
		}

		fakeCursor.visible = (canType && elapsedTime % 1 <= 0.5);
		fakeCursor.setPosition(inputText.x + inputText.width + 2, inputText.y + inputText.height - fakeCursor.height);
		fakeCursor.x -= 2;
		fakeCursor.y -= 4;
	}

	// for organization
	function setInputText(?t:String = '')
	{
		inputText.text = prefix + t;
	}

	function addToInputText(t:String)
	{
		inputText.text += t;
	}

	function inputStuff(key:FlxKey):String
	{
		var keyAsInt = cast(key, Int);

		if (keyAsInt != FlxKey.NONE)
		{
			if (keyAsInt >= 65 && keyAsInt <= 90) // a-z
				return (FlxG.keys.pressed.SHIFT ? key.toString().toUpperCase() : key.toString().toLowerCase());
			if (specialChars.exists(keyAsInt))
				return specialChars[keyAsInt][(FlxG.keys.pressed.SHIFT ? 1 : 0)];
		}

		return '';
	}

	function addText(text:String)
	{
		for (t in text.split('\n'))
		{
			var newText:FlxText;
			if (allTheTexts.length < MAX_TEXTS - 1)
			{
				newText = new FlxText(0, allTheTexts.length * TEXT_HEIGHT, 0, t, 13);
			}
			else
			{
				for (i in allTheTexts)
					i.y -= TEXT_HEIGHT;
				newText = allTheTexts.shift();
				newText.y = allTheTexts.length * TEXT_HEIGHT;
				newText.text = t;
			}

			newText.setFormat(Paths.font('casmono.ttf'), 16, FlxColor.LIME, FlxTextAlign.LEFT);
			newText.antialiasing = false;

			var textFormat = newText.textField.getTextFormat();
			textFormat.leading = -3;
			newText.textField.setTextFormat(textFormat);
			newText.updateHitbox();
			// newText.setPosition(0, -50);
			add(newText);
			allTheTexts.push(newText);
		}
		inputText.y = (allTheTexts.length) * TEXT_HEIGHT;
	}

	function clearTexts()
	{
		while (allTheTexts.length > 0)
		{
			var ok = allTheTexts.shift();
			ok.kill();
			ok.destroy();
			remove(ok);
		}
	}

	override function destroy()
	{
		Paths.setCurrentLevel('embed');
		FlxG.sound.soundTrayEnabled = true;
		FlxG.save.data.hasSeenMinimalMenu = true;
		FlxG.sound.muteKeys = TitleState.muteKeys;
		FlxG.sound.volumeDownKeys = TitleState.volumeDownKeys;
		FlxG.sound.volumeUpKeys = TitleState.volumeUpKeys;
		Framerate.debugMode = 1; // re enable framerate at default level when exiting
		super.destroy();
	}
}

class LogReaderSubState extends MusicBeatSubstate
{
	public var textShitArray:Array<String> = [];
	public var logImages:Array<Array<String>> = [];

	var allTheTexts:Array<FlxText> = [];

	public function new(fuck:Array<String>)
	{
		super();
		// log images
		fuck = [for (i in fuck) i.trim()];

		if (fuck.indexOf('# IMAGES') != -1)
		{
			var i = fuck.indexOf('# IMAGES');
			// seperate log and images I LOVE THAT HAXE JUST LETS YOU CODE LIKE THIS ITS SO STUPID
			logImages = [for (img in fuck.splice(i, 999)) [for (sep in img.split('::')) sep.trim()]];
			logImages.shift(); // remove the # IMAGES line
			trace(i);
		}
		textShitArray = fuck;

		trace(fuck);
		trace(logImages);
	}

	override public function create()
	{
		super.create();
		LogImage.totalHeight = Std.int(LogState.TEXT_HEIGHT * 2); // a litttle bit from the top
		var weeweecharles = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		weeweecharles.setGraphicSize(FlxG.width, FlxG.height);
		weeweecharles.updateHitbox();
		weeweecharles.screenCenter();
		weeweecharles.scrollFactor.set();
		add(weeweecharles);

		addText('');
		var imgIndex = 0;
		new FlxTimer().start(0.05, (tmr) ->
		{
			if (textShitArray.length == 0)
			{
				if (logImages.length == 0)
				{
					canType = true;
					addText('\nPress ENTER key to close.');
				}
				else
				{
					var yum = logImages.shift();
					add(new LogImage(++imgIndex, yum[0], yum[1]));
				}
			}
			else
				addText(textShitArray.shift());
		}, textShitArray.length + logImages.length + 1);
	}

	public var canType:Bool = false;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (canType)
		{
			if (FlxG.keys.justReleased.ENTER)
			{
				close();
			}
			// scrolling!!!
			if (allTheTexts.length > LogState.MAX_TEXTS)
			{
				camera.scroll.y += LogState.TEXT_HEIGHT * ((controls.UI_DOWN_P ? 1 : 0)
					- (controls.UI_UP_P ? 1 : 0)
					+ (FlxG.mouse.wheel == 0 ? 0 : (FlxG.mouse.wheel > 0 ? -1 : 1)));
				camera.scroll.y = FlxMath.bound(camera.scroll.y, 0, ((allTheTexts.length - LogState.MAX_TEXTS) * LogState.TEXT_HEIGHT));
			}
		}
	}

	function addText(text:String)
	{
		for (t in text.split('\n'))
		{
			var newText:FlxText;
			newText = new FlxText(0, allTheTexts.length * LogState.TEXT_HEIGHT, 0, t, 13);

			newText.setFormat(Paths.font('casmono.ttf'), 16, FlxColor.LIME, FlxTextAlign.LEFT);
			newText.antialiasing = false;

			var textFormat = newText.textField.getTextFormat();
			textFormat.leading = -3;
			newText.textField.setTextFormat(textFormat);
			newText.updateHitbox();
			// newText.setPosition(0, -50);
			newText.scrollFactor.set(0, 1);
			add(newText);
			allTheTexts.push(newText);
		}

		if (allTheTexts.length > LogState.MAX_TEXTS)
			camera.scroll.y = (allTheTexts.length - LogState.MAX_TEXTS) * LogState.TEXT_HEIGHT;
	}

	public override function close()
	{
		camera.scroll.y = 0;
		super.close();
	}
}

class LogImage extends FlxSpriteGroup
{
	public static var totalHeight:Int = 0;

	public function new(index:Int = 0, ?image:String = '', ?caption:String = '')
	{
		super();

		var sprite = new FlxSprite(0, 0).loadGraphic(Paths.image(image));
		sprite.antialiasing = false;
		add(sprite);

		if (!['', null].contains(caption))
		{
			var text = new FlxText(0, sprite.height + 5, 0, caption, 16);
			text.setFormat(Paths.font('casmono.ttf'), 16, FlxColor.LIME, FlxTextAlign.LEFT);
			text.antialiasing = false;
			add(text);
		}

		setPosition(Std.int(FlxG.width - (width + 32)), FlxG.height - (height + totalHeight));
		totalHeight += Math.ceil(height + (LogState.TEXT_HEIGHT * 1));
		scrollFactor.set();
	}
}
