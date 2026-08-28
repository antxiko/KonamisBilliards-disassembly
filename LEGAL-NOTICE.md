# Legal notice and attribution

*(También disponible [en castellano](AVISO-LEGAL.md).)*

## Who owns what

**The game is not ours.** *Konami's Billiards* was published by **Konami** as
cartridge RC-706 for the MSX; the cartridge signs it on screen itself, with the
list at 0x42D1 that draws "(c)KONAMI 1984" on row 8 of the title screen. All
rights in the game remain with their holders.

**What is ours** are the tools in this repository, the comments in the listing,
the analysis and the documentation. Those are published under the licence in
`LICENSE`.

## What is in this repository

The file `src/billiards.asm` is the commented disassembly of the cartridge. It is
published for the **preservation, study and documentation** of a title that is
part of MSX software history.

The cartridge image (`.rom`) is **not** distributed here. Anyone wanting to
rebuild the listing has to supply their own, and the `Makefile` checks its sha256
before doing anything.

The pictures produced by `tools/graficos.py` are not artwork brought in from
elsewhere, nor emulator screenshots: they are the game's own video memory,
reconstructed by replaying the cartridge's copies and its two drawing
interpreters — the same addresses and the same order that are in the listing —
and developed as they stand. They are part of the proof that the reading of the
binary is correct: if it were wrong, noise would come out.

## What it rests on

On nobody's work. Everything asserted here comes from reading this binary, and
every assertion carries its evidence beside it: the instruction that reads a
piece of data, the table that ends exactly where it has to end, or the arithmetic
that works out on its own. What is not settled is said not to be settled, and has
its place on the open questions page.

The only outside work cited is **Manuel Pazos**'s finding about the hidden mark
in Konami cartridges, and it is cited precisely to say that this cartridge does
not carry it.

## If you are one of the authors

If you worked on *Konami's Billiards* or hold rights in the game, and would
rather this material were not published, **say so and it comes down, no argument
about it**. The intent of this work is the exact opposite of harming you: it is
to put on record how it was done.
