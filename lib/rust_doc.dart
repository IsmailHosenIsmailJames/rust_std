import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:rust_std/list_of_html_files.dart';
import 'package:rust_std/show_toast_messages.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class InAppWebViewExampleScreen extends StatefulWidget {
  const InAppWebViewExampleScreen({super.key});

  @override
  InAppWebViewExampleScreenState createState() =>
      InAppWebViewExampleScreenState();
}

class InAppWebViewExampleScreenState extends State<InAppWebViewExampleScreen> {
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
  String url = "";
  double progress = 0;
  Widget initWiget = const Center(
    child: CircularProgressIndicator(),
  );

  void initLastWebUrl() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String initUrl = prefs.getString("last_url") ??
        "file:///android_asset/flutter_assets/assets/std/index.html";
    makeAppBarTitle(initUrl);
    setState(() {
      initWiget = InAppWebView(
        key: webViewKey,
        // initialFile: initUrl,
        initialUrlRequest: URLRequest(url: WebUri(initUrl)),
        // initialUrlRequest:
        // URLRequest(url: WebUri(Uri.base.toString().replaceFirst("/#/", "/") + 'page.html')),
        // initialFile: "assets/index.html",
        initialUserScripts: UnmodifiableListView<UserScript>([]),
        initialSettings: settings,
        contextMenu: contextMenu,
        pullToRefreshController: pullToRefreshController,
        onWebViewCreated: (controller) async {
          webViewController = controller;
        },
        onLoadStart: (controller, url) async {
          setState(() {
            this.url = url.toString();
          });
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          if (url != null) {
            await prefs.setString("last_url", url.toString());
          }
          makeAppBarTitle(url.toString());
        },
        onPermissionRequest: (controller, request) async {
          return PermissionResponse(
              resources: request.resources,
              action: PermissionResponseAction.GRANT);
        },
        shouldOverrideUrlLoading: (controller, navigationAction) async {
          var uri = navigationAction.request.url!;

          if (![
            "http",
            "https",
            "file",
            "chrome",
            "data",
            "javascript",
            "about"
          ].contains(uri.scheme)) {
            if (await canLaunchUrl(uri)) {
              // Launch the App
              await launchUrl(
                uri,
              );
              // and cancel the request
              return NavigationActionPolicy.CANCEL;
            }
          }

          return NavigationActionPolicy.ALLOW;
        },
        onLoadStop: (controller, url) async {
          pullToRefreshController?.endRefreshing();
          setState(() {
            this.url = url.toString();
          });
        },
        onReceivedError: (controller, request, error) {
          pullToRefreshController?.endRefreshing();
        },
        onProgressChanged: (controller, progress) {
          if (progress == 100) {
            pullToRefreshController?.endRefreshing();
          }
          setState(() {
            this.progress = progress / 100;
          });
        },
        onUpdateVisitedHistory: (controller, url, isReload) {
          setState(() {
            this.url = url.toString();
          });
        },
        onConsoleMessage: (controller, consoleMessage) {},
      );
    });
  }

  @override
  void initState() {
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
    FlutterNativeSplash.remove();
  }

  @override
  void dispose() {
    super.dispose();
  }

  String appBarTitile = "";

  void makeAppBarTitle(String url) {
    if (url.startsWith("file")) {
      List partsOfURL = url.split("/");
      List toBeShow = partsOfURL.sublist(6);
      String showString = toBeShow.toString();
      showString = showString
          .replaceAll(" ", "")
          .replaceAll("[", "")
          .replaceAll("]", "")
          .replaceAll(",", "/");
      setState(() {
        appBarTitile = showString;
      });
    } else {
      setState(() {
        appBarTitile = url;
      });
    }
    setState(() {
      showSearchBar = false;
      appBarSeacrchIcon = Icons.search;
    });
  }

  List<String> listOfSurfaceFolders = [
    "ascii",
    "panic",
    "i32",
    "result",
    "mem",
    "u32",
    "i128",
    "panicking",
    "option",
    "u8",
    "any",
    "cell",
    "i8",
    "usize",
    "fmt",
    "clone",
    "hash",
    "char",
    "simd",
    "path",
    "ops",
    "borrow",
    "isize",
    "task",
    "array",
    "primitive",
    "u16",
    "str",
    "process",
    "std_float",
    "prelude",
    "boxed",
    "assert_matches",
    "fs",
    "thread",
    "intrinsics",
    "u64",
    "async_iter",
    "f32",
    "rc",
    "default",
    "string",
    "future",
    "env",
    "collections",
    "os",
    "slice",
    "alloc",
    "pin",
    "time",
    "backtrace",
    "ptr",
    "i16",
    "hint",
    "error",
    "io",
    "iter",
    "sys_common",
    "net",
    "f64",
    "cmp",
    "i64",
    "num",
    "u128",
    "marker",
    "vec",
    "sync",
    "arch",
    "ffi",
    "convert"
  ];
  TextEditingController searchController = TextEditingController();
  TextEditingValue textEditingValue = const TextEditingValue();
  bool showSearchBar = false;
  bool expandSearchBar = true;
  bool autoFocus = false;
  IconData appBarSeacrchIcon = Icons.search;
  @override
  Widget build(BuildContext context) {
    listOfSurfaceFolders.sort();
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        bool? canPop = await webViewController?.canGoBack();
        if (canPop == true) {
          webViewController?.goBack();
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        drawer: expandSearchBar
            ? Drawer(
                child: ListView.builder(
                  itemCount: listOfSurfaceFolders.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return const DrawerHeader(
                        decoration: BoxDecoration(
                            color: Color.fromARGB(100, 33, 149, 243)),
                        child: Center(
                          child: Column(
                            children: [
                              SizedBox(
                                height: 80,
                                child: CircleAvatar(
                                  radius: 40,
                                  backgroundImage:
                                      AssetImage("assets/img/logo.jpg"),
                                ),
                              ),
                              Text(
                                "RUST DOC",
                                style: TextStyle(
                                    fontSize: 40, fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else {
                      return Padding(
                        padding: const EdgeInsets.only(
                            left: 15, right: 15, top: 3, bottom: 3),
                        child: TextButton.icon(
                          onPressed: () {
                            webViewController?.loadUrl(
                              urlRequest: URLRequest(
                                url: WebUri(
                                  "file:///android_asset/flutter_assets/assets/std/${listOfSurfaceFolders[index - 1]}/index.html",
                                ),
                              ),
                            );
                            if (Scaffold.of(context).isDrawerOpen) {
                              Scaffold.of(context).closeDrawer();
                            }
                          },
                          icon: const Icon(Icons.folder),
                          label: Row(
                            children: [
                              Text(
                                listOfSurfaceFolders[index - 1][0]
                                        .toUpperCase() +
                                    listOfSurfaceFolders[index - 1]
                                        .substring(1),
                                style: const TextStyle(fontSize: 22),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                ),
              )
            : null,
        appBar: AppBar(
          toolbarHeight: 65,
          title: Row(
            children: [
              if (expandSearchBar)
                SizedBox(
                  height: 35,
                  width: 35,
                  child: IconButton(
                    iconSize: 20,
                    icon: const Icon(
                      Icons.home,
                    ),
                    onPressed: () async {
                      final SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      String homePage = prefs.getString("home_page") ??
                          "file:///android_asset/flutter_assets/assets/std/index.html";
                      await webViewController?.loadUrl(
                        urlRequest: URLRequest(
                          url: WebUri(homePage),
                        ),
                      );
                    },
                  ),
                ),
              if (expandSearchBar)
                const SizedBox(
                  width: 5,
                ),
              Expanded(
                child: SizedBox(
                  height: 45,
                  child: Autocomplete<String>(
                    optionsMaxHeight: 500,
                    fieldViewBuilder: (context, textEditingController,
                        focusNode, onFieldSubmitted) {
                      return TextField(
                        textAlignVertical: TextAlignVertical.bottom,
                        textAlign: TextAlign.start,
                        style: const TextStyle(fontSize: 13),
                        controller: textEditingController,
                        focusNode: focusNode,
                        autofocus: autoFocus,
                        onTapOutside: (event) {
                          focusNode.unfocus();
                          setState(() {
                            autoFocus = false;
                            expandSearchBar = true;
                          });
                        },
                        onTap: () {
                          focusNode.requestFocus();
                          setState(() {
                            autoFocus = true;
                            expandSearchBar = false;
                          });
                        },
                        onEditingComplete: onFieldSubmitted,
                        decoration: InputDecoration(
                          hintText: appBarTitile,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                      );
                    },
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text == '') {
                        return const Iterable<String>.empty();
                      }
                      return allHTMLFilesPathSorted.where((String option) {
                        return option
                            .contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    onSelected: (String selection) {
                      webViewController?.loadUrl(
                          urlRequest: URLRequest(
                              url: WebUri(
                                  "file:///android_asset/flutter_assets/assets/std/$selection")));
                    },
                  ),
                ),
              ),
              if (expandSearchBar)
                const SizedBox(
                  width: 5,
                ),
              if (expandSearchBar)
                SizedBox(
                  height: 35,
                  width: 35,
                  child: IconButton(
                    iconSize: 20,
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () async {
                      await webViewController?.goBack();
                    },
                  ),
                ),
              if (expandSearchBar)
                const SizedBox(
                  width: 5,
                ),
              if (expandSearchBar)
                SizedBox(
                  height: 35,
                  width: 35,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 20,
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () async {
                      await webViewController?.goForward();
                    },
                  ),
                ),
              if (expandSearchBar)
                SizedBox(
                  height: 35,
                  width: 35,
                  child: PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Text("Reload"),
                        onTap: () async {
                          await webViewController?.reload();
                        },
                      ),
                      PopupMenuItem(
                        child: const Text(
                          "Set as your Home page",
                        ),
                        onTap: () async {
                          final webUri = await webViewController?.getUrl();
                          String currentURL = webUri.toString();
                          final SharedPreferences prefs =
                              await SharedPreferences.getInstance();
                          await prefs.setString("home_page", currentURL);
                          showToast("Set this as your Home page done.");
                        },
                      ),
                      PopupMenuItem(
                        child: const Text(
                          "Go to defult home page",
                        ),
                        onTap: () async {
                          webViewController?.loadUrl(
                            urlRequest: URLRequest(
                              url: WebUri(
                                  "file:///android_asset/flutter_assets/assets/std/index.html"),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        // drawer: Drawer(),
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Expanded(
                child: Stack(
                  children: [
                    initWiget,
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
