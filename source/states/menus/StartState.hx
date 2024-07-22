package states.menus;

// this isnt startup state im rewriting things -Kn1ght
import util.Discord.DiscordClient;
import objects.WaveformSprite;
import flixel.group.FlxSpriteGroup;
import flixel.addons.transition.FlxTransitionableState;
import flixel.util.FlxTimer;
import flixel.FlxG;
import engine.info.Framerate;
import data.Paths;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import states.MusicBeatState;

class StartStateIntro extends MusicBeatState {
    var textField:FlxText;
    var terminalMessages:Array<Dynamic> = [
		["FATAL ERROR: APPLICATION FUTUREFUNK.EXE HAS FAILED TO BOOT INTO TITLESTATE.CPP", 1.1, false],
		["BOOTING RECOVERY METHODS.", 0.8, false],
		["[----------------------]", 1.35, true],
		["[#---------------------]", 2.47, true],
		["[##--------------------]", 0.9, true],
		["[####------------------]", 2.4, true],
		["[########--------------]", 2.9, true],
		["[################------]", 3.4, true],
		["[####################--]", 1.74, true],
		["[#####################-]", 1.6, true],
		["[######################]", 2.4, true],
        ["DONE! SWITCHING STATE TO FUTUREFUNKBOOTLOADER.CPP", 0.6, true]
	];

    override public function create()
        {
            super.create();

            // skipping intro for once you already got in the mod

            if (FlxG.save.data.alreadyOnceEnteredThisTHING) {
                MusicBeatState.switchState(new TitleState());
            } else {
                FlxG.sound.play(Paths.sound('boot'));
    
                if (FlxG.sound.music != null)
                    FlxG.sound.music.stop();
        
                Framerate.debugMode = 0;
                FlxG.mouse.visible = false;
                FlxG.sound.soundTrayEnabled = false;
        
                textField = new FlxText(5, 5, 0, '', 8);
                textField.setFormat(Paths.font('casmono.ttf'), 16, FlxColor.WHITE, FlxTextAlign.LEFT);
                textField.antialiasing = false;
        
                var textFormat = textField.textField.getTextFormat();
                textFormat.leading = -2;
                textField.textField.setTextFormat(textFormat);
                textField.updateHitbox();
                add(textField);
        
                textWait(terminalMessages);
            }
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
					FlxG.switchState(new StartMenu());
				}
			});
		}
	}
}

class StartMenu extends MusicBeatState {
    public static var returnToBoot:Bool = true;
    var waveform:WaveformSprite;
    var textField:FlxText;
    var textPrefix:Array<String> = [
		'',
		'',
		'    ##############################',
		'    ##                          ##',
		'    ##  FUTURE FUNK BOOTLOADER  ##',
		'    ##                          ##',
		'    ##############################',
		'',
		'',
        '',
        '    PRESS [ENTER] TO OPERATE VISUAL BASE MENU. (TITLESTATE.CPP)',
        '    PRESS [F1] TO OPERATE VISUAL OPTIONS MENU. (OPTIONSSTATE.CPP)'
	];

    var texts:FlxSpriteGroup;

    override public function create()
        {
            super.create();
    
            if (FlxG.sound.music != null)
                FlxG.sound.music.stop();
    
            FlxG.sound.playMusic(Paths.music("bootloader"), 0.4);

            texts = new FlxSpriteGroup();
            add(texts);

            waveform = new WaveformSprite(0, 0, 120, 640, FlxG.sound.music);
            waveform.angle = -90;
            waveform.waveformDrawStep = 4;
            waveform.waveformDrawNegativeSpace = 2;
            waveform.framerate = 60;
            waveform.waveformSampleLength = 0.1;
            waveform.scale.set(2, 2);
            waveform.screenCenter(XY);
            waveform.y += 120;
            add(waveform);

            FlxG.mouse.visible = false;
            FlxG.sound.soundTrayEnabled = false;

            FlxG.save.data.alreadyOnceEnteredThisTHING = true;
            FlxG.save.flush();
    
            textField = new FlxText(5, 5, 0, '##############################\n##                          ##\n##  FUTURE FUNK BOOTLOADER  ##\n##                          ##\n##############################\n\n\nPRESS [F1] TO OPERATE VISUAL OPTIONS MENU. (OPTIONSSTATE.CPP)\nPRESS [ENTER] TO OPERATE VISUAL BASE MENU. (TITLESTATE.CPP)', 8);
            textField.setFormat(Paths.font('casmono.ttf'), 16, FlxColor.WHITE, FlxTextAlign.LEFT);
            textField.antialiasing = false;
    
            var textFormat = textField.textField.getTextFormat();
            textFormat.leading = -2;
            textField.textField.setTextFormat(textFormat);
            textField.updateHitbox();
            add(textField);
        }

        function renderText(array:Array<String>, ?includePrefix:Bool = true)
        {
            // textprefix is copied to prevent variable weirdness
            if (includePrefix) array = textPrefix.copy().concat(array);
            textField.text = array.join('\n');
            textField.screenCenter();
            textField.x -= 16; // its SLIGHTLY TO THE RIGHT >:[
        }

    override public function update(elapsed:Float) {
        super.update(elapsed);

        if (FlxG.keys.justPressed.F1)
            MusicBeatState.switchState(new states.options.OptionsState());
        if (FlxG.keys.justPressed.ENTER)
            MusicBeatState.switchState(new TitleState()); 
    }
}