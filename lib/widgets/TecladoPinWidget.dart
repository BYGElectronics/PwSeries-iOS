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
    if (_pin.isNotEmpty) {
      widget.onPinComplete(_pin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double keySize = screenWidth / 5;

    final List<String> teclas = [
      '1', '2', '3',
      '4', '5', '6',
      '7', '8', '9',
      'X', '0', 'V',
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 10),
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
                color: Colors.white,
              ),
              onPressed: () {
                setState(() => _mostrarPin = !_mostrarPin);
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Divider(thickness: 1, color: Colors.black),
        const SizedBox(height: 10),
        Wrap(
          spacing: 18,
          runSpacing: 18,
          alignment: WrapAlignment.center,
          children: teclas.map((valor) {
            return _buildTecla(
              valor,
              size: keySize,
              esBorrar: valor == 'X',
              esConfirmar: valor == 'V',
            );
          }).toList(),
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
        child: Image.asset(rutaImagen, fit: BoxFit.contain),
      ),
    );
  }
}
