# La música

Todo lo que suena aquí sale de ejecutar el motor de sonido del cartucho (`toca_el_sonido`, 0x5C0E, y `pide_un_sonido_sin_mirar_la_partida`, 0x5BCA, que le reparte los canales; lo llama la interrupción en 0x4038) en un Z80 emulado, cuadro a cuadro y a 60 por segundo, igual que lo llama el juego. Lo que el motor escribe en el PSG pasa a sonido con un AY-3-8910 (`tools/musica.py`). Cada MP3 es la pieza entera hasta donde vuelve a empezar, más 8 segundos de la vuelta apagándose; las que no se repiten acaban donde acaba el motor.

## Cotejado con openMSX

Las escrituras al PSG se han comparado cuadro a cuadro con las de openMSX (C-BIOS MSX1 japonés). En todos los cuadros el PSG queda igual:

- la música del final (0x8A) entera, 194 cuadros;
- la pista larga 0x87, sus primeros 375 cuadros, hasta que el juego vuelve a pedir el sonido.

El timbre no está cotejado: es el de un AY-3-8910 de manual, no una grabación del emulador. Las sondas están en `tools/omsx_psg.tcl` y `tools/coteja_psg.py`.

## Cómo se pide una pieza

`pide_un_sonido` recibe el número en A y solo suena con partida de verdad (bit 6 de 0xE002); la otra entrada se salta esa comprobación. Por debajo de 0x87 es un efecto de un canal, del 0x87 al 0x89 usa dos y del 0x8A en adelante los tres. Las 0x86 y 0x87 son pistas largas de la tabla que ninguna rutina pide con un `ld a`. El motor no escribe el mezclador del PSG: lo deja el arranque, y aquí se parte de su mismo valor, 0xB8.

## Las músicas

**La música del final** (0x8A)

Lo pide `estado_12_fin_de_tacada` (0x44F6); dura 3,2 s.

<audio controls preload="none" src="../audio/musica_8A.mp3?v=1a65f842"></audio>

**La mesa limpia** (0x88)

Lo pide la rutina de 0x4E60: la mesa se ha quedado sin bolas; dura 2,4 s.

<audio controls preload="none" src="../audio/musica_88.mp3?v=6fd6bd19"></audio>

**El jingle de salida** (0x8D)

Lo pide `estado_8_confirma_la_seleccion` (0x443C); dura 2,8 s.

<audio controls preload="none" src="../audio/musica_8D.mp3?v=a74e2d90"></audio>

**Una pista larga de la tabla** (0x86)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 64,3 s.

<audio controls preload="none" src="../audio/musica_86.mp3?v=969d3934"></audio>

**Otra pista larga de la tabla** (0x87)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 25,2 s.

<audio controls preload="none" src="../audio/musica_87.mp3?v=abcc09ca"></audio>
