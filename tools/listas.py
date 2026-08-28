#!/usr/bin/env python3
"""Decodifica las listas de pintado del cartucho. Hay DOS interpretes:

  A) 0x472A / 0x472E  -  [destino_VRAM:2] [bytes] ... 0xFE=otro destino, 0xFF=fin
     Con la entrada 0x472A el byte se enmascara con 0 (o sea, BORRA lo que la
     misma lista pinta); con 0x472E se escribe tal cual.

  B) 0x4965 / 0x4969  -  [destino_VRAM:2] [ordenes] ... 0xFF=otro destino, 0x00=fin
     Cada orden es un contador: con el bit 7 puesto, copia (n and 0x7F) bytes
     literales de la lista; con el bit 7 limpio, repite n veces el byte que
     sigue.

Los numeros de tile de los textos son ASCII directo: la fuente de 0x4136
ocupa los tiles 0x30-0x5F, o sea "0"-"9", los simbolos y las mayusculas.

Uso: listas.py <rom> <a|b> <direccion> [limite]
"""
import sys

ORG = 0x4000


def texto(bs):
    out = []
    for b in bs:
        if 0x30 <= b <= 0x5F:
            out.append(chr(b))
        elif b == 0x00:
            out.append(' ')
        else:
            out.append('.')
    return "".join(out)


def fila_col(de):
    v = de & 0x3FFF
    if 0x3800 <= v < 0x3B00:
        return "  nombres fila %2d col %2d" % ((v - 0x3800) // 32, (v - 0x3800) % 32)
    return ""


def lista_a(d, p, lim):
    while p < lim:
        de = d[p] | (d[p + 1] << 8)
        p += 2
        bs = []
        while p < lim:
            b = d[p]
            p += 1
            if b in (0xFE, 0xFF):
                break
            bs.append(b)
        print("  VRAM %04X%s  n=%d  |%s|" % (de, fila_col(de), len(bs), texto(bs)))
        print("        " + " ".join("%02X" % x for x in bs))
        if b == 0xFF:
            print("  --- fin de la lista en 0x%04X (%d bytes)" % (ORG + p - 1, p - (0)))
            return ORG + p
    return ORG + p


def lista_b(d, p, lim):
    while p < lim:
        de = d[p] | (d[p + 1] << 8)
        p += 2
        print("  VRAM %04X%s" % (de, fila_col(de)))
        while p < lim:
            n = d[p]
            p += 1
            if n == 0xFF:
                break
            if n == 0x00:
                print("  --- fin de la lista en 0x%04X" % (ORG + p - 1))
                return ORG + p
            if n & 0x80:
                k = n & 0x7F
                bs = d[p:p + k]
                p += k
                print("        literal %2d: %s  |%s|"
                      % (k, " ".join("%02X" % x for x in bs), texto(bs)))
            else:
                print("        repite  %2d veces 0x%02X" % (n, d[p]))
                p += 1
    return ORG + p


def main():
    d = open(sys.argv[1], "rb").read()
    modo = sys.argv[2].lower()
    a = int(sys.argv[3], 0)
    lim = int(sys.argv[4], 0) if len(sys.argv) > 4 else 0xC000
    fin = (lista_a if modo == "a" else lista_b)(d, a - ORG, lim - ORG)
    print("  [acaba en 0x%04X]" % fin)
    return 0


if __name__ == "__main__":
    sys.exit(main())
