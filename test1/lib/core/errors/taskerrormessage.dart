String getTaskErrorMessage(dynamic error) {
  if (error is String) return error;

  final String errStr = error.toString();

  if (errStr.contains('SocketException') || errStr.contains('Failed host lookup')) {
    return 'Network failure. Please check your internet connection.';
  }
  if (errStr.contains('404') || errStr.contains('Task not found')) {
    return 'Task was not found. It may have been deleted.';
  }
  if (errStr.contains('422') || errStr.contains('Validation error')) {
    return 'Validation error: Please check your task fields.';
  }
  if (errStr.contains('500') || errStr.contains('Server error')) {
    return 'Server error. Please try again later.';
  }
  if (errStr.contains('permission-denied')) {
    return 'Permission denied. You do not have access to manage this task.';
  }

  return 'An unexpected error occurred: ${errStr.replaceAll('Exception:', '').trim()}';
}
