package engine.info;

import song.Conductor;

class ConductorInfo extends FramerateCategory
{
	public function new()
	{
		super("Conductor Info");
	}

	public override function __enterFrame(t:Int)
	{
		if (alpha <= 0.05)
			return;
		_text = 'Current Song Position: ${Math.floor(Conductor.songPosition * 1000) / 1000}';
		_text += '\nCurrent BPM: ${Conductor.bpm}';

		this.text.text = _text;
		super.__enterFrame(t);
	}
}
