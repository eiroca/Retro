#!/usr/bin/env python3
"""
Decode UT format hex, into binary.
"""
import argparse

def valid_dump_line(l):
  """Returns True if `l` looks like a valid UT hex dump line."""
  if len(l) < 5: return False
  if l[4] != ' ': return False
  for i in range(4):
    if l[i] not in '0123456789ABCDEF': return False
  return True

def unhex(lines):
  """
  Decode `lines` which is in UT hex dump format.
  Return the binary data and the last address seen.
  """
  # Example line:
  # 'BFF0 00 00 B8 36 00 00 AF 36 00 00 9F 36 00 00 80 36'
  data = ''
  last_addr = 0
  for l in lines:
    l = l.strip()  # Remove newline.
    if not valid_dump_line(l):
      print('ignoring line', repr(l))
      continue
    l = l.split(' ')
    addr = l.pop(0)
    assert len(addr) == 4, addr
    last_addr = int(addr, 16) + len(l) - 1
    data += ''.join(l)
  data = bytes.fromhex(data)
  return (data, last_addr)

def main():
  p = argparse.ArgumentParser()
  p.add_argument('infile')
  args = p.parse_args()

  fn = args.infile
  print(f'info: loading from {fn}')
  with open(fn, 'r') as f:
    data = f.read()

  data, last_addr = unhex(data.splitlines())

  binfn = fn + '.bin'
  print(f'info: writing {len(data)} binary bytes to {binfn}')
  with open(binfn, 'wb') as f:
    f.write(data)

if __name__ == '__main__':
  main()

# vim:set sw=2 ts=2 sts=2 et tw=80:
