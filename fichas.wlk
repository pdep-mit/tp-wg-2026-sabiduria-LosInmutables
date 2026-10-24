import wollok.game.*

// Ficha: lo que tienen en común todas las fichas (jugador, posición y la mecánica de caer).
// No se crea directamente: se usan FichaComun, FichaFantasma o FichaBomba, que se diferencian en
// `image`, `reemplaza` y `filaDeAterrizajeEn`, cada una a su manera (polimorfismo).
//
// La ficha se encarga de su propia caída: le pregunta al tablero cuántas fichas hay en su
// columna, decide hasta qué fila tiene que bajar, baja sola y, al llegar, avisa que se apoyó.
class Ficha {
  const property jugador
  var property position = null
  var cayendo = false
  

  const milisegundosPorCelda = 32

  method estaCayendo() = cayendo

  method estaApoyada() = !cayendo

  method estaEnColumna(columna) = position.x() == columna

  method estaEn(otraPosicion) = position.x() == otraPosicion.x() && position.y() == otraPosicion.y()

  // Cantidad de fichas apoyadas en la columna sobre la que está la ficha.
  method alturaDeSuColumnaEn(tablero) = tablero.alturaDe(position.x())

  method imagenDe(tipo) = tipo + "-" + jugador.color() + ".png"

  method bajar() {
    position = position.down(1)
  }

  // Empieza a caer hasta la fila indicada.
  method caerHasta(fila, tablero) {
    cayendo = true
    self.avanzarHasta(fila, tablero)
  }

  // Baja una celda y programa el siguiente paso; al llegar a su fila, se apoya.
  method avanzarHasta(fila, tablero) {
    if (position.y() > fila) {
      self.bajar()
      game.schedule(milisegundosPorCelda, { self.avanzarHasta(fila, tablero) })
    } else {
      self.aterrizar(tablero)
    }
  }

  method aterrizar(tablero) {
    cayendo = false
    tablero.apoyar(self)
  }
}

// Ficha común: queda apoyada arriba de las fichas que ya hay en la columna.
// No reemplaza ninguna: si la columna está llena no se puede soltar.
class FichaComun inherits Ficha {
  method image() = self.imagenDe("comun")
  method reemplaza() = false
  method filaDeAterrizajeEn(tablero) = self.alturaDeSuColumnaEn(tablero)
}

// Ficha fantasma: atraviesa las primeras `atraviesa` fichas de la columna (contando desde arriba)
// y reemplaza la que encuentra. Cuántas atraviesa se sortea al crearla, de 0 a 5: con 5 llega
// hasta el fondo de una columna llena. Si la columna no tiene más de `atraviesa` fichas, cae
// como una común. Reemplaza fichas, así que se puede soltar aunque la columna esté llena.
class FichaFantasma inherits Ficha {
  const atraviesa = (0..5).anyOne()

  method image() = self.imagenDe("fantasma")
  method reemplaza() = true
  method filaDeAterrizajeEn(tablero) {
    const altura = self.alturaDeSuColumnaEn(tablero)
    return if (altura > atraviesa) altura - 1 - atraviesa else altura
  }
}

// Ficha bomba: reemplaza la ficha de arriba de la columna (por eso se puede soltar aunque
// esté llena) y al llegar explota: rompe las fichas que tiene a la izquierda y a la derecha.
// Lo que estaba apoyado sobre las fichas rotas queda flotando y baja.
class FichaBomba inherits FichaComun {
  override method image() = self.imagenDe("bomba")

  override method reemplaza() = true

  override method filaDeAterrizajeEn(tablero) = (self.alturaDeSuColumnaEn(tablero) - 1).max(0)

  override method aterrizar(tablero) {
    tablero.romperAlLadoDe(self)
    super(tablero)
    tablero.bajarFichasFlotantes()
  }
}
