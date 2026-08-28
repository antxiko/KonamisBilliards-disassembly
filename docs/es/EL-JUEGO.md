# El juego

![La mesa](../imagenes/mesa.png)

Una mesa de billar americano vista desde arriba, con seis troneras, y una bola
blanca con la que hay que meter las seis de color. Se apunta moviendo un punto
que da la vuelta a la mesa por fuera, y se tira cuando la barra de fuerza está
donde interesa.

## Apuntar es mover un punto por el borde

Eso pequeño que se ve a la derecha del paño es la mira, y no es un adorno: es
la octava entrada de la tabla de bolas (0xE170). Cuando se dispara, el juego le
resta la posición de la bola blanca y de esa diferencia salen la dirección y la
distancia del tiro.

La mira no se mueve libremente. Solo va por **un eje cada vez**, el que diga el
bit 0 de 0xE1F9, y ese bit se conmuta al llegar a los topes: la X se queda entre
0x0E y 0xE1 y la Y entre 0x36 y 0xA9. Con esas dos reglas el sitio donde puede
estar es el perímetro de un rectángulo que rodea la mesa, así que apuntar es
elegir un punto de ese marco.

## La fuerza no se elige, se caza

El indicador **SPEED** de abajo a la izquierda no responde a las teclas. La
misma rutina que lo pinta (0x5314) lo adelanta un paso cada vez que la llaman, y
cicla 1, 2, 3, 1, 2, 3… La llamada entra una vez cada 64 cuadros, algo más de
un segundo.

O sea que el tiro flojo o fuerte no se decide, se pilla al vuelo apretando el
botón en el momento justo. La velocidad de salida de la blanca es la fuerza más
uno multiplicada por el vector de dirección, y su energía, 0x20 por cada unidad.

## REST: tres tacadas por bola

A la derecha del marcador hay hasta cuatro rombos: son los intentos que le
quedan a la bola en juego (0xE053). Se entra con dos, y cada tacada que no
emboca nada gasta uno; cuando se acaban, suena el aviso y la bola se pierde.

Se empieza con **tres bolas de reserva** y se gana una al pasar de cierto
marcador, umbral que va subiendo de cinco millares en cinco millares (0xE052), y
otra cada vez que se limpia la mesa entera.

## Lo que valen las bolas

Cada bola vale **su número por cien**, y ahí entra el multiplicador: por cada
bola que se emboque seguida sin fallar, la cuenta se dobla. La tabla es 1, 2, 4,
8 y 16, y de 16 no pasa.

El cartel del recuento va enseñando una a una las bolas cobradas al final de la
tacada, con el multiplicador que le ha tocado a cada una. El rótulo **RATE** de
la izquierda enseña, mientras se apunta, el que se aplicará a la siguiente.

## El castigo de la blanca

Si la bola blanca cae en una tronera, no solo se pierde el turno: **todas las
bolas embocadas en esa tacada vuelven al paño**. La rutina que lo hace (0x5A3A)
las borra de la fila de bolas cobradas de arriba y a cada una le busca un hueco
libre en la mesa antes de devolverla, empezando por Y=0x70 X=0x90 y corriéndose
ocho píxeles cada vez que el sitio está ocupado.

Como no pasan por el recuento, esas bolas no se cobran.

## Dos jugadores, una sola fase

En el menú se elige uno o dos jugadores, y el juego guarda de cada uno sus bolas
de reserva, su umbral de bola extra y sus intentos. El rótulo 1P o 2P del que
tiene el turno parpadea, un cuadro de cada treinta y dos, leyendo de la propia
pantalla si estaba puesto o no: no hay variable de parpadeo.

Lo que **no** se reparte es el número de fase. El intercambio de 0x4526 salta
0xE051 a propósito, así que los dos jugadores comparten el mismo contador de
STAGE.

## La máquina jugando sola

Si nadie toca nada, el juego entra en su propia demostración, y no hay código
aparte para ella: mide el ángulo de la blanca a la primera bola que quede en la
mesa, mueve la mira hasta que coincide y entonces **escribe el botón de tiro en
las mismas variables donde el juego deja las teclas del jugador**. Se aprieta el
botón a sí mismo.

Durante el attract, el bit 6 de 0xE002 está a cero, y ese bit es el que permite
puntuar y el que deja pedir sonidos por la vía normal: la demostración ni suma
ni suena.
