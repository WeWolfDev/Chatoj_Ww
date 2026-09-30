# CH'ATOJ — audio integrado en scripts

El audio generado en `assets/Audio/Generated/` ya está conectado al código.

## Sistema global
Se agregó `Scripts/audio_manager.gd` como Autoload `AudioManager` en `project.godot`.
Maneja música persistente, ambiente, SFX globales y SFX 2D posicionales.

## Integrado
- Main Menu: música, hover, click y stinger al jugar.
- Mapa: música de exploración y ambiente de jungla.
- Player: pasos, espada, dash, escudo, bloqueo, bloqueo perfecto, daga, curación, daño, muerte, UI de muerte y respawn.
- Daga: impacto, desaparición y ticks de sangrado.
- Checkpoint: activación.
- NPC/Soldado: detección, ataque, golpe, daño y muerte.
- Wayob: ataque, invocación, intercambio, daño y muerte.
- Sombra de Wayob: desaparición.
- Murciélago: loop de alas, mordida, daño y muerte.
- Camazots: música de jefe, windups, embestida, slam, invocación, daño, fase 2 y muerte.
- Kakasbal: música de jefe, rasguño, coletazo, embestida, lock, choque, daño, fase 2 y muerte.

Los volúmenes están puestos desde código en dB para evitar que todos los efectos suenen al mismo nivel.
