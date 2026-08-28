# Konami's Billiards (MSX, Konami 1984) — desensamblado comentado

Desensamblado completo y comentado de **Konami's Billiards** para MSX: el
cartucho **RC-706** de Konami, 16 KB en la página 1.

**El 100 % del binario está explicado**, reensambla en el original byte a byte,
y aquí no hay ninguna suposición disfrazada de hecho.

📖 **[Leer la web](https://antxiko.github.io/KonamisBilliards-disassembly/es/)** ·
🇬🇧 **[In English](README.md)**

## Lo que hay dentro

| | bytes | |
|---|---|---|
| código trazado | 5.343 | 32,61 % |
| datos identificados | 11.041 | 67,39 % |
| **sin explicar** | **0** | **0,00 %** |

**332 etiquetas** (ni una sin bautizar), **1.151 comentarios anclados** —el
39,3 % de las instrucciones llevan comentario, y **ninguna rutina baja del
10 %**— y **55 rangos de datos**, cada uno con su nombre, su explicación y, donde
son tablas, la anchura de sus filas. **15 tests** lo vigilan todo.

Los 16 KB del chip son en realidad 8.115 bytes de juego: de 0x5FB3 en adelante
son 8.269 bytes de 0xFF que ninguna instrucción lee.

## Algo de lo que apareció

- **En la mesa solo hay siete bolas.** La tabla tiene ocho registros, pero el
  octavo no es una bola: es el punto al que se apunta, y de restarle la posición
  de la blanca sale el vector del tiro.
- **Dos bolas que no existen.** 0xE18F y 0xE1EA no guardan nada: están colocadas
  para que su byte +7 y su +9 caigan sobre un par de variables sueltas, y así la
  rutina que saca el ángulo de una bola sirve sin tocarla para medir el ángulo de
  la recta que une dos centros.
- **El attract juega apretando el botón por dentro**, escribiendo 0x10 en las
  mismas variables donde el juego deja las teclas del jugador.
- **Un rebote a 45° sin una sola multiplicación**: los chaflanes de las troneras
  se resuelven con la suma y la resta de las coordenadas, y rebotar en ellos es
  intercambiar las dos componentes de la velocidad.
- **Una raíz cuadrada de doce bytes** que, pasada por los 65.536 valores
  posibles, devuelve exactamente `round(sqrt(n))`.
- **La barra de fuerza no se ajusta**: cicla sola 1, 2, 3 y hay que disparar en el
  momento.
- **Este cartucho no lleva la marca oculta de Konami** que descubrió Manuel
  Pazos: no hay un solo `RC-7` en ASCII en los 16 KB.

## Cómo se comprueba

    make verify

Reensambla el listado con pasmo y lo compara con la ROM, byte a byte.

    make            # el ciclo entero
    make sanity     # lo que el reensamblado NO cubre
    make imagenes   # rehace los dibujos desde la ROM, sin emulador

La ROM **no** se distribuye aquí. Va en la raíz como `billiards.rom`, 16384
bytes, y el `Makefile` comprueba su sha256 antes de hacer nada.

## Las imágenes no son capturas

No hay ni una foto de pantalla en este repositorio. `tools/graficos.py` repite,
instrucción a instrucción, las rutinas de carga del cartucho y sus dos
intérpretes de dibujo sobre una memoria de vídeo vacía, y luego revela esa VRAM
como la revelaría el VDP.

Que la mesa salga bien es la comprobación más honesta que hay de que las rutinas
se han entendido: si la lectura estuviera mal, saldría ruido.

## Lo que no está cerrado

Nada de esto se ha visto corriendo en un emulador ni en una máquina real. Lo que
sí se ha comprobado —la raíz cuadrada sobre sus 65.536 entradas, el reparto de
teclas simulado, las cuatro tablas trigonométricas contra su fórmula— está dicho
en [la página de preguntas abiertas](docs/es/PREGUNTAS-ABIERTAS.md), junto con lo
que queda por saber.

## Licencia y atribución

El juego es de Konami; el análisis, los comentarios y las herramientas se
publican con la licencia de [`LICENSE`](LICENSE). Ver
[`AVISO-LEGAL.md`](AVISO-LEGAL.md).
