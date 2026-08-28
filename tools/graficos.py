#!/usr/bin/env python3
"""Reconstruye desde la ROM lo que Konami's Billiards dibuja en pantalla.

Nada de esto son capturas: aqui no hay emulador. Lo que hace la herramienta es
repetir, instruccion a instruccion, las rutinas de carga y los dos interpretes
de dibujo del cartucho sobre una memoria de video vacia, y luego revelar esa
VRAM como la revelaria el VDP. Si el dibujo sale bien es que las rutinas se han
entendido bien; es la comprobacion mas honesta que hay de un desensamblado.

Los interpretes, tal como estan en el listado:

    FORMATO A   0x472E pinta y 0x472A borra (la unica diferencia es la mascara
                de C). [destino:2][tiles...], con 0xFE = viene otro destino y
                0xFF = fin.
    FORMATO B   0x4969, con el destino ya en DE (0x4965 lo lee delante).
                Ordenes: 0x00 = fin, 0xFF = viene otro destino, bit 7 puesto =
                copia (n & 0x7F) literales, bit 7 a cero = repite n veces el
                byte que sigue.

Y las cuatro cargas que el INIT (0x405F) encadena al arrancar:

    0x490A  el logotipo KONAMI      -> patrones 0x2008, los tres tercios
    0x4A24  los tiles de la mesa    -> patrones 0x2400 y colores 0x0400
    0x4743  la fuente               -> patrones 0x2180, colores a 0xF0
    0x5766  el rotulo BILLIARDS     -> patrones 0x2600, SOLO el primer tercio

En SCREEN 2 el generador son tres tablas de 0x800, una por tercio de pantalla,
y por eso casi todas las cargas repiten la copia tres veces sumando 0x800. El
rotulo grande es la excepcion: solo vive en el primer tercio, que es donde
cae la fila 5.

Uso: graficos.py <rom> <directorio de salida>
"""
import struct
import sys
import zlib

ORG = 0x4000

# La paleta del TMS9918, en el orden en que la numera el VDP.
PAL = [(0, 0, 0), (0, 0, 0), (33, 200, 66), (94, 220, 120), (84, 85, 237),
       (125, 118, 252), (212, 82, 77), (66, 235, 245), (252, 85, 84),
       (255, 121, 120), (212, 193, 84), (230, 206, 128), (33, 176, 59),
       (201, 91, 186), (204, 204, 204), (255, 255, 255)]

GRIS = (56, 56, 64)          # lo que el cartucho no llega a escribir
REJILLA = (90, 90, 96)


def png(w, h, filas, fn):
    raw = b"".join(b"\x00" + bytes(v for p in f for v in p) for f in filas)

    def chunk(t, d):
        return (struct.pack(">I", len(d)) + t + d
                + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff))

    with open(fn, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n"
                + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
                + chunk(b"IDAT", zlib.compress(raw))
                + chunk(b"IEND", b""))


class VRAM:
    """Los 16 KB del VDP, y ademas la cuenta de que bytes ha tocado el cartucho."""

    def __init__(self):
        self.m = bytearray(0x4000)
        self.puesto = bytearray(0x4000)

    def pon(self, d, v):
        d &= 0x3FFF
        self.m[d] = v
        self.puesto[d] = 1

    def llena(self, d, n, v):
        for i in range(n):
            self.pon(d + i, v)

    def bloque(self, datos, d):
        for i, b in enumerate(datos):
            self.pon(d + i, b)


# ---------------------------------------------------------------------------
# Los dos interpretes
# ---------------------------------------------------------------------------
def formato_b(rom, v, hl, de):
    """0x4969. Devuelve donde se queda HL, que es lo que necesita 0x4A39."""
    while True:
        orden = rom[hl - ORG]
        hl += 1
        if orden == 0x00:                       # 0x496E: fin del bloque
            return hl
        if orden == 0xFF:                       # 0x4970: viene otro destino
            de = rom[hl - ORG] | (rom[hl - ORG + 1] << 8)
            hl += 2
            continue
        if orden & 0x80:                        # 0x4983: literales
            n = orden & 0x7F
            for _ in range(n):
                v.pon(de, rom[hl - ORG])
                hl += 1
                de += 1
        else:                                   # 0x4978: repeticion
            b = rom[hl - ORG]
            hl += 1
            for _ in range(orden):
                v.pon(de, b)
                de += 1


def formato_a(rom, v, hl, mascara=0xFF):
    """0x472E con la mascara a 0xFF, 0x472A con la mascara a 0x00."""
    de = rom[hl - ORG] | (rom[hl - ORG + 1] << 8)
    hl += 2
    while True:
        b = rom[hl - ORG]
        hl += 1
        if b == 0xFF:                           # 0x4737: fin
            return
        if b == 0xFE:                           # 0x4739: otro destino
            de = rom[hl - ORG] | (rom[hl - ORG + 1] << 8)
            hl += 2
            continue
        v.pon(de, b & mascara)
        de += 1


def tres_tercios(f):
    """El envoltorio de 0x4757, 0x476C y 0x4953: la misma copia en los tres
    tercios del generador, sumando 0x800 cada vez."""
    def envuelto(rom, v, destino, *a):
        for t in range(3):
            f(rom, v, destino + t * 0x800, *a)
    return envuelto


# ---------------------------------------------------------------------------
# Las cargas del INIT, cada una donde el cartucho la tiene
# ---------------------------------------------------------------------------
def carga_los_tiles_del_logo(rom, v):
    """0x490A: el logotipo KONAMI comprimido, y su color blanco."""
    for t in range(3):
        formato_b(rom, v, 0x498D, 0x2008 + t * 0x800)
        v.llena(0x0008 + t * 0x800, 0xD8, 0xF0)


def carga_los_tiles_de_la_mesa(rom, v):
    """0x4A24: 472 bytes de patrones tal cual, y sus colores comprimidos."""
    for t in range(3):
        v.bloque(rom[0x4A70 - ORG:0x4C48 - ORG], 0x2400 + t * 0x800)
        formato_b(rom, v, 0x4C40, 0x0400 + t * 0x800)


def carga_la_fuente(rom, v):
    """0x4743: los 48 glifos en los tiles 0x30-0x5F, blancos sobre nada."""
    for t in range(3):
        v.llena(0x0180 + t * 0x800, 0x180, 0xF0)
        v.bloque(rom[0x4136 - ORG:0x42B6 - ORG], 0x2180 + t * 0x800)


def carga_el_rotulo_grande(rom, v):
    """0x5766: los tiles 0xC0-0xDE. Solo el primer tercio, que es donde cae la
    fila 5; el apostrofe va blanco y las letras del BILLIARDS, verdes."""
    v.bloque(rom[0x5788 - ORG:0x5880 - ORG], 0x2600)
    v.llena(0x0600, 0x08, 0xF0)
    v.llena(0x0608, 0xF0, 0xC0)


def pinta_la_mesa(rom, v):
    """0x4A39. El plano de 0x4C59 es una tira de [cuantas filas][bloque formato
    B], y cada bloque se repite bajando de 32 en 32 desde la VRAM 0x38E2, que
    es la fila 7 columna 2. Un cero cierra el plano."""
    hl, de = 0x4C59, 0x38E2
    while True:
        n = rom[hl - ORG]
        hl += 1
        if n == 0:
            break
        bloque = hl
        for _ in range(n):
            hl = formato_b(rom, v, bloque, de)
            de += 0x20
    # 0x4A5A: los patrones de sprite, que son los mismos bytes de la mesa
    v.bloque(rom[0x4B30 - ORG:0x4C50 - ORG], 0x1800)


def monta_la_pantalla(rom):
    """Todo lo que el INIT deja cargado, mas la mesa pintada."""
    v = VRAM()
    carga_los_tiles_del_logo(rom, v)
    carga_los_tiles_de_la_mesa(rom, v)
    carga_la_fuente(rom, v)
    carga_el_rotulo_grande(rom, v)
    pinta_la_mesa(rom, v)
    return v


# ---------------------------------------------------------------------------
# Revelar la VRAM
# ---------------------------------------------------------------------------
def pinta_tile(v, tercio, t, px, ox, oy, esc=1):
    """Un tile de 8x8 con su color, tal como lo lee el VDP en SCREEN 2."""
    pat = 0x2000 + tercio * 0x800 + t * 8
    col = 0x0000 + tercio * 0x800 + t * 8
    for y in range(8):
        linea, c = v.m[pat + y], v.m[col + y]
        visto = v.puesto[pat + y] or v.puesto[col + y]
        fg, bg = PAL[c >> 4], PAL[c & 15]
        for x in range(8):
            if not visto:
                p = GRIS
            else:
                p = fg if linea & (0x80 >> x) else bg
            for dy in range(esc):
                for dx in range(esc):
                    px[(oy + y) * esc + dy][(ox + x) * esc + dx] = p


def png_pantalla(v, fn, con_bolas=None, rom=None, esc=2):
    """La pantalla entera: 32x24 tiles, cada fila leyendo el tercio que le toca."""
    w, h = 256 * esc, 192 * esc
    px = [[PAL[1]] * w for _ in range(h)]
    for fila in range(24):
        for col in range(32):
            t = v.m[0x3800 + fila * 32 + col]
            pinta_tile(v, fila // 8, t, px, col * 8, fila * 8, esc)
    if con_bolas:
        for (y, x, pat, color) in con_bolas:
            pinta_sprite(v, px, pat, x, y + 1, color, esc, w, h)
    png(w, h, px, fn)


def pinta_sprite(v, px, pat, x, y, color, esc, w, h):
    """Un sprite de 16x16: cuatro cuadrantes de 8x8 en columnas, como el VDP."""
    c = PAL[color & 15]
    base = 0x1800 + pat * 8
    for cuad, (dx, dy) in enumerate(((0, 0), (0, 8), (8, 0), (8, 8))):
        for fy in range(8):
            linea = v.m[base + cuad * 8 + fy]
            for fx in range(8):
                if not linea & (0x80 >> fx):
                    continue
                sx, sy = x + dx + fx, y + dy + fy
                if not (0 <= sx < 256 and 0 <= sy < 192):
                    continue
                for ey in range(esc):
                    for ex in range(esc):
                        px[sy * esc + ey][sx * esc + ex] = c


def png_tiles(v, tercio, primero, cuantos, fn, ancho=16, esc=3):
    """Una rejilla de tiles con su color, para mirarlos de cerca."""
    filas = (cuantos + ancho - 1) // ancho
    w = ancho * (8 * esc + 1) + 1
    h = filas * (8 * esc + 1) + 1
    px = [[REJILLA] * w for _ in range(h)]
    for i in range(cuantos):
        f, c = divmod(i, ancho)
        ox, oy = c * (8 * esc + 1) + 1, f * (8 * esc + 1) + 1
        sub = [[GRIS] * (8 * esc) for _ in range(8 * esc)]
        pinta_tile(v, tercio, primero + i, sub, 0, 0, esc)
        for y in range(8 * esc):
            px[oy + y][ox:ox + 8 * esc] = sub[y]
    png(w, h, px, fn)


def png_sprites(v, cuantos, fn, esc=3):
    """Los dibujos de sprite de 16x16 de la VRAM 0x1800."""
    w = cuantos * (16 * esc + 1) + 1
    h = 16 * esc + 2
    px = [[REJILLA] * w for _ in range(h)]
    for i in range(cuantos):
        ox = i * (16 * esc + 1) + 1
        for cuad, (dx, dy) in enumerate(((0, 0), (0, 8), (8, 0), (8, 8))):
            for fy in range(8):
                linea = v.m[0x1800 + i * 32 + cuad * 8 + fy]
                for fx in range(8):
                    p = PAL[15] if linea & (0x80 >> fx) else PAL[1]
                    for ey in range(esc):
                        for ex in range(esc):
                            px[1 + (dy + fy) * esc + ey][ox + (dx + fx) * esc + ex] = p
    png(w, h, px, fn)


def png_rotulo(v, fn, esc=3):
    """El BILLIARDS grande, montado como lo monta 0x48B8: quince letras de dos
    tiles, la de arriba desde 0xC1 y la de abajo quince mas alla."""
    w, h = 15 * 8 * esc, 16 * esc
    px = [[PAL[1]] * w for _ in range(h)]
    for i in range(15):
        pinta_tile(v, 0, 0xC1 + i, px, i * 8, 0, esc)
        pinta_tile(v, 0, 0xD0 + i, px, i * 8, 8, esc)
    png(w, h, px, fn)


def png_logo_konami(v, fn, esc=3):
    """El logotipo KONAMI de 0x498D, en las tres filas de 3, 11 y 12 tiles que
    reparte 0x491E."""
    w, h = 12 * 8 * esc, 24 * esc
    px = [[PAL[1]] * w for _ in range(h)]
    t = 1
    for fila, n in enumerate((3, 11, 12)):
        for i in range(n):
            pinta_tile(v, 0, t, px, i * 8, fila * 8, esc)
            t += 1
    png(w, h, px, fn)


def main(argv):
    rom = open(argv[1], "rb").read()
    out = argv[2].rstrip("/")
    v = monta_la_pantalla(rom)

    # Las OCHO entradas de 0x461F. La octava no es una bola: es la mira, y se
    # dibuja como las demas -0x463F vuelca dos grupos de cuatro sprites, o sea
    # los ocho- con el patron 0x1C, que es ese punto pequeno. El 0xD0 que
    # 0x4A66 mete en 0x3B1C corta la lista solo hasta el refresco siguiente.
    bolas = []
    for i in range(8):
        b = 0x461F - ORG + i * 4
        bolas.append((rom[b], rom[b + 1], rom[b + 2], rom[b + 3]))

    png_pantalla(v, out + "/mesa.png", con_bolas=bolas, rom=rom)
    png_pantalla(v, out + "/mesa_vacia.png")
    png_tiles(v, 0, 0x80, 59, out + "/tiles.png")
    png_tiles(v, 0, 0x30, 48, out + "/fuente.png")
    png_sprites(v, 9, out + "/sprites.png")   # nueve: el ultimo no es un dibujo
    png_rotulo(v, out + "/rotulo.png")
    png_logo_konami(v, out + "/logo_konami.png")
    print("escritas 7 imagenes en %s/" % out)


if __name__ == "__main__":
    main(sys.argv)
