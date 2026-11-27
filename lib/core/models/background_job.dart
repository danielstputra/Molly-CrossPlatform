class BackgroundJob {
  final String id;
  final String name;
  final String taskType;
  final String status; // 'running', 'completed', 'scheduled', 'failed'
  final String? schedule; // e.g. "0 */2 * * *"
  final String? lastRun;
  final String? nextRun;
  final double progress;

  const BackgroundJob({
    required this.id,
    required this.name,
    required this.taskType,
    required this.status,
    this.schedule,
    this.lastRun,
    this.nextRun,
    this.progress = 0.0,
  });

  factory BackgroundJob.fromJson(Map<String, dynamic> json) {
    return BackgroundJob(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Job Latar Belakang',
      taskType: json['task_type'] ?? 'agent_workflow',
      status: json['status'] ?? 'scheduled',
      schedule: json['schedule'],
      lastRun: json['last_run'],
      nextRun: json['next_run'],
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
