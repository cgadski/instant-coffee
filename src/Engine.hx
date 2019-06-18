package;

import js.Browser;
import haxe.ds.Option;

class PlayControl {
	public var frame:Int = 0; // Frames since level start. Inputs do happen on frame 0!
	public var paused:Bool = false; // If true, wait for frame advance to run.
	public var speed:Int = 0; // 0 for slow, 1 for normal, 2 for fast forward.

	public function new() {}

	public function pause() {
		paused = true;
		speed = 0;
	}
}

class Engine {
	public var control = new PlayControl();
	public var playback:Option<Video.VideoPlayer> = None; // If this is initialized, we're in playback.
	public var recording:Video.VideoRecorder = new Video.VideoRecorder();
	public var slots:Array<Video>;

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

		slots = new Array();
		for (i in 0...10) {
			slots.push(new Video());
		}
	}

	private function wrapCallback(callback:Dynamic) {
		return function() {
			fakeTime += 16;

			switch playback {
				case Some(player):
					if (control.frame + 1 >= callback.pauseFrame) {
						control.pause();
					}
					callback(fakeTime);
					for (action in player.getActions(control.frame)) {
						sendGameInput(action.code, action.down);
					}
					if (player.done(control.frame)) {
						playback = None;
					}
				case None:
					callback(fakeTime);
			}

			control.frame += 1;

			if (control.paused) {
				trace('[PAUSE] @ ${control.frame}');
			}
		}
	}

	private function requestAnimationFrame(callback:Dynamic) {
		var wrappedCallback = wrapCallback(callback);
		if (!control.paused) {
			switch control.speed {
				case 0:
					Browser.window.setTimeout(wrappedCallback, 100);
				case 1:
					_requestAnimationFrame(wrappedCallback);
				case _:
					Browser.window.setTimeout(wrappedCallback, 0);
			}
		} else {
			pausedCallback = Some(wrappedCallback);
		}
	}

	private function triggerPausedCallback() {
		switch pausedCallback {
			case Some(cb):
				pausedCallback = None;
				cb();
			case None:
				{}
		}
	}

	var keyupHandler:Dynamic;
	var keydownHandler:Dynamic;

	private function keyup(callback:Dynamic) {
		keyupHandler = callback;
		Browser.window.onkeyup = function(key) {
			onKey(key, false);
		}
	}

	private function keydown(callback:Dynamic) {
		keydownHandler = callback;
		Browser.window.onkeydown = function(key) {
			onKey(key, true);
		}
	}

	// Top-level for keyboard input from the user.
	private function onKey(event:Dynamic, down:Bool) {
		if (!Util.isSome(playback)) {
			var suppress = [83, 87, 65, 68];
			if (suppress.indexOf(event.keyCode) == -1)
				sendGameInput(event.keyCode, down);
		}
		if (down) {
			if (handleInterfaceInput(event.keyCode, event.ctrlKey))
				event.preventDefault();
		}
	}

	// Send input to the game and record it.
	private function sendGameInput(keyCode:Int, down:Bool) {
		recording.recordKey(control.frame, keyCode, down);
		var event = {which: keyCode, preventDefault: function() {}};
		if (down) {
			keydownHandler(event);
		} else {
			keyupHandler(event);
		}
	}

	private function resetControls() {
		for (code in Video.keyCodes) {
			sendGameInput(code, false);
		}
	}

	private function resetLevel() {
		trace("[RESET]");
		recording = new Video.VideoRecorder();
		control = new PlayControl();
		resetControls();
	}

	// Keyboard interface.
	// Return true to signal that input was captured.
	private function handleInterfaceInput(keyCode:Int, ctrlKey:Bool):Bool {
		// z to step frames
		if (keyCode == 90 && control.paused) {
			triggerPausedCallback();
			return true;
		}

		var oldControl = untyped JSON.parse(JSON.stringify(control));

		// a to pause
		if (keyCode == 65) { 
			control.paused = true;
			return true;
		}

		// s to go slow, d to go normal
		if (keyCode == 83 || keyCode == 68) {
			control.paused = false;
			control.speed = keyCode == 83 ? 0 : 1;
			if (oldControl.paused) trace('[PLAY] @ ${control.frame}');
			triggerPausedCallback();
			return true;
		}

		// r to reset level
		if (keyCode == 82) {
			// trace(recording.video.toString());
			resetLevel();
			control.pause();
			triggerPausedCallback();
			return true;
		}

		// 0-9 to replay slot
		if (keyCode >= 48 && keyCode <= 57) {
			resetLevel();
			playback = Some(new Video.VideoPlayer(slots[keyCode - 48]));
			triggerPausedCallback();
		}

		// 0-9 to 

		return false;
	}
}
