module dialog.chat.message.message;

import std.datetime;
import std.typecons;
import dialog.chat.message.user;
import dialog.chat.message.theme;

/**
 * Msg is a base type for other message types.
 */
struct Message {
    string  content;
    SysTime timestamp;

    this(string _content) {
        content   = content;
        timestamp = Clock.currTime;
    }

    /**
     * Render message based on a theme
     */
    string  render(Theme*) {
        return this.toString;
    }

    string  toString() {
        return msgBody;
    }

    string  command() {
        return "";
    }
}

Message parseInput(string content, User from) {
    auto m   = PublicMsg(content, from);
    auto cmd = m.parseCommand;

    if (cmd.isNull)
        return m;
    return cmd.get;
}

/**
 * PublicMsg is any message from a user sent to the room
 */
struct PublicMsg {
    Message msg;
    User    from;
    alias msg this;

    this(string _content, User _from) {
        msg  = Message(_content);
        from = _from;
    }

    auto parseCommand() {
        import std.algorithm: startsWith;
        import std.array:     split;

        if (!msg.content.startsWith("/"))
            return Nullable!string();

        auto fields  = content.split;
        auto m       = CommandMsg(msg, fields[0], fields[1..$]);
        return Nullable!CommandMsg(m);
    }

    string render(Theme t) {
        if (t == null)
            return msg.toString;
        return cfg.theme.colorName(from) ~ ": " ~ content;
    }

    string renderFor(UserConfig cfg) {
        if (cfg.highlight  == null
          || cfg.theme     == null
          || cfg.highlight != content)
            return cfg.theme.render;

        content = cfg.highlight.replace(content, cfg.theme.highlight("${1}"));

        if (cfg.bell)
            content ~= BEL;

        return cfg.theme.colorName(from) ~ ": " ~ content;
    }

    string toString() {
        return from.name ~ ": " ~ content;
    }
}

unittest {
    auto u = User(SimpleId("foo"));
    assert(PublicMsg("hello", u).toString == "");
}


/**
 * EmoteMsg is a /me message sent to the room. It specifically does not
 * extend PublicMsg because it doesn't implement MessageFrom to allow the
 * sender to see the emote.
 */
struct EmoteMsg {
    Message msg;
    User    from;
    alias msg this;

    this(string _content, User _from) {
        msg  = Message(_content);
        from = _from;
    }

    string render(Theme t) {
        if (t == null)
            return msg.toString;
        return "** " ~ cfg.theme.colorName(from) ~ " " ~ content;
    }
}

unittest {
    auto u = User(SimpleId("foo"));
    assert(EmoteMsg("sighs.", u).toString == "** foo sighs.");
}

/**
 * PrivateMsg is a message sent to another user, not shown to anyone else.
 */
struct PrivateMsg {
    PublicMsg msg;
    User      to;
    alias msg this;

    this(string _content, User _from, User _to) {
        msg  = PublicMsg(_content, _from);
        to = _to;
    }

    string render(Theme t) {
        return "[PM from " ~ from.name ~ "] " ~ content;
    }
}

unittest {
    auto u = User(SimpleId("foo"));
    assert(PrivateMsg("hello", u, u).toString == "[PM from foo] hello");
}

/**
 * SystemMsg is a response sent from the server directly to a user, not shown
 * to anyone else. Usually in response to something, like /help.
 */
struct SystemMsg {
    Message msg;
    User    to;
    alias msg this;

    this(string _content, User _to) {
        msg = Message(_content);
        to  = _to;
    }

    string render(Theme t) {
        if (t == null) {
            return this.toString;
        }
        return t.colorSys(this.toString);
    }

    string toString() {
        return "-> " ~ content;
    }
}

unittest {
    auto u = User(SimpleId("foo"));
    assert(SystemMsg("hello", u).toString == "-> hello");
}

/**
 * AnnounceMsg is a message sent from se server to everyone, like a join or
 * leave event.
 */
struct AnnounceMsg {
    Message msg;
    alias msg this;

    this(string _content) {
        msg = Message(_content);
    }

    string render(Theme t) {
        if (t == null)
            return toString;
        return t.colorSys(toString);
    }

    string toString() {
        return " * " ~ content;
    }
}

unittest {
    assert(AnnounceMsg("foo").toString == " * foo");
}

struct CommandMsg {
    PublicMsg msg;
    string    command;
    string[]  args;

    alias msg this;
}
