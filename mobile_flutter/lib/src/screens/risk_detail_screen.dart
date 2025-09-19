import 'package:flutter/material.dart';
import '../models/risk_factor.dart';
import '../models/risk_level.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class RiskDetailScreen extends StatelessWidget {
  final RiskFactor riskFactor;

  const RiskDetailScreen({Key? key, required this.riskFactor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(riskFactor.title),
        backgroundColor: riskFactor.riskLevel.color,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const Divider(),
            _buildRiskDescription(context),
            const Divider(),
            _buildRiskChart(context),
            const Divider(),
            _buildRecommendations(context),
            const SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            riskFactor.riskLevel.color,
            riskFactor.riskLevel.color.withOpacity(0.7),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            riskFactor.iconData,
            size: 56.0,
            color: Colors.white,
          ),
          const SizedBox(height: 16.0),
          Text(
            '${riskFactor.value.toStringAsFixed(1)}${riskFactor.unit}',
            style: const TextStyle(
              fontSize: 32.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8.0),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Text(
              riskFactor.riskLevel.level,
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Last Updated: ${DateFormat('MMM d, yyyy').format(riskFactor.lastUpdated)}',
            style: TextStyle(
              fontSize: 14.0,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskDescription(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What is ${riskFactor.title}?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8.0),
          Text(
            _getDetailedDescription(),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildRiskChart(BuildContext context) {
    // Sample chart data to visualize risk ranges
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Risk Ranges',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16.0),
          SizedBox(
            height: 200,
            child: _buildRiskLevelChart(),
          ),
          const SizedBox(height: 16.0),
          _buildRiskLegend(),
        ],
      ),
    );
  }

  Widget _buildRiskLevelChart() {
    // Create appropriate chart based on the risk factor type
    if (riskFactor.id == 'blood_pressure') {
      return _buildBloodPressureChart();
    }
    
    // Generic horizontal bar chart for other metrics
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 4,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                String text = '';
                switch (value.toInt()) {
                  case 0:
                    text = 'Normal';
                    break;
                  case 1:
                    text = 'Moderate';
                    break;
                  case 2:
                    text = 'High';
                    break;
                  case 3:
                    text = 'Very High';
                    break;
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    text,
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: _getRiskBarGroups(),
        gridData: FlGridData(show: false),
      ),
    );
  }

  List<BarChartGroupData> _getRiskBarGroups() {
    // Define risk level colors
    List<Color> colors = [];
    
    // Set colors for risk levels
    colors = [
        RiskLevel.normal.color,
        RiskLevel.moderate.color,
        RiskLevel.high.color,
        RiskLevel.veryHigh.color,
      ];
    
    List<BarChartGroupData> barGroups = [];
    
    for (int i = 0; i < 4; i++) {
      double height = (i == riskFactor.riskLevel.index) ? 3 : 1;
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: height,
              color: colors[i],
              width: 40,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
          ],
        ),
      );
    }
    
    return barGroups;
  }

  Widget _buildBloodPressureChart() {
    // Special chart for blood pressure that shows systolic and diastolic
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBloodPressureItem('Systolic', '< 120', '120-129', '130-139', '≥ 140'),
              const SizedBox(width: 16.0),
              _buildBloodPressureItem('Diastolic', '< 80', '80-84', '85-89', '≥ 90'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBloodPressureItem(
    String title, 
    String normal, 
    String moderate, 
    String high, 
    String veryHigh
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
            ),
          ),
          const SizedBox(height: 8.0),
          _buildBPRange('Normal', normal, RiskLevel.normal.color),
          _buildBPRange('Moderate', moderate, RiskLevel.moderate.color),
          _buildBPRange('High', high, RiskLevel.high.color),
          _buildBPRange('Very High', veryHigh, RiskLevel.veryHigh.color),
        ],
      ),
    );
  }

  Widget _buildBPRange(String label, String range, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 12.0,
            height: 12.0,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6.0),
            ),
          ),
          const SizedBox(width: 8.0),
          Text('$label: $range'),
        ],
      ),
    );
  }

  Widget _buildRiskLegend() {
    return Wrap(
      spacing: 16.0,
      runSpacing: 8.0,
      children: [
        _buildLegendItem(RiskLevel.normal, 'Normal'),
        _buildLegendItem(RiskLevel.moderate, 'Moderate'),
        _buildLegendItem(RiskLevel.high, 'High'),
        _buildLegendItem(RiskLevel.veryHigh, 'Very High'),
      ],
    );
  }

  Widget _buildLegendItem(RiskLevel level, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16.0,
          height: 16.0,
          decoration: BoxDecoration(
            color: level.color,
            borderRadius: BorderRadius.circular(4.0),
          ),
        ),
        const SizedBox(width: 4.0),
        Text(text),
      ],
    );
  }

  Widget _buildRecommendations(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recommendations',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16.0),
          ..._getRecommendations().map((rec) => _buildRecommendationItem(rec)),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(String recommendation) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            color: riskFactor.riskLevel.color,
            size: 20.0,
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Text(recommendation),
          ),
        ],
      ),
    );
  }

  String _getDetailedDescription() {
    switch (riskFactor.id) {
      case 'bmi':
        return 'Body Mass Index (BMI) is a measure of body fat based on height and weight. It applies to adult men and women. '
            'A high BMI can indicate high body fatness, which increases your risk for heart disease, high blood pressure, type 2 diabetes, and other health problems.';
      case 'ldl_cholesterol':
        return 'LDL (low-density lipoprotein) cholesterol is often referred to as "bad" cholesterol. '
            'It contributes to fatty buildups in arteries (atherosclerosis), which increases the risk for heart attack, stroke, and peripheral artery disease.';
      case 'hdl_cholesterol':
        return 'HDL (high-density lipoprotein) cholesterol is known as "good" cholesterol because it helps remove other forms of cholesterol from your bloodstream. '
            'Higher levels of HDL cholesterol are associated with a lower risk of heart disease.';
      case 'total_cholesterol':
        return 'Total cholesterol is the sum of HDL, LDL, and other lipid components. '
            'While cholesterol is necessary for building cells and producing hormones, too much can lead to heart disease.';
      case 'triglycerides':
        return 'Triglycerides are a type of fat found in your blood that your body uses for energy. '
            'High triglyceride levels combined with high LDL (bad) cholesterol or low HDL (good) cholesterol increases your risk for heart attack and stroke.';
      case 'blood_pressure':
        return 'Blood pressure is the force of blood pushing against the walls of your arteries. High blood pressure (hypertension) can damage your heart '
            'and blood vessels and lead to stroke, heart attack, kidney failure, and other health problems.';
      case 'blood_sugar':
        return 'Blood sugar (glucose) is your body\'s main source of energy. Persistent high blood sugar levels may signal diabetes or prediabetes, '
            'which can lead to serious health problems including heart disease, stroke, kidney disease, and nerve damage.';
      case 'smoking':
        return 'Smoking damages nearly every organ in your body and causes numerous diseases. It affects your cardiovascular system by reducing '
            'oxygen in the blood, increasing blood pressure and heart rate, and damaging blood vessel walls.';
      default:
        return riskFactor.description;
    }
  }

  List<String> _getRecommendations() {
    switch (riskFactor.id) {
      case 'bmi':
        return [
          'Aim for a balanced diet rich in fruits, vegetables, whole grains, and lean proteins.',
          'Reduce portion sizes and be mindful of calorie intake.',
          'Engage in regular physical activity, aiming for at least 150 minutes of moderate exercise per week.',
          'Consider consulting with a nutritionist or dietitian for personalized advice.',
          'Set realistic weight loss goals of 1-2 pounds per week.',
        ];
      case 'ldl_cholesterol':
        return [
          'Limit foods high in saturated and trans fats.',
          'Increase consumption of soluble fiber found in oats, beans, and fruits.',
          'Choose lean proteins such as fish, poultry, and plant-based options.',
          'Consider incorporating plant sterols and stanols in your diet.',
          'Regular exercise can help improve cholesterol levels.',
          'Discuss medication options with your healthcare provider if lifestyle changes aren\'t sufficient.',
        ];
      case 'blood_pressure':
        return [
          'Reduce sodium intake to less than 2,300 mg per day.',
          'Adopt the DASH (Dietary Approaches to Stop Hypertension) eating plan.',
          'Limit alcohol consumption.',
          'Maintain a healthy weight.',
          'Exercise regularly with activities like walking, cycling, or swimming.',
          'Manage stress through relaxation techniques such as meditation or deep breathing.',
          'Take prescribed medications as directed by your healthcare provider.',
        ];
      case 'blood_sugar':
        return [
          'Limit refined carbohydrates and added sugars in your diet.',
          'Choose complex carbohydrates with a lower glycemic index.',
          'Eat regular meals and avoid skipping meals.',
          'Stay physically active to help your body use insulin more efficiently.',
          'Maintain a healthy weight.',
          'Monitor your blood sugar levels as recommended by your healthcare provider.',
        ];
      case 'smoking':
        return [
          'Set a quit date and make a plan to stop smoking.',
          'Consider nicotine replacement therapy or other medications that can help.',
          'Seek support from friends, family, or smoking cessation programs.',
          'Identify and avoid triggers that make you want to smoke.',
          'Stay physically active to reduce cravings and manage stress.',
          'Remember that quitting smoking has immediate and long-term health benefits.',
        ];
      default:
        return [
          'Follow a balanced diet rich in fruits, vegetables, whole grains, and lean proteins.',
          'Engage in regular physical activity.',
          'Maintain a healthy weight.',
          'Limit alcohol consumption.',
          'Manage stress through relaxation techniques.',
          'Get regular check-ups with your healthcare provider.',
        ];
    }
  }
}