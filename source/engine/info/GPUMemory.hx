package engine.info;

/**
 * To start tracking GPU memory usage, call `init()` function.
 * 
 * Works only on Windows target.
 */
#if windows
import flixel.FlxG;
import sys.io.Process;
 @:cppInclude('windows.h')
 #end
 class GPUMemory {
     /**
      * Current dedicated GPU memory usage of this application, updates each second.
      * 
      * Will be `0`, if `init()` wasnt called / not supported by target.
      */
     public static var usage(default, null):Float = 0;
 
     /**
      * Will be called on update of `usage` variable.
      */
     public static var onUpdate:Void->Void = () -> {};
 
     @:noCompletion static var usageTracker:Process;
 
     @:noCompletion static function __close() {
         #if windows
         if (usageTracker == null) return;
 
         usageTracker.close();
         Sys.command('taskkill', ['/F', '/PID', usageTracker.getPid() + '']); // WTF POWERSHELL NOT CLOSING WITH CLOSE FUNC
         usageTracker = null;
         #end
     }
 
     /**
      * Starts tracking GPU memory usage, can be got in `usage` variable.
      * 
      * @return `1` if successfully initialized, `2` if was already called / not supported by target.
      */
     public static function init():Int {
         #if windows
         if (usageTracker != null) return 0;
 
         // very cool thing!!!
         // https://stackoverflow.com/a/73496338
         usageTracker = new Process('powershell', ["Get-Counter -Counter '\\GPU Process Memory(pid_" + Std.string(untyped __cpp__('GetCurrentProcessId()')) + "*)\\Dedicated Usage' -Continuous | Foreach-Object {$_.CounterSamples[0].CookedValue}"]);
         FlxG.stage.window.onClose.add(__close);
 
         sys.thread.Thread.create(() -> {
             while(usageTracker != null) {
                 Sys.sleep(1);
                 try {
                     usage = Std.parseFloat(usageTracker.stdout.readLine());
                     //trace('updated ' + usage);
                     onUpdate();
                 }
             }
         });
         return 1;
         #end
         return 0;
     }
 
     /**
      * Terminates tracking GPU memory usage.
      */
     public static function close() {
         __close();
         if (FlxG.stage.window.onClose.has(__close))
             FlxG.stage.window.onClose.remove(__close);
     }
 }