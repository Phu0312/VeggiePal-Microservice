import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:VeggiePal/core/network/api_client.dart';
import 'package:VeggiePal/core/widgets/paged_list_view.dart';
import 'package:VeggiePal/features/blog/data/blog_models.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('hiện các mục của trang đầu và tải thêm khi cuộn xuống cuối', (tester) async {
    final requested = <int>[];
    final key = GlobalKey<PagedListViewState<String>>();
    await tester.pumpWidget(_host(PagedListView<String>(
      key: key,
      emptyText: 'Trống',
      spacing: 0,
      load: (page) async {
        requested.add(page);
        return PageData([for (var i = 0; i < 10; i++) 'Mục ${page * 10 + i}'], page, 2, 20);
      },
      itemBuilder: (_, s) => SizedBox(height: 120, child: Text(s)),
    )));
    await tester.pumpAndSettle();

    expect(requested, [0]);
    expect(find.text('Mục 0'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pumpAndSettle();

    expect(requested, [0, 1]); // chỉ tải đúng trang kế tiếp, một lần
    expect(key.currentState!.items.length, 20);
  });

  testWidgets('danh sách rỗng hiện thông báo; replaceWhere cập nhật đúng một mục', (tester) async {
    final key = GlobalKey<PagedListViewState<String>>();
    var empty = true;
    await tester.pumpWidget(_host(PagedListView<String>(
      key: key,
      emptyText: 'Chưa có gì',
      load: (page) async => PageData(empty ? <String>[] : ['a', 'b'], 0, 1),
      itemBuilder: (_, s) => Text('item-$s'),
    )));
    await tester.pumpAndSettle();
    expect(find.text('Chưa có gì'), findsOneWidget);

    empty = false;
    await key.currentState!.reload();
    await tester.pumpAndSettle();
    expect(find.text('item-a'), findsOneWidget);

    key.currentState!.replaceWhere((s) => s == 'a', 'z');
    await tester.pump();
    expect(find.text('item-a'), findsNothing);
    expect(find.text('item-z'), findsOneWidget);
    expect(find.text('item-b'), findsOneWidget);
  });

  testWidgets('lỗi tải hiện popup và nút thử lại', (tester) async {
    var fail = true;
    await tester.pumpWidget(_host(PagedListView<String>(
      emptyText: 'Trống',
      errorTitle: 'Không tải được thử nghiệm',
      load: (page) async {
        if (fail) throw ApiException('Mất kết nối');
        return PageData(['ok'], 0, 1);
      },
      itemBuilder: (_, s) => Text(s),
    )));
    await tester.pumpAndSettle();
    expect(find.text('Không tải được thử nghiệm'), findsOneWidget);
    expect(find.text('Mất kết nối'), findsOneWidget);

    await tester.tap(find.text('Đóng'));
    await tester.pumpAndSettle();
    fail = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('ok'), findsOneWidget);
  });
}
