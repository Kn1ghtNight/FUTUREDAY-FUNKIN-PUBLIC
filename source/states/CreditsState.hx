package states;

import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.FlxG;
import states.menus.TitleState;
import flixel.group.FlxSpriteGroup;
import data.Paths;
import openfl.Assets;

class CreditsState extends MusicBeatState
{
    var keyMult:Float = 1;

    var creditsSHIT:Array<Array<Dynamic>> = [
        ['FUTUREDAY GANG', null, true],
        ['Kn1ghtNight', 'kn1ght'],
        ['goofeeSQUARED', 'goofee'],
        ['therealjake_12', null],
        ['MagBros78', 'mag'],
        ['Binos', 'binos'],
        ['Felx Lamp', 'Felx'],
        ['Cinder', 'Cinder'],
        ['Fulanox.Tsu', 'fula'],
        ['TreePlays', 'tree'],
        ['ThouHastLigma', 'liggy'],
        ['Notabraveboi', null],
        ['Fungus', null],
        ['Switchy', 'switchy'],
        ['remixmage', null],
        ['prod_42', 'prod'],
        ['CheriPop', 'cheri'],
        ['loozenhehe', null],
        ['applemcfruit', 'sarupple'],
        ['lunarcleint', 'lunar'],
        ['OneAndOnlyEGGU', 'eggu'],
        ['Raijin', null],
        ['Boxyyyy_', 'boxy'],
    ];

    var creditGroup:FlxSpriteGroup;

    public function new() {
        super();
    }

    public override function create() {
        super.create();

        creditGroup = new FlxSpriteGroup(24, FlxG.height);
        doCreds();

        add(creditGroup);
    }

    function doCreds()
    {
        var y:Float = 0;

        for (textt in creditsSHIT) {
            if (textt[2] != null && textt[2] == true) {
                var header = ahhh(textt[0], y, true);
                header.bold = true;
                creditGroup.add(header);
                y += 24 + (header.textField.numLines * 24) + 75;
            } else {
                var entry = ahhh(textt[0], y, false);
                creditGroup.add(entry);
                y += (24 * entry.textField.numLines) + 75;
                addIcon(entry.x + entry.width + 25, (y - 125.5), textt[1]);
            }
        }

        // Padding between each role.
        y += 24 * 2.5;
    }

    function ahhh(text:String, day:Float, isHeader:Bool):FlxText
    {
        var creditsLine:FlxText = new FlxText(0, day, 0, text).setFormat(Paths.font('neuro.ttf'), (isHeader ? 48 : 24), FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        creditsLine.screenCenter(X);
        return creditsLine;
    }

    function addIcon(eX:Float, eY:Float, namee:String)
    {
        var iconah:FlxSprite = new FlxSprite(eX, eY);

        if (!Assets.exists(Paths.getPath('images/credits/$namee.png', IMAGE))) iconah.loadGraphic(Paths.image('credits/part'));
        else iconah.loadGraphic(Paths.image('credits/$namee'));

        iconah.setGraphicSize(75);
        iconah.updateHitbox();

        creditGroup.add(iconah);
    }

    public override function update(elapsed:Float)
    {
        super.update(elapsed);

        keyMult = 1;

        if (FlxG.keys.pressed.SHIFT)
            keyMult = 1.5;
        else if (FlxG.keys.pressed.TAB)
            keyMult = keyMult * 2; // this may not work!
      
        creditGroup.y -= 75 * elapsed * keyMult;
      
        if (controls.BACK || (hasEnded())) MusicBeatState.switchState(new TitleState());
    }
      
    function hasEnded():Bool
    {
        return creditGroup.y < -creditGroup.height;
    }
}
