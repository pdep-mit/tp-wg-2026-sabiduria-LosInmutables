import wollok.game.*

// Objeto fijo en el centro del tablero, invisible mientras nadie ganó. Sirve de ancla para
// que el cartel de victoria aparezca siempre en el mismo lugar, en vez de pegado a la ficha
// que completó la línea. cartel.png es una imagen vacía (transparente) de una sola celda: lo
// único que se llega a ver es el globo de game.say. El tablero visible es de 7 columnas por
// 7 filas (6 del juego más la de arriba), así que la celda del medio es la (3,3): como la
// imagen ocupa una sola celda, ubicarla ahí ya la centra. Si cartel.png pasara a ocupar más
// de una celda, columna y fila son los dos números para correr y volver a centrarla.
object cartelDeVictoria {
  const columna = 5
  const fila = 5

  method position() = game.at(columna, fila)

  method image() = "cartel.png"
}

// Tablero de Cuatro en línea (7 columnas x 6 filas).
// Guarda todas las fichas que se soltaron, tanto las apoyadas como la que está cayendo.
// Cada ficha sabe su posición; el tablero sabe qué fichas hay y responde preguntas sobre ellas.
class Tablero {
  const property columnas = 7
  const property filas = 6
  const fichas = []
  var ganador = null

  method ganador() = ganador

  method hayGanador() = ganador != null

  method agregar(ficha) {
    fichas.add(ficha)
  }

  method fichasApoyadasEn(columna) =
    fichas.filter({ ficha => ficha.estaApoyada() && ficha.estaEnColumna(columna) })

  // Cantidad de fichas apoyadas en la columna: también es la primera fila libre (0 = la de abajo).
  method alturaDe(columna) = self.fichasApoyadasEn(columna).size()

  method columnaLlena(columna) = self.alturaDe(columna) == filas

  method hayFichaCayendo() = fichas.any({ ficha => ficha.estaCayendo() })

  // La ficha ya estaba flotando en la fila extra sobre el tablero (ya es un visual).
  // Primero se le pregunta dónde va a aterrizar (ella le consulta al tablero la altura de su columna,
  // por eso todavía no puede estar registrada) y después se la registra y empieza a caer.
  method soltar(ficha, columna) {
    ficha.position(game.at(columna, filas))
    const filaDeAterrizaje = ficha.filaDeAterrizajeEn(self)
    self.agregar(ficha)
    ficha.caerHasta(filaDeAterrizaje, self)
  }

  // La ficha avisa que terminó de caer. Si en su celda ya había otra ficha apoyada
  // (caso fantasma), la nueva la reemplaza. Hecho eso, se fija si esa jugada ganó la partida.
  method apoyar(ficha) {
    const reemplazadas = fichas.filter({ otra => otra != ficha && otra.estaApoyada() && otra.estaEn(ficha.position()) })
    reemplazadas.forEach({ otra => game.removeVisual(otra) })
    fichas.removeAll(reemplazadas)
    self.revisarGanador(ficha)
  }

  // Si la ficha que acaba de apoyarse completa un 4 en línea, su jugador es el ganador.
  method revisarGanador(ficha) {
    if (self.formaCuatroEnLinea(ficha)) {
      ganador = ficha.jugador()
      game.addVisual(cartelDeVictoria)
      self.avisarVictoria()
    }
  }

  // game.say arma un globo que se borra solo a los 2 segundos. Para que quede fijo, este
  // método se vuelve a programar a sí mismo con game.schedule (igual que Ficha.avanzarHasta)
  // y se repite refrescando el globo mientras haya ganador; se corta solo cuando reiniciar()
  // pone el ganador en null.
  method avisarVictoria() {
    if (self.hayGanador()) {
      game.say(cartelDeVictoria, ganador.color() + " ganó! Presioná R para reiniciar.")
      game.schedule(1000, { self.avisarVictoria() })
    }
  }

  // Vuelve a dejar el tablero como recién empezado: sin fichas y sin ganador.
  method reiniciar() {
    fichas.forEach({ ficha => game.removeVisual(ficha) })
    fichas.clear()
    if (self.hayGanador()) {
      game.removeVisual(cartelDeVictoria)
    }
    ganador = null
  }

  // Hay 4 en línea si, para alguna de las 4 direcciones (horizontal, vertical y las dos
  // diagonales), la ficha tiene 3 o más fichas propias seguidas, contando para los dos lados.
  method formaCuatroEnLinea(ficha) =
    self.cantidadEnLinea(ficha, 1, 0) >= 4 ||  // horizontal
    self.cantidadEnLinea(ficha, 0, 1) >= 4 ||  // vertical
    self.cantidadEnLinea(ficha, 1, 1) >= 4 ||  // diagonal ascendente ( / )
    self.cantidadEnLinea(ficha, 1, -1) >= 4    // diagonal descendente ( \ )

  // dx y dy son cuánto se mueve en x y en y para ir "hacia ese lado" (por ejemplo, dx=1 dy=0
  // es ir a la derecha). La línea completa es la ficha misma, más lo que sigue hacia ese lado,
  // más lo que sigue hacia el lado opuesto (dx y dy con el signo cambiado).
  method cantidadEnLinea(ficha, dx, dy) =
    1 + self.contarEnSentido(ficha, dx, dy) + self.contarEnSentido(ficha, dx * -1, dy * -1)

  // Mira la celda siguiente en ese sentido: si hay una ficha apoyada del mismo jugador,
  // la cuenta y sigue buscando una celda más allá, en el mismo sentido.
  method contarEnSentido(ficha, dx, dy) {
    const siguiente = self.fichaApoyadaEn(ficha.position().x() + dx, ficha.position().y() + dy)
    if (siguiente != null && siguiente.jugador() == ficha.jugador()) {
      return 1 + self.contarEnSentido(siguiente, dx, dy)
    } else {
      return 0
    }
  }

  // La ficha apoyada en esa posición, o null si no hay ninguna (incluye posiciones fuera del tablero).
  method fichaApoyadaEn(x, y) {
    const encontradas = fichas.filter({ ficha => ficha.estaApoyada() && ficha.estaEn(game.at(x, y)) })
    return if (encontradas.isEmpty()) null else encontradas.first()
  }
}
