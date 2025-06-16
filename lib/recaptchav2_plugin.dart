library recaptchav2_plugin;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class RecaptchaV2 extends StatefulWidget {
  final String apiKey;
  final String pluginURL;
  final RecaptchaV2Controller controller;
  final bool addCancelButton;
  final String cancelButtonLabel;
  final ValueChanged<String> response;

  RecaptchaV2({
    required this.apiKey,
    required this.pluginURL,
    RecaptchaV2Controller? controller,
    required this.response,
    this.addCancelButton = true,
    this.cancelButtonLabel = "CANCEL RECAPTCHA",
  })  : controller = controller ?? RecaptchaV2Controller(),
        assert(apiKey.isNotEmpty, "Google ReCaptcha API KEY is missing.");

  @override
  State<RecaptchaV2> createState() => _RecaptchaV2State();
}

class _RecaptchaV2State extends State<RecaptchaV2> {
  late final RecaptchaV2Controller controller;
  late final WebViewController webViewController;
  bool _isWebViewInitialized = false;

  void onListen() {
    if (controller.visible && _isWebViewInitialized) {
      webViewController.clearCache();
      webViewController.reload();
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    controller = widget.controller;
    controller.addListener(onListen);
    _initializeWebViewController();
  }

  Future<void> _initializeWebViewController() async {
    // // Setup JavaScript channel
    // final jsChannel = JavaScriptChannel(
    //   name: 'RecaptchaFlutterChannel',
    //   onMessageReceived: (message) => _handleToken(message.message),
    // );

    // Create and configure WebViewController
    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // ..addJavaScriptChannel(jsChannel)
      ..addJavaScriptChannel(
        'RecaptchaFlutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          _handleToken(message.message);
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(content: Text(message.message)),
          // );
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            setState(() => _isWebViewInitialized = true);
          },
        ),
      )
      ..loadRequest(
        Uri.parse('${widget.pluginURL}?api_key=${widget.apiKey}'),
      );
  }

  void _handleToken(String token) {
    if (token.contains("verify")) {
      token = token.substring(7);
    }
    widget.response(token);
    controller.hide();
  }

  @override
  void didUpdateWidget(RecaptchaV2 oldWidget) {
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(onListen);
      controller = widget.controller;
      controller.addListener(onListen);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    controller.removeListener(onListen);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: controller.visible
          ? Stack(
              children: [
                _buildWebView(),
                if (widget.addCancelButton) _buildCancelButton(),
              ],
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildWebView() {
    return Container(
      color: Colors.white,
      child: _isWebViewInitialized
          ? WebViewWidget(controller: webViewController)
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildCancelButton() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 60,
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: controller.hide,
                child: Text(widget.cancelButtonLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RecaptchaV2Controller extends ChangeNotifier {
  bool _visible = false;
  bool get visible => _visible;

  void show() {
    _visible = true;
    notifyListeners();
  }

  void hide() {
    _visible = false;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
