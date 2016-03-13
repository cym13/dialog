module dialog.chat.message.identity;

struct SimpleId {
    immutable string id;

    string toString() {
        return id;
    }

    string setId() {}

    string name() {
        return id;
    }
}
