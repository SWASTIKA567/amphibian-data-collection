import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import 'home_view.dart';
import 'edna_input_view.dart';
import 'gemini_species_view.dart';
import 'projects_community_view.dart';

/// A global provider that allows any widget to switch tabs and pass a species name
final mainNavIndexProvider = StateProvider<int>((ref) => 0);
final mainNavSpeciesProvider = StateProvider<String?>((ref) => null);
// Alias for backwards compatibility
final mainNavGeminiSpeciesProvider = mainNavSpeciesProvider;

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(mainNavIndexProvider);
    final pendingSpecies = ref.watch(mainNavSpeciesProvider);

    // Listen to nav index changes and animate page
    ref.listen<int>(mainNavIndexProvider, (prev, next) {
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          const HomeView(),
          const EdnaInputView(),
          SpeciesInfoView(
            initialSpecies: pendingSpecies,
          ),
          const ProjectsCommunityView(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(currentIndex),
    );
  }

  Widget _buildBottomNav(int currentIndex) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          ref.read(mainNavIndexProvider.notifier).state = index;
        },
        backgroundColor: AppTheme.white,
        indicatorColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
        surfaceTintColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        animationDuration: const Duration(milliseconds: 300),
        destinations: [
          NavigationDestination(
            icon: Icon(
              Icons.home_outlined,
              color: currentIndex == 0 ? AppTheme.primaryGreen : AppTheme.textMuted,
            ),
            selectedIcon: const Icon(Icons.home_rounded, color: AppTheme.primaryGreen),
            label: 'Results',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.biotech_outlined,
              color: currentIndex == 1 ? AppTheme.primaryGreen : AppTheme.textMuted,
            ),
            selectedIcon: const Icon(Icons.biotech_rounded, color: AppTheme.primaryGreen),
            label: 'eDNA Input',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.travel_explore_outlined,
              color: currentIndex == 2 ? AppTheme.primaryGreen : AppTheme.textMuted,
            ),
            selectedIcon: const Icon(Icons.travel_explore_rounded, color: AppTheme.primaryGreen),
            label: 'Species Info',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.hub_outlined,
              color: currentIndex == 3 ? AppTheme.primaryGreen : AppTheme.textMuted,
            ),
            selectedIcon: const Icon(Icons.hub_rounded, color: AppTheme.primaryGreen),
            label: 'Community',
          ),
        ],
      ),
    );
  }
}
