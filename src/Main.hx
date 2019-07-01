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
		infoTrace("[r] to load initial state.");
		infoTrace("[a-s-d] to adjust playback.");
		infoTrace("[z] to step frame."); 
		infoTrace("ctrl+[0-9] to set save."); 
		infoTrace("[0-9] to load save."); 
		infoTrace("[p] to play the save in slot 0 in realtime");
		infoTrace("`window.load(string)` to read savestate. You should be already on the correct level.");
		infoTrace("`window.start{Left,Neutral,Right}()` to start the level with a direction key already pressed.");

		var engine = new Engine();
	}
}
