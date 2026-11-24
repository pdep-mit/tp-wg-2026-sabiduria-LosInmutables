import tablero.*
import fichas.*
import cpu.*

class Jugador {
  const property color
}

// Vista previa de la ficha fantasma: una copia que parpadea en la celda donde va a terminar
// cayendo la ficha en mano. No guarda nada propio: su posición y su imagen las calcula
// la partida cada vez que se dibuja, así que siempre acompaña a la ficha en mano.
object sombraDelFantasma {
  method position() = partida.posicionDeAterrizaje()

  method image() = partida.fichaEnMano().image()
}

// Partida 1 vs 1 local: siempre son los mismos dos jugadores, que se turnan.
object partida {
  const property tablero = new Tablero()
  const jugadorRojo = new Jugador(color = "rojo")
  const jugadorAmarillo = new Jugador(color = "amarillo")
  var jugadorActual = jugadorRojo
  var property fichaEnMano = new FichaComun(jugador = jugadorRojo)
  // Si es true, el jugador amarillo es la CPU (la elige pantallaJuego al mostrarse).
  var property contraCPU = false
  // Cómo se reparten las fichas en cada turno (también la elige pantallaJuego al mostrarse).
  var property reparto = eleccionDeFichas
  // Columna sobre la que "flota" la ficha en mano (fila extra, arriba del tablero), y con la que se empieza.
  const columnaInicial = 3
  var columnaActual = columnaInicial

  method jugadorActual() = jugadorActual

  // Mientras nadie ganó ni empataron se puede seguir jugando. Una vez que termina la partida,
  // el tablero queda congelado: ni se mueve la ficha en mano, ni se elige otro tipo, ni se suelta.
  method jugando() = !tablero.hayGanador() && !tablero.hayEmpate()

  // Columna en la que está la ficha en mano; después de soltar, es la de la última jugada del humano.
  method columnaActual() = columnaActual

  method jugadorRival() = if (jugadorActual == jugadorRojo) jugadorAmarillo else jugadorRojo

  method turnoDeLaCPU() = contraCPU && jugadorActual == jugadorAmarillo

  // Las teclas solo andan si la partida sigue y no le toca a la CPU.
  method puedeJugarElHumano() = self.jugando() && !self.turnoDeLaCPU()

  // Al salir de la pantalla de juego: se saca todo lo que la partida tenía en pantalla.
  method limpiar() {
    game.removeVisual(fichaEnMano)
    game.removeVisual(sombraDelFantasma)
    tablero.reiniciar()
    contraCPU = false
  }

  // Vuelve a dejar la partida como al principio: tablero vacío, sin ganador,
  // el turno para el rojo y una ficha común nueva en mano (la primera de la partida siempre es común).
  method reiniciar() {
    game.removeVisual(fichaEnMano)
    tablero.reiniciar()
    jugadorActual = jugadorRojo
    columnaActual = 3
    cpu.reiniciar()
    self.ponerEnMano(new FichaComun(jugador = jugadorRojo))
  }

  // Deja la ficha como la que está en mano y la muestra flotando en la columna actual.
  // Cualquier sombra que hubiera era de la ficha anterior: se saca (el parpadeo la vuelve
  // a mostrar si la nueva es fantasma).
  method ponerEnMano(ficha) {
    fichaEnMano = ficha
    self.actualizarPosicionDeFichaEnMano()
    game.addVisual(fichaEnMano)
    game.removeVisual(sombraDelFantasma)
  }

  method actualizarPosicionDeFichaEnMano() {
    fichaEnMano.position(game.at(columnaActual, tablero.filas()))
  }

  // Celda donde terminaría la ficha en mano si se soltara ahora en la columna actual.
  method posicionDeAterrizaje() = game.at(columnaActual, fichaEnMano.filaDeAterrizajeEn(tablero))

  // Se llama a intervalos regulares desde el program: si la sombra se ve la saca y si no se
  // ve la pone, lo que da el parpadeo. Solo aparece si la ficha en mano se está mostrando
  // (o sea, si estamos en la pantalla de juego) y reemplaza otra.
  method parpadearSombra() {
    if (game.hasVisual(sombraDelFantasma)) {
      game.removeVisual(sombraDelFantasma)
    } else if (game.hasVisual(fichaEnMano) && self.puedeJugarElHumano()) {
      game.addVisual(sombraDelFantasma)
    }
  }

  // Cambiar de tipo de ficha (solo si el reparto lo permite): se saca la que flotaba y se
  // pone la nueva en el mismo lugar.
  method elegir(ficha) {
    if (self.puedeJugarElHumano() && reparto.permiteElegir()) {
      game.removeVisual(fichaEnMano)
      self.ponerEnMano(ficha)
    }
  }

  method elegirComun() {
    self.elegir(new FichaComun(jugador = jugadorActual))
  }

  method elegirFantasma() {
    self.elegir(new FichaFantasma(jugador = jugadorActual))
  }

  method elegirBomba() {
    self.elegir(new FichaBomba(jugador = jugadorActual))
  }

  method elegirVoladora() {
    self.elegir(new FichaVoladora(jugador = jugadorActual))
  }

  // Mover la ficha flotante sin salirse del tablero.
  method desplazarIzquierda() {
    if (self.puedeJugarElHumano() && columnaActual > 0) {
      columnaActual = columnaActual - 1
      self.actualizarPosicionDeFichaEnMano()
    }
  }

  method desplazarDerecha() {
    if (self.puedeJugarElHumano() && columnaActual < tablero.columnas() - 1) {
      columnaActual = columnaActual + 1
      self.actualizarPosicionDeFichaEnMano()
    }
  }

  // Si hay una ficha cayendo o la columna está llena no se puede soltar y el turno no pasa.
  // Si la partida ya terminó o le toca a la CPU, puedeJugarElHumano() corta todo antes de llegar a mirar esto.
  method soltar() {
    if (self.puedeJugarElHumano() && !tablero.hayFichaCayendo() && fichaEnMano.puedeSoltarseEn(tablero, columnaActual)) {
      self.soltarEn(columnaActual)
    }
  }

  // Suelta la ficha en mano en esa columna y pasa el turno. La usa el humano (con la columna
  // que eligió con las flechas) y la CPU (con la que eligió ella).
  method soltarEn(columna) {
    tablero.soltar(fichaEnMano, columna)
    self.pasarTurno()
  }

  method pasarTurno() {
    jugadorActual = self.jugadorRival()
    self.ponerEnMano(reparto.fichaPara(jugadorActual))
    if (self.turnoDeLaCPU()) {
      cpu.jugar()
    }
  }
}
