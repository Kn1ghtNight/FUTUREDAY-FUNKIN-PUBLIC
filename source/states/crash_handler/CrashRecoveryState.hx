package states.crash_handler;

import flixel.addons.display.FlxBackdrop;
import flixel.util.FlxColor;
import flixel.addons.transition.FlxTransitionableState;
import flixel.input.keyboard.FlxKey;
import flixel.FlxState;
import flixel.FlxG;
import openfl.events.KeyboardEvent;
import flixel.text.FlxText;
import data.Paths;

//use base flixel flxstate, no musicbeatstate bullshit
class CrashRecoveryState extends FlxState{
    private var crashState:String;
    private var error:String;

    public function new(errMsg:String, crashState:String) {
        this.error = errMsg;
        this.crashState = crashState;
	    trace("The app has just recovered from a crash.");	
        super();
    }

    override function create(){
        final bgLoop:FlxBackdrop = new FlxBackdrop(Paths.image('titleBG'), XY, 0,5);
        bgLoop.velocity.x = 12;
        add(bgLoop);

        final text:FlxText = new FlxText(10, 100, 0, 'The game has crashed and successfully recovered. Crash log:\n$error\nState where the crash happened: $crashState.\n Please report this error. Press enter to switch to TitleState.');
        text.setFormat(Paths.font("vcr.ttf"), 21, FlxColor.WHITE, FlxTextAlign.CENTER);
        text.screenCenter();
        add(text);

        FlxG.sound.playMusic(Paths.music('Occurance'), 0.4);

        //to do later: implement hscript and add an hscript menu on debug

        FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDown);
    }

    override function destroy(){
        FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDown);
    }

    private function keyDown(event:KeyboardEvent){
        if (event.keyCode == FlxKey.SPACE || event.keyCode == FlxKey.ENTER)
            FlxG.switchState((crashState == "TitleState" ? new states.menus.MainMenuState() : new states.menus.TitleState())); // hey ziad i fixed the cast issue!
            //MusicBeatState.switchState(crashState == "TitleState" ? new states.menus.MainMenuState() : new states.menus.TitleState());
    }
}