# CH'ATOJ — Paquete de audio

Este paquete fue preparado a partir de las mecánicas encontradas en el proyecto Godot:
Player, dagas, escudo, curación, muerte, checkpoints, MainMenu, Soldado/NPC,
Wayob y sus sombras, murciélagos, Camazots y Kakasbal.

## Música
- `Music/main_menu_theme_loop.wav` — menú principal.
- `Music/exploration_theme_loop.wav` — mapa/exploración.
- `Music/boss_theme_loop.wav` — combates contra jefes.
- `Ambience/jungle_ambience_loop.wav` — ambiente de jungla.

Las pistas terminadas en `_loop` están diseñadas para repetirse. En Godot activa **Loop** en la importación.

## Menús
Usa:
- `SFX/UI/ui_hover.wav` para `mouse_entered`.
- `SFX/UI/ui_click.wav` para `button_down` o `pressed`.
- `SFX/UI/game_start_stinger.wav` al pulsar JUGAR.
- `SFX/UI/death_screen_reveal.wav` al mostrar la pantalla de muerte.
- `SFX/UI/respawn.wav` al elegir Último Checkpoint.

## Checkpoint
`SFX/UI/checkpoint_activate.wav` corresponde a `checkpoint.gd::_on_body_entered()`.

## Estilo
Son sonidos originales sintetizados para acompañar la estética oscura de ruinas,
piedra, jade, jungla y fantasía mesoamericana de CH'ATOJ. No pretenden ser
reconstrucciones de música o instrumentos mayas históricos.

## Integración
`audio_manifest.csv` indica el archivo y la función/estado del proyecto donde conviene reproducirlo.

Para SFX cortos usa `AudioStreamPlayer` o `AudioStreamPlayer2D`.
Para música de menú y mapa usa `AudioStreamPlayer`.
Para sonidos posicionales de enemigos/jefes, usa `AudioStreamPlayer2D`.

Evita reproducir `hurt` cada frame: dispáralo únicamente cuando el daño sea aceptado
por el script. Para sonidos de windup de jefes, reprodúcelos al entrar al estado,
no dentro de `_physics_process()` en cada frame.
