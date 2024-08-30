class HubWaveResponse {
  final String id;
  final int amount;
  final String checkout_status;
  final String? client_reference;
  final String currency;
  final String error_url;
  final String? last_payment_error;
  final String business_name;
  final String payment_status;
  final String success_url;
  final String wave_launch_url;
  final String? when_completed;
  final String when_created;
  final String when_expires;

  const HubWaveResponse({
    required this.id,
    required this.amount,
    required this.checkout_status,
    required this.client_reference,
    required this.currency,
    required this.error_url,
    required this.last_payment_error,
    required this.business_name,
    required this.payment_status,
    required this.success_url,
    required this.wave_launch_url,
    required this.when_completed,
    required this.when_created,
    required this.when_expires
  });

  factory HubWaveResponse.fromJson(Map<String, dynamic> json) {
    return HubWaveResponse(
        id: json['id'],
        amount: json['amount'],
        checkout_status: json['checkout_status'],
        client_reference: json['client_reference'],
        currency: json['currency'],
        error_url: json['error_url'],
        last_payment_error: json['last_payment_error'],
        business_name: json['business_name'],
        payment_status: json['payment_status'],
        success_url: json['success_url'],
        wave_launch_url: json['wave_launch_url'],
        when_completed: json['when_completed'],
        when_created: json['when_created'],
        when_expires: json['when_expires']
    );
  }
}