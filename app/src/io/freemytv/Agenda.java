package io.freemytv;

import java.util.Collections;
import java.util.List;

/**
 * Fork: today's appointments for the calendar card. Not linked to any calendar yet, so the card says there are none;
 * a calendar (such as Google Calendar's private iCal address) plugs in here later.
 */
final class Agenda {
    private Agenda() {}

    static final class Event {
        final String time, title;

        Event(String time, String title) {
            this.time = time;
            this.title = title;
        }
    }

    /** Today's appointments in order of time; empty while no calendar is linked. */
    static List<Event> today() {
        return Collections.emptyList();
    }
}
