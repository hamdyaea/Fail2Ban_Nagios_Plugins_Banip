#!/usr/bin/env python3
# Developer: Hamdy Abou El Anein
# Contact: hamdy.aea@protonmail.com
# SPDX-License-Identifier: GPL-3.0-or-later
"""Offline Nagios plugin tests; never contact a running Fail2Ban daemon."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / "check_fail2ban_banned_ip.bash"


class PluginTests(unittest.TestCase):
    def run_check(self, status, output, jail="sshd"):
        with tempfile.TemporaryDirectory() as tmp:
            mock = Path(tmp) / "fail2ban-client"
            mock.write_text(
                '#!/bin/sh\nprintf "%s\\n" "$FAKE_STATUS"\nexit "$FAKE_RC"\n'
            )
            mock.chmod(0o700)
            env = dict(os.environ, PATH=f"{tmp}:" + os.environ.get("PATH", ""),
                       FAKE_STATUS=output, FAKE_RC=str(status))
            return subprocess.run(["bash", str(SCRIPT), jail], env=env,
                                  capture_output=True, text=True, timeout=10)

    def test_no_bans(self):
        result = self.run_check(0, "Currently banned: 0\nBanned IP list:")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("banned=0", result.stdout)

    def test_one_ban(self):
        result = self.run_check(0, "Currently banned: 1\nBanned IP list: 192.0.2.8")
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
        self.assertIn("192.0.2.8", result.stdout)
        self.assertIn("banned=1", result.stdout)

    def test_multiple_bans(self):
        result = self.run_check(0, "Currently banned: 2\nBanned IP list: 192.0.2.8 2001:db8::1", "nginx-http-auth")
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
        self.assertIn("banned=2", result.stdout)

    def test_failed_command_is_unknown(self):
        result = self.run_check(1, "Failed to access socket")
        self.assertEqual(result.returncode, 3)

    def test_invalid_response_is_unknown(self):
        result = self.run_check(0, "Status for the jail: sshd")
        self.assertEqual(result.returncode, 3)

    def test_missing_ips_is_unknown(self):
        result = self.run_check(0, "Currently banned: 2\nBanned IP list:")
        self.assertEqual(result.returncode, 3)

    def test_jail_injection_is_rejected(self):
        result = self.run_check(0, "Currently banned: 0", "sshd;whoami")
        self.assertEqual(result.returncode, 3)


if __name__ == "__main__":
    unittest.main()
