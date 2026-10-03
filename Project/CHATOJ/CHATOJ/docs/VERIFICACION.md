# Verificación de CHATOJ optimizado

Motor: Godot 4.7.2 stable (ed1daf0bf). Pruebas automáticas sin ventana.

- **75 comprobaciones aprobadas, 0 fallos.**
- 23 escenas cargadas e instanciadas.
- 244 referencias a recursos comprobadas: ninguna ruta faltante.
- Las 29 imágenes convertidas conservan exactamente sus dimensiones y píxeles RGBA.
- Las 5 pistas Ogg conservan el número de muestras, canales y frecuencia del audio original.
- Todos los efectos WAV están en formatos compatibles. Se corrigió el formato del sonido de lanzamiento.
- No hay carpeta de complementos ni dependencia de Ziva.

La prueba de combate incluye la tecla física E, ausencia de objetivos, objetivo a 451 px, borde exacto de 450 px, enemigos sin vida, jugador muerto, curación, falta de cargas, HUD, daño inicial de 40, sangrado total de 10, recarga a los 3 segundos y alcance configurable compartido por jugador y proyectil. También se comprobó daño contra un soldado real del mapa principal.

El botón Jugar abre el mapa original. En el mapa alternativo, M no modifica la cámara y ya no figura como control en la ayuda.

El entorno restringido de pruebas emitió un aviso al intentar leer el almacén de certificados de Windows y, durante la importación del editor, al abrir su directorio de perfil. No hubo errores de scripts, recursos o pruebas de juego después de las correcciones. No se verificó una partida completa, el balance de todos los jefes ni se midieron FPS o tiempo de edición en el equipo del usuario.

## Tamaño

- ZIP original: 320.35 MB (320 354 086 bytes).
- Contenido original descomprimido: 388.98 MB, 10,553 archivos.
- Entrega optimizada: aproximadamente **28,1 MB en ZIP** y **30,0 MB descomprimida**, 320 archivos; reducción del ZIP de **91,2 %**.
- La nueva entrega excluye `.godot/`; Godot regenera esa caché al abrir el proyecto.

## Resultado detallado

```text
PASS: Cargar res://scenes/cinematics/intro.tscn
PASS: Instanciar res://scenes/cinematics/intro.tscn
PASS: Cargar res://scenes/enemies/camazots.tscn
PASS: Instanciar res://scenes/enemies/camazots.tscn
PASS: Cargar res://scenes/enemies/guardian.tscn
PASS: Instanciar res://scenes/enemies/guardian.tscn
PASS: Cargar res://scenes/enemies/kakasbal.tscn
PASS: Instanciar res://scenes/enemies/kakasbal.tscn
PASS: Cargar res://scenes/enemies/murcielago.tscn
PASS: Instanciar res://scenes/enemies/murcielago.tscn
PASS: Cargar res://scenes/enemies/soldado.tscn
PASS: Instanciar res://scenes/enemies/soldado.tscn
PASS: Cargar res://scenes/enemies/tzucan.tscn
PASS: Instanciar res://scenes/enemies/tzucan.tscn
PASS: Cargar res://scenes/enemies/wayobs.tscn
PASS: Instanciar res://scenes/enemies/wayobs.tscn
PASS: Cargar res://scenes/enemies/wayobs_shadow.tscn
PASS: Instanciar res://scenes/enemies/wayobs_shadow.tscn
PASS: Cargar res://scenes/interactables/checkpoint.tscn
PASS: Instanciar res://scenes/interactables/checkpoint.tscn
PASS: Cargar res://scenes/interactables/checkpoint_dialogue.tscn
PASS: Instanciar res://scenes/interactables/checkpoint_dialogue.tscn
PASS: Cargar res://scenes/maps/aldea.tscn
PASS: Instanciar res://scenes/maps/aldea.tscn
PASS: Cargar res://scenes/maps/camino.tscn
PASS: Instanciar res://scenes/maps/camino.tscn
PASS: Cargar res://scenes/maps/cenote.tscn
PASS: Instanciar res://scenes/maps/cenote.tscn
PASS: Cargar res://scenes/maps/mapa3.tscn
PASS: Instanciar res://scenes/maps/mapa3.tscn
PASS: Cargar res://scenes/maps/mapa4.tscn
PASS: Instanciar res://scenes/maps/mapa4.tscn
PASS: Cargar res://scenes/maps/mapa_completo.tscn
PASS: Instanciar res://scenes/maps/mapa_completo.tscn
PASS: Cargar res://scenes/maps/parte_kakasbal.tscn
PASS: Instanciar res://scenes/maps/parte_kakasbal.tscn
PASS: Cargar res://scenes/maps/segundo_combate.tscn
PASS: Instanciar res://scenes/maps/segundo_combate.tscn
PASS: Cargar res://scenes/maps/selva_jade.tscn
PASS: Instanciar res://scenes/maps/selva_jade.tscn
PASS: Cargar res://scenes/player/player.tscn
PASS: Instanciar res://scenes/player/player.tscn
PASS: Cargar res://scenes/ui/main_menu.tscn
PASS: Instanciar res://scenes/ui/main_menu.tscn
PASS: Cargar res://scenes/weapons/dagger_projectile.tscn
PASS: Instanciar res://scenes/weapons/dagger_projectile.tscn
PASS: Daga asignada al jugador
PASS: Alcance inicial de 450 px
PASS: Sin enemigos: no gastar cargas
PASS: Fuera de rango: no seleccionar objetivo
PASS: Fuera de rango: no gastar cargas
PASS: Aceptar el límite exacto de 450 px
PASS: Ignorar enemigos sin vida
PASS: Muerto: bloquear lanzamiento
PASS: Curándose: bloquear lanzamiento
PASS: Sin cargas: no crear dagas
PASS: La acción E lanza y gasta exactamente una carga
PASS: HUD muestra las cargas restantes
PASS: La daga impacta y aplica 40 de daño
PASS: La daga no hiere al jugador
PASS: Sangrado completo de 10 puntos
PASS: Regeneración de una carga a los 3 segundos
PASS: El rango del inspector controla la selección
PASS: Proyectil y selección comparten alcance
PASS: Impacto en el borde del alcance configurado
PASS: Abrir menú
PASS: Jugar abre el mapa original
PASS: Enemigos reales registrados para las dagas
PASS: Objetivo real recibe daño: Camazots
PASS: Objetivo real recibe daño: NPC
PASS: Objetivo real recibe daño: NPC2
PASS: Objetivo real recibe daño: Wayob
PASS: Daga golpea al soldado real en el mapa principal
PASS: M no cambia la cámara ni muestra todo el mapa
PASS: Ayuda sin la función de mapa eliminada
RESULT: 75 checks; 0 failures
```
