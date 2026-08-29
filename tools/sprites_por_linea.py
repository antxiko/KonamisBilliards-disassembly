#!/usr/bin/env python3
"""Cuenta los sprites de Konami's Billiards linea de barrido a linea de barrido.

El TMS9918 del MSX1 tiene 32 sprites en la tabla de atributos, pero solo dibuja
CUATRO por linea de barrido: del quinto en adelante los descarta en esa linea.
El limite no va por sprites en pantalla, va por linea, y no mira la X para nada:
un sprite cuenta en una linea si esa linea cae dentro de su casilla vertical.

Con MAG = 0 y sprites de 16x16 la casilla son 16 lineas, las Y+1 .. Y+16. Esas
dos cosas -el tamano y la magnificacion- salen del registro 1 del VDP, y por eso
lo primero que hace esta herramienta es leerlo de la ROM en vez de suponerlo.

Lo que comprueba, todo sacado de los bytes del cartucho:

  - R1 dice sprites de 16x16 (bit 1) y sin magnificar (bit 0);
  - R5 pone los atributos donde el listado dice que los pone;
  - los siete dibujos de bola miden 10x12 y la mira 4x4;
  - y el triangulo de salida de 0x461F NO pasa de cuatro sprites en ninguna
    linea, que es lo que se afirma en la web.

De propina imprime la tabla linea a linea y mide el margen que queda: cuanto
hay que mover una sola bola para que ese cuatro se convierta en cinco.

Uso:  sprites_por_linea.py <rom> [--png <directorio>]
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import graficos                                          # noqa: E402

ORG = 0x4000

REGISTROS = 0x46BE      # los ocho valores que 0x46AD escribe en el VDP
POSICIONES = 0x461F     # las ocho entradas de arranque, 4 bytes cada una
PATRONES = 0x4B30       # los dibujos, que 0x4A5A copia a VRAM 0x1800
LIMITE = 4              # sprites por linea que dibuja el TMS9918
CASILLA = 16            # lineas que ocupa un sprite de 16x16 con MAG = 0

NOMBRES = ("la bola blanca", "la 1", "la 2", "la 3", "la 4", "la 5", "la 6",
           "la mira")

BOLAS = 7               # las siete que ruedan; la octava entrada es la mira

# Los topes del pano, leidos donde estan: dos `sub n` seguidos por eje dentro de
# mueve_una_bola. El primero deja el origen en cero y el segundo mide el ancho,
# asi que el rango es [n1, n1 + n2 - 1].
TOPES = {"Y": (0x4ED4, 0x4ED6), "X": (0x4E9B, 0x4E9D)}
SUB = 0xD6              # el opcode de `sub n`


def tope(rom, eje):
    """(minimo, maximo) de un eje, sacado de los dos `sub n` del cartucho."""
    a, b = TOPES[eje]
    if rom[a - ORG] != SUB or rom[b - ORG] != SUB:
        return None
    ini, ancho = rom[a - ORG + 1], rom[b - ORG + 1]
    return ini, ini + ancho - 1


def entradas(rom):
    """Las ocho de 0x461F: (Y, X, numero de patron, color)."""
    return [tuple(rom[POSICIONES - ORG + i * 4 + j] for j in range(4))
            for i in range(8)]


def caja(rom, n):
    """La caja del dibujo del patron n: (fila0, fila1, col0, col1, pixeles).

    Un patron de 16x16 son 32 bytes: los 16 primeros llevan las columnas 0-7 de
    las filas 0-15, y los 16 siguientes las columnas 8-15. Devuelve None si el
    patron esta vacio.
    """
    b = rom[PATRONES - ORG + n * 32:PATRONES - ORG + (n + 1) * 32]
    filas, cols = [], []
    for f in range(16):
        for c in range(16):
            byte = b[f] if c < 8 else b[16 + f]
            if byte & (0x80 >> (c & 7)):
                filas.append(f)
                cols.append(c)
    if not filas:
        return None
    return min(filas), max(filas), min(cols), max(cols), len(filas)


def por_linea(ys):
    """{linea: [indices]} para una lista de coordenadas Y."""
    cuenta = {}
    for i, y in enumerate(ys):
        for l in range(y + 1, y + 1 + CASILLA):
            cuenta.setdefault(l, []).append(i)
    return cuenta


def tramos(cuenta):
    """Junta las lineas seguidas que llevan los mismos sprites."""
    out, ini, previo = [], None, None
    for l in sorted(cuenta):
        quienes = tuple(cuenta[l])
        if quienes != previo:
            if previo is not None:
                out.append((ini, l - 1, previo))
            ini, previo = l, quienes
    out.append((ini, max(cuenta), previo))
    return out


def margen(ys):
    """El desplazamiento mas pequeno de UNA sola entrada que da cinco en una
    linea. Devuelve (pixeles, indice, sentido, linea) o None si no lo hay."""
    for d in range(1, 0x40):
        for sentido in (-1, 1):
            for i in range(len(ys)):
                movidas = list(ys)
                movidas[i] = ys[i] + sentido * d
                if not 0 <= movidas[i] <= 0xBF:
                    continue
                cuenta = por_linea(movidas)
                for l in sorted(cuenta):
                    if len(cuenta[l]) > LIMITE:
                        return d, i, sentido, l
    return None


# ---------------------------------------------------------------------------
# El dibujo
# ---------------------------------------------------------------------------
ESC = 2
ANCHO_RANURA = 14
PASO_RANURA = 16
HUECO = 8

GRIS_CASILLA = (215, 215, 225)   # el borde de la casilla de 16x16
RANURA_VACIA = (52, 52, 60)      # el hueco del medidor que no se usa
FONDO = (24, 24, 28)


def png_triangulo(rom, fn):
    """La mesa como sale de la ROM, con la casilla de 16 lineas de cada sprite
    dibujada y, a la derecha, cuantos sprites toca cada linea de barrido.

    La pantalla la monta graficos.py repitiendo las cargas del INIT: aqui no hay
    captura ninguna, igual que en el resto de las imagenes del repositorio.
    """
    v = graficos.monta_la_pantalla(rom)
    ents = entradas(rom)
    cuenta = por_linea([y for (y, _, _, _) in ents])

    ancho_medidor = LIMITE * PASO_RANURA
    w = 256 * ESC + HUECO + ancho_medidor + HUECO + 8 * ESC + HUECO
    h = 192 * ESC
    px = [[FONDO] * w for _ in range(h)]

    for fila in range(24):
        for col in range(32):
            t = v.m[0x3800 + fila * 32 + col]
            graficos.pinta_tile(v, fila // 8, t, px, col * 8, fila * 8, ESC)

    # la casilla de 16 lineas, a rayas, ANTES de las bolas: lo que mira el VDP
    # no es el dibujo de 10x12 sino este cuadrado
    for (y, x, _, _) in ents:
        for i in range(CASILLA):
            for (sy, sx) in ((y + 1, x + i), (y + CASILLA, x + i),
                             (y + 1 + i, x), (y + 1 + i, x + 15)):
                if (sy + sx) // 2 % 2 or not (0 <= sx < 256 and 0 <= sy < 192):
                    continue
                for e in range(ESC):
                    px[sy * ESC + e][sx * ESC:sx * ESC + ESC] = \
                        [GRIS_CASILLA] * ESC

    for (y, x, pat, color) in ents:
        graficos.pinta_sprite(v, px, pat, x, y + 1, color, ESC, w, h)

    # el medidor: una ranura por sprite, y la cuarta en rojo porque es la ultima
    # que el VDP dibuja
    x0 = 256 * ESC + HUECO
    for linea in range(192):
        n = len(cuenta.get(linea, ()))
        for r in range(LIMITE):
            c = RANURA_VACIA
            if r < n:
                c = graficos.PAL[8] if n == LIMITE else graficos.PAL[7]
            ox = x0 + r * PASO_RANURA
            for e in range(ESC):
                px[linea * ESC + e][ox:ox + ANCHO_RANURA] = [c] * ANCHO_RANURA

    # y el numero, escrito con la fuente del propio cartucho: el tile 0x30 es el
    # cero, asi que el digito sale de sumarle la cuenta
    ox = x0 + ancho_medidor + HUECO
    for (ini, fin, quienes) in tramos(cuenta):
        oy = (ini + fin) // 2 - 4
        if not 0 <= oy <= 192 - 8:
            continue
        glifo = 0x2000 + (0x30 + len(quienes)) * 8
        c = graficos.PAL[8] if len(quienes) == LIMITE else graficos.PAL[15]
        for f in range(8):
            for b in range(8):
                if not v.m[glifo + f] & (0x80 >> b):
                    continue
                for ey in range(ESC):
                    y = (oy + f) * ESC + ey
                    px[y][ox + b * ESC:ox + (b + 1) * ESC] = [c] * ESC

    graficos.png(w, h, px, fn)


# ---------------------------------------------------------------------------
def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2
    rom = open(argv[1], "rb").read()
    salida = None
    if "--png" in argv:
        salida = argv[argv.index("--png") + 1].rstrip("/")

    malas = []

    def exige(condicion, texto):
        if not condicion:
            malas.append(texto)

    regs = rom[REGISTROS - ORG:REGISTROS - ORG + 8]
    r1, r5, r6 = regs[1], regs[5], regs[6]

    print("  Como deja el VDP la rutina de 0x46AD, con los ocho valores de 0x%04X"
          % REGISTROS)
    print("    R1 = 0x%02X = %sb   bit 1 = %d -> sprites de %s"
          % (r1, format(r1, "08b"), (r1 >> 1) & 1,
             "16x16" if (r1 >> 1) & 1 else "8x8"))
    print("                            bit 0 = %d -> MAG = %d, %s"
          % (r1 & 1, r1 & 1,
             "magnificado x2" if r1 & 1 else "sin magnificar"))
    print("    R5 = 0x%02X -> atributos de sprite en VRAM 0x%04X, 32 entradas de "
          "4 bytes" % (r5, r5 * 0x80))
    print("    R6 = 0x%02X -> dibujos de sprite en VRAM 0x%04X"
          % (r6, r6 * 0x800))
    print("    Con 16x16 y MAG = 0, un sprite tapa %d lineas de PANTALLA: las "
          "Y+1 a Y+%d." % (CASILLA, CASILLA))
    exige((r1 >> 1) & 1 == 1, "R1 no pide sprites de 16x16")
    exige(r1 & 1 == 0, "R1 pide magnificacion, y la web dice que no")
    exige(r5 * 0x80 == 0x3B00, "los atributos no caen en VRAM 0x3B00")
    exige(r6 * 0x800 == 0x1800, "los dibujos no caen en VRAM 0x1800")

    print()
    print("  Los dibujos (0x%04X, que 0x4A5A copia a VRAM 0x1800)" % PATRONES)
    for n in range(8):
        k = caja(rom, n)
        f0, f1, c0, c1, pixeles = k
        print("    patron 0x%02X  filas %2d-%2d  columnas %2d-%2d  = %2d x %2d  "
              "%3d pixeles  %s"
              % (n * 4, f0, f1, c0, c1, c1 - c0 + 1, f1 - f0 + 1, pixeles,
                 NOMBRES[n]))
        if n < 7:
            exige((f0, f1, c0, c1) == (2, 13, 3, 12),
                  "el patron 0x%02X no es el 10x12 de las filas 2-13 y las "
                  "columnas 3-12" % (n * 4))
        else:
            exige((f0, f1, c0, c1) == (6, 9, 6, 9),
                  "la mira no es el 4x4 de las filas 6-9 y las columnas 6-9")

    ents = entradas(rom)
    print()
    print("  Las ocho entradas de arranque (0x%04X, cuatro bytes: Y, X, patron, "
          "color)" % POSICIONES)
    for i, (y, x, pat, color) in enumerate(ents):
        print("    %d  Y = 0x%02X (%3d)  X = 0x%02X (%3d)  patron 0x%02X  color "
              "%2d  -> lineas %3d-%3d  %s"
              % (i, y, y, x, x, pat, color, y + 1, y + CASILLA, NOMBRES[i]))

    cuenta = por_linea([y for (y, _, _, _) in ents])
    pico = max(len(q) for q in cuenta.values())
    print()
    print("  El triangulo de salida, linea de barrido a linea de barrido")
    for (ini, fin, quienes) in tramos(cuenta):
        marca = "  <- en el limite" if len(quienes) == LIMITE else ""
        print("    lineas %3d-%3d  %d sprite%s  %s%s"
              % (ini, fin, len(quienes), "" if len(quienes) == 1 else "s",
                 " ".join(str(q) for q in quienes), marca))
    print()
    print("    maximo %d sprites por linea, y el TMS9918 dibuja %d: cabe justo."
          % (pico, LIMITE))
    exige(pico == LIMITE,
          "el maximo por linea es %d, y la web dice %d" % (pico, LIMITE))
    m = margen([y for (y, _, _, _) in ents])
    if m:
        d, i, sentido, linea = m
        print("    y por los pelos: %s (entrada %d, Y = 0x%02X) %d pixel%s hacia "
              "%s ya da %d sprites en la linea %d."
              % (NOMBRES[i], i, ents[i][0], d, "" if d == 1 else "es",
                 "abajo" if sentido > 0 else "arriba", LIMITE + 1, linea))
    exige(m is not None and m[0] == 1,
          "el margen hasta los cinco sprites ya no es de un pixel")


    ry, rx = tope(rom, "Y"), tope(rom, "X")
    print()
    print("  Y en partida se pasa de cuatro, porque no cabe de otra manera")
    for eje, r, sitio in (("Y", ry, TOPES["Y"]), ("X", rx, TOPES["X"])):
        if r is None:
            malas.append("los dos `sub n` del eje %s ya no estan donde estaban"
                         % eje)
            continue
        print("    %s del centro de una bola: 0x%02X a 0x%02X, %d valores  "
              "(los `sub` de 0x%04X y 0x%04X)"
              % (eje, r[0], r[1], r[1] - r[0] + 1, sitio[0], sitio[1]))
    if ry:
        franja = (ry[1] + CASILLA) - (ry[0] + 1) + 1
        print("    o sea que las casillas de las siete bolas viven en %d lineas, "
              "de la %d a la %d," % (franja, ry[0] + 1, ry[1] + CASILLA))
        print("    y entre las siete miden %d x %d = %d. Sobran %d lineas: que "
              "dos se solapen"
              % (BOLAS, CASILLA, BOLAS * CASILLA, franja - BOLAS * CASILLA))
        print("    no es la excepcion, es lo que pasa siempre.")
        exige(franja - BOLAS * CASILLA == 3,
              "la holgura de la franja ya no son 3 lineas")

    if salida:
        png_triangulo(rom, salida + "/sprites_por_linea.png")
        print()
        print("    escrito %s/sprites_por_linea.png" % salida)

    print()
    if malas:
        print("  LA ROM NO DICE LO QUE DICE LA WEB:")
        for t in malas:
            print("    - %s" % t)
        return 1
    print("  OK: los sprites de la ROM son los que la web describe")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
