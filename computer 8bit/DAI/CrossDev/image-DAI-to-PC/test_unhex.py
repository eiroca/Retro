#!/usr/bin/env python3
import unittest
from unhex import unhex

class TestUnhex(unittest.TestCase):
  def test_empty(self):
    self.assertEqual(unhex([]), (b'', 0))

  def test_blank_line(self):
    self.assertEqual(unhex(['\n']), (b'', 0))

  def test_ignore_line(self):
    self.assertEqual(unhex(['ignore this line\n']), (b'', 0))

  def test_full_line(self):
    self.assertEqual(unhex([
      'BFF0 00 00 B8 36 00 00 AF 36 00 00 9F 36 00 00 80 36\n']),
      (b'\x00\x00\xB8\x36\x00\x00\xAF\x36\x00\x00\x9F\x36\x00\x00\x80\x36',
        0xBFFF))

  def test_short_line(self):
    self.assertEqual(unhex(['BFF0 12 34 B8 36\n']),
      (b'\x12\x34\xB8\x36', 0xBFF3))

  def test_nonzero_start(self):
    self.assertEqual(unhex(['5678 12 34 B8 36\n']),
      (b'\x12\x34\xB8\x36', 0x567B))

if __name__ == '__main__':
  unittest.main()

# vim:set sw=2 ts=2 sts=2 et tw=80:
