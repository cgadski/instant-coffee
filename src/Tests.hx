import haxe.ds.Option;

class BitstreamTests extends haxe.unit.TestCase {
	public function testBasic() {
        var data = new Array<Int>();
        var head = new Bitstream.BSHead();
        head.write(data, true);
        assertEquals(1, data.length);
        assertEquals(1, data[0]);
        head.increment();
        head.write(data, true);
        assertEquals(1, data.length);
        assertEquals(3, data[0]);
    }

	public function testWrite() {
        var writer = new Bitstream.BSWriter();
        writer.write([true]);
        assertEquals(writer.toString().length, 1);
        assertEquals("B", writer.toString());
        writer.write([false, false, false, false, false]);
        assertEquals("B", writer.toString());
        writer.write([false, false, true]);
        assertEquals("BE", writer.toString());
    }

    public function testInt() {
        var writer = new Bitstream.BSWriter();
        writer.writeInt(1234, 12);
        writer.writeInt(2, 3);
        writer.writeInt(123, 10);
        var reader = new Bitstream.BSReader(writer.toString());
        assertEquals("Some(1234)", Std.string(reader.readInt(12)));
        assertEquals("Some(2)", Std.string(reader.readInt(3)));
        assertEquals("Some(123)", Std.string(reader.readInt(10)));
    }

    public function testRead() {
        var data = [true, false, false, true, true, false, true, false, false, true, true, true, true, false, false, true];
        var writer = new Bitstream.BSWriter();
        writer.write(data);
        var reader = new Bitstream.BSReader(writer.toString());
        assertEquals(Std.string(Some(data)), Std.string(reader.read(data.length)));
    }

    public function testFail() {
        var reader = new Bitstream.BSReader("A");
        assertEquals("None", Std.string(reader.read(10)));
    }
}

class VideoTests extends haxe.unit.TestCase {
    public function testString() {
        var videoA = new Video();
        videoA.pauseFrame = 525;
        videoA.initialDirection = 2;
        videoA.actions.push({frame: 4, code: 1, down: false});
        videoA.actions.push({frame: 400, code: 1, down: true});
        videoA.actions.push({frame: 404, code: 4, down: true});
        videoA.actions.push({frame: 405, code: 2, down: false});
        videoA.actions.push({frame: 500, code: 0, down: true});
        videoA.actions.push({frame: 501, code: 0, down: false});
        videoA.actions.push({frame: 502, code: 2, down: true});
        videoA.actions.push({frame: 520, code: 1, down: false});
        var videoB = new Video(videoA.toString());
        assertEquals(Std.string(videoA.actions), Std.string(videoB.actions));
        assertEquals(videoA.pauseFrame, videoB.pauseFrame);
        assertEquals(videoA.initialDirection, videoB.initialDirection);
        var videoB = videoA.copy();
        assertEquals(Std.string(videoA.actions), Std.string(videoB.actions));
        assertEquals(videoA.pauseFrame, videoB.pauseFrame);
        assertEquals(videoA.initialDirection, videoB.initialDirection);
    }

    public function testSplice() {
        var videoA = new Video();
        videoA.actions.push({frame: 0, code: 1, down: true});
        var videoB = new Video();
        videoA.actions.push({frame: 0, code: 2, down: true});
        var videoAB = Splice.spliceILs([videoA, videoB]);
        assertEquals(Std.string(videoA.actions[0]), Std.string(videoAB.actions[0]));
    }
}

class Tests {
	static function main() {
		var r = new haxe.unit.TestRunner();
		r.add(new BitstreamTests());
		r.add(new VideoTests());
		r.run();
	}
}
