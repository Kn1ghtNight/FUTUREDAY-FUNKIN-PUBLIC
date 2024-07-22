package engine.fancy;

import engine.gc.GarbageCollector;
import states.MusicBeatState;
import flixel.FlxG;
import flixel.FlxCamera;
import states.game.PlayState;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

class FaceOff
{
    //To use Run init() and then faceOff(number) whenever
    public static var cams:Array<FlxCamera> = [];

    public static function faceOff(phase:Int) { // EXAMPLE
        switch(PlayState.phase){
            case 1:
                FlxTween.tween(cams[0],{y:0},0.2,{ease:FlxEase.expoOut});
            case 6:
                FlxTween.tween(cams[1],{y:0},0.2,{ease:FlxEase.expoOut});
            case 12:
                FlxTween.tween(cams[0],{zoom:0.6},0.8,{ease:FlxEase.backIn});
                FlxTween.tween(cams[1],{zoom:0.6},0.8,{ease:FlxEase.backIn});
            case 16:
                FlxTween.tween(cams[1],{y:-720},0.4,{ease:FlxEase.expoIn});
                FlxTween.tween(cams[0],{y:720},0.4,{ease:FlxEase.expoIn, onComplete:(twn) -> murder()});
        }
    }
    public static function init() {
        cams[0] = new FlxCamera();
        cams[0].copyFrom(PlayState.camGame);
        cams[0].x = 0;
        cams[0].y = 0;
        cams[0].width = 640;
        cams[0].height = 720;
        cams[0].zoom = 1.8;
    
        cams[0].scroll.x = PlayState.dad.getMidpoint().x - 150;
        cams[0].scroll.x = cams[0].scroll.x - (PlayState.dad.cameraPosition[0] - PlayState.opponentCameraOffset[0]);
        cams[0].scroll.y = PlayState.dad.getMidpoint().y - 175;
        cams[0].scroll.y = cams[0].scroll.y + (PlayState.dad.cameraPosition[1] - PlayState.opponentCameraOffset[1]);
        cams[0].scroll.x -= 200;
        cams[0].scroll.y-= 330;
        
        cams[0].target = null;
        FlxG.cameras.add(cams[0]);
        cams[0].y-=720;

    
        cams[1]= new FlxCamera();
        cams[1].copyFrom(PlayState.camGame);
        cams[1].x = 1280/2;
        cams[1].y = 0;
        cams[1].width = 640;
        cams[1].height = 720;
        cams[1].zoom = 2.2;
    
        cams[1].scroll.x = PlayState.boyfriend.getMidpoint().x - 150;
        cams[1].scroll.x = cams[1].scroll.x - (PlayState.boyfriend.cameraPosition[0] - PlayState.boyfriendCameraOffset[0]);
        cams[1].scroll.y = PlayState.boyfriend.getMidpoint().y - 175;
        cams[1].scroll.y = cams[1].scroll.y + (PlayState.boyfriend.cameraPosition[1] - PlayState.boyfriendCameraOffset[1]);
        cams[1].scroll.x -= 200;
        cams[1].scroll.y-= 200;
        cams[1].scroll.y-=150;
        cams[1].target = null;
        FlxG.cameras.add(cams[1]);

        FlxCamera.defaultCameras = [cams[0], cams[1], PlayState.camGame]; // is this really it ? EDIT: NO IT ISNT WHY ARENT THE COUNTDOWNS SHOWING
        cams[0].zoom = 1;
        cams[1].y+= 720;
        cams[0].zoom = 1;
        cams[1].zoom = 1;
        
    }

    public static function murder() { // im retarded forgive me
        cams[1].kill();
        cams[0].kill();
        cams[1].destroy();
        cams[0].destroy();
        
        GarbageCollector.run(true);
    }
}