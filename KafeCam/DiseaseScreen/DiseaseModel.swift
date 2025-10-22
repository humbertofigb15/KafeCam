//
//  DiseaseModel.swift
//  KafeCam
//
//  Created by Bruno Rivera on 11/09/25.
//

import Foundation

struct DiseaseModel: Identifiable, Hashable {
    var id = UUID()
    var name: String
    var scientificName: String?
    var description: String
    var impact: String
    var prevention: String
    var imageName: String
}

let sampleDiseases: [DiseaseModel] = [
    .init(name: "Deficiencia de Nitrógeno",
          description: "La deficiencia de nitrógeno se manifiesta en las hojas adultas con una decoloración uniforme que avanza desde la vena central hacia los bordes y la punta de la hoja. Este síntoma aparece primero en las hojas más viejas o ya desarrolladas del arbusto y, si se agrava, progresa hacia las partes más jóvenes.",
          impact: """
            Una deficiencia de nitrógeno puede llevar a que la planta presente síntomas como:
            • Crecimiento pobre.
            • Caída de las hojas.
            • Reducción en la producción.
            • Los frutos se vuelven amarillos, crecen poco y se caen con facilidad.
            """,
          prevention: """
            Los posos de café son una gran fuente de nitrógeno y fósforo. Se pueden utilizar de la siguiente manera:
            **Aplicación directa:**
            • Seca los posos: Es importante que se sequen completamente para evitar moho.
            • Espolvorea: Aplica una capa fina sobre la tierra.
            • Mezcla: Remueve un poco la tierra para que se integren.
            **Fertilizante Líquido (Té de Café):**
            • Mezcla: Agrega dos tazas de posos en 5 litros de agua.
            • Reposa: Deja la mezcla reposar por 24 horas.
            • Cuela y Riega: Filtra el líquido y úsalo para regar.
            
            También se puede utilizar para enriquecer la composta.

            *Nota: Se recomienda su aplicación de manera moderada.*
            """,
          imageName: "DeficienciaNitrogeno"),

    .init(name: "Deficiencia de Hierro",
          description: "La deficiencia de hierro se manifiesta a través de una decoloración progresiva en las hojas jóvenes, que pueden llegar a tornarse de un color más blanco. Las hojas afectadas conservan el color verde en las venas, mientras que el resto de la hoja se vuelve pálido.",
          impact: """
            Los impactos de esta deficiencia en la planta son los siguientes:
            • Afecta el crecimiento general de la planta.
            • Provoca un color ámbar en el grano oro.
            """,
          prevention: """
            Una solución casera sencilla consiste de un abono casero de hierro para poder nutrir a las plantas con este nutriente vital para la planta. 
            
            **Abono casero de hierro**
            **Ingredientes:**
            • Un puñado de fuentes de hierro (clavos, tornillos, tuercas, etc.).
            • Botella de plástico con tapa.
            **Preparación:**
            1. Introduce la fuente de hierro en la botella.
            2. Llena la botella con agua y ciérrala.
            3. Deja la botella al aire libre por una semana.
            4. Cuando el líquido presente un color anaranjado, el abono estará listo.
            """,
          imageName: "DeficienciaHierro"),
          
    .init(name: "Deficiencia de Magnesio",
          description: "La deficiencia de magnesio se presenta en las hojas adultas. Se caracteriza por una decoloración entre la vena principal y las secundarias. A lo largo de la vena central, se forman franjas verdes que crean una figura parecida a una cuña invertida hacia la base.",
          impact: """
            El impacto de esta deficiencia en la planta es severo y afecta tanto a las hojas como a los frutos y al crecimiento general:
            • Provoca una caída rápida y severa de las hojas.
            • Resulta en la producción de granos vacíos.
            • Causa enanismo en las plantas.
            """,
          prevention: """
            **Remedio con sales de Epsom**
            **Ingredientes:**
            • 2 cucharadas de sales de Epsom.
            • 4 litros de agua.
            **Preparación:**
            1. Disuelve las sales en el agua.
            2. Agita bien hasta que las sales se disuelvan.
            3. Aplica con un atomizador o regando la base de la planta.
            
            En caso de no tener sales de Epsom a la mano, también se puede usar ceniza de madera para nutrir de magnesio a la planta de café. Para preparar la solución:
            1. Mezcla 3 cucharadas de ceniza por cada litro de agua.
            2. Deja reposar por 24 horas.
            3. Cuela y diluye en 10 litros de agua antes de regar.
            """,
          imageName: "DeficienciaMagnesio"),

    .init(name: "Deficiencia de Manganeso",
          description: """
            La deficiencia de manganeso se caracteriza por las siguientes afectaciones que provoca en las plantas, tales como:
            • Las hojas jóvenes presentan un color verde pálido, mientras que las venas permanecen verdes.
            • A medida que progresa, las hojas se vuelven más amarillas.
            • El primer par de hojas en la rama adquiere un color amarillo limón brillante a plena exposición solar.
            • Tiende a ser más severa en la época de lluvia.
            """,
          impact: """
            El impacto de esta deficiencia a la planta de café puede presentar problemas como:
            • Perjudica la fotosíntesis, reduciendo el crecimiento.
            • Altera la absorción de otros nutrientes como hierro o calcio.
            • En casos graves, puede provocar necrosis (muerte del tejido).
            """,
          prevention: """
            Este biopreparado casero consiste de una solución sólida que se asemeja a la composta para nutrir las plantas de café. 
            
            **Composta rica en manganeso**
            **Ingredientes:**
            • Restos vegetales: Hojas, cáscaras de frutas.
            • Restos de granos integrales: Arroz, avena.
            • Posos de café.
            • Frutos secos triturados.
            • Restos de legumbres.
            **Preparación:**
            1. Mezcla todos los ingredientes en una compostera.
            2. Asegúrate de que la mezcla esté aireada y húmeda.
            3. Deja que la materia se descomponga durante varias semanas o meses hasta obtener una composta madura y oscura.
            """,
          imageName: "DeficienciaManganeso"),

    .init(name: "Roya del Café",
          scientificName: "Hemileia vastatrix",
          description: "La roya del café es una enfermedad devastadora que ataca principalmente a las hojas de la planta de café, impidiendo que realicen la fotosíntesis correctamente. Se identifica por la aparición de manchas amarillas en la parte superior de las hojas y un polvo anaranjado (esporas) en la hoja de la planta. A medida que la enfermedad avanza, estas manchas se agrandan y pueden unirse, volviéndose de color marrón o gris.",
          impact: """
            El impacto de la roya del café es severo y puede tener consecuencias agrícolas a largo plazo:
            • Defoliación: Caída prematura de las hojas que debilita la planta.
            • Reducción del rendimiento: Afecta la cantidad y calidad de los granos.
            • Muerte de la planta: En casos graves, puede matar la planta en hasta dos años.
            """,
          prevention: """
            **Recomendaciones generales:**
            • No visitar cultivos con roya y cultivos sanos el mismo día (en caso de ser necesario cambiarse la ropa para evitar la propagación de roya).
            • Fertilizar los cultivos al menos un día antes de la floración, para que las plantas tengan defensas fuertes.
            • Tener cultivos diversos, ya que al estar con otras variedades de plantas se fortalece el suelo y hay mayor cantidad de nutrientes disponibles para las plantas de café.
            • Evitar el uso de químicos, ya que debilitan el suelo y eliminan también a insectos y microorganismos benéficos para las plantas de café.
            
            Adicionalmente, existen diversas opciones de biopreparados caseros que tienen propiedades muy nutritivas para las plantas y que también funcionan como preventivo para el desarrollo de enfermedades causadas por hongos. Para el caso de la roya, hay 2 opciones disponibles que pueden ayudar a prevenir la enfermedad o combatirla en su estado temprano:
            
            **Biopreparado concentrado antihongos**
            Este biopreparado se puede usar como vitalizador de plantas, estimulador de crecimiento, y como preventivo de plagas y enfermedades. Protege contra enfermedades causadas por hongos y plagas en general. También es útil para alejar insectos come hojas.

            **Ingredientes:** 
            Para preparar 4 litros de este biopreparado, necesitarás:
            • 4 litros de agua  (preferiblemente de río o lluvia, sin sales).
            • Medio kilo de hojas, frutos y tallos frescos de plantas nativas (o 80 gramos si están secas). Se refiere a las hierbas o monte que crece en tus cultivos.
            • 225 gramos (1 taza) de hojas y tallos frescos de plantas medicinales (o 80 gramos si están secas). Puedes usar manzanilla, ortiguilla, pica pica, neem, romero, frijol, moringa, jaboncillo, repollo, chile, ajo, cebollín, menta o albahaca.
            • Un recipiente no metálico.
            • Un palo para mover la mezcla.
            • Un colador o malla fina.
            
            **Preparación:** 
            1. Cortar las plantas en pedazos grandes para facilitar su descomposición y colocarlos en el recipiente.
            2. Agregar el agua para que las plantas queden sumergidas.
            3. Revolver la mezcla con el palo. 
            4. Taparla muy bien, no hay necesidad de que sea hermético.
            5. Dejarla reposar de 3 a 14 días (2 semanas es lo recomendado), agitando o revolviendo cada 2 días.
            6. Filtrar el preparado. Ahora que el biopreparado está listo, lo puedes colocar directamente en tus cultivos o como agua de riego.

            **Té de cola de caballo**
            Es un concentrado de la planta cola de caballo que tiene una aplicación como fungicida natural para prevenir y tratar los primeros estados de las enfermedades causadas por hongos como mildiu, oídio, y roya en diferentes cultivos.

            **Ingredientes:** 
            • 250 gramos de hojas, frutos y tallos de plantas frescas de Cola de Caballo (Equisetum arvense).
            • 1 litro de agua para hervir el concentrado (es mejor agua sin sales como de río o lluvia).
            • 1 colador o malla fina
            • Recipiente u olla metálica para calentar
            • Recipiente plástico para diluir el biopreparado.
            
            **Preparación:**
            1. Hervir las plantas frescas de cola de caballo en el agua durante 60 minutos (después de una hora se liberan los silicatos que actúan en la planta).
            2. Filtrar y colar con el colador o malla.
            3. Enfriar y dejar reposar.
            4. Si ya quieres aplicarlo (lo recomendado) vas a diluir tu concentrado al 20% (una parte del preparado por cada 5 partes de agua).
            5. Después lo pasas a tu bomba de aplicación y listo para aplicarlo a tus cultivos (hojas y tallos).

            """,
          imageName: "Roya")
]
