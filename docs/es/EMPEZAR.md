# Empezar

Este repositorio contiene un **desensamblado comentado** de Konami's Billiards
para MSX (Konami, 1984, cartucho RC-706). Todo lo que hay aquí sale del binario
y se puede volver a generar desde él.

## Lo que hace falta

- **Python 3** (sin paquetes de terceros)
- **pasmo**, para reensamblar
- **z80dasm**, que solo se usa para los mnemónicos
- la imagen del cartucho, que este repositorio **no distribuye**

La ROM va en la raíz, como `billiards.rom`. Son 16384 bytes exactos:

    sha256  38741612e0b20e39dfd834106a3d5ef5a24c06fb947a104c044f1cdd269c46d9

`make comprueba` lo verifica.

## La prueba que importa

    make verify

Esto reensambla el listado con pasmo y compara el resultado con la ROM
original, byte a byte. Si sale `OK: reproducible byte a byte`, el desensamblado
no se ha inventado nada: es el mismo cartucho escrito de otra forma.

## Lo demás que se puede correr

    make            # el ciclo entero: listado, notas, verify, sanity y tests
    make listado    # regenera src/billiards.asm desde el trazado y las notas
    make sanity     # las comprobaciones que el reensamblado NO cubre
    make test       # los tests
    make densidad   # cuántos comentarios lleva cada rutina
    make imagenes   # rehace los dibujos de docs/imagenes desde la ROM
    make web        # regenera el sitio

`make sanity` es la que vigila lo que un reensamblado correcto puede esconder:
que unos datos se estén leyendo como código. Los bytes salen iguales de todas
formas, porque no cambian; lo único que cambia es lo que decimos de ellos.

## Cómo está montado

    src/billiards.asm       el listado, GENERADO — no se edita a mano
    src/billiards.notes     las anotaciones, ancladas a dirección
    src/billiards.entries   los puntos de entrada que no se deducen solos
    src/billiards.nocode    los tramos que no son código
    tools/                  el trazador, el generador y las comprobaciones
    docs/                   este sitio

El listado **no se edita**: se edita el `.notes` y se vuelve a generar. Cada
anotación va anclada a una dirección, así que sobrevive a un retrazado y no se
descoloca si algo se mueve.

Las directivas del `.notes` son cinco: `L` pone nombre y descripción a una
etiqueta, `C` cuelga un comentario de una instrucción, `B` mete una cabecera de
bloque, `D` declara un rango de datos con su nombre y `F` dice de cuántos bytes
son las filas de una tabla.

## Los dibujos

    make imagenes

No hay ni una captura de pantalla en este sitio. `tools/graficos.py` repite,
instrucción a instrucción, las rutinas de carga del cartucho y sus dos
intérpretes de dibujo sobre una memoria de vídeo vacía, y luego revela esa VRAM
como la revelaría el VDP. No hace falta emulador, y que la mesa salga bien es
la mejor prueba de que las rutinas se han leído bien.
