# Konami's Billiards (MSX, Konami 1984) — a commented disassembly

A complete, commented disassembly of **Konami's Billiards** for the MSX:
Konami's **RC-706** cartridge, 16 KB in page 1.

**100 % of the binary is explained**, it reassembles into the original byte for
byte, and there is no guesswork dressed up as fact.

📖 **[Read the site](https://antxiko.github.io/KonamisBilliards-disassembly/)** ·
🇪🇸 **[En castellano](README.es.md)**

## What is inside

| | bytes | |
|---|---|---|
| traced code | 5,343 | 32.61 % |
| identified data | 11,041 | 67.39 % |
| **unexplained** | **0** | **0.00 %** |

**332 labels** (not one left unnamed), **1,151 anchored comments** — 39.3 % of
the instructions carry one, and **no routine falls below 10 %** — and **55 data
ranges**, each with its name, its explanation and, where they are tables, the
width of their rows. **15 tests** keep watch over all of it.

The chip's 16 KB are really 8,115 bytes of game: from 0x5FB3 onwards there are
8,269 bytes of 0xFF that no instruction ever reads.

## Some of what turned up

- **There are only seven balls on the table.** The array has eight records, but
  the eighth is not a ball: it is the point being aimed at, and subtracting the
  cue ball's position from it gives the shot vector.
- **Two balls that do not exist.** 0xE18F and 0xE1EA hold nothing: they are
  positioned so that their +7 and +9 bytes land on a pair of loose variables, so
  the routine that extracts a ball's angle works untouched to measure the angle
  of the line joining two centres.
- **The attract mode plays by pressing the button from the inside**, writing 0x10
  into the same variables where the game leaves the player's keys.
- **A 45° bounce without a single multiplication**: the pocket chamfers are
  resolved using the sum and the difference of the coordinates, and bouncing off
  them is swapping the two velocity components.
- **A twelve-byte square root** which, run over all 65,536 possible values,
  returns exactly `round(sqrt(n))`.
- **The power bar cannot be set**: it cycles 1, 2, 3 on its own and you have to
  shoot at the right moment.
- **This cartridge does not carry the hidden Konami mark** found by Manuel Pazos:
  there is not a single `RC-7` in ASCII anywhere in the 16 KB.

## How it is checked

    make verify

Reassembles the listing with pasmo and compares it against the ROM, byte for
byte.

    make            # the whole cycle
    make sanity     # what reassembly does NOT cover
    make imagenes   # rebuilds the pictures from the ROM, no emulator

The ROM is **not** distributed here. It goes in the root as `billiards.rom`,
16384 bytes, and the `Makefile` checks its sha256 before doing anything.

## The pictures are not screenshots

There is not one screen photograph in this repository. `tools/graficos.py`
replays the cartridge's loading routines and its two drawing interpreters,
instruction by instruction, onto an empty video memory, and then develops that
VRAM the way the VDP would.

The table coming out right is the most honest check there is that the routines
have been understood: if the reading were wrong, noise would come out.

## What is not settled

None of this has been seen running on an emulator or on real hardware. What has
been checked — the square root over all 65,536 inputs, the key mapping by
simulation, the four trigonometric tables against their formula — is set out on
[the open questions page](docs/OPEN-QUESTIONS.md), along with what is left to
find out.

## Licence and attribution

The game belongs to Konami; the analysis, the comments and the tools are
published under the licence in [`LICENSE`](LICENSE). See
[`LEGAL-NOTICE.md`](LEGAL-NOTICE.md).
