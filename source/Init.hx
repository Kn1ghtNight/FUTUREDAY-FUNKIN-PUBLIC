package;

import states.menus.UserBlock;
import states.menus.StartState.StartStateIntro;
import engine.script.FunkinHScript;
import engine.gc.GarbageCollector;
import states.menus.StartupState;
#if cpp
import cpp.CPPInterface;
#end
import data.ClientPrefs;
import data.Highscore;
import data.Paths;
import flixel.FlxG;
import flixel.FlxState;
import input.PlayerSettings;
import lime.app.Application;
import openfl.Lib;
import shaders.ShaderUtil;
import states.menus.StoryMenuState;
import states.menus.TitleState;
import util.CoolUtil;
import util.Discord.DiscordClient;

class Init extends FlxState
{
	public override function new()
	{
		super();
		FlxG.mouse.visible = false;
	}

	public override function create()
	{
		super.create();

		#if cpp
		CPPInterface.darkMode();
		#end

		GarbageCollector.run(true);

		ClientPrefs.loadDefaultKeys();

		FlxG.autoPause = true;

		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		FlxG.game.focusLostFramerate = 30;
		FlxG.sound.muteKeys = TitleState.muteKeys;
		FlxG.sound.volumeDownKeys = TitleState.volumeDownKeys;
		FlxG.sound.volumeUpKeys = TitleState.volumeUpKeys;
		FlxG.keys.preventDefaultKeys = [TAB];

		FunkinHScript.init();

		PlayerSettings.init();

		PlayerSettings.init();

		FlxG.save.bind(CoolUtil.formatBindString(Lib.application.meta.get("file")), CoolUtil.formatBindString(Lib.application.meta.get("company")));

		ClientPrefs.loadPrefs();
		trace(ClientPrefs.videosUnsupported);
		trace(TitleState.videosSupported);
		if (ClientPrefs.videosUnsupported)
		{
			trace("// WEAK ASS COMPUTER DETECTED, PREVENTING GPU OPERATIONS //");
			TitleState.videosSupported = false;
		}

		Highscore.load();

		if (FlxG.save.data != null && FlxG.save.data.fullscreen)
		{
			FlxG.fullscreen = FlxG.save.data.fullscreen;
		}

		if (FlxG.save.data.weekCompleted != null)
		{
			StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;
		}

		#if desktop
		if (!DiscordClient.isInitialized)
		{
			DiscordClient.initialize();
			Application.current.onExit.add(function(exitCode)
			{
				DiscordClient.shutdown();
			});
		}
		#end

		//decide whether or not we should switch to the crash handler!
		#if sys
		final args:Array<String> = Sys.args();
		final shouldRecover:Bool = (args.length == 2) ? true : false;

		//dont return, let the function progress
		//shouldRecover ? FlxG.switchState(new states.crash_handler.CrashRecoveryState(args[0], args[1])) : null;

		if(shouldRecover){
			FlxG.switchState(new states.crash_handler.CrashRecoveryState(args[0], args[1]));
			return;
			}
		#end

		if (ClientPrefs.hasSeenMinimalMenu)
		FlxG.switchState(Type.createInstance(TitleState, []));
		else if (ClientPrefs.showSplash) {
		FlxG.switchState(Type.createInstance(UserBlock, []));
		}
		else
		FlxG.switchState(Type.createInstance(StartStateIntro, []));
	}
}
