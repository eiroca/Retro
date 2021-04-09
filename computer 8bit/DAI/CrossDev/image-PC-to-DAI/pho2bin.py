#!/usr/bin/env python3
"""
Generate DAI framebuffer data from an image file.
"""
import argparse
import numpy as np
from PIL import Image  # pip3 install pillow
import decode

WIDTH, HEIGHT = 352, 256

CONTROL_16COL_GFX = 0x80
CONTROL_4COL_GFX = 0x0

CONTROL_TEXT_MODE = 0x30
CONTROL_352_COLS = 0x20

NOT_UNIT_COLOR = 0x40

def colort(c1, c2, c3, c4, line_rep = 6):
  """
  Emit list of color change instructions.
  """
  control = CONTROL_TEXT_MODE | line_rep
  return [
      bytes([control, 0x80 | c1, 0, 0]),
      bytes([control, 0x90 | c2, 0, 0]),
      bytes([control, 0xA0 | c3, 0, 0]),
      bytes([control, 0xB0 | c4, 0, 0]),
  ]

def rightsize(img):
  w,h = img.size
  if (w,h) != (WIDTH, HEIGHT):
    # Resize image but maintain aspect.
    if w / h > WIDTH / HEIGHT:
      s = WIDTH / w
    else:
      s = HEIGHT / h
    w = int(w * s + .5)
    h = int(h * s + .5)
    print(f'warn: scaling image to {w} x {h}')
    assert w <= WIDTH, w
    assert h <= HEIGHT, h
    img = img.resize((w, h), Image.BICUBIC)
  return np.asarray(img)

def center(img):
  h,w,c = img.shape
  if (w,h) != (WIDTH, HEIGHT):
    # Center image.
    xo = (WIDTH - w) // 2
    yo = (HEIGHT - h) // 2
    mid = np.asarray(img)
    img = np.zeros((HEIGHT, WIDTH, c), dtype=np.uint8)
    img[yo:yo+h, xo:xo+w, :] = mid
  return img

def encode16(img):
  """
  Encodes image, returns an array of per-line memory chunks, in forward order.
  """
  img = img.convert(mode='RGB')
  img = center(rightsize(img))

  control_byte = CONTROL_16COL_GFX | CONTROL_352_COLS
  color_byte = NOT_UNIT_COLOR

  # This bit pattern selects the color for every block of 8 pixels.
  # 1 = fg color, 0 = bg color
  pattern = 0b11110000

  out = colort(8, 0, 15, 5)
  for y in range(HEIGHT):
    line = [control_byte, color_byte]
    sz = 8
    for x in range(0, WIDTH, sz):
      # Use fg color on the left and bg color on the right.
      fg = img[y, x:x+sz//2,:]
      bg = img[y, x+sz//2:x+sz,:]
      fg = int(np.mean(fg) / 17 + .5)
      bg = int(np.mean(bg) / 17 + .5)
      line += [pattern, (fg << 4) | bg]
    out.append(bytes(line))
  return 'MODE 5A', out

def encode4(img):
  assert img.mode == 'P', ('expecting indexed color, got ', img.mode)
  pmode, pdata = img.palette.getdata()
  assert len(pdata) % 3 == 0, len(pdata)
  ncol = len(pdata) // 3
  print(f'info: palette has {ncol} colors')
  assert ncol <= 4, ('expecting <= 4 colors, got', ncol)

  # Find nearest colors.
  dai_colors = [0,0,0,0]
  pal = np.asarray(decode.PALETTE16)
  for i in range(ncol):
    r,g,b = pdata[i*3:i*3+3]
    best_idx = 0
    best_dist = None
    rgb = np.asarray([r,g,b])
    for col in range(16):
      dist = rgb - pal[col]
      dist = np.mean(dist * dist)
      if best_dist is None or dist < best_dist:
        best_idx = col
        best_dist = dist
    print(f'info: mapped image color {i} (rgb {r:3} {g:3} {b:3}) '
        f'to dai color {best_idx:2}')
    dai_colors[i] = best_idx
  out = colort(*dai_colors)

  control_byte = CONTROL_4COL_GFX | CONTROL_352_COLS
  color_byte = NOT_UNIT_COLOR

  img = np.asarray(img)
  for y in range(HEIGHT):
    line = [control_byte, color_byte]
    sz = 8
    for x in range(0, WIDTH, sz):
      lb = 0
      hb = 0
      for i in range(sz):
        col = img[y, x + i]
        if col & 1: lb |= 1 << (7 - i)
        if col & 2: hb |= 1 << (7 - i)
      # Reverse order because it'll be reversed later.
      line += [hb, lb]
    out.append(bytes(line))
  return 'MODE 6A', out

def encode_text(t):
  """
  Returns a memory chunk (in forward order) encoding a line of text.
  If the line is too long, it gets truncated.
  """
  if type(t) is bytes: t = str(t)
  t = '    ' + t + ' ' * 66
  t = t[:66].encode()
  t = b''.join([bytes([c, 0]) for c in t])
  return bytes([0x7a, 0x40]) + t

def insert_text(lst, text, fn, mode):
  """
  Add text section to encoder output.
  """
  color_regs = lst[:4]
  top = lst[4:4+44]
  bottom = lst[4+44:]

  text += [f'{fn} {mode}', '', '', '']
  text = text[:4]

  return (
      color_regs +
      bottom +
      colort(8, 0, 0, 8, line_rep=0) +
      list(map(encode_text, text)) +
      colort(8, 0, 0, 8, line_rep=15) +
      top)

def main():
  encoders = {
      '16gray': encode16,
      '4color': encode4,
  }
  p = argparse.ArgumentParser()
  p.add_argument('infile')
  p.add_argument('outfile')
  p.add_argument('-text', default=None, type=str,
      help='name of file to load the text insert from')
  p.add_argument('-mode', default='16gray', type=str,
      help=f'encoder mode, options are {encoders.keys()}')
  args = p.parse_args()

  text = []
  if args.text is not None:
    with open(args.text) as f:
      text = f.read().splitlines()

  fn = args.infile
  print(f'info: loading from {fn}')
  img = Image.open(fn)
  w,h = img.size
  print(f'info: loaded {w} x {h} image')

  mode, out = encoders[args.mode](img)
  out = insert_text(out, text, args.infile, mode)

  # Join into one run.
  out = b''.join(out)
  # The framebuffer is in reverse order.
  out = out[::-1]
  print(f'encoded {len(out)} bytes (0x{len(out):x})')

  addr = 0xc000 - len(out)
  print(f'load at address 0x{addr:04x}')

  outfn = args.outfile
  with open(outfn, 'wb') as f:
    f.write(out)

if __name__ == '__main__':
  main()

# vim:set sw=2 ts=2 sts=2 et tw=80:
