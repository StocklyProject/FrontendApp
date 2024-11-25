import 'package:flutter/material.dart';

class OrderList extends StatefulWidget {
  @override
  _OrderListState createState() => _OrderListState();
}

class _OrderListState extends State<OrderList> {
  final List<Map<String, dynamic>> holdings = [
    {
      "name": "삼성전자",
      "buyPrice": 70000,
      "quantity": 10,
      "changeRate": 1.5,
      "changePrice": 1050,
    },
    {
      "name": "카카오",
      "buyPrice": 55000,
      "quantity": 5,
      "changeRate": -0.8,
      "changePrice": -440,
    },
    {
      "name": "LG에너지솔루션",
      "buyPrice": 400000,
      "quantity": 2,
      "changeRate": 2.1,
      "changePrice": 8400,
    }
  ];

  int? _highlightedIndex;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: holdings.asMap().entries.map((entry) {
          final index = entry.key;
          final holding = entry.value;
          final name = holding['name'];
          final quantity = holding['quantity'];
          final buyPrice = holding['buyPrice'];
          final changeRate = holding['changeRate'];
          final changePrice = holding['changePrice'];

          return InkWell(
            onTap: () {
              // 클릭 시 실행할 작업
            },
            onHighlightChanged: (isHighlighted) {
              setState(() {
                _highlightedIndex = isHighlighted ? index : null;
              });
            },
            child: Container(
              color: _highlightedIndex == index ? Color(0xFFF2F4F6) : Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: TextStyle(fontSize: 20)),
                      Text("$quantity주"),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("${buyPrice * quantity}원", style: TextStyle(fontSize: 20)),
                      Text(
                        "${changePrice > 0 ? "+" : ""}$changePrice원 (${changeRate > 0 ? "+" : ""}${changeRate.toStringAsFixed(1)}%)",
                        style: TextStyle(color: changeRate > 0 ? Colors.red : Colors.blue),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}