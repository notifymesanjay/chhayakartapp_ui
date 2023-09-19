

import 'package:egrocer/helper/utils/generalImports.dart';
import 'package:egrocer/models/initiateTransaction.dart';
import 'package:egrocer/models/paytmTransationToken.dart';

enum CheckoutTimeSlotsState {
  timeSlotsLoading,
  timeSlotsLoaded,
  timeSlotsError,
}

enum CheckoutAddressState {
  addressLoading,
  addressLoaded,
  addressBlank,
  addressError,
}

enum CheckoutDeliveryChargeState {
  deliveryChargeLoading,
  deliveryChargeLoaded,
  deliveryChargeError,
}

enum CheckoutPaymentMethodsState {
  paymentMethodLoading,
  paymentMethodLoaded,
  paymentMethodError,
}

enum CheckoutPlaceOrderState {
  placeOrderLoading,
  placeOrderLoaded,
  placeOrderError,
}

class CheckoutProvider extends ChangeNotifier {
  CheckoutAddressState checkoutAddressState = CheckoutAddressState.addressLoading;

  CheckoutDeliveryChargeState checkoutDeliveryChargeState = CheckoutDeliveryChargeState.deliveryChargeLoading;

  CheckoutTimeSlotsState checkoutTimeSlotsState = CheckoutTimeSlotsState.timeSlotsLoading;

  CheckoutPaymentMethodsState checkoutPaymentMethodsState = CheckoutPaymentMethodsState.paymentMethodLoading;

  CheckoutPlaceOrderState checkoutPlaceOrderState = CheckoutPlaceOrderState.placeOrderLoading;

  String message = '';

  //Address variables
  late AddressData? selectedAddress = AddressData();

  // Order Delivery charge variables
  double subTotalAmount = 0.0;
  double totalAmount = 0.0;
  double savedAmount = 0.0;
  double deliveryCharge = 0.0;
  late List<SellersInfo> sellerWiseDeliveryCharges;
  late DeliveryChargeData deliveryChargeData;
  bool isCodAllowed = true;

  //Timeslots variables
  late TimeSlotsData timeSlotsData;
  bool isTimeSlotsEnabled = true;
  int selectedDate = 0;
  int selectedTime = 0;
  String selectedPaymentMethod = "";

  //Payment methods variables
  late PaymentMethods paymentMethods;
  late PaymentMethodsData paymentMethodsData;

  //Place order variables
  String placedOrderId = "";
  String razorpayOrderId = "";
  String transactionId = "";
  String payStackReference = "";

  String paytmTxnToken = "";

  Future<AddressData?> getSingleAddressProvider({required BuildContext context}) async {
    try {
      Map<String, dynamic> getAddress = (await getAddressApi(context: context, params: {ApiAndParams.isDefault: "1"}));
      if (getAddress[ApiAndParams.status].toString() == "1") {
        Address addressData = Address.fromJson(getAddress);
        selectedAddress = addressData.data?[0];

        checkoutAddressState = CheckoutAddressState.addressLoaded;
        notifyListeners();
        return selectedAddress;
      } else {
        checkoutAddressState = CheckoutAddressState.addressBlank;
        notifyListeners();
        return selectedAddress;
      }
    } catch (e) {
      message = e.toString();
      checkoutAddressState = CheckoutAddressState.addressError;
      GeneralMethods.showSnackBarMsg(context, message);
      notifyListeners();
      return selectedAddress;
    }
  }

  setSelectedAddress(BuildContext context, var address) async {
    if (address != AddressData()) {
      if (selectedAddress != AddressData()) {
        selectedAddress = address;

        checkoutAddressState = CheckoutAddressState.addressLoaded;
        notifyListeners();

        await getOrderChargesProvider(
          context: context,
          params: {ApiAndParams.cityId: selectedAddress!.cityId.toString(), ApiAndParams.latitude: selectedAddress!.latitude.toString(), ApiAndParams.longitude: selectedAddress!.longitude.toString(), ApiAndParams.isCheckout: "1"},
        );
      }
    } else if (selectedAddress == null && address == null) {
      checkoutAddressState = CheckoutAddressState.addressBlank;
      notifyListeners();
    }
  }

  setAddressEmptyState() {
    selectedAddress = null;
    checkoutAddressState = CheckoutAddressState.addressBlank;
    notifyListeners();
  }

  Future getOrderChargesProvider({required BuildContext context, required Map<String, String> params}) async {
    try {
      checkoutDeliveryChargeState = CheckoutDeliveryChargeState.deliveryChargeLoading;
      notifyListeners();
      Map<String, dynamic> getCheckoutData = (await getCartListApi(context: context, params: params));

      if (getCheckoutData[ApiAndParams.status].toString() == "1") {
        Checkout checkoutData = Checkout.fromJson(getCheckoutData);
        deliveryChargeData = checkoutData.data;
        isCodAllowed = deliveryChargeData.isCodAllowed != 0;
        subTotalAmount = double.parse(deliveryChargeData.subTotal);
        totalAmount = double.parse(deliveryChargeData.totalAmount);
        deliveryCharge = double.parse(deliveryChargeData.deliveryCharge.totalDeliveryCharge);
        sellerWiseDeliveryCharges = deliveryChargeData.deliveryCharge.sellersInfo;

        checkoutDeliveryChargeState = CheckoutDeliveryChargeState.deliveryChargeLoaded;
        checkoutAddressState = CheckoutAddressState.addressLoaded;
        notifyListeners();
      } else {
        checkoutDeliveryChargeState = CheckoutDeliveryChargeState.deliveryChargeError;
        checkoutAddressState = CheckoutAddressState.addressBlank;
        notifyListeners();
      }
    } catch (e) {
      message = e.toString();
      checkoutDeliveryChargeState = CheckoutDeliveryChargeState.deliveryChargeError;
      checkoutAddressState = CheckoutAddressState.addressBlank;
      notifyListeners();
      GeneralMethods.showSnackBarMsg(context, message);
    }
  }

  Future getTimeSlotsSettings({required BuildContext context}) async {
    try {
      Map<String, dynamic> getTimeSlotsSettings = (await getTimeSlotSettingsApi(context: context, params: {}));

      if (getTimeSlotsSettings[ApiAndParams.status].toString() == "1") {
        TimeSlotsSettings timeSlots = TimeSlotsSettings.fromJson(getTimeSlotsSettings);
        timeSlotsData = timeSlots.data;
        isTimeSlotsEnabled = timeSlots.data.timeSlotsIsEnabled == "true";

        selectedDate = 0;
        // DateFormat dateFormat = DateFormat("yyyy-MM-d hh:mm:ss");
        // DateTime now = new DateTime.now();
        // DateTime currentTime = dateFormat.parse(
        //     "${now.year}-${now.month}-${now.day} ${now.hour}:${now.minute}:${now.second}");
        //2022-10-18 11:36:14.267721
        if (int.parse(timeSlotsData.timeSlotsDeliveryStartsFrom) > 1) {
          selectedTime = 0;
        }
        /* else {
          for (int i = 0; i < timeSlotsData.timeSlots.length; i++) {
            DateTime timeSlotTime = dateFormat.parse(
                "${currentTime.year}-${currentTime.month}-${currentTime.day} ${timeSlotsData.timeSlots[i].lastOrderTime}");
          }
        }*/

        checkoutTimeSlotsState = CheckoutTimeSlotsState.timeSlotsLoaded;
        notifyListeners();
      } else {
        GeneralMethods.showSnackBarMsg(context, message);
        checkoutTimeSlotsState = CheckoutTimeSlotsState.timeSlotsError;
        notifyListeners();
      }
    } catch (e) {
      message = e.toString();
      GeneralMethods.showSnackBarMsg(context, message);
      checkoutTimeSlotsState = CheckoutTimeSlotsState.timeSlotsError;
      notifyListeners();
    }
  }

  setSelectedDate(int index) {
    selectedTime = 0;
    selectedDate = index;
    // DateTime currentTime = DateTime.now();
    // DateFormat dateFormat = DateFormat("yyyy-MM-d hh:mm:ss");
    //2022-10-18 11:36:14.267721
    if (int.parse(timeSlotsData.timeSlotsDeliveryStartsFrom) > 1) {
      selectedTime = 0;
    }
    /* else {
      for (int i = 0; i < timeSlotsData.timeSlots.length; i++) {
        DateTime timeSlotTime = dateFormat.parse(
            "${currentTime.year}-${currentTime.month}-${currentTime.day} ${timeSlotsData.timeSlots[i].lastOrderTime}");
      }
    }*/
    notifyListeners();
  }

  setSelectedTime(int index) {
    selectedTime = index;
    notifyListeners();
  }

  Future getPaymentMethods({required BuildContext context}) async {
    try {
      Map<String, dynamic> getPaymentMethodsSettings = (await getPaymentMethodsSettingsApi(context: context, params: {}));

      if (getPaymentMethodsSettings[ApiAndParams.status].toString() == "1") {
        paymentMethods = PaymentMethods.fromJson(getPaymentMethodsSettings);
        paymentMethodsData = paymentMethods.data;

        if (paymentMethodsData.codMode == "global" && !isCodAllowed) {
          isCodAllowed = true;
        } else if (paymentMethodsData.codMode == "product" && !isCodAllowed) {
          isCodAllowed = false;
        }

        if (paymentMethodsData.codPaymentMethod == "1" && isCodAllowed == true) {
          selectedPaymentMethod = "COD";
        } else if (paymentMethodsData.razorpayPaymentMethod == "1") {
          selectedPaymentMethod = "Razorpay";
        } else if (paymentMethodsData.paystackPaymentMethod == "1") {
          selectedPaymentMethod = "Paystack";
        } else if (paymentMethodsData.stripePaymentMethod == "1") {
          selectedPaymentMethod = "Stripe";
        } else if (paymentMethodsData.paytmPaymentMethod == "1") {
          selectedPaymentMethod = "Paytm";
        } else if (paymentMethodsData.paypalPaymentMethod == "1") {
          selectedPaymentMethod = "Paypal";
        }

        checkoutPaymentMethodsState = CheckoutPaymentMethodsState.paymentMethodLoaded;
        notifyListeners();
      } else {
        GeneralMethods.showSnackBarMsg(context, message);
        checkoutPaymentMethodsState = CheckoutPaymentMethodsState.paymentMethodError;
        notifyListeners();
      }
    } catch (e) {
      message = e.toString();
      GeneralMethods.showSnackBarMsg(context, message);
      checkoutPaymentMethodsState = CheckoutPaymentMethodsState.paymentMethodError;
      notifyListeners();
    }
  }

  setSelectedPaymentMethod(String method) {
    selectedPaymentMethod = method;
    notifyListeners();
  }

  Future placeOrder({required BuildContext context}) async {
    try {
      late DateTime dateTime;
      if (int.parse(timeSlotsData.timeSlotsDeliveryStartsFrom.toString()) == 1) {
        dateTime = DateTime.now();
      } else {
        dateTime = DateTime.now().add(Duration(days: int.parse(timeSlotsData.timeSlotsAllowedDays)));
      }
      final orderStatus = selectedPaymentMethod == "COD" ? "2" : "1";

      Map<String, String> params = {};
      params[ApiAndParams.productVariantId] = deliveryChargeData.productVariantId.toString();
      params[ApiAndParams.quantity] = deliveryChargeData.quantity.toString();
      params[ApiAndParams.total] = deliveryChargeData.subTotal.toString();
      params[ApiAndParams.deliveryCharge] = deliveryChargeData.deliveryCharge.totalDeliveryCharge.toString();
      params[ApiAndParams.finalTotal] = deliveryChargeData.totalAmount.toString();
      params[ApiAndParams.paymentMethod] = selectedPaymentMethod.toString();
      params[ApiAndParams.addressId] = selectedAddress!.id.toString();
      params[ApiAndParams.deliveryTime] = "${dateTime.day}-${dateTime.month}-${dateTime.year} ${timeSlotsData.timeSlots[selectedTime].title}";
      params[ApiAndParams.status] = orderStatus;

      Map<String, dynamic> getPlaceOrderResponse = (await getPlaceOrderApi(context: context, params: params));
      if (getPlaceOrderResponse[ApiAndParams.status].toString() == "1") {
        if (selectedPaymentMethod == "Razorpay" || selectedPaymentMethod == "Stripe") {
          PlacedPrePaidOrder placedPrePaidOrder = PlacedPrePaidOrder.fromJson(getPlaceOrderResponse);
          placedOrderId = placedPrePaidOrder.data.orderId.toString();
        } else if (selectedPaymentMethod == "Paystack") {
          payStackReference = "Charged_From_${GeneralMethods.setFirstLetterUppercase(Platform.operatingSystem)}_${DateTime.now().millisecondsSinceEpoch}";
          transactionId = payStackReference;
        } else if (selectedPaymentMethod == "COD") {
          Navigator.of(context).pushNamedAndRemoveUntil(orderPlaceScreen, (Route<dynamic> route) => false);
        } else if (selectedPaymentMethod == "Paytm") {
          PlacedPrePaidOrder placedPrePaidOrder = PlacedPrePaidOrder.fromJson(getPlaceOrderResponse);
          placedOrderId = placedPrePaidOrder.data.orderId.toString();
          initiatePaytmTransaction(context: context);
        } else if (selectedPaymentMethod == "Paypal") {
          PlacedPrePaidOrder placedPrePaidOrder = PlacedPrePaidOrder.fromJson(getPlaceOrderResponse);
          placedOrderId = placedPrePaidOrder.data.orderId.toString();
          initiatePaypalTransaction(context: context);
        }
      } else {
        GeneralMethods.showSnackBarMsg(context, getPlaceOrderResponse[ApiAndParams.message]);
        checkoutPlaceOrderState = CheckoutPlaceOrderState.placeOrderError;
        notifyListeners();
      }
    } catch (e) {
      message = e.toString();
      GeneralMethods.showSnackBarMsg(context, message);
      checkoutPlaceOrderState = CheckoutPlaceOrderState.placeOrderError;
      notifyListeners();
    }
  }

  Future initiatePaytmTransaction({required BuildContext context}) async {
    try {
      Map<String, String> params = {};

      params[ApiAndParams.orderId] = placedOrderId;
      params[ApiAndParams.amount] = totalAmount.toString();

      Map<String, dynamic> getPaytmTransactionTokenResponse = (await getPaytmTransactionTokenApi(context: context, params: params));

      if (getPaytmTransactionTokenResponse[ApiAndParams.status].toString() == "1") {
        PaytmTransactionToken paytmTransactionToken = PaytmTransactionToken.fromJson(getPaytmTransactionTokenResponse);
        paytmTxnToken = paytmTransactionToken.data?.txnToken ?? "";
        checkoutPlaceOrderState = CheckoutPlaceOrderState.placeOrderLoaded;
        notifyListeners();
      } else {
        GeneralMethods.showSnackBarMsg(context, message);
        checkoutPlaceOrderState = CheckoutPlaceOrderState.placeOrderError;
        notifyListeners();
      }
    } catch (e) {
      message = e.toString();
      GeneralMethods.showSnackBarMsg(context, message);
      checkoutPlaceOrderState = CheckoutPlaceOrderState.placeOrderError;
      notifyListeners();
    }
  }

  Future initiateRazorpayTransaction({required BuildContext context}) async {
    try {
      Map<String, String> params = {};

      params[ApiAndParams.paymentMethod] = selectedPaymentMethod.toString();
      params[ApiAndParams.orderId] = placedOrderId;

      Map<String, dynamic> getInitiatedTransactionResponse = (await getInitiatedTransactionApi(context: context, params: params));

      if (getInitiatedTransactionResponse[ApiAndParams.status].toString() == "1") {
        InitiateTransaction initiateTransaction = InitiateTransaction.fromJson(getInitiatedTransactionResponse);
        razorpayOrderId = initiateTransaction.data.transactionId;
        checkoutPlaceOrderState = CheckoutPlaceOrderState.placeOrderLoaded;
        notifyListeners();
      } else {
        GeneralMethods.showSnackBarMsg(context, message);
        checkoutPlaceOrderState = CheckoutPlaceOrderState.placeOrderError;
        notifyListeners();
      }
    } catch (e) {
      message = e.toString();
      GeneralMethods.showSnackBarMsg(context, message);
      checkoutPlaceOrderState = CheckoutPlaceOrderState.placeOrderError;
      notifyListeners();
    }
  }

  Future initiatePaypalTransaction({required BuildContext context}) async {
    try {
      Map<String, String> params = {};

      params[ApiAndParams.paymentMethod] = selectedPaymentMethod.toString();
      params[ApiAndParams.orderId] = placedOrderId;

      Map<String, dynamic> getInitiatedTransactionResponse = (await getInitiatedTransactionApi(context: context, params: params));

      if (getInitiatedTransactionResponse[ApiAndParams.status].toString() == "1") {
        Map<String, dynamic> data = getInitiatedTransactionResponse[ApiAndParams.data];
        Navigator.pushNamed(context, paypalPaymentScreen, arguments: data["paypal_redirect_url"]).then((value) {
          if (value == true) {
            Navigator.of(context).pushNamedAndRemoveUntil(orderPlaceScreen, (Route<dynamic> route) => false);
          } else {
            GeneralMethods.showSnackBarMsg(
              context,
              getTranslatedValue(context, "lblPaymentCancelledByUser"),
            );
          }
        });
        checkoutPlaceOrderState = CheckoutPlaceOrderState.placeOrderLoaded;
        notifyListeners();
      } else {
        GeneralMethods.showSnackBarMsg(context, message);
        checkoutPlaceOrderState = CheckoutPlaceOrderState.placeOrderError;
        notifyListeners();
      }
    } catch (e) {
      message = e.toString();
      GeneralMethods.showSnackBarMsg(context, message);
      checkoutPlaceOrderState = CheckoutPlaceOrderState.placeOrderError;
      notifyListeners();
    }
  }

  Future addTransaction({required BuildContext context}) async {
    try {
      late PackageInfo packageInfo;
      packageInfo = await PackageInfo.fromPlatform();

      Map<String, String> params = {};

      params[ApiAndParams.orderId] = placedOrderId;
      params[ApiAndParams.deviceType] = GeneralMethods.setFirstLetterUppercase(Platform.operatingSystem);
      params[ApiAndParams.appVersion] = packageInfo.version;
      params[ApiAndParams.transactionId] = transactionId;
      params[ApiAndParams.paymentMethod] = selectedPaymentMethod.toString();

      Map<String, dynamic> addedTransaction = (await getAddTransactionApi(context: context, params: params));
      if (addedTransaction[ApiAndParams.status].toString() == "1") {
        checkoutPlaceOrderState = CheckoutPlaceOrderState.placeOrderLoaded;
        notifyListeners();
        Navigator.of(context).pushNamedAndRemoveUntil(orderPlaceScreen, (Route<dynamic> route) => false);
      } else {
        GeneralMethods.showSnackBarMsg(context, addedTransaction[ApiAndParams.message]);
        checkoutPlaceOrderState = CheckoutPlaceOrderState.placeOrderError;
        notifyListeners();
      }
    } catch (e) {
      message = e.toString();
      GeneralMethods.showSnackBarMsg(context, message);
      checkoutPlaceOrderState = CheckoutPlaceOrderState.placeOrderError;
      notifyListeners();
    }
  }
}
