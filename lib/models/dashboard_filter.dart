class DashboardFilter {
  final DateTime startDate;
  final DateTime endDate;
  final String category;
  final String status;
  final int companyId;

  DashboardFilter({
    required this.startDate,
    required this.endDate,
    required this.category,
    required this.status,
    required this.companyId,
  });
}