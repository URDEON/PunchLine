extends RefCounted
## Datos usados por combate, tarjetas y manual; las cifras no son texto decorativo.
const MEGA := [
	{"id":"cannon","title":"Cañón de ruptura","icon":"cannon","cooldown":2.0,"duration":1.1,"contact":1.1,"damage":32.0,"radius":2.8,"range":32.0,"ragdoll":1.5,"force":13.0,"vertical":5.0,"move":.65,"pros":"Mantén 1: despliega, camina y apunta con el láser. Suelta: dispara y repliega. Proyectil físico a 32 m y explosión de 2,8 m; derriba al primer impacto válido.","cons":"Despliegue de 1,1 s y repliegue de 0,95 s; recarga de 2 s desde el disparo; trayectoria fija tras disparar; paredes detienen el disparo. Sin seguimiento automático."},
	{"id":"hammer","title":"Martillo tectónico","icon":"ground_slam","cooldown":11.0,"duration":1.8,"contact":1.05,"damage":28.0,"radius":4.4,"range":2.3,"ragdoll":1.7,"force":10.0,"vertical":5.0,"move":.15,"pros":"Ambos puños golpean delante: área de 4,4 m y derribo. El centro rompe guardia.","cons":"Preparación de 1,05 s; deja la espalda expuesta y no atraviesa paredes ni pisos."},
	{"id":"seismic","title":"Pisotón sísmico","icon":"stomp","cooldown":10.0,"duration":1.45,"contact":.7,"damage":18.0,"radius":5.5,"range":.0,"ragdoll":1.35,"force":8.0,"vertical":5.5,"move":.1,"pros":"Onda alrededor del mecha; útil contra varios enemigos. Centro de 1,5 m rompe guardia.","cons":"Menos daño; se esquiva alejándose o saltando. Solo alcanza personajes próximos al suelo."},
	{"id":"ram","title":"Carga de ariete","icon":"ram","cooldown":14.0,"duration":2.0,"contact":.55,"damage":24.0,"radius":2.1,"range":6.0,"ragdoll":1.5,"force":18.0,"vertical":4.0,"move":.0,"pros":"Propulsores impulsan el chasis en línea recta; un impacto por objetivo, con derribo.","cons":"No permite girar; chocar con una pared frena la carga. Recuperación de 0,75 s y flancos vulnerables."}
]
const BASE_NAMES := [["Barrido vectorial","Talón ascendente","Meteorito de talón"],["Puño de prensa","Martillo industrial","Pistón lineal"],["Doble percusión","Impulso vectorial","Corte de retorno"],["Bastión frontal","Reversión de impacto","Paso de flanco"]]
const PROFILES := [
	"LEELA · Duelista de piernas. Más rápida; patadas, barridos y elevación. Alcance corto, sin ataques de brazos; los saltos exponen su aterrizaje.",
	"STAN · Artillería de puños. Mayor daño por contacto y empuje; preparación larga y desplazamiento lento. Esquivar su carga deja una ventana de castigo.",
	"GEORGE · Asalto versátil. Doble contacto, avance y remate; daño moderado por golpe. El impulso no persigue al rival y puede fallar.",
	"MIKE · Defensa reactiva. Guardia frontal, counter corto y paso lateral con recarga; puede reposicionarse para castigar. Sigue vulnerable a golpes por espalda y un counter fallido deja 0,35 s de recuperación."
]
const BASE_DETAILS := [
	["Barrido de 13 de daño, 2,8 m y derribo. Ventaja: controla enemigos cercanos. Desventaja: preparación de 0,53 s y alcance corto.","Patada de 14 de daño que eleva al rival. Ventaja: inicia derribo aéreo. Desventaja: salta y expone el aterrizaje; contacto a los 0,67 s.","Talón de 18 de daño hacia el suelo. Ventaja: derribo fuerte. Desventaja: corto alcance y compromiso durante el salto."],
	["Puño de 23 de daño. Ventaja: gran potencia y derribo. Desventaja: carga visible de 0,84 s, fácil de esquivar.","Martillazo de 20 de daño en área cercana. Ventaja: varios objetivos. Desventaja: 1,15 s de animación y movilidad reducida.","Pistón de 16 de daño, 3,5 m y gran empuje. Ventaja: separa al rival. Desventaja: dirección frontal y recuperación lenta."],
	["Dos golpes de 8 de daño. Ventaja: dos oportunidades de contacto. Desventaja: un rival puede salir entre golpes; energía repartida.","Avance de 14 de daño. Ventaja: cierra distancia con propulsión. Desventaja: trayectoria fija, frena contra obstáculos y solo golpea una vez.","Patada de 14 de daño. Ventaja: derribo para terminar una secuencia. Desventaja: alcance limitado y sin protección lateral."],
	["Guardia frontal durante 1,6 s. Ventaja: cubre ataques normales de frente. Desventaja: caminar lento, espalda expuesta y ataques que rompen guardia.","Counter de 0,45 s y respuesta de 14 de daño. Ventaja: castiga un ataque frontal. Desventaja: si nadie lo activa, queda expuesto 0,35 s.","Desplazamiento lateral de 0,24 s, 7 s de recarga. Ventaja: puede esquivar posicionándose a un costado; no concede invulnerabilidad, ni atraviesa muros."]
]
static func mega(slot: int) -> Dictionary:
	return MEGA[slot-1].duplicate(true) if slot >= 1 and slot <= 4 else {}
static func description(slot: int) -> String:
	var move := mega(slot)
	return "%.0f daño · %.0f s de recarga\nVentaja: %s\nDesventaja: %s" % [move.damage,move.cooldown,move.pros,move.cons] if not move.is_empty() else ""
static func base_description(index: int, slot: int) -> String:
	return BASE_DETAILS[index][slot-1] if index >= 0 and index < 4 and slot >= 1 and slot <= BASE_DETAILS[index].size() else "Sin módulo para esta habilidad."
