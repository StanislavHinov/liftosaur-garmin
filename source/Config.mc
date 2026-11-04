import Toybox.Lang;

(:background)
module Config {
    const BASE_URL = "https://www.liftosaur.com/api/v1";
    const CLIENT = "liftosaur-garmin/1.1.0";
    const QUEUE_CAP = 200;
    // Storage holds at most 32 KB per value, and a bigger one is an uncatchable Out Of Memory.
    // About 170 sets fit; this leaves room for long names and variables.
    const MAX_WORKOUT_SETS = 120;
    const RETRY_DELAYS = [5, 15, 30, 60];
    const HOLD_MS = 600;
}
