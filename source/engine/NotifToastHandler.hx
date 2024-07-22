package engine;

import flixel.tweens.FlxEase;
import flixel.text.FlxText;
import data.Paths;
import data.ClientPrefs;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.tweens.FlxTween;
import flixel.group.FlxSpriteGroup;

class NotifToastHandler extends FlxSpriteGroup
{ // making it look more like a notif but still noticeable lol -Kn1ght
	public var onFinish:Void->Void = null;

	var moveTween:FlxTween; // meow fuck out the way

	public function new(desc:String, type:String = 'Warning', ?camera:FlxCamera)
	{
		super(x, y);

		var notifBoxBG:FlxSprite = new FlxSprite(0, 50).makeGraphic(420, 120, FlxColor.BLACK);
		notifBoxBG.alpha = 0.85;
		notifBoxBG.scrollFactor.set();

		var notifIcon:FlxSprite = new FlxSprite(notifBoxBG.x + 10, notifBoxBG.y + 10);
		notifIcon.frames = Paths.getSparrowAtlas('notifAnims');
		notifIcon.animation.addByPrefix('error anim', 'error anim', 24);
		notifIcon.animation.addByPrefix('warning anim', 'warning anim', 24);
		notifIcon.antialiasing = ClientPrefs.globalAntialiasing;
		notifIcon.scrollFactor.set();
		notifIcon.setGraphicSize(Std.int(notifIcon.width * (2 / 3)));
		notifIcon.updateHitbox();

		var title:String = '';

		switch (type)
		{ // awful im sorry
			case 'warn' | 'warning' | 'Warning':
				notifIcon.animation.play('warning anim');
				title = 'Warning!';
			case 'err' | 'error' | 'Error':
				notifIcon.animation.play('error anim');
				title = 'Error!';
		}

		var notifTitle:FlxText = new FlxText(notifIcon.x + notifIcon.width + 20, notifIcon.y + 16, 280, title, 20);
		notifTitle.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, LEFT);
		notifTitle.scrollFactor.set();

		var notifDesc:FlxText = new FlxText(notifTitle.x, notifTitle.y + 32, 280, desc, 16);
		notifDesc.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		notifDesc.scrollFactor.set();

		add(notifBoxBG);
		add(notifIcon);
		add(notifTitle);
		add(notifDesc);

		var cam:Array<FlxCamera> = FlxCamera.defaultCameras;
		if (camera != null)
		{
			cam = [camera];
		}

		x = -520;
		notifBoxBG.cameras = cam;
		notifTitle.cameras = cam;
		notifDesc.cameras = cam;
		notifIcon.cameras = cam;

		moveTween = FlxTween.tween(this, {x: 30}, 0.5, {
			ease: FlxEase.expoOut,
			onComplete: function(twn:FlxTween)
			{
				moveTween = FlxTween.tween(this, {x: -520}, 0.5, {
					startDelay: 2.5,
					ease: FlxEase.expoIn,
					onComplete: function(twn:FlxTween)
					{
						moveTween = null;
						remove(this);
						this.destroy();
						if (onFinish != null)
							onFinish();
					}
				});
			}
		});
	}

	override function destroy()
	{
		if (moveTween != null)
		{
			moveTween.cancel();
		}
		super.destroy();
	}
}
