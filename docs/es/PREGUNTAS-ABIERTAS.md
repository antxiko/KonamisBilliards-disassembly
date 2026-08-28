# Preguntas abiertas

Lo que este desensamblado **no** cierra. El binario está explicado byte a byte,
pero eso no es lo mismo que haberlo comprobado todo.

## Nada de esto se ha visto corriendo

Todo lo que dicen estas páginas sale de leer el código, de simularlo o de
dibujar sus datos. **No hay ni una medida hecha en un emulador ni en una máquina
real.** Lo que sí se ha comprobado, y cómo:

- La raíz cuadrada de 0x5376, ejecutada sobre los 65.536 valores de entrada
  posibles.
- El reparto de teclas de 0x410F, simulando las rotaciones tecla a tecla.
- Las cuatro tablas trigonométricas, comparadas contra su fórmula.
- Las direcciones de pantalla que se citan, contra el operando real de la
  instrucción que las carga.
- Los dibujos: las rutinas de carga y los dos intérpretes, reejecutados sobre
  una VRAM vacía. Que la mesa salga bien es una comprobación fuerte, pero es de
  los dibujos, no del juego.

Queda por delante lo evidente: jugar y ver si el juego se comporta como aquí se
dice.

## Cuatro bytes sin dueño

En 0x4462 hay esto:

    00 80 40 C0

Ninguna instrucción los referencia, y la secuencia de bytes de su dirección no
aparece en toda la ROM, así que tampoco los alcanza ningún puntero. El código
del menú salta por encima de ellos.

Los cuatro valores tienen pinta de ser algo —cero, un cuarto, media y tres
cuartos de vuelta, o los cuatro cuadrantes— pero eso es una impresión, no una
lectura. Qué eran, no se sabe.

## Un sprite de más

El cartucho copia 288 bytes a la tabla de patrones de sprite, que dan para nueve
dibujos de 16×16, pero solo hay ocho de verdad: la bola blanca, las seis
numeradas y el punto de la mira. El noveno se sale por el final y cae sobre los
colores comprimidos de la mesa, así que es ruido.

No hay forma de saber desde el binario si la cuenta redonda es intencionada
—copiar 0x120 bytes es más cómodo que copiar 0x100— o si en algún momento hubo
un noveno dibujo.

## Una escritura repetida

En 0x5962 el mismo valor se escribe dos veces seguidas en el mismo sitio:

    ld (ix+002h),a
    ld (ix+002h),a

Tres bytes que no cambian nada. Tiene toda la pinta de un resto de una edición,
pero eso tampoco se puede afirmar leyendo el binario.

## El reloj de abandono

La cuenta atrás de 0xE202 da, echando la cuenta, algo más de veinte minutos sin
tocar una tecla antes de dar la tacada por perdida. La cuenta está clara en el
código; lo que no se ha hecho es esperar los veinte minutos para verlo.
