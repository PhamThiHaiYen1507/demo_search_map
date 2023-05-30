import 'package:get/get.dart';
import 'package:map_position/poin_data.dart';

class DemoSearchController extends GetxController {
  late final Rxn<PoinData> poin_from;
  late final Rxn<PoinData> poin_to;

  @override
  void onInit() {
    poin_from = Rxn();
    poin_to = Rxn();
    super.onInit();
  }
}
