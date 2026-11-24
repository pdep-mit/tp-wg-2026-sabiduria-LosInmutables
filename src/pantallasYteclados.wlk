import wollok.game.*
import partida.*
import fichas.*

//==================[Fondo]==================
// El fondo es un visual más (a pantalla completa) que muestra el fondo de la pantalla actual.
// Se agrega UNA sola vez, primero de todos, así todo lo demás se dibuja encima.
// (game.boardGround no sirve para esto: no se actualiza si se cambia con el juego ya iniciado.)
object fondoDePantalla {
  method position() = game.at(0, 0)
  method image() = navegador.pantallaActual().fondo()
}

//==================[Navegador]==================
// Sabe cuál es la pantalla actual y se encarga de cambiarla.
// Guarda un historial para poder "volver" a la pantalla anterior.
object navegador {
  var pantallaActual = menuInicial
  const historial = []

  method pantallaActual() = pantallaActual

  method iniciar() {
    game.addVisual(fondoDePantalla)
    pantallaActual.mostrar()
  }

  method irA(pantalla) {
    historial.add(pantallaActual)
    self.cambiarA(pantalla)
  }

  method volver() {
    if (!historial.isEmpty()) {
      const anterior = historial.last()
      historial.remove(anterior)
      self.cambiarA(anterior)
    }
  }

  method irAlInicio() {
    historial.clear()
    self.cambiarA(menuInicial)
  }

  method cambiarA(pantalla) {
    pantallaActual.ocultar()
    pantallaActual = pantalla
    pantallaActual.mostrar()
  }
}

//==================[Teclado]==================
// UN solo teclado, "tonto": no sabe qué hace cada tecla, solo le avisa a la pantalla actual
// que se apretó. Cada pantalla decide qué hacer (polimorfismo).
object teclado {
  method configurar() {
    keyboard.a().onPressDo({ navegador.pantallaActual().teclaA() })
    keyboard.d().onPressDo({ navegador.pantallaActual().teclaD() })
    keyboard.left().onPressDo({ navegador.pantallaActual().teclaIzquierda() })
    keyboard.right().onPressDo({ navegador.pantallaActual().teclaDerecha() })
    keyboard.space().onPressDo({ navegador.pantallaActual().teclaEspacio() })
    keyboard.enter().onPressDo({ navegador.pantallaActual().teclaEnter() })
    keyboard.backspace().onPressDo({ navegador.pantallaActual().teclaBackspace() })
    keyboard.c().onPressDo({ navegador.pantallaActual().teclaC() })
    keyboard.f().onPressDo({ navegador.pantallaActual().teclaF() })
    keyboard.b().onPressDo({ navegador.pantallaActual().teclaB() })
    keyboard.v().onPressDo({ navegador.pantallaActual().teclaV() })
    keyboard.r().onPressDo({ navegador.pantallaActual().teclaR() })
  }
}

//==================[Pantalla]==================
// Clase base: define TODAS las teclas como "no hacer nada" y el ciclo mostrar/ocultar.
// Cada pantalla pisa (override) solo las teclas que le importan.
class Pantalla {
  // Imagen de fondo de la pantalla (cada una la define).
  method fondo()

  // Elementos visuales que se agregan al mostrar la pantalla y se sacan al ocultarla.
  method visuales() = []

  method mostrar() {
    self.visuales().forEach({ visual => game.addVisual(visual) })
  }

  method ocultar() {
    self.visuales().forEach({ visual => game.removeVisual(visual) })
  }

  method teclaA() {}
  method teclaD() {}
  method teclaIzquierda() {}
  method teclaDerecha() {}
  method teclaEspacio() {}
  method teclaEnter() {}
  method teclaC() {}
  method teclaF() {}
  method teclaB() {}
  method teclaV() {}
  method teclaR() {}

  // Por defecto, backspace vuelve a la pantalla anterior (en el menú inicial no hay a dónde volver).
  method teclaBackspace() {
    navegador.volver()
  }
}

//==================[Selector (composición)]==================
// Un cursor que recorre una lista de opciones. Es a la vez la lógica (indice) y el visual
// (marco que se dibuja sobre la opción actual). Lo reusan menú inicial y selección de tablero.
// Cada opción tiene que entender: position(), image() y elegir().
class Selector {
  const property opciones
  const property image
  var indice = 0

  method actual() = opciones.get(indice)

  method position() = self.actual().position()

  method siguiente() {
    indice = (indice + 1) % opciones.size()
  }

  method anterior() {
    indice = (indice - 1 + opciones.size()) % opciones.size()
  }

  method reiniciar() {
    indice = 0
  }
}

//==================[Pantalla con opciones (herencia)]==================
// Para las pantallas donde se navega entre opciones con un selector.
class PantallaConOpciones inherits Pantalla {
  const selector

  override method visuales() = selector.opciones() + [selector]

  override method mostrar() {
    selector.reiniciar()
    super()
  }

  override method teclaA() { selector.anterior() }
  override method teclaIzquierda() { selector.anterior() }
  override method teclaD() { selector.siguiente() }
  override method teclaDerecha() { selector.siguiente() }
  override method teclaEnter() { selector.actual().elegir() }
  override method teclaEspacio() { selector.actual().elegir() }
}

//==================[Configuración elegida en los menús]==================
// Lo que van decidiendo los jugadores y después consume la pantalla de juego / la partida.
object configuracion {
  var property modo = modoContraCPU
  var property reparto = sorteoDeFichas
  var property escenario = escenarioClasico
}

//==================[Modos de juego (polimorfismo)]==================
object modoContraCPU {
  method hayJugador2() = false
  method imagenDelContrincante() = "cpu.png"
}

object modo1vs1 {
  method hayJugador2() = true
  method imagenDelContrincante() = "jugador2.png"
}

//==================[Pantalla: menú inicial]==================
// Jugar | Cómo jugar. Se navega con A/D o las flechas y se elige con Enter/Espacio.
// Cada opción ocupa 3 columnas: en las columnas 0-2 y 4-6 (con la 3 libre en el medio) quedan centradas.
object opcionJugar {
  method position() = game.at(0, 2)
  method image() = "opcion-jugar.png"
  method elegir() { navegador.irA(pantallaSeleccionModo) }
}

object opcionComoJugar {
  method position() = game.at(4, 2)
  method image() = "opcion-como-jugar.png"
  method elegir() { navegador.irA(pantallaComoJugar) }
}

object menuInicial inherits PantallaConOpciones(
  selector = new Selector(opciones = [opcionJugar, opcionComoJugar], image = "cursor.png")
) {
  override method fondo() = "menu-inicial.png"
}

//==================[Pantalla: cómo jugar]==================
// Solo explicación (teclas, fichas, tableros). Backspace vuelve (heredado de Pantalla).
object pantallaComoJugar inherits Pantalla {
  override method fondo() = "como-jugar.png"
}

//==================[Pantalla: selección de modo]==================
// Jugador 1 a la izquierda, a la derecha CPU por defecto.
// Jugador 2 (Enter) se suma y reemplaza a la CPU. Jugador 1 (Espacio) confirma.
object panelJugador1 {
  method position() = game.at(0, 0)
  method image() = "jugador1.png"
}

object panelContrincante {
  method position() = game.at(4, 0)
  method image() = pantallaSeleccionModo.modoElegido().imagenDelContrincante()
}

object pantallaSeleccionModo inherits Pantalla {
  var property modoElegido = modoContraCPU

  override method fondo() = "seleccion-modo.png"

  override method visuales() = [panelJugador1, panelContrincante]

  override method mostrar() {
    modoElegido = modoContraCPU
    super()
  }

  // Jugador 2 se suma
  override method teclaEnter() {
    modoElegido = modo1vs1
  }

  // Jugador 1 confirma
  override method teclaEspacio() {
    configuracion.modo(modoElegido)
    navegador.irA(pantallaSeleccionFichas)
  }
}

//==================[Pantalla: selección de fichas]==================
// Cómo se reparten las fichas: al azar (a cada turno toca una) o a elección (con C, F, B y V).
// Igual que el menú inicial: dos opciones de 2 columnas, en las columnas 0-1 y 4-5, y un selector.
// Cada opción guarda el reparto que representa (ver sorteoDeFichas y eleccionDeFichas).
class OpcionDeFichas {
  const columna
  const property image
  const reparto

  method position() = game.at(columna, 2)

  method elegir() {
    configuracion.reparto(reparto)
    navegador.irA(pantallaSeleccionTablero)
  }
}

object opcionFichasAlAzar inherits OpcionDeFichas(columna = 0, image = "opcion-fichas-azar.png", reparto = sorteoDeFichas) {}

object opcionFichasAElegir inherits OpcionDeFichas(columna = 4, image = "opcion-fichas-elegir.png", reparto = eleccionDeFichas) {}

object pantallaSeleccionFichas inherits PantallaConOpciones(
  selector = new Selector(opciones = [opcionFichasAlAzar, opcionFichasAElegir], image = "cursor-fichas.png")
) {
  override method fondo() = "seleccion-fichas.png"
}

//==================[Pantalla: selección de tablero]==================
// Cada opción es un Escenario (miniatura + fondo del juego).
// Igual que el menú: las miniaturas ocupan 3 columnas y van en las columnas 0-2 y 4-6.
class Escenario {
  const property fondo
  const property image
  const columna
  const fila

  method position() = game.at(columna, fila)

  method elegir() {
    configuracion.escenario(self)
    navegador.irA(pantallaJuego)
  }
}

object escenarioClasico inherits Escenario(fondo = "tablero.png", image = "mini-clasico.png", columna = 0, fila = 3) {}

object escenarioNoche inherits Escenario(fondo = "tablero-noche.png", image = "mini-noche.png", columna = 4, fila = 3) {}

object pantallaSeleccionTablero inherits Pantalla {
  const escenarios = [escenarioClasico, escenarioNoche]
  const selectorJugador1 = new Selector(opciones = escenarios, image = "cursor-jugador1.png")
  const selectorJugador2 = new Selector(opciones = escenarios, image = "cursor-jugador2.png")

  override method fondo() = "seleccion-tablero.png"

  method hayJugador2() = configuracion.modo().hayJugador2()

  override method visuales() =
    if (self.hayJugador2()) escenarios + [selectorJugador1, selectorJugador2]
    else escenarios + [selectorJugador1]

  override method mostrar() {
    selectorJugador1.reiniciar()
    selectorJugador2.reiniciar()
    super()
  }

  // Jugador 1: A/D + Espacio
  override method teclaA() { selectorJugador1.anterior() }
  override method teclaD() { selectorJugador1.siguiente() }
  override method teclaEspacio() { selectorJugador1.actual().elegir() }

  // Jugador 2 (solo si el modo lo tiene): flechas + Enter
  override method teclaIzquierda() {
    if (self.hayJugador2()) { selectorJugador2.anterior() }
  }
  override method teclaDerecha() {
    if (self.hayJugador2()) { selectorJugador2.siguiente() }
  }
  override method teclaEnter() {
    if (self.hayJugador2()) { selectorJugador2.actual().elegir() }
  }
}

//==================[Pantalla: juego]==================
// Es la puerta de entrada a la partida: traduce las teclas a mensajes para `partida`.
// Hoy las teclas de ambos jugadores mueven la ficha del turno actual (igual que antes).
object pantallaJuego inherits Pantalla {
  override method fondo() = configuracion.escenario().fondo()

  override method mostrar() {
    super()
    partida.reiniciar()
    partida.contraCPU(!configuracion.modo().hayJugador2())
    partida.reparto(configuracion.reparto())
  }

  override method ocultar() {
    partida.limpiar()
    super()
  }

  override method teclaA() { partida.desplazarIzquierda() }
  override method teclaIzquierda() { partida.desplazarIzquierda() }
  override method teclaD() { partida.desplazarDerecha() }
  override method teclaDerecha() { partida.desplazarDerecha() }
  override method teclaEspacio() { partida.soltar() }
  override method teclaEnter() { partida.soltar() }
  // C, F, B y V solo sirven si el reparto permite elegir (la partida lo controla)
  override method teclaC() { partida.elegirComun() }
  override method teclaF() { partida.elegirFantasma() }
  override method teclaB() { partida.elegirBomba() }
  override method teclaV() { partida.elegirVoladora() }
  override method teclaR() { partida.reiniciar() }

  // No se sale mientras hay una ficha cayendo (si no, al aterrizar aparecería el cartel en otra pantalla).
  override method teclaBackspace() {
    if (!partida.tablero().hayFichaCayendo()) {
      navegador.irAlInicio()
    }
  }
}
