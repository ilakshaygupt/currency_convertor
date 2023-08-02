import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dropdown_search/dropdown_search.dart';

void main() {
  runApp(const CurrencyConverterApp());
}

class CurrencyConverterApp extends StatelessWidget {
  const CurrencyConverterApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: ThemeMode.dark,
      title: 'Currency Converter',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const CurrencyConverterScreen(),
    );
  }
}

class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({Key? key}) : super(key: key);

  @override
  _CurrencyConverterScreenState createState() =>
      _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  double _conversionRate = 0.0;
  String _baseCurrency = 'USD';
  String _targetCurrency = 'EUR';
  final TextEditingController _amountController = TextEditingController();
  Future<List<String>>? _currenciesFuture;
  List<String> _currencies = [];

  Future<List<String>> _fetchCurrencies() async {
    try {
      final response = await http.get(Uri.parse(
          'https://v6.exchangerate-api.com/v6/e098e56ac399d404a3d45bbd/latest/USD'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data['conversion_rates'] != null) {
          Map<String, dynamic> rates = data['conversion_rates'];
          return rates.keys.toList();
        } else {
          print('API response data is null or conversion_rates is null');
          return [];
        }
      } else {
        print(
            'Failed to fetch conversion rate. Status code: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching currencies: $e');
      return [];
    }
  }

  // @override
  // void initState() {
  //   super.initState();
  //   _currenciesFuture = _fetchCurrencies();
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency Converter'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
              ),
            ),
            const SizedBox(height: 20),
            FutureBuilder<List<String>>(
              future: _fetchCurrencies(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data!.isEmpty) {
                  return Text('Error fetching currencies');
                } else {
                  _currencies = snapshot.data!;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: DropdownSearch<String>(
                          popupProps: const PopupProps.bottomSheet(
                            bottomSheetProps: BottomSheetProps(),
                            showSearchBox: true,
                          ),
                          items: _currencies,
                          onChanged: (value) {
                            setState(() {
                              _baseCurrency = value!;
                            });
                          },
                          selectedItem: _baseCurrency,
                        ),
                      ),
                      const Icon(Icons.arrow_forward),
                      Expanded(
                        child: DropdownSearch<String>(
                          popupProps: const PopupProps.bottomSheet(
                            bottomSheetProps: BottomSheetProps(),
                            showSearchBox: true,
                          ),
                          items: _currencies,
                          onChanged: (value) {
                            setState(() {
                              _targetCurrency = value!;
                            });
                          },
                          selectedItem: _targetCurrency,
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _convertCurrencies,
              child: const Text('Convert'),
            ),
            const SizedBox(height: 20),
            Text(
              '$_conversionRate $_targetCurrency',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _convertCurrencies() async {
    try {
      final url = Uri.parse(
          'https://v6.exchangerate-api.com/v6/e098e56ac399d404a3d45bbd/latest/$_baseCurrency');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data['conversion_rates'] != null) {
          final rate = data['conversion_rates'][_targetCurrency];
          final amount = double.tryParse(_amountController.text) ?? 0.0;
          final convertedAmount = amount * rate;
          setState(() {
            _conversionRate = convertedAmount;
          });
        } else {
          print('API response data is null or conversion_rates is null');
        }
      } else {
        print(
            'Failed to fetch conversion rate. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }
}
