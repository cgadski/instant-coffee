package;

class Main {
	private static function infoTrace(str: String) {
		trace('    ${str}');
	}

	public static function main() {
		trace("  _____           _              _      _____       __  __          
 |_   _|         | |            | |    / ____|     / _|/ _|         
   | |  _ __  ___| |_ __ _ _ __ | |_  | |     ___ | |_| |_ ___  ___ 
   | | | '_ \\/ __| __/ _` | '_ \\| __| | |    / _ \\|  _|  _/ _ \\/ _ \\
  _| |_| | | \\__ \\ || (_| | | | | |_  | |___| (_) | | | ||  __/  __/
 |_____|_| |_|___/\\__\\__,_|_| |_|\\__|  \\_____\\___/|_| |_| \\___|\\___|");
		trace("Instant Coffee is enabled.");
		infoTrace("[r] to reset and pause.");
		infoTrace("[a-s-d] to adjust playback.");
		infoTrace("[z] to step frame."); 
		infoTrace("[0-9] to reset and play back video."); 
		infoTrace("ctrl+[0-9] to save video."); 
		infoTrace("alt+[0-9] to play back video, pausing on frame 1."); 
		infoTrace("[p] to reset and play the video in slot 0 in realtime");
		infoTrace("`window.load(string)` to read video.");
		infoTrace("`window.start{Left,Neutral,Right}()` to configure inputs on frame 0.");

		var engine = new Engine();
	}
}
