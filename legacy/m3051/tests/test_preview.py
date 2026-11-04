"""Python-only launch/server safety checks; no Godot/templates required."""
import contextlib
import functools
import http.client
import importlib.util
import json
import tempfile
import threading
import unittest
from pathlib import Path

spec = importlib.util.spec_from_file_location("preview", Path(__file__).resolve().parents[1] / "tools/preview.py")
preview = importlib.util.module_from_spec(spec)
spec.loader.exec_module(preview)


class PreviewTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.web = self.root / "web"
        self.web.mkdir()
        (self.web / "index.html").write_text("<h1>Actual export fixture</h1>")
        (self.web / "index.wasm").write_bytes(b"\x00asm")
        (self.web / "preview-build.json").write_text(json.dumps({"schema": 1}))
        (self.root / "private.txt").write_text("DO NOT SERVE")
        handler = functools.partial(preview.PreviewHandler, directory=self.web)
        self.server = preview.http.server.ThreadingHTTPServer(("127.0.0.1", 0), handler)
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()
        self.addCleanup(self.stop_server)

    def stop_server(self):
        self.server.shutdown()
        self.server.server_close()
        self.thread.join(2)

    def request(self, path, method="GET"):
        with contextlib.closing(http.client.HTTPConnection("127.0.0.1", self.server.server_port)) as connection:
            connection.request(method, path)
            response = connection.getresponse()
            return response.status, dict(response.getheaders()), response.read()

    def test_serves_index(self):
        status, headers, content = self.request("/")
        self.assertEqual(status, 200)
        self.assertIn(b"Actual export", content)
        self.assertEqual(headers["Cache-Control"], "no-store")

    def test_wasm_mime(self):
        self.assertEqual(self.request("/index.wasm")[1]["Content-type"], "application/wasm")

    def test_health(self):
        self.assertEqual(json.loads(self.request("/__preview__/status")[2]), {"schema": 1})

    def test_traversal(self):
        for url in ("/../private.txt", "/%2e%2e/private.txt", "/%2e%2e%5cprivate.txt", "/.env"):
            self.assertEqual(self.request(url)[0], 404, url)

    def test_symlink_escape(self):
        try:
            (self.web / "link.txt").symlink_to(self.root / "private.txt")
        except OSError:
            self.skipTest("symlinks unavailable")
        self.assertEqual(self.request("/link.txt")[0], 404)

    def test_directory_listing(self):
        (self.web / "empty").mkdir()
        self.assertEqual(self.request("/empty/")[0], 404)

    def test_post_unavailable(self):
        self.assertEqual(self.request("/", "POST")[0], 501)

    def test_no_source_directory(self):
        self.assertEqual(self.request("/project.godot")[0], 404)

    def test_fingerprint(self):
        (self.root / "project.godot").write_text("a")
        before = preview.fingerprint(self.root)
        (self.root / "project.godot").write_text("b")
        self.assertNotEqual(before, preview.fingerprint(self.root))

    def test_corrupt_stamp(self):
        (self.web / "preview-build.json").write_text("broken")
        self.assertEqual(preview.read_stamp(self.web), {})

    def test_exact_engine_release(self):
        for version in ("4.7.2.stable", "4.7.2.stable.official.testhash"):
            preview.validate_engine(version)

    def test_mismatched_engine_rejected(self):
        for version in ("4.5.1.stable.official.test", "4.7.1.stable", "4.7.2.rc1", "4.7.2.stableish", "4.8.stable"):
            with self.assertRaises(RuntimeError):
                preview.validate_engine(version)


if __name__ == "__main__":
    unittest.main()
