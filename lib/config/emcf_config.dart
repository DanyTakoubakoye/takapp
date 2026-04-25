class EmcfConfig {
  // TEST
  static const String invoiceBaseUrlTest =
      'https://developper.impots.bj/sygmef-emcf/api/invoice';
  static const String infoBaseUrlTest =
      'https://developper.impots.bj/sygmef-emcf/api/info';

  // PRODUCTION
  static const String invoiceBaseUrlProd =
      'https://sygmef.impots.bj/emcf/api/invoice';
  static const String infoBaseUrlProd =
      'https://sygmef.impots.bj/emcf/api/info';

  // Mets false pour la production
  static const bool useTestServer = true;

  static String get invoiceBaseUrl =>
      useTestServer ? invoiceBaseUrlTest : invoiceBaseUrlProd;

  static String get infoBaseUrl =>
      useTestServer ? infoBaseUrlTest : infoBaseUrlProd;

  // A REMPLIR AVEC TON IFU VENDEUR
  static const String sellerIfu = '3202532349197';

  // A REMPLIR AVEC TON TOKEN JWT DGI
  static const String bearerToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1bmlxdWVfbmFtZSI6IjMyMDI1MzIzNDkxOTd8VFMwMTAxODM0NCIsInJvbGUiOiJUYXhwYXllciIsIm5iZiI6MTc3NjM2NDA4MSwiZXhwIjoxNzkyMTc1MjgxLCJpYXQiOjE3NzYzNjQwODEsImlzcyI6ImltcG90cy5iaiIsImF1ZCI6ImltcG90cy5iaiJ9.t5zQdB2ZpDVQOFZ5jDtLgAgqx1q8rKS_s8ZjOWyGuMM';
}
