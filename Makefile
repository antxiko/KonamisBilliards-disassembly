# Konami's Billiards (Konami, RC-706, 1984) - desensamblado
#
# El orden de las cosas: trazar el flujo -> generar el listado -> comprobar que
# vuelve a dar la ROM byte a byte -> las comprobaciones que el reensamblado NO
# cubre.
#
# La ROM no se distribuye. Hace falta en la raiz como billiards.rom, y
# `make comprueba` verifica el sha256.

ROM      = billiards.rom
SHA      = 38741612e0b20e39dfd834106a3d5ef5a24c06fb947a104c044f1cdd269c46d9
SRC      = src
WORK     = work
ORG      = 0x4000
TITULO   = KONAMI'S BILLIARDS - Konami - MSX1 - cartucho RC-706 de 16 KB en la pagina 1

all: listado notas verify sanity test

$(ROM):
	@echo "=================================================================="
	@echo " Falta $(ROM), y este repositorio NO lo distribuye."
	@echo ""
	@echo " Es Konami's Billiards (Konami, RC-706) para MSX, 16384 bytes."
	@echo " Ponlo aqui con ese nombre. Para comprobar que es el mismo:"
	@echo "     shasum -a 256 $(ROM)"
	@echo "     $(SHA)"
	@echo ""
	@echo " Sin el se puede leer el listado ya generado en $(SRC)/, y los"
	@echo " tests que no dependen del binario siguen pasando."
	@echo "=================================================================="
	@false

comprueba: $(ROM)
	@echo "$(SHA)  $(ROM)" | shasum -a 256 -c -

# El trazado sigue el flujo desde los puntos de entrada. Los que no se pueden
# deducir estaticamente -ganchos de interrupcion, destinos de saltos
# indirectos- estan declarados en el .entries, cada uno con su justificacion.
$(WORK)/billiards.trace.json: $(ROM) $(SRC)/billiards.entries $(SRC)/billiards.nocode
	@mkdir -p $(WORK)
	python3 tools/z80trace.py $(ROM) $(ORG) $(SRC)/billiards.entries \
	        $(WORK)/billiards $(SRC)/billiards.nocode

trace: $(WORK)/billiards.trace.json

listado: $(WORK)/billiards.trace.json $(SRC)/billiards.notes
	python3 tools/mkasm.py $(ROM) $(ORG) $(WORK)/billiards.trace.json \
	        $(SRC)/billiards.notes work/msx.sym $(SRC)/billiards.asm "$(TITULO)"

# La prueba que decide si el desensamblado es fiable.
verify: $(SRC)/billiards.asm $(ROM)
	@sh tools/verify_build.sh $(SRC)/billiards.asm $(ROM) $(ORG)

# Lo que el reensamblado NO puede cazar: que unos datos se esten leyendo como
# codigo. El binario sale identico igual, porque los bytes no cambian; lo unico
# que cambia es lo que decimos de ellos.
sanity: $(WORK)/billiards.trace.json
	@echo "=================================================================="
	@echo " ningun byte declarado como datos puede salir como codigo"
	@echo "=================================================================="
	@python3 tools/check_trace.py $(WORK)/billiards.trace.json $(SRC)/billiards.nocode
	@python3 tools/check_datos_como_codigo.py $(WORK) $(SRC)
	@echo "=================================================================="
	@echo " ningun punto de entrada puede caer dentro de una zona de datos"
	@echo "=================================================================="
	@python3 tools/check_entradas.py $(SRC)/billiards.entries $(SRC)/billiards.notes \
	        $(SRC)/billiards.nocode
	@echo "=================================================================="
	@echo " ni un byte del cartucho sin asignar"
	@echo "=================================================================="
	@python3 tools/presupuesto.py $(WORK) $(SRC)

test:
	@echo "=================================================================="
	@echo " Tests"
	@echo "=================================================================="
	@python3 -m unittest discover -s tests -v

# Los dos fallos que se pierden en silencio al anotar: un comentario anclado a
# una direccion que no es instruccion, y dos comentarios para la misma.
notas: $(SRC)/billiards.asm
	@echo "=================================================================="
	@echo " ningun comentario suelto ni repetido"
	@echo "=================================================================="
	@python3 tools/valida_notas.py $(SRC)/billiards.notes $(SRC)/billiards.asm

densidad:
	@python3 tools/densidad.py $(SRC)/billiards.asm

# La ROM en openMSX, para verla con los ojos.
juega: $(ROM)
	"C:/Program Files/openMSX/openmsx.exe" -machine Philips_VG_8020 -cart $(ROM)

clean:
	rm -rf $(WORK)/billiards.trace.json $(WORK)/billiards.map $(WORK)/png

.PHONY: all comprueba trace listado notas verify sanity test densidad juega clean
