import wollok.game.*

// Tablero de Cuatro en línea (7 columnas x 6 filas).
// Guarda todas las fichas que se soltaron, tanto las apoyadas como la que está cayendo.
// Cada ficha sabe su posición; el tablero sabe qué fichas hay y responde preguntas sobre ellas.
class Tablero {
  const property columnas = 7
  const property filas = 6
  const fichas = []

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
    fichas.add(ficha)
    ficha.caerHasta(filaDeAterrizaje, self)
  }

  // La ficha avisa que terminó de caer. Si en su celda ya había otra ficha apoyada
  // (caso fantasma), la nueva la reemplaza.
  method apoyar(ficha) {
    const reemplazadas = fichas.filter({ otra => otra != ficha && otra.estaApoyada() && otra.estaEn(ficha.position()) })
    reemplazadas.forEach({ otra => game.removeVisual(otra) })
    fichas.removeAll(reemplazadas)
  }
}
