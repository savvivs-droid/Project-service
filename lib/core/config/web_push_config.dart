/// Публичный VAPID-ключ для push-уведомлений веб-версии. Он не секретный
/// (браузер получает его в любом случае). Парный приватный ключ хранится
/// только в секретах Supabase Edge Functions (VAPID_PRIVATE_KEY) — см.
/// README, раздел "Push-уведомления в веб-версии".
const webPushVapidPublicKey =
    'BJOUE6tadjSqarHqRMcCQCL8CWgk4oEYHHjxrI7oZv55tybDlHh2q3Rv_6NIlKgd2WJ7XxOZmx1CRRdUzLQywnA';
