package engine.info;

import flixel.util.FlxColor;
import util.CoolUtil;
import openfl.text.TextFormat;
import openfl.display.Sprite;
import openfl.text.TextField;

class MemoryCounter extends Sprite
{
	public var memoryText:TextField;
	public var memoryPeakText:TextField;
	public var vramText:TextField; // to measure cur vram usage by the game / process
	public var vramPeakText:TextField; // max vram used by process

	public var memory:Float = 0;
	public var memoryPeak:Float = 0;
	public var vram:Float = 0;
	public var vramPeak:Float = 0;

	public function new()
	{
		super();

		GPUMemory.init();

		memoryText = new TextField();
		memoryPeakText = new TextField();
		vramText = new TextField();
		vramPeakText = new TextField();

		for (label in [memoryText, memoryPeakText])
		{
			label.autoSize = LEFT;
			label.x = 0;
			label.y = 0;
			label.text = "FPS";
			label.multiline = label.wordWrap = false;
			label.defaultTextFormat = new TextFormat(Framerate.fontName, 12, -1);
			addChild(label);
		}

		for (label in [vramText, vramPeakText])
		{
			label.autoSize = LEFT;
			label.x = 0;
			label.y = 12;
			label.text = "FPS";
			label.multiline = label.wordWrap = false;
			label.defaultTextFormat = new TextFormat(Framerate.fontName, 12, -1);
			addChild(label);
		}
		memoryPeakText.alpha = 0.5;
	}

	public override function __enterFrame(t:Int)
	{
		if (alpha <= 0.05)
			return;
		super.__enterFrame(t);

		memory = MemoryUtil.currentMemUsage();
		vram = GPUMemory.usage;
		if (memoryPeak < memory)
			memoryPeak = memory;

		if (vramPeak < vram)
			vramPeak = vram;
		memoryText.text = CoolUtil.getSizeString(memory);
		memoryPeakText.text = ' / ${CoolUtil.getSizeString(memoryPeak)}';
		vramText.text = CoolUtil.getSizeString(vram);
		vramPeakText.text = ' / ${CoolUtil.getSizeString(vramPeak)}';

		for (label in [memoryText]) {
            label.textColor = FlxColor.WHITE;
            if (memory >= 0.8 * memoryPeak) { // if memory is using more than 80% of memoryPeak
                label.textColor = FlxColor.RED;
            } else if (memory >= 0.65 * memoryPeak) { // if memory is using more than 65% of memoryPeak
                label.textColor = FlxColor.ORANGE;
            }
        }

		vramPeakText.x = vramText.x + vramText.width;
		memoryPeakText.x = memoryText.x + memoryText.width;
	}
}
