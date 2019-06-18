package;

import haxe.ds.Option;

typedef Action = {
	var frame:Int;
	var code:Int;
	var down:Bool;
}

class Video {
	static var headerSize = 6 * 4;
	static var delaySize = 5;
	static var longDelaySize = 10;

	public var actions:Array<Action>;
    public var pauseFrame:Int = 0;

	private function getOption<T>(x:Option<T>):T {
		switch x {
			case None:
				throw "Invalid video string.";
			case Some(x):
				return x;
		}
	}

	public function new(?save:String) {
		actions = new Array();
		if (save != null) {
			// Load from save.
			var reader = new Bitstream.BSReader(save);
			var saveSize = getOption(reader.readInt(headerSize));
			pauseFrame = getOption(reader.readInt(headerSize));
			var frame = 0;
			for (i in 0...saveSize) {
				var longDelay = getOption(reader.read(1))[0];
				var delay = getOption(reader.readInt(longDelay ? longDelaySize : delaySize));
				var code = getOption(reader.readInt(2));
				var down = getOption(reader.read(1));
				frame += delay;
				actions.push({frame: frame, code: code, down: down[0]});
			}
		}
	}

	public function toString():String {
		var writer = new Bitstream.BSWriter();
		writer.writeInt(actions.length, headerSize);
		writer.writeInt(pauseFrame, headerSize);
		var lastFrame = 0;
		for (action in actions) {
			var delay = action.frame - lastFrame;
			lastFrame = action.frame;
			var longDelay = delay >= 32;
			writer.write([longDelay]);
			writer.writeInt(delay, longDelay ? longDelaySize : delaySize);
			writer.writeInt(action.code, 2);
			writer.write([action.down]);
		}
		return writer.toString();
	}

	public static var keyCodes = [37, 38, 39, 88];

	public static function toActionCode(keyCode:Int):Option<Int> {
		for (i in 0...4) {
			if (keyCodes[i] == keyCode)
				return Some(i);
		}
		return None;
	}

	public static function fromActionCode(actionCode:Int): Int {
        return keyCodes[actionCode];
    }

    public static function showActionCode(actionCode: Int): String {
        switch actionCode {
            case 0: return "left ";
            case 1: return "jump ";
            case 2: return "right";
            case 3: return "axe  ";
        }
        return "???";
    }

    public function copy():Video {
        var video = new Video();
        video.actions = actions.copy();
        video.pauseFrame = pauseFrame;
        return video;
    }
}

class VideoRecorder {
    public var video:Video = new Video();
    private var keyStates:Array<Bool>;

    public function new() {
        keyStates = new Array();
        for (i in 0...Video.keyCodes.length) {
            keyStates.push(false);
        }
    }

    public function recordKey(frame: Int, keyCode: Int, down: Bool, silent: Bool) {
        switch Video.toActionCode(keyCode) {
            case Some(action):
                var oldState = keyStates[action];
                if (down == oldState) return;
                keyStates[action] = down;
                video.actions.push({frame: frame, code: action, down: down});
				if (!silent) trace('---> ${Video.showActionCode(action)} ${down ? "down" : "up  "} @ ${frame}');
            case None:
                return;
        }
    }

    public function saveVideo(frame: Int):Video {
        var res = video.copy();
        res.pauseFrame = frame;
        return res;
    }
}

class VideoPlayer {
    public var video: Video;

    public function new(video: Video) {
        this.video = video.copy();
    }

    public function getActions(frame: Int): Array<{code: Int, down: Bool}> {
        var res = [];
        while (video.actions.length > 0 && video.actions[0].frame == frame) {
            var action = video.actions.shift();
            res.push({code: Video.fromActionCode(action.code), down: action.down});
        }
        return res;
    }
}
