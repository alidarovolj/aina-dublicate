import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:aina_flutter/core/types/slides.dart';
import 'package:url_launcher/url_launcher.dart';

class CarouselWithIndicator extends StatefulWidget {
  final List<Slide> slideList;
  final bool showIndicators;
  final bool showGradient;
  final double height;

  const CarouselWithIndicator({
    super.key,
    required this.slideList,
    this.showIndicators = true,
    this.showGradient = false,
    this.height = 125,
  });

  @override
  State<CarouselWithIndicator> createState() => _CarouselWithIndicatorState();
}

class _CarouselWithIndicatorState extends State<CarouselWithIndicator> {
  int _current = 0;
  final CarouselController _controller = CarouselController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            CarouselSlider.builder(
              itemCount: widget.slideList.length,
              itemBuilder: (context, index, realIndex) {
                final slide = widget.slideList[index];
                return GestureDetector(
                  onTap: () {
                    if (slide.button?.link != null) {
                      launchUrl(slide.button!.link);
                    }
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: widget.height,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(slide.previewImage.url),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
              options: CarouselOptions(
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 5),
                autoPlayAnimationDuration: const Duration(milliseconds: 1000),
                height: widget.height,
                enlargeCenterPage: true,
                enableInfiniteScroll: true,
                viewportFraction: 1,
                enlargeFactor: 0,
                scrollDirection: Axis.horizontal,
                onPageChanged: (index, reason) {
                  setState(() {
                    _current = index;
                  });
                },
              ),
            ),
            if (widget.showGradient)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            if (widget.showIndicators)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: widget.slideList.asMap().entries.map((entry) {
                    return Container(
                      width: 6.0,
                      height: 6.0,
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _current == entry.key
                            ? Colors.white
                            : Colors.transparent,
                        border: Border.all(
                          color: Colors.white,
                          width: 1.0,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ],
    );
  }

  void launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
