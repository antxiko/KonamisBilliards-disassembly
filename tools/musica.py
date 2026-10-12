#!/usr/bin/env python3
"""La musica del cartucho, ejecutando su motor de sonido (ver motor_musica.py).

Pide el sonido con `pide_un_sonido_sin_mirar_la_partida` (0x5BCA, A = numero;
`pide_un_sonido`, 0x5BC4, solo suena en partida) y corre `toca_el_sonido`
(0x5C0E), que la interrupcion llama cada cuadro (0x4038).
Uso:  musica.py registros 0x8A [cuadros] | mp3 0x8A f.mp3 | todas docs/audio
      musica.py barrido 0x80 0xFF | emu
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import motor_musica  # noqa: E402
from motor_musica import P  # noqa: E402

PIEZAS = [
    P(0x8A, "La música del final", "The ending tune",
      "`estado_12_fin_de_tacada` (0x44F6)"),
    P(0x88, "La mesa limpia", "The table is clear",
      "la rutina de 0x4E60: la mesa se ha quedado sin bolas"),
    P(0x8D, "El jingle de salida", "The exit jingle",
      "`estado_8_confirma_la_seleccion` (0x443C)"),
    P(0x86, "Una pista larga de la tabla", "A long track in the table",
      "ninguna llamada directa: está en la tabla de pistas"),
    P(0x87, "Otra pista larga de la tabla", "Another long track in the table",
      "ninguna llamada directa: está en la tabla de pistas"),
]

PAGINA = motor_musica.pagina_basica(
    "`toca_el_sonido`, 0x5C0E, y `pide_un_sonido_sin_mirar_la_partida`, "
    "0x5BCA, que le reparte los canales; lo llama la interrupción en 0x4038",
    "`toca_el_sonido`, 0x5C0E, and `pide_un_sonido_sin_mirar_la_partida`, "
    "0x5BCA, which hands it the channels; the interrupt calls it at 0x4038",
    "C-BIOS MSX1 japonés",
    [("la música del final (0x8A) entera, 194 cuadros",
      "the ending tune (0x8A), whole, 194 frames"),
     ("la pista larga 0x87, sus primeros 375 cuadros, hasta que el juego "
      "vuelve a pedir el sonido",
      "the long track 0x87, its first 375 frames, up to where the game asks "
      "for the sound again")],
    [("Cómo se pide una pieza",
      "`pide_un_sonido` recibe el número en A y solo suena con partida de "
      "verdad (bit 6 de 0xE002); la otra entrada se salta esa comprobación. "
      "Por debajo de 0x87 es un efecto de un canal, del 0x87 al 0x89 usa "
      "dos y del 0x8A en adelante los tres. Las 0x86 y 0x87 son pistas largas "
      "de la tabla que ninguna rutina pide con un `ld a`. El motor no escribe "
      "el mezclador del PSG: lo deja el arranque, y aquí se parte de su "
      "mismo valor, 0xB8.",
      "How a piece is asked for",
      "`pide_un_sonido` takes the number in A and only sounds during a real "
      "game (bit 6 of 0xE002); the other entry skips that check. Below 0x87 "
      "it is a one-channel effect, from 0x87 to 0x89 it uses two and from "
      "0x8A up all three. Tracks 0x86 and 0x87 are long entries in the table "
      "that no routine asks for with an `ld a`. The engine never writes the "
      "PSG mixer: start-up leaves it set, and here it starts from that same "
      "value, 0xB8.")])

CFG = dict(rom="billiards.rom", org=0x4000, frame=0x5C0E, pide=0x5BCA,
           ram=(0xE010, 0xE02E), hz=60, psg0={7: 0xB8}, piezas=PIEZAS,
           pagina=PAGINA, cotejado=[(0x8A, 194, None)])

if __name__ == "__main__":
    sys.exit(motor_musica.main(CFG, sys.argv[1:]))
