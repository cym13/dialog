module dialog.chat.message.theme;

import dialog.chat.message.user;

enum {
    RESET     = "\033[0m",
    BOLD      = "\033[1m",
    DIM       = "\033[2m",
    ITALIC    = "\033[3m",
    UNDERLINE = "\033[4m",
    BLINK     = "\033[5m",
    INVERT    = "\033[7m",
    NEWLINE   = "\r\n",
    BEL       = "\007",
}

/**
 * General hardcoded style, mostly used as a crutch until we flesh out the
 * framework to support backgrounds etc.
 */
struct Style {
    private string _str;
    alias _str this;

    string format(string s) {
        return _str ~ s ~ RESET;
    }

    string toString() {
        return _str;
    }
}

/**
 * 256 color type, for terminals that support it.
 */
struct Color256 {
    private ubyte _color;
    alias _color this;

    string format(string) {
        return "\033[" ~ this.toString ~ "m" ~ s ~ RESET;
    }

    string toString() {
        import std.conv: to;
        return "38;05;" ~ _color.to!string;
    }
}

/**
 * No color, used for mono theme
 */
struct Color0 {
    string toString() {
        return "";
    }

    string format(string s) {
        return s;
    }
}

/**
 * Container for a collection of colors
 */
struct Palette {
    Style[] colors;
    int     length;

    /**
     * Get a color by index, overflows are looped around.
     */
    Style take(int i) {
        return colors[i % (length-1)];
    }

    string toString() {
        import std.algorithm: map, join;

        return colors.map!(c => c.format("X")).join;
    }
}

/**
 * Collection of chat settings.
 */
struct Theme {
    import std.typecons: Nullable;

    string           id;
    Style            sys;
    Style            pm;
    Style            highlight;
    Nullable!Palette names;

    this(string _id) {
        id = _id;
    }

    /**
     * Colorize name strings given some index.
     */
    string colorName(User u) {
        if (names.isNull)
            return u.name;
        return names.take(u.colorIdx).format(u.name);
    }

    /**
     * Colorize PM messages
     */
    string colorPm(string s) {
        if (names.isNull)
            return s;
        return pm.format(s);
    }

    /**
     * Colorize Sys messages
     */
    string colorSys(string s) {
        if (names.isNull)
            return s;
        return highlight.format(s);
    }
}

Palette readableColors256() {
    immutable size = 247;

    Styles[] styles;
    styles.length = size;

    auto p = Palette(styles, size);

    uint j;
    foreach (i ; 0..256) {
        if ((16 <= i && i <= 18) || (232 <= i && i <= 237))
            continue;
        p.colors[j] = Color256(i);
        j++;
    }

    return p;
}

Theme[] themes;
Theme   defaultTheme;

void init() {
    auto palette = readableColors256;

    Theme[] themes = [Theme("colors",
                         // sys: Grey
                            palette.take(8),
                         // pm: White
                            palette.take(7),
                         // highlight: Yellow
                            style(Bold + "\033[48;5;11m\033[38;5;16m"),
                         // names
                            palette),
                      Theme("mono")];

    defaultTheme = themes[0];
}

unittest {
    auto palette = readableColors256;
    auto color   = palette.take(5);

    assert(color.toString == "38;05;5");
    assert(color.format("foo") == "\033[38;05;5mfoo\033[0m");
    assert(palette.take(palette.size() + 1).toString == "38;05;2");
}

unittest {
    auto colorTheme = themes[0];
    auto color      = colorTheme.sys;

    assert(color.format("foo") == "\033[38;05;8mfoo\033[0m");
    assert(colorTheme.ColorSys("foo") == "\033[38;05;8mfoo\033[0m");

    auto u = User(SimpleId("foo"));
    u.colorIdx = 4;

    assert(colorTheme.colorName(u) == "\033[38;05;4mfoo\033[0m");

    auto msg = PublicMsg("hello", u);

    assert(msg.render(colorTheme) == "\033[38;05;4mfoo\033[0m: hello");
}
