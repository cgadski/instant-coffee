package;
import haxe.ds.Option;

enum CoffeeInput {
    StepFrame;
    Pause;
    PlaySlow;
    PlayNormal;
    PlayFast;
    Reset;
    Slot(code: Int);
}

class KeyBindings {
    public static function fromKeyCode(code: Int):Option<CoffeeInput> {
        switch code {
            case 90: return Some(StepFrame);
            case 65: return Some(Pause);
            case 83: return Some(PlaySlow);
            case 68: return Some(PlayNormal);
            case 70: return Some(PlayFast);
            case 82: return Some(Reset);
            case _: {
                if (code >= 48 && code <= 57) {
                    return Some(Slot(code - 48));
                } else {
                    return None;
                }
            }
        }
    }
}

