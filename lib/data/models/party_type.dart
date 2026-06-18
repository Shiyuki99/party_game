enum PartyType {
  passAndPlay,
  lan;

  String get displayName {
    switch (this) {
      case PartyType.passAndPlay:
        return 'Pass & Play';
      case PartyType.lan:
        return 'LAN Party';
    }
  }

  String get description {
    switch (this) {
      case PartyType.passAndPlay:
        return 'All players share one device';
      case PartyType.lan:
        return 'Each player uses their own device';
    }
  }
}
