/// Публичный адрес веб-версии приложения (GitHub Pages) — передаётся
/// в Supabase как redirectTo при восстановлении пароля: именно сюда
/// пользователя вернёт ссылка из письма. Этот же адрес должен быть
/// добавлен в Supabase Dashboard -> Authentication -> URL Configuration
/// -> Redirect URLs, иначе Supabase отклонит redirectTo и откатится
/// на Site URL по умолчанию.
const String kAppWebUrl = 'https://savvivs-droid.github.io/Project-service/';
