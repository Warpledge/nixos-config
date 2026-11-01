"""omni-face-auth: Omni Settings' root half of face auth, run through pkexec.

Only ever acts on the caller from PKEXEC_UID, never a user from its arguments.
"""

import os
import pwd
import re
import subprocess
import sys

HOWDY = os.environ["OMNI_FACE_HOWDY"]
LABEL = re.compile(r"[A-Za-z0-9][A-Za-z0-9 _-]{0,31}")
MODEL_ID = re.compile(r"[0-9]{1,6}")


def refuse(message):
    print(message, file=sys.stderr)
    sys.exit(2)


def main(argv):
    uid = os.environ.get("PKEXEC_UID", "")
    if os.geteuid() != 0 or not uid.isdigit():
        refuse("run this through pkexec")
    user = pwd.getpwuid(int(uid)).pw_name
    command = argv[0] if argv else ""
    #--- Test only needs the polkit prompt it took to get here to have passed
    if command == "test" and len(argv) == 1:
        return 0
    if command == "add" and len(argv) == 2 and LABEL.fullmatch(argv[1]):
        return subprocess.run([HOWDY, "-U", user, "-y", "add", argv[1]], check=False).returncode
    if command == "remove" and len(argv) == 2 and MODEL_ID.fullmatch(argv[1]):
        return subprocess.run([HOWDY, "-U", user, "-y", "remove", argv[1]], check=False).returncode
    refuse("expected: add <label>, remove <id> or test; a label is letters, numbers, spaces, _ or -")


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
