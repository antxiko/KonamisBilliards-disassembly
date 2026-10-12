# The music

Everything you hear here comes from running the cartridge's own sound engine (`toca_el_sonido`, 0x5C0E, and `pide_un_sonido_sin_mirar_la_partida`, 0x5BCA, which hands it the channels; the interrupt calls it at 0x4038) on an emulated Z80, frame by frame at 60 per second, just as the game calls it. What the engine writes to the PSG is turned into sound with an AY-3-8910 (`tools/musica.py`). Each MP3 is the whole piece up to where it starts again, plus 8 seconds of the repeat fading out; those that do not repeat end where the engine ends.

## Checked against openMSX

The PSG writes have been compared frame by frame with those of openMSX (C-BIOS MSX1 japonés). In every frame the PSG ends up the same:

- the ending tune (0x8A), whole, 194 frames;
- the long track 0x87, its first 375 frames, up to where the game asks for the sound again.

The timbre is not checked: it is a textbook AY-3-8910, not a recording of the emulator. The probes are `tools/omsx_psg.tcl` and `tools/coteja_psg.py`.

## How a piece is asked for

`pide_un_sonido` takes the number in A and only sounds during a real game (bit 6 of 0xE002); the other entry skips that check. Below 0x87 it is a one-channel effect, from 0x87 to 0x89 it uses two and from 0x8A up all three. Tracks 0x86 and 0x87 are long entries in the table that no routine asks for with an `ld a`. The engine never writes the PSG mixer: start-up leaves it set, and here it starts from that same value, 0xB8.

## The tunes

**The ending tune** (0x8A)

Asked for by `estado_12_fin_de_tacada` (0x44F6); lasts 3.2 s.

<audio controls preload="none" src="audio/musica_8A.mp3?v=1a65f842"></audio>

**The table is clear** (0x88)

Asked for by la rutina de 0x4E60: la mesa se ha quedado sin bolas; lasts 2.4 s.

<audio controls preload="none" src="audio/musica_88.mp3?v=6fd6bd19"></audio>

**The exit jingle** (0x8D)

Asked for by `estado_8_confirma_la_seleccion` (0x443C); lasts 2.8 s.

<audio controls preload="none" src="audio/musica_8D.mp3?v=a74e2d90"></audio>

**A long track in the table** (0x86)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 64.3 s.

<audio controls preload="none" src="audio/musica_86.mp3?v=969d3934"></audio>

**Another long track in the table** (0x87)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 25.2 s.

<audio controls preload="none" src="audio/musica_87.mp3?v=abcc09ca"></audio>
