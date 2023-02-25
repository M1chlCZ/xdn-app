import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xdn_web_app/src/overlay_pages/start_fifth_page.dart';
import 'package:xdn_web_app/src/overlay_pages/start_first_page.dart';
import 'package:xdn_web_app/src/overlay_pages/start_forth_page.dart';
import 'package:xdn_web_app/src/overlay_pages/start_second_page.dart';
import 'package:xdn_web_app/src/overlay_pages/start_sixth_page.dart';
import 'package:xdn_web_app/src/overlay_pages/start_third_page.dart';
import 'package:xdn_web_app/src/provider/blocking_provider.dart';
import 'package:xdn_web_app/src/widgets/alert_dialogs.dart';
import 'package:xdn_web_app/src/widgets/flat_custom_btn.dart';

class StartOverlay extends ModalRoute<void> {
  final PageController _pageController = PageController(initialPage: 0);

  int _activePage = 0;

  final List<Widget> _pages = const [
    StartOvrPage(),
    SecondOvrPage(),
    ThirdOvrPage(),
    ForthOvrPage(),
    FifthOvrPage(),
    SixthOvrPage(),
  ];

  @override
  Duration get transitionDuration => const Duration(milliseconds: 200);

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => false;

  @override
  Color get barrierColor => Colors.black.withOpacity(0.5);

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    // This makes sure that text and other content follows the material style
    return Material(
      type: MaterialType.transparency,
      // make sure that the overlay content is not cut off
      child: SafeArea(
        child: _buildOverlayContent(context),
      ),
    );
  }

  Widget _buildOverlayContent(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Center(
            child: StatefulBuilder(builder: (context, setState) {
              return Consumer(builder: (context, ref, child) {
                final block = ref.read(blockProvider.notifier);
                return Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    height: MediaQuery.of(context).size.height * 0.9,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C3353),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            Expanded(
                              child: PageView.builder(
                                controller: _pageController,
                                onPageChanged: (int page) {
                                  setState(() {
                                    _activePage = page;
                                  });
                                },
                                itemCount: _pages.length,
                                itemBuilder: (BuildContext context, int index) {
                                  return _pages[index % _pages.length];
                                },
                              ),
                            ),
                            Container(
                                height: MediaQuery.of(context).size.width * 0.03,
                                width: 200,
                                color: Colors.transparent,
                                child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List<Widget>.generate(
                                        _pages.length,
                                        (index) => Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 10),
                                              child: InkWell(
                                                onTap: () {
                                                  _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
                                                },
                                                child: CircleAvatar(
                                                  radius: 4,
                                                  backgroundColor: _activePage == index ? Colors.white : Colors.white24,
                                                ),
                                              ),
                                            ))))
                          ],
                        ),
                        if (_activePage != 0)
                          Positioned(
                              left: 0,
                              child: FlatCustomButton(
                                width: MediaQuery.of(context).size.width * 0.04,
                                color: Colors.black.withOpacity(0.05),
                                splashColor: Colors.black38,
                                height: MediaQuery.of(context).size.height * 0.9,
                                onTap: () {
                                  block.setBlock(false);
                                  var index = _activePage - 1;
                                  _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.fastLinearToSlowEaseIn);
                                },
                                child: const Center(child: Icon(Icons.arrow_back_ios, color: Colors.white)),
                              )),
                        if (_pages.length != _activePage + 1)
                          Positioned(
                              right: 0,
                              child: FlatCustomButton(
                                width: MediaQuery.of(context).size.width * 0.04,
                                color: Colors.black.withOpacity(0.05),
                                splashColor: Colors.black38,
                                height: MediaQuery.of(context).size.height * 0.9,
                                onTap: () {
                                  if (block.isLoading) {
                                    showAlertDialog(title: 'Alert', content: 'Please complete this step to proceed', context: context);
                                    return;
                                  }
                                  var index = _activePage + 1;
                                  _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.fastLinearToSlowEaseIn);
                                },
                                child: const Center(child: Icon(Icons.arrow_forward_ios, color: Colors.white)),
                              )),
                      ],
                    ));
              });
            }),
          ),
          Consumer(builder: (context, ref, child) {
            return Positioned(
              right: 20,
              top: 20,
              child: FlatCustomButton(
                color: Colors.black,
                splashColor: Colors.red,
                radius: 8,
                onTap: () {
                  final rr = ref.read(blockProvider.notifier);
                  rr.setBlock(false);
                  Navigator.pop(context);
                },
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'X CLOSE',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            );
          }
          )
        ],
      ),
    );
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    // You can add your own animations for the overlay content
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }
}
