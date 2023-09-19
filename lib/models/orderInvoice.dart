class OrderInvoice {
  int? status;
  String? message;
  int? total;
  String? data;

  OrderInvoice({this.status, this.message, this.total, this.data});

  OrderInvoice.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    total = json['total'];
    data = json['data'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['message'] = message;
    data['total'] = total;
    data['data'] = this.data;
    return data;
  }
}
