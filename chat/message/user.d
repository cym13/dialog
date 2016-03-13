module dialog.chat.message.user;

import std.datetime;
import std.typecons;

import dialog.chat.message.theme;
import dialog.chat.message.message;
import dialog.chat.message.identity;

struct UserConfig {
    import std.regex;
    import std.format;

    typeof(regex("")) highlight;
    bool  bell  = true;
    bool  quiet = false;
    Theme theme;
}

UserConfig defaultUserConfig = UserConfig();

enum messageBuffer = 20;
enum reHighlight   = `\b(%s)\b`;

struct User {
    SimpleId      sid;
    UserConfig    config;
    int           colorIdx;
    SysTime       joined;
    Message[]     msg;
    bool          done;
    Nullable!User replyTo;
    bool          closed;

    alias sid this;

    this(SimpleId identity) {
        import std.random: uniform;

        sid     = identity;
        config  = defaultUserConfig;
        joined  = Clock.currTime;
        msg     = Message;
        done    = true;

        colorIdx = uniform(0, 256);
    }

    this(SimpleId identity, Writer dst) {
        // TODO, launch consume in another thread
    }

    /**
     * Rename the user with a new identifier
     */
    void setId(string id) {
        sid.setId(id);
        colorIdx = uniform(0, 256);
    }

    void toogleQuietMode() {
        config.quiet = !config.quiet;
    }

    void wait() {
        while (!done) {}
    }

    /**
     * Disconnect user, stop accepting messages
     */
    void close() {
        synchronized {
            closed = true;
            done   = true;
        }
    }

    /**
     * Consume message buffer into a writer. Will block, should be called in
     * another thread.
     */
    void consume(Writer dst) {
        foreach (m ; msg)
            handleMsg(m, dst);
    }

    void setHighlight(string s) {
        import std.regex;
        import std.format;

        config.highlight = regex(reHighlight.format(s));
    }

    // Ok... maybe I shouldn't have gone the struct route in D after all
    string render(T)(T m) if (__traits(compiles, q{Message msg = m;})) {
        static if (typeid(m) == "PublicMsg")
            return m.renderFor(config) + NEWLINE;

        static if (typeid(m) == "PrivateMsg")
            replyTo = m.from;

        return m.render(config.theme) + NEWLINE;
    }

    void handleMsg(Message m, Writer dst) {
        dst.write(this.render(m));
    }

    void send(Message m) {
        if (closed)
            throw new UserClosedException;

        // TODO
    }
}
