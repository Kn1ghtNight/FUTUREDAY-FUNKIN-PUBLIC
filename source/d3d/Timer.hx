#if D3D
package d3d;

import haxe.Int64Helper;
import haxe.Int64;
#if windows
import com.LargeInteger;
import d3d.CPPTypes;
#end
#if cpp
import cpp.Star;

using cpp.Native;
#end

// https://github.com/walbourn/directx-vs-templates/blob/main/d3d11game_win32/StepTimer.h
class Timer
{
	private var elapsedTicks:Float = 0;
	private var totalTicks:Float = 0;
	private var leftOverTicks:Float = 0;
	private var frameCount:Float = 0;
	private var framesPerSecond:Float = 0;
	private var framesThisSecond:Float = 0;
	private var qpcSecondCounter:LargeInteger = LargeInteger.createPtr();
	private var isFixedTimestep:Bool = false;

	public static inline final TicksPerSecond:Float = 10000000;

	private var targetElapsedTicks:Float = TicksPerSecond / 60;
	private var qpcFrequency:LargeInteger = LargeInteger.createPtr();
	private var qpcLastTime:LargeInteger = LargeInteger.createPtr();
	private var qpcMaxDelta:LargeInteger = LargeInteger.createPtr();

	public function new()
	{
		if (NativeFunctions.QueryPerformanceFrequency(qpcFrequency) != 1)
		{
			throw 'Couldn\'t retrieve CPU frequency.';
		}

		if (NativeFunctions.QueryPerformanceCounter(qpcLastTime) != 1)
		{
			throw 'Couldn\'t retrieve program counter.';
		}

		qpcMaxDelta.quadPart = (qpcFrequency.quadPart / Int64.fromFloat(10));
	}

	public inline function GetElapsedTicks():Float
		return elapsedTicks;

	public inline function GetElapsedSeconds():Float
		return TicksToSeconds(elapsedTicks);

	public inline function GetTotalTicks():Float
		return totalTicks;

	public inline function GetTotalSeconds():Float
		return TicksToSeconds(frameCount);

	public inline function GetFrameCount():Float
		return frameCount;

	public inline function GetFramesPerSecond():Float
		return framesPerSecond;

	public inline function SetFixedTimeStep(isFixedTimeStep:Bool)
		this.isFixedTimestep = isFixedTimeStep;

	public inline function SetTargetElapsedTicks(targetElapsed:Float)
		this.targetElapsedTicks = targetElapsed;

	public inline function SetTargetElapsedSeconds(targetElapsed:Float)
		this.targetElapsedTicks = SecondsToTicks(targetElapsed);

	private static inline function SecondsToTicks(seconds:Float):Float
		return seconds * TicksPerSecond;

	private static inline function TicksToSeconds(ticks:Float):Float
		return ticks / TicksPerSecond;

	public function ResetElapsedTime():Void
	{
		if (NativeFunctions.QueryPerformanceCounter(qpcLastTime) != 1)
		{
			throw 'Couldn\'t retrieve perfomance counter while resetting elapsed time.';
		}

		leftOverTicks = 0;
		framesPerSecond = 0;
		framesThisSecond = 0;
		qpcSecondCounter = LargeInteger.createPtr();
	}

	public function Tick(updateFunction:Void->Void):Void
	{
		var currentTime:LargeInteger = LargeInteger.createPtr();

		if (NativeFunctions.QueryPerformanceCounter(currentTime) != 1)
		{
			throw 'Couldn\'t retrieve the current time.';
		}

		@:privateAccess
		var deltaTime:Float = Int64Helper.toFloat(currentTime.quadPart.toInt64() - qpcLastTime.quadPart.toInt64());

		qpcLastTime.quadPart = currentTime.quadPart;
		qpcSecondCounter.quadPart += Int64Helper.fromFloat(deltaTime);
		if ((Int64Helper.fromFloat(deltaTime)) > qpcMaxDelta.quadPart)
			deltaTime = Int64Helper.toFloat(qpcMaxDelta.quadPart);

		deltaTime *= TicksPerSecond;
		deltaTime /= Int64Helper.toFloat(qpcFrequency.quadPart);

		final lastFrameCount:Float = frameCount;

		if (isFixedTimestep)
		{
			if (Math.abs(deltaTime - targetElapsedTicks) < TicksPerSecond / 4000)
			{
				deltaTime = targetElapsedTicks;
			}

			leftOverTicks += deltaTime;

			while (leftOverTicks >= targetElapsedTicks)
			{
				elapsedTicks = targetElapsedTicks;
				totalTicks += targetElapsedTicks;
				leftOverTicks -= targetElapsedTicks;
				frameCount++;

				updateFunction();
			}
		}
		else
		{
			elapsedTicks = deltaTime;
			totalTicks += deltaTime;
			leftOverTicks = 0;
			frameCount++;

			updateFunction();
		}

		if (frameCount != lastFrameCount)
		{
			framesThisSecond++;
		}

		// dumbass int64
		@:privateAccess
		if (qpcSecondCounter.quadPart.toInt64() >= qpcFrequency.quadPart.toInt64())
		{
			framesPerSecond = framesThisSecond;
			framesThisSecond = 0;
			qpcSecondCounter.quadPart %= qpcFrequency.quadPart;
		}
	}
}

@:unreflective @:keep
@:include('windows.h')
extern class NativeFunctions
{
	@:native('QueryPerformanceFrequency')
	// lpPerformanceFreq goes out
	static function QueryPerformanceFrequency(lpFrequency:Star<LargeInteger>):BOOL;
	@:native('QueryPerformanceCounter')
	// lpPerformanceCount goes out
	static function QueryPerformanceCounter(lpPerformanceCount:Star<LargeInteger>):BOOL;
}
#end
