package;

import js.Browser;
import haxe.ds.Option;

class PlayControl {
	public var frame:Int = 0; // Frames since level start. Inputs do happen on frame 0!
	public var paused:Bool = false; // If true, wait for frame advance to run.
	public var speed:Int = 1; // 0 for slow, 1 for normal, 2 for super

	public function new() {}
}

class Engine {
	public var control = new PlayControl();
	public var playback:Option<Video.VideoPlayer> = None; // If this is initialized, we're in playback.
	public var recording:Video.VideoRecorder = new Video.VideoRecorder();
	public var slot:Video = new Video();

	var pausedCallback:Option<Dynamic> = None;
	var fakeTime:Float = 0;

	var _requestAnimationFrame:Dynamic;
	var _now:Dynamic;

	public function new() {
		// Inject our methods into the global scope.
		_requestAnimationFrame = Browser.window.requestAnimationFrame;
		_now = Browser.window.performance.now;
		untyped window.requestAnimationFrame = this.requestAnimationFrame;
		untyped window.performance.now = function() {
			return fakeTime;
		}
		untyped window._keyup = this.keyup;
		untyped window._keydown = this.keydown;

		// Give fakeTime a reasonable initial value.
		fakeTime = _now();
	}

    // Modified requestAnimationFrame.
	private function requestAnimationFrame(callback:Dynamic) {
		switch playback {
			case Some(player):
				triggerPlayback(player);
			case None:
				{}
		}
		fakeTime += 17;
		control.frame += 1;
		if (!control.paused) {
			var cb = function() {
				callback(fakeTime);
			};
			switch control.speed {
				case 0:
					Browser.window.setTimeout(cb, 0.1);
				case 1:
					_requestAnimationFrame(cb);
				case _:
					Browser.window.setTimeout(cb, 0);
			}
		} else {
			pausedCallback = Some(callback);
		}
	}

	private function triggerPlayback(player:Video.VideoPlayer) {
		for (action in player.getActions(control.frame)) {
            sendGameInput(action.code, action.down);
		}
		if (player.done(control.frame))
			playback = None;
	}

	private function triggerPausedCallback() {
		switch pausedCallback {
			case Some(cb):
				pausedCallback = None;
				cb(fakeTime);
			case None:
				{}
		}
	}


	var keyupHandler:Dynamic;
	var keydownHandler:Dynamic;

	private function keyup(callback:Dynamic) {
		keyupHandler = callback;
		Browser.window.onkeyup = function(key) {
            onKey(key.keyCode, false);
		}
	}

	private function keydown(callback:Dynamic) {
		keydownHandler = callback;
		Browser.window.onkeydown = function(key) {
            onKey(key.keyCode, true);
		}
	}

    // Top-level for keyboard input from the user.
    private function onKey(keyCode: Int, down: Bool) {
        sendGameInput(keyCode, down);
        if (down) handleInterfaceInput(keyCode);
    }

    // Send input to the game and record it.
    private function sendGameInput(keyCode: Int, down: Bool) {
        recording.recordKey(control.frame, keyCode, down);
        var event = {which: keyCode, preventDefault: function() {}};
        if (down) {
            keydownHandler(event);
        } else {
            keyupHandler(event);
        }
    }

	// Keyboard interface.
	private function handleInterfaceInput(keyCode:Int) {
		// z to step frames
		if (keyCode == 90 && control.paused) {
			triggerPausedCallback();
		}

		// q to switch pause state
		if (keyCode == 81) {
			control.paused = !control.paused;
			if (!control.paused) {
				triggerPausedCallback();
			}
		}

		// r to reset level
		if (keyCode == 82) {
			trace('level replay string: ${recording.video.toString()}');
			recording = new Video.VideoRecorder();
			control = new PlayControl();
            playback = Some(new Video.VideoPlayer(new Video("uAAA22nACvUwIIHZGW4IFYYZJUqoLIaUGAYrYKKDJBCWDAYqoQAxBAzRAhVEAYlodlpclBKJbJ")));
			triggerPausedCallback();
		}
	}
}