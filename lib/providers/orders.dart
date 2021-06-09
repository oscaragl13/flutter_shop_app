import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'cart.dart';

class OrderItem {
  final String id;
  final double amount;
  final List<CartItem> products;
  final DateTime dateTime;

  OrderItem({
    required this.id,
    required this.amount,
    required this.products,
    required this.dateTime,
  });
}

class Orders with ChangeNotifier {
  var _authToken;
  var _userId;

  set authToken(String value) {
    _authToken = value;
  }

  set userId(String value) {
    _userId = value;
  }

  List<OrderItem> _orders = [];

  List<OrderItem> get orders {
    return [..._orders];
  }

  Future<void> addOrder(List<CartItem> cartProducts, double total) async {
    final url = Uri.parse(
        'https://flutter-course-ab219-default-rtdb.firebaseio.com/orders/$_userId.json?auth=$_authToken');
    final date = DateTime.now();
    try {
      final response = await http.post(
        url,
        body: json.encode(
          {
            'amount': total,
            'products': cartProducts
                .map((cartItem) => {
                      'id': cartItem.id,
                      'title': cartItem.title,
                      'quantity': cartItem.quantity,
                      'price': cartItem.price,
                    })
                .toList(),
            'dateTime': date.toIso8601String(),
          },
        ),
      );
      _orders.insert(
        0,
        OrderItem(
          id: json.decode(response.body)['name'],
          amount: total,
          products: cartProducts,
          dateTime: date,
        ),
      );
      notifyListeners();
    } catch (error) {
      print(error);
      throw error;
    }
  }

  Future<void> fetchAndSetOrders() async {
    final url = Uri.parse(
        'https://flutter-course-ab219-default-rtdb.firebaseio.com/orders/$_userId.json?auth=$_authToken');
    try {
      final response = await http.get(url);
      if (response.body == 'null') {
        return;
      }
      final List<OrderItem> loadedOrders = [];
      final extractedData = json.decode(response.body) as Map<String, dynamic>;
      extractedData.forEach(
        (orderId, orderData) {
          loadedOrders.add(
            OrderItem(
              id: orderId,
              amount: orderData['amount'],
              dateTime: DateTime.parse(orderData['dateTime']),
              products: (orderData['products'] as List<dynamic>)
                  .map(
                    (item) => CartItem(
                      id: item['id'],
                      price: item['price'],
                      quantity: item['quantity'],
                      title: item['title'],
                    ),
                  )
                  .toList(),
            ),
          );
        },
      );
      _orders = loadedOrders.reversed.toList();
      notifyListeners();
    } catch (error) {
      print(error);
      throw error;
    }
  }
}
