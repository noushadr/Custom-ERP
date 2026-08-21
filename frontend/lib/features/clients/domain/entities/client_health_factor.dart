/// Raw values matching the backend's ClientHealthFactor enum.
class ClientHealthFactor {
  static const payment = 'payment';
  static const performance = 'performance';
  static const delays = 'delays';
  static const complaints = 'complaints';
  static const communication = 'communication';
  static const renewal = 'renewal';

  static const values = [
    payment,
    performance,
    delays,
    complaints,
    communication,
    renewal,
  ];
}
