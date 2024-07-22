package shaders;

import flixel.addons.display.FlxRuntimeShader;
import openfl.utils.Assets;

class GaussianBlur extends FlxRuntimeShader
{
  public var amount:Float;

  public function new(amount:Float = 1.0)
  {
    super(Assets.getText(data.Paths.frag("gaussianBlur")));
    setAmount(amount);
  }

  public function setAmount(value:Float):Void
  {
    this.amount = value;
    this.setFloat("_amount", amount);
  }
}