import 'package:egrocer/helper/utils/generalImports.dart';

Future<Map<String, dynamic>> getPlaceOrderApi({required BuildContext context, required Map<String, dynamic> params}) async {
  print("entered in order placed api");
  var response = await GeneralMethods.sendApiRequest(apiName: ApiAndParams.apiPlaceOrder, params: params, isPost: true, context: context);
  print(response);
  return json.decode(response);
}
