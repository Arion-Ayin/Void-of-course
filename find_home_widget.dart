import 'dart:isolate';
void main() async {
  print(await Isolate.resolvePackageUri(Uri.parse('package:home_widget/home_widget.dart')));
}
