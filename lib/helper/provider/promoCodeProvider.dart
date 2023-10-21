import 'package:egrocer/helper/utils/generalImports.dart';

enum PromoCodeState {
  initial,
  loading,
  loaded,
  error,
}

class PromoCodeProvider extends ChangeNotifier {
  PromoCodeState promoCodeState = PromoCodeState.initial;
  String message = '';
  late PromoCode promoCode;

  getPromoCodeProvider({
    required Map<String, dynamic> params,
    required BuildContext context,
  }) async {
    promoCodeState = PromoCodeState.loading;

    notifyListeners();

    try {
      Map<String, dynamic> getData = (await getPromoCodeApi(context: context, params: params));
       print("promocodeapi");
      print(getData);
       print(getData[ApiAndParams.status]);
      if (getData[ApiAndParams.status] == 1) {
        print("entered in if of getpromocode");
        promoCode = PromoCode.fromJson(getData);
        print(promoCode);
        promoCodeState = PromoCodeState.loaded;
      } else {
        promoCodeState = PromoCodeState.error;
      }
      notifyListeners();
    } catch (e) {
      message = e.toString();
      promoCodeState = PromoCodeState.error;
      GeneralMethods.showSnackBarMsg(context, message);
      notifyListeners();
    }
  }

  applyPromoCode(PromoCodeData promoCode) {
    Constant.isPromoCodeApplied = true;
    Constant.selectedCoupon = promoCode.promoCode;
    Constant.discountedAmount = double.parse(promoCode.discountedAmount);
    Constant.discount = double.parse(promoCode.discount);
    notifyListeners();
  }
}
