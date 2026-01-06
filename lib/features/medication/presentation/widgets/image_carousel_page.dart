import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pautamedica/features/medication/presentation/widgets/medication_image_placeholder.dart';

class ImageCarouselPage extends StatefulWidget {
  final List<String> imagePaths;
  final int initialIndex;
  final String medicationName;

  const ImageCarouselPage({
    super.key,
    required this.imagePaths,
    required this.initialIndex,
    required this.medicationName,
  });

  @override
  State<ImageCarouselPage> createState() => _ImageCarouselPageState();
}

class _ImageCarouselPageState extends State<ImageCarouselPage> {
  late PageController _pageController;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    _currentPage = widget.initialIndex;
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page!.round();
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.medicationName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        backgroundColor: Colors.deepPurple.shade900,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imagePaths.length,
            itemBuilder: (context, index) {
              return Center(
                child: InteractiveViewer(
                  child: Image.file(
                    File(widget.imagePaths[index]),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const MedicationImagePlaceholder(
                          size: 200, iconSize: 80);
                    },
                  ),
                ),
              );
            },
          ),
          if (widget.imagePaths.length > 1 && _currentPage > 0)
            Positioned(
              left: 0,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.ease,
                  );
                },
              ),
            ),
          if (widget.imagePaths.length > 1 &&
              _currentPage < widget.imagePaths.length - 1)
            Positioned(
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.arrow_forward_ios),
                onPressed: () {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.ease,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
