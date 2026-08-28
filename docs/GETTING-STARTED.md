# Getting started

This repository holds a **commented disassembly** of Konami's Billiards for the
MSX (Konami, 1984, cartridge RC-706). Everything here comes out of the binary
and can be generated from it again.

## What you need

- **Python 3** (no third-party packages)
- **pasmo**, to reassemble
- **z80dasm**, used only for the mnemonics
- the cartridge image, which this repository **does not distribute**

The ROM goes in the root, named `billiards.rom`. It is exactly 16384 bytes:

    sha256  38741612e0b20e39dfd834106a3d5ef5a24c06fb947a104c044f1cdd269c46d9

`make comprueba` verifies it.

## The test that matters

    make verify

This reassembles the listing with pasmo and compares the result against the
original ROM, byte for byte. If it prints `OK: reproducible byte a byte`, the
disassembly has invented nothing: it is the same cartridge written differently.

## Everything else you can run

    make            # the whole cycle: listing, notes, verify, sanity and tests
    make listado    # regenerates src/billiards.asm from the trace and the notes
    make sanity     # the checks reassembly does NOT cover
    make test       # the tests
    make densidad   # how many comments each routine carries
    make imagenes   # rebuilds the pictures in docs/imagenes from the ROM
    make web        # regenerates the site

`make sanity` is the one that watches for what a correct reassembly can hide:
data being read as code. The bytes come out the same either way, because they do
not change; the only thing that changes is what we say about them.

## How it is put together

    src/billiards.asm       the listing, GENERATED — not edited by hand
    src/billiards.notes     the annotations, anchored to addresses
    src/billiards.entries   the entry points that cannot be deduced
    src/billiards.nocode    the stretches that are not code
    tools/                  the tracer, the generator and the checks
    docs/                   this site

The listing is **never edited**: you edit the `.notes` and regenerate. Every
annotation is anchored to an address, so it survives a retrace and does not slide
out of place if something moves.

The `.notes` directives are five: `L` names and describes a label, `C` hangs a
comment off an instruction, `B` inserts a block header, `D` declares a data range
with its name, and `F` says how many bytes a table's rows are.

## The pictures

    make imagenes

There is not a single screenshot on this site. `tools/graficos.py` replays the
cartridge's loading routines and its two drawing interpreters, instruction by
instruction, onto an empty video memory, and then develops that VRAM the way the
VDP would. No emulator is needed, and the table coming out right is the best
proof that the routines have been read correctly.
