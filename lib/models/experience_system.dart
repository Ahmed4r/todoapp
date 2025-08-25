class ExperienceSystem {
  int currentXP;
  int level;
  int xpToNextLevel;

  ExperienceSystem({
    this.currentXP = 0,
    this.level = 1,
    this.xpToNextLevel = 100,
  });

  void addXP(int amount) {
    currentXP += amount;
    while (currentXP >= xpToNextLevel) {
      levelUp();
    }
  }

  void levelUp() {
    currentXP -= xpToNextLevel;
    level++;
    // Increase XP required for next level by 50%
    xpToNextLevel = (xpToNextLevel * 1.5).round();
  }

  double get levelProgress {
    return currentXP / xpToNextLevel;
  }

  // XP rewards for different actions
  static const int COMPLETE_POMODORO = 50;
  static const int COMPLETE_BREAK = 10;
  static const int COMPLETE_TASK = 100;
}
