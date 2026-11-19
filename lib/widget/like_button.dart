import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Tombol like dengan animasi Lottie dan ikon hati permanen saat liked.
class LikeButton extends StatefulWidget {
  final bool isLiked;
  final int likeCount;
  final VoidCallback? onTap;
  final bool showCount;
  final Color inactiveColor;
  final Color activeColor;

  const LikeButton({
    super.key,
    required this.isLiked,
    required this.likeCount,
    this.onTap,
    this.showCount = false,
    this.inactiveColor = const Color(0xFF1A1B1E),
    this.activeColor = const Color(0xFFBA1A1A),
  });

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> with TickerProviderStateMixin {
  late AnimationController _lottieController;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  bool _isPlayingLottie = false;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _lottieController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() {
            _isPlayingLottie = false;
          });
        }
      }
    });

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.3).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.3, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_bounceController);
  }

  @override
  void didUpdateWidget(LikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Jika berubah dari false ke true, putar animasi Lottie dan bounce
    if (!oldWidget.isLiked && widget.isLiked) {
      _triggerLikeAnimation();
    }
  }

  void _triggerLikeAnimation() {
    setState(() {
      _isPlayingLottie = true;
    });

    // Reset dan mainkan Lottie
    _lottieController.reset();
    _lottieController.forward();

    // Mainkan efek bounce pada ikon hati
    _bounceController.reset();
    _bounceController.forward();
  }

  void _onLottieLoaded(LottieComposition composition) {
    _lottieController.duration = composition.duration;
  }

  @override
  void dispose() {
    _lottieController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ScaleTransition(
                  scale: _bounceAnimation,
                  child: Icon(
                    widget.isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_outline_rounded,
                    size: 25,
                    color: widget.isLiked
                        ? widget.activeColor
                        : widget.inactiveColor,
                  ),
                ),
                if (_isPlayingLottie)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Lottie.asset(
                        'assets/animations/like_heart.json',
                        controller: _lottieController,
                        width: 32,
                        height: 32,
                        fit: BoxFit.contain,
                        onLoaded: _onLottieLoaded,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (widget.showCount) ...[
            const SizedBox(width: 4),
            Text(
              '${widget.likeCount}',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: widget.isLiked
                    ? widget.activeColor
                    : widget.inactiveColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
