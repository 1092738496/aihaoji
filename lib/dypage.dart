import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
// 确保你的项目中有这个文件，或者使用下面提供的模拟版本
import 'package:aihaoji/req.dart';

class Dypage extends StatefulWidget {
  final String? _Cookie;
  final String? _Authorization;
  final String? nodeID;
  const Dypage(this._Cookie, this._Authorization, this.nodeID, {super.key});

  @override
  State<Dypage> createState() => _DypageState();
}

class _DypageState extends State<Dypage> {
  InAppWebViewController? _webViewController;
  final Map<String, String> _collectionUrls = {}; // Key: URL, Value: Title

  @override
  void initState() {
    super.initState();
    print(widget.nodeID);
    // 如果需要预设Cookie，可以在这里处理
  }

  @override
  void dispose() {
    _webViewController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('抖音收藏夹监听 (${_collectionUrls.length})'),
        actions: [
          IconButton(
            onPressed: () async {
              if (_collectionUrls.isEmpty) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('请先等待页面加载并收集URL')));
                return;
              }

              final Set<String>? selectedUrls = await showDialog<Set<String>>(
                context: context,
                builder: (BuildContext context) {
                  // 使用我们增强后的对话框
                  return _SelectionDialog(allItems: _collectionUrls);
                },
              );

              if (selectedUrls == null || selectedUrls.isEmpty) {
                print("用户取消了选择或未选择任何项。");
                return;
              }

              print("用户选择了 ${selectedUrls.length} 个URL，准备发送请求...");

              final List<Map<String, String>> urlListPayload = selectedUrls.map(
                (url) {
                  return {'url': url, 'task_source': 'douyin'};
                },
              ).toList();
              for (var i = 0; i < urlListPayload.length; i++) {
                var url = urlListPayload[i]["url"]!.trim();
                var title = _collectionUrls[url];

                final Map<String, dynamic> payload = {
                  'url_list': [urlListPayload[i]],
                };
                try {
                  var result = await Req.PostfetchData(
                    "https://aihaoji.com/api/v1/url/detail",
                    widget._Cookie ?? "",
                    widget._Authorization ?? "",
                    payload,
                  );
                  print("第一步请求:$result");
                  await Future.delayed(const Duration(seconds: 5));
                  print("-----------------------");
                  // 2. 提取出原始的任务对象 (Object)
                  // 显式地将解码后的对象转换为 Map<String, dynamic> 以获得类型安全
                  final Map<String, dynamic> originalTaskObject =
                      Map<String, dynamic>.from(
                        jsonDecode(result)["data"][0]["data"],
                      );

                  // 3. ✨ 创建一个新的可变 Map，并明确其类型
                  // 使用 Map.from() 构造函数来复制原始对象，确保类型正确
                  final Map<String, dynamic> transformedTaskObject = Map.from(
                    originalTaskObject,
                  );

                  // 4. ✨ 根据您的目标格式，添加或派生新的字段
                  // 注意：这里的很多值需要根据您的业务逻辑来定义

                  // 从现有字段派生
                  transformedTaskObject['name'] = originalTaskObject['title'];
                  transformedTaskObject['url'] =
                      originalTaskObject['origin_url'];
                  transformedTaskObject['url_biz_id'] =
                      originalTaskObject['biz_id'];
                  transformedTaskObject['author'] =
                      originalTaskObject['author_name'];

                  // ⚠️ 下面的这些值在原始数据中不存在，您需要从其他地方获取
                  // 这里我先用一些占位符或默认值来演示
                  transformedTaskObject['ctrl_params'] = {
                    "image_mode": "more",
                    "input_language": "auto",
                    "output_language": "zh",
                    "enable_speaker_recognition": true,
                    "enable_ai_polish": true,
                    "custom_words": [],
                    "folder_id": widget.nodeID, // 使用从 App 获取的值
                  };
                  transformedTaskObject['folder_id'] = widget.nodeID;

                  // 5. ✨ 创建最终的 payload，将转换后的对象放入一个 List 中
                  var finalPayload = {
                    'task_list': [
                      transformedTaskObject,
                    ], // <-- 关键：将对象放入一个数组/List
                  };

                  //print("API1 请求: ${jsonEncode(finalPayload)}");

                  final result2 = await Req.PostfetchData(
                    "https://aihaoji.com/api/v5/task/create/batch",
                    widget._Cookie ?? "",
                    widget._Authorization ?? "",
                    finalPayload,
                  );
                  print("第二步请求:$result2");
                  print(
                    "`````````````````````````````````````````````````````````````````",
                  );
                  var result2json = jsonDecode(result2);
                  bool A = result2json["data"][0]["success"];
                  if (A) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('成功导入: $title')));
                    await Future.delayed(const Duration(seconds: 8));
                  } else {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('任务已创建: $title')));
                    await Future.delayed(const Duration(seconds: 5));
                  }
                } catch (e) {
                  print("API 异常请求失败: $e");
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('导入失败: $e')));
                  }
                }
              }
            },
            icon: const Icon(Icons.import_export),
            tooltip: '导入',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(
                url: WebUri(
                  "https://www.douyin.com/user/self?showTab=favorite_collection",
                ),
              ),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                userAgent:
                    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36",
              ),
              onWebViewCreated: (controller) {
                _webViewController = controller;
                controller.addJavaScriptHandler(
                  handlerName: 'collectionHandler',
                  callback: (args) {
                    if (args.isNotEmpty && args[0] is Map) {
                      final Map<String, dynamic> dynamicUrls =
                          Map<String, dynamic>.from(args[0]);
                      final Map<String, String> urls = dynamicUrls.map(
                        (key, value) => MapEntry(key, value.toString()),
                      );

                      setState(() {
                        _collectionUrls.addAll(urls);
                      });
                    }
                  },
                );
              },
              onLoadStop: (controller, url) async {
                await controller.evaluateJavascript(
                  source: r'''
                    (() => {
                      console.log("🚀 JS Observer Script Injected!");
                      const targetSelector = "#user_detail_element > div > div.XA9ZQ2av > div > div > div.z_YvCWYy.Klp5EcJu > div > div.XVZoufXL > div > div > ul";
                      
                      function sendCollectionsToFlutter() {
                        const nodes = document.querySelectorAll(targetSelector + " > li");
                        if (nodes.length === 0) {
                          console.log("... waiting for collection list to render.");
                          return;
                        }
                        
                        const dataObject = {};
                        nodes.forEach(node => {
                          const anchor = node.querySelector('div > a');
                          const textElement = node.querySelector('div > a > p');
                          if (anchor && anchor.href && textElement && textElement.textContent) {
                            dataObject[anchor.href] = textElement.textContent.trim();
                          }
                        });

                        if (window.flutter_inappwebview) {
                          window.flutter_inappwebview.callHandler('collectionHandler', dataObject);
                          console.log(`📡 Sent ${Object.keys(dataObject).length} items to Flutter.`);
                        } else {
                          console.error("flutter_inappwebview is not available!");
                        }
                      }

                      const observer = new MutationObserver((mutationsList, observer) => {
                        console.log("DOM changed, re-fetching and sending data...");
                        sendCollectionsToFlutter();
                      });

                      const intervalId = setInterval(() => {
                        const targetNode = document.querySelector(targetSelector);
                        if (targetNode) {
                          clearInterval(intervalId);
                          console.log("🎯 Target node found. Initial data fetch and starting observer...");
                          sendCollectionsToFlutter();
                          observer.observe(targetNode, { childList: true, subtree: true });
                        }
                      }, 500);
                    })();
                  ''',
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 增强后的选择对话框 Widget
class _SelectionDialog extends StatefulWidget {
  final Map<String, String> allItems;

  const _SelectionDialog({required this.allItems});

  @override
  State<_SelectionDialog> createState() => _SelectionDialogState();
}

class _SelectionDialogState extends State<_SelectionDialog> {
  final Set<String> _selectedItems = {};

  void _selectAll() {
    setState(() {
      _selectedItems.addAll(widget.allItems.keys);
    });
  }

  void _selectNone() {
    setState(() {
      _selectedItems.clear();
    });
  }

  void _invertSelection() {
    setState(() {
      for (final itemKey in widget.allItems.keys) {
        if (_selectedItems.contains(itemKey)) {
          _selectedItems.remove(itemKey);
        } else {
          _selectedItems.add(itemKey);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<String> itemKeys = widget.allItems.keys.toList();
    final bool isAllSelected = _selectedItems.length == widget.allItems.length;

    return AlertDialog(
      title: Text('选择要导入的URL (${_selectedItems.length}/${itemKeys.length})'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: const Text(
                '全选 / 全不选',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              value: isAllSelected && itemKeys.isNotEmpty,
              onChanged: (bool? value) {
                if (value == true) {
                  _selectAll();
                } else {
                  _selectNone();
                }
              },
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
            ),
            const Divider(),
            Flexible(
              child: ListView.builder(
                itemCount: itemKeys.length,
                shrinkWrap: true,
                itemBuilder: (BuildContext context, int index) {
                  final String currentUrl = itemKeys[index];
                  final String currentTitle =
                      widget.allItems[currentUrl] ?? '无标题';
                  final bool isSelected = _selectedItems.contains(currentUrl);

                  return CheckboxListTile(
                    title: Text(
                      "${index + 1}. $currentTitle",
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    dense: true,
                    subtitle: Text(
                      currentUrl,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedItems.add(currentUrl);
                        } else {
                          _selectedItems.remove(currentUrl);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: _invertSelection, child: const Text('反选')),
        TextButton(
          child: const Text('取消'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          child: const Text('确认选择'),
          onPressed: () => Navigator.of(context).pop(_selectedItems),
        ),
      ],
    );
  }
}
