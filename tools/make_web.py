#!/usr/bin/env python3
"""Genera la portada de la web, en los dos idiomas.

El diseno es el compartido por la serie (tools/estilo_web.py) y la pagina sale
autocontenida, con las imagenes embebidas como data URI.

La galeria de este proyecto tiene dos clases de imagen y estan separadas a
proposito:

  * las RECONSTRUIDAS -tiles.png, sprites.png, logo_konami.png- no son
    capturas: las dibuja tools/graficos.py repitiendo instruccion a instruccion
    los dos interpretes de dibujo del cartucho (0x4068 y 0x4AC6) sobre una
    memoria de video vacia. Si un rango estuviera mal etiquetado, saldria ruido.
  * las CAPTURAS -titulo.png, logotipo.png, partida.png- son pantallas reales
    de openMSX, sacadas sin tocar el teclado con tools/omsx_capturas.tcl.

El rotulo de la cabecera, logo.png, es el del propio juego: lo recorta
tools/recorta_rotulo.py de la captura del titulo. NO es el logotipo de Konami,
que va en la galeria con su nombre.

Uso: make_web.py <docs/imagenes> <salida.html> <idioma>
"""
import base64
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from estilo_web import ESTILO                                   # noqa: E402

# Las cifras de la portada salen de contar sobre el listado generado, no de
# escribirlas aqui a ojo: 8192 = 5783 + 2409, que es lo que imprime
# tools/presupuesto.py (make sanity).
CODIGO = 5343
DATOS = 11041
ESTADOS = 16                        # las dieciseis palabras de la tabla de 0x4350
RUTINAS = 333                       # las que cuenta tools/densidad.py
DENSIDAD = "39,2 %"


def mil(n, idioma):
    return f"{n:,}".replace(",", "." if idioma == "es" else ",")


TXT = {
    "es": dict(
        titulo="Konami's Billiards — desensamblado comentado",
        aviso="<b>Aquí no hay ni una captura de pantalla.</b> Todas las "
              "imágenes están <b>reconstruidas</b>: las dibuja una herramienta "
              "que repite, instrucción a instrucción, las rutinas de carga y "
              "los dos intérpretes de dibujo del cartucho sobre una memoria de "
              "vídeo vacía, y luego revela esa VRAM como la revelaría el VDP. "
              "Que la mesa salga bien es la prueba de que las rutinas se han "
              "entendido bien. El listado y las cifras salen del binario y se "
              "reproducen con <code>make</code>.",
        claim="Dieciséis kilobytes de los que el juego ocupa ocho: arranca, "
              "engancha la interrupción y se queda en un <code>jr $</code> "
              "para siempre. La partida entera cabe dentro del gancho de "
              "vídeo, repartida en dieciséis estados, y dentro hay una física "
              "de choques con trigonometría, raíces cuadradas y rebotes a "
              "cuarenta y cinco grados.",
        ficha=["Konami · <b>©KONAMI 1984</b>",
               "Cartucho <b>RC-706</b>, 16 KB",
               "MSX1 · <b>página 1</b>", "Volcado <b>38741612…</b>"],
        nav=[("#numbers", "Las cifras"), ("#findings", "Hallazgos"),
             ("#screens", "Lo que dibuja")],
        docnav=[("EMPEZAR.html", "Empezar"), ("EL-JUEGO.html", "El juego"),
                ("EL-CARTUCHO.html", "El cartucho"),
                ("EL-CODIGO.html", "El código"),
                ("LA-MUSICA.html", "La música"), ("HALLAZGOS.html", "Hallazgos"),
                ("PREGUNTAS-ABIERTAS.html", "Preguntas abiertas")],
        otro=("../", "In English"),
        h_num="El cartucho en cifras", h_find="Lo que apareció al desmontarlo",
        h_scr="Lo que el cartucho dibuja",
        cifras=[("100 %", "del binario explicado"),
                (str(ESTADOS), "estados del juego"),
                (str(RUTINAS), "rutinas identificadas"),
                (mil(CODIGO, "es"), "bytes de código"),
                (mil(DATOS, "es"), "bytes de datos"),
                ("0", "bytes sin identificar")],
        nota_scr="Debajo de cada pie está la dirección de donde sale. Todas "
                 "son reconstruidas: se rehacen con <code>make imagenes</code> "
                 "y no hace falta emulador.",
        pie_leg="Esto es trabajo de documentación y preservación: el código y "
                "los gráficos siguen siendo de sus autores y de Konami, y la "
                "imagen del cartucho no se distribuye.",
    ),
    "en": dict(
        titulo="Konami's Billiards — a commented disassembly",
        aviso="<b>There is not a single screenshot here.</b> Every picture is "
              "<b>reconstructed</b>: a tool replays the cartridge's loading "
              "routines and its two drawing interpreters, instruction by "
              "instruction, onto an empty video memory, and then develops that "
              "VRAM the way the VDP would. The table coming out right is the "
              "proof that the routines have been understood. The listing and "
              "the numbers come from the binary and are reproduced with "
              "<code>make</code>.",
        claim="Sixteen kilobytes of which the game uses eight: it boots, hooks "
              "the interrupt and settles into a <code>jr $</code> forever. The "
              "whole game fits inside the video hook, split across sixteen "
              "states, and inside it there is collision physics with "
              "trigonometry, square roots and forty-five degree bounces.",
        ficha=["Konami · <b>©KONAMI 1984</b>",
               "Cartridge <b>RC-706</b>, 16 KB",
               "MSX1 · <b>page 1</b>", "Dump <b>38741612…</b>"],
        nav=[("#numbers", "The numbers"), ("#findings", "What turned up"),
             ("#screens", "What it draws")],
        docnav=[("GETTING-STARTED.html", "Getting started"),
                ("THE-GAME.html", "The game"),
                ("THE-CARTRIDGE.html", "The cartridge"),
                ("THE-CODE.html", "The code"),
                ("THE-MUSIC.html", "The music"), ("FINDINGS.html", "Findings"),
                ("OPEN-QUESTIONS.html", "Open questions")],
        otro=("es/", "En castellano"),
        h_num="The cartridge in numbers",
        h_find="What turned up when we took it apart",
        h_scr="What the cartridge draws",
        cifras=[("100%", "of the binary explained"),
                (str(ESTADOS), "game states"),
                (str(RUTINAS), "routines identified"),
                (mil(CODIGO, "en"), "bytes of code"),
                (mil(DATOS, "en"), "bytes of data"),
                ("0", "bytes unidentified")],
        nota_scr="Under each caption is the address it comes from. They are "
                 "all reconstructed: <code>make imagenes</code> rebuilds them "
                 "and no emulator is needed.",
        pie_leg="This is documentation and preservation work: the code and "
                "artwork still belong to their authors and to Konami, and the "
                "cartridge image is not distributed.",
    ),
}

HALLAZGOS = {
    "es": [
        ("En la mesa sólo hay siete bolas, y la octava entrada no es una bola",
         "<p>La tabla de la mesa (0xE100) tiene ocho registros de dieciséis "
         "bytes, pero el bucle de la física sólo recorre siete: se para en "
         "0xE16F. El octavo, 0xE170, es <b>el punto al que se apunta</b>, y de "
         "restarle la posición de la bola blanca sale el vector del tiro "
         "(0x4CA8).</p>"
         "<p>Se dibuja como los demás —es ese punto pequeño que se ve a la "
         "derecha de la mesa— porque el refresco de sprites vuelca dos grupos "
         "de cuatro, o sea las ocho entradas.</p>"),
        ("Dos bolas que no existen, puestas ahí para reaprovechar una rutina",
         "<p>0xE18F y 0xE1EA no guardan nada. Están colocadas para que su "
         "byte +7 y su byte +9 caigan justo encima de un par de variables "
         "sueltas, que es donde una bola de verdad tiene las dos componentes "
         "de su velocidad.</p>"
         "<p>Con eso, la rutina que saca la pendiente y el ángulo de una bola "
         "(0x5430) sirve <b>sin cambiarle una línea</b> para medir el ángulo "
         "de la recta que une dos centros, en el choque, y el de la blanca a "
         "la mira, en el attract. Un puntero bien elegido en vez de una "
         "segunda rutina.</p>"),
        ("El attract juega apretando el botón por dentro",
         "<p>No hay código de juego aparte para la demostración. Lo que hace "
         "0x5EEC es medir el ángulo de la blanca a la primera bola que quede "
         "en la mesa, compararlo con el de la mira y, cuando coinciden con un "
         "grado de margen, <b>escribir 0x10 en 0xE009</b>.</p>"
         "<p>0xE008 y 0xE009 son las dos variables donde el juego deja las "
         "teclas del cuadro anterior y las de este; 0x10 es el bit del botón "
         "de tiro. La máquina no llama a la rutina de tirar: finge la "
         "pulsación y deja que el juego la lea como si fuera de una persona.</p>"),
        ("Un rebote a cuarenta y cinco grados, sin una sola multiplicación",
         "<p>Las bocas de las troneras están achaflanadas en diagonal, y el "
         "cartucho las resuelve mirando la <b>suma</b> y la <b>resta</b> de "
         "las dos coordenadas: sobre una diagonal de 45°, una de las dos vale "
         "siempre lo mismo.</p>"
         "<p>Y para rebotar en ella basta con <b>intercambiar las dos "
         "componentes de la velocidad</b> (0x5923), o intercambiarlas y "
         "cambiarles el signo si es la otra diagonal (0x593B). Reflejar en un "
         "espejo a 45° es exactamente eso, y sale gratis.</p>"),
        ("Una raíz cuadrada que redondea, y no por casualidad",
         "<p>0x5376 saca la raíz por el método de los impares: resta 1, luego "
         "0, luego 2 y 2, luego 4 y 4… y devuelve cuántas vueltas ha "
         "aguantado. Es una docena de bytes.</p>"
         "<p>Pasada por los <b>65.536</b> valores posibles de entrada, "
         "devuelve exactamente <code>round(sqrt(n))</code>: la raíz redondeada "
         "al entero más cercano, no la truncada, que es lo que suelen dar "
         "estas rutinas. Se usa para la distancia entre la bola y la mira, y "
         "medio píxel importa cuando de ahí sale la dirección del tiro.</p>"),
        ("La barra de fuerza no se ajusta: va y viene sola",
         "<p>El indicador SPEED no responde a las teclas. La misma rutina que "
         "lo pinta (0x5314) lo <b>adelanta</b> un paso cada vez que se la "
         "llama, y cicla 1, 2, 3, 1, 2, 3… La llamada entra una vez cada "
         "sesenta y cuatro cuadros.</p>"
         "<p>Así que la fuerza del tiro no se elige, se caza: hay que apretar "
         "el botón en el momento en que la barra está donde interesa. La "
         "máquina, en el attract, sólo dispara con la barra al máximo.</p>"),
        ("Este cartucho no lleva la marca oculta de Konami",
         "<p>Manuel Pazos descubrió que los cartuchos de Konami de esta época "
         "esconden al final de la ROM su número de catálogo RC-7xx y el título "
         "en katakana. Aquí no está: <b>no hay un solo <code>RC-7</code> en "
         "ASCII en los 16 KB</b>, y el final del chip son 8.269 bytes de 0xFF "
         "seguidos desde 0x5FB3.</p>"
         "<p>El RC-706 de la ficha de esta página sale del catálogo, no del "
         "binario.</p>"),
    ],
    "en": [
        ("There are only seven balls on the table, and the eighth entry is not a ball",
         "<p>The table array (0xE100) holds eight sixteen-byte records, but "
         "the physics loop only walks seven: it stops at 0xE16F. The eighth, "
         "0xE170, is <b>the point being aimed at</b>, and subtracting the cue "
         "ball's position from it is what gives the shot vector (0x4CA8).</p>"
         "<p>It is drawn like the rest — it is that small dot to the right of "
         "the table — because the sprite refresh dumps two groups of four, "
         "that is, all eight entries.</p>"),
        ("Two balls that do not exist, placed there to reuse one routine",
         "<p>0xE18F and 0xE1EA hold nothing. They are positioned so that their "
         "+7 and +9 bytes land exactly on a pair of loose variables, which is "
         "where a real ball keeps the two components of its velocity.</p>"
         "<p>With that, the routine that extracts a ball's slope and angle "
         "(0x5430) works <b>without changing a single line</b> to measure the "
         "angle of the line joining two centres, in a collision, and the angle "
         "from the cue ball to the aiming point, in the attract mode. A "
         "well-chosen pointer instead of a second routine.</p>"),
        ("The attract mode plays by pressing the button from the inside",
         "<p>There is no separate game code for the demonstration. What 0x5EEC "
         "does is measure the angle from the cue ball to the first ball still "
         "on the table, compare it with the angle to the aiming point and, "
         "when they match within one degree, <b>write 0x10 into 0xE009</b>.</p>"
         "<p>0xE008 and 0xE009 are the two variables where the game keeps last "
         "frame's keys and this frame's; 0x10 is the fire button bit. The "
         "machine does not call the shooting routine: it fakes the keypress "
         "and lets the game read it as if a person had made it.</p>"),
        ("A forty-five degree bounce without a single multiplication",
         "<p>The pocket mouths are chamfered diagonally, and the cartridge "
         "resolves them by looking at the <b>sum</b> and the <b>difference</b> "
         "of the two coordinates: along a 45° diagonal, one of the two is "
         "always constant.</p>"
         "<p>And bouncing off it is just <b>swapping the two velocity "
         "components</b> (0x5923), or swapping them and negating both for the "
         "other diagonal (0x593B). Reflecting in a 45° mirror is exactly that, "
         "and it costs nothing.</p>"),
        ("A square root that rounds, and not by accident",
         "<p>0x5376 takes the root by the method of odd numbers: subtract 1, "
         "then 0, then 2 and 2, then 4 and 4… and return how many rounds it "
         "survived. It is about a dozen bytes.</p>"
         "<p>Run over all <b>65,536</b> possible inputs, it returns exactly "
         "<code>round(sqrt(n))</code>: the root rounded to the nearest "
         "integer, not truncated, which is what these routines usually give. "
         "It is used for the distance between ball and aiming point, and half "
         "a pixel matters when the shot direction comes out of it.</p>"),
        ("The power bar cannot be set: it swings on its own",
         "<p>The SPEED indicator does not respond to the keys. The very "
         "routine that draws it (0x5314) also <b>advances</b> it one step "
         "every time it is called, cycling 1, 2, 3, 1, 2, 3… The call comes in "
         "once every sixty-four frames.</p>"
         "<p>So shot power is not chosen, it is caught: you press the button "
         "at the moment the bar sits where you want it. The machine, in "
         "attract mode, only shoots with the bar at maximum.</p>"),
        ("This cartridge does not carry Konami's hidden mark",
         "<p>Manuel Pazos found that Konami cartridges of this period hide "
         "their RC-7xx catalogue number and the title in katakana at the end "
         "of the ROM. It is not here: <b>there is not a single "
         "<code>RC-7</code> in ASCII anywhere in the 16 KB</b>, and the end of "
         "the chip is 8,269 bytes of 0xFF running from 0x5FB3.</p>"
         "<p>The RC-706 on this page's fact line comes from the catalogue, not "
         "from the binary.</p>"),
    ],
}

GALERIA = [
    ("mesa.png",
     "RECONSTRUIDA — la mesa entera, montada como la monta 0x4A39: el plano de "
     "0x4C59 es una tira de [cuántas filas][bloque comprimido] que se despliega "
     "desde la fila 7. Encima, las ocho entradas de 0x461F: la blanca, las seis "
     "de color en triángulo y, a la derecha del paño, la mira",
     "RECONSTRUCTED — the whole table, laid out the way 0x4A39 lays it: the "
     "plan at 0x4C59 is a strip of [how many rows][compressed block] unrolled "
     "from row 7 down. On top, the eight entries from 0x461F: the cue ball, the "
     "six coloured ones in a triangle and, to the right of the cloth, the "
     "aiming point"),
    ("mesa_vacia.png",
     "RECONSTRUIDA — la misma mesa sin sprites. Se ven las seis troneras y, en "
     "las cuatro esquinas, los chaflanes de 45° que el código resuelve con la "
     "suma y la resta de las coordenadas",
     "RECONSTRUCTED — the same table with no sprites. The six pockets are "
     "visible and, at the four corners, the 45° chamfers the code resolves "
     "using the sum and the difference of the coordinates"),
    ("tiles.png",
     "RECONSTRUIDA de 0x4A70 — los 59 tiles de la mesa con su color. Los "
     "patrones se copian tal cual y los colores vienen comprimidos aparte, en "
     "0x4C40, con el mismo formato que el resto de los dibujos",
     "RECONSTRUCTED from 0x4A70 — the 59 table tiles with their colour. The "
     "patterns are copied verbatim and the colours come compressed separately, "
     "at 0x4C40, in the same format as the rest of the artwork"),
    ("sprites.png",
     "RECONSTRUIDA de 0x4B30 — los dibujos de sprite de 16×16: la bola blanca, "
     "las seis numeradas y el punto de la mira. El noveno no es un dibujo: los "
     "288 bytes que se copian se pasan del final y caen sobre los colores "
     "comprimidos de la mesa",
     "RECONSTRUCTED from 0x4B30 — the 16×16 sprite drawings: the cue ball, the "
     "six numbered ones and the aiming dot. The ninth is not a drawing: the 288 "
     "bytes copied overrun the end and land on the table's compressed colours"),
    ("rotulo.png",
     "RECONSTRUIDA de 0x5788 — el BILLIARDS verde del título. Son quince "
     "columnas de dos tiles, no quince letras: la animación de 0x48B8 suelta "
     "una columna por llamada",
     "RECONSTRUCTED from 0x5788 — the green BILLIARDS from the title screen. "
     "That is fifteen two-tile columns, not fifteen letters: the animation at "
     "0x48B8 releases one column per call"),
    ("fuente.png",
     "RECONSTRUIDA de 0x4136 — los 48 glifos que el cartucho lleva propios, "
     "cargados en los tiles 0x30 a 0x5F. Como esos números coinciden con el "
     "ASCII, las listas de texto escriben las palabras tal cual",
     "RECONSTRUCTED from 0x4136 — the 48 glyphs the cartridge carries itself, "
     "loaded into tiles 0x30 to 0x5F. Since those numbers match ASCII, the text "
     "lists spell the words out literally"),
    ("logo_konami.png",
     "RECONSTRUIDA de 0x498D — los 26 tiles del logotipo KONAMI, descomprimidos "
     "y montados en las tres filas de 3, 11 y 12 tiles que reparte 0x491E al "
     "hacerlo subir por la pantalla del título",
     "RECONSTRUCTED from 0x498D — the 26 tiles of the KONAMI logo, decompressed "
     "and laid out in the rows of 3, 11 and 12 tiles that 0x491E uses as it "
     "scrolls them up the title screen"),
]


def img64(ruta):
    with open(ruta, "rb") as f:
        return "data:image/png;base64," + base64.b64encode(f.read()).decode()


def main(argv):
    if len(argv) < 4:
        print(__doc__)
        return 2
    imgdir, salida, idioma = argv[1:4]
    t = TXT[idioma]

    # El rotulo del JUEGO, no el de Konami: rotulo.png sale de la propia ROM,
    # montado como lo monta la animacion del titulo (0x48B8).
    ruta_logo = os.path.join(imgdir, "rotulo.png")
    cabecera = (f'<img src="{img64(ruta_logo)}" alt="Konami&#39;s Billiards">'
                if os.path.exists(ruta_logo) else "<h1>Konami&#39;s Billiards</h1>")

    nav = "".join(f'<a href="{h}">{x}</a>' for h, x in t["nav"])
    nav += "".join(f'<a href="{h}">{x}</a>' for h, x in t["docnav"])
    nav += (f'<a href="{t["otro"][0]}" style="margin-left:auto;color:var(--oro)">'
            f'{t["otro"][1]}</a>')

    cifras = "".join(f'<div class="cifra"><b>{v}</b><span>{e}</span></div>'
                     for v, e in t["cifras"])
    halls = "".join(f'<div class="hall"><h3>{tit}</h3>{cuerpo}</div>'
                    for tit, cuerpo in HALLAZGOS[idioma])
    imgs = ""
    faltan = []
    for fich, es, en in GALERIA:
        ruta = os.path.join(imgdir, fich)
        if not os.path.exists(ruta):
            faltan.append(fich)
            continue
        pie = es if idioma == "es" else en
        imgs += (f'<figure><img src="{img64(ruta)}" alt="{pie}">'
                 f'<figcaption>{pie}</figcaption></figure>')
    if faltan:
        print("  (faltan %d imagenes: %s)" % (len(faltan), " ".join(faltan)))

    html = f"""<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{t['titulo']}</title>
<style>{ESTILO}</style>
<header class="top">
  {cabecera}
  <p class="claim">{t['claim']}</p>
  <p class="ficha">{' · '.join(t['ficha'])}</p>
</header>
<p class="ficha" style="border:1px solid var(--oro);padding:.8em 1em;margin:1.5em 0">
{t['aviso']}</p>
<nav>{nav}</nav>
<section id="numbers">
  <h2>{t['h_num']}</h2>
  <div class="cifras">{cifras}</div>
</section>
<section id="findings"><h2>{t['h_find']}</h2>{halls}</section>
<section id="screens">
  <h2>{t['h_scr']}</h2>
  <p class="n">{t['nota_scr']}</p>
  <div class="galeria">{imgs}</div>
</section>
<footer><p>{t['pie_leg']}</p></footer>
"""
    with open(salida, "w", encoding="utf-8") as f:
        f.write(html)
    print("  %s: %d KB (%s)" % (salida, len(html) // 1024, idioma))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
