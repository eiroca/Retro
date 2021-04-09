#!/usr/bin/env python3
"""
Decode DAI framebuffer data into an image file.
"""
import argparse
import numpy as np
from PIL import Image  # pip3 install pillow
from unhex import unhex

WIDTH = 352

# Palette for 16 color gfx.
# Taken from src/mame/video/dai.cpp
PALETTE16 = [
    [0x00, 0x00, 0x00],  #  0 Black
    [0x00, 0x00, 0x8b],  #  1 Dark Blue
    [0xb1, 0x00, 0x95],  #  2 Purple Red
    [0xff, 0x00, 0x00],  #  3 Red
    [0x75, 0x2e, 0x50],  #  4 Purple Brown
    [0x00, 0xb2, 0x38],  #  5 Emerald Green
    [0x98, 0x62, 0x00],  #  6 Kakhi Brown
    [0xae, 0x7a, 0x00],  #  7 Mustard Brown
    [0x89, 0x89, 0x89],  #  8 Grey
    [0xa1, 0x6f, 0xff],  #  9 Middle Blue
    [0xff, 0xa5, 0x00],  # 10 Orange
    [0xff, 0x99, 0xff],  # 11 Pink
    [0x9e, 0xf4, 0xff],  # 12 Light Blue
    [0xb3, 0xff, 0xbb],  # 13 Light Green
    [0xff, 0xff, 0x28],  # 14 Light Yellow
    [0xff, 0xff, 0xff],  # 15 White
]

PALETTE_GRAY = [[n,n,n] for n in range(0, 256, 16)]
assert len(PALETTE_GRAY) == 16
PALETTE_GRAY = np.asarray(PALETTE_GRAY, dtype=np.uint8)

def to_float(img, gamma=2.2):
  """Converts [0-255] to [0-1] with gamma conversion."""
  out = img.astype(np.float) / 255.
  if gamma != 1.0:
    out = np.power(out, gamma)
  return out

def from_float(img, gamma=2.2):
  out = np.power(img.astype(np.float), 1.0 / gamma)
  out = (out * 255).clip(0, 255)
  # Rounding reduces quantization error (compared to just truncating)
  return np.round(out).astype(np.uint8)

def adjust_pal(pal):
  """
  Adjusts the given palette so that luminance is a gradient.
  """
  pal_rgb = np.asarray(pal)
  pal_rgb = to_float(pal_rgb)  # Linear rgb.

  # YUV constants for Rec.709
  wr = 0.2126
  wg = 0.7152
  wb = 0.0722

  y = pal_rgb.dot([wr, wg, wb])

  for i in range(16):
    lum = i / 15
    lum = np.power(lum, 2.2)
    pal_rgb[i] = pal_rgb[i] / y[i] * lum

  return from_float(pal_rgb)

def cut(b, l):
  """Cut the last `l` bytes from `b`, returns the left and right parts."""
  assert len(b) >= l, (len(b), l)
  return b[:-l], b[-l:]

assert cut(b'hello', 3) == (b'he', b'llo')

def cols_from_res(res):
  """Returns the number of columns based on the resolution number."""
  # 528 cols is also 66 chars per line in character mode.
  return [88, 176, 352, 528][res]

def mul_from_res(res):
  """Returns the width multiplier based on the resolution number."""
  return [4,2,1][res]

def get_line_len(not_unit_color, disp, res, data):
  """Returns the length of the payload for this line."""
  if not not_unit_color:
    #assert disp == 0, disp  # Doesn't hold in FFFF?
    #assert res == 0, res  # Doesn't hold. Why?
    return 2  # FIXME: Why?
  elif disp in [0, 2]:
    # 2 bytes = 8 cols
    return cols_from_res(res) // 8 * 2
  elif disp == 1 and res == 3:
    # 66 text cols * 2 bytes each
    return 66 * 2
  elif disp == 3 and res == 3:
    # FIXME: Guessing here!
    # 66 text cols * 2 bytes each
    return 66 * 2
  print('Unknown mode, trailing data is:')
  print(data[-70:].hex())
  return None

def decode(data, addr = 0xBFFF):
  """
  Decode `data` into an array of color numbers.
  `addr` is the addr of the last seen byte, if known.
  """
  out = []
  ascii_break = None
  line_num = 0
  prev_bg = 0  # Used in 16 color gfx mode.
  color_regs = [1, 9, 12, 15]  # Used in 4 color gfx mode. (blues)
  while data:
    # Control word, high address byte (mode byte) (manual section 3.2.1)
    data, mode = cut(data, 1)
    mode = mode[0]
    # Bits:
    # 7, 6 - display mode control
    # 5, 4 - resolution control
    # 3, 2, 1, 0 - line repeat count
    # Disp:
    # (0) 00 -  4 color gfx
    # (1) 01 -  4 color chars
    # (2) 10 - 16 color gfx
    # (3) 11 - 16 color chars
    disp = (mode >> 6) & 3
    # Res:
    # (0) 00 -  88 cols
    # (1) 01 - 176 cols
    # (2) 10 - 352 cols
    # (3) 11 - 528 cols, text mode with 66 chars per line
    res = (mode >> 4) & 3
    line_rep = mode & 15

    # Low address byte (color byte)
    data, color = cut(data, 1)
    color = color[0]
    enable_change = (color >> 7) & 1
    not_unit_color = (color >> 6) & 1
    color_reg = (color >> 4) & 3
    color_sel = color & 15

    print(f'addr 0x{addr:04X} insn {line_num:3} row {len(out):3} '
        f'mode 0x{mode:02x} disp {disp} res {res} '
        f'rep {line_rep} '
        f'| color 0x{color:02x} change {enable_change} '
        f'not_unit {not_unit_color} reg {color_reg} '
        f'sel {color_sel} ', end='')
    line_len = get_line_len(not_unit_color, disp, res, data)
    print(f'| len {line_len}')
    assert line_len is not None
    addr -= line_len + 2

    # Consume line.
    if line_len > len(data):
      print(f'warn: giving up because not enough data left ({len(data)} bytes)')
      break
    data, pixels = cut(data, line_len)
    pixels = pixels[::-1] # Reverse.

    # Convert to image.
    if mode == 0x7a:
      # Log text, don't add it to the image.
      text = pixels[0::2]
      print(' Text:', repr(text))
    elif len(out) == 212 and mode == 0x30 and color == 0x88 and \
        ascii_break is None:
      print(f'info: decided ascii break starts on line {line_num} '
          f'after {len(out)} image rows')
      ascii_break = len(out)
    else:
      if enable_change == 1:
        # rep varies - why?
        if ascii_break:
          print(' ignored color change due to ascii break')
        else:
          color_regs[color_reg] = color_sel
          print(f' set color register {color_reg} to color {color_sel}')
      if disp == 0 and not_unit_color == 1:
        # 4 color gfx.
        out_line = []
        mul = mul_from_res(res)
        for i in range(0,len(pixels),2):
          # High and low are flipped because the payload is reversed.
          hb, lb = pixels[i], pixels[i+1]
          for bit in range(7,-1,-1):
            color = ((lb >> bit) & 1)
            color |= ((hb >> bit) & 1) * 2
            out_line.extend([color_regs[color]] * mul)
        assert len(out_line) == WIDTH, len(out_line)
        out.extend([out_line] * (line_rep + 1))
      elif disp == 2 and not_unit_color == 1:
        # 16 color gfx.
        out_line = []
        mul = mul_from_res(res)
        for i in range(0,len(pixels),2):
          hb, lb = pixels[i], pixels[i+1]
          bg = lb & 15
          fg = (lb >> 4) & 15
          for bit in range(7,-1,-1):
            color = prev_bg
            if (hb >> bit) & 1:
              color = fg
              prev_bg = bg
            else:
              if prev_bg != bg:
                print(f' col {len(out_line)} '
                  f'holding prev bg color {prev_bg} vs {bg}')
            out_line.extend([color] * mul)
        assert len(out_line) == WIDTH, len(out_line)
        out.extend([out_line] * (line_rep + 1))
      elif color == 0 and mode == 0:
        print(f' looks like uninitialized memory, stop decoding')
        break
      elif color == 0xff and mode == 0xff:
        # Probably unused memory: skip it.
        pass
      elif not_unit_color == 0:
        print(f' ignoring data {repr(pixels)} due to unit_color')
        pass
      else:
        print(' unimplemented')
    line_num += 1
    if len(out) >= 260:
      print('info: giving up after a full screen')
      break
  print(f'info: decoded {len(out)} lines')

  if ascii_break:
    print(f'info: fixing ascii_break at image row {ascii_break}')
    #marker = [[[255,0,0]] * WIDTH]
    marker = []
    out = out[ascii_break:260] + marker + out[:ascii_break]
  return np.asarray(out)

def main():
  p = argparse.ArgumentParser()
  p.add_argument('infile')
  p.add_argument('-pal', default='mame',
      help='palette choice: mame|adjust')
  args = p.parse_args()
  if args.pal == 'mame':
    pal = PALETTE16
  elif args.pal == 'adjust':
    pal = adjust_pal(PALETTE16)
  else:
    assert False, ('unknown palette', args.pal)

  fn = args.infile
  print(f'info: loading from {fn}')
  with open(fn, 'rb') as f:
    data = f.read()

  if not fn.lower().endswith('.bin'):
    data = data.decode('ascii')
    data, last_addr = unhex(data.splitlines())
  else:
    last_addr = 0xBFFF  # Assume.

  print(f'info: loaded {len(data)} bytes')
  exp_last = 0xBFFF
  if last_addr != exp_last:
    print(f'WARN: last seen line starts at addr {last_addr:04x}, '
        f'expecting {exp_last:04x}')

  binfn = fn + '.bin'
  print(f'info: writing binary data to {binfn}')
  with open(binfn, 'wb') as f:
    f.write(data)

  out = decode(data, last_addr)

  # Apply palette.
  pal = np.asarray(pal, dtype=np.uint8)
  img = pal[out]
  h,w,c = img.shape
  print(f'info: output image res is {w} x {h}')
  im = Image.fromarray(img)
  outfn = fn + '.png'
  print(f'info: writing image to {outfn}')
  im.save(outfn)

  # Generate grayscale version.
  img = PALETTE_GRAY[out]
  im = Image.fromarray(img)
  outfn = fn + '.gray.png'
  print(f'info: writing grayscale image to {outfn}')
  im.save(outfn)

if __name__ == '__main__':
  main()

# vim:set sw=2 ts=2 sts=2 et tw=80:
