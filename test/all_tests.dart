import 'unit/app_lock_test.dart' as app_lock_tests;
import 'unit/calendar_test.dart' as calendar_tests;
import 'unit/currency_utils_test.dart' as currency_tests;
import 'unit/date_utils_test.dart' as date_tests;
import 'unit/habit_streak_test.dart' as habit_streak_tests;
import 'unit/inbox_and_template_test.dart' as inbox_tests;
import 'unit/note_model_test.dart' as note_tests;
import 'unit/recurrence_engine_test.dart' as recurrence_tests;
import 'unit/reminder_test.dart' as reminder_tests;
import 'unit/finance_core_test.dart' as finance_core_tests;
import 'unit/finance_advanced_test.dart' as finance_advanced_tests;
import 'unit/focus_time_test.dart' as focus_time_tests;
import 'unit/reflection_goals_test.dart' as reflection_goals_tests;
import 'unit/health_test.dart' as health_tests;

void main() {
  currency_tests.main();
  date_tests.main();
  note_tests.main();
  app_lock_tests.main();
  recurrence_tests.main();
  inbox_tests.main();
  calendar_tests.main();
  habit_streak_tests.main();
  reminder_tests.main();
  finance_core_tests.main();
  finance_advanced_tests.main();
  focus_time_tests.main();
  reflection_goals_tests.main();
  health_tests.main();
}
