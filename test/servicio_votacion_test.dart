import 'package:flutter_test/flutter_test.dart';
import 'package:vota_dolores_hidalgo/models/opcion_votacion.dart';
import 'package:vota_dolores_hidalgo/models/votacion.dart';
import 'package:vota_dolores_hidalgo/logic/resultado_voto.dart';
import 'package:vota_dolores_hidalgo/logic/servicio_votacion.dart';

Votacion _crearVotacionDePrueba({DateTime? fechaCierre}) {
  return Votacion(
    pregunta: 'Pregunta de prueba',
    opciones: [
      OpcionVotacion(id: 'op1', texto: 'Opcion 1'),
      OpcionVotacion(id: 'op2', texto: 'Opcion 2'),
    ],
    fechaCierre: fechaCierre ?? DateTime.now().add(const Duration(days: 7)),
  );
}

void main() {
  //! Fase 1
  test('registrar un voto valido incrementa el contador de esa opcion', () {
    final votacion = _crearVotacionDePrueba();
    final servicio = ServicioVotacion(votacion);

    final resultado = servicio.registrarVoto(idUsuario: 'user1', idOpcion: 'op1');
    
    expect(resultado, ResultadoVoto.exitoso);
    expect(votacion.opciones[0].votos, 1); 
  });
 
 //! Fase 2
  test('votar por una opcion que no existe regresa opcionInvalida', () {
    final votacion = _crearVotacionDePrueba();
    final servicio = ServicioVotacion(votacion);

    final resultado = servicio.registrarVoto(idUsuario: 'user1', idOpcion: 'no-existe');
    
    expect(resultado, ResultadoVoto.opcionInvalida);
  });

  //! Fase 3
  test('un mismo usuario no puede votar dos veces', () {
    final votacion = _crearVotacionDePrueba();
    final servicio = ServicioVotacion(votacion);
    
    servicio.registrarVoto(idUsuario: 'user1', idOpcion: 'op1');
    final segundoIntento = servicio.registrarVoto(idUsuario: 'user1', idOpcion: 'op2');
    
    expect(segundoIntento, ResultadoVoto.usuarioYaVoto);
    expect(votacion.opciones[1].votos, 0); // op2 no debió incrementarse
  });

  //! Fase 4
  test('calcula el porcentaje de cada opcion correctamente', () {
    final votacion = _crearVotacionDePrueba();
    final servicio = ServicioVotacion(votacion);
    
    servicio.registrarVoto(idUsuario: 'u1', idOpcion: 'op1');
    servicio.registrarVoto(idUsuario: 'u2', idOpcion: 'op1');
    servicio.registrarVoto(idUsuario: 'u3', idOpcion: 'op1');
    servicio.registrarVoto(idUsuario: 'u4', idOpcion: 'op2');
    
    final resultados = servicio.obtenerResultados();
    final op1 = resultados.firstWhere((r) => r.opcion.id == 'op1');
    final op2 = resultados.firstWhere((r) => r.opcion.id == 'op2');
    
    expect(op1.porcentaje, 75.0);
    expect(op2.porcentaje, 25.0);
  });

  test('si no hay ningun voto, todos los porcentajes son 0', () {
    final votacion = _crearVotacionDePrueba();
    final servicio = ServicioVotacion(votacion);
    
    final resultados = servicio.obtenerResultados();
    
    expect(resultados.every((r) => r.porcentaje == 0), true);
  });

  //! Fase 5
  test('no se puede registrar un voto si la votacion ya expiro', () {
    final votacionExpirada = _crearVotacionDePrueba(
      fechaCierre: DateTime.now().subtract(const Duration(days: 1)), // Ya pasó
    );
    final servicio = ServicioVotacion(votacionExpirada);

    final resultado = servicio.registrarVoto(idUsuario: 'user1', idOpcion: 'op1');

    expect(resultado, ResultadoVoto.votacionExpirada);
  });

  //! Fase 6
  test('un usuario no puede cambiar su voto una vez registrado', () {
    final votacion = _crearVotacionDePrueba();
    final servicio = ServicioVotacion(votacion);

    // Primer voto por op1
    servicio.registrarVoto(idUsuario: 'user1', idOpcion: 'op1');
    
    // Intento de cambiar el voto a op2
    final segundoIntento = servicio.registrarVoto(idUsuario: 'user1', idOpcion: 'op2');

    expect(segundoIntento, ResultadoVoto.usuarioYaVoto);
    expect(votacion.opciones[0].votos, 1); // op1 se mantiene
    expect(votacion.opciones[1].votos, 0); // op2 no recibe el voto
  });

  //! Fase 7
  test('no se puede registrar un voto si la votacion aun no ha iniciado', () {
    final votacionFutura = Votacion(
      pregunta: 'Pregunta futura',
      opciones: [
        OpcionVotacion(id: 'op1', texto: 'Opcion 1'),
      ],
      fechaInicio:  DateTime.now().add(const Duration(days: 1)), // Inicia mañana
      fechaCierre: DateTime.now().add(const Duration(days: 7)),
    );
    final servicio = ServicioVotacion(votacionFutura);

    final resultado = servicio.registrarVoto(idUsuario: 'user1', idOpcion: 'op1');

    expect(resultado, ResultadoVoto.votacionExpirada);
  });

  //! Fase 8
  test('determinarGanador regresa la opcion con mas votos', () {
    final votacion = _crearVotacionDePrueba();
    final servicio = ServicioVotacion(votacion);

    // Damos más votos a 'op1'
    servicio.registrarVoto(idUsuario: 'user1', idOpcion: 'op1');
    servicio.registrarVoto(idUsuario: 'user2', idOpcion: 'op1');
    
    // Damos un voto a 'op2'
    servicio.registrarVoto(idUsuario: 'user3', idOpcion: 'op2');

    final ganadores = servicio.determinarGanador();

    expect(ganadores.length, 1);
    expect(ganadores.first.id, 'op1');
  });
}