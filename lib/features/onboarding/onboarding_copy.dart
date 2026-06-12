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

/// S23 commitment options: (id, label).
const commitmentOptions = [
  ('extreme', '🔥 extremely committed'),
  ('very', '💪 very committed'),
  ('somewhat', '🙂 somewhat committed'),
  ('little', '🌱 a little committed'),
  ('trying', '👀 just trying it out'),
];

/// S24 — response copy tailored to the commitment answer.
const commitmentResponses = {
  'extreme':
      "you're all-in — that's where change lives. let's turn that fire into a "
          'habit.',
  'very':
      'strong start. commitment like this is what carries people through the '
          'hard weeks.',
  'somewhat':
      "honest — and that's enough. small daily sparks will do the heavy "
          'lifting.',
  'little':
      "every big change starts a little unsure. we'll keep it light and easy "
          '— just show up.',
  'trying':
      'perfect — no pressure. try it for a few days and let the streak speak '
          'for itself.',
};

/// S25 — how full the commitment bar reads, per level (0–1).
const commitmentBarFill = {
  'extreme': 1.0,
  'very': 0.8,
  'somewhat': 0.6,
  'little': 0.4,
  'trying': 0.2,
};
