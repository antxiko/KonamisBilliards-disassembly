# Hallazgos

Cosas que aparecieron al leer el código instrucción a instrucción y que no
caben en ninguna de las otras páginas. Casi todas son de la misma familia:
alguien apurando bytes con mucho oficio.

## Tres bytes puestos con dos escrituras

Cuando el marcador se desborda, el juego lo clava en 999999. Los seis nueves
son tres bytes en BCD, y ponerlos cuesta esto:

    ld bc,09999h
    ld (0e040h),bc
    ld (0e041h),bc

Dos escrituras de dos bytes **solapadas** para dejar tres bytes a 0x99. La
segunda pisa el byte alto de la primera con el mismo valor. Sale a un byte de
código por byte escrito, contra los nueve que costaría hacerlo a mano.

## Dos incrementos en vez de dos comparaciones

El intérprete de listas de texto (0x472E) tiene que reconocer dos marcas: 0xFF
para terminar y 0xFE para cambiar de destino. Lo normal serían dos `cp` con sus
dos saltos. Lo que hay es:

    ld b,a
    inc b
    ret z          ; era 0xFF
    inc b
    jr z,L_4730    ; era 0xFE

Se copia el byte a B para no perder A, y se incrementa: 0xFF más uno da cero y
enciende el flag, y otro incremento hace lo mismo con 0xFE. Dos marcas
reconocidas con dos instrucciones de un byte.

## El parpadeo no tiene variable: mira la pantalla

Mientras hay bolas en la mesa, el rótulo 1P o 2P del jugador que tiene el turno
parpadea. No hay ninguna bandera que diga si ahora mismo está puesto o quitado.
Lo que hace 0x4858 es **leer de la VRAM** el tile que hay en esa posición: si
está vacío lo pinta, y si hay algo lo borra.

La propia pantalla hace de memoria. Y como solo entra un cuadro de cada
treinta y dos —los cinco bits de abajo del contador de cuadros a cero—, el
parpadeo sale a algo más de medio segundo por lado.

## El bit que dice "esto va en serio"

0xE002 guarda tres cosas en tres bits, y la del bit 6 es la más útil de todas:
dice si hay una partida de verdad.

Con ese bit a cero no se puntúa (0x4786 se marcha de la rutina del marcador
nada más mirarlo) y no suena nada (0x5BC7 hace lo mismo con la de pedir
sonidos). Es exactamente el estado en el que corre la demostración, que por eso
juega en silencio y sin sumar. Y de paso, el mismo bit decide de qué puerto de
joystick se lee: siempre el 1, o el del jugador que tenga el turno.

Un bit, tres consecuencias, y las tres coherentes.

## Nadie se queda mirando la mesa para siempre

Mientras se apunta corre un reloj en 0xE202 que solo avanza cuando el contador
de cuadros vale cero, o sea **un cuadro de cada 256**. Cuando llega a cero, la
tacada se da por perdida.

Como el contador se pone a cero con cualquier tecla y luego cuenta 256 pasadas,
la cuenta atrás entera son 65.536 cuadros: más de veinte minutos sin tocar
absolutamente nada. Está pensado para una máquina que se queda encendida, no
para meter prisa.

## El teclado se disfraza de joystick a base de rotaciones

Las seis entradas del juego —cuatro direcciones y dos botones— se leen del
joystick por el PSG y del teclado por la BIOS, y **las dos cosas valen siempre
a la vez**: no hay que elegir, se juntan con un `or`.

Para que se puedan juntar, los bits del teclado tienen que caer en las mismas
posiciones que los del joystick, y eso se consigue con cinco rotaciones
encadenadas que van dejando cada tecla en su sitio. Simulando el código tecla a
tecla, el reparto es este:

| tecla | hace de |
|---|---|
| flechas | las cuatro direcciones |
| ESPACIO | botón de tiro |
| SELECT | segundo botón |

Y ninguna otra tecla de las dos filas que se leen produce nada.

## La fase da la vuelta a las cien

El número de fase (0xE051) sube en BCD con `add a,001h` y `daa`, y no hay nada
que compruebe si se ha desbordado. Al pasar de 99 vuelve a 00 y el marcador
sigue como si nada.
