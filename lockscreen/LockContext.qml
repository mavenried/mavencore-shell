import Quickshell
import Quickshell.Services.Pam
import QtQuick

Singleton {
    id: root

    signal unlocked
    signal authFailed(string reason)
    signal pamMessage(string msg)

    function submitPassword(pw: string) {
        if (passwordPam.active)
            return;
        _resetPam();
        passwordPam.start();
        _pendingPassword = pw;
    }

    function startFingerprint() {
        if (fingerprintPam.active)
            return;
        fingerprintPam.start();
    }

    function cancelFingerprint() {
        if (fingerprintPam.active)
            fingerprintPam.abort();
    }

    property string _pendingPassword: ""

    function _resetPam() {
        if (passwordPam.active)
            passwordPam.abort();
        _pendingPassword = "";
    }

    PamContext {
        id: passwordPam
        configDirectory: "pam"
        config: "password.conf"

        onPamMessage: {
            passwordPam.respond(root._pendingPassword);
            root._pendingPassword = "";
        }

        onCompleted: result => {
            if (result == PamResult.Success) {
                root.unlocked();
            } else {
                root.authFailed(message || "Incorrect password");
            }
        }
    }

    PamContext {
        id: fingerprintPam

        configDirectory: "pam"
        config: "fingerprint.conf"

        onCompleted: result => {
            if (result == PamResult.Success) {
                root.unlocked();
            } else {
                root.authFailed(message || "Fingerprint not recognised");
            }
        }
    }
}
