"""A small Source RCON client. Minecraft splits a long reply at 4096 bytes with
nothing marking the end, so a full-sized packet is followed by a request of an
unknown type, whose answer closes the reply. That request waits for the first
packet: 1.7.10 reads one packet per socket read and drops the connection when
two arrive together."""

import re
import socket
import struct

LOGIN = 3
COMMAND = 2
UNKNOWN = 200  # any type the server doesn't know gets an "Unknown request" answer
FULL = 4096  # the body size of a reply packet with more to come
COLOUR = re.compile("§.")


class RconError(Exception):
    pass


class Rcon:
    def __init__(self, host, port, password, timeout=5):
        self.sock = socket.create_connection((host, port), timeout=timeout)
        self.next_id = 0
        self.buffer = b""
        try:
            sent = self._send(LOGIN, password)
            if self._read()[0] != sent:
                raise RconError("the server refused the RCON password")
        except (OSError, RconError):
            self.close()
            raise

    def close(self):
        try:
            self.sock.close()
        except OSError:
            pass

    def _send(self, kind, body):
        self.next_id += 1
        data = struct.pack("<ii", self.next_id, kind) + body.encode() + b"\0\0"
        self.sock.sendall(struct.pack("<i", len(data)) + data)
        return self.next_id

    def _exactly(self, size):
        while len(self.buffer) < size:
            chunk = self.sock.recv(65536)
            if not chunk:
                raise RconError("the server closed the RCON connection")
            self.buffer += chunk
        data, self.buffer = self.buffer[:size], self.buffer[size:]
        return data

    def _read(self):
        size = struct.unpack("<i", self._exactly(4))[0]
        if not 10 <= size <= 1 << 20:
            raise RconError(f"bad RCON packet size {size}")
        data = self._exactly(size)
        rid, _kind = struct.unpack("<ii", data[:8])
        return rid, data[8:-2].decode(errors="replace")

    def command(self, text):
        """The command's reply with colour codes removed."""
        sent = self._send(COMMAND, text)
        rid, body = self._read()
        parts = [body] if rid == sent else []
        if len(body.encode()) >= FULL:
            closing = self._send(UNKNOWN, "")
            while True:
                rid, body = self._read()
                if rid == closing:
                    break
                if rid == sent:
                    parts.append(body)
        return COLOUR.sub("", "".join(parts))
