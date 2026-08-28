; ==========================================================================
; KONAMI'S BILLIARDS - Konami - MSX1 - cartucho RC-706 de 16 KB en la pagina 1
; ==========================================================================
; Generado por tools/mkasm.py a partir del trazado de flujo real.
; Los comentarios provienen de tools/../src/*.notes y estan anclados a
; direccion, de modo que sobreviven a un retrazado.
; ==========================================================================

	org 0x04000


; ----------------------------------------------------------------------
; DATOS cabecera: Los dieciseis bytes que lee la BIOS al arrancar la maquina:
;   AB, INIT=0x405F, y los otros tres punteros a cero. Este cartucho no
;   declara STATEMENT, ni DEVICE, ni TEXT.
;   0x4000..0x4010  (16 bytes)
DATA_cabecera:
	defb 041h,042h,05fh,040h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 4000  AB_@............

; ======================================================================
; CODIGO 0x4010..0x4136  (294 bytes)
; ======================================================================


escribe_en_vram:		; WRTVRM de la BIOS con los registros cruzados: DE es la direccion y A el dato
	ex de,hl			;4010   ; DE trae la direccion de VRAM y A el dato; WRTVRM la quiere en HL
	call 0004dh		;4011   ; BIOS WRTVRM - Writes data in VRAM | la BIOS escribe el byte
	ex de,hl			;4014   ; devuelve DE como estaba: quien llama sigue usandolo de puntero
	ret			;4015
lee_de_vram:		; RDVRM de la BIOS con DE como direccion
	ex de,hl			;4016   ; mismo cruce para leer
	call 0004ah		;4017   ; BIOS RDVRM - Reads the content of VRAM
	ex de,hl			;401a
	ret			;401b
abre_la_vram_para_escribir:		; SETWRT con DE como direccion, y deja en C' el puerto de datos del VDP (0x0007) para los `out (c)` de los bucles de copia
	ex de,hl			;401c   ; SETWRT deja el VDP apuntando y en modo escritura
	call 00053h		;401d   ; BIOS SETWRT - Enables VDP to write
	ex de,hl			;4020
	push af			;4021   ; el dato de A no se pierde por lo que viene
	ld a,(00007h)		;4022   ; la BIOS guarda en 0x0007 el puerto de datos del VDP de esta maquina
	exx			;4025   ; al juego alterno: C' es el puerto que usan los `out (c),r` de las copias
	ld c,a			;4026
	exx			;4027
	pop af			;4028   ; y A vuelve intacto
	ret			;4029
suma_a_a_hl:		; HL += A sin tocar mas registros
	add a,l			;402a   ; el acarreo del byte bajo sube a H
	ld l,a			;402b
	ret nc			;402c   ; sin acarreo no hay nada que arrastrar
	inc h			;402d
	ret			;402e
suma_a_a_de:		; DE += A
	add a,e			;402f
	ld e,a			;4030
	ret nc			;4031
	inc d			;4032
	ret			;4033
interrupcion:		; El gancho H.KEYI apunta aqui: lee el estado del VDP, toca el sonido (0x5C0E), y si no esta ya dentro (0xE005) lee los mandos y corre un paso del juego (0x4337) con las interrupciones abiertas
	di			;4034   ; nada de reentrar mientras se toca el VDP
	call 0013eh		;4035   ; BIOS RDVDP - Reads VDP status register | leer el registro de estado es lo que baja la linea de interrupcion del VDP
	call toca_el_sonido		;4038   ; el sonido va primero: un paso del driver por cuadro, pase lo que pase
	ld hl,0e005h		;403b   ; 0xE005 es el cerrojo del paso de juego
	bit 0,(hl)		;403e   ; ya hay una pasada dentro?
	jr nz,L_405A		;4040   ; pues este cuadro se pierde: solo reconoce la interrupcion y sale
	ld (hl),001h		;4042   ; echa el cerrojo
	ei			;4044   ; y ABRE las interrupciones: el paso de juego puede pasarse de cuadro y aqui se le deja
	ld a,(0e002h)		;4045   ; bit 6 de 0xE002: si esta puesto, cada jugador lee SU puerto de joystick
	and 040h		;4048
	push af			;404a
	call nz,L_40E8		;404b   ; partida de dos: el puerto sale del jugador que toca
	pop af			;404e
	call z,lee_los_mandos		;404f   ; partida de uno: siempre el puerto 1
	call avanza_el_juego		;4052   ; y el paso del juego, ya con la maquina abierta
	di			;4055   ; cierra para soltar el cerrojo sin que le pisen
	xor a			;4056
	ld (0e005h),a		;4057   ; fuera el cerrojo
L_405A:
	call 0013eh		;405a   ; BIOS RDVDP - Reads VDP status register | segunda lectura del estado del VDP: se traga la interrupcion que haya entrado durante el paso
	ei			;405d
	ret			;405e
init:		; El INIT que declara la cabecera: instala la interrupcion en H.KEYI, borra la RAM 0xE000-0xEFFF, monta la pantalla y el titulo, y se queda en el bucle de 0x409E: el juego entero corre en la interrupcion
	di			;405f
	im 1		;4060
	ld a,0c3h		;4062   ; 0xC3 es el `jp` que se monta a mano en el gancho
	ld (0fd9ah),a		;4064   ; H.KEYI (0xFD9A), el gancho que la BIOS llama en cada interrupcion
	ld hl,interrupcion		;4067
	ld (0fd9bh),hl		;406a   ; y detras el destino: a partir de aqui el cartucho manda
	ld sp,0e400h		;406d   ; la pila, justo debajo de la RAM de trabajo
	ld hl,0e000h		;4070   ; borra los 4 KB de 0xE000 a 0xEFFF con el LDIR solapado de siempre
	ld de,0e001h		;4073
	ld bc,00fffh		;4076
	ld (hl),000h		;4079
	ldir		;407b
	ld a,001h		;407d   ; el cerrojo puesto ANTES de abrir: la carga de tiles no debe verse interrumpida por un paso de juego
	ld (0e005h),a		;407f
	call monta_la_pantalla		;4082   ; VDP, PSG callado y VRAM a cero
	call carga_los_tiles_del_logo		;4085
	call carga_los_tiles_de_la_mesa		;4088
	call carga_la_fuente		;408b
	call carga_los_tiles_del_rotulo_grande		;408e
	xor a			;4091
	ld (0e005h),a		;4092   ; ya esta todo cargado: se suelta el cerrojo
	ld a,090h		;4095   ; sonido 0x90, el arranque
	call L_5BCA		;4097
	call 0013eh		;409a   ; BIOS RDVDP - Reads VDP status register | reconoce el VDP antes de abrir, para no entrar con una pendiente
	ei			;409d
L_409E:
	jr L_409E		;409e   ; y aqui se queda para siempre: LO DEMAS PASA DENTRO DE LA INTERRUPCION
despachador:		; Coge la direccion de retorno con `pop hl`, le suma el doble del indice A y salta a la palabra que hay alli: la tabla va pegada detras del `call`
	add a,a			;40a0   ; A es el indice; se dobla porque la tabla va de dos en dos
	pop hl			;40a1   ; la direccion de retorno ES la base de la tabla
	call suma_a_a_hl		;40a2   ; y el indice se le suma
	ld e,(hl)			;40a5   ; saca la palabra
	inc hl			;40a6
	ld d,(hl)			;40a7
	ex de,hl			;40a8
	jp (hl)			;40a9   ; salta sin volver: el `ret` de la rutina destino ya vuelve al que llamo al despachador
lee_las_teclas_del_menu:		; Trabaja con FLANCOS: compara el estado de teclas de este cuadro (0xE009) con el del anterior (0xE008) y solo atiende a las que se acaban de pulsar. Fuera del estado 5 (el menu), cualquiera de las seis teclas de jugar rearma la pantalla del titulo (0x43A6). Dentro del menu, cualquier DIRECCION alterna la opcion (0xE006 solo vale 0 o 1, no hay arriba ni abajo) y cualquiera de los dos botones fija 0xE002 (0x40 un jugador, 0x60 dos) y pasa al estado 8
	ld hl,0e008h		;40aa   ; 0xE008 el estado de teclas del cuadro anterior, 0xE009 el de este
	ld a,(hl)			;40ad
	inc l			;40ae
	xor (hl)			;40af   ; los bits que han cambiado
	and (hl)			;40b0   ; ...y que ahora estan a uno: el flanco de pulsacion, para que una tecla mantenida no cuente dos veces
	ld hl,0e006h		;40b1   ; de paso deja HL en 0xE006, la opcion elegida del menu
	and 03fh		;40b4   ; las seis teclas de jugar: cuatro direcciones y dos botones
	ret z			;40b6   ; ninguna nueva, no hay nada que hacer
	ld c,a			;40b7
	xor a			;40b8
	ld (0e004h),a		;40b9   ; cualquier tecla corta la espera en curso
	ld a,(0e000h)		;40bc
	cp 005h		;40bf   ; el estado 5 es el menu
	jp nz,rearma_el_titulo		;40c1   ; fuera del menu -attract, logo, lo que sea- cualquier tecla vuelve al titulo
	ld a,c			;40c4   ; bits 4 y 5: los dos botones
	and 030h		;40c5
	jr z,L_40DE		;40c7   ; ninguno de los dos, entonces mueve el cursor
	ld a,(hl)			;40c9   ; la opcion que estaba marcada
	and a			;40ca
	ld a,040h		;40cb   ; 0x40 = un jugador (bit 6, el que reparte los puertos de joystick)
	jr z,L_40D1		;40cd
	ld a,060h		;40cf   ; 0x60 = dos jugadores: el mismo bit 6 mas el bit 5, que es "hay segundo jugador"
L_40D1:
	ld (0e002h),a		;40d1
	ld a,008h		;40d4   ; estado 8: confirmar la seleccion
	ld (0e000h),a		;40d6
	xor a			;40d9
	ld (0e201h),a		;40da   ; y su submodo a cero
	ret			;40dd
L_40DE:
	ld a,(hl)			;40de   ; la opcion no se mueve arriba y abajo: CUALQUIER direccion la alterna
	inc a			;40df
	and 001h		;40e0   ; solo hay dos, asi que basta el bit 0
	ld (hl),a			;40e2
	ret			;40e3
lee_los_mandos:		; Lee el joystick por los registros 15 y 14 del PSG Y el teclado por SNSMAT, y los junta con un `or` (0x4106): las dos cosas valen siempre a la vez. Lo que el bit 6 de 0xE002 decide es otra cosa: de que puerto de joystick se lee, siempre el 1 (entrada 0x40E4) o el del jugador con el turno (entrada 0x40E8). El resultado, seis bits -arriba, abajo, izquierda, derecha y dos botones-, va a 0xE009, y lo que habia pasa a 0xE008
	ld e,08fh		;40e4   ; 0x8F: bit 7 = el puerto B del PSG es de entrada, bit 6 = 0 = joystick del puerto 1
	jr L_40F2		;40e6   ; y a la lectura, sin mirar de quien es el turno
L_40E8:
	ld e,08fh		;40e8   ; la otra entrada, la de las partidas de dos
	ld a,(0e002h)		;40ea
	add a,a			;40ed   ; el bit 7 de 0xE002 es el jugador que tiene el turno
	jr nc,L_40F2		;40ee
	set 6,e		;40f0   ; el jugador 2 juega con el joystick del puerto 2 (bit 6 del registro 15)
L_40F2:
	ld a,00fh		;40f2   ; registro 15 del PSG: la seleccion de puerto
	call 00093h		;40f4   ; BIOS WRTPSG - Writes data to PSG-register
	ld a,00eh		;40f7   ; y el 14, donde se leen los pines
	di			;40f9   ; la lectura del PSG no puede partirse
	call 00096h		;40fa   ; BIOS RDPSG - Reads value from PSG-register
	ei			;40fd
	cpl			;40fe   ; los pines estan a cero cuando se pulsan
	and 03fh		;40ff   ; se quedan las seis: arriba, abajo, izquierda, derecha y los dos botones
	push af			;4101   ; guarda el joystick mientras lee el teclado
	call L_410F		;4102   ; el teclado da los mismos seis bits
	pop bc			;4105
	or b			;4106   ; SE SUMAN LOS DOS: nunca se elige entre joystick y teclado, valen los dos a la vez
	ld hl,0e009h		;4107
	ld c,(hl)			;410a   ; lo de este cuadro pasa a ser lo del anterior
	ld (hl),a			;410b   ; 0xE009 = ahora
	dec hl			;410c
	ld (hl),c			;410d   ; 0xE008 = antes; de esos dos sale el flanco de 0x40AA
	ret			;410e
L_410F:
	ld a,007h		;410f   ; fila 7 de la matriz: RETURN, SELECT, BS, STOP, TAB, ESC, F5, F4
	call 00141h		;4111   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	cpl			;4114   ; la matriz tambien da cero al pulsar
	rrca			;4115   ; una rotacion: el bit 6 cae en el 5
	and 020h		;4116   ; y el bit 5 es el boton B del joystick, asi que SELECT hace de boton B
	ld e,a			;4118
	ld a,008h		;4119   ; fila 8: derecha, abajo, arriba, izquierda, DEL, INS, HOME, ESPACIO
	push de			;411b   ; SNSMAT se lleva por delante DE
	call 00141h		;411c   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	pop de			;411f
	cpl			;4120
	rrca			;4121   ; dos rotaciones
	rrca			;4122
	ld b,a			;4123
	and 004h		;4124   ; el bit 4 (izquierda) cae en el 2, que es el de izquierda del joystick
	or e			;4126
	ld c,a			;4127
	ld a,b			;4128
	rrca			;4129   ; dos mas, cuatro en total
	rrca			;412a
	ld b,a			;412b
	and 018h		;412c   ; el bit 7 (derecha) cae en el 3, y el bit 0 (ESPACIO) en el 4: el ESPACIO es el boton de tiro
	or c			;412e
	ld c,a			;412f
	ld a,b			;4130
	rrca			;4131   ; una quinta rotacion
	and 003h		;4132   ; los bits 5 y 6 (arriba y abajo) caen en el 0 y el 1
	or c			;4134   ; y ya estan las seis teclas colocadas en el mismo formato que el joystick
	ret			;4135

; ----------------------------------------------------------------------
; DATOS fuente: Los 48 glifos de 8 bytes que 0x4743 copia a VRAM 0x2180 en los
;   tres tercios: son los tiles 0x30-0x5F, es decir, los caracteres ASCII
;   "0"-"9", los simbolos y las mayusculas "A"-"Z", y por eso las listas de
;   texto escriben ASCII tal cual. En el hueco de la barra, el corchete y los
;   guiones (0x5C-0x5F) hay dibujos propios: los dos tiles del cursor del
;   menu, un rombo y una bola rellena. Sus colores: blanco sobre transparente
;   (el relleno 0xF0 que la misma rutina mete en 0x0180-0x02FF).
;   0x4136..0x42b6  (384 bytes)
DATA_fuente:
	defb 000h,01ch,022h,063h,063h,063h,022h,01ch	; 4136  .."ccc".
	defb 000h,018h,038h,018h,018h,018h,018h,07eh	; 413e  ..8....~
	defb 000h,03eh,063h,003h,00eh,03ch,070h,07fh	; 4146  .>c..<p.
	defb 000h,03eh,063h,003h,00eh,003h,063h,03eh	; 414e  .>c...c>
	defb 000h,00eh,01eh,036h,066h,066h,07fh,006h	; 4156  ...6ff..
	defb 000h,07fh,060h,07eh,063h,003h,063h,03eh	; 415e  ..`~c.c>
	defb 000h,03eh,063h,060h,07eh,063h,063h,03eh	; 4166  .>c`~cc>
	defb 000h,07fh,063h,006h,00ch,018h,018h,018h	; 416e  ..c.....
	defb 000h,03eh,063h,063h,03eh,063h,063h,03eh	; 4176  .>cc>cc>
	defb 000h,03eh,063h,063h,03fh,003h,063h,03eh	; 417e  .>cc?.c>
	defb 03ch,042h,099h,0a1h,0a1h,099h,042h,03ch	; 4186  <B....B<
	defb 000h,003h,003h,003h,003h,003h,003h,003h	; 418e  ........
	defb 01ch,038h,070h,0e1h,0cdh,0cdh,0fdh,079h	; 4196  .8p....y
	defb 000h,000h,000h,0eeh,06bh,06bh,06bh,0ebh	; 419e  ....kkk.
	defb 000h,000h,000h,073h,01ah,07ah,05ah,07ah	; 41a6  ...s.zZz
	defb 000h,003h,000h,0f3h,05bh,05bh,05bh,05bh	; 41ae  ....[[[[
	defb 000h,000h,000h,000h,07eh,000h,000h,000h	; 41b6  ....~...
	defb 000h,01ch,036h,063h,063h,07fh,063h,063h	; 41be  ..6cc.cc
	defb 000h,07eh,063h,063h,07eh,063h,063h,07eh	; 41c6  .~cc~cc~
	defb 000h,03eh,063h,060h,060h,060h,063h,03eh	; 41ce  .>c```c>
	defb 000h,07ch,066h,063h,063h,063h,066h,07ch	; 41d6  .|fcccf|
	defb 000h,07fh,060h,060h,07eh,060h,060h,07fh	; 41de  ..``~``.
	defb 000h,07fh,060h,060h,07eh,060h,060h,060h	; 41e6  ..``~```
	defb 000h,03eh,063h,060h,067h,063h,063h,03fh	; 41ee  .>c`gcc?
	defb 000h,063h,063h,063h,07fh,063h,063h,063h	; 41f6  .ccc.ccc
	defb 000h,03ch,018h,018h,018h,018h,018h,03ch	; 41fe  .<.....<
	defb 000h,01fh,006h,006h,006h,006h,066h,03ch	; 4206  ......f<
	defb 000h,063h,066h,06ch,078h,07ch,06eh,067h	; 420e  .cflx|ng
	defb 000h,060h,060h,060h,060h,060h,060h,07fh	; 4216  .``````.
	defb 000h,063h,077h,07fh,07fh,06bh,063h,063h	; 421e  .cw..kcc
	defb 000h,063h,073h,07bh,07fh,06fh,067h,063h	; 4226  .cs{.ogc
	defb 000h,03eh,063h,063h,063h,063h,063h,03eh	; 422e  .>ccccc>
	defb 000h,07eh,063h,063h,063h,07eh,060h,060h	; 4236  .~ccc~``
	defb 000h,03eh,063h,063h,063h,06fh,066h,03dh	; 423e  .>cccof=
	defb 000h,07eh,063h,063h,062h,07ch,066h,063h	; 4246  .~ccb|fc
	defb 000h,03eh,063h,060h,03eh,003h,063h,03eh	; 424e  .>c`>.c>
	defb 000h,07eh,018h,018h,018h,018h,018h,018h	; 4256  .~......
	defb 000h,063h,063h,063h,063h,063h,063h,03eh	; 425e  .cccccc>
	defb 000h,063h,063h,063h,063h,036h,01ch,008h	; 4266  .cccc6..
	defb 000h,063h,063h,06bh,06bh,07fh,077h,022h	; 426e  .cckk.w"
	defb 000h,063h,076h,03ch,01ch,01eh,037h,063h	; 4276  .cv<..7c
	defb 000h,066h,066h,07eh,03ch,018h,018h,018h	; 427e  .ff~<...
	defb 000h,07fh,007h,00eh,01ch,038h,070h,07fh	; 4286  .....8p.
	defb 000h,024h,024h,024h,000h,000h,000h,000h	; 428e  .$$$....
	defb 000h,00fh,01fh,0ffh,0ffh,0ffh,0ffh,00fh	; 4296  ........
	defb 000h,000h,0feh,0e0h,0e0h,0c0h,0c0h,080h	; 429e  ........
	defb 000h,008h,01ch,03eh,07fh,03eh,01ch,008h	; 42a6  ...>.>..
	defb 038h,07ch,0feh,0feh,0feh,0feh,07ch,038h	; 42ae  8|....|8

; ----------------------------------------------------------------------
; DATOS rotulo_del_marcador: Lista formato A del marco del marcador: "1P" en
;   la fila 0 columna 2, "HI" en la 12 y "STAGE" en la 22, cada uno con el
;   tile 0x40 detras como separador. La pinta 0x47F1 al refrescar el marcador.
;   0x42b6..0x42cb  (21 bytes)
DATA_rotulo_del_marcador:
	defb 00ch,038h,048h,049h,040h,0feh,016h,038h,053h,054h,041h,047h,045h,040h,0feh,002h	; 42b6  .8HI@..8STAGE@..
	defb 038h,031h,050h,040h,0ffh	; 42c6

; ----------------------------------------------------------------------
; DATOS rotulo_2p: Lista formato A: "2P" en la fila 1 columna 2. Solo se pinta
;   si hay segundo jugador (bit 5 de 0xE002, comprobado en 0x47F7).
;   0x42cb..0x42d1  (6 bytes)
DATA_rotulo_2p:
	defb 022h,038h,032h,050h,040h,0ffh	; 42cb

; ----------------------------------------------------------------------
; DATOS rotulo_copyright: Lista formato A: "(c)KONAMI 1984" en la fila 8 (el
;   tile 0x3A de la fuente es el simbolo del copyright). Lo pinta el titulo
;   cuando el logo termina de desplegarse (0x48DF) o directamente al entrar en
;   la pantalla (0x4410).
;   0x42d1..0x42e0  (15 bytes)
DATA_rotulo_copyright:
	defb 00bh,039h,03ah,04bh,04fh,04eh,041h,04dh,049h,000h,031h,039h,038h,034h,0ffh	; 42d1  .9:KONAMI.1984.

; ----------------------------------------------------------------------
; DATOS rotulo_play_select: Lista formato A: "PLAY SELECT" en la fila 13
;   (0x4416).
;   0x42e0..0x42ee  (14 bytes)
DATA_rotulo_play_select:
	defb 0abh,039h,050h,04ch,041h,059h,000h,053h,045h,04ch,045h,043h,054h,0ffh	; 42e0  .9PLAY.SELECT.

; ----------------------------------------------------------------------
; DATOS rotulo_1_player: Lista formato A: "1 PLAYER" en la fila 16 (0x441C);
;   el menu la parpadea borrandola y pintandola (0x4451 con las dos entradas
;   del interprete).
;   0x42ee..0x42f9  (11 bytes)
DATA_rotulo_1_player:
	defb 00dh,03ah,031h,000h,050h,04ch,041h,059h,045h,052h,0ffh	; 42ee  .:1.PLAYER.

; ----------------------------------------------------------------------
; DATOS rotulo_2_players: Lista formato A: "2 PLAYERS" en la fila 18 (0x4422 y
;   0x4456).
;   0x42f9..0x4305  (12 bytes)
DATA_rotulo_2_players:
	defb 04dh,03ah,032h,000h,050h,04ch,041h,059h,045h,052h,053h,0ffh	; 42f9  M:2.PLAYERS.

; ----------------------------------------------------------------------
; DATOS rotulo_game_over_y_player: Lista formato A de dos entradas que pinta
;   0x4503 al acabarse las bolas: "GAME OVER" en la fila 11 columna 11
;   (destino 0x396B, con dos tiles 0 de separacion en medio) y, tras el 0xFE,
;   "PLAYER" en la fila 9 columna 12 (destino 0x392C). El aviso de turno del
;   estado 9 NO usa el interprete: 0x448B copia a pelo los seis tiles que hay
;   en 0x4314 -el "PLAYER" ya sin su cabecera de destino- a la VRAM 0x386C,
;   que es la fila 3 columna 12, y le pega el digito del jugador en la columna
;   19.
;   0x4305..0x431b  (22 bytes)
DATA_rotulo_game_over_y_player:
	defb 06bh,039h,047h,041h,04dh,045h,000h,000h,04fh,056h,045h,052h,0feh,02ch,039h,050h	; 4305  k9GAME..OVER.,9P
	defb 04ch,041h,059h,045h,052h,0ffh	; 4315

; ----------------------------------------------------------------------
; DATOS raya_y_software: Lista FORMATO B del titulo (la unica de texto en ese
;   formato; la pinta 0x438D con 0x4965): doce tiles 0x1B seguidos en la fila
;   10 -la raya bajo el logo- y los ocho literales "SOFTWARE" en la fila 11.
;   0x431b..0x432c  (17 bytes)
DATA_raya_y_software:
	defb 04ah,039h,00ch,01bh,0ffh,06ch,039h,088h,053h,04fh,046h,054h,057h,041h,052h,045h	; 431b  J9...l9.SOFTWARE
	defb 000h	; 432b

; ----------------------------------------------------------------------
; DATOS rotulo_konamis: Lista formato A: "KONAMI" mas el tile 0xC0 (el
;   apostrofe) y la "S" en la fila 3: el "KONAMI'S" sobre el logo grande. La
;   pinta 0x48B8 al arrancar la animacion del titulo.
;   0x432c..0x4337  (11 bytes)
DATA_rotulo_konamis:
	defb 06ch,038h,04bh,04fh,04eh,041h,04dh,049h,0c0h,053h,0ffh	; 432c  l8KONAMI.S.

; ======================================================================
; CODIGO 0x4337..0x4350  (25 bytes)
; ======================================================================


avanza_el_juego:		; El paso de juego que corre dentro de la interrupcion: incrementa el contador de cuadros (0xE003) y despacha el estado (0xE000) por la tabla de 0x4350
	ld hl,0e003h		;4337   ; 0xE003 es el contador de cuadros: lo usan los parpadeos y las esperas
	inc (hl)			;433a
	ld a,(0e000h)		;433b   ; los estados por debajo del 8 son la pantalla del titulo y el menu
	cp 008h		;433e
	call c,lee_las_teclas_del_menu		;4340   ; solo alli se miran las teclas desde aqui; en partida las lee el modulo de la mesa
	ld a,(0e000h)		;4343
	cp 00bh		;4346   ; del 11 en adelante ya hay bolas en la mesa
	push af			;4348
	call nc,parpadea_el_jugador_del_turno		;4349   ; y entonces cada cuadro corre la fisica
	pop af			;434c   ; el estado vuelve a A para el despachador
	call despachador		;434d   ; la tabla de las dieciseis palabras va justo detras, sin etiqueta ni puntero

; ----------------------------------------------------------------------
; DATOS tabla_de_estados: Las dieciseis palabras del despachador de 0x40A0,
;   pegadas detras del `call` de 0x434D. El indice es (0xE000), el estado del
;   juego.
;   0x4350..0x4370  (32 bytes)
DATA_tabla_de_estados:
	defb 070h,043h	; 4350
	defb 081h,043h	; 4352
	defb 094h,043h	; 4354
	defb 08dh,045h	; 4356
	defb 0b3h,043h	; 4358
	defb 0c1h,043h	; 435a
	defb 0d0h,043h	; 435c
	defb 0dah,043h	; 435e
	defb 02bh,044h	; 4360
	defb 070h,044h	; 4362
	defb 0a5h,044h	; 4364
	defb 0bfh,044h	; 4366
	defb 0d3h,044h	; 4368
	defb 026h,045h	; 436a
	defb 04eh,045h	; 436c
	defb 070h,045h	; 436e

; ======================================================================
; CODIGO 0x4370..0x4462  (242 bytes)
; ======================================================================


estado_0_prepara_el_titulo:		; Programa los registros del VDP y arma la subida del logo: 14 pasos (0xE00A) desde la fila 21 (0xE00E=0x3AAA)
	ld a,00eh		;4370   ; catorce filas de subida para el logotipo
	ld (0e00ah),a		;4372
	ld hl,03aaah		;4375   ; 0x3AAA: nombres 0x3800 + 0x2AA, o sea la fila 21 columna 10
	ld (0e00eh),hl		;4378
	call programa_los_registros_del_vdp		;437b   ; el titulo necesita el VDP tal y como lo dejo el arranque
	jp L_458D		;437e   ; sin contador: el estado 1 va por su cuenta
estado_1_sube_el_logo:		; Cada dos cuadros pinta el logotipo KONAMI una fila mas arriba (0x491E); al llegar pinta la raya y SOFTWARE (lista 0x431B) y pasa
	ld a,(0e003h)		;4381
	rra			;4384   ; el bit 0 del contador de cuadros al acarreo
	ret nc			;4385   ; un cuadro si y otro no: el logo sube a la mitad de velocidad
	call sube_el_logo_konami		;4386
	ret nz			;4389   ; devuelve no-cero mientras le queden filas
	ld hl,0431bh		;438a   ; la raya y el SOFTWARE de debajo, ya en su sitio definitivo
	call pinta_lista_formato_b		;438d
	xor a			;4390   ; contador a cero, que son 256 cuadros de espera en el estado 2
	jp L_458A		;4391
estado_2_despeja_el_titulo:		; Agota el contador 0xE004, restaura el borde, borra sprites y tabla de nombres (0x43EF) y pasa
	ld hl,0e004h		;4394
	dec (hl)			;4397   ; con 0xE004 a cero el primer `dec` da 0xFF: la pantalla del titulo se queda cinco segundos
	ret nz			;4398
	call restaura_el_borde		;4399   ; el borde vuelve a negro
	xor a			;439c
	ld (0e00ah),a		;439d
	call borra_sprites_y_nombres		;43a0
	jp L_458D		;43a3   ; y al estado 3, que solo es un `inc`: la tabla lo manda a 0x458D
rearma_el_titulo:		; Lo llama el teclado fuera del menu: pinta la pantalla del titulo entera de golpe (0x4401) y salta al estado 5, el menu
	call pinta_el_titulo_de_golpe		;43a6   ; el atajo del teclado: la misma pantalla pero sin animacion
	ld a,005h		;43a9   ; y directo al menu
	ld (0e000h),a		;43ab
	xor a			;43ae
	ld (0e004h),a		;43af   ; sin espera: el menu responde ya
	ret			;43b2
estado_4_despliega_el_logo_grande:		; Suelta letra a letra el BILLIARDS verde (0x48B8); al acabar pinta el cursor y el menu y pasa
	call despliega_el_logo_grande		;43b3
	ret c			;43b6   ; acarreo = todavia quedan letras del BILLIARDS
	call pinta_el_cursor_del_menu		;43b7   ; la ultima letra trae detras el menu entero
	call L_4416		;43ba
	xor a			;43bd
	jp L_458A		;43be   ; otros 256 cuadros, esta vez de menu
estado_5_el_menu:		; Pinta el cursor donde diga 0xE006 y deja correr el contador; las teclas las procesa 0x40AA, que salta al estado 8 con el disparo
	call pinta_el_cursor_del_menu		;43c1   ; el cursor se repinta cada cuadro por si 0xE006 ha cambiado
	ld hl,0e004h		;43c4
	dec (hl)			;43c7
	ret nz			;43c8   ; mientras no se agote, aqui se queda esperando teclas
	xor a			;43c9
	ld (0e00bh),a		;43ca   ; 0xE00B a cero: al volver por el estado 7 sera para el attract
	jp pasa_al_estado_siguiente		;43cd
estado_6_cortina_hacia_la_partida:		; Corre la cortina de borrado (0x46EB) y al terminar entra en el modo de juego (0x48B0)
	call cortina_de_borrado		;43d0
	ret p			;43d3   ; signo positivo mientras a la cortina le queden columnas
	call arranca_el_modo_de_juego		;43d4   ; con la pantalla ya negra, entra la partida
	jp pasa_al_estado_siguiente		;43d7
estado_7_vuelta_al_titulo:		; Segun 0xE00B: arranca el modulo del attract (0x5EB3) o corre la cortina y vuelve al estado 0
	ld a,(0e00bh)		;43da
	or a			;43dd   ; 0xE00B dice de que vuelta se trata
	jr nz,L_43E3		;43de
	jp L_48B5		;43e0   ; a cero, la que sale del menu: arranca el attract
L_43E3:
	call cortina_de_borrado		;43e3
	ret p			;43e6
	xor a			;43e7
	ld (0e00bh),a		;43e8   ; gastado el aviso
	ld (0e000h),a		;43eb   ; y a empezar de nuevo por el estado 0
	ret			;43ee
borra_sprites_y_nombres:		; Corta la lista de sprites (0xD0 en 0x3B00) y pone a cero la tabla de nombres entera
	ld de,03b00h		;43ef   ; 0x3B00 son los atributos de sprite
	ld a,0d0h		;43f2   ; una Y de 0xD0 corta la lista: el VDP no dibuja ni ese sprite ni los siguientes
	call escribe_en_vram		;43f4
	ld de,03800h		;43f7   ; la tabla de nombres
	ld bc,00300h		;43fa   ; 24 filas por 32 columnas
	xor a			;43fd
	jp rellena_vram		;43fe
pinta_el_titulo_de_golpe:		; La version sin animacion: borra, logo hasta el final, copyright, menu y cursor
	call borra_sprites_y_nombres		;4401
	call restaura_el_borde		;4404
	xor a			;4407
	ld (0e00ah),a		;4408   ; el contador de filas del logo, a cero
L_440B:
	call despliega_el_logo_grande		;440b   ; la version de golpe: se le llama en bucle
	jr c,L_440B		;440e   ; hasta que suelta el acarreo
	ld hl,042d1h		;4410   ; el copyright de 1984
	call pinta_lista_formato_a		;4413
L_4416:
	ld hl,042e0h		;4416   ; los tres rotulos del menu, la entrada que tambien usa el estado 4
	call pinta_lista_formato_a		;4419
	ld hl,042eeh		;441c
	call pinta_lista_formato_a		;441f
	ld hl,042f9h		;4422
	call pinta_lista_formato_a		;4425
	jp pinta_el_cursor_del_menu		;4428
estado_8_confirma_la_seleccion:		; Submodo 0xE201: pide el jingle de salida (sonido 13), parpadea la opcion elegida 0x50 cuadros y arranca la partida (0x45A2)
	ld a,(0e201h)		;442b   ; 0xE201, el submodo dentro del estado 8
	dec a			;442e   ; submodo 1
	jr z,L_4446		;442f
	dec a			;4431   ; submodo 2
	jr z,$+52		;4432   ; el salto sin etiqueta cae en 0x4466, por encima de los cuatro bytes huerfanos de 0x4462
	call pinta_el_cursor_del_menu		;4434   ; submodo 0: fija el cursor donde se eligio
	ld a,050h		;4437   ; 0x50 cuadros de parpadeo
	ld (0e004h),a		;4439
	ld a,08dh		;443c   ; sonido 0x8D: el pitido de aceptar
	call pide_un_sonido		;443e
L_4441:
	ld hl,0e201h		;4441   ; y al submodo siguiente
	inc (hl)			;4444
	ret			;4445
L_4446:
	ld hl,0e004h		;4446
	dec (hl)			;4449   ; agotado el parpadeo, al submodo 2
	jr z,L_4441		;444a
	ld c,(hl)			;444c   ; el propio contador marca el ritmo del parpadeo
	ld a,(0e006h)		;444d   ; la opcion elegida
	and a			;4450
	ld hl,042eeh		;4451   ; 1 PLAYER
	jr z,L_4459		;4454
	ld hl,042f9h		;4456   ; 2 PLAYERS
L_4459:
	ld a,c			;4459
	and 004h		;445a   ; el bit 2 del contador: cuatro cuadros vista, cuatro cuadros borrada
	jp z,pinta_lista_formato_a		;445c   ; cuatro de cada ocho, pintada
	jp borra_lista_formato_a		;445f   ; y las otras cuatro, borrada con la misma lista

; ----------------------------------------------------------------------
; DATOS datos_sin_dueno_4462: Cuatro bytes (00 80 40 C0) que ninguna
;   instruccion del cartucho referencia: ni aparecen como operando inmediato
;   en el codigo trazado, ni la secuencia de su direccion (62 44) existe en
;   toda la ROM. El codigo del menu salta por encima (el `jr z` de 0x4432 cae
;   en 0x4466). Parecen una tabla abandonada.
;   0x4462..0x4466  (4 bytes)
DATA_datos_sin_dueno_4462:
	defb 000h,080h,040h,0c0h	; 4462

; ======================================================================
; CODIGO 0x4466..0x45cc  (358 bytes)
; ======================================================================


L_4466:
	call prepara_la_partida		;4466   ; submodo 2: la seleccion ya esta decidida
	xor a			;4469
	ld (0e00ch),a		;446a   ; la fisica, parada
	jp pasa_al_estado_siguiente		;446d
estado_9_saca_bola:		; Gasta una bola de reserva (0xE050), refresca el marcador y, con dos jugadores, pinta PLAYER y el numero del que entra
	ld hl,0e1fbh		;4470   ; 0xE1FB dice si esta entrada lleva cortina
	ld a,(hl)			;4473
L_4474:
	ld (hl),000h		;4474   ; se gasta al leerlo: solo vale para una vuelta
	and a			;4476
	jr nz,L_447D		;4477   ; puesto a uno, se salta la cortina (viene de un cambio de jugador)
	call cortina_de_borrado		;4479   ; a cero, primero se borra la pantalla columna a columna
	ret p			;447c
L_447D:
	ld hl,0e050h		;447d   ; 0xE050: las bolas de reserva
	dec (hl)			;4480   ; sacar cuesta una
	call refresca_el_marcador		;4481
	ld a,(0e002h)		;4484
	and 020h		;4487   ; el bit 5 de 0xE002: hay segundo jugador
	jr z,L_44A1		;4489
	ld hl,04314h		;448b   ; 0x4314 no es una lista: son los seis tiles de PLAYER, sin la cabecera de destino que llevan delante
	ld bc,00006h		;448e
	ld de,0386ch		;4491   ; 0x386C = fila 3, columna 12; el aviso del turno va arriba, no donde el GAME OVER
	call copia_a_vram		;4494   ; copia cruda, sin pasar por el interprete
	ld hl,00006h		;4497   ; copia_a_vram no mueve DE, asi que la suma se hace aqui
	add hl,de			;449a
	ex de,hl			;449b
	call L_4595		;449c   ; y detras el 1 o el 2 del jugador
	ld a,04fh		;449f   ; 0x4F, que el `inc` de abajo deja en 0x50
L_44A1:
	inc a			;44a1   ; sin segundo jugador se llega con A a cero: un solo cuadro de espera y a la mesa
	jp L_458A		;44a2
estado_10_monta_la_mesa:		; Borra el aviso de PLAYER y coloca las bolas en su posicion inicial (0x45D0)
	ld hl,0e004h		;44a5
	dec (hl)			;44a8
	jp nz,L_4642		;44a9   ; mientras se lee el PLAYER n, los sprites siguen refrescandose
L_44AC:
	xor a			;44ac
	ld (0e00ah),a		;44ad
	ld bc,00008h		;44b0   ; ocho tiles desde 0x386C: PLAYER, el hueco y el digito
	ld de,0386ch		;44b3
	call rellena_vram		;44b6
	call coloca_las_bolas		;44b9   ; y las bolas a su sitio
	jp pasa_al_estado_siguiente		;44bc
estado_11_la_tacada:		; Refresca los sprites de las bolas (0x463F) y espera a que la fisica diga: 0xE00C en marcha, y 0xE00D distinto de cero manda al estado 15
	call refresca_los_sprites		;44bf
	ld hl,0e00ch		;44c2   ; 0xE00C: la fisica en marcha
	xor a			;44c5
	cp (hl)			;44c6
	jp nz,L_458D		;44c7   ; se ha movido algo, asi que la tacada ha terminado
	inc hl			;44ca
	cp (hl)			;44cb   ; 0xE00D: la mesa se ha quedado limpia
	ret z			;44cc   ; nada que decidir, sigue la tacada
	ld a,00fh		;44cd   ; estado 15: mesa completada
	ld (0e000h),a		;44cf
	ret			;44d2
estado_12_fin_de_tacada:		; Espera a que se apague el canal de sonido y decide: sin bolas de reserva es el GAME OVER (musica, cortina, cartel y estado 13); con ellas restablece los intentos y vuelve a sacar por el estado 9, o le pasa el turno al otro si conserva bolas
	ld a,(0e024h)		;44d3   ; 0xE024 es el canal de sonido de mas peso
	cp 005h		;44d6   ; el 5 es el golpe de bola: hasta que no acabe no se decide nada
	ret z			;44d8
	ld a,(0e1adh)		;44d9   ; 0xE1AD: hay multiplicador de apuesta pendiente
	and a			;44dc
	call nz,ensena_el_rate		;44dd
	ld a,001h		;44e0
	ld (0e1b6h),a		;44e2   ; 0xE1B6 a uno: la proxima llamada a coloca_las_bolas NO recolocara
	xor a			;44e5
	ld (0e00ch),a		;44e6   ; la fisica, parada
	ld hl,0e050h		;44e9
	or (hl)			;44ec   ; quedan bolas de reserva?
	jr nz,L_4512		;44ed   ; si quedan, la partida sigue
	ld a,(0e024h)		;44ef
	cp 08ah		;44f2   ; no repetir la musica si ya esta sonando
	jr z,L_44FB		;44f4
	ld a,08ah		;44f6   ; 0x8A: la musica del final
	call pide_un_sonido		;44f8
L_44FB:
	xor a			;44fb
	ld (0e053h),a		;44fc   ; y se acabo el credito
	call cortina_de_borrado		;44ff
	ret p			;4502
	ld hl,04305h		;4503   ; el cartel GAME OVER con el numero de jugador
	call pinta_cartel_y_numero_de_jugador		;4506
	ld a,00dh		;4509   ; 0x0D, que el `inc` de L_458D convierte en el estado 14
	ld (0e000h),a		;450b
	xor a			;450e
	jp L_458A		;450f   ; contador a cero: 256 cuadros de cartel
L_4512:
	call restablece_los_intentos		;4512   ; los intentos de la bola siguiente, otra vez a dos
	ld hl,0e080h		;4515   ; 0xE080 y 0xE082: las reservas y el credito del OTRO jugador
	ld a,(hl)			;4518
	inc hl			;4519
	inc hl			;451a
	or (hl)			;451b
	ld hl,0e1fbh		;451c
	ld (hl),001h		;451f   ; de entrada, la siguiente entrada sin cortina
	jr nz,L_458D		;4521   ; al otro le queda algo, asi que le toca: estado 13
	dec (hl)			;4523   ; no queda nadie mas, asi que se sigue con cortina
	jr L_4581		;4524
estado_13_cambia_de_jugador:		; Intercambia byte a byte lo que es de cada jugador: 0xE050 (bolas de reserva), 0xE052 (el umbral de la bola extra) y 0xE053 (el credito) con 0xE080-0xE082. Se SALTA 0xE051 a proposito (el `inc hl` de 0x452F), asi que el numero de fase no cambia de manos: los dos jugadores avanzan por el mismo. Ademas conmuta el bit 7 de 0xE002 -de quien es el turno- y la bandera de cortina 0xE1FB, y vuelve a sacar bola por el estado 9
	ld hl,0e050h		;4526   ; la terna del jugador que sale
	ld de,0e080h		;4529   ; y la del que entra
	call L_4546		;452c   ; intercambia las bolas de reserva
	inc hl			;452f   ; SALTA 0xE051: el numero de fase NO se intercambia, los dos jugadores comparten el mismo
	call L_4546		;4530   ; el umbral de la bola extra
	call L_4546		;4533   ; y el credito
	ld hl,0e002h		;4536
	ld a,(hl)			;4539
	xor 080h		;453a   ; el bit 7 de 0xE002 es de quien es el turno
	ld (hl),a			;453c
	ld hl,0e1fbh		;453d
	ld a,(hl)			;4540
	xor 001h		;4541   ; y la bandera de la cortina se conmuta: quien entra por aqui si la ve
	ld (hl),a			;4543
	jr L_4581		;4544
L_4546:
	ld b,(hl)			;4546   ; el intercambio de un byte, con los dos punteros avanzando
	ld a,(de)			;4547
	ld (hl),a			;4548
	ld a,b			;4549
	ld (de),a			;454a
	inc hl			;454b
	inc de			;454c
	ret			;454d
estado_14_tras_el_game_over:		; Deja el cartel un rato: si el otro jugador sigue vivo le pasa el turno; si no, apaga y vuelve al titulo por el estado 7
	ld hl,0e004h		;454e
	dec (hl)			;4551   ; mientras el cartel siga puesto
	ret nz			;4552
	ld a,(0e080h)		;4553   ; las bolas del otro jugador
	or a			;4556
	ld a,00ch		;4557   ; 0x0C, que con el `inc` de abajo da el estado 13
	ld hl,0e1fbh		;4559
	ld (hl),001h		;455c   ; cortina saltada para el que entra
	jr nz,L_456B		;455e   ; le queda vida al otro: se le pasa el turno
	dec (hl)			;4560   ; no queda nadie: se acabo la partida
	ld hl,0e002h		;4561
	res 6,(hl)		;4564   ; fuera el reparto de puertos de joystick, que vuelve a mandar el 1
	ld a,006h		;4566   ; el 6 sirve dos veces: aviso en 0xE00B y estado 6, que con el `inc` da el 7
	ld (0e00bh),a		;4568
L_456B:
	ld (0e000h),a		;456b
	jr pasa_al_estado_siguiente		;456e
estado_15_mesa_completada:		; Bola de reserva de regalo, STAGE+1 en BCD, restablece los intentos y a sacar de nuevo
	ld hl,0e050h		;4570
	inc (hl)			;4573   ; completar la mesa regala una bola
	inc hl			;4574
	ld a,(hl)			;4575
	add a,001h		;4576   ; y sube la fase, en BCD para que el marcador la pinte tal cual
	daa			;4578
	ld (hl),a			;4579
	call restablece_los_intentos		;457a
	xor a			;457d
	ld (0e00dh),a		;457e   ; la mesa ya no esta limpia
L_4581:
	ld a,008h		;4581   ; estado 8 mas el `inc` = 9, a sacar bola
	ld (0e000h),a		;4583
	jr pasa_al_estado_siguiente		;4586
pasa_al_estado_siguiente:		; 0xE004=0x50 y estado+1 (la entrada 0x458A deja poner otro contador, y 0x458D solo incrementa)
	ld a,050h		;4588   ; 0x50 cuadros, la espera de siempre
L_458A:
	ld (0e004h),a		;458a   ; la entrada con contador a medida
L_458D:
	ld hl,0e000h		;458d   ; y la que solo pasa de estado
	inc (hl)			;4590
	ret			;4591
pinta_cartel_y_numero_de_jugador:		; Pinta la lista que llega en HL y le anade el digito 1 o 2 segun el bit 7 de 0xE002
	call pinta_lista_formato_a		;4592
L_4595:
	ld a,(0e002h)		;4595
	rlca			;4598   ; el bit 7 al bit 0
	and 001h		;4599
	add a,031h		;459b   ; 0x31 es el ASCII del uno, que tambien es su numero de tile
	inc de			;459d   ; un hueco entre el rotulo y la cifra
	call escribe_en_vram		;459e
	ret			;45a1
prepara_la_partida:		; Borra los marcadores y las variables (0xE043-0xE1FA), copia los valores iniciales y, con dos jugadores, arma la terna del segundo
	ld hl,0e043h		;45a2   ; desde 0xE043
	ld de,0e044h		;45a5
	ld bc,001b8h		;45a8   ; hasta 0xE1FB: marcadores, bolas y todo el estado de la mesa
	ld (hl),000h		;45ab
	ldir		;45ad
	ld hl,045cch		;45af   ; los cuatro valores de arranque
	ld de,0e050h		;45b2
	ld bc,00004h		;45b5
	ldir		;45b8
	ld a,(0e002h)		;45ba
	bit 5,a		;45bd   ; hay segundo jugador?
	ret z			;45bf
	ld hl,0e080h		;45c0
	ld (hl),003h		;45c3   ; tres bolas para el, igual que el primero
	inc hl			;45c5
	ld (hl),001h		;45c6   ; su umbral de bola extra
	inc hl			;45c8
	ld (hl),002h		;45c9   ; y sus dos creditos
	ret			;45cb

; ----------------------------------------------------------------------
; DATOS valores_iniciales_de_la_partida: Los cuatro bytes que 0x45AF copia a
;   0xE050-0xE053 al empezar: BALL=3 (las bolas blancas de reserva del
;   marcador), 0xE051=1, 0xE052=1 (el umbral en millares BCD de la siguiente
;   bola extra) y 0xE053=2.
;   0x45cc..0x45d0  (4 bytes)
DATA_valores_iniciales_de_la_partida:
	defb 003h,001h,001h,002h	; 45cc

; ======================================================================
; CODIGO 0x45d0..0x461f  (79 bytes)
; ======================================================================


coloca_las_bolas:		; Pinta la mesa y reparte los ocho registros de 0x461F en los registros de bola de 0xE100 (dieciseis bytes por bola)
	call pinta_la_mesa		;45d0   ; el fieltro y las bandas
	call L_5314		;45d3
	ld hl,0e1b6h		;45d6   ; 0xE1B6 lo pone el fin de tacada: entonces las bolas se quedan donde estan
	ld a,(hl)			;45d9
	ld (hl),000h		;45da   ; se gasta al leerlo
	and a			;45dc
	ret nz			;45dd   ; puesto, solo habia que repintar la mesa
	ld (0e1f9h),a		;45de
	ld hl,0e1d7h		;45e1   ; los siete bytes de 0xE1D7
	ld b,007h		;45e4
L_45E6:
	ld (hl),000h		;45e6
	inc hl			;45e8
	djnz L_45E6		;45e9
	call L_59C8		;45eb
	ld hl,0e100h		;45ee   ; los registros de bola, de dieciseis bytes cada uno
	ld de,0461fh		;45f1   ; la tabla de arranque, de cuatro bytes por bola
	ld b,008h		;45f4   ; las ocho bolas
L_45F6:
	ld (hl),0ffh		;45f6   ; el byte +0 a 0xFF: la bola entra en juego
	ld a,004h		;45f8   ; al +4
	call suma_a_a_hl		;45fa
	ld a,(de)			;45fd   ; la Y
	ld (hl),a			;45fe
	inc hl			;45ff
	inc de			;4600
	inc hl			;4601   ; al +6
	ld a,(de)			;4602   ; la X
	inc de			;4603
	ld (hl),a			;4604
	ld a,005h		;4605   ; al +11
	call suma_a_a_hl		;4607
	ld a,(de)			;460a   ; el numero de patron
	inc de			;460b
	ld (hl),a			;460c
	inc hl			;460d
	ld a,(de)			;460e   ; y el color, en el +12
	inc de			;460f
	ld (hl),a			;4610
	ld a,004h		;4611   ; al +16, la bola siguiente
	call suma_a_a_hl		;4613
	djnz L_45F6		;4616
	ld hl,0e100h		;4618   ; 0xE194 apunta a la bola en juego, y se empieza por la blanca
	ld (0e194h),hl		;461b
	ret			;461e

; ----------------------------------------------------------------------
; DATOS posiciones_iniciales_de_las_bolas: Ocho registros de cuatro bytes (Y,
;   X, numero de patron, color) que el bucle de 0x45F6 reparte por los
;   registros de bola de 0xE100, de dieciseis bytes cada uno: el +0 a 0xFF (la
;   bola entra en juego), la Y en el +4, la X en el +6, el patron en el +11 y
;   el color en el +12. La bola blanca sale en Y=0x70 X=0x40 y el triangulo de
;   colores en X=0x98, 0xA5 y 0xB2, mas la octava entrada en Y=0x80 X=0xE1,
;   fuera del pano. Los patrones van de 4 en 4 porque los sprites son de
;   16x16, y el color es el del palo de cada bola.
;   0x461f..0x463f  (32 bytes)
DATA_posiciones_iniciales_de_las_bolas:
	defb 070h,040h,000h,00fh	; 461f
	defb 070h,098h,004h,008h	; 4623
	defb 068h,0a5h,008h,009h	; 4627
	defb 078h,0a5h,00ch,00eh	; 462b
	defb 060h,0b2h,010h,00ah	; 462f
	defb 070h,0b2h,014h,007h	; 4633
	defb 080h,0b2h,018h,00bh	; 4637
	defb 080h,0e1h,01ch,00fh	; 463b

; ======================================================================
; CODIGO 0x463f..0x46be  (127 bytes)
; ======================================================================


refresca_los_sprites:		; Vuelca el estado de las bolas de 0xE100 a los atributos de sprite de la VRAM
	call L_51FF		;463f
L_4642:
	ld a,(0e00ah)		;4642   ; la entrada que usa el estado 10 mientras espera: refresca sin tocar la fisica
	and a			;4645   ; 0xE00A distinto de cero: hay una animacion pintando y los sprites no se tocan
	ret nz			;4646
	ld de,03b00h		;4647   ; los atributos de sprite
	call abre_la_vram_para_escribir		;464a
	ld a,(0e003h)		;464d   ; el contador de cuadros decide el orden
	ld c,a			;4650
	rra			;4651   ; su bit 0 al acarreo
	ld hl,0e104h		;4652   ; 0xE104: la Y de la primera bola
	jr nc,L_465A		;4655
	ld hl,0e144h		;4657   ; 0xE144: la Y de la quinta
L_465A:
	di			;465a   ; los dieciseis bytes tienen que salir de un tiron: el VDP va autoincrementando
	call vuelca_cuatro_bolas		;465b
	rr c		;465e   ; el mismo bit 0, otra vez al acarreo
	ld hl,0e144h		;4660   ; y el reparto se invierte
	jr nc,L_4668		;4663
	ld hl,0e104h		;4665
L_4668:
	call vuelca_cuatro_bolas		;4668   ; asi que cada cuadro se turna que grupo de cuatro bolas va primero en la lista
	ei			;466b
	ret			;466c
vuelca_cuatro_bolas:		; Escribe de un tiron los dieciseis bytes de cuatro sprites por el puerto de datos: de cada registro de bola saca la Y (+4), la X (+6), el patron (+11) y el color (+12), y salta al +16 para la siguiente.
	ld a,(00007h)		;466d   ; cada bola son cuatro bytes seguidos en la VRAM
	exx			;4670
	ld c,a			;4671
	exx			;4672
	ld b,004h		;4673   ; cuatro bolas por pasada
L_4675:
	ld a,(hl)			;4675   ; la Y, en el +4 del registro de bola
	exx			;4676
	out (c),a		;4677
	exx			;4679
	inc hl			;467a   ; al +6
	inc hl			;467b
	ld a,(hl)			;467c   ; la X
	exx			;467d
	out (c),a		;467e
	exx			;4680
	ld a,005h		;4681   ; al +11
	call suma_a_a_hl		;4683
	ld a,(hl)			;4686   ; el numero de patron
	exx			;4687
	out (c),a		;4688
	exx			;468a
	inc hl			;468b   ; al +12
	ld a,(hl)			;468c   ; el color
	exx			;468d
	out (c),a		;468e
	exx			;4690
	ld a,008h		;4691   ; al +16, el registro de la bola siguiente
	call suma_a_a_hl		;4693
	djnz L_4675		;4696
	ret			;4698
monta_la_pantalla:		; Programa los ocho registros del VDP y escribe 0xB8 en el registro 7 del PSG, que es el mezclador: abre los tres canales de tono, corta los tres de ruido y deja el puerto A de entrada (el joystick) y el B de salida. Lo que mantiene el chip callado son los volumenes, que estan a cero. Luego borra los 16 KB de VRAM de un golpe.
	call programa_los_registros_del_vdp		;4699
	ld a,007h		;469c   ; registro 7 del PSG: el mezclador
	ld e,0b8h		;469e   ; 0xB8 abre los tres canales de tono, corta los tres de ruido y deja el puerto A de entrada para el joystick
	call 00093h		;46a0   ; BIOS WRTPSG - Writes data to PSG-register
	ld de,00000h		;46a3   ; los 16 KB enteros de VRAM
	ld bc,04000h		;46a6
	xor a			;46a9
	jp rellena_vram		;46aa
programa_los_registros_del_vdp:		; Escribe los ocho valores de 0x46BE en los registros 0-7
	ld hl,046beh		;46ad   ; los ocho valores estan seguidos
	ld d,008h		;46b0
	ld c,000h		;46b2   ; empezando por el registro 0
L_46B4:
	ld b,(hl)			;46b4   ; el valor
	call 00047h		;46b5   ; BIOS WRTVDP - Writes data in the VDP-register | y C dice a que registro va
	inc hl			;46b8
	inc c			;46b9
	dec d			;46ba
	jr nz,L_46B4		;46bb
	ret			;46bd

; ----------------------------------------------------------------------
; DATOS registros_del_vdp: Los ocho valores que 0x46AD escribe en los
;   registros 0-7 del VDP al arrancar: 02 E2 0E 7F 07 76 03 E4. Es SCREEN 2
;   con la tabla de nombres en 0x3800 (R2=0x0E), colores en 0x0000 (R3=0x7F),
;   patrones en 0x2000 (R4=0x07), atributos de sprites en 0x3B00 (R5=0x76),
;   patrones de sprites en 0x1800 (R6=0x03) y borde de color 4, el azul oscuro
;   (R7=0xE4).
;   0x46be..0x46c6  (8 bytes)
DATA_registros_del_vdp:
	defb 002h,0e2h,00eh,07fh,007h,076h,003h,0e4h	; 46be  .....v..

; ======================================================================
; CODIGO 0x46c6..0x48ac  (486 bytes)
; ======================================================================


restaura_el_borde:		; Registro 7 = 0xE0
	ld c,007h		;46c6
	ld b,0e0h		;46c8
	jp 00047h		;46ca   ; BIOS WRTVDP - Writes data in the VDP-register
copia_a_vram:		; BC bytes desde HL a la direccion DE, por el puerto de datos
	call abre_la_vram_para_escribir		;46cd
L_46D0:
	ld a,(hl)			;46d0
	exx			;46d1
	out (c),a		;46d2
	exx			;46d4
	inc hl			;46d5
	dec bc			;46d6
	ld a,b			;46d7
	or c			;46d8
	jr nz,L_46D0		;46d9
	ret			;46db
rellena_vram:		; Escribe BC veces el byte A desde la direccion DE
	ld h,a			;46dc
	call abre_la_vram_para_escribir		;46dd
L_46E0:
	ld a,h			;46e0
	exx			;46e1
	out (c),a		;46e2
	exx			;46e4
	dec bc			;46e5
	ld a,b			;46e6
	or c			;46e7
	jr nz,L_46E0		;46e8
	ret			;46ea
cortina_de_borrado:		; Borra la pantalla una columna por cuadro segun el contador de 0xE004; devuelve signo cuando ha terminado
	ld a,001h		;46eb
	ld (0e00ah),a		;46ed
	ld d,038h		;46f0
	ld hl,0e004h		;46f2
	ld b,018h		;46f5
	bit 6,(hl)		;46f7
	jr nz,L_4703		;46f9
	ld a,01fh		;46fb
	sub (hl)			;46fd
	ld e,a			;46fe
	set 6,(hl)		;46ff
	jr L_4708		;4701
L_4703:
	res 6,(hl)		;4703
	dec (hl)			;4705
	ret m			;4706
	ld e,(hl)			;4707
L_4708:
	ld a,(0e000h)		;4708
	cp 00ch		;470b
	jr c,L_4715		;470d
	ld a,060h		;470f
	add a,e			;4711
	ld e,a			;4712
	ld b,015h		;4713
L_4715:
	xor a			;4715
	call escribe_en_vram		;4716
	ld a,020h		;4719
	call suma_a_a_de		;471b
	djnz L_4715		;471e
	ld de,03b00h		;4720
	ld a,0d0h		;4723
	call escribe_en_vram		;4725
	xor a			;4728   ; la cortina devuelve cero al terminar
	ret			;4729
borra_lista_formato_a:		; La entrada que enmascara con 0x00: la misma lista que pinta, borra
	ld c,000h		;472a   ; la misma lista sirve para borrar: basta con enmascarar los tiles a cero
	jr L_4730		;472c
pinta_lista_formato_a:		; [destino:2][tiles...] con 0xFE = otro destino y 0xFF = fin
	ld c,0ffh		;472e   ; y con 0xFF pasan tal cual
L_4730:
	ld e,(hl)			;4730   ; los dos primeros bytes son el destino en VRAM
	inc hl			;4731
	ld d,(hl)			;4732
	inc hl			;4733
L_4734:
	ld a,(hl)			;4734   ; el tile siguiente
	inc hl			;4735
	ld b,a			;4736   ; la comprobacion se hace sobre una copia, que A hace falta entero
	inc b			;4737   ; 0xFF + 1 = 0: fin de la lista
	ret z			;4738
	inc b			;4739   ; 0xFE + 1 + 1 = 0: viene otro destino
	jr z,L_4730		;473a
	and c			;473c   ; y si no, es un tile: la mascara decide si pinta o borra
	call escribe_en_vram		;473d
	inc de			;4740   ; la VRAM avanza sola
	jr L_4734		;4741
carga_la_fuente:		; Rellena los colores (0xF0) y copia los 48 glifos de 0x4136 a los tiles 0x30-0x5F de los tres tercios
	ld a,0f0h		;4743   ; 0xF0: blanco sobre transparente
	ld de,00180h		;4745   ; los colores de los tiles 0x30-0x5F (0x30 * 8 = 0x180)
	ld bc,00180h		;4748   ; 384 bytes, que son los 48 glifos
	call rellena_los_tres_tercios		;474b
	ld hl,04136h		;474e   ; los glifos
	ld bc,00180h		;4751
	ld de,02180h		;4754   ; y sus patrones, 0x2000 + 0x180
copia_a_los_tres_tercios:		; Como 0x46CD pero repitiendo la copia en los tres tercios del generador (D += 8 por pasada)
	exx			;4757   ; en SCREEN 2 el generador son tres tablas de 0x800, una por tercio de pantalla
	ld b,003h		;4758   ; tres pasadas, con B del juego alterno porque BC lleva la longitud
L_475A:
	exx			;475a
	push de			;475b   ; copia_a_vram se lleva por delante HL, DE y BC
	push hl			;475c
	push bc			;475d
	call copia_a_vram		;475e
	pop bc			;4761
	pop hl			;4762
	pop de			;4763
	ld a,d			;4764   ; sumar 8 al byte alto es sumar 0x800: el tercio siguiente
	add a,008h		;4765
	ld d,a			;4767
	exx			;4768
	djnz L_475A		;4769
	ret			;476b
rellena_los_tres_tercios:		; Idem con el relleno
	exx			;476c
	ld b,003h		;476d
L_476F:
	exx			;476f
	push af			;4770   ; aqui es A el que lleva el dato, asi que tambien se guarda
	push de			;4771
	push bc			;4772
	call rellena_vram		;4773
	pop bc			;4776
	pop de			;4777
	pop af			;4778
	ld hl,00800h		;4779   ; la misma suma de 0x800, pero por HL porque A esta ocupado
	add hl,de			;477c
	ex de,hl			;477d
	exx			;477e
	djnz L_476F		;477f
	ret			;4781
suma_al_marcador:		; Suma DE en BCD al marcador del jugador activo (0xE043 o 0xE046 segun el bit 7 de 0xE002), con tope en 999999; de paso da la bola extra al cruzar el umbral de 0xE052 y actualiza el record (0xE040) si toca
	ld a,(0e002h)		;4782
	add a,a			;4785   ; el bit 6 de 0xE002 al signo: dice si hay partida de verdad
	ret p			;4786   ; en el attract nadie puntua
	ld hl,0e043h		;4787   ; y el bit 7 quedo en el acarreo: de quien es el turno
	jr nc,L_478E		;478a
	ld l,046h		;478c   ; 0xE046, el marcador del segundo jugador
L_478E:
	ld a,(hl)			;478e   ; las tres cifras en BCD, de dos en dos
	add a,e			;478f
	daa			;4790   ; `daa` tras cada suma: el marcador se guarda ya en decimal para pintarlo tal cual
	ld (hl),a			;4791
	ld e,a			;4792   ; DE se va quedando con lo que hay, para compararlo con el record
	inc l			;4793
	ld a,(hl)			;4794
	adc a,d			;4795
	daa			;4796
	ld (hl),a			;4797
	ld d,a			;4798
	jr nc,L_47B0		;4799
	inc hl			;479b
	ld a,(hl)			;479c
	add a,001h		;479d   ; el tercer byte solo recibe el acarreo
	daa			;479f
	ld (hl),a			;47a0
	jr nc,L_47B1		;47a1
	ld bc,09999h		;47a3   ; seis nueves: se ha desbordado el marcador y se clava en 999999
	ld (0e040h),bc		;47a6   ; dos escrituras de 16 bits para tres bytes, aprovechando el solape
	ld (0e041h),bc		;47aa
	jr pinta_el_record		;47ae
L_47B0:
	inc hl			;47b0
L_47B1:
	ld a,(0e052h)		;47b1   ; 0xE052: el millar en el que toca bola extra
	cp (hl)			;47b4   ; el byte alto del marcador ya lo ha pasado?
	push de			;47b5
	push hl			;47b6
	jr nc,L_47D2		;47b7
	add a,005h		;47b9   ; el siguiente umbral, cinco millares mas arriba
	daa			;47bb
	jr nc,L_47C0		;47bc   ; si se sale de la cuenta, se pone tan alto que no vuelve a saltar
	ld a,0ffh		;47be
L_47C0:
	ld (0e052h),a		;47c0
	ld hl,0e050h		;47c3
	inc (hl)			;47c6   ; una bola de regalo
	call pinta_ball_y_reserva		;47c7   ; y a la vista en el marcador
	ld a,007h		;47ca   ; sonido 7: el aviso de la bola extra
	call pide_un_sonido		;47cc
	pop hl			;47cf
	jr L_47D3		;47d0
L_47D2:
	pop hl			;47d2
L_47D3:
	ld a,(0e042h)		;47d3   ; 0xE042 es el byte alto del record
	ld b,(hl)			;47d6
	sub (hl)			;47d7   ; el marcador aun no llega
	ex de,hl			;47d8
	pop de			;47d9
	jr c,L_47E7		;47da
	jr nz,L_481E		;47dc   ; lo pasa de largo: record nuevo
	push hl			;47de
	ld hl,(0e040h)		;47df   ; empatados arriba, hay que mirar los cuatro digitos de abajo
	sbc hl,de		;47e2
	pop hl			;47e4
	jr nc,L_481E		;47e5   ; el record sigue siendo mejor
L_47E7:
	ld (0e040h),de		;47e7   ; y si no, el marcador pasa a ser el record
	ld a,b			;47eb
	ld (0e042h),a		;47ec
	jr pinta_el_record		;47ef
refresca_el_marcador:		; Pinta los rotulos del marcador y los numeros: 1P, 2P si procede, HI, STAGE, BALL y las cifras
	ld hl,042b6h		;47f1   ; el marco: 1P, HI y STAGE
	call pinta_lista_formato_a		;47f4
	ld a,(0e002h)		;47f7
	bit 5,a		;47fa   ; hay segundo jugador?
	jr z,L_480C		;47fc
	ld hl,042cbh		;47fe   ; entonces tambien el 2P de la fila 1
	call pinta_lista_formato_a		;4801
	ld a,(0e002h)		;4804
	xor 080h		;4807   ; invierte el turno para pintar el marcador del OTRO
	call pinta_el_marcador_de_un_jugador		;4809
L_480C:
	call pinta_ball_y_reserva		;480c   ; las bolas de reserva
	call pinta_el_numero_de_fase		;480f   ; y el numero de fase
	call L_52E5		;4812
pinta_el_record:		; Las seis cifras BCD de 0xE040-0xE042 en la fila 0 columnas 15-20, detras del rotulo HI.
	ld hl,0e042h		;4815   ; el record: 0xE042 es el byte alto, y el bucle va hacia atras
	ld de,0380fh		;4818   ; fila 0, columna 15, detras del HI
	call L_482F		;481b
L_481E:
	ld a,(0e002h)		;481e   ; y por ultimo el marcador del jugador que tiene el turno
pinta_el_marcador_de_un_jugador:		; Las seis cifras del marcador de quien diga el bit 7 de A: 0xE043 en la fila 0 (entrada 0x481E con el turno de verdad) o 0xE046 en la fila 1, siempre a partir de la columna 5.
	ld de,03805h		;4821   ; fila 0, columna 5: el del primer jugador
	ld hl,0e045h		;4824   ; 0xE045, otra vez el byte alto
	add a,a			;4827   ; el bit 7: de quien es el turno
	jr nc,L_482F		;4828
	ld e,025h		;482a   ; 0x3825 = fila 1, columna 5
	ld hl,0e048h		;482c   ; y su marcador, 0xE048
L_482F:
	ld b,003h		;482f   ; tres bytes BCD, o sea seis cifras
	jr pinta_cifras_bcd		;4831
pinta_el_numero_de_fase:		; Las dos cifras BCD de 0xE051 en la fila 0 columnas 28-29, detras del rotulo STAGE. El record lo pinta 0x4815, que entra en el mismo bucle con tres bytes en vez de uno.
	ld de,0381ch		;4833   ; fila 0, columna 28, detras del STAGE
	ld hl,0e051h		;4836   ; 0xE051, el numero de fase
	ld b,001h		;4839   ; un solo byte: dos cifras
pinta_cifras_bcd:		; El bucle comun del marcador: B bytes BCD leidos de HL hacia ATRAS, cada uno en dos tiles (el digito alto primero) a partir de la direccion de VRAM DE.
	ld a,(hl)			;483b
	push af			;483c
	and 00fh		;483d   ; el digito de abajo
	or 030h		;483f   ; 0x30 es el ASCII del cero, y tambien su numero de tile
	ld c,a			;4841
	pop af			;4842
	and 0f0h		;4843   ; y el de arriba
	rra			;4845   ; cuatro rotaciones para bajarlo
	rra			;4846
	rra			;4847
	rra			;4848
	or 030h		;4849
	call escribe_en_vram		;484b   ; el de arriba va primero
	inc de			;484e
	ld a,c			;484f
	call escribe_en_vram		;4850
	dec hl			;4853   ; los bytes se leen del mas alto al mas bajo
	inc de			;4854
	djnz pinta_cifras_bcd		;4855
	ret			;4857
parpadea_el_jugador_del_turno:		; Del estado 11 en adelante, uno de cada 32 cuadros: lee de la VRAM el rotulo 1P o 2P del jugador que tiene el turno (fila 0 o 1, columna 2) y lo borra si estaba, o lo pinta si no. La lectura de la propia pantalla es lo que hace de bandera: no hay variable de parpadeo.
	ld hl,(0e002h)		;4858   ; H se queda con el contador de cuadros y L con 0xE002
	ld a,01fh		;485b   ; uno de cada 32 cuadros
	and h			;485d
	ret nz			;485e
	ld de,03802h		;485f   ; fila 0, columna 2
	ld a,l			;4862
	ld c,040h		;4863   ; 0x40, el tile que hace de separador
	ld h,031h		;4865   ; 0x31: el "1" de 1P
	rla			;4867   ; el bit 7 al acarreo
	jr nc,L_486D		;4868
	ld e,022h		;486a   ; fila 1, columna 2
	inc h			;486c   ; y el "2" de 2P
L_486D:
	ld l,050h		;486d   ; 0x50, la "P"
	call lee_de_vram		;486f   ; mira lo que hay puesto ahora mismo
	and a			;4872
	jr z,L_4879		;4873   ; esta vacio, asi que toca pintarlo
	xor a			;4875   ; esta puesto, asi que toca borrarlo: de ahi el parpadeo
	ld h,a			;4876
	ld l,a			;4877
	ld c,a			;4878
L_4879:
	ld a,h			;4879
	call escribe_en_vram		;487a
	inc de			;487d
	ld a,l			;487e
	call escribe_en_vram		;487f
	ld a,c			;4882
	inc de			;4883
	call escribe_en_vram		;4884
	ret			;4887
pinta_ball_y_reserva:		; El rotulo BALL de 0x48AC y el numero de bolas de reserva (0xE050)
	ld de,03834h		;4888   ; fila 1, columna 20
	ld hl,048ach		;488b   ; los cuatro tiles del BALL
	ld bc,00004h		;488e
	call copia_a_vram		;4891
	ld de,0383dh		;4894   ; fila 1, columna 29
	ld a,(0e050h)		;4897   ; las bolas de reserva
	ld c,a			;489a
	ld b,005h		;489b   ; cinco huecos, se pinten o no
	ld a,05fh		;489d   ; 0x5F: el tile de la bola rellena
L_489F:
	dec c			;489f   ; una menos
	jp p,L_48A5		;48a0   ; mientras queden, bolita
	ld a,000h		;48a3   ; y cuando se acaban, hueco
L_48A5:
	call escribe_en_vram		;48a5
	dec de			;48a8   ; se pinta de derecha a izquierda
	djnz L_489F		;48a9
	ret			;48ab

; ----------------------------------------------------------------------
; DATOS rotulo_ball: Los cuatro tiles ASCII "BALL" que 0x4888 copia a la fila
;   1 columna 20 del marcador, delante del numero de bolas de reserva (0xE050)
;   que pinta a continuacion en la columna 29.
;   0x48ac..0x48b0  (4 bytes)
DATA_rotulo_ball:
	defb 042h,041h,04ch,04ch	; 48ac

; ======================================================================
; CODIGO 0x48b0..0x48f6  (70 bytes)
; ======================================================================


arranca_el_modo_de_juego:		; No salta a ningun sitio: solo pone a cero 0xE1F0, el indice del despachador del modulo de la mesa, para que la partida empiece por su primer submodo. Quien salta de verdad al modulo es 0x48B5, y lo llama el estado 7.
	xor a			;48b0
	ld (0e1f0h),a		;48b1   ; no salta al modulo de la mesa: solo rearma su despachador al primer submodo
	ret			;48b4
L_48B5:
	jp modulo_de_la_mesa		;48b5
despliega_el_logo_grande:		; Pinta el KONAMIS de la lista 0x432C y suelta una letra del BILLIARDS verde por llamada (tiles 0xC1+, contador 0xE00A); devuelve acarreo mientras queden
	ld hl,0432ch		;48b8   ; el KONAMI'S de arriba se repinta entero en cada llamada
	call pinta_lista_formato_a		;48bb
	ld hl,0e00ah		;48be   ; 0xE00A cuenta las letras ya soltadas
	ld a,(hl)			;48c1
	inc (hl)			;48c2
	cp 00fh		;48c3   ; quince letras y se acabo
	jr nc,L_48DF		;48c5
	ld de,038a9h		;48c7   ; 0x38A9 = fila 5, columna 9
	ld c,a			;48ca   ; guarda el indice, que A va a cambiar
	add a,e			;48cb   ; la columna avanza con la letra
	ld e,a			;48cc
	ld a,c			;48cd
	add a,0c1h		;48ce   ; los tiles de la mitad de ARRIBA empiezan en 0xC1
	call escribe_en_vram		;48d0
	ld hl,00020h		;48d3   ; una fila mas abajo
	add hl,de			;48d6
	ex de,hl			;48d7
	add a,00fh		;48d8   ; y quince mas alla estan las mitades de ABAJO: cada letra son dos tiles
	call escribe_en_vram		;48da
	scf			;48dd   ; acarreo: aun quedan letras por soltar
	ret			;48de
L_48DF:
	ld hl,042d1h		;48df   ; la ultima trae detras el copyright
	call pinta_lista_formato_a		;48e2
	or a			;48e5   ; y limpia el acarreo: aqui termina la animacion
	ret			;48e6
pinta_el_cursor_del_menu:		; Elige la lista 0x48F6 o 0x4900 segun 0xE006
	ld a,(0e006h)		;48e7
	ld hl,048f6h		;48ea   ; la lista con el cursor arriba
	and a			;48ed
	jr z,L_48F3		;48ee
	ld hl,04900h		;48f0   ; y la que lo pone abajo; las dos borran la otra fila, asi que no hay que limpiar nada
L_48F3:
	jp pinta_lista_formato_a		;48f3

; ----------------------------------------------------------------------
; DATOS cursor_en_1_player: Lista formato A del cursor del menu: los tiles
;   0x5C-0x5D (el simbolo del cursor) en la fila de "1 PLAYER" y dos tiles
;   0x00 que lo borran de la fila de "2 PLAYERS". La elige 0x48E7 cuando
;   (0xE006)=0.
;   0x48f6..0x4900  (10 bytes)
DATA_cursor_en_1_player:
	defb 00ah,03ah,05ch,05dh,0feh,04ah,03ah,000h,000h,0ffh	; 48f6  .:\].J:...

; ----------------------------------------------------------------------
; DATOS cursor_en_2_players: La lista simetrica: borra el cursor de "1 PLAYER"
;   y lo pinta en "2 PLAYERS" ((0xE006)=1).
;   0x4900..0x490a  (10 bytes)
DATA_cursor_en_2_players:
	defb 00ah,03ah,000h,000h,0feh,04ah,03ah,05ch,05dh,0ffh	; 4900  .:...J:\].

; ======================================================================
; CODIGO 0x490a..0x498d  (131 bytes)
; ======================================================================


carga_los_tiles_del_logo:		; Descomprime 0x498D en los patrones 0x2008 de los tres tercios y les pone el color blanco
	ld hl,0498dh		;490a   ; el bloque comprimido del logotipo
	ld de,02008h		;490d   ; 0x2008: los patrones a partir del tile 1
	call descomprime_en_los_tres_tercios		;4910
	ld de,00008h		;4913   ; y sus colores, tambien desde el tile 1
	ld bc,000d8h		;4916   ; 216 bytes: veintisiete tiles
	ld a,0f0h		;4919   ; blanco sobre transparente
	jp rellena_los_tres_tercios		;491b
sube_el_logo_konami:		; Pinta el logotipo (tiles 0x01-0x1A, filas de 3+11+12) una fila mas arriba y borra la que deja atras; cuenta en 0xE00A
	ld hl,(0e00eh)		;491e   ; 0xE00E lleva la esquina del logo en la VRAM
	ld de,0ffe0h		;4921   ; restar 32 es subir una fila
	add hl,de			;4924
	ld (0e00eh),hl		;4925
	ld a,001h		;4928   ; el logotipo son los tiles 1 a 26 seguidos
	ld b,003h		;492a   ; la fila de arriba, tres tiles
	call pinta_tiles_seguidos		;492c
	ld bc,00b0ch		;492f   ; la de en medio, once, y de paso deja 0x0C en C
	call pinta_tiles_seguidos		;4932
	ld b,c			;4935   ; y la de abajo, doce
	call pinta_tiles_seguidos		;4936
	xor a			;4939   ; con BC ya en 12 por el `djnz` de la ultima fila
	ex de,hl			;493a   ; DE quedo en la fila siguiente y HL en la ultima pintada
	call rellena_vram		;493b   ; y se borra la fila que el logo acaba de dejar atras
	ld hl,0e00ah		;493e
	dec (hl)			;4941   ; una fila menos de las catorce
	ret			;4942
pinta_tiles_seguidos:		; B tiles consecutivos desde el numero A en la direccion DE, y devuelve la fila siguiente
	push hl			;4943   ; la direccion de entrada, para poder devolver la fila siguiente
L_4944:
	ex de,hl			;4944   ; el cruce que espera escribe_en_vram
	call escribe_en_vram		;4945
	ex de,hl			;4948
	inc hl			;4949   ; la columna avanza
	inc a			;494a   ; y el numero de tile tambien: van seguidos
	djnz L_4944		;494b
	pop de			;494d   ; DE vuelve a ser el principio de la fila
	ld hl,00020h		;494e   ; y HL sale apuntando 32 bytes mas abajo: la fila de debajo
	add hl,de			;4951
	ret			;4952
descomprime_en_los_tres_tercios:		; Pasa el bloque formato B por los tres tercios (D += 8 por pasada)
	ld b,003h		;4953   ; tres pasadas, una por tercio
L_4955:
	push bc			;4955   ; descomprime_formato_b se lleva por delante los tres pares
	push hl			;4956
	push de			;4957
	call descomprime_formato_b		;4958
	pop de			;495b
	pop hl			;495c
	pop bc			;495d
	ld a,008h		;495e   ; sumar 8 al byte alto de DE es saltar 0x800, el tercio siguiente
	add a,d			;4960
	ld d,a			;4961
	djnz L_4955		;4962
	ret			;4964
pinta_lista_formato_b:		; Lee el destino de los dos primeros bytes y entra en 0x4969
	ld e,(hl)			;4965   ; la entrada con el destino delante
	inc hl			;4966
	ld d,(hl)			;4967
	inc hl			;4968
descomprime_formato_b:		; [ordenes] con bit 7 = copia literales, sin bit 7 = repite el byte siguiente, 0xFF = otro destino, 0x00 = fin
	call abre_la_vram_para_escribir		;4969   ; y la que ya lo trae puesto en DE
L_496C:
	ld a,(hl)			;496c   ; la orden siguiente
	inc hl			;496d
	or a			;496e   ; 0x00 cierra el bloque
	ret z			;496f
	cp 0ffh		;4970   ; 0xFF: se acabo este trozo y viene otro destino
	jr z,pinta_lista_formato_b		;4972
	bit 7,a		;4974   ; el bit 7 separa los dos tipos de orden
	jr nz,L_4983		;4976
	ld b,a			;4978   ; sin el bit 7, el numero es la cuenta de repeticiones
	ld a,(hl)			;4979   ; y detras va el byte que se repite
	inc hl			;497a
L_497B:
	exx			;497b   ; por el puerto, que el VDP ya va autoincrementando
	out (c),a		;497c
	exx			;497e
	djnz L_497B		;497f
	jr L_496C		;4981
L_4983:
	res 7,a		;4983   ; con el bit 7, lo que queda es cuantos literales vienen
	ld c,a			;4985
	ld b,000h		;4986
	call L_46D0		;4988   ; y se copian tal cual con el cuerpo de copia_a_vram
	jr L_496C		;498b

; ----------------------------------------------------------------------
; DATOS tiles_del_logo_konami: Bloque formato B que 0x490A descomprime en VRAM
;   0x2008 de los tres tercios: los patrones de los tiles 0x01-0x1B. Los 26
;   primeros son el logotipo KONAMI en tres filas (3+11+12 tiles, las anchuras
;   que pinta 0x491E al hacerlo subir por el titulo), luego el simbolo (c)
;   -los bytes 38 44 BA AA B2 AA 44 38- y la raya de subrayado (0x1B). El
;   relleno posterior les pone color 0xF0 (blanco sobre transparente).
;   0x498d..0x4a24  (151 bytes)
DATA_tiles_del_logo_konami:
	defb 00fh,000h,001h,001h,006h,000h,082h,0ffh,0feh,008h,00fh,084h,0c3h,0c7h,0cfh,0dfh	; 498d  ................
	defb 003h,0ffh,089h,0feh,0fch,0f8h,0f0h,0e0h,0c0h,080h,007h,007h,005h,000h,083h,003h	; 499d  ................
	defb 0cfh,0dfh,005h,000h,083h,0e1h,0f9h,07dh,005h,000h,083h,0efh,0ffh,0f7h,005h,000h	; 49ad  .......}........
	defb 083h,007h,08fh,09eh,005h,000h,083h,0f0h,0f8h,078h,005h,000h,083h,0f7h,0ffh,0fbh	; 49bd  .........x......
	defb 005h,000h,08bh,08fh,0dfh,0f7h,00ch,01eh,01eh,00ch,000h,01eh,09eh,09eh,008h,00fh	; 49cd  ................
	defb 090h,0ffh,0ffh,0dfh,0cfh,0c7h,0c3h,0c1h,0c0h,007h,087h,0c7h,0efh,0ffh,0ffh,0ffh	; 49dd  ................
	defb 0fch,004h,0deh,084h,09eh,09fh,00fh,003h,005h,03dh,083h,07dh,0f9h,0e1h,008h,0e3h	; 49ed  .........=.}....
	defb 090h,0dch,0c0h,0c7h,0deh,0dch,0deh,0cfh,0c3h,03ch,07ch,0fch,03ch,03ch,07ch,0fch	; 49fd  .........<|.<<|.
	defb 0deh,008h,0f1h,008h,0e3h,008h,0deh,088h,038h,044h,0bah,0aah,0b2h,0aah,044h,038h	; 4a0d  ........8D....D8
	defb 003h,000h,001h,0ffh,004h,000h,000h	; 4a1d

; ======================================================================
; CODIGO 0x4a24..0x4a70  (76 bytes)
; ======================================================================


carga_los_tiles_de_la_mesa:		; Copia los patrones 0x4A70 a 0x2400 de los tres tercios y descomprime sus colores (0x4C40)
	ld de,02400h		;4a24   ; 0x2400: los tiles de la mesa empiezan en el 0x80
	ld bc,001d8h		;4a27   ; 472 bytes, cincuenta y nueve tiles
	ld hl,04a70h		;4a2a
	call copia_a_los_tres_tercios		;4a2d   ; los patrones, iguales en los tres tercios
	ld hl,04c40h		;4a30   ; los colores van comprimidos
	ld de,00400h		;4a33   ; 0x0400: los colores del tile 0x80 en adelante
	jp descomprime_en_los_tres_tercios		;4a36
pinta_la_mesa:		; Recorre el plano de 0x4C59: cada grupo es un bloque formato B que se repite N filas desde VRAM 0x38E2; al acabar carga los patrones de sprite (0x4B30) y corta la lista de sprites
	di			;4a39   ; la mesa se pinta de un tiron, sin que entre la interrupcion en medio
	ld hl,04c59h		;4a3a   ; el plano de filas
	ld de,038e2h		;4a3d   ; 0x38E2 = fila 7, columna 2: la esquina de arriba a la izquierda de la mesa
L_4A40:
	ld a,(hl)			;4a40
	inc hl			;4a41
	and a			;4a42   ; un cero cierra el plano
	jr z,L_4A5A		;4a43
	ld b,a			;4a45   ; el numero dice cuantas filas seguidas van con este mismo dibujo
	ld (0e1b2h),hl		;4a46   ; y detras del numero empieza el bloque
L_4A49:
	ld hl,(0e1b2h)		;4a49   ; se recarga en cada vuelta porque el interprete deja HL al final del bloque
	push bc			;4a4c
	call descomprime_formato_b		;4a4d
	pop bc			;4a50
	ld a,020h		;4a51   ; y la fila de abajo
	call suma_a_a_de		;4a53
	djnz L_4A49		;4a56   ; las filas repetidas
	jr L_4A40		;4a58   ; al salir, HL ya esta en el numero del grupo siguiente
L_4A5A:
	ld de,01800h		;4a5a   ; 0x1800: los patrones de sprite
	ld hl,04b30h		;4a5d   ; los mismos bytes que ya se copiaron como tiles de la mesa
	ld bc,00120h		;4a60   ; 288 bytes: nueve sprites de 16x16
	call copia_a_vram		;4a63
	ld de,03b1ch		;4a66   ; 0x3B1C es la Y del sprite 7, el octavo
	ld a,0d0h		;4a69   ; y con 0xD0 el VDP deja de dibujar ahi: en la mesa solo hay siete bolas
	call escribe_en_vram		;4a6b
	ei			;4a6e
	ret			;4a6f

; ----------------------------------------------------------------------
; DATOS tiles_de_la_mesa: Los patrones que 0x4A24 copia tal cual a VRAM 0x2400
;   en los tres tercios: 0x1D8 bytes, los tiles 0x80-0xBA con el dibujo de la
;   mesa (bandas, troneras, tapete). SOLAPE DELIBERADO, dos veces: los ultimos
;   8 bytes de la copia (0x4C40-0x4C47) son a la vez el principio del bloque
;   de colores siguiente; y el tramo 0x4B30-0x4C4F se copia ADEMAS a VRAM
;   0x1800 como los nueve patrones de sprite de 16x16 (0x4A5D): las bolas y la
;   marca de la blanca son los mismos bytes leidos como sprites.
;   0x4a70..0x4c40  (464 bytes)
DATA_tiles_de_la_mesa:
	defb 000h,001h,003h,007h,005h,00ah,015h,02ah,000h,080h,0c0h,0e0h,050h,0a8h,054h,0aah	; 4a70  .......*....P.T.
	defb 0a0h,050h,0a0h,050h,0f0h,0f0h,0f0h,0e0h,002h,005h,00ah,00eh,00fh,00fh,00fh,007h	; 4a80  .P.P............
	defb 075h,03ah,015h,00ah,005h,002h,001h,000h,05eh,0ach,058h,0a0h,040h,080h,000h,000h	; 4a90  u:......^.X.@...
	defb 0f5h,0fah,0f5h,0fah,0f5h,0fah,0f5h,0fah,02ah,015h,00ah,005h,007h,003h,001h,000h	; 4aa0  ........*.......
	defb 000h,080h,040h,0a0h,050h,0a8h,05ch,0aeh,0aah,055h,0aah,055h,0ffh,0ffh,0ffh,0ffh	; 4ab0  ..@.P.\..U.U....
	defb 000h,000h,001h,002h,005h,00ah,035h,07ah,054h,0a8h,050h,0a0h,0e0h,0c0h,080h,000h	; 4ac0  ......5zT.P.....
	defb 0e0h,0f0h,0f0h,0f0h,050h,0f0h,050h,0f0h,05fh,0afh,05fh,0afh,05fh,0afh,05fh,0afh	; 4ad0  ....P.P._._._._.
	defb 0ffh,0ffh,0ffh,0ffh,055h,0aah,055h,0aah,05ah,0afh,05ah,0afh,05ah,0afh,05ah,0afh	; 4ae0  ....U.U.Z.Z.Z.Z.
	defb 000h,000h,000h,000h,000h,000h,000h,000h,0e0h,0f0h,0f0h,0f0h,050h,0a0h,050h,0a0h	; 4af0  ............P.P.
	defb 007h,00fh,00fh,00fh,005h,00ah,005h,002h,07fh,03fh,01fh,00fh,007h,003h,001h,000h	; 4b00  .........?......
	defb 000h,080h,0c0h,0e0h,0f0h,0f8h,0fch,0feh,001h,003h,007h,00fh,01fh,03fh,07fh,0ffh	; 4b10  .............?..
	defb 0ffh,0feh,0fch,0f8h,0f0h,0e0h,0c0h,080h,000h,000h,07fh,07fh,07fh,07fh,000h,000h	; 4b20  ................
	defb 000h,000h,003h,007h,00fh,00fh,01fh,01fh,01fh,01fh,00fh,00fh,007h,003h,000h,000h	; 4b30  ................
	defb 000h,000h,0c0h,0e0h,0f0h,0f0h,0f8h,0f8h,0f8h,0f8h,0f0h,0f0h,0e0h,0c0h,000h,000h	; 4b40  ................
	defb 000h,000h,003h,007h,00eh,00eh,01eh,01eh,01eh,01eh,00eh,00eh,007h,003h,000h,000h	; 4b50  ................
	defb 000h,000h,0c0h,0e0h,070h,070h,078h,078h,078h,078h,070h,070h,0e0h,0c0h,000h,000h	; 4b60  ....ppxxxxpp....
	defb 000h,000h,003h,007h,00ch,00bh,01fh,01fh,01ch,018h,008h,00fh,007h,003h,000h,000h	; 4b70  ................
	defb 000h,000h,0c0h,0e0h,030h,0d0h,0d8h,038h,0f8h,0f8h,010h,0f0h,0e0h,0c0h,000h,000h	; 4b80  ....0..8........
	defb 000h,000h,003h,007h,00ch,00bh,01fh,01eh,01fh,01bh,00ch,00fh,007h,003h,000h,000h	; 4b90  ................
	defb 000h,000h,0c0h,0e0h,030h,0d0h,0d8h,038h,0d8h,0d8h,030h,0f0h,0e0h,0c0h,000h,000h	; 4ba0  ....0..8..0.....
	defb 000h,000h,003h,007h,00fh,00fh,01eh,01dh,018h,01fh,00fh,00fh,007h,003h,000h,000h	; 4bb0  ................
	defb 000h,000h,0c0h,0e0h,0b0h,030h,0b8h,0b8h,018h,0b8h,0b0h,0f0h,0e0h,0c0h,000h,000h	; 4bc0  .....0..........
	defb 000h,000h,003h,007h,00fh,00ch,01dh,01ch,01fh,01fh,00dh,00eh,007h,003h,000h,000h	; 4bd0  ................
	defb 000h,000h,0c0h,0e0h,0f0h,030h,0f8h,038h,0d8h,0d8h,0d0h,030h,0e0h,0c0h,000h,000h	; 4be0  .....0.8...0....
	defb 000h,000h,003h,007h,00ch,00bh,01bh,018h,01bh,01bh,00ch,00fh,007h,003h,000h,000h	; 4bf0  ................
	defb 000h,000h,0c0h,0e0h,030h,0d0h,0f8h,038h,0d8h,0d8h,030h,0f0h,0e0h,0c0h,000h,000h	; 4c00  ....0..8..0.....
	defb 000h,000h,000h,000h,000h,000h,001h,003h,003h,001h,000h,000h,000h,000h,000h,000h	; 4c10  ................
	defb 000h,000h,000h,000h,000h,000h,080h,0c0h,0c0h,080h,000h,000h,000h,000h,000h,000h	; 4c20  ................
	defb 000h,000h,000h,0feh,000h,0feh,000h,000h,000h,082h,044h,028h,010h,028h,044h,082h	; 4c30  ..........D(.(D.

; ----------------------------------------------------------------------
; DATOS colores_de_la_mesa_comprimidos: Bloque formato B que 0x4A30
;   descomprime en VRAM 0x0400 de los tres tercios: los colores de los tiles
;   de la mesa. Sus ocho primeros bytes son tambien el final de los patrones
;   de arriba (el solape esta contado alli).
;   0x4c40..0x4c59  (25 bytes)
DATA_colores_de_la_mesa_comprimidos:
	defb 050h,06ch,048h,06ch,020h,01ch,008h,041h,020h,0f0h,020h,080h,020h,090h,020h,0e0h	; 4c40  PlHl ..A . . . .
	defb 020h,0a0h,020h,070h,020h,0b0h,030h,0f0h,000h	; 4c50   . p .0..

; ----------------------------------------------------------------------
; DATOS plano_de_la_mesa: El dibujo de la mesa en la tabla de nombres, tal
;   como lo consume 0x4A39: una secuencia de [contador][bloque formato B sin
;   destino], donde cada bloque es una fila de tiles que se repite [contador]
;   filas seguidas desde VRAM 0x38E2 bajando de 0x20 en 0x20. Cierra exacto en
;   el 0x00 final: 7 grupos que cubren 16 filas, de la 7 a la 22.
;   0x4c59..0x4ca8  (79 bytes)
DATA_plano_de_la_mesa:
	defb 001h,083h,000h,096h,087h,009h,089h,081h,082h,002h,090h,081h,083h,009h,089h,082h	; 4c59  ................
	defb 08bh,093h,000h,001h,081h,096h,01ah,090h,081h,093h,000h,001h,081h,088h,01ah,090h	; 4c69  ................
	defb 081h,08ah,000h,00ah,081h,08dh,01ah,090h,081h,086h,000h,001h,081h,085h,01ah,090h	; 4c79  ................
	defb 081h,084h,000h,001h,081h,094h,01ah,090h,081h,095h,000h,001h,083h,000h,094h,080h	; 4c89  ................
	defb 009h,08eh,081h,091h,002h,090h,081h,092h,009h,08eh,082h,081h,095h,000h,000h	; 4c99  ...............

; ======================================================================
; CODIGO 0x4ca8..0x52dc  (1588 bytes)
; ======================================================================


calcula_el_tiro:		; Convierte la mira en velocidad. Resta la posicion de la bola blanca (0xE104/0xE106) a la de la OCTAVA entrada de la tabla de bolas (0xE174/0xE176), que no es una bola sino el punto al que se apunta, y guarda las dos diferencias con signo en 0xE188 (dY) y 0xE18A (dX). Con ellas saca la distancia por Pitagoras -dos cuadrados, una suma y la raiz de 0x5376- y divide cada componente por ella para tener el vector unidad escalado a 256 (0xE18E, 0xE190). Ese vector, multiplicado (0xE1A0)+1 veces, es la velocidad inicial de la blanca; ademas deja su energia en el +1, su angulo en el +2 y limpia las banderas de las otras seis bolas antes de pedir el sonido 3, el golpe del taco.
	ld a,001h		;4ca8
	ld (0e19fh),a		;4caa   ; 0xE19F: hay tiro en marcha
	ld hl,0e104h		;4cad   ; la Y de la bola blanca
	ld de,0e174h		;4cb0   ; la Y de la OCTAVA entrada, que no es una bola: es el punto al que se apunta
	ld a,(de)			;4cb3   ; dY = mira - blanca
	sub (hl)			;4cb4
	ld b,000h		;4cb5   ; y el signo se extiende a mano a 16 bits
	jr nc,L_4CBA		;4cb7
	dec b			;4cb9
L_4CBA:
	ld c,a			;4cba
	ld (0e188h),bc		;4cbb   ; 0xE188 = dY
	inc l			;4cbf   ; a la X de la blanca
	inc l			;4cc0
	inc e			;4cc1   ; y a la X de la mira
	inc e			;4cc2
	ld a,(de)			;4cc3
	sub (hl)			;4cc4
	ld b,000h		;4cc5
	jr nc,L_4CCA		;4cc7
	dec b			;4cc9
L_4CCA:
	ld c,a			;4cca
	ld (0e18ah),bc		;4ccb   ; 0xE18A = dX
	inc b			;4ccf   ; B a 0xFF significa que dX es negativo
	jr nz,L_4CD4		;4cd0
	neg		;4cd2   ; y entonces se le da la vuelta: para el cuadrado da igual el signo
L_4CD4:
	ld h,a			;4cd4   ; el mismo valor en los dos: H * E es dX al cuadrado
	ld e,a			;4cd5
	call multiplica_h_por_e		;4cd6
	ld (0e18ch),hl		;4cd9   ; guardado
	ld hl,(0e188h)		;4cdc
	inc h			;4cdf   ; ahora el signo de dY
	ld a,l			;4ce0
	jr nz,L_4CE5		;4ce1
	neg		;4ce3
L_4CE5:
	ld h,a			;4ce5
	ld e,a			;4ce6
	call multiplica_h_por_e		;4ce7   ; dY al cuadrado
	ld bc,(0e18ch)		;4cea   ; y se le suma el de dX
	add hl,bc			;4cee
	call raiz_cuadrada		;4cef   ; la raiz: BC sale con la distancia entre la bola y la mira
	ld hl,(0e188h)		;4cf2
	xor a			;4cf5   ; A hara de bandera de signo
	inc h			;4cf6   ; dY negativo?
	jr nz,L_4D00		;4cf7
	dec a			;4cf9   ; se apunta el signo en el juego alterno
	ex af,af'			;4cfa
	ld a,l			;4cfb
	neg		;4cfc   ; y se trabaja con el valor absoluto
	ld l,a			;4cfe
	ex af,af'			;4cff
L_4D00:
	ex af,af'			;4d00
	ld h,l			;4d01   ; dY pasa al byte ALTO: dividir asi da el cociente con ocho bits de fraccion
	ld l,000h		;4d02
	ld e,c			;4d04   ; C, el byte bajo de la distancia
	call divide_hl_entre_bc		;4d05   ; dY * 256 / distancia: la componente Y del vector unidad
	ex af,af'			;4d08
	and a			;4d09   ; habia que darle la vuelta?
	ld h,000h		;4d0a
	jr z,L_4D13		;4d0c
	dec h			;4d0e   ; complemento a dos de HL
	ld a,l			;4d0f
	cpl			;4d10
	ld l,a			;4d11
	inc hl			;4d12
L_4D13:
	ld (0e18eh),hl		;4d13   ; 0xE18E = componente Y, con signo
	ld hl,(0e18ah)		;4d16   ; y lo mismo con dX
	xor a			;4d19
	inc h			;4d1a
	jr nz,L_4D24		;4d1b
	dec a			;4d1d
	ex af,af'			;4d1e
	ld a,l			;4d1f
	neg		;4d20
	ld l,a			;4d22
	ex af,af'			;4d23
L_4D24:
	ex af,af'			;4d24
	ld h,l			;4d25
	ld l,000h		;4d26
	ld e,c			;4d28
	call divide_hl_entre_bc		;4d29
	ex af,af'			;4d2c
	and a			;4d2d
	ld h,000h		;4d2e
	jr z,L_4D37		;4d30
	dec h			;4d32
	ld a,l			;4d33
	cpl			;4d34
	ld l,a			;4d35
	inc hl			;4d36
L_4D37:
	ld (0e190h),hl		;4d37   ; 0xE190 = componente X
	ld a,(0e1a0h)		;4d3a   ; 0xE1A0: la fuerza que se eligio
	inc a			;4d3d   ; una unidad mas, que la fuerza cero tambien mueve
	ld b,a			;4d3e
	ld e,l			;4d3f
	ld d,h			;4d40
	ld hl,00000h		;4d41   ; multiplicar sumando: son pocas vueltas
L_4D44:
	add hl,de			;4d44
	djnz L_4D44		;4d45
	ld (0e109h),hl		;4d47   ; el +9 de la bola blanca: su velocidad X, de 16 bits
	ld de,(0e18eh)		;4d4a   ; y la componente Y
	ld b,a			;4d4e
	ld hl,00000h		;4d4f
L_4D52:
	add hl,de			;4d52
	djnz L_4D52		;4d53
	ld (0e107h),hl		;4d55   ; el +7: su velocidad Y
	ld b,a			;4d58
	ld c,020h		;4d59   ; 0x20 por cada unidad de fuerza
	xor a			;4d5b
L_4D5C:
	add a,c			;4d5c
	djnz L_4D5C		;4d5d
	ld (0e101h),a		;4d5f   ; el +1: la energia que le queda a la bola, y la bandera de que se mueve
	ld hl,0e100h		;4d62
	call saca_la_pendiente_del_vector		;4d65   ; de la velocidad recien puesta saca la pendiente y el angulo
	ld a,(0e1a5h)		;4d68   ; 0xE1A5, la componente que dejo el paso anterior
	ld e,a			;4d6b
	ld h,018h		;4d6c   ; escalada a 24/256
	call multiplica_h_por_e		;4d6e
	ld a,h			;4d71
	ld (0e10dh),a		;4d72   ; al +13 de la bola
	ld a,(0e1a6h)		;4d75
	ld e,a			;4d78
	ld h,018h		;4d79
	call multiplica_h_por_e		;4d7b
	ld a,h			;4d7e
	ld (0e10eh),a		;4d7f   ; y al +14
	ld a,(0e1a1h)		;4d82   ; 0xE1A1, el angulo del tiro
	ld (0e102h),a		;4d85   ; al +2 de la bola
	ld hl,0e10fh		;4d88   ; el +15 de cada bola
	ld b,007h		;4d8b
L_4D8D:
	ld (hl),000h		;4d8d
	ld a,010h		;4d8f   ; de dieciseis en dieciseis: las siete bolas
	add a,l			;4d91
	ld l,a			;4d92
	djnz L_4D8D		;4d93
	ld hl,0e1d0h		;4d95   ; y los siete bytes de 0xE1D0
	ld b,007h		;4d98
L_4D9A:
	ld (hl),000h		;4d9a
	inc hl			;4d9c
	djnz L_4D9A		;4d9d
	ld a,003h		;4d9f   ; sonido 3: el golpe del taco
	call pide_un_sonido		;4da1
	xor a			;4da4
	ld (0e17ch),a		;4da5   ; se acabo de apuntar
	ld (0e202h),a		;4da8
	ld a,020h		;4dab   ; 0xE1F6: la cuenta atras que corre cuando todo se para
	ld (0e1f6h),a		;4dad
	ret			;4db0
paso_de_la_fisica:		; Un cuadro de mesa: recorre las siete bolas dos veces -primero moviendolas (0x4E6B) y luego resolviendo lo que se toca (0x53DD)-, y si al acabar ninguna conserva energia, deja pasar la cuenta atras de 0xE1F6 y decide como termina la tacada.
	ld hl,0e100h		;4db1   ; primera vuelta: mover
L_4DB4:
	ld a,(hl)			;4db4   ; el +0 dice si la bola sigue en la mesa
	inc hl			;4db5
	and (hl)			;4db6   ; y el +1 si le queda energia: hacen falta las dos
	dec hl			;4db7
	ld (0e194h),hl		;4db8   ; la rutina de mover trabaja con 0xE194
	call nz,L_4E6B		;4dbb   ; quieta o embocada, no se toca
	ld hl,(0e194h)		;4dbe
	ld a,010h		;4dc1   ; la bola siguiente, dieciseis bytes mas alla
	add a,l			;4dc3
	ld l,a			;4dc4
	ld a,06fh		;4dc5   ; hasta 0xE16F: SIETE bolas, que la octava es la mira
	cp l			;4dc7
	jr nc,L_4DB4		;4dc8
	ld hl,0e100h		;4dca   ; segunda vuelta: los choques
L_4DCD:
	ld (0e194h),hl		;4dcd
	ld a,(hl)			;4dd0
	inc hl			;4dd1
	and (hl)			;4dd2
	dec hl			;4dd3
	call nz,L_53DD		;4dd4
	ld hl,(0e194h)		;4dd7
	ld a,010h		;4dda
	add a,l			;4ddc
	ld l,a			;4ddd
	ld a,06fh		;4dde
	cp l			;4de0
	jr nc,L_4DCD		;4de1
	ld hl,0e101h		;4de3   ; el +1 de la primera bola
	ld de,00010h		;4de6   ; el salto de un registro de bola al siguiente
	ld b,007h		;4de9
	xor a			;4deb
L_4DEC:
	or (hl)			;4dec   ; junta la energia de las siete
	add hl,de			;4ded
	djnz L_4DEC		;4dee
	and a			;4df0
	ret nz			;4df1   ; mientras quede alguna rodando, no hay nada que decidir
	ld hl,0e1f6h		;4df2
	dec (hl)			;4df5   ; todo parado: corre la cuenta atras
	ret nz			;4df6
	inc (hl)			;4df7   ; al llegar a cero se queda clavada ahi
	ld (0e19fh),a		;4df8   ; se acabo el tiro
	ld a,010h		;4dfb
	ld (0e1aah),a		;4dfd
	ld a,(0e1adh)		;4e00   ; 0xE1AD: se ha embocado algo en esta tacada
	and a			;4e03
	jr z,L_4E0E		;4e04
	xor a			;4e06
	ld (0e1aeh),a		;4e07
	inc a			;4e0a
	ld (0e00ch),a		;4e0b   ; y entonces la tacada termina bien
L_4E0E:
	ld a,(0e1d0h)		;4e0e   ; 0xE1D0: la primera bola embocada de la tanda
	and a			;4e11
	ld (0e1afh),a		;4e12
	jr nz,L_4E47		;4e15   ; hay recuento pendiente, asi que a la animacion del multiplicador
	xor a			;4e17
	ld (0e1aeh),a		;4e18
	ld a,(0e00ch)		;4e1b   ; la tacada ya esta dada por terminada
	and a			;4e1e
	ret nz			;4e1f
	ld hl,0e053h		;4e20   ; 0xE053: los intentos que quedan con esta bola
	dec (hl)			;4e23
	jp p,L_4E32		;4e24   ; aun queda alguno
	ld a,006h		;4e27   ; sonido 6: se agotaron los intentos
	call pide_un_sonido		;4e29
	ld a,001h		;4e2c
	ld (0e00ch),a		;4e2e   ; y la tacada termina
	ret			;4e31
L_4E32:
	ld hl,0e080h		;4e32   ; el otro jugador conserva algo?
	ld a,(hl)			;4e35
	inc hl			;4e36
	inc hl			;4e37
	or (hl)			;4e38
	ret z			;4e39   ; no hay a quien pasarle el turno
	ld hl,0e050h		;4e3a
	inc (hl)			;4e3d   ; le devuelve la bola gastada
	ld a,00dh		;4e3e
	ld (0e000h),a		;4e40   ; estado 13: cambio de jugador
	ld (0e1b6h),a		;4e43   ; y que no se recoloquen las bolas al entrar
	ret			;4e46
L_4E47:
	xor a			;4e47
	ld (0e1b0h),a		;4e48
restablece_los_intentos:		; No toca ninguna bola: lo unico que hace es poner 0xE053 a 2, los intentos con los que entra la bola siguiente. Cada tacada que no emboca gasta uno (0x4E23), y al agotarse se acaba la bola. La llaman los estados 12 y 15 antes de volver a sacar.
	ld a,002h		;4e4b   ; los dos intentos de la bola siguiente
	ld (0e053h),a		;4e4d
	ret			;4e50
mira_si_la_mesa_esta_limpia:		; Junta el byte +0 de las seis bolas de color: si ninguna sigue en la mesa, pide el sonido 8 y pone el estado 15, el de mesa completada.
	ld hl,0e110h		;4e51   ; el +0 de la primera bola de color
	xor a			;4e54
	ld b,006h		;4e55   ; las seis de color, que la blanca no cuenta
	ld de,00010h		;4e57
L_4E5A:
	or (hl)			;4e5a
	add hl,de			;4e5b
	djnz L_4E5A		;4e5c
	and a			;4e5e
	ret nz			;4e5f   ; queda alguna en la mesa
	ld a,088h		;4e60   ; sonido 8: la mesa esta limpia
	call pide_un_sonido		;4e62
	ld a,00fh		;4e65   ; y el estado 15
	ld (0e000h),a		;4e67
	ret			;4e6a
L_4E6B:
	push hl			;4e6b
	pop ix		;4e6c
	inc hl			;4e6e
	inc hl			;4e6f
	inc hl			;4e70
	ld e,l			;4e71
	ld d,h			;4e72
	ld a,004h		;4e73
	add a,l			;4e75
	ld l,a			;4e76
	ld a,(de)			;4e77
	add a,(hl)			;4e78
	ld (de),a			;4e79
	inc hl			;4e7a
	inc de			;4e7b
	ld a,(de)			;4e7c
	adc a,(hl)			;4e7d
	ld (de),a			;4e7e
	inc hl			;4e7f
	inc de			;4e80
	ld a,(de)			;4e81
	add a,(hl)			;4e82
	ld (de),a			;4e83
	inc de			;4e84
	inc hl			;4e85
	ld a,(de)			;4e86
	adc a,(hl)			;4e87
	ld (de),a			;4e88
	call L_4F25		;4e89
	ld hl,(0e194h)		;4e8c
	ld d,h			;4e8f
	ld e,l			;4e90
	ld a,006h		;4e91
	add a,e			;4e93
	ld e,a			;4e94
	ld a,00ah		;4e95
	add a,l			;4e97
	ld l,a			;4e98
	ld a,(de)			;4e99
	ld c,a			;4e9a
	sub 014h		;4e9b
	sub 0c5h		;4e9d
	jr c,L_4ECE		;4e9f
	dec de			;4ea1
	dec de			;4ea2
	ex af,af'			;4ea3
	ld a,(de)			;4ea4
	ld b,a			;4ea5
	cp 045h		;4ea6
	jp c,L_5880		;4ea8
	cp 09dh		;4eab
	jp nc,L_589A		;4ead
	ex af,af'			;4eb0
	inc de			;4eb1
	inc de			;4eb2
	cp 010h		;4eb3
	jr c,L_4EB9		;4eb5
	add a,0c5h		;4eb7
L_4EB9:
	add a,a			;4eb9
	jr nz,L_4EBD		;4eba
	inc a			;4ebc
L_4EBD:
	ld b,a			;4ebd
	ld a,(de)			;4ebe
	sub b			;4ebf
	ld (de),a			;4ec0
	call L_4F19		;4ec1
	push hl			;4ec4
	push de			;4ec5
	call L_4F14		;4ec6
	call L_4F05		;4ec9
	pop de			;4ecc
	pop hl			;4ecd
L_4ECE:
	dec hl			;4ece
	dec hl			;4ecf
	dec de			;4ed0
	dec de			;4ed1
	ld a,(de)			;4ed2
	ld b,a			;4ed3
	sub 03eh		;4ed4
	sub 064h		;4ed6
	ret c			;4ed8
	inc de			;4ed9
	inc de			;4eda
	ex af,af'			;4edb
	ld a,(de)			;4edc
	ld c,a			;4edd
	cp 01fh		;4ede
	jp c,L_58B3		;4ee0
	cp 0d5h		;4ee3
	jp nc,L_5908		;4ee5
	sub 070h		;4ee8
	cp 010h		;4eea
	jp c,L_58CD		;4eec
	dec de			;4eef
	dec de			;4ef0
	ex af,af'			;4ef1
	jp p,L_4EF7		;4ef2
	add a,064h		;4ef5
L_4EF7:
	add a,a			;4ef7
	jr nz,L_4EFB		;4ef8
	inc a			;4efa
L_4EFB:
	ld b,a			;4efb
	ld a,(de)			;4efc
	sub b			;4efd
	ld (de),a			;4efe
	call L_4F19		;4eff
	call L_4F14		;4f02
L_4F05:
	call L_542D		;4f05
	ld a,(0e1a1h)		;4f08
	ld hl,(0e194h)		;4f0b
	inc hl			;4f0e
	inc hl			;4f0f
	ld (hl),a			;4f10
	jp L_4F25		;4f11
L_4F14:
	ld (ix+00fh),000h		;4f14
	ret			;4f18
L_4F19:
	ld a,(hl)			;4f19
	cpl			;4f1a
	ld b,a			;4f1b
	dec hl			;4f1c
	ld a,(hl)			;4f1d
	cpl			;4f1e
	ld c,a			;4f1f
	inc bc			;4f20
	ld (hl),c			;4f21
	inc hl			;4f22
	ld (hl),b			;4f23
	ret			;4f24
L_4F25:
	ld hl,(0e194h)		;4f25
	ld a,004h		;4f28
	add a,l			;4f2a
	ld l,a			;4f2b
	ld de,0e104h		;4f2c
	ld b,(hl)			;4f2f
	inc l			;4f30
	inc l			;4f31
	ld c,(hl)			;4f32
	dec l			;4f33
	dec l			;4f34
L_4F35:
	ld a,l			;4f35
	cp e			;4f36
	jr z,L_4F5A		;4f37
	ld a,(de)			;4f39
	inc e			;4f3a
	inc e			;4f3b
	sub b			;4f3c
	jr nc,L_4F41		;4f3d
	neg		;4f3f
L_4F41:
	cp 00ch		;4f41
	jr nc,L_4F58		;4f43
	ld a,(de)			;4f45
	sub c			;4f46
	jr nc,L_4F4B		;4f47
	neg		;4f49
L_4F4B:
	cp 00ch		;4f4b
	jr nc,L_4F58		;4f4d
	push hl			;4f4f
	push bc			;4f50
	push de			;4f51
	call c,L_4F63		;4f52
	pop de			;4f55
	pop bc			;4f56
	pop hl			;4f57
L_4F58:
	dec e			;4f58
	dec e			;4f59
L_4F5A:
	ld a,010h		;4f5a
	add a,e			;4f5c
	ld e,a			;4f5d
	cp 070h		;4f5e
	jr c,L_4F35		;4f60
	ret			;4f62
L_4F63:
	ld a,e			;4f63
	and 0f0h		;4f64
	ld e,a			;4f66
	ld (0e19ch),de		;4f67
	push de			;4f6b
	pop iy		;4f6c
	ld a,(ix+003h)		;4f6e
	sub (iy+003h)		;4f71
	ld l,a			;4f74
	ld a,(ix+004h)		;4f75
	sbc a,(iy+004h)		;4f78
	ld h,a			;4f7b
	add hl,hl			;4f7c
	add hl,hl			;4f7d
	add hl,hl			;4f7e
	add hl,hl			;4f7f
	call c,L_51BD		;4f80
	ld e,h			;4f83
	call multiplica_h_por_e		;4f84
	push hl			;4f87
	ld a,(ix+005h)		;4f88
	sub (iy+005h)		;4f8b
	ld l,a			;4f8e
	ld a,(ix+006h)		;4f8f
	sbc a,(iy+006h)		;4f92
	ld h,a			;4f95
	add hl,hl			;4f96
	add hl,hl			;4f97
	add hl,hl			;4f98
	add hl,hl			;4f99
	call c,L_51BD		;4f9a
	ld e,h			;4f9d
	call multiplica_h_por_e		;4f9e
	pop de			;4fa1
	add hl,de			;4fa2
	and a			;4fa3
	ld de,09000h		;4fa4
	sbc hl,de		;4fa7
	ret nc			;4fa9
	ld hl,(0e194h)		;4faa
	ld de,(0e19ch)		;4fad
	ld a,l			;4fb1
	add a,010h		;4fb2
	ld b,a			;4fb4
	ld a,e			;4fb5
	add a,010h		;4fb6
	ld c,a			;4fb8
	ld a,00fh		;4fb9
	add a,l			;4fbb
	ld l,a			;4fbc
	ld a,00fh		;4fbd
	add a,e			;4fbf
	ld e,a			;4fc0
	ld a,(hl)			;4fc1
	and a			;4fc2
	jr z,L_4FD0		;4fc3
	cp c			;4fc5
	jr nz,L_4FD0		;4fc6
	ld a,(de)			;4fc8
	and a			;4fc9
	jr z,L_4FD0		;4fca
	cp b			;4fcc
	jp z,L_51C5		;4fcd
L_4FD0:
	call L_51E5		;4fd0
	ld a,003h		;4fd3
	call L_5BCA		;4fd5
	call L_51C5		;4fd8
	ld de,(0e19ch)		;4fdb
	inc de			;4fdf
	ld a,(de)			;4fe0
	and a			;4fe1
	jp nz,L_5192		;4fe2
	call L_4FEB		;4fe5
	jp L_5104		;4fe8
L_4FEB:
	ld a,005h		;4feb
	add a,e			;4fed
	ld e,a			;4fee
	ld hl,(0e194h)		;4fef
	ld a,006h		;4ff2
	add a,l			;4ff4
	ld l,a			;4ff5
	call L_517B		;4ff6
	ld (0e198h),hl		;4ff9
	exx			;4ffc
	call L_517B		;4ffd
	ld (0e196h),hl		;5000
	ld hl,0e18fh		;5003
	call saca_la_pendiente_del_vector		;5006
	ld b,(ix+002h)		;5009
	ld a,(0e1a1h)		;500c
	sub b			;500f
	jp p,L_5015		;5010
	neg		;5013
L_5015:
	cp 03ch		;5015
	jr c,L_501B		;5017
	ld a,03ch		;5019
L_501B:
	call coseno_de_la_fuerza		;501b
	ld (0e1ach),a		;501e
	ld a,c			;5021
	ld e,a			;5022
	ld h,(ix+001h)		;5023
	push hl			;5026
	call multiplica_h_por_e		;5027
	ld a,h			;502a
	ld (0e1a7h),a		;502b
	ld (iy+001h),a		;502e
	pop hl			;5031
	ld a,(0e1ach)		;5032
	ld e,a			;5035
	call multiplica_h_por_e		;5036
	ld (ix+001h),h		;5039
	ld a,(0e1a5h)		;503c
	ld e,a			;503f
	ld a,(0e1a7h)		;5040
	ld h,a			;5043
	call multiplica_h_por_e		;5044
	xor a			;5047
	add hl,hl			;5048
	rla			;5049
	add hl,hl			;504a
	rla			;504b
	add hl,hl			;504c
	rla			;504d
	ld l,h			;504e
	ld h,a			;504f
	ld a,(0e1a2h)		;5050
	rra			;5053
	call c,L_51BD		;5054
	ld (0e1a8h),hl		;5057
	ld a,(0e1a6h)		;505a
	ld e,a			;505d
	ld a,(0e1a7h)		;505e
	ld h,a			;5061
	call multiplica_h_por_e		;5062
	xor a			;5065
	add hl,hl			;5066
	rla			;5067
	add hl,hl			;5068
	rla			;5069
	add hl,hl			;506a
	rla			;506b
	ld l,h			;506c
	ld h,a			;506d
	ld a,(0e1a2h)		;506e
	and 002h		;5071
	call nz,L_51BD		;5073
	ld (0e1aah),hl		;5076
	ex de,hl			;5079
	ld hl,(0e19ch)		;507a
	ld a,00ah		;507d
	add a,l			;507f
	ld l,a			;5080
	ld (hl),d			;5081
	dec hl			;5082
	ld (hl),e			;5083
	dec hl			;5084
	ld de,(0e1a8h)		;5085
	ld (hl),d			;5089
	dec hl			;508a
	ld (hl),e			;508b
	ld a,(0e1a1h)		;508c
	ld (iy+002h),a		;508f
	ld a,(0e1a5h)		;5092
	ld e,a			;5095
	ld h,018h		;5096
	call multiplica_h_por_e		;5098
	ld (iy+00dh),h		;509b
	ld a,(0e1a6h)		;509e
	ld e,a			;50a1
	ld h,018h		;50a2
	call multiplica_h_por_e		;50a4
	ld (iy+00eh),h		;50a7
	ld h,(ix+001h)		;50aa
	push hl			;50ad
	ld a,(0e1a6h)		;50ae
	ld e,a			;50b1
	call multiplica_h_por_e		;50b2
	xor a			;50b5
	add hl,hl			;50b6
	rla			;50b7
	add hl,hl			;50b8
	rla			;50b9
	add hl,hl			;50ba
	rla			;50bb
	ld l,h			;50bc
	ld h,a			;50bd
	ld (0e1a8h),hl		;50be
	pop hl			;50c1
	ld a,(0e1a5h)		;50c2
	ld e,a			;50c5
	call multiplica_h_por_e		;50c6
	xor a			;50c9
	add hl,hl			;50ca
	rla			;50cb
	add hl,hl			;50cc
	rla			;50cd
	add hl,hl			;50ce
	rla			;50cf
	ld l,h			;50d0
	ld h,a			;50d1
	ld (0e1aah),hl		;50d2
	ld a,(0e1a1h)		;50d5
	ld b,(ix+002h)		;50d8
	cp 040h		;50db
	jr c,L_513C		;50dd
	cp 080h		;50df
	jr c,L_5156		;50e1
	cp 0c0h		;50e3
	jp c,L_5168		;50e5
	sub 060h		;50e8
	ex af,af'			;50ea
	ld a,b			;50eb
	sub 060h		;50ec
	ld b,a			;50ee
	ex af,af'			;50ef
	cp b			;50f0
	ld hl,(0e1a8h)		;50f1
	call nc,L_51BD		;50f4
	ld (0e1a8h),hl		;50f7
	ld hl,(0e1aah)		;50fa
	call nc,L_51BD		;50fd
L_5100:
	ld (0e1aah),hl		;5100
	ret			;5103
L_5104:
	ld hl,(0e194h)		;5104
	ld a,007h		;5107
	add a,l			;5109
	ld l,a			;510a
	ld bc,(0e1a8h)		;510b
	ld de,(0e1aah)		;510f
	ld (hl),c			;5113
	inc hl			;5114
	ld (hl),b			;5115
	inc hl			;5116
	ld (hl),e			;5117
	inc hl			;5118
	ld (hl),d			;5119
	call L_542D		;511a
	ld a,(0e1a5h)		;511d
	ld e,a			;5120
	ld h,018h		;5121
	call multiplica_h_por_e		;5123
	ld a,(0e1a1h)		;5126
	ld (ix+002h),a		;5129
	ld (ix+00dh),h		;512c
	ld a,(0e1a6h)		;512f
	ld e,a			;5132
	ld h,018h		;5133
	call multiplica_h_por_e		;5135
	ld (ix+00eh),h		;5138
	ret			;513b
L_513C:
	add a,060h		;513c
	ex af,af'			;513e
	ld a,b			;513f
	add a,060h		;5140
	ld b,a			;5142
	ex af,af'			;5143
	cp b			;5144
	ld hl,(0e1a8h)		;5145
	call nc,L_51BD		;5148
	ld (0e1a8h),hl		;514b
	ld hl,(0e1aah)		;514e
	call c,L_51BD		;5151
	jr L_5100		;5154
L_5156:
	cp b			;5156
	ld hl,(0e1a8h)		;5157
	call c,L_51BD		;515a
	ld (0e1a8h),hl		;515d
	ld hl,(0e1aah)		;5160
	call c,L_51BD		;5163
	jr L_5100		;5166
L_5168:
	cp b			;5168
	ld hl,(0e1a8h)		;5169
	call c,L_51BD		;516c
	ld (0e1a8h),hl		;516f
	ld hl,(0e1aah)		;5172
	call nc,L_51BD		;5175
	jp L_5100		;5178
L_517B:
	ld a,(de)			;517b
	dec de			;517c
	exx			;517d
	ld h,a			;517e
	exx			;517f
	ld a,(de)			;5180
	dec de			;5181
	exx			;5182
	ld l,a			;5183
	exx			;5184
	ld a,(hl)			;5185
	dec hl			;5186
	exx			;5187
	ld b,a			;5188
	exx			;5189
	ld a,(hl)			;518a
	dec hl			;518b
	exx			;518c
	ld c,a			;518d
	and a			;518e
	sbc hl,bc		;518f
	ret			;5191
L_5192:
	ld hl,(0e19ch)		;5192
	ld de,(0e194h)		;5195
	inc hl			;5199
	inc de			;519a
	ld b,002h		;519b
	call L_51B3		;519d
	ld a,004h		;51a0
	add a,l			;51a2
	ld l,a			;51a3
	ld a,004h		;51a4
	add a,e			;51a6
	ld e,a			;51a7
	ld b,004h		;51a8
	call L_51B3		;51aa
	inc hl			;51ad
	inc hl			;51ae
	inc de			;51af
	inc de			;51b0
	ld b,002h		;51b1
L_51B3:
	ld c,(hl)			;51b3
	ld a,(de)			;51b4
	ld (hl),a			;51b5
	ld a,c			;51b6
	ld (de),a			;51b7
	inc de			;51b8
	inc hl			;51b9
	djnz L_51B3		;51ba
	ret			;51bc
L_51BD:
	ld a,l			;51bd
	cpl			;51be
	ld l,a			;51bf
	ld a,h			;51c0
	cpl			;51c1
	ld h,a			;51c2
	inc hl			;51c3
	ret			;51c4
L_51C5:
	ld de,(0e194h)		;51c5
	ld l,e			;51c9
	ld h,d			;51ca
	ld a,007h		;51cb
	add a,l			;51cd
	ld l,a			;51ce
	inc de			;51cf
	inc de			;51d0
	inc de			;51d1
	ld a,(de)			;51d2
	sub (hl)			;51d3
	ld (de),a			;51d4
	inc hl			;51d5
	inc de			;51d6
	ld a,(de)			;51d7
	sbc a,(hl)			;51d8
	ld (de),a			;51d9
	inc hl			;51da
	inc de			;51db
	ld a,(de)			;51dc
	sub (hl)			;51dd
	ld (de),a			;51de
	inc hl			;51df
	inc de			;51e0
	ld a,(de)			;51e1
	sbc a,(hl)			;51e2
	ld (de),a			;51e3
	ret			;51e4
L_51E5:
	ld hl,(0e194h)		;51e5
	ld de,(0e19ch)		;51e8
	ld b,l			;51ec
	ld c,e			;51ed
	ld a,00fh		;51ee
	add a,l			;51f0
	ld l,a			;51f1
	ld a,00fh		;51f2
	add a,e			;51f4
	ld e,a			;51f5
	ld a,b			;51f6
	add a,010h		;51f7
	ld (de),a			;51f9
	ld a,c			;51fa
	add a,010h		;51fb
	ld (hl),a			;51fd
	ret			;51fe
L_51FF:
	call L_59C8		;51ff
	call L_52E5		;5202
	ld a,(0e19fh)		;5205
	and a			;5208
	jp nz,paso_de_la_fisica		;5209
	ld a,(0e1afh)		;520c
	and a			;520f
	jp nz,L_5AC4		;5210
	ld a,00fh		;5213
	ld (0e17ch),a		;5215
	ld a,(0e003h)		;5218
	and 03fh		;521b
	call z,L_5314		;521d
	ld a,(0e008h)		;5220
	cpl			;5223
	ld b,a			;5224
	ld a,(0e009h)		;5225
	ld c,a			;5228
	and b			;5229
	bit 4,a		;522a
	jp nz,calcula_el_tiro		;522c
	exx			;522f
	ld hl,0e202h		;5230
	and a			;5233
	jr nz,L_5246		;5234
	ld a,(0e003h)		;5236
	and 0ffh		;5239
	jr nz,L_5248		;523b
	dec (hl)			;523d
	jr nz,L_5248		;523e
	ld a,001h		;5240
	ld (0e00ch),a		;5242
	ret			;5245
L_5246:
	ld (hl),000h		;5246
L_5248:
	ld a,(0e174h)		;5248
	ld h,a			;524b
	ld a,(0e176h)		;524c
	ld l,a			;524f
	push hl			;5250
	call L_5B90		;5251
	call L_527C		;5254
	ld a,(0e174h)		;5257
	ld d,a			;525a
	ld a,(0e176h)		;525b
	ld e,a			;525e
	pop hl			;525f
	and a			;5260
	sbc hl,de		;5261
	jr z,L_526E		;5263
	ld a,(0e024h)		;5265
	and a			;5268
	ld a,001h		;5269
	call z,pide_un_sonido		;526b
L_526E:
	exx			;526e
	ld hl,0e1aah		;526f
	ld a,c			;5272
	and a			;5273
	jr nz,L_5279		;5274
	ld (hl),010h		;5276
	ret			;5278
L_5279:
	dec (hl)			;5279
	ret p			;527a
	inc (hl)			;527b
L_527C:
	ld de,(0e1f7h)		;527c
	ld hl,(0e174h)		;5280
	ld a,(0e176h)		;5283
	ld h,a			;5286
	ld a,(0e009h)		;5287
	and a			;528a
	jr nz,L_528F		;528b
	ld d,a			;528d
	ld e,a			;528e
L_528F:
	rra			;528f
	jr nc,L_5294		;5290
	ld e,0ffh		;5292
L_5294:
	rra			;5294
	jr nc,L_5299		;5295
	ld e,001h		;5297
L_5299:
	rra			;5299
	jr nc,L_529E		;529a
	ld d,0ffh		;529c
L_529E:
	rra			;529e
	jr nc,L_52A3		;529f
	ld d,001h		;52a1
L_52A3:
	ld (0e1f7h),de		;52a3
	ld a,h			;52a7
	add a,d			;52a8
	ld d,a			;52a9
	ld a,l			;52aa
	add a,e			;52ab
	ld e,a			;52ac
	ld hl,0e1f9h		;52ad
	bit 0,(hl)		;52b0
	jr z,L_52C7		;52b2
	ld a,d			;52b4
	sub 00eh		;52b5
	jr nz,L_52BA		;52b7
	inc (hl)			;52b9
L_52BA:
	sub 0d4h		;52ba
	jr nc,L_52DA		;52bc
	inc a			;52be
	jr nz,L_52C2		;52bf
	inc (hl)			;52c1
L_52C2:
	ld a,d			;52c2
	ld (0e176h),a		;52c3
	ret			;52c6
L_52C7:
	ld a,e			;52c7
	sub 036h		;52c8
	jr nz,L_52CD		;52ca
	inc (hl)			;52cc
L_52CD:
	sub 074h		;52cd
	jr nc,L_52DA		;52cf
	inc a			;52d1
	jr nz,L_52D5		;52d2
	inc (hl)			;52d4
L_52D5:
	ld a,e			;52d5
	ld (0e174h),a		;52d6
	ret			;52d9
L_52DA:
	inc (hl)			;52da
	ret			;52db

; ----------------------------------------------------------------------
; DATOS rotulo_speed: Los cinco tiles ASCII "SPEED" que 0x5317 copia a VRAM,
;   delante del indicador de fuerza del tiro.
;   0x52dc..0x52e1  (5 bytes)
DATA_rotulo_speed:
	defb 053h,050h,045h,045h,044h	; 52dc

; ----------------------------------------------------------------------
; DATOS rotulo_rest: Los cuatro tiles ASCII "REST" que 0x52E8 copia a VRAM.
;   0x52e1..0x52e5  (4 bytes)
DATA_rotulo_rest:
	defb 052h,045h,053h,054h	; 52e1

; ======================================================================
; CODIGO 0x52e5..0x539c  (183 bytes)
; ======================================================================


L_52E5:
	ld de,03858h		;52e5
	ld hl,052e1h		;52e8
	ld bc,00004h		;52eb
	call copia_a_vram		;52ee
	ld a,(0e053h)		;52f1
	ld b,a			;52f4
	ld a,004h		;52f5
	sub b			;52f7
	ld c,a			;52f8
	ld de,0385ch		;52f9
	call abre_la_vram_para_escribir		;52fc
L_52FF:
	ld a,b			;52ff
	and a			;5300
	jr z,L_530B		;5301
	ld a,05eh		;5303
	exx			;5305
	out (c),a		;5306
	exx			;5308
	djnz L_52FF		;5309
L_530B:
	xor a			;530b
	exx			;530c
	out (c),a		;530d
	exx			;530f
	dec c			;5310
	jr nz,L_530B		;5311
	ret			;5313
L_5314:
	ld de,038c4h		;5314
	ld hl,052dch		;5317
	ld bc,00005h		;531a
	call copia_a_vram		;531d
	ld hl,0e1a0h		;5320
	ld a,(hl)			;5323
	inc a			;5324
	cp 004h		;5325
	jr c,L_532B		;5327
	ld a,001h		;5329
L_532B:
	ld (hl),a			;532b
	ld b,a			;532c
	ld a,004h		;532d
	sub b			;532f
	ld h,a			;5330
	ld de,038c9h		;5331
	ld a,097h		;5334
L_5336:
	call escribe_en_vram		;5336
	inc de			;5339
	djnz L_5336		;533a
	ld a,000h		;533c
L_533E:
	dec h			;533e
	ret m			;533f
	call escribe_en_vram		;5340
	inc de			;5343
	jr L_533E		;5344
multiplica_h_por_e:		; El producto 8x8 del juego: HL = H * E, por desplazamientos y sumas, ocho vueltas.
	ld d,000h		;5346   ; el multiplicando entra en H y el multiplicador en E
	ld l,d			;5348   ; HL empieza a cero, con H haciendo de registro de desplazamiento
	ld b,008h		;5349   ; ocho bits
L_534B:
	add hl,hl			;534b   ; saca el bit de arriba de H y a la vez hace hueco abajo
	jr nc,L_534F		;534c
	add hl,de			;534e   ; si el bit sale a uno, suma
L_534F:
	djnz L_534B		;534f
	ret			;5351
divide_hl_entre_bc:		; La division con resta y restauracion del juego: entra con el dividendo en HL y el divisor en E, y devuelve el cociente en L y el byte bajo del resto en H. Si el cociente no cabe en ocho bits, L sale clavado a 0xFF en vez de dar la vuelta. Es la que saca la pendiente del vector del tiro y las componentes del vector unidad.
	ex de,hl			;5352   ; el dividendo pasa a DE
	ld c,l			;5353   ; y el divisor, que llego en E, a BC
	ld b,000h		;5354
	ld h,b			;5356   ; HL sera el resto
	ld l,b			;5357
	exx			;5358
	ld b,010h		;5359   ; dieciseis vueltas, con el contador en el juego alterno
L_535B:
	exx			;535b
	sla e		;535c   ; el bit de arriba del dividendo
	rl d		;535e
	adc hl,hl		;5360   ; baja al resto
	sbc hl,bc		;5362   ; se prueba a restar
	jr c,L_5369		;5364   ; no cabe: se deshace
	inc e			;5366   ; cabe: un uno al cociente, que va entrando por abajo del propio dividendo
	jr L_536A		;5367
L_5369:
	add hl,bc			;5369
L_536A:
	exx			;536a
	djnz L_535B		;536b
	exx			;536d
	ld h,l			;536e   ; H se queda con el resto
	ld l,e			;536f   ; y L con el cociente
	ld a,d			;5370   ; el cociente no cabia en ocho bits
	and a			;5371
	ret z			;5372
	ld l,0ffh		;5373   ; y entonces sale clavado a 0xFF
	ret			;5375
raiz_cuadrada:		; La raiz cuadrada de HL, por el metodo de los impares: resta 1, luego 0, luego 2 y 2, luego 4 y 4... y devuelve en BC cuantas vueltas ha aguantado. Comprobado sobre los 65536 valores posibles: devuelve exactamente round(sqrt(HL)), la raiz redondeada al entero mas cercano, nunca truncada.
	ld bc,00000h		;5376   ; BC cuenta los impares
	scf			;5379   ; el primer impar es el 1, y el acarreo lo pone
L_537A:
	sbc hl,bc		;537a   ; los impares se restan de dos en dos: 2k+1 = k + (k+1)
	ret c			;537c   ; se paso: BC es la raiz
	sbc hl,bc		;537d
	ret c			;537f
	inc bc			;5380   ; el impar siguiente
	jr L_537A		;5381
coseno_de_la_fuerza:		; Lee la tabla de 0x539C con el indice saturado a 0x40, para el coseno, y con 0x40 menos el indice para el seno
	cp 040h		;5383
	jr c,L_5389		;5385
	ld a,040h		;5387
L_5389:
	ld b,a			;5389
	ld hl,0539ch		;538a
	call suma_a_a_hl		;538d
	ld c,(hl)			;5390
	ld a,040h		;5391
	sub b			;5393
	ld hl,0539ch		;5394
	call suma_a_a_hl		;5397
	ld a,(hl)			;539a
	ret			;539b

; ----------------------------------------------------------------------
; DATOS tabla_de_coseno_de_la_fuerza: Los 65 valores 255*cos(i*90/64 grados),
;   i=0..64 (comprobado numericamente: error maximo 1). La lee 0x5383 con el
;   indice saturado a 0x40, dos veces (i y 64-i), para sacar el coseno y el
;   seno con una sola tabla.
;   0x539c..0x53dd  (65 bytes)
DATA_tabla_de_coseno_de_la_fuerza:
	defb 0ffh,0ffh,0ffh,0ffh,0feh,0feh,0fdh,0fch,0fbh,0f9h,0f8h,0f6h,0f4h,0f3h,0f1h,0eeh	; 539c  ................
	defb 0ech,0eah,0e7h,0e4h,0e1h,0deh,0dbh,0d8h,0d4h,0d1h,0cdh,0c9h,0c5h,0c1h,0bdh,0b9h	; 53ac  ................
	defb 0b5h,0b0h,0abh,0a7h,0a2h,09dh,098h,093h,08eh,088h,083h,07eh,078h,073h,06dh,067h	; 53bc  ...........~xsmg
	defb 061h,05ch,056h,050h,04ah,044h,03eh,038h,031h,02bh,025h,01fh,019h,012h,00ch,006h	; 53cc  a\VPJD>81+%.....
	defb 000h	; 53dc

; ======================================================================
; CODIGO 0x53dd..0x54e6  (265 bytes)
; ======================================================================


L_53DD:
	ld a,(0e003h)		;53dd
	and 007h		;53e0
	ret nz			;53e2
L_53E3:
	ld hl,(0e194h)		;53e3
	inc hl			;53e6
	ld a,(hl)			;53e7
	sub 003h		;53e8
	jr nc,L_53ED		;53ea
	xor a			;53ec
L_53ED:
	ld (hl),a			;53ed
	ld a,00ch		;53ee
	call suma_a_a_hl		;53f0
	ld c,(hl)			;53f3
	inc hl			;53f4
	ld b,(hl)			;53f5
	ld hl,(0e194h)		;53f6
	ld a,007h		;53f9
	call suma_a_a_hl		;53fb
	ld e,(hl)			;53fe
	inc hl			;53ff
	ld d,(hl)			;5400
	ex de,hl			;5401
	ld a,b			;5402
	ld b,000h		;5403
	bit 7,h		;5405
	push af			;5407
	call z,L_5425		;5408
	pop af			;540b
	add hl,bc			;540c
	ex de,hl			;540d
	ld (hl),d			;540e
	dec hl			;540f
	ld (hl),e			;5410
	inc hl			;5411
	inc hl			;5412
	ld e,(hl)			;5413
	inc hl			;5414
	ld d,(hl)			;5415
	ex de,hl			;5416
	ld b,000h		;5417
	ld c,a			;5419
	bit 7,h		;541a
	call z,L_5425		;541c
	add hl,bc			;541f
	ex de,hl			;5420
	ld (hl),d			;5421
	dec hl			;5422
	ld (hl),e			;5423
	ret			;5424
L_5425:
	ld a,c			;5425
	cpl			;5426
	ld c,a			;5427
	ld a,b			;5428
	cpl			;5429
	ld b,a			;542a
	inc bc			;542b
	ret			;542c
L_542D:
	ld hl,(0e194h)		;542d
saca_la_pendiente_del_vector:		; Toma la velocidad de la bola que apunta HL (+7 la componente Y, +9 la X, las dos de 16 bits con signo), se queda con los valores absolutos y apunta los dos espejos en 0xE1A2 (bit 0 = la Y iba hacia arriba, bit 1 = la X hacia la izquierda), divide las dos por 32 y compara: la mayor pasa a ser el divisor y la menor el dividendo, de modo que la pendiente que sale de la division siempre cae entre 0 y 255. Asi el juego guarda una direccion como un octante mas una pendiente, y le basta con tablas de 256 entradas.
	ld a,007h		;5430
	call suma_a_a_hl		;5432
	ld e,(hl)			;5435
	inc hl			;5436
	ld d,(hl)			;5437
	inc hl			;5438
	ld c,(hl)			;5439
	inc hl			;543a
	ld b,(hl)			;543b
	xor a			;543c
	bit 7,d		;543d
	jr z,L_5449		;543f
	ex de,hl			;5441
	ex af,af'			;5442
	call L_51BD		;5443
	ex de,hl			;5446
	ex af,af'			;5447
	inc a			;5448
L_5449:
	bit 7,b		;5449
	jr z,L_5454		;544b
	ex af,af'			;544d
	call L_5425		;544e
	ex af,af'			;5451
	or 002h		;5452
L_5454:
	ld (0e1a2h),a		;5454
	rr d		;5457
	rr e		;5459
	rr d		;545b
	rr e		;545d
	rr d		;545f
	rr e		;5461
	rr d		;5463
	rr e		;5465
	rr d		;5467
	rr e		;5469
	ld a,c			;546b
	rr b		;546c
	rra			;546e
	rr b		;546f
	rra			;5471
	rr b		;5472
	rra			;5474
	rr b		;5475
	rra			;5477
	rr b		;5478
	rra			;547a
	cp e			;547b
	jr c,L_54E0		;547c
	ld h,e			;547e
	ld e,a			;547f
	xor a			;5480
	ld l,a			;5481
convierte_pendiente_en_vector:		; Con la pendiente (0xE1A3/0xE1A4) lee las cuatro tablas de 0x54E6: deja las componentes en 0xE1A5/0xE1A6 y el angulo del tiro en 0xE1A1, con los reflejos de 0xE1A2
	ld (0e1a4h),a		;5482
	call divide_hl_entre_bc		;5485
	ld a,r		;5488
	and 001h		;548a
	xor l			;548c
	ld (0e1a3h),a		;548d
	ld a,(0e1a4h)		;5490
	ld d,a			;5493
	ld hl,054e6h		;5494
	add a,h			;5497
	ld h,a			;5498
	ld a,(0e1a3h)		;5499
	ld e,a			;549c
	call suma_a_a_hl		;549d
	ld a,(hl)			;54a0
	ld (0e1a5h),a		;54a1
	ld a,d			;54a4
	ld hl,055e6h		;54a5
	rra			;54a8
	jr nc,L_54AE		;54a9
	ld hl,054e6h		;54ab
L_54AE:
	ld a,e			;54ae
	call suma_a_a_hl		;54af
	ld a,(hl)			;54b2
	ld (0e1a6h),a		;54b3
	ld a,d			;54b6
	ld hl,056e6h		;54b7
	rra			;54ba
	jr nc,L_54C0		;54bb
	ld hl,05726h		;54bd
L_54C0:
	ld a,e			;54c0
	srl a		;54c1
	srl a		;54c3
	call suma_a_a_hl		;54c5
	ld b,(hl)			;54c8
	ld a,(0e1a2h)		;54c9
	ld c,000h		;54cc
	bit 1,a		;54ce
	jr z,L_54D4		;54d0
	ld c,080h		;54d2
L_54D4:
	and a			;54d4
	ld a,b			;54d5
	jp pe,L_54DB		;54d6
	neg		;54d9
L_54DB:
	add a,c			;54db
	ld (0e1a1h),a		;54dc
	ret			;54df
L_54E0:
	ld h,a			;54e0
	xor a			;54e1
	ld l,a			;54e2
	inc a			;54e3
	jr convierte_pendiente_en_vector		;54e4

; ----------------------------------------------------------------------
; DATOS tabla_de_seno_por_pendiente: 256 valores: 255*sin(atan(p)) con p=i/255
;   (error maximo 1, comprobado). El movimiento guarda la direccion como
;   PENDIENTE dentro de un octante (el cociente dy/dx que saca la division de
;   0x5352) mas los reflejos en 0xE1A2; esta tabla da la componente mayor del
;   vector unidad, escalada a 255.
;   0x54e6..0x55e6  (256 bytes)
DATA_tabla_de_seno_por_pendiente:
	defb 000h,001h,002h,003h,004h,005h,006h,007h,008h,009h,00ah,00bh,00ch,00dh,00eh,00fh	; 54e6  ................
	defb 010h,011h,012h,013h,014h,015h,016h,017h,018h,019h,01ah,01bh,01ch,01dh,01eh,01fh	; 54f6  ................
	defb 020h,021h,022h,023h,024h,025h,026h,027h,028h,029h,029h,02ah,02bh,02ch,02dh,02eh	; 5506   !"#$%&'())*+,-.
	defb 02fh,030h,031h,032h,032h,033h,034h,035h,036h,037h,038h,039h,03ah,03bh,03ch,03dh	; 5516  /01223456789:;<=
	defb 03eh,03fh,03fh,040h,041h,042h,043h,044h,045h,046h,047h,047h,048h,049h,04ah,04bh	; 5526  >??@ABCDEFGGHIJK
	defb 04ch,04dh,04eh,04eh,04fh,050h,051h,052h,053h,054h,054h,055h,056h,057h,058h,059h	; 5536  LMNNOPQRSTTUVWXY
	defb 059h,05ah,05bh,05ch,05dh,05dh,05eh,05fh,060h,061h,061h,062h,063h,064h,065h,065h	; 5546  YZ[\]]^_`aabcdee
	defb 066h,067h,068h,068h,069h,06ah,06bh,06bh,06ch,06dh,06eh,06eh,06fh,070h,071h,071h	; 5556  fghhijkklmnnopqq
	defb 072h,073h,073h,074h,075h,076h,076h,077h,078h,078h,079h,07ah,07ah,07bh,07ch,07ch	; 5566  rsstuvvwxxyzz{||
	defb 07dh,07eh,07eh,07fh,080h,080h,081h,082h,082h,083h,083h,084h,085h,085h,086h,087h	; 5576  }~~.............
	defb 087h,088h,088h,089h,08ah,08ah,08bh,08bh,08ch,08dh,08dh,08eh,08eh,08fh,08fh,090h	; 5586  ................
	defb 091h,091h,092h,092h,093h,093h,094h,094h,095h,095h,096h,097h,097h,098h,098h,099h	; 5596  ................
	defb 099h,09ah,09ah,09bh,09bh,09ch,09ch,09dh,09dh,09eh,09eh,09fh,09fh,0a0h,0a0h,0a0h	; 55a6  ................
	defb 0a1h,0a1h,0a2h,0a2h,0a3h,0a3h,0a4h,0a4h,0a5h,0a5h,0a5h,0a6h,0a6h,0a7h,0a7h,0a8h	; 55b6  ................
	defb 0a8h,0a9h,0a9h,0a9h,0aah,0aah,0abh,0abh,0abh,0ach,0ach,0adh,0adh,0adh,0aeh,0aeh	; 55c6  ................
	defb 0afh,0afh,0afh,0b0h,0b0h,0b1h,0b1h,0b1h,0b2h,0b2h,0b2h,0b3h,0b3h,0b3h,0b4h,0b4h	; 55d6  ................

; ----------------------------------------------------------------------
; DATOS tabla_de_coseno_por_pendiente: 256 valores: 255*cos(atan(p)) con
;   p=i/255 (error maximo 1). La pareja de la anterior: 0x5482 lee las dos
;   para montar (0xE1A5, 0xE1A6), las componentes del vector de velocidad.
;   0x55e6..0x56e6  (256 bytes)
DATA_tabla_de_coseno_por_pendiente:
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 55e6  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0feh,0feh,0feh,0feh,0feh,0feh,0feh,0feh,0feh	; 55f6  ................
	defb 0feh,0fdh,0fdh,0fdh,0fdh,0fdh,0fdh,0fdh,0fch,0fch,0fch,0fch,0fch,0fch,0fbh,0fbh	; 5606  ................
	defb 0fbh,0fbh,0fbh,0fbh,0fah,0fah,0fah,0fah,0fah,0f9h,0f9h,0f9h,0f9h,0f9h,0f8h,0f8h	; 5616  ................
	defb 0f8h,0f8h,0f7h,0f7h,0f7h,0f7h,0f6h,0f6h,0f6h,0f6h,0f5h,0f5h,0f5h,0f5h,0f4h,0f4h	; 5626  ................
	defb 0f4h,0f4h,0f3h,0f3h,0f3h,0f2h,0f2h,0f2h,0f2h,0f1h,0f1h,0f1h,0f0h,0f0h,0f0h,0f0h	; 5636  ................
	defb 0efh,0efh,0efh,0eeh,0eeh,0eeh,0edh,0edh,0edh,0ech,0ech,0ech,0ebh,0ebh,0ebh,0eah	; 5646  ................
	defb 0eah,0eah,0e9h,0e9h,0e9h,0e8h,0e8h,0e8h,0e7h,0e7h,0e7h,0e6h,0e6h,0e6h,0e5h,0e5h	; 5656  ................
	defb 0e4h,0e4h,0e4h,0e3h,0e3h,0e3h,0e2h,0e2h,0e2h,0e1h,0e1h,0e0h,0e0h,0e0h,0dfh,0dfh	; 5666  ................
	defb 0dfh,0deh,0deh,0deh,0ddh,0ddh,0dch,0dch,0dch,0dbh,0dbh,0dah,0dah,0dah,0d9h,0d9h	; 5676  ................
	defb 0d9h,0d8h,0d8h,0d7h,0d7h,0d7h,0d6h,0d6h,0d6h,0d5h,0d5h,0d4h,0d4h,0d4h,0d3h,0d3h	; 5686  ................
	defb 0d2h,0d2h,0d2h,0d1h,0d1h,0d1h,0d0h,0d0h,0cfh,0cfh,0cfh,0ceh,0ceh,0cdh,0cdh,0cdh	; 5696  ................
	defb 0cbh,0cch,0cch,0cbh,0cbh,0cah,0cah,0cah,0c9h,0c9h,0c8h,0c8h,0c8h,0c7h,0c7h,0c7h	; 56a6  ................
	defb 0c6h,0c6h,0c5h,0c5h,0c5h,0c4h,0c4h,0c4h,0c3h,0c3h,0c2h,0c2h,0c2h,0c1h,0c1h,0c1h	; 56b6  ................
	defb 0c0h,0c0h,0bfh,0bfh,0bfh,0beh,0beh,0beh,0bdh,0bdh,0bch,0bch,0bch,0bbh,0bbh,0bbh	; 56c6  ................
	defb 0bah,0bah,0bah,0b9h,0b9h,0b8h,0b8h,0b8h,0b7h,0b7h,0b7h,0b6h,0b6h,0b6h,0b5h,0b5h	; 56d6  ................

; ----------------------------------------------------------------------
; DATOS tabla_de_angulo_por_pendiente: 64 valores: atan(i*4/255) en 1/256 de
;   vuelta (0x00-0x20, error maximo 1). Convierte la pendiente en el angulo
;   que se guarda en 0xE1A1 (con los bits de espejo encima): el angulo
;   redondeado del tiro.
;   0x56e6..0x5726  (64 bytes)
DATA_tabla_de_angulo_por_pendiente:
	defb 000h,001h,001h,002h,003h,003h,004h,004h,005h,006h,006h,007h,008h,008h,009h,009h	; 56e6  ................
	defb 00ah,00bh,00bh,00ch,00ch,00dh,00dh,00eh,00fh,00fh,010h,010h,011h,011h,012h,012h	; 56f6  ................
	defb 013h,013h,014h,014h,015h,015h,016h,016h,017h,017h,018h,018h,019h,019h,019h,01ah	; 5706  ................
	defb 01ah,01bh,01bh,01bh,01ch,01ch,01dh,01dh,01dh,01eh,01eh,01eh,01fh,01fh,01fh,020h	; 5716  ............... 

; ----------------------------------------------------------------------
; DATOS tabla_de_angulo_complementario: Los mismos 64 valores restados de
;   0x40: el angulo cuando la pendiente se midio contra el otro eje (la rama
;   de 0x54BD).
;   0x5726..0x5766  (64 bytes)
DATA_tabla_de_angulo_complementario:
	defb 040h,03fh,03eh,03dh,03ch,03ch,03ch,03bh,03ah,03ah,039h,038h,038h,037h,037h,036h	; 5726  @?>=<<<;::988776
	defb 035h,035h,034h,034h,033h,033h,032h,031h,031h,030h,030h,02fh,02fh,02eh,02eh,02dh	; 5736  55443321100//..-
	defb 02dh,02ch,02ch,02bh,02bh,02ah,02ah,029h,029h,028h,028h,027h,027h,027h,026h,026h	; 5746  -,,++**))(('''&&
	defb 025h,025h,025h,024h,024h,023h,023h,023h,022h,022h,022h,021h,021h,021h,020h,020h	; 5756  %%%$$###"""!!!  

; ======================================================================
; CODIGO 0x5766..0x5788  (34 bytes)
; ======================================================================


carga_los_tiles_del_rotulo_grande:		; Copia 0x5788 a los patrones 0x2600: el apostrofe blanco y las letras verdes del BILLIARDS
	ld de,02600h		;5766
	ld hl,05788h		;5769
	ld bc,000f8h		;576c
	call copia_a_vram		;576f
	ld de,00600h		;5772
	ld bc,00008h		;5775
	ld a,0f0h		;5778
	call rellena_vram		;577a
	ld de,00608h		;577d
	ld bc,000f0h		;5780
	ld a,0c0h		;5783
	jp rellena_vram		;5785

; ----------------------------------------------------------------------
; DATOS tiles_del_rotulo_del_titulo: Los 31 patrones (0xF8 bytes) que 0x5766
;   copia a VRAM 0x2600: los tiles 0xC0-0xDE. El 0xC0 es el apostrofe de
;   "KONAMI'S" (color 0xF0, blanco); los tiles 0xC1-0xDE son las letras
;   grandes del logo BILLIARDS, en verde (color 0xC0), que la animacion del
;   titulo (0x48B8) va soltando de una en una en las filas 5 y 6.
;   0x5788..0x5880  (248 bytes)
DATA_tiles_del_rotulo_del_titulo:
	defb 000h,018h,018h,008h,010h,000h,000h,000h	; 5788  ........
	defb 00fh,03fh,07fh,0ffh,0f8h,0f1h,0f3h,0fbh	; 5790  .?......
	defb 0ffh,0ffh,0ffh,0ffh,007h,0c3h,0e7h,0ffh	; 5798  ........
	defb 007h,0cfh,0efh,0efh,0efh,0efh,0cfh,08fh	; 57a0  ........
	defb 01ch,0beh,0beh,0beh,0beh,0beh,0beh,0beh	; 57a8  ........
	defb 001h,003h,003h,003h,003h,003h,003h,003h	; 57b0  ........
	defb 0c0h,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h	; 57b8  ........
	defb 01ch,03eh,03eh,03eh,03eh,03eh,03eh,03eh	; 57c0  .>>>>>>>
	defb 003h,007h,007h,00fh,00fh,01fh,01eh,03ch	; 57c8  .......<
	defb 080h,0c0h,0c0h,0e0h,0e0h,0f0h,0f0h,078h	; 57d0  .......x
	defb 07fh,0ffh,0ffh,0ffh,0f8h,0f8h,0ffh,0ffh	; 57d8  ........
	defb 0e1h,0f3h,0f3h,0fbh,07bh,07bh,0fbh,0fbh	; 57e0  ....{{..
	defb 0ffh,0ffh,0ffh,0ffh,0e3h,0e1h,0e1h,0e1h	; 57e8  ........
	defb 000h,0c1h,0e3h,0e3h,0f3h,0f3h,0f3h,0f1h	; 57f0  ........
	defb 07fh,0ffh,0ffh,0e3h,0c1h,0e0h,0fch,0ffh	; 57f8  ........
	defb 000h,080h,0c0h,0c0h,080h,000h,000h,080h	; 5800  ........
	defb 07bh,033h,003h,003h,003h,003h,003h,001h	; 5808  {3......
	defb 0ffh,0ffh,0e7h,0e3h,0e7h,0ffh,0ffh,0ffh	; 5810  ........
	defb 08fh,0cfh,0efh,0efh,0efh,0efh,0cfh,087h	; 5818  ........
	defb 0beh,0beh,0beh,0bfh,0bfh,0bfh,0bfh,01fh	; 5820  ........
	defb 003h,003h,003h,0f3h,0fbh,0fbh,0fbh,0f1h	; 5828  ........
	defb 0e0h,0e0h,0e0h,0ffh,0ffh,0ffh,0ffh,0ffh	; 5830  ........
	defb 03eh,03eh,03eh,03eh,0beh,0beh,0beh,01ch	; 5838  >>>>....
	defb 03ch,07fh,07fh,0ffh,0ffh,0f0h,0f0h,060h	; 5840  <......`
	defb 078h,0fch,0fch,0feh,0feh,01eh,01eh,00ch	; 5848  x.......
	defb 0ffh,0ffh,0ffh,0ffh,0fbh,0f9h,0f8h,070h	; 5850  .......p
	defb 0f3h,0c3h,0e3h,0f3h,0fbh,0fbh,07bh,031h	; 5858  ......{1
	defb 0e1h,0e1h,0e1h,0e3h,0ffh,0ffh,0ffh,0ffh	; 5860  ........
	defb 0f0h,0f0h,0f3h,0f7h,0e7h,0e7h,0c3h,000h	; 5868  ........
	defb 07fh,007h,083h,0c3h,0ffh,0ffh,0ffh,0ffh	; 5870  ........
	defb 0c0h,0c0h,0e0h,0e0h,0e0h,0e0h,0c0h,000h	; 5878  ........

; ======================================================================
; CODIGO 0x5880..0x5acd  (589 bytes)
; ======================================================================


L_5880:
	ld a,c			;5880
	cp 076h		;5881
	jp c,L_5911		;5883
L_5886:
	ld a,b			;5886
	sub c			;5887
	cp 058h		;5888
	jp c,L_5980		;588a
	ld a,b			;588d
	add a,c			;588e
	cp 00dh		;588f
	jp c,L_593B		;5891
	cp 01eh		;5894
	jp nc,L_593B		;5896
	ret			;5899
L_589A:
	ld a,c			;589a
	cp 076h		;589b
	jr c,L_58B9		;589d
L_589F:
	ld a,b			;589f
	add a,c			;58a0
	cp 088h		;58a1
	jp nc,L_5980		;58a3
	ld a,b			;58a6
	sub c			;58a7
	cp 0c4h		;58a8
	jp c,L_5923		;58aa
	cp 0d3h		;58ad
	jp nc,L_5923		;58af
	ret			;58b2
L_58B3:
	ld a,b			;58b3
	cp 070h		;58b4
	jp c,L_5911		;58b6
L_58B9:
	ld a,b			;58b9
	sub c			;58ba
	cp 098h		;58bb
	jp nc,L_5980		;58bd
	ld a,b			;58c0
	add a,c			;58c1
	cp 0b1h		;58c2
	jp c,L_593B		;58c4
	cp 0c1h		;58c7
	jp nc,L_593B		;58c9
	ret			;58cc
L_58CD:
	ld a,b			;58cd
	sub 02eh		;58ce
	cp 084h		;58d0
	jp nc,L_5980		;58d2
	ld a,c			;58d5
	ld l,(ix+009h)		;58d6
	ld h,(ix+00ah)		;58d9
	cp 074h		;58dc
	jr nc,L_58E8		;58de
	ex af,af'			;58e0
	ld a,(ix+00ah)		;58e1
	and a			;58e4
	ret p			;58e5
	jr L_58F0		;58e6
L_58E8:
	cp 07ch		;58e8
	ret c			;58ea
	ld a,(ix+00ah)		;58eb
	and a			;58ee
	ret m			;58ef
L_58F0:
	call L_51BD		;58f0
	ld (ix+009h),l		;58f3
	ld (ix+00ah),h		;58f6
	call L_542D		;58f9
	ld a,(0e1a1h)		;58fc
	ld (ix+002h),a		;58ff
	call L_53E3		;5902
	jp L_4F14		;5905
L_5908:
	ld a,b			;5908
	cp 070h		;5909
	jp c,L_5886		;590b
	jp L_589F		;590e
L_5911:
	ld a,b			;5911
	add a,c			;5912
	cp 048h		;5913
	jp c,L_5980		;5915
	ld a,b			;5918
	sub c			;5919
	cp 01fh		;591a
	jr c,L_5923		;591c
	cp 031h		;591e
	jr nc,L_5923		;5920
	ret			;5922
L_5923:
	ld hl,(0e194h)		;5923
	ld a,007h		;5926
	call suma_a_a_hl		;5928
	ld b,(hl)			;592b
	inc hl			;592c
	ld c,(hl)			;592d
	inc hl			;592e
	ld d,(hl)			;592f
	ld (hl),b			;5930
	inc hl			;5931
	ld e,(hl)			;5932
	ld (hl),c			;5933
	dec hl			;5934
	dec hl			;5935
	ld (hl),e			;5936
	dec hl			;5937
	ld (hl),d			;5938
	jr L_5959		;5939
L_593B:
	ld l,(ix+007h)		;593b
	ld h,(ix+008h)		;593e
	ld c,(ix+009h)		;5941
	ld b,(ix+00ah)		;5944
	call L_51BD		;5947
	call L_5425		;594a
	ld (ix+007h),c		;594d
	ld (ix+008h),b		;5950
	ld (ix+009h),l		;5953
	ld (ix+00ah),h		;5956
L_5959:
	call L_542D		;5959
	ld a,(0e1a1h)		;595c
	ld (ix+002h),a		;595f
	ld (ix+002h),a		;5962
	ld a,(0e1a5h)		;5965
	ld e,a			;5968
	ld h,018h		;5969
	call multiplica_h_por_e		;596b
	ld (ix+00dh),h		;596e
	ld a,(0e1a6h)		;5971
	ld e,a			;5974
	ld h,018h		;5975
	call multiplica_h_por_e		;5977
	ld (ix+00eh),h		;597a
	jp L_4F14		;597d
L_5980:
	ld a,(0e1adh)		;5980
	and a			;5983
	ld a,004h		;5984
	call z,pide_un_sonido		;5986
	ld a,(0e194h)		;5989
	and a			;598c
	ld a,005h		;598d
	call z,pide_un_sonido		;598f
	ld hl,0e1aeh		;5992
	ld a,(hl)			;5995
	cp 005h		;5996
	jr z,L_599B		;5998
	inc (hl)			;599a
L_599B:
	ld hl,(0e194h)		;599b
	xor a			;599e
	ld (hl),a			;599f
	inc hl			;59a0
	ld (hl),a			;59a1
	inc hl			;59a2
	inc hl			;59a3
	inc hl			;59a4
	ld (hl),0e0h		;59a5
	ld hl,0e1d7h		;59a7
	ld de,0e1d0h		;59aa
L_59AD:
	ld a,(de)			;59ad
	and a			;59ae
	jr z,L_59B4		;59af
	inc de			;59b1
	jr L_59AD		;59b2
L_59B4:
	ld a,(0e194h)		;59b4
	and a			;59b7
	jr nz,L_59BF		;59b8
	inc a			;59ba
	ld (0e1adh),a		;59bb
	ret			;59be
L_59BF:
	ld (de),a			;59bf
	ld b,a			;59c0
L_59C1:
	ld a,(hl)			;59c1
	and a			;59c2
	inc hl			;59c3
	jr nz,L_59C1		;59c4
	dec hl			;59c6
	ld (hl),b			;59c7
L_59C8:
	ld de,03893h		;59c8
	ld bc,0e1d7h		;59cb
	ld a,(00007h)		;59ce
	exx			;59d1
	ld c,a			;59d2
	ld b,006h		;59d3
L_59D5:
	exx			;59d5
	ld a,(bc)			;59d6
	and a			;59d7
	jr z,L_5A10		;59d8
	inc bc			;59da
	rrca			;59db
	rrca			;59dc
	add a,098h		;59dd
	ld h,a			;59df
	call abre_la_vram_para_escribir		;59e0
	ld a,h			;59e3
	exx			;59e4
	out (c),a		;59e5
	exx			;59e7
	push hl			;59e8
	pop hl			;59e9
	inc a			;59ea
	inc a			;59eb
	exx			;59ec
	out (c),a		;59ed
	exx			;59ef
	dec a			;59f0
	ld hl,00020h		;59f1
	add hl,de			;59f4
	ex de,hl			;59f5
	ld h,a			;59f6
	call abre_la_vram_para_escribir		;59f7
	ld a,h			;59fa
	exx			;59fb
	out (c),a		;59fc
	exx			;59fe
	inc a			;59ff
	inc a			;5a00
	push hl			;5a01
	pop hl			;5a02
	exx			;5a03
	out (c),a		;5a04
	exx			;5a06
	ld hl,0ffe2h		;5a07
	add hl,de			;5a0a
	ex de,hl			;5a0b
	exx			;5a0c
	djnz L_59D5		;5a0d
	ret			;5a0f
L_5A10:
	ld a,(00007h)		;5a10
	ld c,a			;5a13
	ld b,000h		;5a14
	di			;5a16
L_5A17:
	call abre_la_vram_para_escribir		;5a17
	out (c),b		;5a1a
	push hl			;5a1c
	pop hl			;5a1d
	out (c),b		;5a1e
	ld hl,00020h		;5a20
	add hl,de			;5a23
	ex de,hl			;5a24
	call abre_la_vram_para_escribir		;5a25
	out (c),b		;5a28
	push hl			;5a2a
	pop hl			;5a2b
	out (c),b		;5a2c
	ld hl,0ffe2h		;5a2e
	add hl,de			;5a31
	ex de,hl			;5a32
	exx			;5a33
	dec b			;5a34
	exx			;5a35
	jr nz,L_5A17		;5a36
	ei			;5a38
	ret			;5a39
ensena_el_rate:		; El cartel del multiplicador de la apuesta
	ld hl,0e1d0h		;5a3a
	ld de,0e1d7h		;5a3d
	ld c,(hl)			;5a40
	ld b,007h		;5a41
L_5A43:
	ld a,(de)			;5a43
	inc de			;5a44
	dec b			;5a45
	cp c			;5a46
	jr nz,L_5A43		;5a47
	dec de			;5a49
	xor a			;5a4a
L_5A4B:
	ld (de),a			;5a4b
	inc de			;5a4c
	djnz L_5A4B		;5a4d
	ld a,(hl)			;5a4f
	and a			;5a50
	jr z,L_5A77		;5a51
L_5A53:
	exx			;5a53
	ld bc,07090h		;5a54
	call L_5A99		;5a57
	ld a,b			;5a5a
	exx			;5a5b
	ld b,a			;5a5c
	exx			;5a5d
	ld a,c			;5a5e
	exx			;5a5f
	ld c,a			;5a60
	ld a,(hl)			;5a61
	ld (hl),000h		;5a62
	ld d,0e1h		;5a64
	ld e,a			;5a66
	ex de,hl			;5a67
	ld (hl),0ffh		;5a68
	add a,004h		;5a6a
	ld l,a			;5a6c
	ld (hl),b			;5a6d
	inc hl			;5a6e
	inc hl			;5a6f
	ld (hl),c			;5a70
	ex de,hl			;5a71
	inc hl			;5a72
	ld a,(hl)			;5a73
	and a			;5a74
	jr nz,L_5A53		;5a75
L_5A77:
	ld bc,07040h		;5a77
	ld hl,0e100h		;5a7a
	ld (hl),0ffh		;5a7d
	call L_5A99		;5a7f
	ld (hl),b			;5a82
	inc hl			;5a83
	inc hl			;5a84
	ld (hl),c			;5a85
	xor a			;5a86
	ld (0e1adh),a		;5a87
	ret			;5a8a
L_5A8B:
	ld a,c			;5a8b
	add a,008h		;5a8c
	ld c,a			;5a8e
	cp 0c1h		;5a8f
	jr c,L_5A97		;5a91
	ld c,090h		;5a93
	inc b			;5a95
	inc b			;5a96
L_5A97:
	jr L_5A9C		;5a97
L_5A99:
	add a,004h		;5a99
	ld l,a			;5a9b
L_5A9C:
	ld de,0e104h		;5a9c
L_5A9F:
	ld a,l			;5a9f
	cp e			;5aa0
	jr z,L_5ABB		;5aa1
	ld a,(de)			;5aa3
	inc e			;5aa4
	inc e			;5aa5
	sub b			;5aa6
	jr nc,L_5AAB		;5aa7
	neg		;5aa9
L_5AAB:
	cp 00ch		;5aab
	jr nc,L_5AB9		;5aad
	ld a,(de)			;5aaf
	sub c			;5ab0
	jr nc,L_5AB5		;5ab1
	neg		;5ab3
L_5AB5:
	cp 00ch		;5ab5
	jr c,L_5A8B		;5ab7
L_5AB9:
	dec e			;5ab9
	dec e			;5aba
L_5ABB:
	ld a,010h		;5abb
	add a,e			;5abd
	ld e,a			;5abe
	cp 070h		;5abf
	jr c,L_5A9F		;5ac1
	ret			;5ac3
L_5AC4:
	ld a,(0e1b0h)		;5ac4
	ld hl,05acdh		;5ac7
	call despachador		;5aca

; ----------------------------------------------------------------------
; DATOS tabla_de_la_animacion_del_rate: Las tres palabras del despachador,
;   detras del `call` de 0x5ACA: las fases de aparecer, esperar y borrar del
;   rotulo del multiplicador (el indice esta en 0xE1B0).
;   0x5acd..0x5ad3  (6 bytes)
DATA_tabla_de_la_animacion_del_rate:
	defb 0d3h,05ah	; 5acd
	defb 0dfh,05ah	; 5acf
	defb 073h,05bh	; 5ad1

; ======================================================================
; CODIGO 0x5ad3..0x5b85  (178 bytes)
; ======================================================================


L_5AD3:
	ld hl,0e1d0h		;5ad3
	ld (0e1b2h),hl		;5ad6
	ld a,001h		;5ad9
	ld (0e1b0h),a		;5adb
	ret			;5ade
L_5ADF:
	ld hl,(0e1b2h)		;5adf
	ld a,(0e1aeh)		;5ae2
	ld b,a			;5ae5
	ld a,(hl)			;5ae6
	and a			;5ae7
	jr nz,L_5AF0		;5ae8
	ld (0e1afh),a		;5aea
	jp mira_si_la_mesa_esta_limpia		;5aed
L_5AF0:
	rrca			;5af0
	rrca			;5af1
	rrca			;5af2
	rrca			;5af3
	ld c,a			;5af4
	add a,030h		;5af5
	ld (0e1b4h),a		;5af7
	ld a,c			;5afa
	inc hl			;5afb
	ld (0e1b2h),hl		;5afc
L_5AFF:
	dec b			;5aff
	jr z,L_5B06		;5b00
	add a,a			;5b02
	daa			;5b03
	jr L_5AFF		;5b04
L_5B06:
	ld (0e1b5h),a		;5b06
	ld d,a			;5b09
	ld e,000h		;5b0a
	call suma_al_marcador		;5b0c
	ld a,(0e1b4h)		;5b0f
	ld de,0386ah		;5b12
	call escribe_en_vram		;5b15
	inc de			;5b18
	ld hl,05b85h		;5b19
	ld bc,00005h		;5b1c
	call copia_a_vram		;5b1f
	exx			;5b22
	ld a,c			;5b23
	exx			;5b24
	ld c,a			;5b25
	ld a,(0e1aeh)		;5b26
	ld hl,05b89h		;5b29
	call suma_a_a_hl		;5b2c
	ld a,(hl)			;5b2f
	ld b,a			;5b30
	rra			;5b31
	rra			;5b32
	rra			;5b33
	rra			;5b34
	and 00fh		;5b35
	jr z,L_5B3D		;5b37
	add a,030h		;5b39
	out (c),a		;5b3b
L_5B3D:
	ld a,b			;5b3d
	and 00fh		;5b3e
	add a,030h		;5b40
	out (c),a		;5b42
	ld a,0b8h		;5b44
	nop			;5b46
	out (c),a		;5b47
	ld a,(0e1b5h)		;5b49
	rra			;5b4c
	rra			;5b4d
	rra			;5b4e
	rra			;5b4f
	and 00fh		;5b50
	jr z,L_5B56		;5b52
	add a,030h		;5b54
L_5B56:
	out (c),a		;5b56
	ld a,(0e1b5h)		;5b58
	and 00fh		;5b5b
	add a,030h		;5b5d
	out (c),a		;5b5f
	ld a,030h		;5b61
	nop			;5b63
	out (c),a		;5b64
	push hl			;5b66
	pop hl			;5b67
	out (c),a		;5b68
	ld hl,0e1b0h		;5b6a
	inc (hl)			;5b6d
	inc hl			;5b6e
	ld a,080h		;5b6f
	ld (hl),a			;5b71
	ret			;5b72
L_5B73:
	ld hl,0e1b1h		;5b73
	dec (hl)			;5b76
	ret nz			;5b77
	dec hl			;5b78
	dec (hl)			;5b79
	ld de,0386ah		;5b7a
	ld bc,0000dh		;5b7d
	ld a,000h		;5b80
	jp rellena_vram		;5b82

; ----------------------------------------------------------------------
; DATOS rotulo_x100: Los cinco tiles "|100|" (0xB9 "1" "0" "0" 0xB9) que
;   0x5B19 copia a la fila 3 tras el tile del multiplicador: el cartel "n x
;   100" de los puntos de la bola embocada.
;   0x5b85..0x5b8a  (5 bytes)
DATA_rotulo_x100:
	defb 0b9h,031h,030h,030h,0b9h	; 5b85

; ----------------------------------------------------------------------
; DATOS multiplicadores_del_rate: Los seis valores BCD del multiplicador de
;   puntos, indexados por (0xE1AE): 1, 2, 4, 8, 16 y 16. Los lee 0x5B29 para
;   el cartel y 0x5B9F para la pantalla de RATE. El byte anterior (0xB9, el
;   final del rotulo) hace de tope.
;   0x5b8a..0x5b90  (6 bytes)
DATA_multiplicadores_del_rate:
	defb 001h,002h,004h,008h,016h,016h	; 5b8a

; ======================================================================
; CODIGO 0x5b90..0x5bbf  (47 bytes)
; ======================================================================


L_5B90:
	ld hl,05bbfh		;5b90
	ld bc,00005h		;5b93
	ld de,038a4h		;5b96
	call copia_a_vram		;5b99
	ld a,(0e1aeh)		;5b9c
	ld hl,05b8ah		;5b9f
	call suma_a_a_hl		;5ba2
	ld a,(hl)			;5ba5
	ld c,a			;5ba6
	rra			;5ba7
	rra			;5ba8
	rra			;5ba9
	rra			;5baa
	and 00fh		;5bab
	jr z,L_5BB1		;5bad
	add a,030h		;5baf
L_5BB1:
	exx			;5bb1
	out (c),a		;5bb2
	exx			;5bb4
	ld a,c			;5bb5
	and 00fh		;5bb6
	add a,030h		;5bb8
	exx			;5bba
	out (c),a		;5bbb
	exx			;5bbd
	ret			;5bbe

; ----------------------------------------------------------------------
; DATOS rotulo_rate: Los cuatro tiles ASCII "RATE" mas un tile 0x00 que 0x5B90
;   copia a la fila 5 columna 4, delante del multiplicador vigente.
;   0x5bbf..0x5bc4  (5 bytes)
DATA_rotulo_rate:
	defb 052h,041h,054h,045h,000h	; 5bbf

; ======================================================================
; CODIGO 0x5bc4..0x5d07  (323 bytes)
; ======================================================================


pide_un_sonido:		; Encola el numero A si su canal esta libre o suena algo menos prioritario: canal de 0xE024 para numeros bajos, 0xE012 para 0x87-0x89, y el tercero para el resto; el puntero sale de la tabla de 0x5D1C
	ld hl,0e002h		;5bc4
	bit 6,(hl)		;5bc7
	ret z			;5bc9
L_5BCA:
	ld b,002h		;5bca
	ld hl,0e012h		;5bcc
	cp 087h		;5bcf
	jr c,L_5BDA		;5bd1
	cp 08ah		;5bd3
	jr c,L_5BDE		;5bd5
	inc b			;5bd7
	jr L_5BDE		;5bd8
L_5BDA:
	dec b			;5bda
	ld hl,0e024h		;5bdb
L_5BDE:
	cp (hl)			;5bde
	jr c,L_5C04		;5bdf
	ld c,a			;5be1
	and 03fh		;5be2
	add a,a			;5be4
	ld de,05d1ah		;5be5
	call suma_a_a_de		;5be8
L_5BEB:
	dec hl			;5beb
	dec hl			;5bec
	ld (hl),001h		;5bed
	inc hl			;5bef
	ld (hl),001h		;5bf0
	inc hl			;5bf2
	ld a,c			;5bf3
	ld (hl),a			;5bf4
	inc hl			;5bf5
	ld a,(de)			;5bf6
	ld (hl),a			;5bf7
	inc hl			;5bf8
	inc de			;5bf9
	ld a,(de)			;5bfa
	ld (hl),a			;5bfb
	ld a,007h		;5bfc
	call suma_a_a_hl		;5bfe
	inc de			;5c01
	djnz L_5BEB		;5c02
L_5C04:
	ret			;5c04
L_5C05:
	ld a,(ix+002h)		;5c05
	push bc			;5c08
	call pide_un_sonido		;5c09
	pop bc			;5c0c
	ret			;5c0d
toca_el_sonido:		; El paso del driver en cada interrupcion: tres canales de 9 bytes desde 0xE010, con 0xFD para los parametros, 0xFE para repetir y 0xFF de fin
	ld c,001h		;5c0e
	ld ix,0e010h		;5c10
	exx			;5c14
	ld b,003h		;5c15
	ld de,00009h		;5c17
L_5C1A:
	exx			;5c1a
	ld a,(ix+002h)		;5c1b
	or a			;5c1e
	call nz,L_5C2B		;5c1f
	inc c			;5c22
	inc c			;5c23
	exx			;5c24
	add ix,de		;5c25
	djnz L_5C1A		;5c27
	exx			;5c29
	ret			;5c2a
L_5C2B:
	jp m,L_5C82		;5c2b
	dec (ix+000h)		;5c2e
	ret nz			;5c31
L_5C32:
	ld l,(ix+003h)		;5c32
	ld h,(ix+004h)		;5c35
	ld a,(hl)			;5c38
	cp 0feh		;5c39
	jr z,L_5C05		;5c3b
	jr nc,L_5C7B		;5c3d
	bit 7,(ix+002h)		;5c3f
	jp nz,L_5CAB		;5c43
	and 0f0h		;5c46
	cp 020h		;5c48
	jr nz,L_5C53		;5c4a
	ld a,(hl)			;5c4c
	and 00fh		;5c4d
	ld (ix+001h),a		;5c4f
	inc hl			;5c52
L_5C53:
	ld a,(hl)			;5c53
	and 0f0h		;5c54
	ld b,a			;5c56
	xor (hl)			;5c57
	ld d,a			;5c58
	inc hl			;5c59
	ld e,(hl)			;5c5a
	inc hl			;5c5b
	ld (ix+003h),l		;5c5c
	ld (ix+004h),h		;5c5f
	ex de,hl			;5c62
	call L_5CFA		;5c63
	ld a,b			;5c66
	rrca			;5c67
	rrca			;5c68
	rrca			;5c69
	rrca			;5c6a
	and 00fh		;5c6b
L_5C6D:
	ld h,a			;5c6d
	ld a,(ix+001h)		;5c6e
	ld (ix+000h),a		;5c71
	add a,003h		;5c74
	ld (ix+008h),a		;5c76
	jr L_5CA3		;5c79
L_5C7B:
	xor a			;5c7b
	ld (ix+002h),a		;5c7c
	ld h,a			;5c7f
	jr L_5CA3		;5c80
L_5C82:
	dec (ix+000h)		;5c82
	jr z,L_5C32		;5c85
	dec (ix+008h)		;5c87
	ld a,(ix+008h)		;5c8a
	cp (ix+000h)		;5c8d
	jr nz,L_5C97		;5c90
	cp 003h		;5c92
	jr c,L_5C9A		;5c94
	ret			;5c96
L_5C97:
	dec (ix+008h)		;5c97
L_5C9A:
	ld a,(ix+007h)		;5c9a
	dec a			;5c9d
	ret m			;5c9e
	ld (ix+007h),a		;5c9f
	ld h,a			;5ca2
L_5CA3:
	ld a,c			;5ca3
	rrca			;5ca4
	add a,088h		;5ca5
	ld e,h			;5ca7
	jp 00093h		;5ca8   ; BIOS WRTPSG - Writes data to PSG-register
L_5CAB:
	cp 0fdh		;5cab
	jr nz,L_5CBF		;5cad
	inc hl			;5caf
	ld a,(hl)			;5cb0
	and 007h		;5cb1
	ld (ix+005h),a		;5cb3
	xor (hl)			;5cb6
	rrca			;5cb7
	rrca			;5cb8
	rrca			;5cb9
	ld (ix+006h),a		;5cba
	inc hl			;5cbd
	ld a,(hl)			;5cbe
L_5CBF:
	and 00fh		;5cbf
	ld b,a			;5cc1
	xor (hl)			;5cc2
	inc hl			;5cc3
	ld (ix+003h),l		;5cc4
	ld (ix+004h),h		;5cc7
	rrca			;5cca
	rrca			;5ccb
	rrca			;5ccc
	rrca			;5ccd
	ld hl,05d14h		;5cce
	call suma_a_a_hl		;5cd1
	ld a,(hl)			;5cd4
	ld (ix+001h),a		;5cd5
	ld a,b			;5cd8
	sub 00ch		;5cd9
	jr z,L_5CE3		;5cdb
	ld a,(ix+006h)		;5cdd
	ld (ix+007h),a		;5ce0
L_5CE3:
	call L_5C6D		;5ce3
	ld a,b			;5ce6
	ld hl,05d08h		;5ce7
	call suma_a_a_hl		;5cea
	ld l,(hl)			;5ced
	ld h,000h		;5cee
	ld a,(ix+005h)		;5cf0
	or a			;5cf3
	jr z,L_5CFA		;5cf4
	ld b,a			;5cf6
L_5CF7:
	add hl,hl			;5cf7
	djnz L_5CF7		;5cf8
L_5CFA:
	ld a,c			;5cfa
	ld e,h			;5cfb
	call 00093h		;5cfc   ; BIOS WRTPSG - Writes data to PSG-register
	dec c			;5cff
	ld a,c			;5d00
	ld e,l			;5d01
	call 00093h		;5d02   ; BIOS WRTPSG - Writes data to PSG-register
	inc c			;5d05
	ret			;5d06

; ----------------------------------------------------------------------
; DATOS partitura_vacia: Un solo 0xFF (el terminador del driver): es la
;   partitura a la que apuntan los numeros de sonido 16-18 de la tabla de
;   abajo, los huecos sin musica.
;   0x5d07..0x5d08  (1 bytes)
DATA_partitura_vacia:
	defb 0ffh	; 5d07

; ----------------------------------------------------------------------
; DATOS semitonos: Los doce divisores de frecuencia del PSG de una octava (6A
;   64 5F ... 38), la misma tabla de semitonos que lleva toda la familia
;   Konami de 1984. La lee 0x5CE7 al traducir cada nota.
;   0x5d08..0x5d14  (12 bytes)
DATA_semitonos:
	defb 06ah,064h,05fh,059h,054h,050h,04bh,047h,043h,03fh,03ch,038h	; 5d08  jd_YTPKGC?<8

; ----------------------------------------------------------------------
; DATOS duraciones_de_nota: Las ocho duraciones en interrupciones que indexa
;   el nibble alto del byte de nota en el modo efecto (0x5CCE): 4, 6, 8, 12,
;   14, 22, 44 y 84 (0x54). Las dos ultimas comparten sus bytes con el hueco
;   del puntero 0 de la tabla siguiente: Konami empalmo las dos tablas.
;   0x5d14..0x5d1c  (8 bytes)
DATA_duraciones_de_nota:
	defb 004h,006h,008h,00ch,00eh,016h,02ch,054h	; 5d14  ......,T

; ----------------------------------------------------------------------
; DATOS punteros_de_los_sonidos: Las dieciocho palabras (numeros de sonido
;   1-18) que 0x5BE5 lee con base 0x5D1A e indice (numero & 0x3F)*2: la
;   direccion de la partitura de cada sonido. El "puntero 0" no existe: sus
;   dos bytes son las duraciones 44 y 84 de la tabla anterior, y ningun sitio
;   pide el sonido 0. Los numeros 16-18 apuntan a la partitura vacia de
;   0x5D07.
;   0x5d1c..0x5d40  (36 bytes)
DATA_punteros_de_los_sonidos:
	defw 05e85h,05e8fh	; 5d1c  -> DATA_sonido_01 DATA_sonido_02_y_03
	defw 05e8fh,05df0h	; 5d20  -> DATA_sonido_02_y_03 DATA_sonido_04
	defw 05e49h,05e59h	; 5d24  -> DATA_sonido_05 DATA_sonido_06
	defw 05ea1h,05d40h	; 5d28  -> DATA_sonido_07 DATA_sonido_08
	defw 05d53h,05d9ah	; 5d2c  -> DATA_sonido_09 DATA_sonido_10
	defw 05dc9h,05ddch	; 5d30  -> DATA_sonido_11 DATA_sonido_12
	defw 05d66h,05d7bh	; 5d34  -> DATA_sonido_13 DATA_sonido_14
	defw 05d8eh,05d07h	; 5d38  -> DATA_sonido_15 DATA_partitura_vacia
	defw 05d07h,05d07h	; 5d3c  -> DATA_partitura_vacia DATA_partitura_vacia

; ----------------------------------------------------------------------
; DATOS sonido_08: Partitura del numero 8: la pide 0x4E60 con A=0x88.
;   0x5d40..0x5d53  (19 bytes)
DATA_sonido_08:
	defb 0fdh,068h,030h,030h,0fdh,069h,03bh,03bh,039h,039h,037h,037h,037h,039h,03bh,0fdh	; 5d40  .h00.i;;997779;.
	defb 068h,030h,0ffh	; 5d50

; ----------------------------------------------------------------------
; DATOS sonido_09: Partitura del numero 9.
;   0x5d53..0x5d66  (19 bytes)
DATA_sonido_09:
	defb 0fdh,069h,034h,034h,032h,032h,030h,030h,0fdh,06ah,03bh,03bh,03bh,0fdh,069h,030h	; 5d53  .i442200.j;;;.i0
	defb 032h,034h,0ffh	; 5d63

; ----------------------------------------------------------------------
; DATOS sonido_13: Partitura del numero 13: la pide el menu al confirmar la
;   seleccion (0x443C, A=0x8D): el jingle de empezar la partida.
;   0x5d66..0x5d7b  (21 bytes)
DATA_sonido_13:
	defb 0fdh,069h,034h,034h,034h,0fdh,06ah,039h,039h,039h,039h,0fdh,069h,039h,039h,039h	; 5d66  .i444.j9999.i999
	defb 039h,037h,037h,039h,0ffh	; 5d76

; ----------------------------------------------------------------------
; DATOS sonido_14: Partitura del numero 14.
;   0x5d7b..0x5d8e  (19 bytes)
DATA_sonido_14:
	defb 0fdh,06ah,034h,034h,034h,034h,034h,034h,034h,0fdh,069h,034h,034h,034h,034h,032h	; 5d7b  .j4444444.i44442
	defb 032h,036h,0ffh	; 5d8b

; ----------------------------------------------------------------------
; DATOS sonido_15: Partitura del numero 15.
;   0x5d8e..0x5d9a  (12 bytes)
DATA_sonido_15:
	defb 07ch,0fdh,069h,031h,031h,031h,031h,0fdh,06ah,03bh,03bh,0ffh	; 5d8e  |.i1111.j;;.

; ----------------------------------------------------------------------
; DATOS sonido_10: Partitura del numero 10: la escala que pide 0x44F6 con
;   A=0x8A al quedarse sin bolas de reserva: la musica del GAME OVER.
;   0x5d9a..0x5dc9  (47 bytes)
DATA_sonido_10:
	defb 0fdh,06ah,014h,012h,015h,014h,017h,015h,019h,017h,01bh,019h,0fdh,069h,010h,0fdh	; 5d9a  .j...........i..
	defb 06ah,01bh,0fdh,069h,012h,010h,014h,012h,015h,014h,017h,015h,019h,017h,01bh,019h	; 5daa  j..i............
	defb 0fdh,068h,010h,0fdh,069h,01bh,0fdh,068h,012h,010h,014h,012h,015h,014h,0ffh	; 5dba  .h..i..h.......

; ----------------------------------------------------------------------
; DATOS sonido_11: Partitura del numero 11.
;   0x5dc9..0x5ddc  (19 bytes)
DATA_sonido_11:
	defb 0fdh,06ah,032h,035h,032h,035h,032h,035h,032h,035h,032h,035h,032h,035h,032h,035h	; 5dc9  .j25252525252525
	defb 032h,035h,0ffh	; 5dd9

; ----------------------------------------------------------------------
; DATOS sonido_12: Partitura del numero 12.
;   0x5ddc..0x5df0  (20 bytes)
DATA_sonido_12:
	defb 0fdh,06bh,057h,04ch,027h,00ch,057h,04ch,027h,00ch,067h,00ch,027h,00ch,027h,00ch	; 5ddc  .kWL'.WL'.g.'.'.
	defb 027h,00ch,027h,0ffh	; 5dec

; ----------------------------------------------------------------------
; DATOS sonido_04: Partitura del numero 4, la mas larga (89 bytes).
;   0x5df0..0x5e49  (89 bytes)
DATA_sonido_04:
	defb 024h,0e0h,025h,022h,0d0h,025h,0a0h,025h,070h,025h,060h,024h,02ah,000h,000h,000h	; 5df0  $.%".%.%p%`$*...
	defb 000h,022h,0d6h,0aeh,0d5h,0f4h,0d6h,0aeh,0d5h,0f4h,0d5h,09eh,0d5h,002h,0d5h,09eh	; 5e00  ."..............
	defb 0d5h,002h,0d4h,0bah,0d4h,036h,0d4h,0bah,0d4h,036h,0d3h,0fah,0d3h,08ah,0d3h,0fah	; 5e10  .....6...6......
	defb 0d3h,08ah,0d3h,057h,0d2h,0fah,0d3h,057h,0d2h,0fah,0d2h,0cfh,0d2h,081h,0d2h,0cfh	; 5e20  ...W...W........
	defb 0d2h,081h,0d2h,05dh,0d2h,01bh,0d2h,05dh,0d2h,01bh,0d1h,0fdh,0d1h,0c5h,0d1h,0fdh	; 5e30  ...]...]........
	defb 0d1h,0c5h,0d1h,0abh,0d1h,07dh,0d1h,053h,0ffh	; 5e40  .....}.S.

; ----------------------------------------------------------------------
; DATOS sonido_05: Partitura del numero 5.
;   0x5e49..0x5e59  (16 bytes)
DATA_sonido_05:
	defb 023h,0e4h,0a8h,0d4h,0a8h,0b4h,0a8h,084h,0a8h,064h,0a8h,02ah,000h,000h,000h,000h	; 5e49  #........d.*....

; ----------------------------------------------------------------------
; DATOS sonido_06: Partitura del numero 6: la pide 0x4E27 (A=0x06, con
;   prioridad de efecto).
;   0x5e59..0x5e85  (44 bytes)
DATA_sonido_06:
	defb 024h,0c1h,01dh,0c1h,040h,0c1h,053h,0c1h,07dh,0c1h,0abh,0c1h,0c5h,0c1h,0fdh,0d2h	; 5e59  $...@.S.}.......
	defb 03bh,0d2h,081h,0d2h,0a7h,0d2h,0fah,0d3h,057h,0d3h,08ah,0d3h,0fah,0d4h,076h,0d5h	; 5e69  ;.......W.....v.
	defb 002h,0d5h,04eh,0d5h,0f4h,0d6h,0aeh,0d7h,014h,0d7h,0e8h,0ffh	; 5e79  ..N.........

; ----------------------------------------------------------------------
; DATOS sonido_01: Partitura del numero 1 (y con sus mismos bytes empieza la
;   2).
;   0x5e85..0x5e8f  (10 bytes)
DATA_sonido_01:
	defb 021h,0e0h,025h,0c0h,025h,090h,025h,060h,025h,0ffh	; 5e85  !.%.%.%`%.

; ----------------------------------------------------------------------
; DATOS sonido_02_y_03: Partitura de los numeros 2 y 3 (los dos punteros
;   apuntan aqui): la pide 0x4D9F con A=0x03, dentro de la fisica de las
;   bolas.
;   0x5e8f..0x5ea1  (18 bytes)
DATA_sonido_02_y_03:
	defb 021h,0f0h,048h,0f0h,049h,0e0h,048h,0d0h,049h,090h,048h,080h,049h,070h,048h,060h	; 5e8f  !.H.I.H.I.H.IpH`
	defb 049h,0ffh	; 5e9f

; ----------------------------------------------------------------------
; DATOS sonido_07: Partitura del numero 7: la fanfarria de la bola de reserva
;   extra que pide 0x47CA (A=0x07) al cruzar el marcador el umbral de 0xE052.
;   0x5ea1..0x5eb3  (18 bytes)
DATA_sonido_07:
	defb 024h,0d1h,01dh,0d0h,0d5h,0d0h,0a9h,0d0h,08eh,0d1h,01dh,0d0h,0d5h,0d0h,0a9h,0d0h	; 5ea1  $...............
	defb 08eh,0ffh	; 5eb1

; ======================================================================
; CODIGO 0x5eb3..0x5eb9  (6 bytes)
; ======================================================================


modulo_de_la_mesa:		; El otro punto con despachador del juego: salta por la tabla de 0x5EB9 con el indice de 0xE1F0
	ld a,(0e1f0h)		;5eb3
	call despachador		;5eb6

; ----------------------------------------------------------------------
; DATOS tabla_del_despachador_5EB6: Las cuatro palabras del despachador,
;   detras del `call` de 0x5EB6 (el indice esta en 0xE1F0).
;   0x5eb9..0x5ec1  (8 bytes)
DATA_tabla_del_despachador_5EB6:
	defb 0c1h,05eh	; 5eb9
	defb 0cah,05eh	; 5ebb
	defb 0d3h,05eh	; 5ebd
	defb 0ech,05eh	; 5ebf

; ======================================================================
; CODIGO 0x5ec1..0x5fb3  (242 bytes)
; ======================================================================


L_5EC1:
	xor a			;5ec1
	ld (0e002h),a		;5ec2
	call L_4466		;5ec5
	jr L_5EE2		;5ec8
L_5ECA:
	call cortina_de_borrado		;5eca
	ret p			;5ecd
	call L_4474		;5ece
	jr L_5EE2		;5ed1
L_5ED3:
	ld hl,0e004h		;5ed3
	dec (hl)			;5ed6
	ret nz			;5ed7
	call L_44AC		;5ed8
	ld a,021h		;5edb
	ld (0e1fah),a		;5edd
	jr L_5EE2		;5ee0
L_5EE2:
	ld hl,0e1f0h		;5ee2
	inc (hl)			;5ee5
L_5EE6:
	ld a,007h		;5ee6
	ld (0e000h),a		;5ee8
	ret			;5eeb
L_5EEC:
	ld a,(0e19fh)		;5eec
	and a			;5eef
	jr nz,L_5F26		;5ef0
	ld de,0e100h		;5ef2
L_5EF5:
	ld a,010h		;5ef5
	call suma_a_a_de		;5ef7
	ld a,(de)			;5efa
	and a			;5efb
	jr z,L_5EF5		;5efc
	ld a,003h		;5efe
	call suma_a_a_de		;5f00
	call L_5F6D		;5f03
	push af			;5f06
	ld de,0e173h		;5f07
	call L_5F6D		;5f0a
	ld b,a			;5f0d
	pop af			;5f0e
	sub b			;5f0f
	inc a			;5f10
	cp 002h		;5f11
	ld a,001h		;5f13
	ld hl,0e008h		;5f15
	jr nc,L_5F42		;5f18
	ld a,(0e1a0h)		;5f1a
	sub 003h		;5f1d
	jr nz,L_5F3F		;5f1f
	ld (hl),a			;5f21
	ld a,010h		;5f22
L_5F24:
	inc hl			;5f24
	ld (hl),a			;5f25
L_5F26:
	call estado_11_la_tacada		;5f26
	ld a,(0e000h)		;5f29
	cp 00fh		;5f2c
	jr z,L_5F35		;5f2e
	ld a,(0e00ch)		;5f30
	and a			;5f33
	ret z			;5f34
L_5F35:
	xor a			;5f35
	ld (0e00dh),a		;5f36
	inc a			;5f39
	ld (0e00bh),a		;5f3a
	jr L_5EE6		;5f3d
L_5F3F:
	xor a			;5f3f
	jr L_5F24		;5f40
L_5F42:
	ld c,000h		;5f42
	ld a,(0e176h)		;5f44
	cp 0e1h		;5f47
	jr nz,L_5F4C		;5f49
	inc c			;5f4b
L_5F4C:
	cp 00eh		;5f4c
	jr nz,L_5F51		;5f4e
	inc c			;5f50
L_5F51:
	ld a,(0e174h)		;5f51
	cp 036h		;5f54
	jr nz,L_5F59		;5f56
	inc c			;5f58
L_5F59:
	cp 0a9h		;5f59
	jr nz,L_5F5E		;5f5b
	inc c			;5f5d
L_5F5E:
	dec c			;5f5e
	ld a,(0e1fah)		;5f5f
	jr z,L_5F69		;5f62
	rlca			;5f64
	rlca			;5f65
	ld (0e1fah),a		;5f66
L_5F69:
	and 00fh		;5f69
	jr L_5F24		;5f6b
L_5F6D:
	ld hl,0e103h		;5f6d
	ld a,(de)			;5f70
	sub (hl)			;5f71
	ld c,a			;5f72
	inc hl			;5f73
	inc de			;5f74
	ld a,(de)			;5f75
	sbc a,(hl)			;5f76
	ld b,a			;5f77
	ld a,000h		;5f78
	jr nc,L_5F7D		;5f7a
	dec a			;5f7c
L_5F7D:
	inc hl			;5f7d
	inc de			;5f7e
	call L_5FA4		;5f7f
	ld (0e1f1h),bc		;5f82
	ld a,(de)			;5f86
	sub (hl)			;5f87
	ld c,a			;5f88
	inc hl			;5f89
	inc de			;5f8a
	ld a,(de)			;5f8b
	sbc a,(hl)			;5f8c
	ld b,a			;5f8d
	ld a,000h		;5f8e
	jr nc,L_5F93		;5f90
	dec a			;5f92
L_5F93:
	call L_5FA4		;5f93
	ld (0e1f3h),bc		;5f96
	ld hl,0e1eah		;5f9a
	call saca_la_pendiente_del_vector		;5f9d
	ld a,(0e1a1h)		;5fa0
	ret			;5fa3
L_5FA4:
	ex af,af'			;5fa4
	ld a,003h		;5fa5
L_5FA7:
	ex af,af'			;5fa7
	sra a		;5fa8
	rr b		;5faa
	rr c		;5fac
	ex af,af'			;5fae
	dec a			;5faf
	jr nz,L_5FA7		;5fb0
	ret			;5fb2

; ----------------------------------------------------------------------
; DATOS relleno: El final vacio del chip: 8269 bytes de 0xFF, de 0x5FB3 a
;   0x7FFF. Ninguna instruccion del cartucho lee de aqui.
;   0x5fb3..0x8000  (8269 bytes)
DATA_relleno:
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 5fb3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 5fc3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 5fd3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 5fe3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 5ff3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6003  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6013  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6023  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6033  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6043  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6053  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6063  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6073  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6083  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6093  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 60a3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 60b3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 60c3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 60d3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 60e3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 60f3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6103  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6113  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6123  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6133  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6143  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6153  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6163  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6173  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6183  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6193  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 61a3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 61b3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 61c3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 61d3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 61e3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 61f3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6203  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6213  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6223  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6233  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6243  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6253  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6263  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6273  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6283  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6293  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 62a3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 62b3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 62c3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 62d3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 62e3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 62f3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6303  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6313  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6323  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6333  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6343  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6353  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6363  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6373  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6383  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6393  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 63a3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 63b3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 63c3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 63d3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 63e3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 63f3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6403  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6413  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6423  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6433  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6443  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6453  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6463  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6473  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6483  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6493  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 64a3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 64b3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 64c3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 64d3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 64e3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 64f3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6503  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6513  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6523  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6533  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6543  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6553  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6563  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6573  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6583  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6593  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 65a3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 65b3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 65c3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 65d3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 65e3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 65f3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6603  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6613  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6623  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6633  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6643  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6653  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6663  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6673  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6683  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6693  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 66a3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 66b3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 66c3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 66d3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 66e3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 66f3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6703  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6713  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6723  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6733  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6743  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6753  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6763  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6773  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6783  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6793  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 67a3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 67b3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 67c3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 67d3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 67e3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 67f3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6803  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6813  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6823  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6833  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6843  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6853  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6863  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6873  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6883  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6893  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 68a3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 68b3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 68c3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 68d3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 68e3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 68f3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6903  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6913  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6923  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6933  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6943  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6953  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6963  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6973  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6983  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6993  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 69a3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 69b3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 69c3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 69d3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 69e3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 69f3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6a03  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6a13  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6a23  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6a33  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6a43  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6a53  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6a63  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6a73  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6a83  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6a93  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6aa3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6ab3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6ac3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6ad3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6ae3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6af3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6b03  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6b13  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6b23  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6b33  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6b43  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6b53  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6b63  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6b73  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6b83  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6b93  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6ba3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6bb3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6bc3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6bd3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6be3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6bf3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6c03  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6c13  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6c23  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6c33  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6c43  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6c53  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6c63  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6c73  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6c83  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6c93  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6ca3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6cb3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6cc3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6cd3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6ce3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6cf3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6d03  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6d13  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6d23  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6d33  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6d43  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6d53  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6d63  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6d73  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6d83  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6d93  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6da3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6db3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6dc3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6dd3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6de3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6df3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6e03  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6e13  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6e23  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6e33  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6e43  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6e53  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6e63  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6e73  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6e83  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6e93  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6ea3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6eb3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6ec3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6ed3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6ee3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6ef3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6f03  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6f13  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6f23  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6f33  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6f43  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6f53  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6f63  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6f73  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6f83  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6f93  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6fa3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6fb3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6fc3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6fd3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6fe3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6ff3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7003  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7013  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7023  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7033  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7043  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7053  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7063  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7073  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7083  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7093  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 70a3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 70b3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 70c3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 70d3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 70e3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 70f3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7103  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7113  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7123  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7133  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7143  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7153  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7163  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7173  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7183  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7193  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 71a3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 71b3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 71c3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 71d3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 71e3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 71f3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7203  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7213  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7223  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7233  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7243  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7253  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7263  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7273  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7283  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7293  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 72a3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 72b3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 72c3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 72d3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 72e3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 72f3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7303  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7313  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7323  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7333  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7343  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7353  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7363  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7373  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7383  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7393  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 73a3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 73b3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 73c3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 73d3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 73e3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 73f3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7403  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7413  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7423  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7433  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7443  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7453  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7463  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7473  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7483  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7493  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 74a3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 74b3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 74c3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 74d3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 74e3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 74f3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7503  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7513  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7523  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7533  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7543  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7553  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7563  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7573  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7583  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7593  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 75a3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 75b3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 75c3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 75d3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 75e3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 75f3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7603  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7613  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7623  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7633  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7643  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7653  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7663  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7673  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7683  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7693  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 76a3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 76b3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 76c3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 76d3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 76e3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 76f3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7703  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7713  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7723  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7733  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7743  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7753  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7763  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7773  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7783  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7793  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 77a3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 77b3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 77c3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 77d3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 77e3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 77f3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7803  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7813  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7823  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7833  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7843  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7853  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7863  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7873  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7883  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7893  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 78a3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 78b3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 78c3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 78d3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 78e3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 78f3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7903  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7913  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7923  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7933  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7943  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7953  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7963  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7973  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7983  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7993  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 79a3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 79b3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 79c3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 79d3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 79e3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 79f3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7a03  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7a13  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7a23  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7a33  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7a43  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7a53  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7a63  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7a73  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7a83  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7a93  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7aa3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7ab3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7ac3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7ad3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7ae3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7af3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7b03  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7b13  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7b23  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7b33  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7b43  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7b53  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7b63  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7b73  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7b83  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7b93  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7ba3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7bb3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7bc3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7bd3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7be3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7bf3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7c03  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7c13  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7c23  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7c33  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7c43  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7c53  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7c63  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7c73  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7c83  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7c93  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7ca3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7cb3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7cc3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7cd3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7ce3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7cf3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7d03  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7d13  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7d23  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7d33  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7d43  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7d53  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7d63  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7d73  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7d83  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7d93  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7da3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7db3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7dc3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7dd3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7de3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7df3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7e03  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7e13  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7e23  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7e33  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7e43  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7e53  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7e63  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7e73  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7e83  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7e93  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7ea3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7eb3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7ec3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7ed3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7ee3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7ef3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f03  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f13  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f23  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f33  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f43  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f53  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f63  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f73  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f83  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f93  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7fa3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7fb3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7fc3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7fd3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7fe3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7ff3  .............
