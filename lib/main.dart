import 'package:flutter/material.dart';
import 'dart:math' as math;

void main() => runApp(const MaterialApp(
  home: AppRoboticaESPOCH(), 
  debugShowCheckedModeBanner: false
));

class AppRoboticaESPOCH extends StatelessWidget {
  const AppRoboticaESPOCH({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4, 
      child: Scaffold(
        appBar: AppBar(
          title: const Text("INGENIERÍA ROBÓTICA - ESPOCH", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            isScrollable: true, 
            tabs: [
              Tab(icon: Icon(Icons.grid_on), text: "MTH Inversa"),
              Tab(icon: Icon(Icons.calculate), text: "Cuaternios"),
              Tab(icon: Icon(Icons.menu_book), text: "Identidades"),
              Tab(icon: Icon(Icons.precision_manufacturing), text: "Algoritmo DH"),
            ],
            indicatorColor: Colors.white,
            labelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
        body: const TabBarView(
          children: [
            ModuloMatrizInversa(),
            ModuloCuaternios(),
            ModuloIdentidadesMaestro(),
            ModuloDenavitHartenberg(), 
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// MÓDULO 4: RESOLVEDOR DENAVIT-HARTENBERG
// =============================================================================
class ModuloDenavitHartenberg extends StatefulWidget {
  const ModuloDenavitHartenberg({super.key});
  @override
  State<ModuloDenavitHartenberg> createState() => _ModuloDenavitHartenbergState();
}

class _ModuloDenavitHartenbergState extends State<ModuloDenavitHartenberg> {
  int _gdlSeleccionados = 4; 
  
  final List<List<TextEditingController>> _tablaCtrls = List.generate(
    7, 
    (i) => List.generate(4, (j) => TextEditingController(text: "0"))
  );

  bool _calculado = false; 
  List<List<double>> _matricesIndividuales = []; 
  List<List<double>> _pasosMultiplicacion = [];  
  List<double> _matrizTFinal = List.filled(16, 0.0);

  @override
  void initState() {
    super.initState();
    _cargarValoresPorDefecto();
  }

  void _cargarValoresPorDefecto() {
    _tablaCtrls[0][0].text = "90";  
    _tablaCtrls[0][1].text = "2";   
    _tablaCtrls[0][2].text = "0";   
    _tablaCtrls[0][3].text = "0";   
    
    _tablaCtrls[1][0].text = "90";  
    _tablaCtrls[1][1].text = "3";   
    _tablaCtrls[1][2].text = "0";   
    _tablaCtrls[1][3].text = "90";  
    
    _tablaCtrls[2][0].text = "0";   
    _tablaCtrls[2][1].text = "4";   
    _tablaCtrls[2][2].text = "0";   
    _tablaCtrls[2][3].text = "0";   

    _tablaCtrls[3][0].text = "0";   
    _tablaCtrls[3][1].text = "1";   
    _tablaCtrls[3][2].text = "0";   
    _tablaCtrls[3][3].text = "0";   
  }

  void _limpiarFormulario() {
    setState(() {
      for (int i = 0; i < 7; i++) {
        for (int j = 0; j < 4; j++) {
          _tablaCtrls[i][j].text = "0";
        }
      }
      _calculado = false;
      _matricesIndividuales = [];
      _pasosMultiplicacion = [];
      _matrizTFinal = List.filled(16, 0.0);
    });
  }

  void _calcularCinematicaDirecta() {
    List<List<double>> transfIndividuales = [];
    List<List<double>> pasosHistorial = [];
    List<double> acumulada = [1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1]; 

    for (int i = 0; i < _gdlSeleccionados; i++) {
      double thetaGrad = evaluarEntrada(_tablaCtrls[i][0].text);
      double d = evaluarEntrada(_tablaCtrls[i][1].text);
      double a = evaluarEntrada(_tablaCtrls[i][2].text);
      double alphaGrad = evaluarEntrada(_tablaCtrls[i][3].text);

      double th = thetaGrad * (math.pi / 180.0);
      double al = alphaGrad * (math.pi / 180.0);

      List<double> Ai = [
        math.cos(th), -math.sin(th) * math.cos(al),  math.sin(th) * math.sin(al), a * math.cos(th),
        math.sin(th),  math.cos(th) * math.cos(al), -math.cos(th) * math.sin(al), a * math.sin(th),
        0,             math.sin(al),                 math.cos(al),                d,
        0,             0,                            0,                           1
      ];

      transfIndividuales.add(Ai);
      acumulada = multiplicarMatrices(acumulada, Ai);
      pasosHistorial.add(List.from(acumulada)); 
    }

    setState(() {
      _matricesIndividuales = transfIndividuales;
      _pasosMultiplicacion = pasosHistorial;
      _matrizTFinal = acumulada;
      _calculado = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              "RESOLVEDOR CINEMÁTICA DIRECTA (DH)", 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo)
            ),
          ),
          const SizedBox(height: 15),
          
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Número de Articulaciones (GDL):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  DropdownButton<int>(
                    value: _gdlSeleccionados,
                    items: List.generate(7, (index) => index + 1).map((int val) {
                      return DropdownMenuItem<int>(value: val, child: Text("$val GDL"));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _gdlSeleccionados = value;
                          _calculado = false;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 15),

          Row(
            children: const [
              Expanded(flex: 2, child: Text("Art.", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
              Expanded(flex: 3, child: Text("θ (Grados)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.indigo), textAlign: TextAlign.center)),
              Expanded(flex: 3, child: Text("d (Dist.)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.indigo), textAlign: TextAlign.center)),
              Expanded(flex: 3, child: Text("a (Dist.)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.indigo), textAlign: TextAlign.center)),
              Expanded(flex: 3, child: Text("α (Grados)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.indigo), textAlign: TextAlign.center)),
            ],
          ),
          const Divider(thickness: 1.5),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _gdlSeleccionados,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2, 
                      child: CircleAvatar(
                        radius: 12, 
                        backgroundColor: Colors.indigo.shade100, 
                        child: Text("${index + 1}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo))
                      )
                    ),
                    Expanded(flex: 3, child: _campoTextoCelda(_tablaCtrls[index][0])),
                    Expanded(flex: 3, child: _campoTextoCelda(_tablaCtrls[index][1])),
                    Expanded(flex: 3, child: _campoTextoCelda(_tablaCtrls[index][2])),
                    Expanded(flex: 3, child: _campoTextoCelda(_tablaCtrls[index][3])),
                  ],
                ),
              );
            },
          ),
          
          const SizedBox(height: 15),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _calcularCinematicaDirecta,
                icon: const Icon(Icons.play_arrow),
                label: const Text("CALCULAR MATRIZ FINAL T"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _limpiarFormulario,
                icon: const Icon(Icons.clear_all),
                label: const Text("LIMPIAR"),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
              ),
            ],
          ),

          if (_calculado) ...[
            const SizedBox(height: 25),
            const Text("1. MATRICES DE ESLABÓN INDIVIDUALES:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.indigo)),
            const Divider(),
            
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _matricesIndividuales.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.arrow_right, size: 18, color: Colors.blueGrey),
                          Text(" Matriz del Eslabón $index ", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                          Text("T", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.indigo.shade700, fontStyle: FontStyle.italic)),
                          Text("_${index + 1} :", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Center(child: _renderGridMatriz4x4(_matricesIndividuales[index], Colors.blue.shade50)),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 25),
            Text("2. MULTIPLICACIÓN EN CADENA (PASO A PASO):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.orange.shade900)),
            const Divider(),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _pasosMultiplicacion.length,
              itemBuilder: (context, index) {
                Widget cabeceraOperacion;
                if (index == 0) {
                  cabeceraOperacion = Row(
                    children: [
                      const Text("Asignación de la Base: ", style: TextStyle(fontSize: 12)),
                      Text("T", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade900, fontStyle: FontStyle.italic)),
                      const Text("₀₁ = ", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Text("⁰T₁", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo.shade700)),
                    ],
                  );
                } else {
                  cabeceraOperacion = Row(
                    children: [
                      const Text("Multiplicación acumulada: ", style: TextStyle(fontSize: 12)),
                      Text("T", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade900, fontStyle: FontStyle.italic)),
                      Text("₀${index + 1} = T₀$index × ", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Text("${index}T${index + 1}", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo.shade700)),
                    ],
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(4)),
                        child: cabeceraOperacion,
                      ),
                      const SizedBox(height: 6),
                      Center(child: _renderGridMatriz4x4(_pasosMultiplicacion[index], const Color(0xFFFFF3E0))),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 30),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("MATRIZ FINAL GLOBAL (", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red)),
                  Text("T", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red, fontStyle: FontStyle.italic)),
                  Text("₀$_gdlSeleccionados)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Center(child: _renderGridMatriz4x4(_matrizTFinal, Colors.green.shade50)),
            const SizedBox(height: 15),
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.shade300)),
                child: Text(
                  "Coordenadas del Extremo Final:\nX = ${_matrizTFinal[3].toStringAsFixed(3)}   |   Y = ${_matrizTFinal[7].toStringAsFixed(3)}   |   Z = ${_matrizTFinal[11].toStringAsFixed(3)}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 12, height: 1.5)
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _campoTextoCelda(TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12),
        decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.all(6)),
      ),
    );
  }

  Widget _renderGridMatriz4x4(List<double> mat, Color bg) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320), 
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade400, width: 1.5)
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, 
          childAspectRatio: 1.4, 
          crossAxisSpacing: 4,
          mainAxisSpacing: 4
        ),
        itemCount: 16,
        itemBuilder: (ctx, i) {
          bool esUltimaFila = i >= 12;
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4), 
              color: esUltimaFila ? Colors.grey.shade100 : bg
            ),
            child: Center(
              child: Text(
                mat[i].toStringAsFixed(3), 
                style: TextStyle(
                  fontSize: 11, 
                  fontWeight: FontWeight.bold,
                  color: esUltimaFila ? Colors.black54 : Colors.indigo.shade900
                )
              )
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// MÓDULO 1: MATRIZ DE TRANSFORMACIÓN HOMOGÉNEA
// =============================================================================
class ModuloMatrizInversa extends StatefulWidget {
  const ModuloMatrizInversa({super.key});
  @override
  State<ModuloMatrizInversa> createState() => _ModuloMatrizInversaState();
}

class _ModuloMatrizInversaState extends State<ModuloMatrizInversa> {
  final List<TextEditingController> _ctrls = List.generate(16, (i) => 
    TextEditingController(text: i % 5 == 0 ? "1" : "0"));
  List<double> _resultado = List.filled(16, 0.0);
  bool _calculado = false;

  void _limpiarMatriz() {
    setState(() {
      for (int i = 0; i < 16; i++) {
        _ctrls[i].text = (i % 5 == 0) ? "1" : "0";
      }
      _calculado = false;
      _resultado = List.filled(16, 0.0);
    });
  }

  void _calcularInversa() {
    List<double> m = _ctrls.map((c) => evaluarEntrada(c.text)).toList();
    double rt00 = m[0], rt01 = m[4], rt02 = m[8];
    double rt10 = m[1], rt11 = m[5], rt12 = m[9];
    double rt20 = m[2], rt21 = m[6], rt22 = m[10];
    double px = m[3], py = m[7], pz = m[11];
    double npx = -(rt00 * px + rt01 * py + rt02 * pz);
    double npy = -(rt10 * px + rt11 * py + rt12 * pz);
    double npz = -(rt20 * px + rt21 * py + rt22 * pz);

    setState(() {
      _resultado = [rt00, rt01, rt02, npx, rt10, rt11, rt12, npy, rt20, rt21, rt22, npz, 0, 0, 0, 1];
      _calculado = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text("ENTRADA: MATRIZ T (4x4)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
          const SizedBox(height: 10),
          _gridMatriz(_ctrls, true),
          const SizedBox(height: 15),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _calcularInversa, 
                icon: const Icon(Icons.sync_alt),
                label: const Text("INVERTIR MTH"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: _limpiarMatriz,
                icon: const Icon(Icons.clear),
                label: const Text("LIMPIAR"),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
              )
            ],
          ),
          if (_calculado) ...[
            const SizedBox(height: 25),
            const Text("RESULTADO: T⁻¹", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            _gridMatriz(_resultado, false),
          ]
        ],
      ),
    );
  }

  Widget _gridMatriz(List<dynamic> items, bool isInput) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 1.4),
      itemCount: 16,
      itemBuilder: (ctx, i) => isInput 
        ? Container(
            margin: const EdgeInsets.all(2),
            child: TextField(
              controller: items[i], 
              textAlign: TextAlign.center, 
              style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.all(8))
            ),
          )
        : Container(
            margin: const EdgeInsets.all(2), 
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4), color: Colors.grey.shade100), 
            child: Center(child: Text(items[i].toStringAsFixed(3), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)))
          ),
    );
  }
}

// =============================================================================
// MÓDULO 2: OPERACIONES DE CUATERNIOS
// =============================================================================
class ModuloCuaternios extends StatefulWidget {
  const ModuloCuaternios({super.key});
  @override
  State<ModuloCuaternios> createState() => _ModuloCuaterniosState();
}

class _ModuloCuaterniosState extends State<ModuloCuaternios> {
  final List<TextEditingController> _q1 = List.generate(4, (i) => TextEditingController(text: "0"));
  final List<TextEditingController> _q2 = List.generate(4, (i) => TextEditingController(text: "0"));
  String _res = "Esperando operación...";

  void _limpiarCuaternios() {
    setState(() {
      for (int i = 0; i < 4; i++) {
        _q1[i].text = "0";
        _q2[i].text = "0";
      }
      _res = "Esperando operación...";
    });
  }

  void _operar(String op) {
    List<double> a = _q1.map((c) => evaluarEntrada(c.text)).toList();
    List<double> b = _q2.map((c) => evaluarEntrada(c.text)).toList();
    setState(() {
      if (op == "SUMA") {
        _res = "SUMA: (${(a[0]+b[0]).toStringAsFixed(3)}, ${(a[1]+b[1]).toStringAsFixed(3)}i, ${(a[2]+b[2]).toStringAsFixed(3)}j, ${(a[3]+b[3]).toStringAsFixed(3)}k)";
      } else if (op == "PRODUCTO") {
        double q0 = a[0]*b[0] - a[1]*b[1] - a[2]*b[2] - a[3]*b[3];
        double q1 = a[0]*b[1] + a[1]*b[0] + a[2]*b[3] - a[3]*b[2];
        double q2 = a[0]*b[2] - a[1]*b[3] + a[2]*b[0] + a[3]*b[1];
        double q3 = a[0]*b[3] + a[1]*b[2] - a[2]*b[1] + a[3]*b[0];
        _res = "PRODUCTO ∘: ($q0, ${q1}i, ${q2}j, ${q3}k)";
      } else if (op == "NORMA") {
        double n = math.sqrt(a[0]*a[0] + a[1]*a[1] + a[2]*a[2] + a[3]*a[3]);
        _res = "NORMA ||Q1||: ${n.toStringAsFixed(4)}";
      } else {
        _res = "CONJUGADO Q1*: (${a[0]}, ${-a[1]}i, ${-a[2]}j, ${-a[3]}k)";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text("Q1 (s, x, y, z)", style: TextStyle(fontWeight: FontWeight.bold)),
          _filaCuaternio(_q1),
          const SizedBox(height: 15),
          const Text("Q2 (s, x, y, z)", style: TextStyle(fontWeight: FontWeight.bold)),
          _filaCuaternio(_q2),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8, runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              ...["SUMA", "PRODUCTO", "NORMA", "CONJUGADO"].map((op) => ElevatedButton(onPressed: () => _operar(op), child: Text(op))).toList(),
              ElevatedButton.icon(
                onPressed: _limpiarCuaternios, 
                icon: const Icon(Icons.refresh),
                label: const Text("LIMPIAR"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              )
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(15), width: double.infinity,
            decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.indigo)),
            child: Text(_res, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.indigo)),
          )
        ],
      ),
    );
  }

  Widget _filaCuaternio(List<TextEditingController> ctrls) {
    return Row(children: ctrls.map((c) => Expanded(child: Padding(padding: const EdgeInsets.all(2), child: TextField(controller: c, textAlign: TextAlign.center, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true))))).toList());
  }
}

// =============================================================================
// MÓDULO 3: FORMULARIO DE IDENTIDADES (COMPLETO CON TODAS LAS SECCIONES)
// =============================================================================
class ModuloIdentidadesMaestro extends StatelessWidget {
  const ModuloIdentidadesMaestro({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(15),
      child: Column(
        children: [
          const Text("FORMULARIO DE TRIGONOMETRÍA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo)),
          const Divider(thickness: 2),
          const SizedBox(height: 10),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 140, height: 140,
                child: CustomPaint(painter: TrianguloPainter()),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text("Razones Fundamentales", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      SizedBox(height: 5),
                      Text("sen θ = O / H", style: TextStyle(fontSize: 12)),
                      Text("cos θ = A / H", style: TextStyle(fontSize: 12)),
                      Text("tan θ = O / A", style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Secciones completas recuperadas y añadidas
          _bloqueIdentidad("Identidades Pitagóricas", [
            "sen²(α) + cos²(α) = 1", 
            "tan²(α) + 1 = sec²(α)",
            "1 + cot²(α) = csc²(α)"
          ], Colors.blue.shade100),
          
          _bloqueIdentidad("Ángulo Doble", [
            "sen(2α) = 2sen(α)cos(α)", 
            "cos(2α) = cos²(α) - sen²(α)",
            "cos(2α) = 1 - 2sen²(α)",
            "cos(2α) = 2cos²(α) - 1",
            "tan(2α) = [2tan(α)] / [1 - tan²(α)]"
          ], const Color(0xFFFFF3E0)),
          
          _bloqueIdentidad("Suma y Resta de Ángulos", [
            "sen(α ± β) = senα cosβ ± cosα senβ", 
            "cos(α ± β) = cosα cosβ ∓ senα senβ",
            "tan(α ± β) = [tanα ± tanβ] / [1 ∓ tanα tanβ]"
          ], const Color(0xFFE8F5E9)),

          _bloqueIdentidad("Ángulo Medio", [
            "sen(α / 2) = ±√[(1 - cosα) / 2]",
            "cos(α / 2) = ±√[(1 + cosα) / 2]",
            "tan(α / 2) = ±√[(1 - cosα) / (1 + cosα)]"
          ], Colors.purple.shade50),

          _bloqueIdentidad("Producto a Suma", [
            "senα cosβ = ½ [sen(α + β) + sen(α - β)]",
            "cosα cosβ = ½ [cos(α + β) + cos(α - β)]",
            "senα senβ = ½ [cos(α - β) - cos(α + β)]"
          ], Colors.pink.shade50),
        ],
      ),
    );
  }

  Widget _bloqueIdentidad(String titulo, List<String> items, Color color) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const Divider(),
          ...items.map((e) => Text(e, style: const TextStyle(fontFamily: 'monospace', fontSize: 12))),
        ],
      ),
    );
  }
}

class TrianguloPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.indigo..strokeWidth = 2..style = PaintingStyle.stroke;
    final path = Path()..moveTo(20, 120)..lineTo(120, 120)..lineTo(120, 20)..close();
    canvas.drawPath(path, p);
    canvas.drawArc(Rect.fromCircle(center: const Offset(20, 120), radius: 20), 0, -0.7, false, p);
    _txt(canvas, "θ", const Offset(45, 105));
    _txt(canvas, "H", const Offset(50, 50));
    _txt(canvas, "A", const Offset(65, 125));
    _txt(canvas, "O", const Offset(125, 65));
  }
  void _txt(Canvas c, String t, Offset o) {
    TextPainter(text: TextSpan(text: t, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), textDirection: TextDirection.ltr)..layout()..paint(c, o);
  }
  @override bool shouldRepaint(CustomPainter old) => false;
}

// =============================================================================
// OPERACIONES MATEMÁTICAS GLOBALES (NATIVAS)
// =============================================================================
List<double> multiplicarMatrices(List<double> A, List<double> B) {
  List<double> C = List.filled(16, 0.0);
  for (int i = 0; i < 4; i++) {
    for (int j = 0; j < 4; j++) {
      double suma = 0.0;
      for (int k = 0; k < 4; k++) {
        suma += A[i * 4 + k] * B[k * 4 + j];
      }
      C[i * 4 + j] = suma;
    }
  }
  return C;
}

double evaluarEntrada(String texto) {
  String entrada = texto.trim();
  if (entrada.isEmpty) return 0.0;
  
  double? numeroDirecto = double.tryParse(entrada);
  if (numeroDirecto != null) return numeroDirecto;
  
  return 0.0; 
}