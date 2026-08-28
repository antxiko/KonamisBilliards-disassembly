#!/usr/bin/env python3
"""Comprobaciones sobre la web publicada en docs/.

La web de la serie se hace copiando la del proyecto anterior, y ese copiado es
justo lo que se lleva por delante el nombre del juego, la URL del repositorio o
una pagina entera del menu. Estos tests miran lo que se rompe solo.
"""
import os
import re
import unittest

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOCS = os.path.join(RAIZ, "docs")
ES = os.path.join(DOCS, "es")
ASM = os.path.join(RAIZ, "src", "billiards.asm")

REPO = "KonamisBilliards-disassembly"
CODIGO, DATOS = 5343, 11041

# Las seis parejas de documento, en los dos idiomas.
PAREJAS = [("GETTING-STARTED", "EMPEZAR"),
           ("THE-GAME", "EL-JUEGO"),
           ("THE-CARTRIDGE", "EL-CARTUCHO"),
           ("THE-CODE", "EL-CODIGO"),
           ("FINDINGS", "HALLAZGOS"),
           ("OPEN-QUESTIONS", "PREGUNTAS-ABIERTAS")]

# Los demas juegos de la serie. Ninguno pinta nada en esta web: este cartucho
# no comparte codigo con ellos y la documentacion no se apoya en los otros
# proyectos.
OTROS_JUEGOS = ["Super Cobra", "Frogger", "Time Pilot", "Pippols",
                "Athletic Land", "Monkey Academy", "Antarctic", "Pitfall",
                "Temptations", "Stardust", "Mahjong", "F-1 Spirit",
                "Ale Hop", "Colt 36", "supercobra", "frogger", "timepilot"]


def lee(p):
    with open(p, encoding="utf-8") as f:
        return f.read()


def paginas():
    """Los doce .md de la web, con su ruta."""
    for en, es in PAREJAS:
        yield os.path.join(DOCS, en + ".md")
        yield os.path.join(ES, es + ".md")


class TestWeb(unittest.TestCase):

    def test_cada_pagina_tiene_su_pareja_en_el_otro_idioma(self):
        """Un documento suelto en un idioma deja el selector sin destino."""
        for p in paginas():
            self.assertTrue(os.path.exists(p), "falta " + p)

    def test_cada_pareja_tiene_las_mismas_secciones(self):
        """Si una de las dos versiones se corrige y la otra no, se separan."""
        for en, es in PAREJAS:
            a = re.findall(r"^## ", lee(os.path.join(DOCS, en + ".md")), re.M)
            b = re.findall(r"^## ", lee(os.path.join(ES, es + ".md")), re.M)
            self.assertEqual(len(a), len(b),
                             "%s tiene %d secciones y %s tiene %d"
                             % (en, len(a), es, len(b)))

    def test_las_paginas_no_hablan_de_otro_juego(self):
        """La documentacion no se apoya en los proyectos anteriores."""
        for p in paginas():
            t = lee(p)
            for j in OTROS_JUEGOS:
                self.assertNotIn(j, t, "%s nombra a %s" % (os.path.basename(p), j))

    def test_las_herramientas_de_la_web_no_hablan_de_otro_juego(self):
        """El pie, el titulo de pestana y los textos de la portada se copian
        del proyecto anterior y se quedan con su nombre."""
        for h in ("md2html.py", "make_web.py", "graficos.py"):
            t = lee(os.path.join(RAIZ, "tools", h))
            for j in OTROS_JUEGOS:
                self.assertNotIn(j, t, "tools/%s nombra a %s" % (h, j))

    def test_los_enlaces_al_repositorio_son_a_ESTE_repositorio(self):
        """La constante REPO de md2html.py viaja al copiar la herramienta."""
        t = lee(os.path.join(RAIZ, "tools", "md2html.py"))
        urls = re.findall(r"https://github\.com/antxiko/([A-Za-z0-9._-]+)", t)
        self.assertTrue(urls, "md2html.py no declara ninguna URL de repositorio")
        for u in urls:
            self.assertEqual(u, REPO, "md2html.py apunta a " + u)

    def test_las_dos_portadas_publican_las_cifras_del_arbol(self):
        """Las cifras de la portada viven en make_web.py, no en el markdown:
        al corregir una hay que tocar tambien ahi."""
        t = lee(os.path.join(RAIZ, "tools", "make_web.py"))
        self.assertIn("CODIGO = %d" % CODIGO, t)
        self.assertIn("DATOS = %d" % DATOS, t)
        self.assertEqual(CODIGO + DATOS, 0x4000, "las cifras no suman los 16 KB")

    def test_las_paginas_no_inventan_direcciones(self):
        """Toda direccion 0xNNNN citada en la web tiene que existir en el
        listado, o como instruccion o como dato."""
        t = lee(ASM)
        vistas = set(int(d, 16) for d in re.findall(r";([0-9a-f]{4})", t))
        vistas |= set(int(d, 16) for d in re.findall(r"; ([0-9a-f]{4}) ", t))
        # Y todo lo que cae dentro de un rango de datos declarado: un volcado
        # solo lleva marca de direccion una vez por fila, no byte a byte.
        notes = lee(os.path.join(RAIZ, "src", "billiards.notes"))
        for a, b in re.findall(r"^D 0x([0-9A-F]{4}) 0x([0-9A-F]{4})", notes, re.M):
            vistas |= set(range(int(a, 16), min(int(b, 16), 0x8000)))
        for p in paginas():
            for d in re.findall(r"0x([0-9A-F]{4})\b", lee(p)):
                n = int(d, 16)
                if not (0x4000 <= n < 0x8000):     # RAM y VRAM no van aqui
                    continue
                self.assertTrue(n in vistas,
                                "%s cita 0x%04X y no esta en el listado"
                                % (os.path.basename(p), n))

    def test_las_imagenes_citadas_existen(self):
        """Un enlace de imagen roto no lo caza el navegador: sale un hueco."""
        for p in paginas():
            for img in re.findall(r"!\[[^\]]*\]\(([^)]+)\)", lee(p)):
                ruta = os.path.normpath(os.path.join(os.path.dirname(p), img))
                self.assertTrue(os.path.exists(ruta),
                                "%s enlaza a %s y no existe"
                                % (os.path.basename(p), img))

    def test_el_menu_no_apunta_a_paginas_que_no_existen(self):
        """En cuanto el menu lista una pagina de mas, TODAS las paginas del
        sitio salen con un enlace roto."""
        t = lee(os.path.join(RAIZ, "tools", "md2html.py"))
        for nav, carpeta in (("NAV_EN", DOCS), ("NAV_ES", ES)):
            i = t.index(nav)
            bloque = t[i:t.index("]", i)]
            for h in re.findall(r'\("([A-Z-]+\.html)"', bloque):
                self.assertTrue(os.path.exists(os.path.join(carpeta, h[:-5] + ".md")),
                                "%s lista %s y no hay markdown" % (nav, h))

    def test_los_readme_publican_las_mismas_cifras(self):
        """Los README se quedan con la cifra vieja cuando se corrige la web."""
        for r in ("README.md", "README.es.md"):
            t = lee(os.path.join(RAIZ, r))
            self.assertRegex(t, r"5[.,]343", r + " no publica los bytes de codigo")
            self.assertRegex(t, r"11[.,]041", r + " no publica los bytes de datos")
            self.assertIn(REPO, t, r + " no enlaza a este repositorio")


if __name__ == "__main__":
    unittest.main()
