import wollok.game.*

// Ficha: lo que tienen en común todas las fichas (jugador, posición y la mecánica de caer).
// No se crea directamente: se usan FichaComun, FichaFantasma, FichaBomba o FichaVoladora, que se
// diferencian en `image`, `reemplaza` y `filaDeAterrizajeEn`, cada una a su manera (polimorfismo).
//
// Lo que hace una ficha lo hace ella misma: le pregunta al tablero cuántas fichas hay en su
// columna, decide hasta qué fila tiene que bajar, baja sola y, al llegar, avisa que se apoyó
// (y la bomba y la voladora hacen además lo suyo). El tablero solo sabe qué fichas hay y responde sobre ellas.
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

  // Por defecto una ficha no reemplaza ninguna; la fantasma y la bomba sí.
  method reemplaza() = false

  // Las que reemplazan fichas se pueden soltar aunque la columna esté llena.
  method puedeSoltarseEn(tablero, columna) = self.reemplaza() || !tablero.columnaLlena(columna)

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
  method filaDeAterrizajeEn(tablero) = self.alturaDeSuColumnaEn(tablero)
  // Una ficha igual, para que la CPU pruebe jugadas sin tocar la verdadera.
  method copia() = new FichaComun(jugador = jugador, position = position)
}

// Ficha fantasma: atraviesa las primeras `atraviesa` fichas de la columna (contando desde arriba)
// y reemplaza la que encuentra. Cuántas atraviesa se sortea al crearla, de 0 a 5: con 5 llega
// hasta el fondo de una columna llena. Si la columna no tiene más de `atraviesa` fichas, cae
// como una común. Reemplaza fichas, así que se puede soltar aunque la columna esté llena.
class FichaFantasma inherits Ficha {
  const atraviesa = (0..5).anyOne()

  method image() = self.imagenDe("fantasma")
  override method reemplaza() = true
  method filaDeAterrizajeEn(tablero) {
    const altura = self.alturaDeSuColumnaEn(tablero)
    return if (altura > atraviesa) altura - 1 - atraviesa else altura
  }
  method copia() = new FichaFantasma(jugador = jugador, position = position, atraviesa = atraviesa)
}

// Ficha bomba: reemplaza la ficha de arriba de la columna (por eso se puede soltar aunque
// esté llena) y al llegar explota: rompe las fichas que tiene a la izquierda y a la derecha.
// Lo que estaba apoyado sobre las fichas rotas queda flotando y baja.
class FichaBomba inherits FichaComun {
  override method image() = self.imagenDe("bomba")

  override method reemplaza() = true

  override method filaDeAterrizajeEn(tablero) = (self.alturaDeSuColumnaEn(tablero) - 1).max(0)

  override method copia() = new FichaBomba(jugador = jugador, position = position)

  override method aterrizar(tablero) {
    self.explotar(tablero)
    super(tablero)
    tablero.bajarFichasFlotantes()
  }

  method explotar(tablero) {
    tablero.destruirEn(position.x() - 1, position.y())
    tablero.destruirEn(position.x() + 1, position.y())
  }
}

// Ficha voladora: aparece en el aire, `vuela` celdas por encima de lo que hay en la columna
// (se sortea al crearla, de 1 a 3, y no pasa del borde de arriba). Como no puede quedar flotando,
// al llegar el tablero le pone abajo las fichas azules que la sostienen. Después queda como una común.
class FichaVoladora inherits FichaComun {
  const vuela = (1..3).anyOne()

  override method image() = self.imagenDe("voladora")

  override method filaDeAterrizajeEn(tablero) = (self.alturaDeSuColumnaEn(tablero) + vuela).min(tablero.filas() - 1)

  override method aterrizar(tablero) {
    self.ponerAzulesDebajo(tablero)
    super(tablero)
  }

  // Llena con azules las celdas vacías que tiene debajo, desde la última ficha de su columna hasta ella.
  method ponerAzulesDebajo(tablero) {
    const debajo = tablero.cantidadDebajoDe(self)
    (position.y() - debajo).times({ i => tablero.agregarVisible(new FichaAzul(position = game.at(position.x(), debajo + i - 1))) })
  }

  override method copia() = new FichaVoladora(jugador = jugador, position = position, vuela = vuela)
}

// Las fichas azules no son de ningún equipo: solo sostienen a la voladora y tapan lugar.
// Nunca arman línea (ni cuentan para nadie), por eso al llegar no se revisa si ganó.
object sinEquipo {}

class FichaAzul inherits Ficha(jugador = sinEquipo) {
  method image() = "azul.png"

  override method aterrizar(tablero) {
    cayendo = false
  }

  method copia() = new FichaAzul(position = position)
}

// Cómo se reparten las fichas: de dos formas, y la partida usa la que se eligió en el menú
// (polimorfismo: las dos entienden fichaPara y permiteElegir).

// Al azar: a cada turno toca una ficha distinta y no se puede elegir (las teclas C, F, B y V no hacen nada).
// Funciona como una bolsa: tiene tantas fichas de cada tipo como su peso, y se saca una al azar.
// Cuanto más alto el peso, más seguido toca (la probabilidad es el peso dividido por la suma de todos).
// Para sumar una ficha nueva: un peso nuevo y una línea más en sacarDeLaBolsa.
object sorteoDeFichas {
  const pesoComun = 7
  const pesoFantasma = 2
  const pesoBomba = 1
  const pesoVoladora = 1

  method permiteElegir() = false

  method fichaPara(jugador) {
    const bolsa = []
    pesoComun.times({ i => bolsa.add({ new FichaComun(jugador = jugador) }) })
    pesoFantasma.times({ i => bolsa.add({ new FichaFantasma(jugador = jugador) }) })
    pesoBomba.times({ i => bolsa.add({ new FichaBomba(jugador = jugador) }) })
    pesoVoladora.times({ i => bolsa.add({ new FichaVoladora(jugador = jugador) }) })
    return bolsa.anyOne().apply()
  }
}

// A elección: cada turno empieza con una común y el jugador cambia de tipo con C, F, B y V.
object eleccionDeFichas {
  method permiteElegir() = true

  method fichaPara(jugador) = new FichaComun(jugador = jugador)
}
