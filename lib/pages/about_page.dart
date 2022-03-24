import 'package:flutter/material.dart';
import 'package:lsa_gloves/navigation/navigation_drawer.dart';

/// Page containing a brief description of the application and the project per
/// se, as well as contact information.
class AboutPage extends StatefulWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  _AboutPageState createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Acerca de"),
        ),
        drawer: NavDrawer(),
        body: ListView(
          padding: EdgeInsets.all(8),
          children: [
            Image.asset("assets/images/ic_launcher.png", height: 150),
            SizedBox(height: 8),
            Text("LSA Gloves",
                textAlign: TextAlign.center, textScaleFactor: 1.5),
            SizedBox(height: 8),
            Text("Acerca de", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
                "Se trata de un proyecto de final de carrera de ingeneiría de la UBA"
                " llevado adelante por Jazmín Ferreiro y Darius Maitia, con el asesoramiento de Pablo Deymonnaz y Sebastián García Marra."),
            SizedBox(height: 8),
            Text("¿Qué es LSA Gloves?",
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
                "LSA es el acrónimo de la lengua de señas argentina. Glove en inglés significa guante. Tal y como se infiere de su nombre, "
                "en este proyecto nos proponemos construir un guante con capacidad de interpretar gestos de lengua de señas, con el fin de"
                " intentar ayudar a reducir las barreras comunicacionales existentes entre personas oyentes y personas que se comunican "
                "primordialmente con lengua de señas argentina a raíz de alguna discapacidad. "),
            SizedBox(height: 8),
            Text("¿Cómo se usa?",
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Image.asset("assets/images/glove.jpg"),
            SizedBox(height: 8),
            Text("La aplicación se usa en conjunto con un guante como el de la imagen. Se debe conectar la aplicación con el guante"
                "mediante bluetooth (pantalla de conexiones). Una vez hecho esto en la sección de interpretaciones se pueden"
                " efectuar gestos con el guante colocado y la aplicación mostrará cuál es el gesto efectuado."
                "También en caso de querer extender el set de datos de gestos, existe la posibilidad de efectuar recolecciones de datos, "
                "debiendo uno efectuar un gesto repetidas veces, para posteriormente subir esos datos a la nube y actualizar "
                "el motor de inferencia con el nuevo gesto."),
            SizedBox(height: 8),
            Text("Contacto:",
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text("Darius Maitia: dmaitia@fi.uba.ar"),
            Text("Jazmín Ferreiro: jazminsofiaf@gmail.com")
          ],
        ));
  }
}
