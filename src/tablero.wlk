import wollok.game.*
import fichas.*

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

  method ganador() = ganador

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

  method columnasLibres() = (0..columnas - 1).filter({ columna => !self.columnaLlena(columna) })

  // Las columnas donde se puede soltar esa ficha: las que reemplazan fichas (fantasma y bomba)
  // pueden caer también en una columna llena.
  method columnasDondePuedeSoltar(ficha) =
    if (ficha.reemplaza()) (0..columnas - 1) else self.columnasLibres()

  // Las columnas donde el jugador, soltando una ficha común, armaría una línea de ese largo o más.
  method columnasQueArman(jugador, largo) =
    self.columnasLibres().filter({ columna => self.armaLineaEn(jugador, columna, largo) })

  // Se prueba con una ficha que no se agrega al tablero, así que no cambia nada.
  method armaLineaEn(jugador, columna, largo) =
    self.formaLineaDe(new FichaComun(jugador = jugador, position = game.at(columna, self.alturaDe(columna))), largo)

  // Para que la CPU pruebe jugadas: un tablero igual a este (con copias de sus fichas) en el que
  // se suelta una copia de la ficha, y se devuelve para ver cómo habría quedado. Este tablero no se toca.
  method despuesDeSoltar(ficha, columna) {
    const prueba = new TableroHipotetico()
    fichas.forEach({ otra => prueba.agregar(otra.copia()) })
    prueba.soltar(ficha, columna)
    return prueba
  }

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

  // La ficha (una voladora) quedó en el aire: se llenan con fichas azules las celdas que tiene
  // debajo, desde la última ficha de su columna hasta ella.
  method sostener(ficha) {
    const columna = ficha.position().x()
    const debajo = self.cantidadDebajoDe(ficha)
    (ficha.position().y() - debajo).times({ i => self.agregarVisible(new FichaAzul(position = game.at(columna, debajo + i - 1))) })
  }

  method agregarVisible(ficha) {
    game.addVisual(ficha)
    self.agregar(ficha)
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
      self.mostrarCartelDeVictoria()
    }
  }

  method mostrarCartelDeVictoria() {
    cartelDeVictoria.ganador(ganador)
    game.addVisual(cartelDeVictoria)
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

  method formaCuatroEnLinea(ficha) = self.formaLineaDe(ficha, 4)

  // Hay una línea de ese largo si, para alguna de las 4 direcciones (horizontal, vertical y las dos
  // diagonales), la ficha tiene seguidas ese largo de fichas propias (contándola), mirando para los dos lados.
  method formaLineaDe(ficha, largo) =
    self.cantidadEnLinea(ficha, 1, 0) >= largo ||  // horizontal
    self.cantidadEnLinea(ficha, 0, 1) >= largo ||  // vertical
    self.cantidadEnLinea(ficha, 1, 1) >= largo ||  // diagonal ascendente ( / )
    self.cantidadEnLinea(ficha, 1, -1) >= largo    // diagonal descendente ( \ )

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
    const celda = game.at(x, y)
    const encontradas = fichas.filter({ ficha => ficha.estaEn(celda) && ficha.estaApoyada() })
    return if (encontradas.isEmpty()) null else encontradas.first()
  }
}

// Tablero para probar jugadas (lo usa la CPU): hace lo mismo que el Tablero, pero sin mostrar
// nada en pantalla: la ficha queda de una en su lugar en vez de caer, lo que se cae por una bomba
// también baja de una, y no aparecen carteles.
class TableroHipotetico inherits Tablero {
  override method soltar(ficha, columna) {
    ficha.position(game.at(columna, 0))   // primero la columna: de ahí la ficha calcula su fila
    ficha.position(game.at(columna, ficha.filaDeAterrizajeEn(self)))
    self.agregar(ficha)
    ficha.aterrizar(self)
  }

  // Las fichas flotantes bajan una celda a la vez hasta apoyarse; después se revisa si alguna
  // de las que bajó armó un 4 en línea (la primera que se encuentre es la ganadora).
  override method bajarFichasFlotantes() {
    const flotantes = fichas.filter({ ficha => self.estaFlotando(ficha) })
    self.bajarHastaApoyar(flotantes)
    flotantes.forEach({ ficha => self.revisarGanador(ficha) })
  }

  method estaFlotando(ficha) = self.cantidadDebajoDe(ficha) < ficha.position().y()

  method bajarHastaApoyar(flotantes) {
    const siguenFlotando = flotantes.filter({ ficha => self.estaFlotando(ficha) })
    if (!siguenFlotando.isEmpty()) {
      siguenFlotando.forEach({ ficha => ficha.bajar() })
      self.bajarHastaApoyar(siguenFlotando)
    }
  }

  override method agregarVisible(ficha) {
    self.agregar(ficha)
  }

  override method mostrarCartelDeVictoria() {}

  override method revisarEmpate() {}
}
