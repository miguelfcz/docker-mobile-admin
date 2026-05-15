import 'package:flutter_test/flutter_test.dart';

import 'package:docker_mobile_app/main.dart';

void main() {
  testWidgets('shows the initial Docker Mobile screen', (tester) async {
    await tester.pumpWidget(const DockerMobileApp());

    expect(find.text('Docker Mobile Admin'), findsOneWidget);
    expect(find.text('Painel de containers'), findsOneWidget);
    expect(find.text('Backend Dart'), findsOneWidget);
    expect(find.text('Base criada'), findsOneWidget);
  });
}
