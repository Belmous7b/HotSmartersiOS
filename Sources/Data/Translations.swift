import Foundation

/// Translations for the app's user-facing strings, keyed by the ENGLISH source
/// string. Each entry maps language code -> translation. Anything not listed here
/// falls back to the English text. Ported verbatim from the Android `Translations`.
enum Translations {
    // Order: en (key), then fr, ar, es, de, it, pt, tr, ru, hi, zh, ja, nl, pl.
    private static func e(_ en: String, _ fr: String, _ ar: String, _ es: String, _ de: String,
                          _ it: String, _ pt: String, _ tr: String, _ ru: String, _ hi: String,
                          _ zh: String, _ ja: String, _ nl: String, _ pl: String) -> (String, [String: String]) {
        (en, ["fr": fr, "ar": ar, "es": es, "de": de, "it": it, "pt": pt,
              "tr": tr, "ru": ru, "hi": hi, "zh": zh, "ja": ja, "nl": nl, "pl": pl])
    }

    static let map: [String: [String: String]] = Dictionary([
        // ---- Common / navigation / buttons ----
        e("Settings", "Paramètres", "الإعدادات", "Ajustes", "Einstellungen", "Impostazioni", "Definições", "Ayarlar", "Настройки", "सेटिंग्स", "设置", "設定", "Instellingen", "Ustawienia"),
        e("Support", "Assistance", "الدعم", "Soporte", "Support", "Supporto", "Suporte", "Destek", "Поддержка", "सहायता", "支持", "サポート", "Ondersteuning", "Wsparcie"),
        e("Alerts", "Alertes", "التنبيهات", "Alertas", "Benachrichtigungen", "Avvisi", "Alertas", "Uyarılar", "Уведомления", "सूचनाएँ", "提醒", "通知", "Meldingen", "Alerty"),
        e("Refresh", "Actualiser", "تحديث", "Actualizar", "Aktualisieren", "Aggiorna", "Atualizar", "Yenile", "Обновить", "रिफ्रेश", "刷新", "更新", "Vernieuwen", "Odśwież"),
        e("Search", "Rechercher", "بحث", "Buscar", "Suchen", "Cerca", "Pesquisar", "Ara", "Поиск", "खोज", "搜索", "検索", "Zoeken", "Szukaj"),
        e("Back", "Retour", "رجوع", "Atrás", "Zurück", "Indietro", "Voltar", "Geri", "Назад", "वापस", "返回", "戻る", "Terug", "Wstecz"),
        e("Close", "Fermer", "إغلاق", "Cerrar", "Schließen", "Chiudi", "Fechar", "Kapat", "Закрыть", "बंद करें", "关闭", "閉じる", "Sluiten", "Zamknij"),
        e("Cancel", "Annuler", "إلغاء", "Cancelar", "Abbrechen", "Annulla", "Cancelar", "İptal", "Отмена", "रद्द करें", "取消", "キャンセル", "Annuleren", "Anuluj"),
        e("Save", "Enregistrer", "حفظ", "Guardar", "Speichern", "Salva", "Guardar", "Kaydet", "Сохранить", "सहेजें", "保存", "保存", "Opslaan", "Zapisz"),
        e("Delete", "Supprimer", "حذف", "Eliminar", "Löschen", "Elimina", "Eliminar", "Sil", "Удалить", "हटाएँ", "删除", "削除", "Verwijderen", "Usuń"),
        e("Remove", "Retirer", "إزالة", "Quitar", "Entfernen", "Rimuovi", "Remover", "Kaldır", "Убрать", "निकालें", "移除", "削除", "Verwijderen", "Usuń"),
        e("Edit", "Modifier", "تعديل", "Editar", "Bearbeiten", "Modifica", "Editar", "Düzenle", "Изменить", "संपादित करें", "编辑", "編集", "Bewerken", "Edytuj"),
        e("Play", "Lire", "تشغيل", "Reproducir", "Abspielen", "Riproduci", "Reproduzir", "Oynat", "Смотреть", "चलाएँ", "播放", "再生", "Afspelen", "Odtwórz"),
        e("Connect", "Connecter", "اتصال", "Conectar", "Verbinden", "Connetti", "Ligar", "Bağlan", "Подключить", "कनेक्ट", "连接", "接続", "Verbinden", "Połącz"),
        e("Add playlist", "Ajouter une playlist", "إضافة قائمة", "Añadir lista", "Playlist hinzufügen", "Aggiungi playlist", "Adicionar lista", "Liste ekle", "Добавить плейлист", "प्लेलिस्ट जोड़ें", "添加播放列表", "プレイリスト追加", "Afspeellijst toevoegen", "Dodaj playlistę"),
        e("ADD Playlist", "Ajouter une playlist", "إضافة قائمة", "Añadir lista", "Playlist hinzufügen", "Aggiungi playlist", "Adicionar lista", "Liste ekle", "Добавить плейлист", "प्लेलिस्ट जोड़ें", "添加播放列表", "プレイリスト追加", "Afspeellijst toevoegen", "Dodaj playlistę"),
        e("Live TV", "TV en direct", "البث المباشر", "TV en vivo", "Live-TV", "TV in diretta", "TV ao vivo", "Canlı TV", "Эфир", "लाइव टीवी", "直播电视", "ライブTV", "Live-tv", "Telewizja na żywo"),
        e("Live", "Direct", "مباشر", "En vivo", "Live", "Diretta", "Ao vivo", "Canlı", "Эфир", "लाइव", "直播", "ライブ", "Live", "Na żywo"),
        e("Movies", "Films", "أفلام", "Películas", "Filme", "Film", "Filmes", "Filmler", "Фильмы", "फ़िल्में", "电影", "映画", "Films", "Filmy"),
        e("Series", "Séries", "مسلسلات", "Series", "Serien", "Serie", "Séries", "Diziler", "Сериалы", "सीरीज़", "剧集", "シリーズ", "Series", "Seriale"),
        e("Favorites", "Favoris", "المفضلة", "Favoritos", "Favoriten", "Preferiti", "Favoritos", "Favoriler", "Избранное", "पसंदीदा", "收藏", "お気に入り", "Favorieten", "Ulubione"),
        e("Folders", "Dossiers", "المجلدات", "Carpetas", "Ordner", "Cartelle", "Pastas", "Klasörler", "Папки", "फ़ोल्डर", "文件夹", "フォルダ", "Mappen", "Foldery"),
        e("Home", "Accueil", "الرئيسية", "Inicio", "Start", "Home", "Início", "Ana sayfa", "Главная", "होम", "主页", "ホーム", "Home", "Główna"),
        e("Playlist", "Playlist", "القائمة", "Lista", "Playlist", "Playlist", "Lista", "Liste", "Плейлист", "प्लेलिस्ट", "播放列表", "プレイリスト", "Afspeellijst", "Playlista"),
        e("Switch", "Changer", "تبديل", "Cambiar", "Wechseln", "Cambia", "Mudar", "Değiştir", "Сменить", "बदलें", "切换", "切替", "Wisselen", "Zmień"),
        e("Account", "Compte", "الحساب", "Cuenta", "Konto", "Account", "Conta", "Hesap", "Аккаунт", "खाता", "账户", "アカウント", "Account", "Konto"),
        e("Exit", "Quitter", "خروج", "Salir", "Beenden", "Esci", "Sair", "Çıkış", "Выйти", "बाहर निकलें", "退出", "終了", "Afsluiten", "Wyjdź"),
        e("Stay", "Rester", "البقاء", "Quedarse", "Bleiben", "Resta", "Ficar", "Kal", "Остаться", "रुकें", "留下", "残る", "Blijven", "Zostań"),
        e("Exit app?", "Quitter l'application ?", "إغلاق التطبيق؟", "¿Salir de la app?", "App beenden?", "Uscire dall'app?", "Sair da aplicação?", "Uygulamadan çıkılsın mı?", "Закрыть приложение?", "ऐप बंद करें?", "退出应用？", "アプリを終了しますか？", "App afsluiten?", "Zamknąć aplikację?"),
        e("OK", "OK", "موافق", "OK", "OK", "OK", "OK", "Tamam", "OK", "ठीक है", "确定", "OK", "OK", "OK"),

        // ---- Playlists screen ----
        e("Expires", "Expire", "ينتهي", "Caduca", "Läuft ab", "Scade", "Expira", "Bitiş", "Истекает", "समाप्ति", "到期", "有効期限", "Verloopt", "Wygasa"),
        e("Never", "Jamais", "أبدًا", "Nunca", "Nie", "Mai", "Nunca", "Asla", "Никогда", "कभी नहीं", "永不", "なし", "Nooit", "Nigdy"),
        e("Protected", "Protégé", "محمي", "Protegido", "Geschützt", "Protetto", "Protegido", "Korumalı", "Защищено", "सुरक्षित", "受保护", "保護済み", "Beveiligd", "Chroniony"),
        e("Connecting to", "Connexion à", "جارٍ الاتصال بـ", "Conectando a", "Verbinde mit", "Connessione a", "A ligar a", "Bağlanılıyor", "Подключение к", "कनेक्ट हो रहा है", "正在连接", "接続中", "Verbinden met", "Łączenie z"),
        e("Delete playlist?", "Supprimer la playlist ?", "حذف القائمة؟", "¿Eliminar la lista?", "Playlist löschen?", "Eliminare la playlist?", "Eliminar a lista?", "Liste silinsin mi?", "Удалить плейлист?", "प्लेलिस्ट हटाएँ?", "删除播放列表？", "プレイリストを削除しますか？", "Afspeellijst verwijderen?", "Usunąć playlistę?"),
        e("You can add it again later.", "Vous pourrez l'ajouter de nouveau plus tard.", "يمكنك إضافتها مرة أخرى لاحقًا.", "Puedes volver a añadirla más tarde.", "Du kannst sie später wieder hinzufügen.", "Puoi aggiungerla di nuovo più tardi.", "Pode adicioná-la novamente mais tarde.", "Daha sonra tekrar ekleyebilirsiniz.", "Вы сможете добавить её позже.", "आप इसे बाद में फिर से जोड़ सकते हैं.", "您之后可以重新添加。", "後でもう一度追加できます。", "Je kunt hem later opnieuw toevoegen.", "Możesz dodać ją ponownie później."),
        e("Playlist not working", "Playlist ne fonctionne pas", "القائمة لا تعمل", "La lista no funciona", "Playlist funktioniert nicht", "Playlist non funzionante", "A lista não funciona", "Liste çalışmıyor", "Плейлист не работает", "प्लेलिस्ट काम नहीं कर रही", "播放列表无法使用", "プレイリストが動作しません", "Afspeellijst werkt niet", "Playlista nie działa"),
        e("Contact support", "Contacter l'assistance", "اتصل بالدعم", "Contactar soporte", "Support kontaktieren", "Contatta il supporto", "Contactar o suporte", "Desteğe başvur", "Связаться с поддержкой", "सहायता से संपर्क करें", "联系支持", "サポートに連絡", "Contact met ondersteuning", "Skontaktuj się z pomocą"),
        e("Notifications", "Notifications", "الإشعارات", "Notificaciones", "Benachrichtigungen", "Notifiche", "Notificações", "Bildirimler", "Уведомления", "सूचनाएँ", "通知", "通知", "Meldingen", "Powiadomienia"),
        e("No notifications yet.", "Aucune notification pour le moment.", "لا توجد إشعارات بعد.", "Aún no hay notificaciones.", "Noch keine Benachrichtigungen.", "Ancora nessuna notifica.", "Ainda não há notificações.", "Henüz bildirim yok.", "Пока нет уведомлений.", "अभी कोई सूचना नहीं।", "暂无通知。", "まだ通知はありません。", "Nog geen meldingen.", "Brak powiadomień."),

        // ---- Subscription / trial ----
        e("Free Trial", "Essai gratuit", "نسخة تجريبية مجانية", "Prueba gratuita", "Kostenlose Testversion", "Prova gratuita", "Teste gratuito", "Ücretsiz deneme", "Бесплатный период", "नि:शुल्क परीक्षण", "免费试用", "無料トライアル", "Gratis proefperiode", "Bezpłatny okres próbny"),
        e("Lifetime", "À vie", "مدى الحياة", "De por vida", "Lebenslang", "A vita", "Vitalício", "Ömür boyu", "Навсегда", "आजीवन", "终身", "永久", "Levenslang", "Dożywotnio"),
        e("Never expires", "N'expire jamais", "لا ينتهي أبدًا", "Nunca caduca", "Läuft nie ab", "Non scade mai", "Nunca expira", "Hiç bitmez", "Никогда не истекает", "कभी समाप्त नहीं", "永不过期", "無期限", "Verloopt nooit", "Nigdy nie wygasa"),
        e("6 Months", "6 mois", "6 أشهر", "6 meses", "6 Monate", "6 mesi", "6 meses", "6 ay", "6 месяцев", "6 महीने", "6 个月", "6か月", "6 maanden", "6 miesięcy"),
        e("1 Year", "1 an", "سنة واحدة", "1 año", "1 Jahr", "1 anno", "1 ano", "1 yıl", "1 год", "1 वर्ष", "1 年", "1年", "1 jaar", "1 rok"),
        e("Expired", "Expiré", "منتهٍ", "Caducado", "Abgelaufen", "Scaduto", "Expirado", "Süresi doldu", "Истёк", "समाप्त", "已过期", "期限切れ", "Verlopen", "Wygasł"),

        // ---- Welcome screen ----
        e("Welcome to Hot Smarters", "Bienvenue sur Hot Smarters", "مرحبًا بك في Hot Smarters", "Bienvenido a Hot Smarters", "Willkommen bei Hot Smarters", "Benvenuto in Hot Smarters", "Bem-vindo ao Hot Smarters", "Hot Smarters'a hoş geldiniz", "Добро пожаловать в Hot Smarters", "Hot Smarters में आपका स्वागत है", "欢迎使用 Hot Smarters", "Hot Smarters へようこそ", "Welkom bij Hot Smarters", "Witamy w Hot Smarters"),
        e("Upload your playlist from our website", "Importez votre playlist depuis notre site", "ارفع قائمتك من موقعنا", "Sube tu lista desde nuestro sitio web", "Lade deine Playlist über unsere Website hoch", "Carica la tua playlist dal nostro sito", "Carregue a sua lista a partir do nosso site", "Oynatma listenizi web sitemizden yükleyin", "Загрузите плейлист с нашего сайта", "हमारी वेबसाइट से अपनी प्लेलिस्ट अपलोड करें", "从我们的网站上传您的播放列表", "ウェブサイトからプレイリストをアップロード", "Upload je afspeellijst via onze website", "Prześlij playlistę z naszej strony"),
        e("Or upload inside the app", "Ou importez dans l'application", "أو ارفع داخل التطبيق", "O sube dentro de la app", "Oder in der App hochladen", "Oppure carica nell'app", "Ou carregue dentro da aplicação", "Veya uygulama içinde yükleyin", "Или загрузите в приложении", "या ऐप में अपलोड करें", "或在应用内上传", "またはアプリ内でアップロード", "Of upload in de app", "Lub prześlij w aplikacji"),
        e("I've uploaded — load my playlist", "J'ai importé — charger ma playlist", "لقد رفعت — حمّل قائمتي", "Ya lo subí: cargar mi lista", "Hochgeladen – meine Playlist laden", "Ho caricato — carica la mia playlist", "Já carreguei — carregar a minha lista", "Yükledim — listemi getir", "Я загрузил — открыть плейлист", "मैंने अपलोड किया — मेरी प्लेलिस्ट लोड करें", "我已上传 — 加载我的播放列表", "アップロード済み — プレイリストを読み込む", "Geüpload — laad mijn afspeellijst", "Przesłałem — wczytaj playlistę"),

        // ---- Live / VOD ----
        e("Program Guide", "Guide des programmes", "دليل البرامج", "Guía de programas", "Programmführer", "Guida ai programmi", "Guia de programas", "Program rehberi", "Телепрограмма", "प्रोग्राम गाइड", "节目指南", "番組表", "Programmagids", "Przewodnik programowy"),
        e("UP NEXT", "À SUIVRE", "التالي", "A CONTINUACIÓN", "ALS NÄCHSTES", "IN ONDA DOPO", "A SEGUIR", "SIRADAKİ", "ДАЛЕЕ", "आगे", "即将播出", "次の番組", "HIERNA", "NASTĘPNIE"),
        e("No live channels in this playlist.", "Aucune chaîne en direct dans cette playlist.", "لا توجد قنوات مباشرة في هذه القائمة.", "No hay canales en vivo en esta lista.", "Keine Live-Sender in dieser Playlist.", "Nessun canale in diretta in questa playlist.", "Sem canais ao vivo nesta lista.", "Bu listede canlı kanal yok.", "В этом плейлисте нет каналов.", "इस प्लेलिस्ट में कोई लाइव चैनल नहीं।", "此播放列表中没有直播频道。", "このプレイリストにライブチャンネルがありません。", "Geen live-kanalen in deze afspeellijst.", "Brak kanałów na żywo na tej liście."),
        e("All", "Tout", "الكل", "Todo", "Alle", "Tutti", "Tudo", "Tümü", "Все", "सभी", "全部", "すべて", "Alle", "Wszystko"),
        e("Nothing here.", "Rien ici.", "لا يوجد شيء هنا.", "No hay nada aquí.", "Nichts vorhanden.", "Niente qui.", "Nada aqui.", "Burada bir şey yok.", "Здесь пусто.", "यहाँ कुछ नहीं।", "这里没有内容。", "ここには何もありません。", "Niets hier.", "Nic tu nie ma."),
        e("Results", "Résultats", "النتائج", "Resultados", "Ergebnisse", "Risultati", "Resultados", "Sonuçlar", "Результаты", "परिणाम", "搜索结果", "検索結果", "Resultaten", "Wyniki"),
        e("Search movies", "Rechercher des films", "ابحث عن أفلام", "Buscar películas", "Filme suchen", "Cerca film", "Pesquisar filmes", "Film ara", "Поиск фильмов", "फ़िल्में खोजें", "搜索电影", "映画を検索", "Films zoeken", "Szukaj filmów"),
        e("Search series", "Rechercher des séries", "ابحث عن مسلسلات", "Buscar series", "Serien suchen", "Cerca serie", "Pesquisar séries", "Dizi ara", "Поиск сериалов", "सीरीज़ खोजें", "搜索剧集", "シリーズを検索", "Series zoeken", "Szukaj seriali"),
        e("Catch-up", "Rattrapage", "مشاهدة لاحقة", "En diferido", "Mediathek", "Replay", "Em diferido", "Geri izleme", "Архив", "कैच-अप", "回看", "見逃し", "Terugkijken", "Powtórki"),
        e("Loading…", "Chargement…", "جارٍ التحميل…", "Cargando…", "Lädt…", "Caricamento…", "A carregar…", "Yükleniyor…", "Загрузка…", "लोड हो रहा है…", "加载中…", "読み込み中…", "Laden…", "Ładowanie…"),

        // ---- Dashboard ----
        e("Latest added", "Ajouts récents", "أحدث الإضافات", "Añadido recientemente", "Zuletzt hinzugefügt", "Aggiunti di recente", "Adicionados recentemente", "Son eklenenler", "Недавно добавленные", "हाल में जोड़े गए", "最近添加", "最近追加", "Recent toegevoegd", "Ostatnio dodane"),
        e("Continue Watching", "Reprendre", "متابعة المشاهدة", "Continuar viendo", "Weiterschauen", "Continua a guardare", "Continuar a ver", "İzlemeye devam et", "Продолжить просмотр", "देखना जारी रखें", "继续观看", "続きを見る", "Verder kijken", "Kontynuuj oglądanie"),
        e("Connect a playlist to see movies.", "Connectez une playlist pour voir des films.", "اتصل بقائمة لعرض الأفلام.", "Conecta una lista para ver películas.", "Verbinde eine Playlist, um Filme zu sehen.", "Connetti una playlist per vedere i film.", "Ligue uma lista para ver filmes.", "Film görmek için bir liste bağlayın.", "Подключите плейлист, чтобы увидеть фильмы.", "फ़िल्में देखने के लिए प्लेलिस्ट कनेक्ट करें.", "连接播放列表以查看电影。", "映画を見るにはプレイリストを接続してください。", "Verbind een afspeellijst om films te zien.", "Połącz playlistę, aby zobaczyć filmy."),

        // ---- Settings ----
        e("Playback", "Lecture", "التشغيل", "Reproducción", "Wiedergabe", "Riproduzione", "Reprodução", "Oynatma", "Воспроизведение", "प्लेबैक", "播放", "再生", "Afspelen", "Odtwarzanie"),
        e("App", "Application", "التطبيق", "Aplicación", "App", "App", "Aplicação", "Uygulama", "Приложение", "ऐप", "应用", "アプリ", "App", "Aplikacja"),
        e("Auto-play next episode", "Lire l'épisode suivant automatiquement", "تشغيل الحلقة التالية تلقائيًا", "Reproducir el siguiente episodio automáticamente", "Nächste Folge automatisch abspielen", "Riproduci automaticamente l'episodio successivo", "Reproduzir o próximo episódio automaticamente", "Sonraki bölümü otomatik oynat", "Автовоспроизведение следующей серии", "अगला एपिसोड स्वतः चलाएँ", "自动播放下一集", "次のエピソードを自動再生", "Volgende aflevering automatisch afspelen", "Automatycznie odtwarzaj następny odcinek"),
        e("Start the next episode automatically", "Démarre l'épisode suivant automatiquement", "يبدأ الحلقة التالية تلقائيًا", "Inicia el siguiente episodio automáticamente", "Startet die nächste Folge automatisch", "Avvia automaticamente l'episodio successivo", "Inicia o próximo episódio automaticamente", "Sonraki bölümü otomatik başlatır", "Автоматически запускает следующую серию", "अगला एपिसोड अपने आप शुरू करता है", "自动开始下一集", "次のエピソードを自動的に開始", "Start automatisch de volgende aflevering", "Automatycznie uruchamia następny odcinek"),
        e("Audio language", "Langue audio", "لغة الصوت", "Idioma de audio", "Audiosprache", "Lingua audio", "Idioma do áudio", "Ses dili", "Язык звука", "ऑडियो भाषा", "音频语言", "音声言語", "Audiotaal", "Język dźwięku"),
        e("Subtitle language", "Langue des sous-titres", "لغة الترجمة", "Idioma de subtítulos", "Untertitelsprache", "Lingua dei sottotitoli", "Idioma das legendas", "Altyazı dili", "Язык субтитров", "उपशीर्षक भाषा", "字幕语言", "字幕言語", "Ondertiteltaal", "Język napisów"),
        e("Video fit", "Ajustement vidéo", "ملاءمة الفيديو", "Ajuste de vídeo", "Videoanpassung", "Adattamento video", "Ajuste de vídeo", "Video uyumu", "Формат видео", "वीडियो फ़िट", "视频比例", "映像の表示", "Videoweergave", "Dopasowanie wideo"),
        e("Start screen", "Écran de démarrage", "شاشة البدء", "Pantalla de inicio", "Startbildschirm", "Schermata iniziale", "Ecrã inicial", "Başlangıç ekranı", "Начальный экран", "प्रारंभ स्क्रीन", "启动界面", "起動画面", "Startscherm", "Ekran startowy"),
        e("App language", "Langue de l'application", "لغة التطبيق", "Idioma de la app", "App-Sprache", "Lingua dell'app", "Idioma da aplicação", "Uygulama dili", "Язык приложения", "ऐप भाषा", "应用语言", "アプリの言語", "App-taal", "Język aplikacji"),
        e("Parental code", "Code parental", "رمز الرقابة الأبوية", "Código parental", "Jugendschutzcode", "Codice parentale", "Código parental", "Ebeveyn kodu", "Родительский код", "पैरेंटल कोड", "家长密码", "ペアレンタルコード", "Ouderlijke code", "Kod rodzicielski"),
        e("Clear cache & refresh", "Vider le cache et actualiser", "مسح التخزين المؤقت والتحديث", "Borrar caché y actualizar", "Cache leeren & aktualisieren", "Svuota cache e aggiorna", "Limpar cache e atualizar", "Önbelleği temizle ve yenile", "Очистить кэш и обновить", "कैश साफ़ करें और रिफ्रेश करें", "清除缓存并刷新", "キャッシュを消去して更新", "Cache wissen & vernieuwen", "Wyczyść pamięć i odśwież"),
        e("Reload channels, movies and series", "Recharger chaînes, films et séries", "إعادة تحميل القنوات والأفلام والمسلسلات", "Recargar canales, películas y series", "Sender, Filme und Serien neu laden", "Ricarica canali, film e serie", "Recarregar canais, filmes e séries", "Kanalları, filmleri ve dizileri yeniden yükle", "Перезагрузить каналы, фильмы и сериалы", "चैनल, फ़िल्में और सीरीज़ फिर से लोड करें", "重新加载频道、电影和剧集", "チャンネル・映画・シリーズを再読み込み", "Kanalen, films en series herladen", "Przeładuj kanały, filmy i seriale"),
        e("Test internet speed", "Tester la vitesse Internet", "اختبار سرعة الإنترنت", "Probar velocidad de Internet", "Internetgeschwindigkeit testen", "Verifica velocità Internet", "Testar velocidade da Internet", "İnternet hızını test et", "Проверить скорость интернета", "इंटरनेट स्पीड जांचें", "测试网速", "インターネット速度を測定", "Internetsnelheid testen", "Testuj szybkość Internetu"),
        e("Check for updates", "Rechercher des mises à jour", "التحقق من التحديثات", "Buscar actualizaciones", "Nach Updates suchen", "Controlla aggiornamenti", "Procurar atualizações", "Güncellemeleri denetle", "Проверить обновления", "अपडेट जांचें", "检查更新", "更新を確認", "Controleren op updates", "Sprawdź aktualizacje"),
        e("Open the website for the latest version", "Ouvrir le site pour la dernière version", "افتح الموقع للحصول على أحدث إصدار", "Abre el sitio web para la última versión", "Website für die neueste Version öffnen", "Apri il sito per l'ultima versione", "Abrir o site para a versão mais recente", "En son sürüm için web sitesini aç", "Открыть сайт для последней версии", "नवीनतम संस्करण के लिए वेबसाइट खोलें", "打开网站获取最新版本", "最新版はウェブサイトで確認", "Open de website voor de nieuwste versie", "Otwórz stronę po najnowszą wersję"),
        e("Account & activation", "Compte et activation", "الحساب والتفعيل", "Cuenta y activación", "Konto & Aktivierung", "Account e attivazione", "Conta e ativação", "Hesap ve etkinleştirme", "Аккаунт и активация", "खाता और सक्रियण", "账户与激活", "アカウントと認証", "Account & activering", "Konto i aktywacja"),
        e("Subscription", "Abonnement", "الاشتراك", "Suscripción", "Abonnement", "Abbonamento", "Subscrição", "Abonelik", "Подписка", "सदस्यता", "订阅", "サブスクリプション", "Abonnement", "Subskrypcja"),
        e("About", "À propos", "حول", "Acerca de", "Über", "Informazioni", "Acerca de", "Hakkında", "О приложении", "परिचय", "关于", "アプリについて", "Over", "O aplikacji"),
        e("Version", "Version", "الإصدار", "Versión", "Version", "Versione", "Versão", "Sürüm", "Версия", "संस्करण", "版本", "バージョン", "Versie", "Wersja"),
        e("Website", "Site web", "الموقع الإلكتروني", "Sitio web", "Website", "Sito web", "Site", "Web sitesi", "Сайт", "वेबसाइट", "网站", "ウェブサイト", "Website", "Strona"),
        e("Library", "Bibliothèque", "المكتبة", "Biblioteca", "Mediathek", "Libreria", "Biblioteca", "Kütüphane", "Библиотека", "लाइब्रेरी", "媒体库", "ライブラリ", "Bibliotheek", "Biblioteka"),
        e("Disconnect", "Déconnecter", "قطع الاتصال", "Desconectar", "Trennen", "Disconnetti", "Desligar", "Bağlantıyı kes", "Отключить", "डिस्कनेक्ट", "断开连接", "切断", "Verbinding verbreken", "Rozłącz"),
        e("Not set", "Non défini", "غير محدد", "No establecido", "Nicht festgelegt", "Non impostato", "Não definido", "Ayarlanmadı", "Не задан", "सेट नहीं", "未设置", "未設定", "Niet ingesteld", "Nie ustawiono"),
        e("Enabled", "Activé", "مُفعّل", "Activado", "Aktiviert", "Attivato", "Ativado", "Etkin", "Включено", "सक्षम", "已启用", "有効", "Ingeschakeld", "Włączony"),
        e("Not tested", "Non testé", "لم يُختبر", "Sin probar", "Nicht getestet", "Non testato", "Não testado", "Test edilmedi", "Не проверено", "परीक्षण नहीं", "未测试", "未測定", "Niet getest", "Nie testowano"),
        e("Testing…", "Test en cours…", "جارٍ الاختبار…", "Probando…", "Teste…", "Verifica…", "A testar…", "Test ediliyor…", "Проверка…", "परीक्षण हो रहा है…", "测试中…", "測定中…", "Testen…", "Testowanie…"),
        e("Set parental code", "Définir le code parental", "تعيين رمز الرقابة", "Establecer código parental", "Jugendschutzcode festlegen", "Imposta codice parentale", "Definir código parental", "Ebeveyn kodu ayarla", "Задать родительский код", "पैरेंटल कोड सेट करें", "设置家长密码", "ペアレンタルコードを設定", "Ouderlijke code instellen", "Ustaw kod rodzicielski"),
        e("Change parental code", "Modifier le code parental", "تغيير رمز الرقابة", "Cambiar código parental", "Jugendschutzcode ändern", "Cambia codice parentale", "Alterar código parental", "Ebeveyn kodunu değiştir", "Изменить родительский код", "पैरेंटल कोड बदलें", "更改家长密码", "ペアレンタルコードを変更", "Ouderlijke code wijzigen", "Zmień kod rodzicielski"),
        e("4-digit code", "Code à 4 chiffres", "رمز من 4 أرقام", "Código de 4 dígitos", "4-stelliger Code", "Codice a 4 cifre", "Código de 4 dígitos", "4 haneli kod", "4-значный код", "4-अंकों का कोड", "4 位密码", "4桁のコード", "Code van 4 cijfers", "Kod 4-cyfrowy"),

        // ---- Watch Later (extra app strings) ----
        e("Watch Later", "À regarder plus tard", "المشاهدة لاحقًا", "Ver más tarde", "Später ansehen", "Guarda più tardi", "Ver mais tarde", "Daha sonra izle", "Посмотреть позже", "बाद में देखें", "稍后观看", "あとで見る", "Later kijken", "Do obejrzenia"),
        e("Nothing saved yet.", "Rien d'enregistré pour le moment.", "لم يتم الحفظ بعد.", "Nada guardado aún.", "Noch nichts gespeichert.", "Ancora niente salvato.", "Ainda nada guardado.", "Henüz kaydedilmedi.", "Пока ничего не сохранено.", "अभी कुछ सहेजा नहीं गया।", "尚未保存任何内容。", "まだ保存されていません。", "Nog niets opgeslagen.", "Nic jeszcze nie zapisano."),
        e("Open any movie or series and tap Watch Later to save it here.", "Ouvrez un film ou une série et appuyez sur À regarder plus tard pour l'enregistrer ici.", "افتح أي فيلم أو مسلسل واضغط على المشاهدة لاحقًا لحفظه هنا.", "Abre cualquier película o serie y toca Ver más tarde para guardarla aquí.", "Öffne einen Film oder eine Serie und tippe auf Später ansehen, um ihn hier zu speichern.", "Apri un film o una serie e tocca Guarda più tardi per salvarlo qui.", "Abra um filme ou série e toque em Ver mais tarde para guardá-lo aqui.", "Bir film veya dizi açın ve buraya kaydetmek için Daha sonra izle'ye dokunun.", "Откройте фильм или сериал и нажмите Посмотреть позже, чтобы сохранить его здесь.", "कोई फ़िल्म या सीरीज़ खोलें और उसे यहाँ सहेजने के लिए बाद में देखें पर टैप करें।", "打开任意电影或剧集，点按“稍后观看”即可保存到这里。", "映画やシリーズを開き、「あとで見る」をタップするとここに保存されます。", "Open een film of serie en tik op Later kijken om deze hier op te slaan.", "Otwórz dowolny film lub serial i dotknij Do obejrzenia, aby go tu zapisać."),
        e("Movie", "Film", "فيلم", "Película", "Film", "Film", "Filme", "Film", "Фильм", "फ़िल्म", "电影", "映画", "Film", "Film"),
    ], uniquingKeysWith: { a, _ in a })
}
