package states.substates;

import objects.AttachedSprite;
import util.CoolUtil;
import objects.ArtImage;
import states.menus.ArtGalleryState;
import data.ClientPrefs;
import data.Paths;
import objects.Alphabet;
import objects.FlxFixedText;
import objects.ArtImage;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxSort;
import sys.FileSystem;
import openfl.filters.GlowFilter;
import openfl.filters.ShaderFilter;
import flixel.FlxSubState;
import flixel.group.FlxGroup;
import flixel.graphics.FlxGraphic;
import data.WeekData;
import flixel.util.FlxTimer;
import flixel.util.FlxGradient;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

using StringTools;

class ArtSubState extends MusicBeatSubstate
{
	var scoreText:FlxFixedText;

	var txtWeekTitle:FlxFixedText;

	private var curSelection:Int = 0;

	var txtTracklist:FlxFixedText;

	var grpImages:FlxTypedGroup<ArtImage>;
	var grpVisualImages:FlxTypedGroup<ArtImage>;

	var difficultySelectors:FlxGroup;
	var sprDifficulty:FlxSprite;
	var upArrow:FlxSprite;
	var downArrow:FlxSprite;

	var loadedImages:Array<String> = [];

	var origImages:Array<String> = [];
	var totalImages:Int;
	var totalFakeImages:Int;

	var wrapAround:Int = 0;

	var realSelected:Int;
	var wrappedSelected:Int;

	var imageCounter:FlxFixedText;

	var credit:Alphabet;
	var support:Alphabet;

	static var exclude = ["og look by rechi"];

	override function create()
	{
		persistentUpdate = persistentDraw = true;

		var bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.setGraphicSize(FlxG.width);
		bg.updateHitbox();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);
		bg.screenCenter();

		var bars = new FlxSprite().loadGraphic(Paths.image('freeplay/bars'));
		bars.scale.set(0.66, 0.66);
		bars.updateHitbox();
		bars.antialiasing = ClientPrefs.globalAntialiasing;
		// add(bars);
		bars.angle = -2;
		bars.screenCenter();

		var titleSpr = new FlxSprite().loadGraphic(Paths.image('title'));
		titleSpr.scale.set(0.66, 0.66);
		// titleSpr.updateHitbox();
		titleSpr.antialiasing = ClientPrefs.globalAntialiasing;
		titleSpr.screenCenter(X);
		titleSpr.y -= 100;
		add(titleSpr);

		var title = new Alphabet(0, 25, ArtGalleryState.selectedCategoryName);
		title.screenCenter(X);
		title.y -= 30;
		add(title);

		if (ArtGalleryState.selectedCategoryName.contains(" "))
		{ // Fixes some weird spacing
			titleSpr.scale.x = title.width / (titleSpr.frameWidth - 350);
		}
		else
		{
			titleSpr.scale.x = title.width / (titleSpr.frameWidth - 400);
		}

		credit = new Alphabet(0, 0, "", false);
		credit.scaleX = 0.6;
		credit.scaleY = 0.6;
		credit.alignment = CENTERED;
		add(credit);

		var enter = new AttachedSprite();
		enter.loadGraphic(Paths.image("enter"));
		enter.scale.set(0.4, 0.4);
		enter.updateHitbox();
		enter.antialiasing = ClientPrefs.globalAntialiasing;

		enter.xAdd = -60;
		enter.yAdd = 60;

		add(enter);
		support = new Alphabet(0, 0, "Support the artist", false);
		// supportTitle.x = enter.x + 10;
		support.screenCenter(X);
		support.y = FlxG.height - 70 - 50 + 100;
		support.scaleX = 0.6;
		support.scaleY = 0.6;
		enter.sprTracker = support;
		add(support);

		grpImages = new FlxTypedGroup<ArtImage>();
		grpVisualImages = new FlxTypedGroup<ArtImage>();
		add(grpVisualImages);

		var folder = Paths.getPreloadPath("images/artgallery/" + ArtGalleryState.selectedCategory + "/");

		loadedImages = [];

		trace(folder);

		if (FileSystem.exists(folder))
		{
			for (image in FileSystem.readDirectory(folder))
			{
				if (image.endsWith(".png") || image.endsWith(".jpg"))
				{
					if (!loadedImages.contains(image))
					{
						if (exclude.contains(image.toLowerCase().replace(".jpg", "").replace(".png", "")))
						{
							continue;
						}
						loadedImages.push(image);
					}
				}
			}
		}

		#if sys
		var infoFile:Array<String> = CoolUtil.coolTextFile('assets/images/artgallery/${ArtGalleryState.selectedCategory}/credits.txt');
		#else
		var infoFile:Array<String> = CoolUtil.coolTextFile('artgallery:assets/artgallery/images/${ArtGalleryState.selectedCategory}/credits.txt');
		#end

		var infoMap:Map<String, {url:String, artist:String}> = [];

		for (info in infoFile)
		{
			var data = info.split("|");

			var key = data[0].toLowerCase();

			infoMap[key] = {
				url: data[2],
				artist: data[1]
			};
		}

		trace(infoMap);

		var images = loadedImages;

		trace("Images: ", images);

		// Make sure its always infinite
		if (images.length <= 2)
		{
			var _origImages = images.copy();
			for (_week in _origImages)
				images.push(_week);
			for (_week in _origImages)
				images.push(_week);
		}
		if (images.length <= 4)
		{
			var _origImages = images.copy();
			for (_week in _origImages)
				images.push(_week);
		}

		// Duplicate Images
		origImages = images.copy();
		totalImages = origImages.length;
		for (_week in origImages)
			images.push(_week);
		for (_week in origImages)
			images.push(_week);
		totalFakeImages = images.length;

		var num:Int = 0;
		for (i in 0...images.length)
		{
			var image = images[i].replace(".jpg", "").replace(".png", "");
			var weekThing:ArtImage = new ArtImage(0, 0, image, 'artgallery/' + ArtGalleryState.selectedCategory, images[i].endsWith(".jpg"));
			weekThing.screenCenter();
			weekThing.y -= 15; // 58
			weekThing.x += 250 * num;
			weekThing.targetItem = num;
			weekThing.index = num;
			// weekThing.cameras = [camPortraits];
			if (infoMap.exists(image.toLowerCase()))
			{
				var info = infoMap[image.toLowerCase()];
				weekThing.url = info.url;
				weekThing.artist = info.artist;
			}
			grpVisualImages.add(weekThing);
			grpImages.add(weekThing);

			weekThing.antialiasing = ClientPrefs.globalAntialiasing;
			num++;
		}

		arrowLeft = new FlxSprite();
		arrowLeft.frames = Paths.getSparrowAtlas("artgallery/arrows");
		arrowLeft.animation.addByPrefix("idle", "arrow0", 24, true);
		arrowLeft.animation.addByPrefix("press", "arrow press0", 24, false);
		arrowLeft.animation.play("idle");
		arrowLeft.updateHitbox();
		arrowLeft.screenCenter();
		arrowLeft.x -= 300;
		arrowLeft.scale.set(0.6, 0.6);
		arrowLeft.antialiasing = ClientPrefs.globalAntialiasing;
		arrowLeft.flipX = true;
		add(arrowLeft);

		arrowRight = new FlxSprite();
		arrowRight.frames = Paths.getSparrowAtlas("artgallery/arrows");
		arrowRight.animation.addByPrefix("idle", "arrow0", 24, true);
		arrowRight.animation.addByPrefix("press", "arrow press0", 24, false);
		arrowRight.animation.play("idle");
		arrowRight.updateHitbox();
		arrowRight.screenCenter();
		arrowRight.x += 300;
		arrowRight.scale.set(0.6, 0.6);
		arrowRight.antialiasing = ClientPrefs.globalAntialiasing;
		arrowRight.flipX = false;
		add(arrowRight);

		imageCounter = new FlxFixedText(0, 0, 100, "0/0");
		imageCounter.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		imageCounter.y = FlxG.height - imageCounter.height - 10;
		add(imageCounter);

		changeSelection(0);

		super.create();
	}

	static inline var arrowIdleScale = 0.75;
	static inline var arrowPressedScale = 0.65;

	override public function destroy():Void
	{
		super.destroy();
	}

	var disableSelect = 0.5;
	var arrowLeft:FlxSprite;
	var arrowRight:FlxSprite;

	override function update(elapsed:Float)
	{
		var leftP = controls.UI_LEFT_P;
		var rightP = controls.UI_RIGHT_P;
		if (leftP)
		{
			changeSelection(-1);
			arrowLeft.animation.play("press");
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}

		if (rightP)
		{
			changeSelection(1);
			arrowRight.animation.play("press");
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}

		if (arrowLeft.animation.finished && arrowLeft.animation.name == "press")
			arrowLeft.animation.play("idle");
		if (arrowRight.animation.finished && arrowRight.animation.name == "press")
			arrowRight.animation.play("idle");

		if (disableSelect <= 0 && controls.ACCEPT)
		{
			var curImage = grpImages.members[realSelected];
			trace(curImage, realSelected, curImage.url, curImage.artist);
			if (curImage.url != "")
			{
				CoolUtil.browserLoad(curImage.url);
			}
		}

		disableSelect -= elapsed;

		if (controls.BACK && !movedBack)
		{
			close();
			movedBack = true;
		}

		super.update(elapsed);
	}

	override function openSubState(subState:FlxSubState)
	{
		super.openSubState(subState);
	}

	override function beatHit()
	{
		super.beatHit();
	}

	var movedBack:Bool = false;

	function changeSelection(change:Int = 0):Void
	{
		curSelection += change;

		var totalImages = origImages.length;

		var reall = curSelection - totalImages * wrapAround;
		var real = reall - totalImages;

		if (real >= totalImages)
		{
			wrapAround++;
		}
		if (real < 0)
		{
			wrapAround--;
		}

		realSelected = CoolUtil.mod(curSelection, totalImages);
		wrappedSelected = CoolUtil.mod(curSelection, totalFakeImages);

		imageCounter.text = (realSelected + 1) + "/" + totalImages;

		imageCounter.x = FlxG.width - 10 - imageCounter.width;

		for (item in grpImages.members)
		{
			item.targetItem = CoolUtil.mod(item.index - curSelection + totalImages, loadedImages.length) - totalImages;

			if (Math.abs(item.targetItem) > 4)
			{
				item.visible = false;
			}
			else
			{
				item.visible = true;
			}
		}

		var image = grpImages.members[realSelected];
		var offset = (image.imageSpr.frameWidth * image.selectedScale) / 2 + 150;
		trace(offset, image.imageSpr.frameWidth, image.selectedScale);
		FlxTween.cancelTweensOf(arrowLeft);
		FlxTween.cancelTweensOf(arrowRight);
		FlxTween.tween(arrowLeft, {x: ((FlxG.width - arrowLeft.width) / 2) - offset}, 0.3);
		FlxTween.tween(arrowRight, {x: ((FlxG.width - arrowRight.width) / 2) + offset}, 0.3);

		if (image.artist != "")
		{
			credit.visible = true;
			credit.set_text(image.artist);
			credit.screenCenter(XY);
			var y = (image.imageSpr.frameHeight * image.selectedScale) / 2 - 50;
			credit.y += y;
			credit.y -= 40;
			FlxTween.cancelTweensOf(credit);
			FlxTween.tween(credit, {y: credit.y + 40}, 0.15);
		}
		else
		{
			credit.visible = false;
		}

		if (image.url != "")
		{
			// support.visible = true;

			FlxTween.cancelTweensOf(support);
			FlxTween.tween(support, {y: FlxG.height - 70 - 50}, 0.15);

			// credit.changeText(image.artist);
			// credit.screenCenter(XY);
			// for(credit in credit.lettersArray) {
			//	credit.colorTransform.color = 0xffffff;
			// }
			// var y = (image.imageSpr.frameHeight * image.selectedScale) / 2 - 50;
			// credit.y += y;
			// credit.y -= 40;
			// FlxTween.cancelTweensOf(credit);
			// FlxTween.tween(credit, {y: credit.y + 40}, 0.15);
		}
		else
		{
			// support.visible = false;
			FlxTween.cancelTweensOf(support);
			FlxTween.tween(support, {y: FlxG.height - 70 - 50 + 100}, 0.15);
		}

		grpVisualImages.sort(byZ, FlxSort.DESCENDING);
	}

	public static inline function byZ(Order:Int, Obj1:ArtImage, Obj2:ArtImage):Int
	{
		return FlxSort.byValues(Order, Math.abs(Obj1.targetItem), Math.abs(Obj2.targetItem));
	}
}
