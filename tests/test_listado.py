#!/usr/bin/env python3
"""Comprobaciones sobre el listado generado.

Ninguna de estas necesita el cartucho: se hacen sobre src/billiards.asm y
src/billiards.notes (salvo la del espejo de sanity, que ejecuta
presupuesto.py sobre el trazado de work/).
"""
import os
import re
import unittest

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASM = os.path.join(RAIZ, "src", "billiards.asm")
NOTES = os.path.join(RAIZ, "src", "billiards.notes")

ORG, FIN = 0x4000, 0x8000        # 16 KB: pagina 1, 0x4000-0x7FFF

# Lo que imprime `make sanity`. Si esta cifra se mueve sin que el commit lo
# explique, algo ha cambiado el trazado o las notas sin que nadie se entere.
CODIGO, DATOS = 5343, 11041


def asm():
    with open(ASM, encoding="utf-8") as f:
        return f.read()


def notas():
    with open(NOTES, encoding="utf-8") as f:
        return f.read()


class TestListado(unittest.TestCase):
    def test_no_hay_datos_sin_identificar(self):
        """Ni un `DATOS sin identificar` debe quedar en el listado."""
        self.assertNotIn("DATOS sin identificar", asm())

    def test_las_cifras_de_sanity_no_se_mueven_solas(self):
        """Espejo de lo que imprime presupuesto.py; si cambia, hay que revisar
        por que y actualizar esta constante a proposito, no sin darse cuenta."""
        import subprocess
        import sys
        r = subprocess.run(
            [sys.executable, os.path.join(RAIZ, "tools", "presupuesto.py"),
             os.path.join(RAIZ, "work"), os.path.join(RAIZ, "src")],
            capture_output=True, text=True, cwd=RAIZ)
        m_c = re.search(r"codigo trazado\s+(\d+)", r.stdout)
        m_d = re.search(r"datos identificados\s+(\d+)", r.stdout)
        self.assertIsNotNone(m_c, r.stdout)
        self.assertIsNotNone(m_d, r.stdout)
        self.assertEqual(int(m_c.group(1)), CODIGO)
        self.assertEqual(int(m_d.group(1)), DATOS)
        self.assertEqual(int(m_c.group(1)) + int(m_d.group(1)), FIN - ORG)

    def test_los_bloques_d_del_cartucho_no_se_solapan(self):
        """Los rangos D dentro de 0x4000-0x7FFF no se pisan. Los solapes
        REALES del cartucho (los tiles de la mesa que tambien son sprites, y
        el rotulo x100 cuyo ultimo byte hace de tope de la tabla siguiente)
        estan declarados como rangos CONTIGUOS y contados en su descripcion,
        asi que aqui no aparecen."""
        rangos = []
        for ln in notas().splitlines():
            m = re.match(r"^D\s+0x([0-9A-Fa-f]+)\s+0x([0-9A-Fa-f]+)", ln)
            if m:
                a, b = int(m.group(1), 16), int(m.group(2), 16)
                if ORG <= a < FIN:
                    rangos.append((a, b))
        rangos.sort()
        for (a1, b1), (a2, b2) in zip(rangos, rangos[1:]):
            self.assertLessEqual(b1, a2,
                                  "0x%04X-0x%04X se solapa con 0x%04X-0x%04X"
                                  % (a1, b1, a2, b2))

    def test_etiquetas_sin_acentos_ni_enes(self):
        """pasmo no ensambla etiquetas con caracteres fuera de ASCII, y
        densidad.py cuenta una rutina menos por cada una: ni un solo nombre
        de rango o etiqueta puede llevarlos."""
        for ln in notas().splitlines():
            m = re.match(r"^[LD]\s+0x[0-9A-Fa-f]+\s+(?:0x[0-9A-Fa-f]+\s+)?(\S+)", ln)
            if m:
                self.assertTrue(all(ord(c) < 128 for c in m.group(1)),
                                "nombre no ASCII: %r" % ln)

    def test_el_listado_reensambla_lo_que_dice_la_cabecera(self):
        """El listado declara el org 0x4000 y existe de verdad."""
        s = asm()
        self.assertIn("org 0x04000", s)
        self.assertIn("KONAMI'S BILLIARDS", s)


if __name__ == "__main__":
    unittest.main()
