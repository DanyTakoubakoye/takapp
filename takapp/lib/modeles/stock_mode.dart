enum StockMode {
  disabled('disabled'),
  warningOnly('warningOnly'),
  strict('strict');

  const StockMode(this.value);

  final String value;

  static StockMode fromValue(Object? value) {
    return StockMode.values.firstWhere(
      (mode) => mode.value == value,
      orElse: () => StockMode.strict,
    );
  }
}
