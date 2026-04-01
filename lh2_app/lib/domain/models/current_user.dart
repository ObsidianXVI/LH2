// CurrentUser — minimal user concept for workspace ownership (Task 6.1-1).
//
// No auth flows; auto-signs-in anonymously for local dev/emulator.
class CurrentUser {
  final String uid;

  const CurrentUser(this.uid);
}