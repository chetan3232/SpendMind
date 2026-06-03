import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'hive_service.dart';
import 'models.dart';
import 'gemini_service.dart';
import 'theme.dart';

class SimulatorScreen extends StatefulWidget {
  const SimulatorScreen({super.key});

  @override
  State<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends State<SimulatorScreen> {
  final _scenarioController = TextEditingController();
  
  // Simulated adjustments mapped as offsets from current category limits
  final Map<String, double> _adjustments = {};
  
  bool _isLoading = false;
  
  // Results populated by Gemini or Fallback Local calculator
  double _projectedSavingsRate = 0.0;
  int _monthsToGoal = 0;
  List<String> _recommendations = [];
  List<Map<String, dynamic>> _trajectory = [];

  final List<String> _sliderCategories = ['Food', 'Shopping', 'Travel', 'Entertainment'];

  @override
  void initState() {
    super.initState();
    for (var cat in _sliderCategories) {
      _adjustments[cat] = 0.0;
    }
    // Run an initial simulation using fallback rules
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runSimulation(initial: true);
    });
  }

  @override
  void dispose() {
    _scenarioController.dispose();
    super.dispose();
  }

  Future<void> _runSimulation({bool initial = false}) async {
    setState(() {
      _isLoading = true;
    });

    final hive = Provider.of<HiveService>(context, listen: false);
    
    // Map current category budget limits
    final Map<String, double> currentCategoryBudgets = {};
    for (var b in hive.budgets) {
      currentCategoryBudgets[b.category] = b.limit;
    }

    final gemini = GeminiService(apiKey: hive.geminiApiKey);
    final result = await gemini.getSpendingSimulationProjections(
      currentIncome: hive.monthlyIncome,
      currentSavingsGoal: hive.savingsGoal,
      currentCategoryBudgets: currentCategoryBudgets,
      simulatedBudgetChanges: _adjustments,
      scenarioText: initial ? 'Baseline configuration calculation.' : _scenarioController.text.trim(),
    );

    setState(() {
      _projectedSavingsRate = (result['projectedSavingsRate'] as num?)?.toDouble() ?? 0.0;
      _monthsToGoal = (result['monthsToGoal'] as num?)?.toInt() ?? 0;
      _recommendations = List<String>.from(result['recommendations'] ?? []);
      _trajectory = List<Map<String, dynamic>>.from(
        (result['savingsTrajectory'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ?? []
      );
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hive = Provider.of<HiveService>(context);


    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Text(
                  'Spending Simulator',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Model financial adjustments and project your savings.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 20),

                // Sliders controls
                const Text(
                  'ADJUST MONTHLY SPENDING CAPS',
                  style: TextStyle(
                    color: AppTheme.vibrantPurple,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                AppTheme.glassCard(
                  child: Column(
                    children: _sliderCategories.map((category) {
                      final val = _adjustments[category] ?? 0.0;
                      // Fetch current limit from Hive
                      final currentLimit = hive.budgets.firstWhere(
                        (b) => b.category.toLowerCase() == category.toLowerCase(),
                        orElse: () => Budget(category: category, limit: 5000.0)
                      ).limit;

                      final totalSimulated = currentLimit + val;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  category,
                                  style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  '₹${totalSimulated.toStringAsFixed(0)} (${val >= 0 ? "+" : ""}₹${val.toStringAsFixed(0)})',
                                  style: TextStyle(
                                    color: val > 0 
                                        ? AppTheme.coralRed 
                                        : (val < 0 ? AppTheme.emeraldGreen : AppTheme.textSecondary),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: AppTheme.vibrantPurple,
                                inactiveTrackColor: Colors.white.withOpacity(0.05),
                                thumbColor: AppTheme.vibrantPurple,
                                overlayColor: AppTheme.vibrantPurple.withOpacity(0.2),
                              ),
                              child: Slider(
                                value: val,
                                min: -currentLimit, // Can decrease down to 0 spent
                                max: 15000.0, // Limit maximum positive deviation
                                divisions: 50,
                                onChanged: (newVal) {
                                  setState(() {
                                    _adjustments[category] = newVal;
                                  });
                                },
                              ),
                            )
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 25),

                // Scenario input
                const Text(
                  'DESCRIBE YOUR FUTURE SCENARIO',
                  style: TextStyle(
                    color: AppTheme.vibrantPurple,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                AppTheme.glassCard(
                  child: Column(
                    children: [
                      TextField(
                        controller: _scenarioController,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'e.g., I want to buy a new gym membership for ₹1500/mo and move to a cheaper flat (-₹4000/mo)...',
                          hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          filled: true,
                          fillColor: Colors.black.withOpacity(0.2),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.vibrantPurple),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : () => _runSimulation(),
                          icon: _isLoading 
                              ? const SizedBox(
                                  width: 16, 
                                  height: 16, 
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                                )
                              : const Icon(Icons.play_arrow, color: Colors.white),
                          label: Text(
                            _isLoading ? 'Projecting Sandbox...' : 'Run Simulation Scenario',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.vibrantPurple,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),

                // Results Title
                const Text(
                  'PROJECTION INSIGHTS & COMPARATIVE PATH',
                  style: TextStyle(
                    color: AppTheme.vibrantPurple,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),

                // Metrics cards
                Row(
                  children: [
                    Expanded(
                      child: AppTheme.glassCard(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          children: [
                            const Text('Projected Savings Rate', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                            const SizedBox(height: 4),
                            Text(
                              '$_projectedSavingsRate%',
                              style: TextStyle(
                                color: _projectedSavingsRate > 30 ? AppTheme.emeraldGreen : AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 20
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppTheme.glassCard(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          children: [
                            const Text('Months to Save Goal', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                            const SizedBox(height: 4),
                            Text(
                              _monthsToGoal >= 999 ? 'N/A' : '$_monthsToGoal months',
                              style: const TextStyle(
                                color: AppTheme.vibrantPurple,
                                fontWeight: FontWeight.bold,
                                fontSize: 20
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                // Trajectory Graph
                if (_trajectory.isNotEmpty) ...[
                  AppTheme.glassCard(
                    padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
                    child: SizedBox(
                      height: 180,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: Colors.white.withOpacity(0.04),
                              strokeWidth: 1,
                            ),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  int idx = value.toInt();
                                  if (idx >= 0 && idx < _trajectory.length && idx % 3 == 0) {
                                    return Text(
                                      _trajectory[idx]['month'] ?? '',
                                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            // Current Path Line
                            LineChartBarData(
                              spots: _getSpots(isSimulated: false),
                              isCurved: true,
                              color: AppTheme.mutedBlue,
                              barWidth: 2,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: AppTheme.mutedBlue.withOpacity(0.05),
                              ),
                            ),
                            // Simulated Path Line
                            LineChartBarData(
                              spots: _getSpots(isSimulated: true),
                              isCurved: true,
                              color: AppTheme.vibrantPurple,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: AppTheme.vibrantPurple.withOpacity(0.1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildGraphLegend(color: AppTheme.mutedBlue, label: 'Current path'),
                      const SizedBox(width: 20),
                      _buildGraphLegend(color: AppTheme.vibrantPurple, label: 'Simulated path'),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                // Recommendations list
                if (_recommendations.isNotEmpty) ...[
                  const Text(
                    'AI SCENARIO RECOMMENDATIONS',
                    style: TextStyle(
                      color: AppTheme.vibrantPurple,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ..._recommendations.map((rec) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: AppTheme.glassCard(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.insights, size: 16, color: AppTheme.vibrantPurple),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              rec,
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )).toList(),
                ],
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGraphLegend({required Color color, required String label}) {
    return Row(
      children: [
        Container(width: 12, height: 4, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
      ],
    );
  }

  List<FlSpot> _getSpots({required bool isSimulated}) {
    List<FlSpot> spots = [];
    for (int i = 0; i < _trajectory.length; i++) {
      final valKey = isSimulated ? 'simulated' : 'current';
      final val = (_trajectory[i][valKey] as num?)?.toDouble() ?? 0.0;
      spots.add(FlSpot(i.toDouble(), val));
    }
    return spots;
  }
}
