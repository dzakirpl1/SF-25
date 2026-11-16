import 'unit/app_lock_test.dart' as app_lock_tests;
import 'unit/calendar_test.dart' as calendar_tests;
import 'unit/currency_utils_test.dart' as currency_tests;
import 'unit/date_utils_test.dart' as date_tests;
import 'unit/habit_streak_test.dart' as habit_streak_tests;
import 'unit/inbox_and_template_test.dart' as inbox_tests;
import 'unit/note_model_test.dart' as note_tests;
import 'unit/recurrence_engine_test.dart' as recurrence_tests;

void main() {
  currency_tests.main();
  date_tests.main();
  note_tests.main();
  app_lock_tests.main();
  recurrence_tests.main();
  inbox_tests.main();
  calendar_tests.main();
  habit_streak_tests.main();
}
