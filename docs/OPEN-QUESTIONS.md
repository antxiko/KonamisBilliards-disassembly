# Open questions

What this disassembly does **not** settle. The binary is explained byte by byte,
but that is not the same as having checked everything.

## None of this has been seen running

Everything these pages say comes from reading the code, simulating it or drawing
its data. **There is not one measurement taken on an emulator or on real
hardware.** What has been checked, and how:

- The square root at 0x5376, executed over all 65,536 possible input values.
- The key mapping at 0x410F, simulating the rotations key by key.
- The four trigonometric tables, compared against their formula.
- The screen addresses quoted here, against the real operand of the instruction
  that loads them.
- The pictures: the loading routines and the two interpreters, re-executed onto
  an empty VRAM. The table coming out right is a strong check, but it is a check
  of the artwork, not of the game.

What is left is the obvious part: playing it and seeing whether the game behaves
the way this says.

## Four ownerless bytes

At 0x4462 there is this:

    00 80 40 C0

No instruction references them, and the byte sequence of their address does not
appear anywhere in the ROM, so no pointer reaches them either. The menu code
jumps over them.

The four values look like they mean something — zero, a quarter, half and three
quarters of a turn, or the four quadrants — but that is an impression, not a
reading. What they were is not known.

## One sprite too many

The cartridge copies 288 bytes into the sprite pattern table, enough for nine
16×16 drawings, but there are only eight real ones: the cue ball, the six
numbered ones and the aiming dot. The ninth overruns the end and lands on the
table's compressed colours, so it is noise.

There is no way to tell from the binary whether the round number is deliberate —
copying 0x120 bytes is tidier than copying 0x100 — or whether there was a ninth
drawing at some point.

## A repeated write

At 0x5962 the same value is written twice in a row to the same place:

    ld (ix+002h),a
    ld (ix+002h),a

Three bytes that change nothing. It has every appearance of being a leftover from
an edit, but that cannot be asserted from the binary either.

## The abandonment clock

The countdown at 0xE202 works out, doing the arithmetic, at a little over twenty
minutes without touching a key before the shot is written off. The arithmetic is
clear in the code; what has not been done is waiting the twenty minutes to see
it.
