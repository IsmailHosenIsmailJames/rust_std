import 'dart:collection';
import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:rust_std/src/resources/list_of_files.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class WebViewInApp extends StatefulWidget {
  const WebViewInApp({
    super.key,
  });

  @override
  WebViewInAppState createState() => WebViewInAppState();
}

class WebViewInAppState extends State<WebViewInApp> {
  final GlobalKey webViewKey = GlobalKey();

  InAppWebViewController? webViewController;
  InAppWebViewSettings settings = InAppWebViewSettings(
      isInspectable: kDebugMode,
      mediaPlaybackRequiresUserGesture: false,
      allowsInlineMediaPlayback: true,
      iframeAllow: "camera; microphone",
      iframeAllowFullscreen: true);

  PullToRefreshController? pullToRefreshController;

  late ContextMenu contextMenu;
  double progress = 0;
  Widget initWidget = const Center(
    child: CircularProgressIndicator(),
  );

  void initLastWebUrl() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? homeURL = prefs.getString("home");
    log(homeURL.toString());
    setState(() {
      initWidget = InAppWebView(
        key: webViewKey,
        initialUrlRequest: URLRequest(
          url: WebUri(
            homeURL ??
                "file:///android_asset/flutter_assets/assets/std/index.html",
          ),
        ),
        initialUserScripts: UnmodifiableListView<UserScript>([]),
        initialSettings: settings,
        contextMenu: contextMenu,
        pullToRefreshController: pullToRefreshController,
        onWebViewCreated: (controller) async {
          webViewController = controller;
        },
        onLoadStart: (controller, url) async {
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          if (url != null) {
            await prefs.setString("last_url", url.toString());
          }
        },
        onPermissionRequest: (controller, request) async {
          return PermissionResponse(
              resources: request.resources,
              action: PermissionResponseAction.GRANT);
        },
        onReceivedError: (controller, request, error) {
          pullToRefreshController?.endRefreshing();
          log("Found Error ");
          if (error.description.contains("net::ERR_FILE_NOT_FOUND")) {
            showDialog(
              context: context,
              builder: (context) {
                return Dialog(
                  child: SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "This page is the part of 'Rust Doc - Everything' app.",
                            style: TextTheme.of(context).titleLarge,
                          ),
                          SizedBox(
                            height: 5,
                          ),
                          Text(
                              "You can download it form play store... its free and contains no ads."),
                          SizedBox(
                            height: 15,
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                launchUrl(
                                  Uri.parse(
                                    "https://play.google.com/store/apps/details?id=com.rust_doc.md_ismail_hosen",
                                  ),
                                );
                              },
                              label: Text(
                                "Get 'Rust Doc - Everything'",
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
        onProgressChanged: (controller, progress) {
          if (progress == 100) {
            pullToRefreshController?.endRefreshing();
          }
          setState(() {
            this.progress = progress / 100;
          });
        },
      );
    });
  }

  @override
  void initState() {
    // FlutterNativeSplash.remove();
    super.initState();
    contextMenu = ContextMenu(
      menuItems: [
        ContextMenuItem(
            id: 1,
            title: "Special",
            action: () async {
              await webViewController?.clearFocus();
            })
      ],
      settings: ContextMenuSettings(hideDefaultSystemContextMenuItems: false),
      onCreateContextMenu: (hitTestResult) async {},
    );

    pullToRefreshController = kIsWeb ||
            ![TargetPlatform.iOS, TargetPlatform.android]
                .contains(defaultTargetPlatform)
        ? null
        : PullToRefreshController(
            settings: PullToRefreshSettings(
              color: Colors.blue,
            ),
            onRefresh: () async {
              if (defaultTargetPlatform == TargetPlatform.android) {
                webViewController?.reload();
              } else if (defaultTargetPlatform == TargetPlatform.iOS ||
                  defaultTargetPlatform == TargetPlatform.macOS) {
                webViewController?.loadUrl(
                    urlRequest:
                        URLRequest(url: await webViewController?.getUrl()));
              }
            },
          );

    initLastWebUrl();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        bool? canPop = await webViewController?.canGoBack();
        if (canPop == true) {
          webViewController?.goBack();
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          toolbarHeight: 43,
          title: Row(
            children: [
              IconButton(
                onPressed: () async {
                  final SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  String? homeURL = prefs.getString("home");
                  webViewController!.loadUrl(
                    urlRequest: URLRequest(
                      url: WebUri(homeURL ??
                          "file:///android_asset/flutter_assets/assets/std/index.html"),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.home_rounded,
                ),
              ),
              Expanded(
                child: Autocomplete<String>(
                  optionsMaxHeight: 380,
                  fieldViewBuilder: (context, textEditingController, focusNode,
                      onFieldSubmitted) {
                    return SizedBox(
                      height: 38,
                      child: CupertinoSearchTextField(
                        controller: textEditingController,
                        style: TextStyle(color: Colors.grey),
                        focusNode: focusNode,
                      ),
                    );
                  },
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text == '') {
                      return const Iterable<String>.empty();
                    }
                    return listOfFiles.where((String option) {
                      return option
                          .toLowerCase()
                          .contains(textEditingValue.text.toLowerCase());
                    });
                  },
                  onSelected: (String selection) async {
                    log(selection);

                    webViewController?.loadUrl(
                      urlRequest: URLRequest(
                        url: WebUri(
                          "file:///android_asset/flutter_assets/assets/$selection",
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(
                width: 5,
              ),
              SizedBox(
                height: 30,
                width: 30,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: () async {
                    if (await webViewController!.canGoBack()) {
                      webViewController!.goBack();
                    }
                  },
                  icon: const Icon(
                    Icons.arrow_back,
                    size: 18,
                  ),
                ),
              ),
              SizedBox(
                height: 30,
                width: 30,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: () async {
                    if (await webViewController!.canGoForward()) {
                      webViewController!.goForward();
                    }
                  },
                  icon: const Icon(
                    Icons.arrow_forward,
                    size: 18,
                  ),
                ),
              ),
              SizedBox(
                height: 30,
                width: 40,
                child: PopupMenuButton(
                  padding: EdgeInsets.zero,
                  itemBuilder: (context) {
                    return [
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(Icons.home_rounded),
                            SizedBox(
                              width: 10,
                            ),
                            Text(
                              "Set as home",
                            ),
                          ],
                        ),
                        onTap: () async {
                          final SharedPreferences prefs =
                              await SharedPreferences.getInstance();
                          var x = await webViewController?.getUrl();
                          log(x?.path.toString() ?? "Not Found");
                          String? path = x?.path;
                          if (path != null) path = "file://$path";
                          path ??=
                              "file:///android_asset/flutter_assets/assets/std/index.html";
                          log(path);
                          await prefs.setString(
                            "home",
                            path,
                          );
                          webViewController!.loadUrl(
                              urlRequest: URLRequest(url: WebUri(path)));
                        },
                      ),
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(Icons.restore),
                            SizedBox(
                              width: 10,
                            ),
                            Text(
                              "Reset home",
                            ),
                          ],
                        ),
                        onTap: () async {
                          final SharedPreferences prefs =
                              await SharedPreferences.getInstance();

                          String indexPath =
                              "file:///android_asset/flutter_assets/assets/std/index.html";

                          await prefs.setString("last_url", indexPath);

                          await prefs.setString("home", indexPath);
                          webViewController!.loadUrl(
                              urlRequest: URLRequest(url: WebUri(indexPath)));
                        },
                      ),
                    ];
                  },
                ),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Expanded(
                child: Stack(
                  children: [
                    initWidget,
                    progress < 1.0
                        ? LinearProgressIndicator(value: progress)
                        : Container(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
