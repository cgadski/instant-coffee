package;

import js.Browser;
import haxe.ds.Option;

class PlayControl {
	public var frame:Int = 0; // Frames since level start. Inputs do happen on frame 0!
	public var paused:Bool = false; // If true, wait for frame advance to run.
	public var speed:Int = 0; // 0 for slow, 1 for normal, 2 for fast forward.
	public var silent:Bool = false; // Hide input messages?

	public function new() {}

	public function pause() {
		paused = true;
		speed = 0;
	}
}

class Engine {
	var control = new PlayControl();
	var playback:Option<Video.VideoPlayer> = None; // If this is initialized, we're in playback.
	var recording:Video.VideoRecorder = new Video.VideoRecorder(0);
	var slots:Array<Video>;

	var fullgameVideo:Null<Array<Video>> = null;
	var pausedCallback:Option<Dynamic> = None;
	var fakeTime:Float = 0;

	var _requestAnimationFrame:Dynamic;
	var _now:Dynamic;
	var initialDirection = 0;

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

		// API for runners
		untyped window.load = function(string:String) {
			slots[0] = new Video(string);
		}
		untyped window.loadFullgame = function(string:String) {
			fullgameVideo = string.split(",").map(function(videoString) {
				return new Video(videoString);
			});
		}
		untyped window.startLeft = function() {
			initialDirection = 1;
		}
		untyped window.startRight = function() {
			initialDirection = 2;
		}
		untyped window.startNeutral = function() {
			initialDirection = 0;
		}

		// hook into the helper script
		untyped window.coffee = {};
		untyped window.coffee.onScene = onScene;

		fakeTime = _now();

		slots = new Array();
		for (i in 0...10) {
			slots.push(new Video());
		}

		control.speed = 1;
	}

	function wrapCallback(callback:Dynamic) {
		return function() {
			fakeTime += 16;

			switch playback {
				case Some(player):
					for (action in player.getActions(control.frame)) {
						sendGameInput(action.code, action.down);
					}
					if (control.frame + 1 >= player.video.pauseFrame && fullgameVideo == null) {
						control.pause();
						trace('[PAUSE] @ ${control.frame + 1}');
						playback = None;
						control.silent = false;
					}
					callback(fakeTime);
				case None:
					callback(fakeTime);
			}

			control.frame += 1;
		}
	}

	function requestAnimationFrame(callback:Dynamic) {
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

	function triggerPausedCallback() {
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

	function keyup(callback:Dynamic) {
		keyupHandler = callback;
		Browser.window.onkeyup = function(key) {
			onKey(key, false);
		}
	}

	function keydown(callback:Dynamic) {
		keydownHandler = callback;
		Browser.window.onkeydown = function(key) {
			onKey(key, true);
		}
	}

	// Top-level for keyboard input from the user.
	function onKey(event:Dynamic, down:Bool) {
		if (!Util.isSome(playback)) {
			var suppress = [83, 87, 65, 68, 82]; // alternate movement keys and `r`
			if (suppress.indexOf(event.keyCode) == -1)
				sendGameInput(event.keyCode, down);
		}
		if (down && fullgameVideo == null) {
			if (handleInterfaceInput(event.keyCode, event.ctrlKey))
				event.preventDefault();
		}
	}

	// Send input to the game and record it.
	function sendGameInput(keyCode:Int, down:Bool) {
		recording.recordKey(control.frame, keyCode, down, control.silent);
		var event = {which: keyCode, preventDefault: function() {}};
		if (down) {
			keydownHandler(event);
		} else {
			keyupHandler(event);
		}
	}

	function primeControls() {
		for (code in Video.keyCodes) {
			sendGameInput(code, false);
		}
		if (initialDirection == 1) {
			trace("---> Holding left.");
			sendGameInput(37, true);
		}
		if (initialDirection == 2) {
			trace("---> Holding right.");
			sendGameInput(39, true);
		}
	}

	function resetLevel(?slot:Int, ?replay:Bool) {
		if (replay == null)
			replay = false;
		trace('[${replay ? "REPLAY" : "RESET to"} ${(slot == null) ? "start" : "slot " + Std.string(slot) + "..."}]');
		sendGameInput(82, true);
		sendGameInput(82, false);
		recording = new Video.VideoRecorder(initialDirection);
		control = new PlayControl();
		primeControls();
	}

	function loadPlayback(video: Video) {
		playback = Some(new Video.VideoPlayer(video));
		initialDirection = video.initialDirection;
	}

	// Keyboard interface.
	// Return true to signal that input was captured.
	function handleInterfaceInput(keyCode:Int, ctrlKey:Bool):Bool {
		// z to step frames
		if (keyCode == 90 && control.paused) {
			triggerPausedCallback();
			return true;
		}

		var oldControl = untyped JSON.parse(JSON.stringify(control));

		// a to pause
		if (keyCode == 65) {
			if (!oldControl.paused)
				trace('[PAUSE] @ ${control.frame + 1}');
			control.pause();
			return true;
		}

		// s to go slow, d to go normal
		if (keyCode == 83 || keyCode == 68) {
			control.paused = false;
			control.speed = keyCode == 83 ? 0 : 1;
			if (oldControl.paused)
				trace('[PLAY] @ ${control.frame}');
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
		if (!ctrlKey && keyCode >= 48 && keyCode <= 57) {
			var slot = keyCode - 48;
			resetLevel(slot);
			loadPlayback(slots[slot]);
			control.speed = 2;
			control.silent = true;
			triggerPausedCallback();
			return true;
		}

		// play slot 0 back in realtime
		if (keyCode == 80) {
			resetLevel(0, true);
			loadPlayback(slots[0]);
			control.speed = 1;
			triggerPausedCallback();
			return true;
		}

		// ctrl +0-9 to save slot
		if (ctrlKey && keyCode >= 48 && keyCode <= 57) {
			control.pause();
			var slot = keyCode - 48;
			var video = recording.saveVideo(control.frame);
			trace('[SAVE slot ${slot}] @ ${control.frame}');
			trace('data: ${video.toString()}');
			slots[slot] = video;
			return true;
		}

		return false;
	}

	function onScene(name: String) {
		if ((fullgameVideo != null) && name.charAt(0) == "L") {
			var level = Std.parseInt(untyped name.slice(5, 10));
			loadPlayback(fullgameVideo[level - 1]);
			primeControls();
			control.paused = false;
			control.frame = 0;
			control.speed = 1;
		}
	}
}
