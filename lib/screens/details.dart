import 'package:flutter/material.dart';
import '../widgets/candle_chart.dart';
import '../widgets/order_book.dart';
import '../screens/buy.dart';
import '../screens/sell.dart';
import 'package:http/http.dart' as http;
import 'package:eventsource3/eventsource.dart';
import 'dart:convert';

class DetailsScreen extends StatefulWidget {
  final String symbol;
  final String name;
  final double close;
  final double rate;
  final double ratePrice;

  // 생성자에서 전달된 값을 받아옵니다.
  const DetailsScreen({
    Key? key,
    required this.symbol,
    required this.name,
    required this.close,
    required this.rate,
    required this.ratePrice,
  }) : super(key: key);

  @override
  _DetailsScreenState createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  bool isLoading = true;  // 로딩 상태를 관리하는 변수
  EventSource? eventSource; // SSE 연결

  // 상단 주식 정보 변수
  int price = 0;
  double rate = 0.0;
  int rate_price = 0;

  // 하위 widget에 넘겨줄 실시간 데이터 정보 관리하는 변수
  Map<String, dynamic> stockData = {};

  // 토글 버튼 상태 추적하는 변수
  int _selectedIndex = 0;  // 0: 차트, 1: 호가
  int _selectedFilter = 1; // 0: 분, 1: 일, 2: 주, 3:월, 4:년
  String dropdownValue = '1분';

  @override
  void initState(){
    super.initState();
    price = widget.close.toInt();
    rate = widget.rate;
    rate_price = widget.ratePrice.toInt();
    connectToSSE();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // SSE 연결 및 실시간 데이터 fetch
  void connectToSSE() async {
    try {
      final url = 'http://localhost.stock-service/api/v1/stockDetails/sse/stream/${widget.symbol}';
      eventSource = await EventSource.connect(url);

      eventSource?.listen((event) {
        if (event.data != null) {
          try {
            final parsedData = json.decode(event.data!);

            if (parsedData != null ) {
              if (mounted) {
                setState(() {
                  // 하위 위젯에 넘겨줄 데이터 업데이트
                  stockData = parsedData;

                  // 상단 주식 정보 데이터 업데이트
                  price = parsedData['close'].toInt();
                  rate = parsedData['rate'];
                  rate_price = parsedData['rate_price'].toInt();
                });
              }
            }
            else {
              print('Unexpected data format: $parsedData');
            }
          } catch (e) {
            print('Error parsing SSE data: $e');
          }
        }
      });
    } catch (e) {
      print('Error connecting to SSE: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),  // widget을 통해 상위 클래스의 값에 접근
      ),
      body:SafeArea(child:
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 5),
                  child: Text(widget.name, style: const TextStyle(fontSize: 23)), // widget 사용
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 5),
                  child: Text(widget.symbol, style: const TextStyle(fontSize: 23, color: Color(0xFFB4BDC6))), // widget 사용
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 5),
                  child: Text('${_formatCurrency(price)}원', style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold)), // widget 사용
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 5),
                  child: Text(
                    '${_formatCurrency(rate_price)}원 (${rate}%)',
                    style: TextStyle(
                      fontSize: 18,
                      color: (rate_price > 0 ? Colors.red : Colors.blue), // widget 사용
                    ),
                  ),
                ),
              ],
            ),

            // 차트/호가 토글 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children : [
                ToggleButtons(
                isSelected: [_selectedIndex == 0, _selectedIndex == 1],
                onPressed: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                borderRadius: BorderRadius.circular(20),
                renderBorder: false,
                constraints: const BoxConstraints(
                  minHeight: 30, // 버튼의 높이 지정
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _selectedIndex == 0 ? Color(0xffEAECF0) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20), // 타원형 배경
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Text(
                          '차트',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _selectedIndex == 1 ? Color(0xffEAECF0) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20), // 타원형 배경
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Text(
                          '호가',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                selectedColor: Colors.black, // 선택된 버튼
                fillColor: Colors.transparent, // 선택된 버튼
                borderWidth: 0, // 토글 버튼의 테두리 없애기
              ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    fixedSize: Size(40, 40), // 원하는 정사각형 크기 설정
                    minimumSize: Size(40, 40), // 최소 크기를 동일하게 설정
                    shadowColor: Colors.transparent,
                    backgroundColor: Color(0xffEAECF0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // 모서리 둥글기 설정
                    ),
                    padding: EdgeInsets.zero, // 내부 여백 제거
                  ),
                  onPressed: () {
                    print("Button Pressed");
                  },
                  child: Icon(
                    Icons.notifications,
                    size: 25,
                    color: Color(0xffB4BDC6),
                  ),
                ),
              ]
            ),

            SizedBox(height: 10),

            // 선택된 버튼에 따라 다르게 표시되는 자식 요소
            Expanded(
              child: _selectedIndex == 0
                  ? CandleChart(symbol: widget.symbol, newData: stockData)  // 차트 화면
                  : OrderBook(symbol: widget.symbol),  // 호가 화면, 이 위젯은 별도로 구현 필요
            ),



            SizedBox(height: 10),



            // 분, 일, 주, 월, 년 필터링 버튼
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children : [
                  ToggleButtons(
                    isSelected: [_selectedFilter == 0, _selectedFilter == 1, _selectedFilter == 2, _selectedFilter == 3, _selectedFilter == 4],
                    onPressed: (index) {
                      setState(() {
                        _selectedFilter = index;
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    renderBorder: false,
                    constraints: const BoxConstraints(
                      minHeight: 30, // 버튼의 높이 지정
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _selectedFilter == 0 ? Color(0xffEAECF0) : Colors.transparent,
                            borderRadius: BorderRadius.circular(25), // 타원형 배경
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: dropdownValue,
                              onChanged: (String? newValue) {
                                setState(() {
                                  dropdownValue = newValue!;
                                  _selectedFilter = 0; // 드롭다운 선택 시 필터를 0으로 설정
                                });
                              },
                              items: <String>['1분', '5분']
                                  .map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    child: Text(
                                      value,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                              style: const TextStyle(color: Colors.black),
                              dropdownColor: Colors.white, // 드롭다운 리스트의 배경색 설정
                            ),
                          ),
                        ),
                      ),


                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _selectedFilter == 1 ? Color(0xffEAECF0) : Colors.transparent,
                            borderRadius: BorderRadius.circular(20), // 타원형 배경
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            child: Text(
                              '일',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _selectedFilter == 2 ? Color(0xffEAECF0) : Colors.transparent,
                            borderRadius: BorderRadius.circular(20), // 타원형 배경
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            child: Text(
                              '주',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _selectedFilter == 3 ? Color(0xffEAECF0) : Colors.transparent,
                            borderRadius: BorderRadius.circular(20), // 타원형 배경
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            child: Text(
                              '월',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _selectedFilter == 4 ? Color(0xffEAECF0) : Colors.transparent,
                            borderRadius: BorderRadius.circular(20), // 타원형 배경
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            child: Text(
                              '년',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    selectedColor: Colors.black, // 선택된 버튼
                    fillColor: Colors.transparent, // 선택된 버튼
                    borderWidth: 0, // 토글 버튼의 테두리 없애기
                  ),
                ]
            ),


            SizedBox(height: 10),


            // 판매, 구매 버튼
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => Sell(symbol: widget.symbol, name:widget.name)),
                          );
                        },
                        child: Text(
                          "판매하기",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff3182F6),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFEFF6FF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          shadowColor: Colors.transparent,
                          minimumSize: Size(double.infinity, 60),
                        ),
                      ),
                    ),
                    SizedBox(width: 10), // 버튼 사이에 간격 추가
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => Buy(symbol: widget.symbol, name:widget.name)),
                          );
                        },
                        child: Text(
                          "구매하기",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xff3182F6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          shadowColor: Colors.transparent,
                          minimumSize: Size(double.infinity, 60),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
      )
    );
  }
 // 가격 숫자에 점 찍어주는 함수
  String _formatCurrency(int value) {
    return value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
    );
  }

}
