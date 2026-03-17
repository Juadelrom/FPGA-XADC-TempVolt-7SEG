# FPGA-XADC-TempVolt-7SEG
RTL design in VHDL for the Nexys 4 DDR board. Features XADC integration for on-chip temperature/voltage monitoring, double dabble (bin2bcd) conversion, and a sample-and-hold multiplexed 7-segment display controller.

# Sistema de Adquisición y Visualización Multiplexada de Temperatura y Voltaje (XADC en FPGA)

Este repositorio contiene la implementación de un diseño RTL (VHDL) para el control del bloque IP **XADC** en una FPGA Artix-7 (placa Nexys 4 DDR). El sistema permite medir magnitudes físicas internas del circuito integrado (temperatura, voltaje de alimentación y voltaje de la VRAM), acondicionar digitalmente las señales y representarlas en un visualizador multiplexado de 7 segmentos.

## Descripción General del Sistema

El objetivo principal es muestrear magnitudes internas de la FPGA y mostrarlas al usuario mediante una interfaz física controlada por interruptores, liberando al procesador principal de esta carga computacional. 

El sistema realiza las siguientes etapas:
1. Adquisición de datos mediante el ADC interno (resolución de 12 bits).
2. Acondicionamiento matemático de las señales (escalado a enteros para evitar el uso de punto flotante).
3. Corrección de valores negativos (complemento a dos).
4. Conversión a formato BCD (algoritmo *Double Dabble*).
5. Multiplexado temporal y mitigación de errores visuales (segmentos fantasma) en el display de 7 segmentos.

### Arquitectura Completa del Sistema
A continuación, se muestra el diagrama de bloques completo del sistema, ilustrando la interconexión entre la unidad de control, el XADC y las entidades de la etapa de acondicionamiento:

![Diagrama de Bloques del Sistema Completo](img/fig3_arquitectura.png)
*(Figura 3: Arquitectura RTL del sistema de adquisición, acondicionamiento y visualización).*

---

## Descripción de los Módulos (Entidades VHDL)

El diseño está modularizado en varias entidades VHDL, cada una encargada de una etapa específica del procesamiento de la señal.

### 1. Bloque IP XADC
- **Descripción:** Utiliza el convertidor analógico-digital interno de la serie 7 de Xilinx configurado en modo *Continuous Sequence*. Adquiere cíclicamente la Temperatura, VCCINT y VCCBRAM sin necesidad de señales de inicio externas. Se comunica mediante el puerto DRP (Dynamic Reconfiguration Port).
- **Señales clave:** `daddr_in` (selección de registro), `do_out` (dato crudo), `drdy_out` (dato válido).

### 2. Funciones de Transferencia (`func_trans.vhd` y `func_trans_volt.vhd`)
- **Descripción:** Convierten el valor binario crudo del XADC a unidades físicas reales ($m^\circ C$ y $mV$). Para optimizar el hardware y no usar aritmética de punto flotante, se escala la función matemática por 1000.
  - **Temperatura (`func_trans.vhd`):** Resuelve $Temperatura (m^\circ C) = Valor ADC \times 123 - 273150$.
  - **Voltaje (`func_trans_volt.vhd`):** Resuelve $Voltaje (mV) = (Valor ADC / 4096) \times 3000$.
  
![Interfaz Funciones de Transferencia](img/fig9_12_interfaces_transferencia.png) 
*(Figuras 9 y 12: Interfaces de entrada/salida de los bloques matemáticos).*

### 3. Cálculo del Valor Absoluto (`valor_abs.vhd`)
- **Descripción:** El sensor de temperatura puede registrar valores negativos representados en Complemento a 2. Para evitar que la conversión a BCD genere un dato erróneo, este bloque detecta el bit de signo (MSB). Si es '1', calcula su valor absoluto multiplicándolo por -1.
- **Salida:** Entrega el valor positivo y una señal `signo_o` para informar al sistema.

### 4. Conversión a Formato BCD (`bin2bcd.vhd`)
- **Descripción:** Transforma el valor binario natural positivo a Decimal Codificado en Binario (BCD) para extraer los dígitos (unidades, decenas, etc.) que irán al display.
- **Algoritmo:** Implementa el eficiente algoritmo iterativo **Double Dabble** (Shift-and-Add-3) utilizando una FSM para el control de los desplazamientos y lógica combinacional para la corrección.

![Diagrama de flujo del algoritmo Double Dabble](img/fig20_flujo_bcd.png)
*(Figura 20: Diagrama de flujo del algoritmo Shift-and-Add-3).*

### 5. Control del Visualizador 7 Segmentos (`visu7seg.vhd`)
- **Descripción:** Traduce los dígitos BCD a la codificación de 7 segmentos de ánodo común de la placa Nexys 4 DDR.
- **Características especiales:**
  - **Multiplexado temporal:** Emplea un contador para alternar los ánodos a ~190 Hz (1.31 ms).
  - **Estabilización (*Sample & Hold*):** Para evitar "segmentos fantasma" debidos a la altísima frecuencia de actualización del XADC, refresca los datos a mostrar a una tasa estable de ~3 Hz.
  - **Punto decimal y Reposo:** Gestión dinámica del punto decimal según la magnitud leída y representación de guiones (`----`) cuando no hay lecturas activas.

![Efecto Sample and Hold Visualizador](img/fig32_sample_hold.png)
*(Figura 32: Cronograma de la lógica de estabilización visual).*

### 6. Unidad de Control (Top Level) (`adc_top_level.vhd`)
- **Descripción:** Es la entidad superior que instancia todos los bloques descritos. Contiene un proceso secuencial (`Process P1`) encargado del enrutamiento dinámico de los buses de datos. Dado que la conversión BCD y el display son recursos compartidos, este bloque multiplexa qué dato accede a la etapa final en función de los interruptores de la placa.

---

## Interfaz Física y Modos de Funcionamiento

El control del sistema se realiza físicamente en la placa Nexys 4 DDR a través de interruptores con prioridad (La temperatura prevalece sobre el voltaje).

* `SW0`: Reset del sistema.
* `SW1` (`temp_sel`): Activa la lectura de Temperatura.
* `SW2` (`volt_sel`): Activa la lectura de Voltaje.
* `SW3` (`vram_sel`): Alterna entre Voltaje de alimentación (VCCINT) o VRAM (VCCBRAM).

### 1. Modo Reposo (`SW1=0`, `SW2=0`)
Visualización de guiones para confirmar que el sistema está encendido pero sin magnitud seleccionada.

![Modo Reposo en FPGA](img/fig39_modo_reposo.png)

### 2. Modo Temperatura (`SW1=1`)
Visualización de la temperatura interna del silicio con resolución de décimas de grado ($XX.X ^\circ C$).

![Modo Temperatura en FPGA](img/fig40_modo_temp.png)

### 3. Modo Voltaje (`SW1=0`, `SW2=1`)
Visualización de voltajes internos. Muestra la parte entera y tres decimales ($X.XXX V$). Dependiendo de `SW3` mostrará VCCINT o VCCBRAM.

![Modo Voltaje en FPGA](img/fig41_modo_volt.png)

---

## Documentación Completa

Para un análisis exhaustivo del hardware diseñado, las cartas ASM (Algorithmic State Machine), los diagramas temporales y las fórmulas matemáticas de escalado empleadas, por favor consulte la memoria completa del proyecto:

🔗 [**Ver Memoria Descriptiva del Sistema (PDF)**](docs/memoria_sistema.pdf)

## Utilización de Recursos (FPGA)

El diseño ha sido altamente optimizado para minimizar el consumo de recursos de la FPGA (Artix-7 XC7A100T), haciendo un uso eficiente de la lógica combinacional y minimizando el impacto en el sistema global. Destaca el uso de **solo 2 bloques DSP** para las operaciones aritméticas de escalado.

A continuación, se presenta el resumen de utilización del módulo principal (`adc_top_level`):

| Recursos | Utilizado | Disponible | % Uso |
| :--- | :---: | :---: | :---: |
| **Slice LUTs** | 116 | 63,400 | < 1% |
| **Slice Registers** | 256 | 126,800 | < 1% |
| **Slices** | 56 | 15,850 | < 1% |
| **DSPs** | 2 | 240 | < 1% |
| **Bonded IOB** (Pines) | 21 | 210 | 10% |
| **XADC** | 1 | 1 | 100% |

