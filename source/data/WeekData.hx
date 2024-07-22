package data;

import haxe.Json;
import haxe.format.JsonParser;
import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;
import states.game.PlayState;
import sys.FileSystem;
import sys.io.File;
import sys.io.File;
import util.CoolUtil;

using StringTools;

typedef WeekFile =
{
	// JSON variables
	var songs:Array<Dynamic>;
	var weekCharacters:Array<String>;
	var weekBackground:String;
	var weekBefore:String;
	var storyName:String;
	var weekName:String;
	var freeplayColor:Array<Int>;
	var startUnlocked:Bool;
	var hiddenUntilUnlocked:Bool;
	var hideStoryMode:Bool;
	var hideFreeplay:Bool;
	var directXGamePlay:Bool;
	var difficulties:String;
}

class WeekData
{
	public static var weeksLoaded:Map<String, WeekData> = new Map<String, WeekData>();
	public static var weeksList:Array<String> = [];

	public var folder:String = '';

	// JSON variables
	public var songs:Array<Dynamic>;
	public var weekCharacters:Array<String>;
	public var weekBackground:String;
	public var weekBefore:String;
	public var storyName:String;
	public var weekName:String;
	public var freeplayColor:Array<Int>;
	public var startUnlocked:Bool;
	public var hiddenUntilUnlocked:Bool;
	public var hideStoryMode:Bool;
	public var hideFreeplay:Bool;
	public static var directXGamePlay:Bool;
	public var difficulties:String;

	public var fileName:String;

	public static function createWeekFile():WeekFile
	{
		var weekFile:WeekFile = {
			songs: [
				["Bopeebo", "dad", [146, 113, 253]],
				["Fresh", "dad", [146, 113, 253]],
				["Dad Battle", "dad", [146, 113, 253]]
			],
			weekCharacters: ['dad', 'bf', 'gf'],
			weekBackground: 'stage',
			weekBefore: 'tutorial',
			storyName: 'Your New Week',
			weekName: 'Custom Week',
			freeplayColor: [146, 113, 253],
			startUnlocked: true,
			hiddenUntilUnlocked: false,
			hideStoryMode: false,
			hideFreeplay: false,
			directXGamePlay: false,
			difficulties: ''
		};
		return weekFile;
	}

	// HELP: Is there any way to convert a WeekFile to WeekData without having to put all variables there manually? I'm kind of a noob in haxe lmao
	public function new(weekFile:WeekFile, fileName:String)
	{
		songs = weekFile.songs;
		weekCharacters = weekFile.weekCharacters;
		weekBackground = weekFile.weekBackground;
		weekBefore = weekFile.weekBefore;
		storyName = weekFile.storyName;
		weekName = weekFile.weekName;
		freeplayColor = weekFile.freeplayColor;
		startUnlocked = weekFile.startUnlocked;
		hiddenUntilUnlocked = weekFile.hiddenUntilUnlocked;
		hideStoryMode = weekFile.hideStoryMode;
		hideFreeplay = weekFile.hideFreeplay;
		directXGamePlay = weekFile.directXGamePlay;
		difficulties = weekFile.difficulties;

		this.fileName = fileName;
	}

	public static function reloadWeekFiles(isStoryMode:Null<Bool> = false)
	{
		weeksList = [];
		weeksLoaded.clear();
		var directories:Array<String> = [Paths.getPreloadPath()];
		var originalLength:Int = directories.length;

		var sexList:Array<String> = CoolUtil.coolTextFile(Paths.getPreloadPath('weeks/weekList.txt'));
		for (i in 0...sexList.length)
		{
			for (j in 0...directories.length)
			{
				var fileToCheck:String = directories[j] + 'weeks/' + sexList[i] + '.json';
				if (!weeksLoaded.exists(sexList[i]))
				{
					var week:WeekFile = getWeekFile(fileToCheck);
					if (week != null)
					{
						var weekFile:WeekData = new WeekData(week, sexList[i]);

						if (weekFile != null
							&& (isStoryMode == null
								|| (isStoryMode && !weekFile.hideStoryMode)
								|| (!isStoryMode && !weekFile.hideFreeplay)))
						{
							weeksLoaded.set(sexList[i], weekFile);
							weeksList.push(sexList[i]);
						}
					}
				}
			}
		}

		for (i in 0...directories.length)
		{
			var directory:String = directories[i] + 'weeks/';
			if (FileSystem.exists(directory))
			{
				var listOfWeeks:Array<String> = CoolUtil.coolTextFile(directory + 'weekList.txt');
				for (daWeek in listOfWeeks)
				{
					var path:String = directory + daWeek + '.json';
					if (sys.FileSystem.exists(path))
					{
						addWeek(daWeek, path, directories[i], i, originalLength);
					}
				}

				for (file in FileSystem.readDirectory(directory))
				{
					var path = haxe.io.Path.join([directory, file]);
					if (!sys.FileSystem.isDirectory(path) && file.endsWith('.json'))
					{
						addWeek(file.substr(0, file.length - 5), path, directories[i], i, originalLength);
					}
				}
			}
		}
	}

	private static function addWeek(weekToCheck:String, path:String, directory:String, i:Int, originalLength:Int)
	{
		if (!weeksLoaded.exists(weekToCheck))
		{
			var week:WeekFile = getWeekFile(path);
			if (week != null)
			{
				var weekFile:WeekData = new WeekData(week, weekToCheck);
				if ((PlayState.isStoryMode && !weekFile.hideStoryMode) || (!PlayState.isStoryMode && !weekFile.hideFreeplay))
				{
					weeksLoaded.set(weekToCheck, weekFile);
					weeksList.push(weekToCheck);
				}
			}
		}
	}

	private static function getWeekFile(path:String):WeekFile
	{
		var rawJson:String = null;

		if (OpenFlAssets.exists(path))
		{
			rawJson = Assets.getText(path);
		}

		if (rawJson != null && rawJson.length > 0)
		{
			return cast Json.parse(rawJson);
		}
		return null;
	}

	//   FUNCTIONS YOU WILL PROBABLY NEVER NEED TO USE
	// To use on PlayState.hx or Highscore stuff
	public static function getWeekFileName():String
	{
		return weeksList[PlayState.storyWeek];
	}

	// Used on LoadingState, nothing really too relevant
	public static function getCurrentWeek():WeekData
	{
		return weeksLoaded.get(weeksList[PlayState.storyWeek]);
	}
}
