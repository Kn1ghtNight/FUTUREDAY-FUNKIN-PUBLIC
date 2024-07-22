package engine.gc;

#if cpp
import cpp.vm.Gc;
#elseif hl
import hl.Gc;
#elseif java
import java.vm.Gc;
#elseif neko
import neko.vm.Gc;
#end
import openfl.system.System;
import flixel.FlxG;

class GarbageCollector
{
    public static var enabled(never, set):Bool;

    private function new() {}

    public static function init()
    {
        enabled = true;

        FlxG.signals.postStateSwitch.add(() -> GarbageCollector.run(true));
        FlxG.signals.focusLost.add(() -> GarbageCollector.run(true));
    }

    public static function run(major:Bool)
    {
        #if cpp
        Gc.run(major);
        if (major) Gc.compact();
        #elseif hl
        if (major) Gc.major();
        #elseif (java || neko)
        Gc.run(major);
        #else
        System.gc();
        #end
    }
    
    public static function set_enabled(enabled:Bool)
    {
        #if (cpp || hl)
        Gc.enable(enabled);
        #end
        return false;
    }
}