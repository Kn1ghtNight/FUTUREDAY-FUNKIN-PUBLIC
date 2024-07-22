package;

import states.menus.StartState.StartStateIntro;
import engine.gc.GarbageCollector;
import openfl.display.Bitmap;
import data.Paths;
import engine.info.SystemInfo;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import openfl.Assets;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.display.StageScaleMode;
import flixel.system.scaleModes.FixedScaleAdjustSizeScaleMode;
import openfl.events.Event;
import states.menus.*;

using StringTools;

// crash handler stuff
#if CRASH_HANDLER
import haxe.CallStack;
import haxe.io.Path;
import lime.app.Application;
import openfl.events.UncaughtErrorEvent;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;
import util.Discord.DiscordClient;
#end

// cumming and jizzing
#if D3D
@:buildXml('<include name="../../../../source/d3d/DirectXTK/builder.xml" />')
#end
#if debug
@:build(Macros.fillClasses())
#end
class Main extends Sprite
{
	var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).

	public static var initialState:Class<FlxState> = StartStateIntro; // The FlxState the game starts with.

	var zoom:Float = -1; // If -1, zoom is automatically calculated to fit the window dimensions.
	var framerate:Int = 60; // How many frames per second the game should run at.
	var skipSplash:Bool = true; // Whether to skip the flixel splash screen that appears in release mode.
	var startFullscreen:Bool = false; // Whether to start the game in fullscreen on desktop targets

	public static var framerateSprite:engine.info.Framerate;
	public static var uglyGayRetardedFaggots:Sprite;

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function main():Void
	{
		Lib.current.addChild(new Main());
	}

	public function new()
	{
		super();

		if (stage != null)
		{
			init();
		}
		else
		{
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
	}

	private function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}

		setupGame();
	}

	private function setupGame():Void
	{
		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (zoom == -1)
		{
			var ratioX:Float = stageWidth / gameWidth;
			var ratioY:Float = stageHeight / gameHeight;
			zoom = Math.min(ratioX, ratioY);
			gameWidth = Math.ceil(stageWidth / zoom);
			gameHeight = Math.ceil(stageHeight / zoom);
		}

		#if windows
		@:functionCode('
		#include <Windows.h>
		SetProcessDPIAware()
		')
		#end

		var game:FlxGame = new FlxGame(gameWidth, gameHeight, Init, #if (flixel < "5.0.0") zoom, #end framerate, framerate, skipSplash, startFullscreen);
		FlxG.worldDivisions = 1;

		@:privateAccess
    	game._customSoundTray = engine.ui.FunkSoundTray;
		flixel.FlxG.plugins.add(new engine.plugin.ScreenshotPlugin());

		addChild(game);

		addChild(framerateSprite = new engine.info.Framerate());
		framerateSprite.scaleX = framerateSprite.scaleY = stage.window.scale;

		//FlxG.scaleMode = new FixedScaleAdjustSizeScaleMode();

		SystemInfo.init();
		#if !mobile
		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		#end

		#if html5
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		#end

		#if CRASH_HANDLER
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
		#end

		#if debug
		// ClassesToBeAdded gets generated by macro
		for (clazz in ClassesToBeAdded)
		{
			FlxG.console.registerClass(Type.resolveClass(clazz));
		}
		FlxG.console.registerFunction("cast", castTo);
		#end
	}

	#if debug
	// introduce cast functionality to the console
	private static function castTo<T>(from:Dynamic, to:T):T
	{
		return cast(from);
	}
	#end

	#if CRASH_HANDLER
	function onCrash(e:UncaughtErrorEvent):Void
	{
		var errMsg:String = "";
		final callStack:Array<StackItem> = CallStack.exceptionStack(true);
		
		for (stackItem in callStack){
			switch(stackItem){
				case FilePos(_, file, line, _):
					errMsg += '$file (line $line)\n';
				default: 
					Sys.println(stackItem);
			}
		}
		
		errMsg += '\nCaught error: ${e.error}';
		
		new Process('FutureFunk.exe', [errMsg, states.MusicBeatState.lastKnownStateName]);
		
		dumpAllMemory();
		
		#if DISCORD_ALLOWED
		DiscordClient.shutdown();
		Sys.exit(1);
		#end
	}
	#end

	public static function dumpAllMemory():Void{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
	
		@:privateAccess{
			for (key in FlxG.bitmap._cache.keys())
			{
				final obj = FlxG.bitmap._cache.get(key);
				if (obj != null)
				{
					Assets.cache.removeBitmapData(key);
					FlxG.bitmap._cache.remove(key);
					obj.destroy();
				}
			}
		}
		Assets.cache.clear("songs");
		FlxG.bitmap.dumpCache();
		FlxG.sound.destroy();
		final cache = cast(Assets.cache, openfl.utils.AssetCache);
		for (key in cache.sound.keys())
			cache.removeSound(key);
		for (key in cache.font.keys())
			cache.removeFont(key);
	
		GarbageCollector.run(true);
	}
}
