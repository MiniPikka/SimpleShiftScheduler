/// 班组数据模型 — 对应 Android 版 Team.kt
class Team {
  final int id;

  const Team(this.id);

  static const totalTeams = 6;
  static final List<Team> allTeams =
      List.generate(totalTeams, (i) => Team(i + 1));
}
