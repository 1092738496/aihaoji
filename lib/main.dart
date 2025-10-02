import 'dart:convert';

import 'package:aihaoji/dypage.dart';
import 'package:aihaoji/reqdatas.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(MaterialApp(home: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(1080, 1920),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(home: homepage(), title: "爱好记");
      },
    );
  }
}

class homepage extends StatefulWidget {
  const homepage({super.key});

  @override
  State<homepage> createState() => _homepageState();
}

class _homepageState extends State<homepage> {
  InAppWebViewController? _webViewController;
  final CookieManager cookieManager = CookieManager.instance();
  String? Cookie;
  String? Authorization;
  String? nodeID;

  final CookieManager _cookieManager = CookieManager.instance();

  //登入状态
  bool _ready = true;

  //选中状态
  int _selectedIndex = 0;

  //多选数据
  final List<int> _selectedIndices = [];

  //笔记对象
  reqdatas? _reqdata;

  //笔记本数据
  late Future<Map<String, Map<String, String>>> _nodesFuture;
  String? SelectNodeName;

  //笔记数据
  Future<Map<String, dynamic>>? _nodeDataFuture;

  Map<String, dynamic>? _nodeData;

  // 请将您的 Cookie 字符串粘贴到这里
  final String cookieString =
      r'_c_WBKFRo=Ld97VlcF0NWj2G0nWMy1aXBWczIrcp788hbkdsMs; _ga=GA1.1.416336798.1752640993; Hm_lvt_7280894222f8c6009bb512847905f249=1752657885; _ga_0M2EFQEVYF=GS2.1.s1752743806$o4$g1$t1752744043$j6$l0$h0; __Secure-next-auth.callback-url=https%3A%2F%2Faihaoji.com; __Host-next-auth.csrf-token=0675c31058770ad176901130b9e5437a3c88c047e9beef9720a02bf7318f79ec%7Cb778544c77d95125522f4ad5c3b11b2f82706d0c1fefe4143a22b708587743f5; __Secure-next-auth.session-token=eyJhbGciOiJkaXIiLCJlbmMiOiJBMjU2R0NNIn0..hIpwpOxnQCzO3U_3.C9FrlywEHNuAjMfWRVTSSZ2aq7zibJ744yjCo3xY8QjQy0AwQF2tRn7Qh8RbpK8Oet_-lQDpQBi2DNlRyRmpL6tChcMW2CZIAtBNgtTVy3LNxd1Gep_amiPfDVMM7c_Z7WwIkwKPXB-uypCCw-sRzJLZx1p8SpuVeuWOAOInYFgjyO_AItVJbw98H7FjCjIzzddNBJD4g28L04QutcGTeIoB4r05rUXXXO2ZP22OLOSlXFifNY2pUKjcXdljx2MT-fX5WICCjlSvXiToprjxMfsGGHus1B7Ywo7Ooa30jzNIHnkKJqrBw6ST1EtIx0kKGnbpmputeDV3FdItwwtGdX1w7oVqZg0bJqXne3-Kl6nEpyerWjbdAFuV2T59dSLJd3tNgNJCcUxEeszda2QeyVXVnb6yVUTwZ-iVdvfdmnRD2k49gcQRDILSJNNzKw6y00bYLXOlzZsMY-hx6DXOm-LRw14jM808asSVuKmNdivWhToM1B02BLryva27QiopD8yMwtVAhjEFIcZmMm9_BYsY1Dnxzo78D_b0VQ2YTq7mBXTb8DKeVHwGys85KXpvoPiAiVp5y1fqW6v2g8c6rvL_aAxRMkiI2N7qSEX53Qk-82OOmybnnohW0Nyg-VJE-5xt8AMF6CuIFcp6khdyrdg.dshVAqr8citlxypZYRXeAA';

  // 请将您的 Authorization Token 粘贴到这里
  final String authToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6InVuZGVmaW5lZCIsInd4X29wZW5faWQiOm51bGwsInN1YiI6InVzZXJfMmIzYjdjNzgtZmU3NS02ZDVhLWY4ZjItM2M4YjliZmExMjgyIiwibmFtZSI6IjE3NzA3NzYxNDYwIiwiZXhwIjoxNzYxMjU5MDM2fQ.zMnpyLr9H0O7GD7UTZQD5jtOVbdvzzZJQURA5OHjlSw';

  // 关键：指定这些 Cookie 和 Token 属于哪个域名
  final String targetDomain = "aihaoji.com";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // _setupCredentials();
  }

  Future<void> _setupCredentials() async {
    // 第一步：清空旧的 Cookie，确保一个干净的环境
    await _cookieManager.deleteAllCookies();
    print("🧹 旧 Cookie 已清空");

    // 第二步：解析并设置所有 Cookie
    final targetUrl = WebUri("https://$targetDomain");
    final cookies = cookieString.split(';');

    for (var cookie in cookies) {
      final parts = cookie.split('=');
      if (parts.length >= 2) {
        final name = parts.first.trim();
        final value = parts.sublist(1).join('=').trim();

        await _cookieManager.setCookie(
          url: targetUrl,
          name: name,
          value: value,
          domain: ".$targetDomain", // 使用 . 开头使其对所有子域名有效
        );
        print("🍪 设置 Cookie: $name");
      }
    }

    print("✅ 所有 Cookie 设置完毕!");
  }

  @override
  void dispose() {
    super.dispose();
    _webViewController = null;
  }

  void _loadInitialData() {
    if (_reqdata != null) {
      setState(() {
        // 触发 FutureBuilder 重新加载
        _nodesFuture = _reqdata!.reqNodes();
      });
    }
  }

  void _loadNodeContent(String nodeId) {
    if (_reqdata != null) {
      setState(() {
        // 当用户点击时，为右侧区域创建一个新的加载任务
        _nodeDataFuture = _reqdata!.reqNode(nodeId);
      });
    }
  }

  String? _selectedDirectory;

  // 这个变量暂时不用了，我们将把JS直接写在下面
  // static const String dataExtractorJs = r''' ... ''';

  /// 调用系统文件夹选择器的异步方法
  void _pickDirectory() async {
    // 调用 file_picker 的 getDirectoryPath 方法
    // 它会打开系统的文件夹选择对话框
    String? directoryPath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: '请选择一个文件夹', // 对话框标题
    );

    // 如果用户选择了一个路径（没有取消）
    if (directoryPath != null) {
      // 使用 setState 更新界面，显示选择的路径
      setState(() {
        _selectedDirectory = directoryPath;
      });
      print('选择的路径是: $directoryPath');
    } else {
      print('用户取消了选择');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            child: _ready
                ? InAppWebView(
                    initialUrlRequest: URLRequest(
                      url: WebUri("https://aihaoji.com/zh"),
                    ),
                    onWebViewCreated: (controller) {
                      _webViewController = controller;
                    },

                    shouldInterceptRequest:
                        (
                          InAppWebViewController controller,
                          WebResourceRequest request,
                        ) {
                          final upperCase = request.method?.toUpperCase();
                          if (upperCase == 'GET') {
                            if (request.url.toString().contains(
                              "https://aihaoji.com/api/v2/order/plan-list",
                            )) {
                              Cookie = request.headers?["Cookie"];
                              Authorization = request.headers?["Authorization"];
                              if (Cookie != null &&
                                  Cookie!.isNotEmpty &&
                                  Authorization != null &&
                                  Authorization!.isNotEmpty) {
                                // print("Cookie:${Cookie}");
                                // print("Authorization:${Authorization}");
                                //print("登入成功!");
                                _reqdata = reqdatas(Cookie, Authorization);
                                setState(() {
                                  _ready = false;
                                  _loadInitialData();
                                });
                              }
                            }
                          }
                          return Future.value(null);
                        },
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      // print(_selectedIndex);
                      // print("Cookie:${Cookie}");
                      // print("Authorization:${Authorization}");
                      // print("_notes:${_notes}");

                      return Container(
                        child: Row(
                          children: [
                            SizedBox(
                              width: 280.w,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 一个固定的头部
                                  const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Text(
                                      '我的笔记',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const Divider(height: 1),
                                  // 关键：使用 Expanded 包裹列表，让它填满剩余空间并可滚动
                                  Expanded(
                                    // 使用 ListView.builder 来高效地构建不确定长度的列表
                                    child: FutureBuilder<Map<String, Map<String, String>>>(
                                      future: _nodesFuture,
                                      builder:
                                          (
                                            BuildContext context,
                                            AsyncSnapshot snapshot,
                                          ) {
                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              );
                                            }
                                            Map<String, Map<String, String>>
                                            data = snapshot.data;
                                            final List<String> list = data.keys
                                                .toList();
                                            return ListView.builder(
                                              itemCount: list.length,
                                              itemBuilder: (context, index) {
                                                final bool isSelected =
                                                    _selectedIndex == index;

                                                if (_selectedIndex == 0) {
                                                  nodeID =
                                                      data[data
                                                          .keys
                                                          .first]!["id"];
                                                }
                                                return ListTile(
                                                  title: Text(list[index]),
                                                  subtitle: Text(
                                                    '共 ${data[list[index]]?["total"]} 篇笔记',
                                                  ),
                                                  // ✅ 根据 isSelected 状态来决定样式
                                                  // 设置选中时的背景色，让效果更明显
                                                  selected: isSelected,
                                                  // 设置选中时的背景色，让效果更明显
                                                  selectedTileColor: Colors.blue
                                                      .withOpacity(0.1),

                                                  // 设置选中时，文字和图标的颜色
                                                  selectedColor: Colors.blue,
                                                  onTap: () {
                                                    setState(() {
                                                      _selectedIndices.clear();
                                                      _selectedIndex = index;
                                                      final String nodeId =
                                                          data[list[index]]!["id"]!;
                                                      nodeID = nodeId;
                                                      SelectNodeName =
                                                          list[index];
                                                      // 3. ✅ 触发右侧内容的加载
                                                      _loadNodeContent(nodeId);
                                                    });
                                                  },
                                                );
                                              },
                                            );
                                          },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 50.w),
                            SizedBox(
                              width: 710.w,
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          SelectNodeName ?? "",
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            TextButton(
                                              onPressed: () {
                                                setState(() {
                                                  _selectedIndices.clear();
                                                  for (
                                                    int i = 0;
                                                    i < _nodeData!.length;
                                                    i++
                                                  ) {
                                                    _selectedIndices.add(i);
                                                  }
                                                });
                                                // 在这里添加全选所有项目的逻辑
                                              },
                                              child: const Text('全选'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                setState(() {
                                                  _selectedIndices.clear();
                                                });
                                                // 在这里添加全选所有项目的逻辑
                                              },
                                              child: const Text('清空'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (BuildContext context) {
                                                    List<String> namelist = [];
                                                    var list = _nodeData?.keys
                                                        .toList();
                                                    for (
                                                      int i = 0;
                                                      i <
                                                          _selectedIndices
                                                              .length;
                                                      i++
                                                    ) {
                                                      var name =
                                                          list?[_selectedIndices[i]];
                                                      namelist.add(name!);
                                                    }
                                                    return StatefulBuilder(
                                                      builder:
                                                          (
                                                            BuildContext
                                                            context,
                                                            StateSetter
                                                            dialogSetState,
                                                          ) {
                                                            return AlertDialog(
                                                              title: const Text(
                                                                '导出',
                                                              ),
                                                              content: SizedBox(
                                                                height: 500.h,
                                                                width: 650.w,
                                                                child: ListView.builder(
                                                                  shrinkWrap:
                                                                      true,
                                                                  itemCount:
                                                                      namelist
                                                                          .length,
                                                                  itemBuilder:
                                                                      (
                                                                        BuildContext
                                                                        context,
                                                                        int
                                                                        index,
                                                                      ) {
                                                                        return ListTile(
                                                                          title: Text(
                                                                            namelist[index],
                                                                          ),
                                                                        );
                                                                      },
                                                                ),
                                                              ),

                                                              actions: <Widget>[
                                                                Text(
                                                                  _selectedDirectory ??
                                                                      '请选择导出目录...',
                                                                  style: TextStyle(
                                                                    color: Colors
                                                                        .grey[600],
                                                                  ),
                                                                ),
                                                                ElevatedButton.icon(
                                                                  icon: const Icon(
                                                                    Icons
                                                                        .folder,
                                                                  ),
                                                                  // 文件夹图标
                                                                  label:
                                                                      const Text(
                                                                        "选择目录",
                                                                      ),
                                                                  // 按钮文字
                                                                  onPressed: () async {
                                                                    String?
                                                                    directoryPath =
                                                                        await FilePicker
                                                                            .platform
                                                                            .getDirectoryPath();
                                                                    if (directoryPath !=
                                                                        null) {
                                                                      // ✅ 使用 dialogSetState 来刷新对话框里的 Text
                                                                      dialogSetState(() {
                                                                        // 更新对话框UI的同时，也更新主页面的状态变量
                                                                        _selectedDirectory =
                                                                            directoryPath;
                                                                      });
                                                                    }
                                                                  }, // 点击事件
                                                                ),
                                                                TextButton(
                                                                  child:
                                                                      const Text(
                                                                        '取消',
                                                                      ),
                                                                  onPressed: () {
                                                                    Navigator.of(
                                                                      context,
                                                                    ).pop(); // 关闭对话框
                                                                  },
                                                                ),
                                                                TextButton(
                                                                  child:
                                                                      const Text(
                                                                        '确定',
                                                                      ),
                                                                  onPressed: () async {
                                                                    //提示框
                                                                    if (namelist
                                                                            .isEmpty ||
                                                                        _selectedDirectory ==
                                                                            null) {
                                                                      showDialog(
                                                                        context:
                                                                            context,
                                                                        builder:
                                                                            (
                                                                              BuildContext
                                                                              context,
                                                                            ) {
                                                                              return AlertDialog(
                                                                                icon: const Icon(
                                                                                  Icons.error,
                                                                                  color: Colors.red,
                                                                                  size: 48,
                                                                                ),
                                                                                title: const Text(
                                                                                  '错误',
                                                                                ),
                                                                                content: const Text(
                                                                                  '请确保已选择笔记和路径!',
                                                                                ),
                                                                                actions:
                                                                                    <
                                                                                      Widget
                                                                                    >[
                                                                                      TextButton(
                                                                                        child: const Text(
                                                                                          '好的',
                                                                                        ),
                                                                                        onPressed: () {
                                                                                          Navigator.of(
                                                                                            context,
                                                                                          ).pop(); // 关闭对话框
                                                                                        },
                                                                                      ),
                                                                                    ],
                                                                              );
                                                                            },
                                                                      );
                                                                      return;
                                                                    } else {
                                                                      showDialog(
                                                                        context:
                                                                            context,
                                                                        builder:
                                                                            (
                                                                              BuildContext
                                                                              context,
                                                                            ) {
                                                                              return AlertDialog(
                                                                                icon: const Icon(
                                                                                  Icons.info,
                                                                                  color: Colors.blue,
                                                                                  size: 48,
                                                                                ),
                                                                                title: const Text(
                                                                                  '正在导出',
                                                                                ),
                                                                                content: const Text(
                                                                                  '清注意导出路径目录!',
                                                                                ),
                                                                                actions:
                                                                                    <
                                                                                      Widget
                                                                                    >[
                                                                                      TextButton(
                                                                                        child: const Text(
                                                                                          '好的',
                                                                                        ),
                                                                                        onPressed: () {
                                                                                          Navigator.of(
                                                                                            context,
                                                                                          ).pop(); // 关闭对话框
                                                                                        },
                                                                                      ),
                                                                                    ],
                                                                              );
                                                                            },
                                                                      );
                                                                    }
                                                                    for (var name
                                                                        in namelist) {
                                                                      var bizId =
                                                                          _nodeData?[name]["biz_id"];

                                                                      var summaryContent =
                                                                          await _reqdata?.reqSummaryContent(
                                                                            bizId,
                                                                          );
                                                                      var ReadContent =
                                                                          await _reqdata?.reqReadContent(
                                                                            bizId,
                                                                          );

                                                                      await _reqdata?.Export(
                                                                        summaryContent,
                                                                        ReadContent,
                                                                        name,
                                                                        _selectedDirectory!,
                                                                      );
                                                                    }
                                                                    //namelist
                                                                    //_nodeData
                                                                  },
                                                                ),
                                                              ],
                                                            );
                                                          },
                                                    );
                                                  },
                                                );
                                              },
                                              child: const Text('导出'),
                                            ),
                                            TextButton(
                                              onPressed: () => {
                                                showDialog(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                        return Dypage(
                                                          Cookie,
                                                          Authorization,
                                                          nodeID,
                                                        );
                                                      },
                                                ),
                                              },
                                              child: Text("导入"),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: FutureBuilder<Map<String, dynamic>>(
                                      future: _nodeDataFuture,
                                      builder:
                                          (
                                            BuildContext context,
                                            AsyncSnapshot snapshot,
                                          ) {
                                            // ✅ 判断一：检查任务是否还在进行中
                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              // 如果是，就返回一个加载指示器
                                              return const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              );
                                            }

                                            // ✅ 判断二：检查任务是否出错
                                            if (snapshot.hasError) {
                                              return Center(
                                                child: Text(
                                                  '出错了: ${snapshot.error}',
                                                ),
                                              );
                                            }

                                            if (snapshot.hasData) {
                                              Map<String, dynamic> node =
                                                  snapshot.data;
                                              _nodeData = node;

                                              return Container(
                                                child: ListView.builder(
                                                  itemCount: node.length,
                                                  itemBuilder: (context, index) {
                                                    final isSelected =
                                                        _selectedIndices
                                                            .contains(index);

                                                    return Card(
                                                      color: isSelected
                                                          ? Colors.amber[100]
                                                          : null,
                                                      // 选中时高亮
                                                      margin:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 6,
                                                          ),
                                                      child: ListTile(
                                                        title: Text(
                                                          node.keys
                                                              .toList()[index],
                                                        ),
                                                        onTap: () {
                                                          setState(() {
                                                            if (isSelected) {
                                                              _selectedIndices
                                                                  .remove(
                                                                    index,
                                                                  ); // 如果已选中，则移除
                                                            } else {
                                                              _selectedIndices
                                                                  .add(
                                                                    index,
                                                                  ); // 如果未选中，则添加
                                                            }
                                                          });
                                                        },
                                                      ),
                                                    );
                                                  },
                                                ),
                                              );
                                            }
                                            return Container();
                                          },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Positioned(
            right: 10.w,
            bottom: 10.h,
            child: FloatingActionButton(
              child: Text("登出"),
              onPressed: () async {
                // 1. 先在 setState 外面，执行所有需要等待的异步操作
                await cookieManager.deleteAllCookies();
                final cookies = await cookieManager.getCookies(
                  url: WebUri("https://aihaoji.com/"),
                );
                print("清空后，Cookie 还剩: $cookies");

                // 2. 当所有异步操作都完成后，再调用 setState 进行纯粹的、同步的状态更新
                if (mounted) {
                  // 检查 Widget 是否还存活
                  setState(() {
                    Cookie = null; // 设为 null 更安全
                    Authorization = null;
                    _ready = true;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
