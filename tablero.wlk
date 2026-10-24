import wollok.game.*

// Cartel de victoria: se agrega al juego recién cuando alguien gana y se saca al reiniciar.
// Hay una imagen por jugador (gano-rojo.png, gano-amarillo.png), de 5 columnas x 3 filas.
// El tablero visible es de 7 columnas por 7 filas (6 del juego más la de arriba) y la imagen
// se ancla en su esquina inferior izquierda: con columna 1 y fila 2 queda centrada. Si cambia
// el tamaño de las imágenes, columna y fila son los dos números para volver a centrarla.
object cartelDeVictoria {
  const columna = 1
  const fila = 2
  var ganador = null

  method ganador(jugador) {
    ganador = jugador
  }

  method position() = game.at(columna, fila)

  method image() = "gano-" + ganador.color() + ".png"
}

// Cartel de empate: igual que el de victoria, en el mismo lugar, pero gris (empate.png).
object cartelDeEmpate {
  method position() = cartelDeVictoria.position()

  method image() = "empate.png"
}

// Tablero de Cuatro en línea (7 columnas x 6 filas).
// Guarda todas las fichas que se soltaron, tanto las apoyadas como la que está cayendo.
// Cada ficha sabe su posición; el tablero sabe qué fichas hay y responde preguntas sobre ellas.
class Tablero {
  const property columnas = 7
  const property filas = 6
  const fichas = []
  var ganador = null
  var empate = false

  method hayGanador() = ganador != null

  method hayEmpate() = empate

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
    self.revisarEmpate()
  }

  // La bomba acaba de llegar: rompe lo que tiene a la izquierda y a la derecha.
  method romperAlLadoDe(bomba) {
    self.destruirEn(bomba.position().x() - 1, bomba.position().y())
    self.destruirEn(bomba.position().x() + 1, bomba.position().y())
  }

  method destruirEn(x, y) {
    const ficha = self.fichaApoyadaEn(x, y)
    if (ficha != null) {
      game.removeVisual(ficha)
      fichas.remove(ficha)
    }
  }

  // Cada ficha tiene que quedar apoyada sobre las que tiene debajo: su fila es la cantidad
  // de fichas que hay debajo de ella en su columna. Las que no están ahí caen hasta su fila.
  method bajarFichasFlotantes() {
    fichas.forEach({ ficha =>
      const fila = self.cantidadDebajoDe(ficha)
      if (fila < ficha.position().y()) {
        ficha.caerHasta(fila, self)
      }
    })
  }

  method cantidadDebajoDe(ficha) =
    fichas.filter({ otra => otra.estaEnColumna(ficha.position().x()) && otra.position().y() < ficha.position().y() }).size()

  // Si la ficha que acaba de apoyarse completa un 4 en línea, su jugador es el ganador.
  method revisarGanador(ficha) {
    if (!self.hayGanador() && self.formaCuatroEnLinea(ficha)) {
      ganador = ficha.jugador()
      cartelDeVictoria.ganador(ganador)
      game.addVisual(cartelDeVictoria)
    }
  }

  // Si se llenó el tablero y nadie ganó, es empate: no se puede soltar ninguna ficha más.
  method revisarEmpate() {
    if (!self.hayGanador() && self.estaLleno()) {
      empate = true
      game.addVisual(cartelDeEmpate)
    }
  }

  method estaLleno() = fichas.filter({ ficha => ficha.estaApoyada() }).size() == columnas * filas

  // Vuelve a dejar el tablero como recién empezado: sin fichas, sin ganador y sin empate.
  method reiniciar() {
    fichas.forEach({ ficha => game.removeVisual(ficha) })
    fichas.clear()
    game.removeVisual(cartelDeVictoria)
    game.removeVisual(cartelDeEmpate)
    ganador = null
    empate = false
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
