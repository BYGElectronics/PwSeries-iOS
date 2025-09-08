import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TecladoPinWidget extends StatefulWidget {
  final ValueChanged<String>? onPinChange;
  final ValueChanged<String> onPinComplete;

  const TecladoPinWidget({
    Key? key,
    required this.onPinComplete,
    this.onPinChange,
  }) : super(key: key);

  @override
  State<TecladoPinWidget> createState() => _TecladoPinWidgetState();
}

class _TecladoPinWidgetState extends State<TecladoPinWidget> {
  String _pin = '';
  static const _maxLength = 6;
  bool _mostrarPin = false;

  void _agregarDigito(String digito) {
    if (_pin.length < _maxLength) {
      setState(() => _pin += digito);
      widget.onPinChange?.call(_pin);
    }
  }

  void _borrarDigito() {
    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
      widget.onPinChange?.call(_pin);
    }
  }

  void _confirmarPin() {
    if (_pin.isNotEmpty) widget.onPinComplete(_pin);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isTablet = mq.size.shortestSide >= 600; // umbral estándar tablet
    final spacing = isTablet ? 18.0 : 14.0;

    final teclas = ['1','2','3','4','5','6','7','8','9','X','0','V'];

    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _mostrarPin ? _pin : '•' * _pin.length,
              style: TextStyle(
                fontSize: isTablet ? 32 : 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              icon: Icon(
                _mostrarPin ? Icons.visibility_off : Icons.visibility,
                // no fijamos color para respetar el tema actual
              ),
              onPressed: () => setState(() => _mostrarPin = !_mostrarPin),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Divider(thickness: 1, color: Theme.of(context).dividerColor),
        const SizedBox(height: 8),

        // El teclado ocupa SOLO el espacio restante
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) {
              const cols = 3;
              const rows = 4;

              // Tamaño máximo por ancho y por alto (corregido spacing)
              final sizeByWidth  = (c.maxWidth  - spacing * (cols - 1)) / cols;
              final sizeByHeight = (c.maxHeight - spacing * (rows - 1)) / rows;

              // Escogemos el menor y dejamos margen (0.92) para evitar desbordes
              double keySize = math.min(sizeByWidth, sizeByHeight) * 0.92;

              // (Opcional) acotar tamaños extremos
              keySize = keySize.clamp(44.0, isTablet ? 120.0 : 96.0);

              final gridWidth  = keySize * cols + spacing * (cols - 1);
              final gridHeight = keySize * rows + spacing * (rows - 1);

              return Center(
                child: SizedBox(
                  width: gridWidth,
                  height: gridHeight,
                  child: Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    alignment: WrapAlignment.center,
                    children: teclas.map((v) {
                      return _buildTecla(
                        v,
                        size: keySize,
                        esBorrar: v == 'X',
                        esConfirmar: v == 'V',
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTecla(
      String valor, {
        required double size,
        bool esBorrar = false,
        bool esConfirmar = false,
      }) {
    String rutaImagen;
    if (esBorrar) {
      rutaImagen = 'assets/images/teclado_pin/botonCancel.png';
    } else if (esConfirmar) {
      rutaImagen = 'assets/images/teclado_pin/botonCheck.png';
    } else {
      rutaImagen = 'assets/images/teclado_pin/boton-$valor.png';
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        if (esBorrar) {
          _borrarDigito();
        } else if (esConfirmar) {
          _confirmarPin();
        } else {
          _agregarDigito(valor);
        }
      },
      child: SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          rutaImagen,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}
