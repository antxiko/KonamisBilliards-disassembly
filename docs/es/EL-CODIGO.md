# El código

5.343 bytes de código y 11.041 de datos. El hilo principal está parado en un
`jr $` desde el arranque, así que todo lo que sigue pasa dentro de la
interrupción del VDP, cincuenta veces por segundo.

## La interrupción

0x4034 hace cuatro cosas en este orden: reconoce el VDP —que es lo que baja la
señal—, da un paso al reproductor de sonido, mira el cerrojo de 0xE005 y, si
está libre, lee los mandos y corre un paso del juego.

El cerrojo importa. Antes de meterse en el paso del juego, la rutina hace `ei`:
**abre las interrupciones mientras trabaja**. Si el paso se pasa de cuadro —y la
física de siete bolas se pasa— la interrupción siguiente entra, ve el cerrojo
echado y se marcha sin hacer nada más que atender al sonido. La música no se
entrecorta aunque el juego vaya justo.

## Dieciséis estados y una tabla que no tiene puntero

El paso del juego (0x4337) incrementa el contador de cuadros y despacha por
0xE000, el estado, que va de 0 a 15.

El despachador (0x40A0) no recibe la dirección de la tabla. Hace `pop hl` para
quedarse con **su propia dirección de retorno** y la usa de base, así que la
tabla de dieciséis palabras va pegada justo detrás del `call` que lo invoca, y
no se vuelve nunca a él. Termina en `jp (hl)`.

Hay tres tablas así en el cartucho: la de los dieciséis estados detrás del
`call` de 0x434D, la de las tres fases del recuento detrás del de 0x5ACA y la de
los cuatro pasos de la demostración detrás del de 0x5EB6.

Los estados hacen lo que se espera: el 0 al 7 son la pantalla del título y el
menú, el 8 confirma la selección, el 9 saca bola, el 10 monta la mesa, el 11 es
la tacada, el 12 la decide, el 13 cambia de jugador, el 14 espera tras el GAME
OVER y el 15 celebra la mesa limpia. El estado 3 es un paso muerto: su entrada en
la tabla apunta a la instrucción que solo incrementa el estado.

## El registro de una bola

La mesa son ocho registros de dieciséis bytes desde 0xE100:

| byte | qué es |
|---|---|
| +0 | 0xFF mientras la bola sigue en el paño |
| +1 | la energía que le queda; a cero, está parada |
| +2 | el ángulo con el que va |
| +3 y +4 | la Y en 16 bits, con la parte entera en el +4 |
| +5 y +6 | la X en 16 bits, con la parte entera en el +6 |
| +7 y +8 | la velocidad Y, con signo |
| +9 y +10 | la velocidad X |
| +11 y +12 | número de patrón de sprite y color |
| +13 y +14 | el frenado, repartido por componentes |
| +15 | con qué bola chocó la última vez |

La posición está en punto fijo de 8.8, y el byte entero cae justo donde el
volcado de sprites lo va a leer: mover una bola es sumar dos palabras de 16 bits
a otras dos, y el sprite se entera solo.

Los cuatro bytes que el VDP necesita —el +4, el +6, el +11 y el +12— los vuelca
0x466D de un tirón por el puerto de datos, aprovechando que el VDP
autoincrementa. Y el orden de los dos grupos de cuatro bolas se alterna con el
bit 0 del contador de cuadros, que es el truco de siempre contra el límite de
sprites por línea del TMS9918.

## La física, tres rutinas

**Mover** (0x4E6B) suma la velocidad a la posición y mira si se ha salido: la
mesa va de X=0x14 a X=0xD8 y de Y=0x3E a Y=0xA1. Si se ha salido por donde hay
banda, la refleja —posición menos el doble de lo que se pasó— y le da la vuelta a
esa componente de la velocidad. Si se ha salido por donde hay tronera, va a la
rutina que la emboca.

**Chocar** (0x4F25) recorre las otras seis bolas con una criba barata: si las dos
coordenadas se diferencian en menos de doce píxeles, hay contacto posible.
Entonces 0x4F63 mide la distancia de verdad, con los dos cuadrados sumados
comparados contra 0x9000, que a esa escala son los mismos doce píxeles.

**Frenar** (0x53DD) entra una vez de cada ocho cuadros: quita 3 a la energía y
le suma a cada componente de la velocidad el frenado del +13 y el +14, siempre
con el signo contrario al del movimiento. Como esos dos bytes son las
componentes del vector unidad escaladas a 24/256, la bola frena en su propia
línea y no se tuerce al pararse.

## Cómo se reparte un choque

Si las dos bolas ruedan, el cartucho **se intercambia las velocidades** y ya
está (0x5192): el choque frontal entre masas iguales, resuelto sin una sola
multiplicación.

Si una estaba parada, entonces sí hay cuenta. Se mide el ángulo de la recta que
une los dos centros, se compara con el ángulo con el que llegaba la bola y esa
diferencia —saturada a 0x3C, casi un ángulo recto— entra en la tabla de cosenos:
la parte del movimiento que cae sobre la línea de centros se cede, la
perpendicular se queda. La que golpea sale por la perpendicular, y para eso las
dos componentes se cruzan al escribirlas, que es girar el vector noventa grados
sin tocarlo.

## Direcciones sin senos ni cosenos

Una dirección no se guarda como un ángulo, sino como una **pendiente dentro de
un octante** más dos bits de espejo. La rutina de 0x5430 coge las dos
componentes de la velocidad, se queda con los valores absolutos, apunta en
0xE1A2 hacia dónde iba cada una, divide las dos entre 32 y compara: la mayor es
el divisor y la menor el dividendo, así que el cociente cae siempre entre 0 y
255 y basta con tablas de 256 entradas.

Hay cuatro, todas comprobadas contra su fórmula con error máximo de 1:

| tabla | qué guarda |
|---|---|
| 0x539C | 65 valores de 255·cos, para el reparto del choque |
| 0x54E6 | 256 valores de 255·sin(atan(p)) |
| 0x55E6 | 256 valores de 255·cos(atan(p)) |
| 0x56E6 | 64 valores de atan, en 1/256 de vuelta |

La de 0x539C se lee dos veces, con el índice y con su complemento a 0x40, y de
ahí salen el seno y el coseno con una sola tabla. Y al montar el ángulo final,
los dos bits de espejo se combinan con la **paridad**: un `and a` sobre 0xE1A2 y
un `jp pe`, porque negar el ángulo hace falta cuando está reflejado uno solo de
los dos ejes.

## Una raíz cuadrada de doce bytes

0x5376 saca la raíz de HL restando impares: 1, luego 0, luego 2 y 2, luego 4 y 4…
y devuelve cuántas vueltas aguantó. Pasada por los 65.536 valores posibles,
devuelve exactamente `round(sqrt(n))`, la raíz redondeada al entero más cercano
y no la truncada.

Se usa para la distancia entre la bola blanca y la mira, que es lo que divide a
las dos componentes del tiro para dejarlas en un vector unidad. Medio píxel ahí
se nota en la dirección.

## El reproductor de sonido

Tres canales de nueve bytes desde 0xE010, cada uno con su contador, su puntero a
la partitura y el número de sonido que está tocando, que hace además de
prioridad: un sonido nuevo solo entra si su número es mayor o igual que el que
suena.

Lo que se pide no es un canal sino un **sonido**, y según su número se arrancan
uno, dos o tres canales a la vez con punteros consecutivos de la tabla de 0x5D1C.
Por debajo de 0x87 es un efecto de un canal; de 0x8A en adelante, música de tres.

Las notas llevan la duración en el nibble alto y el semitono en el bajo, y el
semitono 12 es un silencio. El divisor de frecuencia sale de la tabla de doce
que hay en 0x5D08 y se dobla tantas veces como octavas haya que bajar. El
volumen decae solo, por programa, comparando dos contadores.

Y un detalle de los que gustan: el registro de volumen del canal sale de rotar C
—que vale 1, 3 o 5— y sumarle 0x88. Da 8, 9 y 10, que son exactamente los tres
registros de volumen del PSG.

## Cosas que están ahí y no hacen nada

- 0x5962 escribe `(ix+002h)` **dos veces seguidas con el mismo valor**. Tres
  bytes que no cambian nada.
- En 0x4462 hay cuatro bytes (00 80 40 C0) que ninguna instrucción referencia, y
  la secuencia de su dirección no existe en toda la ROM. El código del menú salta
  por encima de ellos. Parecen una tabla abandonada.
- El puntero número 0 de la tabla de sonidos no existe: sus dos bytes son las
  duraciones 44 y 84 de la tabla de arriba, empalmada con esta. Nadie pide el
  sonido 0.

## Y dos que sí hacen, y son las mejores

`push hl` seguido de `pop hl` aparece varias veces en las rutinas que escriben
sprites y carteles (0x59E8, 0x5A01, 0x5B66). No mueven nada: son veintiún ciclos
de reloj de espera para que al VDP le dé tiempo entre dos escrituras
consecutivas.

Y en 0x5488 hay un `ld a,r`. El registro R es el contador de refresco de la
memoria dinámica, que va cambiando solo, así que sirve de número al azar sin
gastar nada. El cartucho se queda con su bit de abajo y con él le da la vuelta
al bit 0 de la pendiente recién calculada: cada dirección sale con una unidad de
ruido encima.
