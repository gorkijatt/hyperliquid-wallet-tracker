class Wallet {
  final String address;
  String label;

  Wallet({required this.address, this.label = ''});

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      address: json['address'] as String,
      label: (json['label'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'address': address, 'label': label};

  String get displayName => label.isNotEmpty ? label : 'Wallet';

  String get shortAddress {
    if (address.length < 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  String get chipText {
    if (label.isNotEmpty) {
      return '$label \u00B7 ${address.substring(0, 6)}\u2026${address.substring(address.length - 4)}';
    }
    return '${address.substring(0, 6)}\u2026${address.substring(address.length - 4)}';
  }
}
