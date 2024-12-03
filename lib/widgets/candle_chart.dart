import 'package:flutter/material.dart';
import 'package:interactive_chart/interactive_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:eventsource3/eventsource.dart';


class CandleChart extends StatefulWidget {
  final String symbol;
  final Map<String, dynamic>? newData; // 상위 위젯에서 받은 실시간 주식 데이터

  const CandleChart({
    Key? key,
    required this.symbol,
    this.newData,
  }) : super(key: key);

  @override
  _CandleChartState createState() => _CandleChartState();
}

class _CandleChartState extends State<CandleChart> {
  List <CandleData> stockDatas = [];
  bool isLoading = true;  // 로딩 상태를 관리하는 변수
  EventSource? eventSource; // SSE 연결

  @override
  void initState(){
    super.initState();
    fetchInitial();
    //connectToSSE();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // 과거 데이터 fetch
  Future<void> fetchInitial() async {
    try {
      final url = Uri.parse(
          'http://localhost.stock-service/api/v1/stockDetails/historicalFilter?symbol=${widget.symbol}&interval=1d');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        // JSON 데이터를 CandleData 리스트로 변환
        final parsedData = data.map((item) {
          return CandleData(
            timestamp: DateTime.parse(item['date']).millisecondsSinceEpoch,
            open: item['open'].toDouble(),
            high: item['high'].toDouble(),
            low: item['low'].toDouble(),
            close: item['close'].toDouble(),
            volume: item['volume'].toDouble(),
          );
        }).toList();

        // 실시간 데이터가 담길 더미 데이터 생성
        final dummyData = CandleData(
          timestamp: DateTime.now().millisecondsSinceEpoch,
          open: 0.0,
          high: 0.0,
          low: 0.0,
          close: 0.0,
          volume: 0.0,
        );

        // 상태 업데이트
        setState(() {
          stockDatas = parsedData;
          stockDatas.add(dummyData); // 더미 데이터를 리스트에 추가
          isLoading = false;  // 데이터가 로드되면 로딩 상태를 false로 설정
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error fetching companies: $e');
    }
  }

  // 상위 위젯에서 newData가 변경된 경우 실행
  @override
  void didUpdateWidget(covariant CandleChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    // newData가 업데이트된 경우, 상태 업데이트
    if (widget.newData != oldWidget.newData) {
      if (widget.newData != null) {
        _updateOrAddData(widget.newData!);
      }
    }
  }

  // 데이터를 업데이트 하는 함수
  void _updateOrAddData(Map<String, dynamic> newData) {
    setState(() {
      if (newData != null ) {

        // 배열의 마지막을 실시간 데이터로 업데이트
        stockDatas[stockDatas.length-1] = CandleData(
          timestamp: DateTime.parse(newData['date']).millisecondsSinceEpoch,
          open: newData['open'].toDouble(),
          high: newData['high'].toDouble(),
          low: newData['low'].toDouble(),
          close: newData['close'].toDouble(),
          volume: newData['volume'].toDouble(),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: isLoading  // 로딩 중이면 로딩 스피너를 표시
              ? Center(child: CircularProgressIndicator())
              : InteractiveChart(
            candles: stockDatas,
            style: ChartStyle(
              priceGainColor: Colors.red,
              priceLossColor: Colors.blue,
            ),
            onTap: (candle) => print("user tapped on $candle"),
            priceLabel: (price) => "${price.round()}",
          ),
        ),
      ],
    );
  }

/** Example styling */
// style: ChartStyle(
//   priceGainColor: Colors.teal[200]!,
//   priceLossColor: Colors.blueGrey,
//   volumeColor: Colors.teal.withOpacity(0.8),
//   trendLineStyles: [
//     Paint()
//       ..strokeWidth = 2.0
//       ..strokeCap = StrokeCap.round
//       ..color = Colors.deepOrange,
//     Paint()
//       ..strokeWidth = 4.0
//       ..strokeCap = StrokeCap.round
//       ..color = Colors.orange,
//   ],
//   priceGridLineColor: Colors.blue[200]!,
//   priceLabelStyle: TextStyle(color: Colors.blue[200]),
//   timeLabelStyle: TextStyle(color: Colors.blue[200]),
//   selectionHighlightColor: Colors.red.withOpacity(0.2),
//   overlayBackgroundColor: Colors.red[900]!.withOpacity(0.6),
//   overlayTextStyle: TextStyle(color: Colors.red[100]),
//   timeLabelHeight: 32,
//   volumeHeightFactor: 0.2, // volume area is 20% of total height
// ),
/** Customize axis labels */
// timeLabel: (timestamp, visibleDataCount) => "📅",
// priceLabel: (price) => "${price.round()} 💎",
/** Customize overlay (tap and hold to see it)
 ** Or return an empty object to disable overlay info. */
// overlayInfo: (candle) => {
//   "💎": "🤚    ",
//   "Hi": "${candle.high?.toStringAsFixed(2)}",
//   "Lo": "${candle.low?.toStringAsFixed(2)}",
// },
/** Callbacks */
// onTap: (candle) => print("user tapped on $candle"),
// onCandleResize: (width) => print("each candle is $width wide"),


//   _computeTrendLines() {
//     final ma7 = CandleData.computeMA(_data, 7);
//     final ma30 = CandleData.computeMA(_data, 30);
//     final ma90 = CandleData.computeMA(_data, 90);
//
//     for (int i = 0; i < _data.length; i++) {
//       _data[i].trends = [ma7[i], ma30[i], ma90[i]];
//     }
//   }
//
//   _removeTrendLines() {
//     for (final data in _data) {
//       data.trends = [];
//     }
//   }
}


