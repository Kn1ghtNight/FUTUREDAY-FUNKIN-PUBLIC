package engine.camera;

import flixel.FlxObject;
import flixel.math.FlxMath;
import flixel.FlxG;
import flixel.math.FlxPoint;
import flixel.math.FlxAngle;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import flixel.FlxCamera;
import flixel.graphics.tile.FlxDrawBaseItem;
import openfl.display.BlendMode;
import flixel.system.FlxAssets.FlxShader;
import flixel.math.FlxMatrix;
import openfl.display.BitmapData;
import flixel.graphics.frames.FlxFrame;
import openfl.geom.ColorTransform;

using flixel.util.FlxColorTransformUtil;
using FunkCamera.FlxMatrixUtil;

// isophoro shut up now i finally had motivation to add this retarded thing in

class FunkCamera extends FlxCamera
{
	public static final betterShake = true;
	public static final betterShakeHardness = .5;
	public static final betterShakeFadeTime = .15;
	public static final useScrollForShake = true;

	var fixer:CameraFixer;

	public function new(X:Int = 0, Y:Int = 0, Width:Int = 0, Height:Int = 0, Zoom:Float = 0)
	{
		super(X, Y, Width, Height, Zoom);
		fixer = new CameraFixer(this);
	}

	override function update(elapsed:Float)
	{
		fixer.update(elapsed);
		super.update(elapsed);
	}

	override function destroy()
	{
		super.destroy();
		fixer.destroy();
	}

	override public function drawPixels(?frame:FlxFrame, ?pixels:BitmapData, matrix:FlxMatrix, ?transform:ColorTransform, ?blend:BlendMode,
			?smoothing:Bool = false, ?shader:FlxShader):Void
	{
		if (transform != null)
		{
			final drawItem = startQuadBatch(frame.parent, inline transform.hasRGBMultipliers(), inline transform.hasRGBAOffsets(), blend, smoothing, shader);
			drawItem.addQuad(frame, matrix, transform);
		}
		else
		{
			final drawItem = startQuadBatch(frame.parent, false, false, blend, smoothing, shader);
			drawItem.addQuad(frame, matrix, transform);
		}
	}
}

class FlxMatrixUtil
{
	public static function skew(mat:FlxMatrix, x = .0, y = .0)
	{
		var skb = Math.tan(y * FlxAngle.TO_RAD);
		var skc = Math.tan(x * FlxAngle.TO_RAD);

		mat.b = mat.a * skb + mat.b;
		mat.c = mat.c + mat.d * skc;

		mat.ty = mat.tx * skb + mat.ty;
		mat.tx = mat.tx + mat.ty * skc;

		return mat;
	}
}

class CameraFixer implements IFlxDestroyable
{
	public var active = true;

	var transform = new FlxMatrix();
	var _matrix = new FlxMatrix();

	var scale = FlxPoint.get(1, 1);
	var spriteScale = FlxPoint.get(1, 1);
	var anchorPoint = FlxPoint.get(.5, .5);
	var skew = FlxPoint.get();
	var clipSkew = FlxPoint.get();
	var scrollOffset = FlxPoint.get();
	var _lastScrollOffset = FlxPoint.get();
	var viewOffset = FlxPoint.get();

	var ignoreScaleMode = false;

	var fxShakeIntensity = 0.;
	var fxShakeDuration = -1000.;
	var fxShakeI = -99999.;

	var cam:FlxCamera;

	var target(get, null):FlxObject;

	inline function get_target()
		return cam.target;

	var _targetPosition = FlxPoint.get();

	public function update(e:Float)
	{
		((target != null) ? target.getPosition(_targetPosition) : cam.scroll).subtractPoint(_lastScrollOffset);
		var scaleModeX = ignoreScaleMode ? 1 : FlxG.scaleMode.scale.x;
		var scaleModeY = ignoreScaleMode ? 1 : FlxG.scaleMode.scale.y;
		var initialZoom = cam.initialZoom;

		var cool = (FunkCamera.betterShake ? -FunkCamera.betterShakeFadeTime : 0);

		fxShakeDuration = (fxShakeDuration > cool ? fxShakeDuration - e : cool);

		// scary
		@:privateAccess {
			if (cam._fxShakeIntensity > 0 && cam._fxShakeDuration > 0)
			{
				fxShakeIntensity = cam._fxShakeDuration;
				fxShakeDuration = cam._fxShakeDuration;
				cam._fxShakeIntensity = 0;
			}
		}

		scale.set(cam.scaleX, cam.scaleY);

		viewOffset.set(cam.x, cam.y);

		skew.set();

		if (fxShakeDuration > cool)
		{
			var sX = fxShakeIntensity * cam.width; // hi im sr. X! from bfb aya sus ayo asus ayo suss hello
			var sY = fxShakeIntensity * cam.height;

			var rX = .0;
			var rY = .0;
			var rAngle = .0;
			var rSkewX = .0;
			var rSkewY = .0;
			if (FunkCamera.betterShake)
			{
				var w = (fxShakeDuration / -cool) + 1;
				var ww = FlxMath.bound(w, 0, 1) * (-FunkCamera.betterShakeHardness + 1); // yo mama make my hardnes to waerbasflhjkdakhj
				var www = FlxMath.bound(w, 0, 1) * FunkCamera.betterShakeHardness;

				fxShakeI += FlxMath.bound((fxShakeIntensity * 7) + .75, 0, 10) * e * FlxMath.bound(w, 0, 1.5);
				rX = Math.cos(fxShakeI * 97) * sX * ww;
				rY = Math.sin(fxShakeI * 86) * sY * ww;
				rAngle = Math.sin(fxShakeI * 62) * FlxMath.bound(fxShakeIntensity * 66, -60, 60) * ww;
				rSkewX = Math.cos(fxShakeI * 54) * FlxMath.bound(fxShakeIntensity * 12, -4, 4) * ww;
				rSkewY = Math.sin(fxShakeI * 54) * FlxMath.bound(fxShakeIntensity * 12, -1.5, 1.5) * ww;

				if (FunkCamera.betterShakeHardness > 0)
				{
					rX += Math.cos(fxShakeI * 165) * sX * www;
					rY += Math.cos(fxShakeI * 132) * sY * www;
					rAngle += Math.sin(fxShakeI * 111) * FlxMath.bound(fxShakeIntensity * 66, -60, 60) * www;
					rSkewX += Math.sin(fxShakeI * 123) * FlxMath.bound(fxShakeIntensity * 12, -4, 4) * www;
					rSkewY += Math.cos(fxShakeI * 101) * FlxMath.bound(fxShakeIntensity * 12, -1.5, 1.5) * www;
				}
			}
			else
			{
				rX = FlxG.random.float(-sX, sX);
				rY = FlxG.random.float(-sY, sY);
			}
			if (FunkCamera.useScrollForShake && target != null)
			{
				scrollOffset.set(rX, rY);
			}
			else
			{
				viewOffset.add(rX * cam.zoom, rY * cam.zoom);
			}
		}
		else
		{
			scrollOffset.set();
		}

		if (cam.canvas != null)
		{
			var width = cam.width * spriteScale.x;
			var height = cam.height * spriteScale.y;

			var ratio = cam.width / width;

			var aW = width * anchorPoint.x;
			var aH = height * anchorPoint.y;

			var mat = _matrix;
			mat.identity();

			mat.translate(-aW, -aH);

			mat.scale(scale.x, scale.y);

			mat.rotate(cam.angle * FlxAngle.TO_RAD);

			mat.skew(skew.x, skew.y);

			mat.translate(aW, aH);

			mat.translate(viewOffset.x, viewOffset.y);

			mat.scale(scaleModeX * spriteScale.x, scaleModeY * spriteScale.y);

			@:privateAccess
			cam.canvas.__transform.copyFrom(mat);
		}

		cam.flashSprite.rotation = 0;
		cam.flashSprite.x = 0;
		cam.flashSprite.y = 0;
		@:privateAccess
		cam._flashOffset.set(cam.width * .5 * scaleModeX * initialZoom - (cam.x * scaleModeX),
			cam.height * .5 * scaleModeY * initialZoom - (cam.y * scaleModeY));

		if (target != null)
		{
			target.x += scrollOffset.x;
			target.y += scrollOffset.y;
		}
		else
		{
			cam.scroll.addPoint(scrollOffset);
		}
		_lastScrollOffset.copyFrom(scrollOffset);
	}

	public function new(cam:FlxCamera)
	{
		this.cam = cam;
	}

	public function destroy()
	{
		scale.put();
		spriteScale.put();
		anchorPoint.put();
		skew.put();
		clipSkew.put();
		scrollOffset.put();
		_lastScrollOffset.put();
		viewOffset.put();
		_targetPosition.put();
	}
}