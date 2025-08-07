import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:store_manager/widgets/organism/line_chart.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Trang chủ')),
      body: Column(
        children: [
          Text('Biểu đồ doanh thu'),
          LineChartSample2(),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: 0.1,
                    color: Colors.red,
                    title: 'Huỷ đơn',
                  ),
                  PieChartSectionData(
                    value: 2,
                    color: Colors.blue,
                    title: 'Đang giao',
                  ),
                  PieChartSectionData(
                    value: 3,
                    color: Colors.green,
                    title: 'Đã giao',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
