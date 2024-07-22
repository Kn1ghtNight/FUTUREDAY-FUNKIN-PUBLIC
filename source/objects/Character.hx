package objects;

import flxanimate.FlxAnimate;
import util.CoolUtil;
import haxe.xml.Access;
import data.ClientPrefs;
import data.Paths;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.effects.FlxTrail;
import flixel.animation.FlxBaseAnimation;
import flixel.util.FlxDestroyUtil;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.tweens.FlxTween;
import flixel.util.FlxSort;
import haxe.Json;
import haxe.Json;
import haxe.format.JsonParser;
import openfl.utils.AssetType;
import openfl.utils.Assets;
import openfl.utils.Assets;
import song.Conductor;
import song.Section.SwagSection;
import states.game.PlayState;
import sys.FileSystem;
import sys.io.File;
import engine.animation.FNFAnimationController;

using StringTools;

typedef CharacterFile =
{
	var animations:Array<AnimArray>;
	var image:String;
	var scale:Float;
	var sing_duration:Float;
	var healthicon:String;

	var position:Array<Float>;
	var camera_position:Array<Float>;
	var flip_x:Bool;
	var no_antialiasing:Bool;
	var healthbar_colors:Array<Int>;
	@:optional var _editor_isPlayer:Null<Bool>;
}

typedef AnimArray =
{
	var anim:String;
	var name:String;
	var fps:Int;
	var loop:Bool;
	var indices:Array<Int>;
	var offsets:Array<Int>;
}

class Character extends FlxSprite
{
	public var animOffsets:Map<String, Array<Dynamic>>;
	@:noCompletion private var _spriteType:String = 'sparrow';
	public var debugMode:Bool = false;

	public var isPlayer:Bool = false;
	public var curCharacter:String = DEFAULT_CHARACTER;

	public var colorTween:FlxTween;
	public var holdTimer:Float = 0;
	public var heyTimer:Float = 0;
	public var specialAnim:Bool = false;
	public var animationNotes:Array<Dynamic> = [];
	public var stunned:Bool = false;
	public var singDuration:Float = 4; // Multiplier of how long a character holds the sing pose
	public var idleSuffix:String = '';
	public var danceIdle:Bool = false; // Character use "danceLeft" and "danceRight" instead of "idle"
	public var skipDance:Bool = false;

	public var healthIcon:String = 'face';
	public var animationsArray:Array<AnimArray> = [];

	public var positionArray:Array<Float> = [0, 0];
	public var cameraPosition:Array<Float> = [0, 0];

	public var hasMissAnimations:Bool = false;

	// Used on Character Editor
	public var imageFile:String = '';
	public var jsonScale:Float = 1;
	public var noAntialiasing:Bool = false;
	public var originalFlipX:Bool = false;
	public var healthColorArray:Array<Int> = [255, 0, 0];
	public var editorIsPlayer:Null<Bool> = null;

	public static var DEFAULT_CHARACTER:String = 'bf'; // In case a character is missing, it will use BF on its place

	public static var onCreate:Character->Void;

	public function new(x:Float, y:Float, ?character:String = 'bf', ?isPlayer:Bool = false)
	{
		super(x, y);

		animation = new FNFAnimationController(this);

		animOffsets = new Map<String, Array<Dynamic>>();

		curCharacter = character;
		this.isPlayer = isPlayer;
		antialiasing = ClientPrefs.globalAntialiasing;
		var library:String = null;
		switch (curCharacter)
		{
			// case 'your character name in case you want to hardcode them instead':

			default:
				var characterPath:String = 'characters/' + curCharacter + '.json';

				var path:String = Paths.getPreloadPath(characterPath);
				if (!FileSystem.exists(path))
				{
					path = Paths.getPreloadPath('characters/' + DEFAULT_CHARACTER +
						'.json'); // If a character couldn't be found, change him to BF just to prevent a crash
				}

				var rawJson = File.getContent(path);

				var json:CharacterFile = cast Json.parse(rawJson);
				var spriteType = "sparrow";

				var txtToFind:String = Paths.getPath('images/' + json.image + '.txt', TEXT);

				if (FileSystem.exists(txtToFind) || Assets.exists(txtToFind))
				{
					spriteType = "packer";
				}

				var animToFind:String = Paths.getPath('images/' + json.image + '/Animation.json', TEXT);

				if (FileSystem.exists(animToFind) || Assets.exists(animToFind))
				{
					spriteType = "texture";
				}

				switch (spriteType)
				{
					case "packer":
						frames = Paths.getPackerAtlas(json.image);

					case "sparrow":
						frames = Paths.getSparrowAtlas(json.image);

					case "texture":
						isAnimateAtlas = true;
						atlas = new FlxAnimate();
						atlas.showPivot = false;
						Paths.loadAnimateAtlas(atlas, json.image);
				}
				imageFile = json.image;

				if (json.scale != 1)
				{
					jsonScale = json.scale;
					setGraphicSize(Std.int(width * jsonScale));
					updateHitbox();
				}

				positionArray = json.position;
				cameraPosition = json.camera_position;

				healthIcon = json.healthicon;
				singDuration = json.sing_duration;
				flipX = !!json.flip_x;
				if (json.no_antialiasing)
				{
					antialiasing = false;
					noAntialiasing = true;
				}

				if (json.healthbar_colors != null && json.healthbar_colors.length > 2)
					healthColorArray = json.healthbar_colors;

				antialiasing = !noAntialiasing;
				if (!ClientPrefs.globalAntialiasing)
					antialiasing = false;

				animationsArray = json.animations;
				if(animationsArray != null && animationsArray.length > 0) {
					for (anim in animationsArray) {
						var animAnim:String = '' + anim.anim;
						var animName:String = '' + anim.name;
						var animFps:Int = anim.fps;
						var animLoop:Bool = !!anim.loop; //Bruh
						var animIndices:Array<Int> = anim.indices;
		
						if(!isAnimateAtlas)
						{
							if(animIndices != null && animIndices.length > 0)
								animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
							else
								animation.addByPrefix(animAnim, animName, animFps, animLoop);
						}
						#if flxanimate
						else
						{
							if(animIndices != null && animIndices.length > 0)
								atlas.anim.addBySymbolIndices(animAnim, animName, animIndices, animFps, animLoop);
							else
								atlas.anim.addBySymbol(animAnim, animName, animFps, animLoop);
						}
						#end
		
						if(anim.offsets != null && anim.offsets.length > 1) addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
						else addOffset(anim.anim, 0, 0);
					}
				}
				#if flxanimate
				if(isAnimateAtlas) copyAtlasValues();
				#end
				// trace('Loaded file to character ' + curCharacter);
		}
		originalFlipX = flipX;

		if (animOffsets.exists('singLEFTmiss') || animOffsets.exists('singDOWNmiss') || animOffsets.exists('singUPmiss') || animOffsets.exists('singRIGHTmiss'))
			hasMissAnimations = true;
		recalculateDanceIdle();
		dance();

		if (isPlayer)
		{
			flipX = !flipX;

			/*// Doesn't flip for BF, since his are already in the right place???
				if (!curCharacter.startsWith('bf'))
				{
					// var animArray
					if(animation.getByName('singLEFT') != null && animation.getByName('singRIGHT') != null)
					{
						var oldRight = animation.getByName('singRIGHT').frames;
						animation.getByName('singRIGHT').frames = animation.getByName('singLEFT').frames;
						animation.getByName('singLEFT').frames = oldRight;
					}

					// IF THEY HAVE MISS ANIMATIONS??
					if (animation.getByName('singLEFTmiss') != null && animation.getByName('singRIGHTmiss') != null)
					{
						var oldMiss = animation.getByName('singRIGHTmiss').frames;
						animation.getByName('singRIGHTmiss').frames = animation.getByName('singLEFTmiss').frames;
						animation.getByName('singLEFTmiss').frames = oldMiss;
					}
			}*/
		}

		if (onCreate != null)
			onCreate(this);
	}

	override function update(elapsed:Float)
	{
		if(isAnimateAtlas) atlas.update(elapsed);

		if(debugMode || (!isAnimateAtlas && animation.curAnim == null) || (isAnimateAtlas && atlas.anim.curSymbol == null))
		{
			super.update(elapsed);
			return;
		}
	
		if(heyTimer > 0)
		{
			var rate:Float = (PlayState.instance != null ? PlayState.instance.playbackRate : 1.0);
			heyTimer -= elapsed * rate;
			if(heyTimer <= 0)
			{
				var anim:String = getAnimationName();
				if(specialAnim && (anim == 'hey' || anim == 'cheer'))
				{
					specialAnim = false;
					dance();
				}
				heyTimer = 0;
			}
		}
		else if(specialAnim && isAnimationFinished())
		{
			specialAnim = false;
			dance();
		}
		else if (getAnimationName().endsWith('miss') && isAnimationFinished())
		{
			dance();
			finishAnimation();
		}
	
		switch(curCharacter)
		{
			case 'pico-speaker':
				if(animationNotes.length > 0 && Conductor.songPosition > animationNotes[0][0])
				{
					var noteData:Int = 1;
					if(animationNotes[0][1] > 2) noteData = 3;

					noteData += FlxG.random.int(0, 1);
					playAnim('shoot' + noteData, true);
					animationNotes.shift();
				}
				if(isAnimationFinished()) playAnim(getAnimationName(), false, false, animation.curAnim.frames.length - 3);
		}
	
			if (getAnimationName().startsWith('sing')) holdTimer += elapsed;
			else if(isPlayer) holdTimer = 0;
	
			if (holdTimer >= Conductor.stepCrochet * (0.0011 #if FLX_PITCH / (FlxG.sound.music != null ? FlxG.sound.music.pitch : 1) #end) * singDuration)
			{
				dance();
				holdTimer = 0;
			}
	
			var name:String = getAnimationName();
			if(isAnimationFinished() && animOffsets.exists('$name-loop'))
				playAnim('$name-loop');
	
			super.update(elapsed);
	}

	inline public function isAnimationNull():Bool
		return !isAnimateAtlas ? (animation.curAnim == null) : (atlas.anim.curSymbol == null);

	inline public function getAnimationName():String
	{
		var name:String = '';
		@:privateAccess
		if(!isAnimationNull()) name = !isAnimateAtlas ? animation.curAnim.name : atlas.anim.lastPlayedAnim;
		return (name != null) ? name : '';
	}

	public function isAnimationFinished():Bool
	{
		if(isAnimationNull()) return false;
		return !isAnimateAtlas ? animation.curAnim.finished : atlas.anim.finished;
	}

	public function finishAnimation():Void
	{
		if(isAnimationNull()) return;

		if(!isAnimateAtlas) animation.curAnim.finish();
		else atlas.anim.curFrame = atlas.anim.length - 1;
	}

	public var animPaused(get, set):Bool;
	private function get_animPaused():Bool
	{
		if(isAnimationNull()) return false;
		return !isAnimateAtlas ? animation.curAnim.paused : atlas.anim.isPlaying;
	}
	private function set_animPaused(value:Bool):Bool
	{
		if(isAnimationNull()) return value;
		if(!isAnimateAtlas) animation.curAnim.paused = value;
		else
		{
			if(value) atlas.anim.pause();
			else atlas.anim.resume();
		} 

		return value;
	}

	public var danced:Bool = false;

	/**
	 * FOR GF DANCING SHIT
	 */
	public function dance()
	{
		if (!debugMode && !skipDance && !specialAnim)
		{
			if (danceIdle)
			{
				danced = !danced;

				if (danced)
					playAnim('danceRight' + idleSuffix);
				else
					playAnim('danceLeft' + idleSuffix);
			}
			else if (animOffsets.exists('idle' + idleSuffix))
			{
				playAnim('idle' + idleSuffix);
			}
		}
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		specialAnim = false;
		if(!isAnimateAtlas) animation.play(AnimName, Force, Reversed, Frame);
		else atlas.anim.play(AnimName, Force, Reversed, Frame);
	
		if (animOffsets.exists(AnimName))
		{
			var daOffset = animOffsets.get(AnimName);
			offset.set(daOffset[0], daOffset[1]);
		}
		else offset.set(0, 0);

		if (curCharacter.startsWith('gf-') || curCharacter == 'gf')
		{
			if (AnimName == 'singLEFT')
				danced = true;

			else if (AnimName == 'singRIGHT')
				danced = false;

			if (AnimName == 'singUP' || AnimName == 'singDOWN')
				danced = !danced;
		}
	}

	function sortAnims(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);
	}

	public var danceEveryNumBeats:Int = 2;

	private var settingCharacterUp:Bool = true;

	public function recalculateDanceIdle()
	{
		var lastDanceIdle:Bool = danceIdle;
		danceIdle = (animation.getByName('danceLeft' + idleSuffix) != null && animation.getByName('danceRight' + idleSuffix) != null);

		if (settingCharacterUp)
		{
			danceEveryNumBeats = (danceIdle ? 1 : 2);
		}
		else if (lastDanceIdle != danceIdle)
		{
			var calc:Float = danceEveryNumBeats;
			if (danceIdle)
				calc /= 2;
			else
				calc *= 2;

			danceEveryNumBeats = Math.round(Math.max(calc, 1));
		}
		settingCharacterUp = false;
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}

	public function quickAnimAdd(name:String, anim:String)
	{
		animation.addByPrefix(name, anim, 24, false);
	}

	public function getAnimationsFromXml():Array<String>
		{
			var arr:Array<String> = []; // ill add atlas support later probably
			if (Paths.fileExists('images/$imageFile.xml', TEXT)) {
				switch (_spriteType) {
					case 'sparrow':
						var data:Access = new Access(Xml.parse(Paths.getTextFromFile('images/$imageFile.xml')).firstElement());
						for (texture in data.nodes.SubTexture) arr.push(texture.att.name.substr(0, texture.att.name.length - 3));
					//? do i need substr here? i cant really check since no one uses these
					case 'packer':
						var data = Paths.getTextFromFile('images/$imageFile.xml').trim().split('\n');
						for (i in 0...data.length)
						{
							var currImageData = data[i].split("=");
							arr.push(currImageData[0].trim());
						}
					/*case 'texpack':
						var xml = Xml.parse(Paths.getTextFromFile('images/$imageFile.xml'));
						for (sprite in xml.firstElement().elements()) arr.push(sprite.get("n"));*/
				}		
			}
			return CoolUtil.removeDuplicates(arr);
		}

		public var isAnimateAtlas:Bool = false;

		#if flxanimate
		public var atlas:FlxAnimate;
		public override function draw()
		{
			if(isAnimateAtlas)
			{
				copyAtlasValues();
				atlas.draw();
				return;
			}
			super.draw();
		}
	
		public function copyAtlasValues()
		{
			@:privateAccess
			{
				atlas.cameras = cameras;
				atlas.scrollFactor = scrollFactor;
				atlas.scale = scale;
				atlas.offset = offset;
				atlas.origin = origin;
				atlas.x = x;
				atlas.y = y;
				atlas.angle = angle;
				atlas.alpha = alpha;
				atlas.visible = visible;
				atlas.flipX = flipX;
				atlas.flipY = flipY;
				atlas.shader = shader;
				atlas.antialiasing = antialiasing;
				atlas.colorTransform = colorTransform;
				atlas.color = color;
			}
		}
	
		public override function destroy()
		{
			super.destroy();
			destroyAtlas();
		}
	
		public function destroyAtlas()
		{
			if (atlas != null)
				atlas = FlxDestroyUtil.destroy(atlas);
		}
		#end
}