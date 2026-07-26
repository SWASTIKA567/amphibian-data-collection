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
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
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

    ref.listen<int>(mainNavIndexProvider, (prev, next) {
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOut,
        );
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.lightMintBackground,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          const HomeView(),
          const EdnaInputView(),
          SpeciesInfoView(initialSpecies: pendingSpecies),
          const ProjectsCommunityView(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(currentIndex),
    );
  }

  Widget _buildBottomNav(int currentIndex) {
    const items = [
      _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Results'),
      _NavItem(icon: Icons.biotech_outlined, activeIcon: Icons.biotech_rounded, label: 'eDNA'),
      _NavItem(icon: Icons.travel_explore_outlined, activeIcon: Icons.travel_explore_rounded, label: 'Species'),
      _NavItem(icon: Icons.hub_outlined, activeIcon: Icons.hub_rounded, label: 'Community'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        border: Border(
          top: BorderSide(
            color: AppTheme.borderGreen.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = index == currentIndex;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    ref.read(mainNavIndexProvider.notifier).state = index;
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon with pill indicator
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryGreen.withValues(alpha: 0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            isSelected ? item.activeIcon : item.icon,
                            size: 22,
                            color: isSelected
                                ? AppTheme.primaryGreen
                                : AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? AppTheme.primaryGreen
                                : AppTheme.textMuted,
                          ),
                          child: Text(item.label),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem(
      {required this.icon,
      required this.activeIcon,
      required this.label});
}
