import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import 'package:aihaoji/req.dart';

class reqdatas {
  final String? _Cookie;
  final String? _Authorization;

  reqdatas(this._Cookie, this._Authorization);

  //笔记本
  Future<Map<String, Map<String, String>>> reqNodes() async {
    Map<String, Map<String, String>> maps = HashMap();
    dynamic json = await Req.fetchData(
      "https://aihaoji.com/api/v1/folder/tree",
      _Cookie,
      _Authorization,
    );
    var jsonDecode2 = jsonDecode(json)["data"];
    for (var nodex in jsonDecode2) {
      Map<String, String> map = HashMap();
      map["id"] = nodex["id"].toString();
      map["name"] = nodex["name"].toString();
      map["total"] = nodex["total"].toString();
      maps[nodex["name"].toString()] = map;
    }
    return maps;
  }

  //笔记
  Future<Map<String, dynamic>> reqNode(String id) async {
    LinkedHashMap<String, dynamic> maps = LinkedHashMap();
    dynamic json = await Req.fetchData(
      "https://aihaoji.com/api/v1/folder/content?page_no=1&page_size=1000&folder_id=$id&keyword=",
      _Cookie,
      _Authorization,
    );
    var jsonDecode2 = jsonDecode(json)["data"]["content"];
    int i = jsonDecode2.length;
    for (var nodex in jsonDecode2) {
      //print(nodex["status"]);
      if (nodex["status"] != "fail") {
        maps["$i.${nodex["name"]}"] = nodex;
      }
      i--;
    }
    return maps;
  }

  //reqSummaryContent
  Future<dynamic> reqSummaryContent(String bizId) async {
    Map<String, String> maps = HashMap();
    dynamic json = await Req.fetchData(
      "https://aihaoji.com/api/v1/article/meta/$bizId",
      _Cookie,
      _Authorization,
    );
    return jsonDecode(json)["data"];
  }

  Future<dynamic> reqReadContent(String bizId) async {
    Map<String, String> maps = HashMap();
    dynamic json = await Req.fetchData(
      "https://aihaoji.com/api/v2/article/section/$bizId?page_no=1&page_size=200",
      _Cookie,
      _Authorization,
    );
    return jsonDecode(json)["data"];
  }

  Future<int> Export(
    dynamic summaryContent,
    dynamic readContent,
    String FileName,
    String FileSeverPath, {
    void Function(int downloaded, int total)? onImageProgress,
  }) async {
    String summaryContents = "";
    String readContents = "";
    //print("------------------------------------------");
    //print(summaryContent);
   /*  if (FileName == "292.未命名任务") {
      print("summaryContent:$summaryContent");
    } */
    print("------------------------------------------");
    //print(summaryContent["name"]);
    final RegExp illegalChars = RegExp(r'[<>:"/\\|?#*]');
    final RegExp illegal1Chars = RegExp(r'\.+$');
    FileName = FileName.toString()
        .replaceAll(illegalChars, "")
        .replaceAll(illegal1Chars, "");
    List<String> images = [];
    //print(FileName);
    summaryContents += summaryContent["name"] + "\n";
    //print(summaryContent["author"]);
    summaryContents += summaryContent["author"] + "\n";
    //print(summaryContent["video_url"]);
    summaryContents += summaryContent["video_url"] + "\n";
    // print("AI总结");
    summaryContents +=
        "\n## AI总结"
        "\n";
    //print("一句话总结");
    summaryContents +=
        "**一句话总结**"
        "\n";
    // print(summaryContent["out_language_total_summary_json"]["one_sentence_summary"]);
    summaryContents +=
        summaryContent["out_language_total_summary_json"]["one_sentence_summary"] +
        "\n";
    //print("要点");
    summaryContents +=
        "\n**要点**"
        "\n";
    if (summaryContent["out_language_total_summary_json"]["takeaways"]
        is Iterable<dynamic>) {
      for (var takeaway
          in summaryContent["out_language_total_summary_json"]["takeaways"]) {
        summaryContents += "- " + takeaway + "\n";
        //print("- "+takeaway);
      }
    }
    //print("深度问答");
    summaryContents +=
        "\n**深度问答**"
        "\n";
    if (summaryContent["out_language_total_summary_json"]["in_depth_qa"]
        is Iterable<dynamic>) {
      for (dynamic in_depth_qa
          in summaryContent["out_language_total_summary_json"]["in_depth_qa"]) {
        String spacing = "";

        if (in_depth_qa is Iterable<dynamic>) {
          for (dynamic o in in_depth_qa) {
            summaryContents += "$spacing- " + o + "\n";
            spacing += "    ";
          }
        } else if (in_depth_qa is String) {
          summaryContents += "- $in_depth_qa\n";
        }
      }
    }
    //print("术语解释");
    summaryContents +=
        "\n**术语解释**"
        "\n";
    if (summaryContent["out_language_total_summary_json"]["terminology_explanation"]
        is Iterable<dynamic>) {
      for (var takeaway
          in summaryContent["out_language_total_summary_json"]["terminology_explanation"]) {
        //print("- "+takeaway);
        summaryContents += "- " + takeaway + "\n";
      }
    }
    // print("文字总结");
    summaryContents +=
        "\n## 文字大纲"
        "\n";
    //print(summaryContent["out_language_outline"]);
    summaryContents += summaryContent["out_language_outline"] + "\n";
    print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
    //print("AI润色: ");
    readContents += "\n## 图文笔记（润色版）\n";
    for (var content in readContent["content"]) {
      // print("- *${content["speaker"]}:* **${content["start_time"]} - "
      //     "${content["end_time"]}**" );
      readContents +=
          "- *${content["speaker"]}:* **${content["start_time"]} - "
          "${content["end_time"]}**\n";
      var picPathNode = content["oss_pic_path"];
      if (picPathNode is String && picPathNode.length > 2) {
        String contentString = picPathNode
            .substring(1, picPathNode.length - 1)
            .replaceAll("'", "");
        if (contentString.isNotEmpty) {
          List<String> repairedList = contentString.split(', ');
          for (var imageUrl in repairedList) {
            //print("    - ![]($imageUrl)");
            final uri = Uri.parse(imageUrl);
            String iamgeName = p.basename(uri.path);
            readContents += "    - ![](image/$iamgeName)\n";
          }
        }
      } else {
        print("    - (该条目没有图片)");
      }

      // print("    - ${content["out_language_modified_text"].toString()
      //     .replaceAll("\n-", "\n    -")
      //     .replaceAll("\n\n", "\n    - ")}" );

      readContents +=
          "    - ${content["out_language_modified_text"].toString().replaceAll("\n-", "\n    -").replaceAll("\n\n", "\n    - ")}\n\n";
      // print("\n******");
    }

    //print("原文: ");
    readContents += "\n\n## 图文笔记（原文版）\n";
    for (var content in readContent["content"]) {
      // print("- *${content["speaker"]}:* **${content["start_time"]} - "
      //     "${content["end_time"]}**" );
      readContents +=
          "- *${content["speaker"]}:* **${content["start_time"]} - "
          "${content["end_time"]}**\n";
      var picPathNode = content["oss_pic_path"];
      if (picPathNode is String && picPathNode.length > 2) {
        String contentString = picPathNode
            .substring(1, picPathNode.length - 1)
            .replaceAll("'", "");
        if (contentString.isNotEmpty) {
          List<String> repairedList = contentString.split(', ');
          for (var imageUrl in repairedList) {
            //print("    - ![]($imageUrl)");
            images.add(imageUrl);
            final uri = Uri.parse(imageUrl);

            String iamgeName = p.basename(uri.path);
            readContents += "    - ![](image/$iamgeName)\n";
          }
        }
      } else {
        //print("    - (该条目没有图片)");
      }

      // print("    - ${content["out_language_origin_text"]}");
      readContents += "    - ${content["out_language_origin_text"]}\n\n";
      //print("    - Ai润色: ${content["out_language_modified_text"]}" );
      //print("\n******");
    }
    // print(summaryContents);
    // print(readContents);
    String Contents = "$summaryContents\n";
    Contents += readContents;

    final savePath = p.join(FileSeverPath, FileName);
    // 1. 创建用于保存图片的 'images' 子文件夹
    final imageDir = Directory(savePath);
    if (!await imageDir.exists()) {
      // recursive: true 可以确保即使父目录不存在也能被创建
      await imageDir.create(recursive: true);
    }

    final FilesavePath = p.join(savePath, "$FileName.md");
    final file = File(FilesavePath);
    await file.writeAsString(Contents);
    file.writeAsString(Contents);
    final imageSavePath = p.join(savePath, "image");
    _downloadImages(images, imageSavePath, onImageProgress);

    //print(images);
    return 1;
  }

  Future<void> _downloadImages(
    List<String> urls,
    String baseSavePath,
    void Function(int downloaded, int total)? onProgress,
  ) async {
    // 如果没有图片需要下载，直接返回
    if (urls.isEmpty) {
      return;
    }

    final dio = Dio();
    final totalCount = urls.length;
    int completedCount = 0;
    // 1. 创建用于保存图片的 'images' 子文件夹
    final imageDir = Directory(baseSavePath);
    if (!await imageDir.exists()) {
      // recursive: true 可以确保即使父目录不存在也能被创建
      await imageDir.create(recursive: true);
    }

    // 2. 为每个 URL 创建一个下载任务 (Future)
    final List<Future> downloadFutures = urls.map((url) {
      final fileName = p.basename(Uri.parse(url).path); // 从 URL 中安全地获取文件名
      final savePath = p.join(imageDir.path, fileName);

      // 3. 使用 dio.download 并处理可能的错误
      return dio
          .download(url, savePath)
          .then(
            (_) => {
              // print('✅ 图片下载成功: $fileName')
            },
          )
          .catchError((error) {
            // 只打印错误，不中断其他下载
            print('❌ 图片下载失败: $url, 原因: $error');
          })
          .whenComplete(() {
            completedCount++;
            onProgress?.call(completedCount, totalCount);
          });
    }).toList();

    // 4. 使用 Future.wait 并发执行所有下载，并等待它们全部结束
    // eagerError: false 确保即使有任务失败，也会等待所有任务都处理完毕
    await Future.wait(downloadFutures, eagerError: false);
  }
}

void main() async {
  reqdatas reqdata = reqdatas(
    r'''__Host-next-auth.csrf-token=82ccadef25ba739016aeb8b0062b11070fe918cb7a627ea4db09037970c42ea3%7C6bd360b7d3007ddcf70643f1a1c3ea1c9357350e85e847346d2e2d18a0d6168d; _c_WBKFRo=Ld97VlcF0NWj2G0nWMy1aXBWczIrcp788hbkdsMs; _nb_ioWEgULi=; _ga=GA1.1.416336798.1752640993; Hm_lvt_7280894222f8c6009bb512847905f249=1752657885; HMACCOUNT=5F5E1B322647E81D; _ga_0M2EFQEVYF=GS2.1.s1752743806$o4$g0$t1752743806$j60$l0$h0; Hm_lpvt_7280894222f8c6009bb512847905f249=1752743807; jwtToken=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6bnVsbCwid3hfb3Blbl9pZCI6Im80SFNnNkhxbldHX0h4VWhNUlBtNTktbktxOVEiLCJzdWIiOiJ1c2VyXzk2OTY3NTcyLTk5YjUtNDhlNy0yODVkLTQ3YzU1YzBhNzk1NCIsIm5hbWUiOiJ3eF91c2VyX0NVY0pkSSIsImV4cCI6MTc1NTM2NDYyNH0.EO8xi_60ZNBMDt9fGXQT8MuIj2kytw8HJYdFSRbPM5g; __Secure-next-auth.callback-url=https%3A%2F%2Faihaoji.com%2Fzh; __Secure-next-auth.session-token=eyJhbGciOiJkaXIiLCJlbmMiOiJBMjU2R0NNIn0..RMkvecBSIXC2PQxm.ck2AYVOUSboXbex2qB-egmYAZidoWSAjPawm3s8Hbqxu9b_p0-SZhWc-9U50Xmj6GZM-YtBc0S923xBoZra9LgPeEdyl4FGYety81HwIwpT0zyPy_dm4sVDB5eiWXmOCUr6vZvlPvxAnErtwfPSC70eBKV7EIZhqKMa7rfl80qtpzPi8kdiUCJt4Ic_Kct-ojBI0fp3oiIAjjaFgka1VT7xkeFSbV09M5vjTUuwhSD7XMx6KSaqCEuIul7TFkI8DjvJQixjzXnREbs82HC9eFQa-LRtigW6FRgsnxXPIJGfB4RrLa1y-FQKknFi8jlzVztD_mUGB8VUB870upIM4bJMZbjrxBgSkFpXyEAc7S4BGvjj8b5y_g6oSTo9kTOYlw_pPPE1ymKxJlCdwvMAO8PkTuI-lgTrAmd32z0Mi5KcL4ETn5jxV74hxgDEQoSY1Cz4JiG7GGFwHOb0x0-oUiNhmPAsIRrabIsHD7DkydSPa3xEScRqDFz9VR34sBM9JalIbdGSqbgj6OZ1vz4qjPVCRJ2hAiC8SbMhCnQbdFP3km_ZD7cQmjy8eigCEq48XRH83d3G-P19Hrzk7EbDW9Oftn8a-NQipdO-sir8UinRo9MXVNTyXs_mBX6ZDNrKJdYFbgq8EQLxp-B1iMuhow0tIeqo9DzbTN8HTuPY4E9EaWfiDGVzhzj3Y.4ZxkXNByD4kERtPI3AKMBQ''',
    r'''eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6bnVsbCwid3hfb3Blbl9pZCI6Im80SFNnNkhxbldHX0h4VWhNUlBtNTktbktxOVEiLCJzdWIiOiJ1c2VyXzk2OTY3NTcyLTk5YjUtNDhlNy0yODVkLTQ3YzU1YzBhNzk1NCIsIm5hbWUiOiJ3eF91c2VyX0NVY0pkSSIsImV4cCI6MTc1NTM2NDYyNH0.EO8xi_60ZNBMDt9fGXQT8MuIj2kytw8HJYdFSRbPM5g''',
  );
  // Map<String, Map<String, String>> maps = await reqdata.reqNodes();
  // for (var key in maps.keys) {
  //   Map<String, String>? map = maps[key];
  //   Map<String, dynamic> node = await reqdata.reqNode(map!["id"].toString(), 1);
  //   for (var key in node.keys) {
  //     String biz_id = node[key]["biz_id"];
  //     dynamic SummaryContent = await reqdata.reqSummaryContent(biz_id);
  //     dynamic ReadContent = await reqdata.reqReadContent(biz_id);
  //     reqdata.Export(SummaryContent, ReadContent, "D:\A");
  //     // await reqdata.reqNodeContent(node[key].toString());
  //   }
  // }
  Map<String, dynamic> node = await reqdata.reqNode("35245");
  //print(node);
  // dynamic SummaryContent = await reqdata.reqSummaryContent(
  //   "15f1d22b-d179-0086-8323-91928d4fe631",
  // );
  // dynamic ReadContent = await reqdata.reqReadContent(
  //   "15f1d22b-d179-0086-8323-91928d4fe631",
  // );
  // reqdata.Export(SummaryContent, ReadContent, "D:\A");
  //await reqdata.reqNode(maps["id"].toString());
}
