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
		/*
		infoTrace("[a-s-d] to adjust playback.");
		infoTrace("[z] to step frame."); 
		infoTrace("ctrl+[0-9] to set save."); 
		infoTrace("[0-9] to load save."); 
		infoTrace("`window.loadSave(slot, string)` to read save data.");
		infoTrace("[r] to load initial state.");
		*/

		var engine = new Engine();
	}
}
