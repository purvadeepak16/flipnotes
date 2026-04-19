import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../theme/neo_brutalism.dart';
import '../services/visualization_service.dart';
import '../models/visualization_model.dart';

/// Visualize Concept screen - Generate notes and mindmaps
class VisualizationScreen extends StatefulWidget {
  const VisualizationScreen({super.key});

  @override
  State<VisualizationScreen> createState() => _VisualizationScreenState();
}

class _VisualizationScreenState extends State<VisualizationScreen>
    with SingleTickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _vizService = VisualizationService();
  final _conceptController = TextEditingController();

  bool _isLoading = false;
  Visualization? _currentVisualization;
  List<Visualization> _savedVisualizations = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSavedVisualizations();
  }

  @override
  void dispose() {
    _conceptController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedVisualizations() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final vizs = await _vizService.getUserVisualizations(user.uid);
    setState(() => _savedVisualizations = vizs);
  }

  Future<void> _generateVisualization() async {
    if (_conceptController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a concept')),
      );
      return;
    }

    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final viz = await _vizService.generateVisualization(
        uid: user.uid,
        concept: _conceptController.text,
      );

      setState(() {
        _currentVisualization = viz;
        _isLoading = false;
      });

      // Reload saved visualizations
      _loadSavedVisualizations();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Visualization generated!')),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            // Hero Banner
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(20, topPadding + 20, 20, 0),
                  decoration: const BoxDecoration(
                    color: AppColors.visualizeAmber,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'VISUALIZE',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Explore any concept',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Turn topics into diagrams',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Custom Tabs
                      TabBar(
                        controller: _tabController,
                        indicatorColor: Colors.white,
                        indicatorWeight: 3,
                        indicatorSize: TabBarIndicatorSize.label,
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white70,
                        tabs: const [
                          Tab(text: 'Generate'),
                          Tab(text: 'Saved'),
                        ],
                      ),
                    ],
                  ),
                ),
                // Decorative Circle
                Positioned(
                  top: -20,
                  right: -40,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.09),
                        width: 30,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Generate
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Enter a concept:',
                          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: TextField(
                            controller: _conceptController,
                            decoration: const InputDecoration(
                              hintText: 'e.g. Machine Learning, Photosynthesis...',
                              hintStyle: TextStyle(color: AppColors.mutedText, fontSize: 13),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _generateVisualization,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.visualizeAmber,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: Text(
                              _isLoading ? 'GENERATING...' : 'Generate visualization',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Placeholder for diagram
                        Container(
                          width: double.infinity,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: const Center(
                            child: Text(
                              'Your diagram will appear here',
                              style: TextStyle(color: AppColors.mutedText, fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Recently saved',
                              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: const Text('See all', style: TextStyle(color: AppColors.visualizeAmber, fontSize: 12)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildSavedItem('Machine learning', 'Apr 16', '🧠'),
                        const SizedBox(height: 8),
                        _buildSavedItem('Photosynthesis', 'Apr 15', '🌱'),
                        const SizedBox(height: 8),
                        _buildSavedItem('Neural networks', 'Apr 14', '⚙️'),
                      ],
                    ),
                  ),

                  // Tab 2: Saved
                  _savedVisualizations.isEmpty
                      ? const Center(child: Text('No saved visualizations yet'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(24),
                          itemCount: _savedVisualizations.length,
                          itemBuilder: (context, index) {
                            final viz = _savedVisualizations[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildSavedItem(viz.concept, viz.createdAt.toString().split(' ')[0], '💡'),
                            );
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedItem(String title, String date, String emoji) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.visualizeAmber.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(date, style: const TextStyle(color: AppColors.mutedText, fontSize: 10)),
              ],
            ),
          ),
          const Icon(Icons.favorite_border, size: 16, color: AppColors.mutedText),
        ],
      ),
    );
  }
}
