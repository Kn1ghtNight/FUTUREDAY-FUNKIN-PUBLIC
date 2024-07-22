package engine.animation;

import flixel.FlxG;
import flixel.animation.FlxAnimationController;

class FNFAnimationController extends FlxAnimationController {

    public override function update(elapsed:Float):Void {
		// shadow mario is infact, not a bald retard. (fix timescale on sparrow sheets / texture atlases, will only play first frame if this code is not active.)
		if (_curAnim != null) {
            var speed:Float = FlxG.timeScale;
            if (followGlobalSpeed) speed *= FlxG.animationTimeScale;
			_curAnim.update(elapsed * speed);
		}
		else if (_prerotated != null) {
			_prerotated.angle = _sprite.angle;
		}
	}
}