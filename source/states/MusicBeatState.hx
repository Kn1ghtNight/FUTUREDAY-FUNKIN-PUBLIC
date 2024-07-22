package states;

import flixel.text.FlxText.FlxTextBorderStyle;
import objects.FlxFixedText;
import data.ClientPrefs;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.ui.FlxUIState;
import flixel.math.FlxRect;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.util.FlxTimer;
import input.Controls;
import input.PlayerSettings;
import song.Conductor.BPMChangeEvent;
import song.Conductor;
import states.game.PlayState;
import states.substates.CustomFadeTransition;
// YEAAAAAHH BABBBYYY
#if D3D
import d3d.D3DGame;
#end

class MusicBeatState extends FlxUIState
{
	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	private var controls(get, never):Controls;

	private var elapsedTime:Float = 0;

	public static var camBeat:FlxCamera;

	//probably titlestate honestly
	public static var lastKnownStateName:String = "TitleState";

	#if D3D
	public var d3dHandler:D3DGame;

	public var is3DEnabled(default, set):Bool = false;
	#end

	#if D3D
	public function set_is3DEnabled(n:Bool):Bool
	{
		if (n)
		{
			if (d3dHandler != null && !d3dHandler.isActive)
				d3dHandler.isActive = true;
			else if (d3dHandler == null)
			{
				// create.
				final window:lime.ui.Window = openfl.Lib.application.window;
				d3dHandler = new D3DGame(window.width, window.height);

				window.onResize.add((width:Int, height:Int) ->
				{
					trace("window resized");
					d3dHandler.onWindowSizeChanged(width, height);
				});

				window.onActivate.add(() ->
				{
					trace("window activated");
					d3dHandler.onActivated();
				});

				window.onDeactivate.add(() ->
				{
					trace("window deactivated");
					d3dHandler.onDeactivated();
				});

				window.onMinimize.add(() ->
				{
					d3dHandler.onDeactivated();
					trace("minimized");
				});
				window.onMaximize.add(() ->
				{
					d3dHandler.onActivated();
					trace("maximized");
				});
				window.onClose.add(() ->
				{
					d3dHandler.Reset();
				});
			}
		}
		else if (d3dHandler != null)
		{
			d3dHandler.isActive = false;

			if (!(FlxG.state is D3DBase))
				d3dHandler.Reset();
		}

		return is3DEnabled = n;
	}
	#end

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	override function create()
	{
		camBeat = FlxG.camera;
		var skip:Bool = FlxTransitionableState.skipNextTransOut;
		super.create();

		lastKnownStateName = Type.getClassName(Type.getClass(FlxG.state));

		if (!skip)
		{
			openSubState(new CustomFadeTransition(0.7, true));
		}
		FlxTransitionableState.skipNextTransOut = false;
	}

	override function update(elapsed:Float)
	{
		#if D3D
		if (d3dHandler != null && d3dHandler.isActive && is3DEnabled)
			d3dHandler.Tick(elapsed);
		#end

		// everyStep();
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep)
		{
			if (curStep > 0)
				stepHit();

			if (PlayState.SONG != null)
			{
				if (oldStep < curStep)
					updateSection();
				else
					rollbackSection();
			}
		}

		if(FlxG.keys.justPressed.F1)
        	FlxG.switchState(new states.menus.MainMenuState());

		if(FlxG.keys.justPressed.F11)
        	FlxG.fullscreen = !FlxG.fullscreen;

		if(FlxG.keys.justPressed.F5)
        	FlxG.resetState();

		if(FlxG.keys.justPressed.F8)
        	FlxG.switchState(new D3DBase());

		if (FlxG.save.data != null)
			FlxG.save.data.fullscreen = FlxG.fullscreen;

		elapsedTime += elapsed;
		super.update(elapsed);
	}

	private function updateSection():Void
	{
		if (stepsToDo < 1)
			stepsToDo = Math.round(getBeatsOnSection() * 4);
		while (curStep >= stepsToDo)
		{
			curSection++;
			var beats:Float = getBeatsOnSection();
			stepsToDo += Math.round(beats * 4);
			sectionHit();
		}
	}

	private function rollbackSection():Void
	{
		if (curStep < 0)
			return;

		var lastSection:Int = curSection;
		curSection = 0;
		stepsToDo = 0;
		for (i in 0...PlayState.SONG.notes.length)
		{
			if (PlayState.SONG.notes[i] != null)
			{
				stepsToDo += Math.round(getBeatsOnSection() * 4);
				if (stepsToDo > curStep)
					break;

				curSection++;
			}
		}

		if (curSection > lastSection)
			sectionHit();
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep / 4;
	}

	private function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

		var shit = ((Conductor.songPosition - ClientPrefs.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	public static function switchState(nextState:FlxState)
	{
		// add cases later when current state is a d3d state to disable d3d shit and renable flixel stuf
		// Custom made Trans in
		var leState:MusicBeatState = cast(FlxG.state, MusicBeatState);
		if (!FlxTransitionableState.skipNextTransIn)
		{
			leState.openSubState(new CustomFadeTransition(0.6, false));
			if (nextState == FlxG.state)
			{
				CustomFadeTransition.finishCallback = function()
				{
					lastKnownStateName = Type.getClassName(Type.getClass(leState));
					FlxG.resetState();
				};
				// trace('resetted');
			}
			else
			{
				CustomFadeTransition.finishCallback = function()
				{
					lastKnownStateName = Type.getClassName(Type.getClass(nextState));
					FlxG.switchState(nextState);
				};
				// trace('changed state');
			}
			return;
		}
		lastKnownStateName = Type.getClassName(Type.getClass(leState));
		FlxTransitionableState.skipNextTransIn = false;
		FlxG.switchState(nextState);
	}

	public static function resetState()
	{
		MusicBeatState.switchState(FlxG.state);
	}

	public inline static function getState():MusicBeatState
		return cast(FlxG.state, MusicBeatState);

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		// trace('Beat: ' + curBeat);
	}

	public function sectionHit():Void
	{
		// trace('Section: ' + curSection + ', Beat: ' + curBeat + ', Step: ' + curStep);
	}

	function getBeatsOnSection()
	{
		var val:Null<Float> = 4;
		if (PlayState.SONG != null && PlayState.SONG.notes[curSection] != null)
			val = PlayState.SONG.notes[curSection].sectionBeats;
		return val == null ? 4 : val;
	}

	var _message:FlxFixedText;
	var message(get, null):FlxFixedText;

	function get_message()
	{
		if (_message == null)
		{
			_message = new FlxFixedText(0, 0, FlxG.width);
			_message.size = 26;
			_message.borderSize = 1.25;
			_message.alignment = CENTER;
			_message.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			_message.scrollFactor.set();
			_message.screenCenter();
			_message.alpha = 0;
		}

		return _message;
	}

	var messageTween:FlxTween;

	public function showMessage(text:String = "", level = 0, delayUntilFade:Float = 0.5)
	{
		// TODO: Add message queue
		message.alpha = 1;

		message.color = switch (level)
		{
			case 0: 0xFFffffff; // Info
			case 1: 0xFFff0000; // Error
			case 2: 0xFFffFF00; // Warning
			default: 0xFFffffff;
		}
		message.text = text;

		message.screenCenter();

		remove(message, true);
		add(message);

		message.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		if (messageTween != null)
			messageTween.cancel();
		messageTween = FlxTween.tween(message, {alpha: 0}, 1.3, {
			startDelay: delayUntilFade,
			onComplete: (v) ->
			{
				remove(message, true);
			}
		});

		trace(text);
	}
}
