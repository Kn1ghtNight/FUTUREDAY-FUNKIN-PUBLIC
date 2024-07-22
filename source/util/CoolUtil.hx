package util;

import flixel.tweens.FlxEase;
import flixel.math.FlxPoint;
import song.Conductor;
import flixel.math.FlxMath;
import data.Paths;
import flixel.FlxG;
import flixel.sound.FlxSound;
import haxe.display.Display.Package;
import haxe.io.Path;
import lime.utils.AssetLibrary;
import lime.utils.AssetManifest;
import lime.utils.Assets as LimeAssets;
import openfl.utils.Assets;
import states.game.PlayState;
import sys.FileSystem;
import sys.io.File;

using StringTools;

class CoolUtil
{
	public static var defaultDifficulties:Array<String> = ['Hard'];
	public static var defaultDifficulty:String = 'Hard'; // The chart that has no suffix and starting difficulty on Freeplay/Story Mode

	public static var difficulties:Array<String> = [];

	inline public static function quantize(f:Float, snap:Float)
	{
		// changed so this actually works lol
		var m:Float = Math.fround(f * snap);
		return (m / snap);
	}

	public static function rotate(x:Float, y:Float, angle:Float, ?point:FlxPoint):FlxPoint
	{
		var p = point == null ? FlxPoint.weak() : point;
		return p.set((x * Math.cos(angle)) - (y * Math.sin(angle)), (x * Math.sin(angle)) + (y * Math.cos(angle)));
	}

	/**
	 * Removes duplicate instances from the input `Array<String>` and sorts alphabetically.
	 * @param string The `Array<String>` to be used.
	 */
	inline public static function removeDuplicates(string:Array<String>):Array<String>
	{
		var tempArray:Array<String> = new Array<String>();
		var lastSeen:String = "";
		string.sort(function(str1:String, str2:String)
		{
			return (str1 == str2) ? 0 : (str1 > str2) ? 1 : -1;
		});
		for (str in string)
		{
			if (str != lastSeen)
			{
				tempArray.push(str);
			}
			lastSeen = str;
		}
		return tempArray;
	}

	public static function getDifficultyFilePath(num:Null<Int> = null)
	{
		if (num == null)
			num = PlayState.storyDifficulty;

		var fileSuffix:String = difficulties[num];
		if (fileSuffix != defaultDifficulty)
		{
			fileSuffix = '-' + fileSuffix;
		}
		else
		{
			fileSuffix = '';
		}
		return Paths.formatToSongPath(fileSuffix);
	}

	public static function difficultyString():String
	{
		return difficulties[PlayState.storyDifficulty].toUpperCase();
	}

	inline public static function boundTo(value:Float, min:Float, max:Float):Float
	{
		return Math.max(min, Math.min(max, value));
	}

	public static function coolTextFile(path:String):Array<String>
	{
		var daList:Array<String> = [];
		#if sys
		if (FileSystem.exists(path))
			daList = File.getContent(path).trim().split('\n');
		#else
		if (Assets.exists(path))
			daList = Assets.getText(path).trim().split('\n');
		#end

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}

		return daList;
	}

	public static function listFromString(string:String):Array<String>
	{
		var daList:Array<String> = [];
		daList = string.trim().split('\n');

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}

		return daList;
	}

	inline public static function stepsToSeconds(step:Float):Float {
		return (Conductor.stepCrochet * step) / 1000;
	}

	public static function dominantColor(sprite:flixel.FlxSprite):Int
	{
		var countByColor:Map<Int, Int> = [];
		for (col in 0...sprite.frameWidth)
		{
			for (row in 0...sprite.frameHeight)
			{
				var colorOfThisPixel:Int = sprite.pixels.getPixel32(col, row);
				if (colorOfThisPixel != 0)
				{
					if (countByColor.exists(colorOfThisPixel))
					{
						countByColor[colorOfThisPixel] = countByColor[colorOfThisPixel] + 1;
					}
					else if (countByColor[colorOfThisPixel] != 13520687 - (2 * 13520687))
					{
						countByColor[colorOfThisPixel] = 1;
					}
				}
			}
		}
		var maxCount = 0;
		var maxKey:Int = 0; // after the loop this will store the max color
		countByColor[flixel.util.FlxColor.BLACK] = 0;
		for (key in countByColor.keys())
		{
			if (countByColor[key] >= maxCount)
			{
				maxCount = countByColor[key];
				maxKey = key;
			}
		}
		return maxKey;
	}

	public static function numberArray(max:Int, ?min = 0):Array<Int>
	{
		var dumbArray:Array<Int> = [];
		for (i in min...max)
		{
			dumbArray.push(i);
		}
		return dumbArray;
	}

	// uhhhh does this even work at all? i'm starting to doubt
	public static function precacheSound(sound:String, ?library:String = null):Void
	{
		Paths.sound(sound, library);
	}

	public static function precacheMusic(sound:String, ?library:String = null):Void
	{
		Paths.music(sound, library);
	}

	public static function browserLoad(site:String)
	{
		#if linux
		Sys.command('/usr/bin/xdg-open', [site]);
		#else
		FlxG.openURL(site);
		#end
	}

	public static final formatNotAllowedChars:Array<String> = ["~", "%", "&", ";", ":", '/', '"', "'", "<", ">", "?", "#", " ", "!"];

	public static function formatBindString(str:String):String
	{
		var finalStr = str;

		for (notAllowed in formatNotAllowedChars)
		{
			finalStr = StringTools.replace(finalStr, notAllowed, "");
		}

		return finalStr.toLowerCase();
	}

	public static function findFilesInPath(path:String, extns:Array<String>, ?filePath:Bool = false, ?deepSearch:Bool = true):Array<String>
	{
		var files:Array<String> = [];

		if (FileSystem.exists(path))
		{
			for (file in FileSystem.readDirectory(path))
			{
				var path = haxe.io.Path.join([path, file]);
				if (!FileSystem.isDirectory(path))
				{
					for (extn in extns)
					{
						if (file.endsWith(extn))
						{
							if (filePath)
								files.push(path);
							else
								files.push(file);
						}
					}
				}
				else if (deepSearch) // ! YAY !!!! -lunar
				{
					var pathsFiles:Array<String> = findFilesInPath(path, extns);

					for (_ in pathsFiles)
						files.push(_);
				}
			}
		}
		return files;
	}

	public static inline function getFileStringFromPath(file:String):String
	{
		return Path.withoutDirectory(Path.withoutExtension(file));
	}

	public static inline function fpsLerp(v1:Float, v2:Float, ratio:Float):Float
	{
		return FlxMath.lerp(v1, v2, getFPSRatio(ratio));
	}

	public static function getSizeString(size:Float):String
	{
		var labels = ["B", "KB", "MB", "GB", "TB"];
		var rSize:Float = size;
		var label:Int = 0;
		while (rSize > 1024 && label < labels.length - 1)
		{
			label++;
			rSize /= 1024;
		}
		return '${Std.int(rSize) + "." + addZeros(Std.string(Std.int((rSize % 1) * 100)), 2)}${labels[label]}';
	}

	public static inline function addZeros(str:String, num:Int)
	{
		while (str.length < num)
			str = '0${str}';
		return str;
	}

	/**
     * Returns an `FlxEase` type based on the input `String`.
     * @param ease The easing `String` to use.
     */
	 public static function easeFromString(?ease:String = '') {
		switch(ease.toLowerCase().trim()) {
			case 'backin': return FlxEase.backIn;
			case 'backinout': return FlxEase.backInOut;
			case 'backout': return FlxEase.backOut;
			case 'bouncein': return FlxEase.bounceIn;
			case 'bounceinout': return FlxEase.bounceInOut;
			case 'bounceout': return FlxEase.bounceOut;
			case 'circin': return FlxEase.circIn;
			case 'circinout': return FlxEase.circInOut;
			case 'circout': return FlxEase.circOut;
			case 'cubein': return FlxEase.cubeIn;
			case 'cubeinout': return FlxEase.cubeInOut;
			case 'cubeout': return FlxEase.cubeOut;
			case 'elasticin': return FlxEase.elasticIn;
			case 'elasticinout': return FlxEase.elasticInOut;
			case 'elasticout': return FlxEase.elasticOut;
			case 'expoin': return FlxEase.expoIn;
			case 'expoinout': return FlxEase.expoInOut;
			case 'expoout': return FlxEase.expoOut;
			case 'quadin': return FlxEase.quadIn;
			case 'quadinout': return FlxEase.quadInOut;
			case 'quadout': return FlxEase.quadOut;
			case 'quartin': return FlxEase.quartIn;
			case 'quartinout': return FlxEase.quartInOut;
			case 'quartout': return FlxEase.quartOut;
			case 'quintin': return FlxEase.quintIn;
			case 'quintinout': return FlxEase.quintInOut;
			case 'quintout': return FlxEase.quintOut;
			case 'sinein': return FlxEase.sineIn;
			case 'sineinout': return FlxEase.sineInOut;
			case 'sineout': return FlxEase.sineOut;
			case 'smoothstepin': return FlxEase.smoothStepIn;
			case 'smoothstepinout': return FlxEase.smoothStepInOut;
			case 'smoothstepout': return FlxEase.smoothStepInOut;
			case 'smootherstepin': return FlxEase.smootherStepIn;
			case 'smootherstepinout': return FlxEase.smootherStepInOut;
			case 'smootherstepout': return FlxEase.smootherStepOut;
		}
		return FlxEase.linear;
	}

	public static inline function getFPSRatio(ratio:Float):Float
	{
		return FlxMath.bound(ratio * 60 * FlxG.elapsed, 0, 1);
	}

	/**
	 * Modulo that works for negative numbers
	 */
	public inline static function mod(n:Int, m:Int)
	{
		return ((n % m) + m) % m;
	}
}
