/// Static copy maps for the onboarding story, shared across steps.
library;

/// S9 goal options: (id, label).
const goalOptions = [
  ('daily_motivation', '🔥 stay motivated every day'),
  ('habits', '🌱 build habits that stick'),
  ('social_strength', '💪 stay strong in social situations'),
  ('reconnect_why', '❤️ reconnect with my why'),
  ('less_alone', '🤝 feel less alone on this path'),
];

/// S10 — what each picked goal promises back to the user.
const goalReflections = {
  'daily_motivation':
      'a fresh spark every morning — your feed and reminders will keep the '
          'fire lit.',
  'habits':
      'gentle streaks and small wins, so good days turn into a way of life.',
  'social_strength':
      'the right words for the hard moments — awkward dinner questions '
          'included.',
  'reconnect_why':
      'we\'ll keep your reason close, especially on the days it feels far.',
  'less_alone':
      'you\'re part of something bigger — we\'ll remind you of the good you do.',
};

/// S15 — first goal in plain words ("you want ...").
const goalPlainWords = {
  'daily_motivation': 'to stay motivated every day',
  'habits': 'to build habits that stick',
  'social_strength': 'to stay strong in social situations',
  'reconnect_why': 'to reconnect with your why',
  'less_alone': 'to feel less alone on this path',
};

/// S12 obstacle options: (id, label).
const obstacleOptions = [
  ('cravings', '🍕 cravings & convenience'),
  ('social_pressure', '🥂 social pressure'),
  ('fading_motivation', '😮‍💨 motivation fades over time'),
  ('alone', '🧍 nobody around me gets it'),
  ('busyness', '⏰ busy life, no headspace'),
];

/// S15 — first obstacle in plain words ("but ... keeps getting in the way").
const obstaclePlainWords = {
  'cravings': 'cravings & convenience',
  'social_pressure': 'social pressure',
  'fading_motivation': 'fading motivation',
  'alone': 'feeling alone in it',
  'busyness': 'a busy life',
};
