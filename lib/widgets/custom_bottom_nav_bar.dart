import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  double _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.currentIndex.toDouble();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(CustomBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _previousIndex = oldWidget.currentIndex.toDouble();
      _animationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromARGB(255, 228, 244, 247), // Xanh da trời rất nhạt
            Color.fromARGB(255, 193, 238, 244), // Xanh da trời nhạt
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          constraints: const BoxConstraints(minHeight: 70),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    context: context,
                    index: 0,
                    icon: Icons.home_rounded,
                    activeIcon: Icons.home,
                    label: 'Trang chủ',
                    animationValue: _slideAnimation.value,
                  ),
                  _buildNavItem(
                    context: context,
                    index: 1,
                    icon: Icons.chat_bubble_outline_rounded,
                    activeIcon: Icons.chat_bubble_rounded,
                    label: 'Chatbot',
                    animationValue: _slideAnimation.value,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required double animationValue,
  }) {
    final isActive = widget.currentIndex == index;
    
    // Calculate slide offset based on animation
    final double slideOffset;
    if (widget.currentIndex > _previousIndex) {
      // Sliding right (0 -> 1)
      slideOffset = index == widget.currentIndex
          ? (1 - animationValue) * 20 // Slide in from right
          : index == _previousIndex.toInt()
              ? animationValue * -20 // Slide out to left
              : 0;
    } else if (widget.currentIndex < _previousIndex) {
      // Sliding left (1 -> 0)
      slideOffset = index == widget.currentIndex
          ? (1 - animationValue) * -20 // Slide in from left
          : index == _previousIndex.toInt()
              ? animationValue * 20 // Slide out to right
              : 0;
    } else {
      slideOffset = 0;
    }
    
    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Transform.translate(
          offset: Offset(slideOffset, 0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white.withValues(alpha: 0.9)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: const Color.fromARGB(255, 139, 223, 245)
                            .withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: child,
                      );
                    },
                    child: Icon(
                      isActive ? activeIcon : icon,
                      key: ValueKey(isActive),
                      color: isActive
                          ? const Color.fromARGB(255, 139, 223, 245)
                          : Colors.grey[600],
                      size: isActive ? 26 : 22,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Flexible(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      fontSize: isActive ? 12 : 11,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive
                          ? const Color.fromARGB(255, 139, 223, 245)
                          : Colors.grey[600],
                    ),
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

