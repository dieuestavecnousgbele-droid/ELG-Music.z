#!/usr/bin/env bash
set -e

echo "=== ELG Music V1.06 (correctif coffre-fort + date d'enregistrement dans l'editeur de tags, base v1.5) : projet complet + workflow GitHub Actions ==="
echo "(a lancer depuis la racine du depot, dans un terminal Linux standard)"
echo ""

echo "[1/3] Creation des dossiers..."
mkdir -p .github/workflows
mkdir -p app
mkdir -p app/src/main
mkdir -p app/src/main/java/com/elg/music/data/local
mkdir -p app/src/main/java/com/elg/music/data/model
mkdir -p app/src/main/java/com/elg/music/data/repository
mkdir -p app/src/main/java/com/elg/music/playback
mkdir -p app/src/main/java/com/elg/music/ui/about
mkdir -p app/src/main/java/com/elg/music/ui/main
mkdir -p app/src/main/java/com/elg/music/ui/settings
mkdir -p app/src/main/res/drawable
mkdir -p app/src/main/res/layout
mkdir -p app/src/main/res/menu
mkdir -p app/src/main/res/mipmap-anydpi
mkdir -p app/src/main/res/values
mkdir -p app/src/main/res/xml

echo "[2/3] Ecriture des 129 fichiers..."
echo "  -> settings.gradle"
cat << 'EOF' > settings.gradle
include ':app'
rootProject.name = 'ELG Music'
EOF

echo "  -> build.gradle"
cat << 'EOF' > build.gradle
buildscript {
    ext.kotlin_version = '2.1.21'
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:8.11.1'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
        // KSP (traitement des annotations de Room) : version alignee sur Kotlin 2.1.21
        classpath 'com.google.devtools.ksp:symbol-processing-gradle-plugin:2.1.21-2.0.1'
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
EOF

echo "  -> gradle.properties"
cat << 'EOF' > gradle.properties
org.gradle.jvmargs=-Xmx3g -Dfile.encoding=UTF-8
android.useAndroidX=true
kotlin.code.style=official
EOF

echo "  -> app/build.gradle"
mkdir -p app
cat << 'EOF' > app/build.gradle
apply plugin: 'com.android.application'
apply plugin: 'kotlin-android'
apply plugin: 'com.google.devtools.ksp'

android {
    namespace 'com.elg.music'
    compileSdk 36

    // Signature fixe : le même fichier debug.keystore (généré par setup_elg_full.sh) signe toutes
    // les versions, debug comme release. Android accepte alors d'installer chaque nouvelle version
    // par-dessus la précédente, sans message d'incompatibilité de signature.
    signingConfigs {
        elgFixed {
            storeFile file('debug.keystore')
            storeType 'pkcs12'
            storePassword 'android'
            keyAlias 'androiddebugkey'
            keyPassword 'android'
        }
    }

    defaultConfig {
        applicationId 'com.elg.music'
        minSdk 33
        targetSdk 36
        versionCode 11
        versionName '1.06'

        testInstrumentationRunner 'androidx.test.runner.AndroidJUnitRunner'
    }

    buildTypes {
        debug {
            signingConfig signingConfigs.elgFixed
        }
        release {
            signingConfig signingConfigs.elgFixed
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = '17'
    }

    buildFeatures {
        viewBinding true
        buildConfig true
    }
}

dependencies {
    // --- AndroidX de base ---
    implementation 'androidx.core:core-ktx:1.18.0'
    implementation 'androidx.appcompat:appcompat:1.8.0'
    implementation 'androidx.fragment:fragment-ktx:1.9.0'
    implementation 'com.google.android.material:material:1.13.0'
    implementation 'androidx.constraintlayout:constraintlayout:2.2.2'
    implementation 'androidx.lifecycle:lifecycle-runtime-ktx:2.9.2'
    implementation 'androidx.lifecycle:lifecycle-viewmodel-ktx:2.9.2'

    // --- Bibliothèque musicale : liste + réglages ---
    implementation 'androidx.recyclerview:recyclerview:1.4.0'
    implementation 'androidx.preference:preference-ktx:1.2.1'

    // --- Coroutines ---
    implementation 'org.jetbrains.kotlinx:kotlinx-coroutines-android:1.11.0'

    // --- Media3 / ExoPlayer : moteur de lecture audio ---
    implementation 'androidx.media3:media3-exoplayer:1.11.0'
    implementation 'androidx.media3:media3-session:1.11.0'
    implementation 'androidx.media3:media3-common:1.11.0'

    // --- Persistance v1.4 : DataStore (réglages) + Room (base locale, via KSP) ---
    implementation 'androidx.datastore:datastore-preferences:1.1.7'
    implementation 'androidx.room:room-runtime:2.7.2'
    implementation 'androidx.room:room-ktx:2.7.2'
    ksp 'androidx.room:room-compiler:2.7.2'

    // --- Firebase : ajouté dès que google-services.json est fourni ---

    // --- Tests ---
    testImplementation 'junit:junit:4.13.2'
    androidTestImplementation 'androidx.test.ext:junit:1.3.0'
    androidTestImplementation 'androidx.test.espresso:espresso-core:3.7.0'
}
EOF

echo "  -> app/proguard-rules.pro"
mkdir -p app
cat << 'EOF' > app/proguard-rules.pro
# Règles ProGuard/R8 propres à ELG Music.
# Media3 embarque ses propres règles consommateur : aucune règle globale n'est nécessaire.
EOF

echo "  -> app/src/main/AndroidManifest.xml"
mkdir -p app/src/main
cat << 'EOF' > app/src/main/AndroidManifest.xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- ===================== BIBLIOTHÈQUE AUDIO ===================== -->
    <!-- minSdk 33 : accès dédié aux fichiers audio, seule permission de stockage nécessaire -->
    <uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />

    <!-- ===================== NOTIFICATIONS ===================== -->
    <!-- Android 13+ : requis pour afficher les contrôles de lecture -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

    <!-- ===================== LECTURE EN PREMIER PLAN ===================== -->
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />

    <!-- ===================== EFFETS AUDIO (égaliseur, bass boost, virtualizer) ===================== -->
    <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />

    <!-- ===================== BLUETOOTH (reprise automatique) ===================== -->
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />

    <!-- ===================== RÉSEAU (Gemini, Firebase, mises à jour) ===================== -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

    <!-- ===================== COFFRE-FORT PRIVÉ ===================== -->
    <uses-permission android:name="android.permission.USE_BIOMETRIC" />

    <application
        android:allowBackup="true"
        android:dataExtractionRules="@xml/data_extraction_rules"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:supportsRtl="true"
        android:theme="@style/Theme.Material3.DayNight.NoActionBar">

        <!-- Écran principal -->
        <activity
            android:name=".ui.main.MainActivity"
            android:exported="true"
            android:launchMode="singleTask"
            android:windowSoftInputMode="adjustResize">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>

            <!-- Lecteur de musique officiel : répond à « ouvrir l'application de musique » -->
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.APP_MUSIC" />
                <category android:name="android.intent.category.DEFAULT" />
            </intent-filter>

            <!-- Commande vocale / assistant : « lis <titre ou artiste> » -->
            <intent-filter>
                <action android:name="android.media.action.MEDIA_PLAY_FROM_SEARCH" />
                <category android:name="android.intent.category.DEFAULT" />
            </intent-filter>

            <!-- « Ouvrir avec » sur un fichier audio (gestionnaires de fichiers, navigateurs, messageries) -->
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="file" />
                <data android:scheme="content" />
                <data android:mimeType="audio/*" />
                <data android:mimeType="application/ogg" />
            </intent-filter>
        </activity>

        <!-- Réglages -->
        <activity
            android:name=".ui.settings.SettingsActivity"
            android:exported="false"
            android:label="@string/settings_title"
            android:parentActivityName=".ui.main.MainActivity" />

        <!-- Audio & effets : vitesse, pitch, égaliseur, bass boost, virtualizer -->
        <activity
            android:name=".ui.settings.AudioSettingsActivity"
            android:exported="false"
            android:label="@string/audio_settings_title"
            android:parentActivityName=".ui.settings.SettingsActivity" />

        <!-- Coffre-fort audio : morceaux masqués, protégés par un code PIN -->
        <activity
            android:name=".ui.vault.VaultActivity"
            android:exported="false"
            android:label="@string/vault_title"
            android:parentActivityName=".ui.settings.SettingsActivity" />

        <!-- Éditeur de tags ID3 « Studio Edition » : avertissement légal, 16 champs, pochette, inspecteur technique -->
        <activity
            android:name=".ui.tags.TagEditorActivity"
            android:configChanges="orientation|screenSize|screenLayout|smallestScreenSize|keyboardHidden"
            android:exported="false"
            android:label="@string/tag_editor_title"
            android:windowSoftInputMode="adjustResize" />

        <!-- v1.5 : boutons physiques (écouteurs filaires, Bluetooth, geste TalkBack à deux doigts) : relance le service
             de lecture et la musique même si l'application est fermée -->
        <receiver
            android:name="androidx.media3.session.MediaButtonReceiver"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MEDIA_BUTTON" />
            </intent-filter>
        </receiver>

        <!-- Service de lecture audio (Media3 / MediaSessionService) -->
        <service
            android:name=".playback.MusicPlaybackService"
            android:exported="true"
            android:foregroundServiceType="mediaPlayback">
            <intent-filter>
                <action android:name="androidx.media3.session.MediaSessionService" />
                <action android:name="android.media.browse.MediaBrowserService" />
            </intent-filter>
        </service>

    </application>

</manifest>
EOF

echo "  -> app/src/main/res/values/strings.xml"
mkdir -p app/src/main/res/values
cat << 'EOF' > app/src/main/res/values/strings.xml
<?xml version="1.0" encoding="utf-8"?>
<resources>

    <!-- ===================== GÉNÉRAL ===================== -->
    <string name="app_name">ELG Music</string>
    <string name="settings_title">Réglages</string>
    <string name="default_song_title">Sans titre</string>
    <string name="voice_note_title">Note vocale</string>
    <string name="voice_note_title_with_date">Note vocale du %1$s</string>

    <!-- ===================== ÉCRAN PRINCIPAL ===================== -->
    <string name="main_placeholder_message">Aucun morceau ne correspond. Vérifiez votre recherche, ou qu\'il y a de la musique sur l\'appareil.</string>
    <string name="search_hint">Rechercher un titre ou un artiste</string>
    <string name="menu_about">À propos &amp; Contact</string>
    <string name="menu_about_description">Ouvrir À propos et Contact</string>
    <string name="menu_settings_description">Ouvrir les réglages</string>

    <!-- ===================== BARRE DE FILTRES ===================== -->
    <string name="filter_tab_titles">Titres</string>
    <string name="filter_tab_artists">Artistes</string>
    <string name="filter_tab_albums">Albums</string>
    <string name="filter_tab_playlists">Playlists</string>
    <string name="filter_tab_favorites">Favoris</string>
    <string name="filter_tab_folders">Dossiers</string>
    <string name="filter_not_available_message">Bientôt disponible</string>

    <!-- ===================== TRI DE LA LISTE ===================== -->
    <string name="sort_button_description">Trier par</string>
    <string name="sort_dialog_title">Trier par</string>
    <string name="sort_dialog_cancel">Annuler</string>
    <string name="sort_applied_message">Tri : %1$s</string>


    <!-- ===================== CRITÈRES DE TRI ===================== -->
    <string name="sort_title_asc">Nom du titre (A à Z)</string>
    <string name="sort_title_desc">Nom du titre (Z à A)</string>
    <string name="sort_date_newest">Date d\'ajout (plus récents en premier)</string>
    <string name="sort_date_oldest">Date d\'ajout (plus anciens en premier)</string>
    <string name="sort_duration_longest">Durée (plus longs en premier)</string>
    <string name="sort_duration_shortest">Durée (plus courts en premier)</string>
    <string name="sort_artist">Artiste (A à Z)</string>
    <string name="sort_album">Album (A à Z)</string>

    <!-- ===================== RECHERCHE ===================== -->
    <string name="search_clear_description">Supprimer la recherche</string>
    <string name="play_from_search_no_result">Aucun morceau trouvé pour « %1$s »</string>
    <string name="view_audio_unreadable">Impossible de lire ce fichier audio.</string>

    <!-- ===================== ARTISTES ET ALBUMS ===================== -->
    <string name="artist_unknown">Inconnu</string>
    <string name="album_unknown">Album inconnu</string>
    <plurals name="album_count">
        <item quantity="one">%d album</item>
        <item quantity="other">%d albums</item>
    </plurals>
    <plurals name="piece_count">
        <item quantity="one">%d morceau</item>
        <item quantity="other">%d morceaux</item>
    </plurals>
    <plurals name="track_count">
        <item quantity="one">%d piste</item>
        <item quantity="other">%d pistes</item>
    </plurals>
    <string name="artist_details_format">%1$s | %2$s</string>
    <string name="album_details_format">%1$s | %2$s</string>
    <string name="artist_row_content_description">Ouvrir l\'artiste %1$s, %2$s</string>
    <string name="album_row_content_description">Ouvrir l\'album %1$s, %2$s</string>
    <string name="empty_artists_message">Aucun artiste à afficher pour le moment.</string>
    <string name="empty_albums_message">Aucun album à afficher pour le moment.</string>

    <!-- ===================== GRAND LECTEUR ET FILE D\'ATTENTE ===================== -->
    <string name="player_pane_title">Lecteur</string>
    <string name="player_open_description">Ouvrir le lecteur</string>
    <string name="player_collapse_description">Réduire le lecteur</string>
    <string name="player_add_to_playlist_description">Ajouter à une playlist</string>
    <string name="player_seek_description">Position de lecture</string>
    <string name="player_seek_state">%1$s sur %2$s</string>
    <string name="player_time_zero">0:00</string>
    <string name="player_more_options_description">Plus d\'options</string>
    <string name="player_menu_unavailable">Ces actions ne sont pas disponibles pour ce fichier.</string>
    <string name="queue_title">File d\'attente</string>
    <string name="queue_button_description">File d\'attente</string>
    <string name="queue_row_description">%1$s, %2$s</string>
    <string name="queue_row_current_description">En cours de lecture : %1$s, %2$s</string>

    <!-- ===================== ALÉATOIRE ET RÉPÉTITION ===================== -->
    <string name="mini_player_shuffle_description">Lecture aléatoire</string>
    <string name="mini_player_repeat_description">Répétition</string>
    <string name="state_on">Activée</string>
    <string name="state_off">Désactivée</string>
    <string name="state_repeat_all">Toute la liste</string>
    <string name="state_repeat_one">Ce titre</string>

    <!-- ===================== NOMBRE DE TITRES ===================== -->
    <plurals name="song_count">
        <item quantity="one">%d titre</item>
        <item quantity="other">%d titres</item>
    </plurals>

    <!-- ===================== ONGLET DOSSIERS ===================== -->
    <string name="folder_root_name">Racine du stockage</string>
    <string name="folder_details_format">%1$s · %2$s</string>
    <string name="folder_row_content_description">Ouvrir le dossier %1$s, %2$s</string>
    <string name="folder_back_description">Revenir à la liste</string>
    <string name="folder_play_all">Lire le dossier</string>
    <string name="empty_folders_message">Aucun dossier ne contient de musique pour le moment.</string>

    <!-- ===================== ONGLET PLAYLISTS ===================== -->
    <string name="playlist_create_fab_description">Créer une nouvelle playlist</string>
    <string name="playlist_create_title">Nouvelle playlist</string>
    <string name="playlist_name_hint">Nom de la playlist</string>
    <string name="playlist_create_confirm">Créer</string>
    <string name="playlist_name_error_empty">Saisissez un nom pour la playlist.</string>
    <string name="playlist_name_error_duplicate">Une playlist porte déjà ce nom.</string>
    <string name="playlist_created_message">Playlist « %1$s » créée</string>
    <string name="playlist_created_with_song_message">Playlist « %1$s » créée, %2$s ajouté</string>
    <string name="playlist_add_dialog_title">Ajouter à une playlist</string>
    <string name="playlist_add_new_option">Nouvelle playlist…</string>
    <string name="playlist_song_added_message">%1$s ajouté à « %2$s »</string>
    <string name="playlist_song_already_message">%1$s est déjà dans « %2$s »</string>
    <string name="playlist_song_removed_message">%1$s retiré de « %2$s »</string>
    <string name="playlist_deleted_message">Playlist « %1$s » supprimée</string>
    <string name="playlist_delete_dialog_title">Supprimer cette playlist ?</string>
    <string name="playlist_delete_dialog_message">« %1$s » sera supprimée. Les morceaux restent sur l\'appareil.</string>
    <string name="playlist_delete_action">Supprimer la playlist</string>
    <string name="playlist_play_all">Tout lire</string>
    <string name="playlist_row_details_format">%1$s · créée le %2$s</string>
    <string name="playlist_row_content_description">Ouvrir la playlist %1$s, %2$s</string>
    <string name="playlist_menu_button_description">Options pour la playlist %1$s</string>
    <string name="empty_playlists_message">Aucune playlist pour l\'instant. Touchez le bouton + pour en créer une.</string>
    <string name="empty_playlist_detail_message">Cette playlist est vide. Utilisez le menu à trois points d\'un titre pour l\'ajouter ici.</string>
    <string name="empty_search_message">Aucun résultat pour cette recherche.</string>
    <string name="song_menu_add_to_playlist">Ajouter à une playlist…</string>
    <string name="song_menu_remove_from_playlist">Retirer de cette playlist</string>

    <!-- ===================== ONGLET FAVORIS ===================== -->
    <string name="favorites_empty_title">Aucun favori pour le moment</string>
    <string name="favorites_empty_message">Ouvrez le menu à trois points d\'un titre et choisissez « Ajouter aux favoris ».</string>
    <string name="favorites_explore_button">Explorer la bibliothèque</string>
    <string name="favorites_shuffle_all">Lecture aléatoire</string>

    <!-- ===================== LISTE DES MORCEAUX ===================== -->
    <string name="song_row_content_description">Lire %1$s, de %2$s</string>
    <string name="song_row_content_description_no_artist">Lire %1$s</string>
    <string name="song_menu_button_content_description">Options pour %1$s</string>
    <string name="song_menu_add_favorite">Ajouter aux favoris</string>
    <string name="song_menu_remove_favorite">Retirer des favoris</string>
    <string name="song_menu_hide">Masquer (liste noire)</string>
    <string name="song_menu_share">Partager le fichier audio</string>
    <string name="song_menu_delete">Supprimer la musique</string>

    <!-- ===================== ACTIONS SUR LES MORCEAUX ===================== -->
    <string name="favorite_added_message">%1$s ajouté aux favoris</string>
    <string name="favorite_removed_message">%1$s retiré des favoris</string>
    <string name="song_hidden_message">%1$s masqué de la bibliothèque</string>
    <string name="share_chooser_title">Partager le morceau via</string>
    <string name="delete_dialog_title">Supprimer ce morceau ?</string>
    <string name="delete_dialog_message">« %1$s » sera définitivement supprimé du stockage de l\'appareil.</string>
    <string name="delete_dialog_confirm">Supprimer</string>
    <string name="delete_dialog_cancel">Annuler</string>
    <string name="song_deleted_message">%1$s supprimé</string>
    <string name="delete_error_message">Impossible de supprimer ce fichier.</string>

    <!-- ===================== PERMISSIONS ===================== -->
    <string name="permission_denied_message">Accès à la musique refusé : la bibliothèque ne peut pas être chargée.</string>

    <!-- ===================== MINI-LECTEUR ===================== -->
    <string name="mini_player_play_description">Lecture</string>
    <string name="mini_player_pause_description">Pause</string>
    <string name="mini_player_previous_description">Morceau précédent</string>
    <string name="mini_player_next_description">Morceau suivant</string>

    <!-- ===================== RÉGLAGES ===================== -->
    <string name="settings_back_description">Revenir à l\'écran principal</string>
    <string name="settings_category_appearance">Affichage &amp; thème</string>
    <string name="settings_theme_title">Thème de l\'application</string>
    <string name="settings_category_about">À propos</string>
    <string name="settings_about_summary">Version, liens et contact du développeur</string>

    <string-array name="theme_entries">
        <item>Clair</item>
        <item>Sombre</item>
        <item>Système (par défaut)</item>
    </string-array>

    <string-array name="theme_values">
        <item>light</item>
        <item>dark</item>
        <item>system</item>
    </string-array>

    <!-- ===================== MODULE À PROPOS & CONTACT ===================== -->
    <string name="about_title">À propos &amp; Contact</string>
    <string name="about_version_format">Version %1$s</string>
    <string name="about_intro">Un lecteur audio pensé pour une expérience sobre, fluide et moderne. Merci d\'utiliser ELG Music !</string>
    <string name="about_section_links">Nous retrouver</string>

    <!-- Libellés visibles des boutons -->
    <string name="about_label_youtube_main">YouTube - Mister-Flasheur</string>
    <string name="about_label_youtube_secondary">YouTube - Arthur 475</string>
    <string name="about_label_facebook">Facebook</string>
    <string name="about_label_instagram">Instagram</string>
    <string name="about_label_twitch">Twitch</string>
    <string name="about_label_email">Contacter le support</string>

    <!-- URLs et adresse (utilisées par les Intents) -->
    <string name="about_url_youtube_main" translatable="false">https://youtube.com/@mister-flasheur475?si=LdIFeBJjpAvPamO_</string>
    <string name="about_url_youtube_secondary" translatable="false">https://youtube.com/@arthur475-s8m?si=67bBtAJ6JaR8Bvak</string>
    <string name="about_url_facebook" translatable="false">https://www.facebook.com/share/14nZxsU1Nt3/</string>
    <string name="about_url_instagram" translatable="false">https://www.instagram.com/mister_flasheur?stkn=MTBjam1qb3dpMms4cA==</string>
    <string name="about_url_twitch" translatable="false">https://www.twitch.tv/arthur475s8m</string>
    <string name="about_email_address" translatable="false">litokoemmanuel@gmail.com</string>

    <!-- Descriptions TalkBack -->
    <string name="about_cd_youtube_main">Ouvrir la chaîne YouTube principale Mister-Flasheur</string>
    <string name="about_cd_youtube_secondary">Ouvrir la chaîne YouTube Arthur 475</string>
    <string name="about_cd_facebook">Ouvrir la page Facebook</string>
    <string name="about_cd_instagram">Ouvrir le compte Instagram Mister Flasheur</string>
    <string name="about_cd_twitch">Ouvrir la chaîne Twitch</string>
    <string name="about_cd_email">Envoyer un e-mail de support à litokoemmanuel@gmail.com</string>

    <!-- Erreurs -->
    <string name="about_error_no_app">Aucune application disponible pour ouvrir ce lien.</string>
    <string name="about_error_no_email_app">Aucune application e-mail disponible.</string>

    <!-- ===================== AUDIO & EFFETS (v1.4, étape 3) ===================== -->
    <string name="settings_category_audio">Audio</string>
    <string name="settings_audio_title">Vitesse, tonalité et égaliseur</string>
    <string name="settings_audio_summary">Pitch, vitesse, égaliseur 5 bandes, bass boost et spatialisation 3D</string>
    <string name="audio_settings_title">Audio &amp; effets</string>
    <string name="audio_section_speed_pitch">Vitesse et tonalité</string>
    <string name="audio_speed_label">Vitesse de lecture</string>
    <string name="audio_pitch_label">Tonalité (pitch)</string>
    <string name="speed_preset_normal">Normal</string>
    <string name="speed_preset_nightcore">Nightcore</string>
    <string name="speed_preset_deep_voice">Deep Voice / Slowed</string>
    <string name="speed_preset_dictation">Dictée / Apprentissage</string>
    <string name="audio_section_equalizer">Égaliseur</string>
    <string name="audio_equalizer_switch">Activer l\'égaliseur</string>
    <string name="eq_preset_button_format">Préréglage : %1$s</string>
    <string name="eq_preset_dialog_title">Préréglage de l\'égaliseur</string>
    <string name="eq_preset_flat">Flat</string>
    <string name="eq_preset_bass">Bass</string>
    <string name="eq_preset_rock">Rock</string>
    <string name="eq_preset_pop">Pop</string>
    <string name="eq_preset_jazz">Jazz</string>
    <string name="eq_preset_vocal">Vocal</string>
    <string name="eq_preset_custom">Custom</string>
    <string-array name="eq_band_labels" translatable="false">
        <item>60 Hz</item>
        <item>230 Hz</item>
        <item>910 Hz</item>
        <item>3,6 kHz</item>
        <item>14 kHz</item>
    </string-array>
    <string name="audio_section_effects">Effets sonores</string>
    <string name="audio_bass_boost_label">Bass Boost</string>
    <string name="audio_virtualizer_label">Spatialisation 3D (Virtualizer)</string>
    <string name="audio_effects_note">Les effets dépendent du matériel de l\'appareil : sur certains modèles, un effet peut être limité ou indisponible. Ils ne s\'appliquent pas aux fichiers MIDI.</string>
    <string name="audio_reset_button">Réinitialiser l\'audio</string>
    <string name="audio_reset_done_message">Réglages audio réinitialisés</string>

    <!-- ===================== COFFRE-FORT (v1.4, étape 4) ===================== -->
    <string name="settings_category_privacy">Confidentialité</string>
    <string name="settings_vault_title">Coffre-fort audio</string>
    <string name="settings_vault_summary">Morceaux masqués, protégés par un code PIN</string>
    <string name="vault_title">Coffre-fort</string>
    <string name="song_menu_vault">Masquer cette musique (coffre-fort)</string>
    <string name="vault_hide_dialog_title">Masquer dans le coffre-fort ?</string>
    <string name="vault_hide_dialog_message">« %1$s » sera déplacé dans le stockage privé de l\'application : il disparaîtra de la bibliothèque et des autres applications audio. Retrouvez-le dans Réglages › Coffre-fort, protégé par votre code PIN.\n\nAttention : si vous désinstallez ELG Music, les morceaux du coffre-fort sont perdus. Démasquez-les avant.</string>
    <string name="vault_hide_confirm">Masquer</string>
    <string name="vault_hidden_message">%1$s masqué dans le coffre-fort</string>
    <string name="vault_hide_error_message">Impossible de masquer ce fichier.</string>
    <string name="vault_hide_cancelled_message">Masquage annulé : le fichier reste dans la bibliothèque.</string>

    <string name="vault_pin_create_title">Créer un code PIN</string>
    <string name="vault_pin_change_title">Changer le code PIN</string>
    <string name="vault_pin_create_message">Choisissez un code de 4 ou 6 chiffres. Il protège l\'accès au coffre-fort.</string>
    <string name="vault_pin_unlock_title">Coffre-fort verrouillé</string>
    <string name="vault_pin_unlock_message">Saisissez votre code PIN.</string>
    <string name="vault_pin_hint">Code PIN</string>
    <string name="vault_pin_confirm_hint">Confirmer le code PIN</string>
    <string name="vault_pin_confirm_button">Valider</string>
    <string name="vault_pin_cancel">Annuler</string>
    <string name="vault_pin_error_format">Le code doit comporter exactement 4 ou 6 chiffres.</string>
    <string name="vault_pin_error_mismatch">Les deux codes ne sont pas identiques.</string>
    <string name="vault_pin_error_wrong">Code incorrect. %1$d essai(s) avant blocage temporaire.</string>
    <string name="vault_pin_error_locked">Trop d\'essais. Réessayez dans %1$d s.</string>
    <string name="vault_pin_error_locked_countdown">Nombre maximal de tentatives atteint. Réessayez dans %1$s</string>
    <string name="vault_pin_changed_message">Code PIN modifié</string>

    <string name="vault_empty_message">Le coffre-fort est vide. Utilisez « Masquer cette musique » dans le menu d\'un titre.</string>
    <string name="vault_menu_change_pin">Changer le code PIN</string>
    <string name="vault_menu_restore">Démasquer (remettre dans la bibliothèque)</string>
    <string name="vault_menu_delete">Supprimer définitivement</string>
    <string name="vault_restore_done_message">%1$s remis dans la bibliothèque</string>
    <string name="vault_restore_error_message">Impossible de démasquer ce fichier.</string>
    <string name="vault_delete_dialog_title">Supprimer définitivement ?</string>
    <string name="vault_delete_dialog_message">« %1$s » sera supprimé pour toujours, sans possibilité de le récupérer.</string>
    <string name="vault_deleted_message">%1$s supprimé</string>

    <!-- ===================== MINUTEUR DE SOMMEIL ET BOUCLE A-B (v1.4, étape 5) ===================== -->
    <string name="settings_sleep_timer_title">Minuteur de sommeil</string>
    <string name="settings_sleep_timer_summary">Arrêter la lecture après une durée ou à la fin de la piste, avec fondu sonore</string>
    <string name="sleep_timer_title">Minuteur de sommeil</string>
    <string name="sleep_timer_option_15">15 minutes</string>
    <string name="sleep_timer_option_30">30 minutes</string>
    <string name="sleep_timer_option_45">45 minutes</string>
    <string name="sleep_timer_option_60">60 minutes</string>
    <string name="sleep_timer_option_end">Fin de la piste</string>
    <string name="sleep_timer_fade_switch">Fondu sonore (30 dernières secondes)</string>
    <string name="sleep_timer_fading">Fondu sonore en cours…</string>
    <string name="sleep_timer_start">Démarrer</string>
    <string name="sleep_timer_cancel">Annuler le minuteur</string>
    <string name="sleep_timer_status_idle">Aucun minuteur actif.</string>
    <string name="sleep_timer_status_countdown">Arrêt de la lecture dans %1$s</string>
    <string name="sleep_timer_status_end_of_track">Arrêt à la fin de la piste en cours</string>
    <string name="sleep_timer_status_end_of_track_remaining">Arrêt à la fin de la piste (dans %1$s)</string>
    <string name="sleep_timer_no_playback">Lancez d\'abord la lecture d\'un morceau : le minuteur agit sur la lecture en cours et continue en arrière-plan.</string>
    <string name="sleep_timer_started_minutes">Minuteur réglé : arrêt dans %1$d min</string>
    <string name="sleep_timer_started_end">Minuteur réglé : arrêt à la fin de la piste</string>
    <string name="sleep_timer_cancelled">Minuteur annulé</string>

    <string name="menu_sleep_timer">Minuteur de sommeil…</string>
    <string name="menu_ab_loop">Boucle A-B…</string>
    <string name="ab_loop_title">Boucle A-B</string>
    <string name="ab_loop_hint">Pendant la lecture, touchez « Marquer A » au début du passage voulu, puis « Marquer B » à sa fin : le passage se répète en boucle.</string>
    <string name="ab_loop_position_format">Position actuelle : %1$s</string>
    <string name="ab_loop_point_a_format">Point A : %1$s</string>
    <string name="ab_loop_point_b_format">Point B : %1$s</string>
    <string name="ab_loop_not_set">non défini</string>
    <string name="ab_loop_mark_a">Marquer A</string>
    <string name="ab_loop_mark_b">Marquer B</string>
    <string name="ab_loop_repeat_switch">Répéter la boucle A-B</string>
    <string name="ab_loop_clear">Effacer la boucle</string>
    <string name="ab_loop_error_no_track">Aucun morceau en cours de lecture.</string>
    <string name="ab_loop_error_needs_a">Marquez d\'abord le point A.</string>
    <string name="ab_loop_error_too_short">Le point B doit suivre le point A d\'au moins 1 seconde.</string>
    <string name="ab_loop_error_incomplete">Marquez d\'abord les points A et B.</string>
    <string name="ab_loop_play_first_message">Lancez d\'abord la lecture de « %1$s » pour définir une boucle A-B.</string>
    <string name="ab_loop_cleared_message">Boucle A-B effacée</string>

    <!-- ===================== ÉDITEUR DE TAGS (v1.4, étape 6) ===================== -->
    <string name="song_menu_edit_tags">Éditeur de tags…</string>
    <string name="tag_editor_title">Éditeur de tags</string>
    <string name="tag_warning_title">Responsabilité &amp; Propriété Intellectuelle</string>
    <string name="tag_warning_message">Avertissement : Vous êtes l\'unique responsable des modifications apportées aux métadonnées et aux fichiers audio (titre, artiste, droits d\'auteur / copyright). Veillez à respecter la législation sur la propriété intellectuelle.</string>
    <string name="tag_warning_cancel">Annuler</string>
    <string name="tag_warning_accept">Compris / J\'accepte</string>

    <string name="tag_cover_description">Pochette de l\'album</string>
    <string name="tag_cover_change">Changer la pochette</string>
    <string name="tag_cover_mp3_only">Ce format n\'a pas de structure d\'image interne : la pochette est conservée dans le cache sécurisé d\'ELG Music, sans modifier le fichier audio.</string>
    <string name="tag_cover_updated">Nouvelle pochette sélectionnée</string>
    <string name="tag_cover_error">Impossible de lire cette image.</string>
    <string name="tag_autofill_button">Remplir automatiquement depuis le nom de fichier</string>
    <string name="tag_autofill_done">Champs remplis depuis le nom du fichier</string>
    <string name="tag_autofill_nothing">Aucune information exploitable dans le nom du fichier</string>
    <string name="tag_non_mp3_note">Ce format (MIDI, AMR, AC-3, DTS…) ne permet pas d\'écrire les tags dans le fichier sans risque de le corrompre : les champs sont conservés par ELG Music, et titre, artiste, album, genre, année, piste et compositeur sont aussi mis à jour dans la bibliothèque Android.</string>

    <string name="tag_section_info">Informations</string>
    <string name="tag_field_title">Titre</string>
    <string name="tag_field_artist">Artiste</string>
    <string name="tag_field_album">Album</string>
    <string name="tag_field_album_artist">Artiste de l\'album</string>
    <string name="tag_field_genre">Genre</string>
    <string name="tag_field_year">Année</string>
    <string name="tag_field_disc">Numéro de disque</string>
    <string name="tag_field_track">Numéro de piste</string>
    <string name="tag_field_track_total">Total pistes</string>
    <string name="tag_field_composer">Compositeur</string>
    <string name="tag_field_copyright">Droits d\'auteur (copyright)</string>
    <string name="tag_field_publisher">Éditeur / Label</string>
    <string name="tag_field_encoder">Encodeur</string>
    <string name="tag_field_language">Langue</string>
    <string name="tag_field_comment">Commentaires</string>
    <string name="tag_field_lyrics">Paroles de la chanson</string>

    <string name="tag_section_tech">Inspecteur technique</string>
    <string name="tag_tech_format">Format : %1$s</string>
    <string name="tag_tech_bitrate">Bitrate : %1$s</string>
    <string name="tag_tech_sample_rate">Fréquence : %1$s</string>
    <string name="tag_tech_size">Taille : %1$s (%2$s octets)</string>
    <string name="tag_tech_path">Chemin : %1$s</string>
    <string name="tag_tech_unknown">inconnu</string>

    <string name="tag_save">Enregistrer</string>
    <string name="tag_cancel">Annuler</string>
    <string name="tag_error_title_empty">Le titre ne peut pas être vide.</string>
    <string name="tag_error_number">Saisissez uniquement des chiffres (4 au maximum).</string>
    <string name="tag_section_record_date">Date d\'enregistrement (facultative)</string>
    <string name="tag_field_record_day">Jour</string>
    <string name="tag_field_record_month">Mois</string>
    <string name="tag_month_none">(aucun)</string>
    <string name="tag_error_date_year_required">Pour enregistrer une date, saisissez l\'année sur 4 chiffres.</string>
    <string name="tag_error_date_month_required">Choisissez le mois correspondant au jour.</string>
    <string name="tag_error_date_day_invalid">Jour invalide pour ce mois.</string>
    <string name="tag_error_date_future">La date d\'enregistrement ne peut pas être dans le futur.</string>
    <string-array name="tag_month_choices">
        <item>(aucun)</item>
        <item>Janvier</item>
        <item>Février</item>
        <item>Mars</item>
        <item>Avril</item>
        <item>Mai</item>
        <item>Juin</item>
        <item>Juillet</item>
        <item>Août</item>
        <item>Septembre</item>
        <item>Octobre</item>
        <item>Novembre</item>
        <item>Décembre</item>
    </string-array>
    <string name="tag_load_error">Impossible de lire ce fichier audio.</string>
    <string name="tag_save_error">Enregistrement impossible : %1$s</string>
    <string name="tag_write_denied">Autorisation refusée : les tags n\'ont pas été modifiés.</string>
    <string name="tag_write_refused">Le système a refusé l\'écriture dans ce fichier : les tags n\'ont pas été modifiés.</string>
    <string name="tag_saved_file">Tags enregistrés dans le fichier</string>
    <string name="tag_saved_library">Tags enregistrés dans ELG Music et dans la bibliothèque</string>

</resources>
EOF

echo "  -> app/src/main/res/values/colors.xml"
mkdir -p app/src/main/res/values
cat << 'EOF' > app/src/main/res/values/colors.xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#1F2A44</color>
</resources>
EOF

echo "  -> app/src/main/res/xml/root_preferences.xml"
mkdir -p app/src/main/res/xml
cat << 'EOF' > app/src/main/res/xml/root_preferences.xml
<?xml version="1.0" encoding="utf-8"?>
<PreferenceScreen xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto">

    <PreferenceCategory app:title="@string/settings_category_appearance">

        <ListPreference
            app:key="pref_theme"
            app:title="@string/settings_theme_title"
            app:summary="%s"
            app:entries="@array/theme_entries"
            app:entryValues="@array/theme_values"
            app:defaultValue="system"
            app:icon="@drawable/ic_settings" />

    </PreferenceCategory>

    <PreferenceCategory app:title="@string/settings_category_audio">

        <Preference
            app:key="pref_audio"
            app:title="@string/settings_audio_title"
            app:summary="@string/settings_audio_summary" />

        <Preference
            app:key="pref_sleep_timer"
            app:title="@string/settings_sleep_timer_title"
            app:summary="@string/settings_sleep_timer_summary" />

    </PreferenceCategory>

    <PreferenceCategory app:title="@string/settings_category_privacy">

        <Preference
            app:key="pref_vault"
            app:title="@string/settings_vault_title"
            app:summary="@string/settings_vault_summary" />

    </PreferenceCategory>

    <PreferenceCategory app:title="@string/settings_category_about">

        <Preference
            app:key="pref_about"
            app:title="@string/menu_about"
            app:summary="@string/settings_about_summary" />

    </PreferenceCategory>

</PreferenceScreen>
EOF

echo "  -> app/src/main/res/drawable/ic_settings.xml"
mkdir -p app/src/main/res/drawable
cat << 'EOF' > app/src/main/res/drawable/ic_settings.xml
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#FF000000"
        android:pathData="M19.14,12.94c0.04,-0.3 0.06,-0.61 0.06,-0.94c0,-0.32 -0.02,-0.64 -0.07,-0.94l2.03,-1.58c0.18,-0.14 0.23,-0.41 0.12,-0.61l-1.92,-3.32c-0.12,-0.22 -0.37,-0.29 -0.59,-0.22l-2.39,0.96c-0.5,-0.38 -1.03,-0.7 -1.62,-0.94L14.4,2.81c-0.04,-0.24 -0.24,-0.41 -0.48,-0.41h-3.84c-0.24,0 -0.43,0.17 -0.47,0.41L9.25,5.35C8.66,5.59 8.12,5.92 7.63,6.29L5.24,5.33c-0.22,-0.08 -0.47,0 -0.59,0.22L2.74,8.87c-0.12,0.21 -0.08,0.47 0.12,0.61l2.03,1.58C4.84,11.36 4.8,11.69 4.8,12s0.02,0.64 0.07,0.94l-2.03,1.58c-0.18,0.14 -0.23,0.41 -0.12,0.61l1.92,3.32c0.12,0.22 0.37,0.29 0.59,0.22l2.39,-0.96c0.5,0.38 1.03,0.7 1.62,0.94l0.36,2.54c0.05,0.24 0.24,0.41 0.48,0.41h3.84c0.24,0 0.44,-0.17 0.47,-0.41l0.36,-2.54c0.59,-0.24 1.13,-0.56 1.62,-0.94l2.39,0.96c0.22,0.08 0.47,0 0.59,-0.22l1.92,-3.32c0.12,-0.22 0.07,-0.47 -0.12,-0.61L19.14,12.94zM12,15.6c-1.98,0 -3.6,-1.62 -3.6,-3.6s1.62,-3.6 3.6,-3.6s3.6,1.62 3.6,3.6S13.98,15.6 12,15.6z" />
</vector>
EOF

echo "  -> app/src/main/res/drawable/ic_more_vert.xml"
mkdir -p app/src/main/res/drawable
cat << 'EOF' > app/src/main/res/drawable/ic_more_vert.xml
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#FF000000"
        android:pathData="M12,8c1.1,0 2,-0.9 2,-2s-0.9,-2 -2,-2 -2,0.9 -2,2S10.9,8 12,8zM12,10c-1.1,0 -2,0.9 -2,2s0.9,2 2,2 2,-0.9 2,-2S13.1,10 12,10zM12,16c-1.1,0 -2,0.9 -2,2s0.9,2 2,2 2,-0.9 2,-2S13.1,16 12,16z" />
</vector>
EOF

echo "  -> app/src/main/res/drawable/ic_play_arrow.xml"
mkdir -p app/src/main/res/drawable
cat << 'EOF' > app/src/main/res/drawable/ic_play_arrow.xml
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#FF000000"
        android:pathData="M8,5v14l11,-7z" />
</vector>
EOF

echo "  -> app/src/main/res/drawable/ic_pause.xml"
mkdir -p app/src/main/res/drawable
cat << 'EOF' > app/src/main/res/drawable/ic_pause.xml
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#FF000000"
        android:pathData="M6,19h4L10,5L6,5v14zM14,5v14h4L18,5h-4z" />
</vector>
EOF

echo "  -> app/src/main/res/drawable/ic_skip_previous.xml"
mkdir -p app/src/main/res/drawable
cat << 'EOF' > app/src/main/res/drawable/ic_skip_previous.xml
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#FF000000"
        android:pathData="M6,6h2v12H6zM9.5,12l8.5,6V6z" />
</vector>
EOF

echo "  -> app/src/main/res/drawable/ic_skip_next.xml"
mkdir -p app/src/main/res/drawable
cat << 'EOF' > app/src/main/res/drawable/ic_skip_next.xml
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#FF000000"
        android:pathData="M6,18l8.5,-6L6,6v12zM16,6v12h2V6h-2z" />
</vector>
EOF

echo "  -> app/src/main/res/drawable/ic_music_note.xml"
mkdir -p app/src/main/res/drawable
cat << 'EOF' > app/src/main/res/drawable/ic_music_note.xml
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#FF000000"
        android:pathData="M12,3v10.55c-0.59,-0.34 -1.27,-0.55 -2,-0.55c-2.21,0 -4,1.79 -4,4s1.79,4 4,4s4,-1.79 4,-4L14,7h4L18,3L12,3z" />
</vector>
EOF

echo "  -> app/src/main/res/drawable/ic_launcher_foreground.xml"
mkdir -p app/src/main/res/drawable
cat << 'EOF' > app/src/main/res/drawable/ic_launcher_foreground.xml
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <group
        android:scaleX="2.2"
        android:scaleY="2.2"
        android:translateX="27.6"
        android:translateY="27.6">
        <path
            android:fillColor="#FFFFFFFF"
            android:pathData="M12,3v10.55c-0.59,-0.34 -1.27,-0.55 -2,-0.55c-2.21,0 -4,1.79 -4,4s1.79,4 4,4s4,-1.79 4,-4L14,7h4L18,3L12,3z" />
    </group>
</vector>
EOF

echo "  -> app/src/main/res/mipmap-anydpi/ic_launcher.xml"
mkdir -p app/src/main/res/mipmap-anydpi
cat << 'EOF' > app/src/main/res/mipmap-anydpi/ic_launcher.xml
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
    <monochrome android:drawable="@drawable/ic_launcher_foreground" />
</adaptive-icon>
EOF

echo "  -> app/src/main/res/mipmap-anydpi/ic_launcher_round.xml"
mkdir -p app/src/main/res/mipmap-anydpi
cat << 'EOF' > app/src/main/res/mipmap-anydpi/ic_launcher_round.xml
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
    <monochrome android:drawable="@drawable/ic_launcher_foreground" />
</adaptive-icon>
EOF

echo "  -> app/src/main/res/menu/menu_main.xml"
mkdir -p app/src/main/res/menu
cat << 'EOF' > app/src/main/res/menu/menu_main.xml
<?xml version="1.0" encoding="utf-8"?>
<menu xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto">

    <item
        android:id="@+id/action_settings"
        android:icon="@drawable/ic_settings"
        android:title="@string/settings_title"
        android:contentDescription="@string/menu_settings_description"
        app:showAsAction="always"
        app:iconTint="?attr/colorOnSurface" />

    <item
        android:id="@+id/action_about"
        android:title="@string/menu_about"
        android:contentDescription="@string/menu_about_description"
        app:showAsAction="never" />

</menu>
EOF

echo "  -> app/src/main/res/menu/menu_song_item.xml"
mkdir -p app/src/main/res/menu
cat << 'EOF' > app/src/main/res/menu/menu_song_item.xml
<?xml version="1.0" encoding="utf-8"?>
<menu xmlns:android="http://schemas.android.com/apk/res/android">

    <item
        android:id="@+id/action_toggle_favorite"
        android:title="@string/song_menu_add_favorite" />

    <item
        android:id="@+id/action_add_to_playlist"
        android:title="@string/song_menu_add_to_playlist" />

    <item
        android:id="@+id/action_remove_from_playlist"
        android:title="@string/song_menu_remove_from_playlist"
        android:visible="false" />

    <item
        android:id="@+id/action_hide_song"
        android:title="@string/song_menu_hide" />

    <item
        android:id="@+id/action_share_song"
        android:title="@string/song_menu_share" />

    <item
        android:id="@+id/action_ab_loop"
        android:title="@string/menu_ab_loop" />

    <item
        android:id="@+id/action_edit_tags"
        android:title="@string/song_menu_edit_tags" />

    <item
        android:id="@+id/action_vault_song"
        android:title="@string/song_menu_vault" />

    <item
        android:id="@+id/action_delete_song"
        android:title="@string/song_menu_delete" />

</menu>
EOF

echo "  -> app/src/main/res/layout/activity_main.xml"
mkdir -p app/src/main/res/layout
cat << 'EOF' > app/src/main/res/layout/activity_main.xml
<?xml version="1.0" encoding="utf-8"?>
<androidx.constraintlayout.widget.ConstraintLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    xmlns:tools="http://schemas.android.com/tools"
    android:layout_width="match_parent"
    android:layout_height="match_parent">

    <com.google.android.material.appbar.MaterialToolbar
        android:id="@+id/toolbar"
        android:layout_width="0dp"
        android:layout_height="?attr/actionBarSize"
        android:background="?attr/colorSurface"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toTopOf="parent">

        <!-- Logo : drapeau centrafricain + titre en pleine couleur (contraste maximal) + liseré aux couleurs du drapeau -->
        <LinearLayout
            android:id="@+id/layoutBrand"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:layout_gravity="center_vertical|start"
            android:gravity="center_vertical"
            android:orientation="horizontal">

            <com.google.android.material.imageview.ShapeableImageView
                android:id="@+id/imageBrandFlag"
                android:layout_width="36dp"
                android:layout_height="24dp"
                android:importantForAccessibility="no"
                android:padding="1dp"
                android:scaleType="fitXY"
                android:src="@drawable/ic_flag_rca"
                app:shapeAppearanceOverlay="@style/ShapeAppearance.Elg.FlagCorner"
                app:strokeColor="?attr/colorOutlineVariant"
                app:strokeWidth="1dp" />

            <LinearLayout
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:layout_marginStart="12dp"
                android:orientation="vertical">

                <TextView
                    android:id="@+id/textBrandTitle"
                    android:layout_width="wrap_content"
                    android:layout_height="wrap_content"
                    android:text="@string/app_name"
                    android:textAppearance="?attr/textAppearanceTitleLarge"
                    android:textColor="?attr/colorOnSurface"
                    android:textStyle="bold" />

                <ImageView
                    android:id="@+id/imageBrandUnderline"
                    android:layout_width="match_parent"
                    android:layout_height="3dp"
                    android:layout_marginTop="1dp"
                    android:importantForAccessibility="no"
                    android:scaleType="fitXY"
                    android:src="@drawable/ic_flag_rca_strip" />

            </LinearLayout>

        </LinearLayout>

    </com.google.android.material.appbar.MaterialToolbar>

    <!-- Recherche : loupe, champ de saisie, et bouton « Supprimer la recherche » (visible seulement s'il y a du texte) -->
    <LinearLayout
        android:id="@+id/searchBar"
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:background="?attr/colorSurface"
        android:orientation="vertical"
        android:paddingBottom="4dp"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toBottomOf="@id/toolbar">

        <LinearLayout
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:gravity="center_vertical"
            android:orientation="horizontal"
            android:paddingStart="16dp"
            android:paddingEnd="4dp">

            <ImageView
                android:layout_width="24dp"
                android:layout_height="24dp"
                android:importantForAccessibility="no"
                android:src="@drawable/ic_search"
                app:tint="?attr/colorOnSurfaceVariant" />

            <EditText
                android:id="@+id/editSearch"
                android:layout_width="0dp"
                android:layout_height="48dp"
                android:layout_marginStart="12dp"
                android:layout_weight="1"
                android:background="@null"
                android:hint="@string/search_hint"
                android:importantForAutofill="no"
                android:imeOptions="actionSearch"
                android:inputType="text"
                android:maxLines="1"
                android:textAppearance="?attr/textAppearanceBodyLarge"
                android:textColorHint="?attr/colorOnSurfaceVariant" />

            <ImageButton
                android:id="@+id/buttonClearSearch"
                android:layout_width="48dp"
                android:layout_height="48dp"
                android:background="?attr/selectableItemBackgroundBorderless"
                android:contentDescription="@string/search_clear_description"
                android:src="@drawable/ic_close"
                android:visibility="gone"
                app:tint="?attr/colorOnSurface" />

        </LinearLayout>

        <View
            android:layout_width="match_parent"
            android:layout_height="1dp"
            android:layout_marginStart="16dp"
            android:layout_marginEnd="16dp"
            android:background="?attr/colorOutlineVariant" />

    </LinearLayout>

    <com.google.android.material.tabs.TabLayout
        android:id="@+id/tabLayoutFilters"
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:background="?attr/colorSurface"
        app:tabGravity="start"
        app:tabMode="scrollable"
        app:layout_constraintEnd_toStartOf="@id/buttonSort"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toBottomOf="@id/searchBar">

        <com.google.android.material.tabs.TabItem
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="@string/filter_tab_titles" />

        <com.google.android.material.tabs.TabItem
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="@string/filter_tab_artists" />

        <com.google.android.material.tabs.TabItem
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="@string/filter_tab_albums" />

        <com.google.android.material.tabs.TabItem
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="@string/filter_tab_playlists" />

        <com.google.android.material.tabs.TabItem
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="@string/filter_tab_favorites" />

        <com.google.android.material.tabs.TabItem
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="@string/filter_tab_folders" />

    </com.google.android.material.tabs.TabLayout>

    <ImageButton
        android:id="@+id/buttonSort"
        android:layout_width="48dp"
        android:layout_height="0dp"
        android:background="?attr/colorSurface"
        android:contentDescription="@string/sort_button_description"
        android:foreground="?attr/selectableItemBackgroundBorderless"
        android:src="@drawable/ic_sort"
        app:layout_constraintBottom_toBottomOf="@id/tabLayoutFilters"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintTop_toTopOf="@id/tabLayoutFilters"
        app:tint="?attr/colorOnSurface" />

    <!-- En-tête contextuel : retour + titre (détail d'un dossier / d'une playlist), boutons de lecture -->
    <LinearLayout
        android:id="@+id/headerBar"
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:background="?attr/colorSurface"
        android:orientation="vertical"
        android:visibility="gone"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toBottomOf="@id/tabLayoutFilters"
        tools:visibility="visible">

        <LinearLayout
            android:id="@+id/layoutHeaderTitleRow"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:gravity="center_vertical"
            android:orientation="horizontal"
            android:paddingStart="4dp"
            android:paddingEnd="16dp">

            <ImageButton
                android:id="@+id/buttonHeaderBack"
                android:layout_width="48dp"
                android:layout_height="48dp"
                android:background="?attr/selectableItemBackgroundBorderless"
                android:contentDescription="@string/folder_back_description"
                android:src="@drawable/ic_arrow_back"
                app:tint="?attr/colorOnSurface" />

            <LinearLayout
                android:layout_width="0dp"
                android:layout_height="wrap_content"
                android:layout_marginStart="4dp"
                android:layout_weight="1"
                android:orientation="vertical">

                <TextView
                    android:id="@+id/textHeaderTitle"
                    android:layout_width="match_parent"
                    android:layout_height="wrap_content"
                    android:ellipsize="end"
                    android:maxLines="1"
                    android:textAppearance="?attr/textAppearanceTitleMedium"
                    tools:text="Afrobeat" />

                <TextView
                    android:id="@+id/textHeaderSubtitle"
                    android:layout_width="match_parent"
                    android:layout_height="wrap_content"
                    android:ellipsize="middle"
                    android:maxLines="1"
                    android:textAppearance="?attr/textAppearanceBodyMedium"
                    android:textColor="?attr/colorOnSurfaceVariant"
                    tools:text="12 titres · /Music/Afrobeat/" />

            </LinearLayout>

        </LinearLayout>

        <LinearLayout
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:gravity="center_vertical"
            android:orientation="horizontal"
            android:paddingStart="12dp"
            android:paddingTop="4dp"
            android:paddingEnd="12dp"
            android:paddingBottom="4dp">

            <Button
                android:id="@+id/buttonHeaderPrimary"
                style="@style/Widget.Material3.Button.TonalButton"
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:minHeight="48dp"
                tools:text="Lire le dossier" />

            <Button
                android:id="@+id/buttonHeaderSecondary"
                style="@style/Widget.Material3.Button.TextButton"
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:layout_marginStart="8dp"
                android:minHeight="48dp"
                android:text="@string/playlist_delete_action"
                android:visibility="gone"
                tools:visibility="visible" />

        </LinearLayout>

    </LinearLayout>

    <androidx.recyclerview.widget.RecyclerView
        android:id="@+id/recyclerSongs"
        android:layout_width="0dp"
        android:layout_height="0dp"
        android:clipToPadding="false"
        android:paddingBottom="8dp"
        android:visibility="gone"
        app:layout_constraintBottom_toTopOf="@id/miniPlayer"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toBottomOf="@id/headerBar"
        tools:listitem="@layout/item_song" />

    <ProgressBar
        android:id="@+id/progressLoading"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        app:layout_constraintBottom_toTopOf="@id/miniPlayer"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toBottomOf="@id/headerBar" />

    <TextView
        android:id="@+id/textEmptyState"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_marginStart="32dp"
        android:layout_marginEnd="32dp"
        android:gravity="center"
        android:text="@string/main_placeholder_message"
        android:textAppearance="?attr/textAppearanceBodyLarge"
        android:visibility="gone"
        app:layout_constraintBottom_toTopOf="@id/miniPlayer"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toBottomOf="@id/headerBar" />

    <!-- Écran vide des favoris : message explicatif + bouton vers l'onglet Titres -->
    <LinearLayout
        android:id="@+id/layoutEmptyFavorites"
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:layout_marginStart="32dp"
        android:layout_marginEnd="32dp"
        android:gravity="center_horizontal"
        android:orientation="vertical"
        android:visibility="gone"
        app:layout_constraintBottom_toTopOf="@id/miniPlayer"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toBottomOf="@id/headerBar">

        <ImageView
            android:layout_width="64dp"
            android:layout_height="64dp"
            android:importantForAccessibility="no"
            android:src="@drawable/ic_favorite_border"
            app:tint="?attr/colorOnSurfaceVariant" />

        <TextView
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:layout_marginTop="16dp"
            android:gravity="center"
            android:text="@string/favorites_empty_title"
            android:textAppearance="?attr/textAppearanceTitleMedium" />

        <TextView
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:layout_marginTop="8dp"
            android:gravity="center"
            android:text="@string/favorites_empty_message"
            android:textAppearance="?attr/textAppearanceBodyMedium"
            android:textColor="?attr/colorOnSurfaceVariant" />

        <Button
            android:id="@+id/buttonExploreLibrary"
            style="@style/Widget.Material3.Button.TonalButton"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:layout_marginTop="24dp"
            android:minHeight="48dp"
            android:text="@string/favorites_explore_button" />

    </LinearLayout>

    <com.google.android.material.floatingactionbutton.FloatingActionButton
        android:id="@+id/fabCreatePlaylist"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_marginEnd="16dp"
        android:layout_marginBottom="16dp"
        android:contentDescription="@string/playlist_create_fab_description"
        android:visibility="gone"
        app:layout_constraintBottom_toTopOf="@id/miniPlayer"
        app:layout_constraintEnd_toEndOf="parent"
        app:srcCompat="@drawable/ic_add"
        app:tint="?attr/colorOnPrimaryContainer" />

    <!-- Mini-lecteur : capsule flottante juste au-dessus de la barre de navigation -->
    <include
        android:id="@+id/miniPlayer"
        layout="@layout/layout_mini_player"
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:layout_marginStart="12dp"
        android:layout_marginEnd="12dp"
        android:layout_marginBottom="8dp"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent" />

    <!-- Hôte du grand lecteur coulissant (BottomSheetBehavior) : transparent et sans effet tant que le lecteur est masqué -->
    <androidx.coordinatorlayout.widget.CoordinatorLayout
        android:id="@+id/playerHost"
        android:layout_width="0dp"
        android:layout_height="0dp"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toTopOf="parent">

        <include
            android:id="@+id/playerSheet"
            layout="@layout/layout_player_sheet"
            android:layout_width="match_parent"
            android:layout_height="match_parent"
            app:layout_behavior="com.google.android.material.bottomsheet.BottomSheetBehavior" />

    </androidx.coordinatorlayout.widget.CoordinatorLayout>

</androidx.constraintlayout.widget.ConstraintLayout>
EOF

echo "  -> app/src/main/res/layout/activity_settings.xml"
mkdir -p app/src/main/res/layout
cat << 'EOF' > app/src/main/res/layout/activity_settings.xml
<?xml version="1.0" encoding="utf-8"?>
<androidx.constraintlayout.widget.ConstraintLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="match_parent">

    <com.google.android.material.appbar.MaterialToolbar
        android:id="@+id/toolbar"
        android:layout_width="0dp"
        android:layout_height="?attr/actionBarSize"
        android:background="?attr/colorSurface"
        app:title="@string/settings_title"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toTopOf="parent" />

    <FrameLayout
        android:id="@+id/settingsContainer"
        android:layout_width="0dp"
        android:layout_height="0dp"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toBottomOf="@id/toolbar" />

</androidx.constraintlayout.widget.ConstraintLayout>
EOF

echo "  -> app/src/main/res/layout/layout_mini_player.xml"
mkdir -p app/src/main/res/layout
cat << 'EOF' > app/src/main/res/layout/layout_mini_player.xml
<?xml version="1.0" encoding="utf-8"?>
<!-- Mini-lecteur : capsule flottante aux coins arrondis (pochette, titre, artiste,
     précédent, lecture/pause, suivant, file d'attente). Toucher la capsule ouvre le grand lecteur. -->
<com.google.android.material.card.MaterialCardView xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    xmlns:tools="http://schemas.android.com/tools"
    android:id="@+id/cardMini"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:clickable="true"
    android:focusable="true"
    app:cardBackgroundColor="?attr/colorSurfaceContainerHigh"
    app:cardCornerRadius="28dp"
    app:cardElevation="6dp"
    app:strokeWidth="0dp"
    tools:visibility="visible">

    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="vertical">

        <LinearLayout
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:gravity="center_vertical"
            android:orientation="horizontal"
            android:paddingStart="10dp"
            android:paddingTop="8dp"
            android:paddingEnd="6dp"
            android:paddingBottom="4dp">

            <com.google.android.material.imageview.ShapeableImageView
                android:id="@+id/imageMiniArt"
                android:layout_width="44dp"
                android:layout_height="44dp"
                android:importantForAccessibility="no"
                android:scaleType="centerCrop"
                android:src="@drawable/ic_artwork_default"
                app:shapeAppearanceOverlay="@style/ShapeAppearance.Elg.Rounded" />

            <LinearLayout
                android:layout_width="0dp"
                android:layout_height="wrap_content"
                android:layout_marginStart="10dp"
                android:layout_marginEnd="4dp"
                android:layout_weight="1"
                android:orientation="vertical">

                <TextView
                    android:id="@+id/textMiniTitle"
                    android:layout_width="match_parent"
                    android:layout_height="wrap_content"
                    android:ellipsize="end"
                    android:maxLines="1"
                    android:textAppearance="?attr/textAppearanceTitleSmall"
                    tools:text="Titre en cours de lecture" />

                <TextView
                    android:id="@+id/textMiniArtist"
                    android:layout_width="match_parent"
                    android:layout_height="wrap_content"
                    android:ellipsize="end"
                    android:maxLines="1"
                    android:textAppearance="?attr/textAppearanceBodySmall"
                    android:textColor="?attr/colorOnSurfaceVariant"
                    android:visibility="gone"
                    tools:text="Artiste"
                    tools:visibility="visible" />

            </LinearLayout>

            <ImageButton
                android:id="@+id/buttonMiniPrevious"
                android:layout_width="40dp"
                android:layout_height="48dp"
                android:background="?attr/selectableItemBackgroundBorderless"
                android:contentDescription="@string/mini_player_previous_description"
                android:src="@drawable/ic_skip_previous"
                app:tint="?attr/colorOnSurface" />

            <ImageButton
                android:id="@+id/buttonMiniPlayPause"
                android:layout_width="44dp"
                android:layout_height="48dp"
                android:background="?attr/selectableItemBackgroundBorderless"
                android:contentDescription="@string/mini_player_play_description"
                android:src="@drawable/ic_play_arrow"
                app:tint="?attr/colorOnSurface" />

            <ImageButton
                android:id="@+id/buttonMiniNext"
                android:layout_width="40dp"
                android:layout_height="48dp"
                android:background="?attr/selectableItemBackgroundBorderless"
                android:contentDescription="@string/mini_player_next_description"
                android:src="@drawable/ic_skip_next"
                app:tint="?attr/colorOnSurface" />

            <ImageButton
                android:id="@+id/buttonMiniQueue"
                android:layout_width="40dp"
                android:layout_height="48dp"
                android:background="?attr/selectableItemBackgroundBorderless"
                android:contentDescription="@string/queue_button_description"
                android:src="@drawable/ic_playlist"
                app:tint="?attr/colorOnSurface" />

        </LinearLayout>

        <com.google.android.material.progressindicator.LinearProgressIndicator
            android:id="@+id/progressMini"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:layout_marginStart="20dp"
            android:layout_marginEnd="20dp"
            android:layout_marginBottom="6dp"
            android:max="100"
            app:trackThickness="2dp" />

    </LinearLayout>

</com.google.android.material.card.MaterialCardView>
EOF

echo "  -> app/src/main/res/layout/item_song.xml"
mkdir -p app/src/main/res/layout
cat << 'EOF' > app/src/main/res/layout/item_song.xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    xmlns:tools="http://schemas.android.com/tools"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:background="?attr/selectableItemBackground"
    android:clickable="true"
    android:focusable="true"
    android:gravity="center_vertical"
    android:minHeight="64dp"
    android:orientation="horizontal"
    android:paddingStart="16dp"
    android:paddingEnd="4dp">

    <ImageView
        android:id="@+id/imageAlbumArt"
        android:layout_width="48dp"
        android:layout_height="48dp"
        android:importantForAccessibility="no"
        android:scaleType="centerInside"
        android:src="@drawable/ic_music_note"
        app:tint="?attr/colorOnSurfaceVariant" />

    <LinearLayout
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:layout_marginStart="16dp"
        android:layout_weight="1"
        android:orientation="vertical">

        <TextView
            android:id="@+id/textSongTitle"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:ellipsize="end"
            android:maxLines="1"
            android:textAppearance="?attr/textAppearanceBodyLarge"
            android:textStyle="bold"
            tools:text="Titre du morceau" />

        <TextView
            android:id="@+id/textSongArtist"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:layout_marginTop="2dp"
            android:ellipsize="end"
            android:maxLines="1"
            android:textAppearance="?attr/textAppearanceBodyMedium"
            android:textColor="?attr/colorOnSurfaceVariant"
            android:visibility="gone"
            tools:text="Nom de l'artiste"
            tools:visibility="visible" />

    </LinearLayout>

    <ImageButton
        android:id="@+id/buttonSongMenu"
        android:layout_width="48dp"
        android:layout_height="48dp"
        android:background="?attr/selectableItemBackgroundBorderless"
        android:src="@drawable/ic_more_vert"
        app:tint="?attr/colorOnSurfaceVariant"
        tools:ignore="ContentDescription" />

</LinearLayout>
EOF

echo "  -> app/src/main/res/layout/dialog_about.xml"
mkdir -p app/src/main/res/layout
cat << 'EOF' > app/src/main/res/layout/dialog_about.xml
<?xml version="1.0" encoding="utf-8"?>
<androidx.core.widget.NestedScrollView xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    xmlns:tools="http://schemas.android.com/tools"
    android:layout_width="match_parent"
    android:layout_height="wrap_content">

    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="vertical"
        android:paddingStart="24dp"
        android:paddingTop="24dp"
        android:paddingEnd="24dp"
        android:paddingBottom="32dp">

        <!-- ===== PRÉSENTATION (toujours en haut) ===== -->
        <TextView
            android:id="@+id/textAboutTitle"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="@string/about_title"
            android:textAppearance="?attr/textAppearanceHeadlineSmall" />

        <TextView
            android:id="@+id/textAboutVersion"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:layout_marginStart="-4dp"
            android:layout_marginTop="4dp"
            android:paddingStart="4dp"
            android:paddingEnd="4dp"
            android:textAppearance="?attr/textAppearanceBodyMedium"
            tools:text="Version 1.01" />

        <TextView
            android:id="@+id/textAboutIntro"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:layout_marginTop="16dp"
            android:text="@string/about_intro"
            android:textAppearance="?attr/textAppearanceBodyLarge" />

        <com.google.android.material.divider.MaterialDivider
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:layout_marginTop="20dp" />

        <!-- ===== COORDONNÉES (toujours tout en bas) ===== -->
        <TextView
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:layout_marginTop="20dp"
            android:text="@string/about_section_links"
            android:textAppearance="?attr/textAppearanceLabelLarge" />

        <Button
            android:id="@+id/buttonYoutubeMain"
            style="@style/Widget.Material3.Button.TextButton"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:layout_marginTop="8dp"
            android:minHeight="48dp"
            android:contentDescription="@string/about_cd_youtube_main"
            android:gravity="start|center_vertical"
            android:text="@string/about_label_youtube_main" />

        <Button
            android:id="@+id/buttonYoutubeSecondary"
            style="@style/Widget.Material3.Button.TextButton"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:minHeight="48dp"
            android:contentDescription="@string/about_cd_youtube_secondary"
            android:gravity="start|center_vertical"
            android:text="@string/about_label_youtube_secondary" />

        <Button
            android:id="@+id/buttonFacebook"
            style="@style/Widget.Material3.Button.TextButton"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:minHeight="48dp"
            android:contentDescription="@string/about_cd_facebook"
            android:gravity="start|center_vertical"
            android:text="@string/about_label_facebook" />

        <Button
            android:id="@+id/buttonInstagram"
            style="@style/Widget.Material3.Button.TextButton"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:minHeight="48dp"
            android:contentDescription="@string/about_cd_instagram"
            android:gravity="start|center_vertical"
            android:text="@string/about_label_instagram" />

        <Button
            android:id="@+id/buttonTwitch"
            style="@style/Widget.Material3.Button.TextButton"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:minHeight="48dp"
            android:contentDescription="@string/about_cd_twitch"
            android:gravity="start|center_vertical"
            android:text="@string/about_label_twitch" />

        <Button
            android:id="@+id/buttonEmail"
            style="@style/Widget.Material3.Button.TextButton"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:layout_marginBottom="8dp"
            android:minHeight="48dp"
            android:contentDescription="@string/about_cd_email"
            android:gravity="start|center_vertical"
            android:text="@string/about_label_email" />

    </LinearLayout>

</androidx.core.widget.NestedScrollView>
EOF

echo "  -> app/src/main/java/com/elg/music/data/model/Song.kt"
mkdir -p app/src/main/java/com/elg/music/data/model
cat << 'EOF' > app/src/main/java/com/elg/music/data/model/Song.kt
package com.elg.music.data.model

import android.net.Uri

/**
 * Représente un morceau de musique tel que lu depuis le MediaStore de l'appareil.
 *
 * @param id identifiant MediaStore du morceau (colonne _ID).
 * @param title titre à afficher, déjà nettoyé (extension retirée, "_" remplacés par des espaces,
 *   noms bruts WhatsApp rendus lisibles) ; jamais vide : "Sans titre" si absent des métadonnées.
 * @param artist nom de l'artiste, ou null si absent des métadonnées.
 * @param album nom de l'album, ou null si absent des métadonnées.
 * @param durationMs durée du morceau en millisecondes.
 * @param contentUri Uri content:// permettant de lire/partager/supprimer le fichier.
 * @param albumId identifiant d'album MediaStore, utilisé pour retrouver la pochette.
 * @param dateAddedSeconds date d'ajout du fichier à l'appareil (secondes depuis 1970, colonne
 *   DATE_ADDED), utilisée par le tri « Date d'ajout ». 0 si inconnue.
 * @param folderPath dossier parent d'origine (RELATIVE_PATH du MediaStore, ex. "Music/Afrobeat/") ;
 *   chaîne vide si inconnu. Sert à regrouper les titres dans l'onglet Dossiers.
 * @param trackNumber numéro de piste dans l'album (TRACK du MediaStore ; 1001 = disque 1, piste 1) ;
 *   0 si absent. Sert à ordonner les pistes d'un album.
 * @param mimeType type MIME du fichier (par ex. "audio/midi"), ou null si inconnu.
 */
data class Song(
    val id: Long,
    val title: String,
    val artist: String?,
    val album: String?,
    val durationMs: Long,
    val contentUri: Uri,
    val albumId: Long,
    val dateAddedSeconds: Long = 0L,
    val folderPath: String = "",
    val trackNumber: Int = 0,
    val mimeType: String? = null
) {
    /** Fichier MIDI (.mid / .midi) : lu par le MediaPlayer natif d'Android, pas par ExoPlayer. */
    val isMidi: Boolean
        get() = mimeType?.contains("midi", ignoreCase = true) == true
}
EOF

echo "  -> app/src/main/java/com/elg/music/data/repository/SongRepository.kt"
mkdir -p app/src/main/java/com/elg/music/data/repository
cat << 'EOF' > app/src/main/java/com/elg/music/data/repository/SongRepository.kt
package com.elg.music.data.repository

import android.content.ContentUris
import android.content.Context
import android.provider.MediaStore
import com.elg.music.data.local.ElgDatabase
import com.elg.music.data.model.Song
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.util.Locale

/**
 * Interroge le MediaStore de l'appareil pour construire la bibliothèque musicale.
 *
 * Formats pris en compte : tout fichier marqué « musique » par Android, plus les fichiers dont
 * le type MIME correspond à MP3, WAV, FLAC, M4A, AAC, OGG, OPUS, AMR, WMA ou MIDI (même s'ils ne
 * sont pas marqués « musique »), à l'exception des sonneries, notifications et alarmes.
 *
 * Applique automatiquement deux filtres du cahier des charges (section 5) :
 *  - exclusion stricte des dossiers WhatsApp (notes vocales et audios reçus), Telegram et mémos vocaux ;
 *  - exclusion des fichiers dont la durée est inférieure à [MIN_DURATION_MS].
 *
 * Le titre de chaque morceau est nettoyé par [TitleCleaner] (extension, tirets du bas, noms
 * bruts WhatsApp). Le tri de la liste est assuré par le LibraryViewModel selon le choix de
 * l'utilisateur : cette classe renvoie les morceaux dans l'ordre du MediaStore.
 *
 * Les mots-clés de dossiers exclus couvrent les cas les plus courants ; les noms de
 * dossiers de mémos vocaux variant selon les fabricants, cette liste est prévue pour
 * être complétée depuis les Réglages dans un incrément futur.
 */
class SongRepository(context: Context) {

    private val appContext = context.applicationContext
    private val titleCleaner = TitleCleaner(appContext)

    suspend fun loadLibrary(): List<Song> = withContext(Dispatchers.IO) {
        val songs = mutableListOf<Song>()

        val pathColumn = MediaStore.Audio.Media.RELATIVE_PATH

        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.ALBUM_ID,
            MediaStore.Audio.Media.DATE_ADDED,
            MediaStore.Audio.Media.TRACK,
            MediaStore.Audio.Media.MIME_TYPE,
            pathColumn
        )

        val mimeList = SUPPORTED_MIME_TYPES.joinToString(",") { "'$it'" }
        val selection = "(${MediaStore.Audio.Media.IS_MUSIC} != 0 OR " +
            "(${MediaStore.Audio.Media.MIME_TYPE} IN ($mimeList) AND " +
            "${MediaStore.Audio.Media.IS_RINGTONE} = 0 AND " +
            "${MediaStore.Audio.Media.IS_NOTIFICATION} = 0 AND " +
            "${MediaStore.Audio.Media.IS_ALARM} = 0))"

        appContext.contentResolver.query(
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
            projection,
            selection,
            null,
            null
        )?.use { cursor ->
            val idCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
            val titleCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
            val artistCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)
            val albumCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM)
            val durationCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)
            val albumIdCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM_ID)
            val dateAddedCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DATE_ADDED)
            val trackCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.TRACK)
            val mimeCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.MIME_TYPE)
            val pathCol = cursor.getColumnIndexOrThrow(pathColumn)

            while (cursor.moveToNext()) {
                val durationMs = cursor.getLong(durationCol)
                if (durationMs < MIN_DURATION_MS) continue

                val path = cursor.getString(pathCol)
                if (isFromExcludedFolder(path)) continue

                val id = cursor.getLong(idCol)
                val title = titleCleaner.clean(cursor.getString(titleCol))
                val artist = cursor.getString(artistCol)
                    ?.takeIf { it.isNotBlank() && it != UNKNOWN_ARTIST_TAG }
                val album = cursor.getString(albumCol)?.takeIf { it.isNotBlank() }
                val albumId = cursor.getLong(albumIdCol)
                val dateAddedSeconds = cursor.getLong(dateAddedCol)
                val contentUri = ContentUris.withAppendedId(
                    MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                    id
                )

                songs.add(
                    Song(
                        id = id,
                        title = title,
                        artist = artist,
                        album = album,
                        durationMs = durationMs,
                        contentUri = contentUri,
                        albumId = albumId,
                        dateAddedSeconds = dateAddedSeconds,
                        folderPath = path.orEmpty(),
                        trackNumber = cursor.getInt(trackCol),
                        mimeType = cursor.getString(mimeCol)
                    )
                )
            }
        }

        applyTagOverrides(songs)
    }

    /**
     * Applique les tags de l'éditeur aux formats dont le fichier n'a pas pu être modifié (FLAC, M4A, OGG…) :
     * la bibliothèque affiche alors la dernière saisie, même si le MediaStore relit les anciens tags.
     */
    private suspend fun applyTagOverrides(songs: List<Song>): List<Song> {
        val overrides = try {
            ElgDatabase.get(appContext).tagDao().getAll().filter { !it.fileWritten }.associateBy { it.mediaId }
        } catch (error: Exception) {
            emptyMap()
        }
        if (overrides.isEmpty()) return songs
        return songs.map { song ->
            val row = overrides[song.id] ?: return@map song
            val track = row.trackNumber.toIntOrNull()
            val disc = row.discNumber.toIntOrNull() ?: 0
            song.copy(
                title = row.title.ifBlank { song.title },
                artist = row.artist.ifBlank { null },
                album = row.album.ifBlank { null },
                trackNumber = if (track != null) disc * 1000 + track else song.trackNumber
            )
        }
    }

    private fun isFromExcludedFolder(path: String?): Boolean {
        if (path.isNullOrBlank()) return false
        val lower = path.lowercase(Locale.ROOT)
        return EXCLUDED_FOLDER_KEYWORDS.any { lower.contains(it) }
    }

    companion object {
        private const val MIN_DURATION_MS = 30_000L
        private const val UNKNOWN_ARTIST_TAG = "<unknown>"

        /** Types MIME reconnus : MP3, WAV, FLAC, M4A/ALAC, AAC, OGG, OPUS, AMR, WMA, MIDI, AIFF, AC-3, DTS, APE, WavPack et MKA. */
        private val SUPPORTED_MIME_TYPES = listOf(
            "audio/mpeg", "audio/mp3",
            "audio/x-wav", "audio/wav", "audio/vnd.wave",
            "audio/flac", "audio/x-flac",
            "audio/mp4", "audio/x-m4a", "audio/m4a",
            "audio/aac", "audio/aacp", "audio/x-aac",
            "audio/ogg", "application/ogg",
            "audio/opus",
            "audio/amr", "audio/3gpp", "audio/amr-wb",
            "audio/x-ms-wma",
            "audio/midi", "audio/x-midi", "audio/mid", "audio/sp-midi",
            // v1.5 : formats avancés (AIFF, ALAC, AC-3 / E-AC-3, DTS, APE, WavPack, Matroska / WebM).
            "audio/aiff", "audio/x-aiff", "audio/alac",
            "audio/ac3", "audio/eac3", "audio/vnd.dolby.dd-raw",
            "audio/vnd.dts", "audio/vnd.dts.hd",
            "audio/x-ape", "audio/ape", "audio/x-wavpack",
            "audio/x-matroska", "audio/webm"
        )

        private val EXCLUDED_FOLDER_KEYWORDS = listOf(
            // WhatsApp : ancien emplacement (WhatsApp/Media/...) et nouveau (Android/media/com.whatsapp/...)
            "whatsapp/media/whatsapp voice notes",
            "whatsapp/media/whatsapp audio",
            "whatsapp audio",
            "whatsapp voice notes",
            "com.whatsapp",
            "whatsapp business",
            "telegram",
            "voice recorder",
            "voice memos",
            "callrecord",
            "call recordings"
        )
    }
}
EOF

echo "  -> app/src/main/java/com/elg/music/data/local/LibraryPreferences.kt"
mkdir -p app/src/main/java/com/elg/music/data/local
cat << 'EOF' > app/src/main/java/com/elg/music/data/local/LibraryPreferences.kt
package com.elg.music.data.local

import android.content.Context
import android.net.Uri
import com.elg.music.data.model.SortOrder

/**
 * Stockage léger (SharedPreferences) pour les favoris, la liste noire de morceaux et le
 * critère de tri choisi par l'utilisateur.
 *
 * Volontairement simple pour cet incrément : chaque morceau est identifié par la
 * chaîne de son Uri MediaStore. Une future migration vers une base Room pourra
 * réutiliser cette même interface sans impacter le reste de l'application.
 */
class LibraryPreferences(context: Context) {

    private val prefs = context.applicationContext.getSharedPreferences(
        PREFS_NAME,
        Context.MODE_PRIVATE
    )

    fun isFavorite(uri: Uri): Boolean = getFavorites().contains(uri.toString())

    /** Bascule l'état favori du morceau et renvoie le nouvel état (true = maintenant favori). */
    fun toggleFavorite(uri: Uri): Boolean {
        val current = getFavorites().toMutableSet()
        val key = uri.toString()
        val nowFavorite = if (current.contains(key)) {
            current.remove(key)
            false
        } else {
            current.add(key)
            true
        }
        prefs.edit().putStringSet(KEY_FAVORITES, current).apply()
        return nowFavorite
    }

    fun getFavorites(): Set<String> =
        prefs.getStringSet(KEY_FAVORITES, emptySet()) ?: emptySet()

    fun isBlacklisted(uri: Uri): Boolean = getBlacklist().contains(uri.toString())

    fun addToBlacklist(uri: Uri) {
        val current = getBlacklist().toMutableSet()
        current.add(uri.toString())
        prefs.edit().putStringSet(KEY_BLACKLIST, current).apply()
    }

    fun removeFromBlacklist(uri: Uri) {
        val current = getBlacklist().toMutableSet()
        current.remove(uri.toString())
        prefs.edit().putStringSet(KEY_BLACKLIST, current).apply()
    }

    fun getBlacklist(): Set<String> =
        prefs.getStringSet(KEY_BLACKLIST, emptySet()) ?: emptySet()

    /** Critère de tri enregistré ; [SortOrder.DEFAULT] tant que l'utilisateur n'en a pas choisi. */
    fun getSortOrder(): SortOrder =
        SortOrder.fromStorageKey(prefs.getString(KEY_SORT_ORDER, null))

    fun setSortOrder(order: SortOrder) {
        prefs.edit().putString(KEY_SORT_ORDER, order.storageKey).apply()
    }

    companion object {
        private const val PREFS_NAME = "elg_music_library_prefs"
        private const val KEY_SORT_ORDER = "sort_order"
        private const val KEY_FAVORITES = "favorite_song_uris"
        private const val KEY_BLACKLIST = "blacklisted_song_uris"
    }
}
EOF

echo "  -> app/src/main/java/com/elg/music/playback/PlayerController.kt"
mkdir -p app/src/main/java/com/elg/music/playback
cat << 'EOF' > app/src/main/java/com/elg/music/playback/PlayerController.kt
package com.elg.music.playback

import android.content.ComponentName
import android.content.Context
import android.net.Uri
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.Player
import androidx.media3.session.MediaController
import androidx.media3.session.SessionToken
import com.google.common.util.concurrent.ListenableFuture
import com.google.common.util.concurrent.MoreExecutors
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlin.random.Random

/** Ligne de la file d'attente de lecture. */
data class QueueEntry(val index: Int, val title: String, val artist: String?)

/** État de lecture exposé à l'interface (mini-lecteur et grand lecteur). */
data class PlaybackUiState(
    val isConnected: Boolean = false,
    val isPlaying: Boolean = false,
    /** Identifiant du morceau en cours (identifiant MediaStore sous forme de texte). */
    val mediaId: String? = null,
    val title: String? = null,
    val artist: String? = null,
    /** Uri dont on extrait la pochette du morceau en cours. */
    val artworkUri: Uri? = null,
    val positionMs: Long = 0L,
    val durationMs: Long = 0L,
    /** Un des Player.REPEAT_MODE_* : OFF, ALL (toute la liste) ou ONE (le titre en cours). */
    val repeatMode: Int = Player.REPEAT_MODE_OFF,
    val shuffleEnabled: Boolean = false
)

/**
 * Encapsule la connexion à [MusicPlaybackService] via un [MediaController] Media3.
 *
 * À connecter dans `onStart()` de l'Activity hôte et déconnecter dans `onStop()`,
 * conformément au cycle de vie recommandé par Media3 pour les MediaController.
 */
class PlayerController(context: Context) {

    private val appContext = context.applicationContext

    private var controllerFuture: ListenableFuture<MediaController>? = null
    private var controller: MediaController? = null

    /** Ordre reçu avant la fin de la connexion au service (ex. « Ouvrir avec ») : exécuté dès qu'elle aboutit. */
    private var pendingAction: (MediaController.() -> Unit)? = null

    /** Identifiants de lecture à retirer de la file dès que la connexion au service aboutit. */
    private val pendingRemovals = mutableListOf<String>()

    private val _state = MutableStateFlow(PlaybackUiState())
    val state: StateFlow<PlaybackUiState> = _state.asStateFlow()

    private val playerListener = object : Player.Listener {
        override fun onIsPlayingChanged(isPlaying: Boolean) {
            _state.update { it.copy(isPlaying = isPlaying) }
        }

        override fun onRepeatModeChanged(repeatMode: Int) {
            _state.update { it.copy(repeatMode = repeatMode) }
        }

        override fun onShuffleModeEnabledChanged(shuffleModeEnabled: Boolean) {
            _state.update { it.copy(shuffleEnabled = shuffleModeEnabled) }
        }

        override fun onMediaMetadataChanged(mediaMetadata: MediaMetadata) {
            _state.update {
                it.copy(
                    title = mediaMetadata.title?.toString(),
                    artist = mediaMetadata.artist?.toString()
                )
            }
        }

        override fun onEvents(player: Player, events: Player.Events) {
            // Un seul point de mise à jour : identité, métadonnées et position du morceau en cours,
            // relues ensemble pour ne jamais afficher un titre avec la pochette du précédent.
            _state.update {
                it.copy(
                    mediaId = player.currentMediaItem?.mediaId,
                    title = player.mediaMetadata.title?.toString(),
                    artist = player.mediaMetadata.artist?.toString(),
                    artworkUri = player.mediaMetadata.artworkUri,
                    positionMs = player.currentPosition.coerceAtLeast(0L),
                    durationMs = player.duration.coerceAtLeast(0L)
                )
            }
        }
    }

    fun connect() {
        val sessionToken = SessionToken(appContext, ComponentName(appContext, MusicPlaybackService::class.java))
        val future = MediaController.Builder(appContext, sessionToken).buildAsync()
        controllerFuture = future
        future.addListener({
            val mediaController = future.get()
            controller = mediaController
            mediaController.addListener(playerListener)
            pendingAction?.let { action ->
                pendingAction = null
                mediaController.action()
            }
            if (pendingRemovals.isNotEmpty()) {
                val removals = pendingRemovals.toList()
                pendingRemovals.clear()
                removals.forEach { mediaId -> mediaController.removeQueueItems(mediaId) }
            }
            _state.update {
                it.copy(
                    isConnected = true,
                    isPlaying = mediaController.isPlaying,
                    mediaId = mediaController.currentMediaItem?.mediaId,
                    title = mediaController.mediaMetadata.title?.toString(),
                    artist = mediaController.mediaMetadata.artist?.toString(),
                    artworkUri = mediaController.mediaMetadata.artworkUri,
                    positionMs = mediaController.currentPosition.coerceAtLeast(0L),
                    durationMs = mediaController.duration.coerceAtLeast(0L),
                    repeatMode = mediaController.repeatMode,
                    shuffleEnabled = mediaController.shuffleModeEnabled
                )
            }
        }, MoreExecutors.directExecutor())
    }

    fun disconnect() {
        controller?.removeListener(playerListener)
        controllerFuture?.let { MediaController.releaseFuture(it) }
        controllerFuture = null
        controller = null
        _state.value = PlaybackUiState()
    }

    /** Exécute [action] tout de suite si le service est connecté, sinon dès que la connexion aboutit. */
    private fun runWhenConnected(action: MediaController.() -> Unit) {
        val connected = controller
        if (connected != null) {
            connected.action()
        } else {
            pendingAction = action
        }
    }

    /** Construit la file d'attente à partir des morceaux visibles et lance la lecture à [startIndex]. */
    fun playSongs(mediaItems: List<MediaItem>, startIndex: Int) {
        runWhenConnected {
            setMediaItems(mediaItems, startIndex, 0L)
            prepare()
            play()
        }
    }

    /**
     * Lance la lecture de [mediaItems] en mode aléatoire, à partir d'un titre tiré au sort :
     * active le mode aléatoire (le bouton du mini-lecteur passe à l'état actif) puis lit la liste.
     */
    fun playSongsShuffled(mediaItems: List<MediaItem>) {
        if (mediaItems.isEmpty()) return
        runWhenConnected {
            setShuffleModeEnabled(true)
            setMediaItems(mediaItems, Random.nextInt(mediaItems.size), 0L)
            prepare()
            play()
        }
    }

    /** Bascule le mode aléatoire (activé / désactivé). */
    fun toggleShuffle() {
        controller?.apply {
            setShuffleModeEnabled(!shuffleModeEnabled)
        }
    }

    /**
     * Fait tourner le mode de répétition sur ses trois états :
     * désactivé → toute la liste → le titre en cours → désactivé.
     */
    fun cycleRepeatMode() {
        controller?.apply {
            val next = when (repeatMode) {
                Player.REPEAT_MODE_OFF -> Player.REPEAT_MODE_ALL
                Player.REPEAT_MODE_ALL -> Player.REPEAT_MODE_ONE
                else -> Player.REPEAT_MODE_OFF
            }
            setRepeatMode(next)
        }
    }

    fun togglePlayPause() {
        controller?.apply {
            if (isPlaying) pause() else play()
        }
    }

    /** Déplace la lecture à [positionMs] dans le morceau courant (barre de progression du grand lecteur). */
    fun seekTo(positionMs: Long) {
        controller?.seekTo(positionMs.coerceAtLeast(0L))
    }

    /** Photo de la file d'attente, dans l'ordre de la liste (et non dans l'ordre aléatoire). */
    fun queueSnapshot(): List<QueueEntry> {
        val mediaController = controller ?: return emptyList()
        return (0 until mediaController.mediaItemCount).map { index ->
            val metadata = mediaController.getMediaItemAt(index).mediaMetadata
            QueueEntry(
                index = index,
                title = metadata.title?.toString().orEmpty(),
                artist = metadata.artist?.toString()
            )
        }
    }

    fun currentQueueIndex(): Int = controller?.currentMediaItemIndex ?: 0

    /** Saute au morceau [index] de la file d'attente et le lit. */
    fun playQueueItem(index: Int) {
        controller?.apply {
            seekTo(index, 0L)
            play()
        }
    }

    /**
     * Retire de la file d'attente le morceau [mediaId] (par ex. après sa suppression du stockage).
     * Si c'est le morceau en cours, ExoPlayer passe aussitôt au suivant ; sans connexion au
     * service, le retrait est fait dès que la connexion aboutit.
     */
    fun removeFromQueue(mediaId: String) {
        val connected = controller
        if (connected == null) {
            pendingRemovals.add(mediaId)
        } else {
            connected.removeQueueItems(mediaId)
        }
    }

    private fun MediaController.removeQueueItems(mediaId: String) {
        for (index in mediaItemCount - 1 downTo 0) {
            if (getMediaItemAt(index).mediaId == mediaId) removeMediaItem(index)
        }
    }

    /** Vrai si la lecture du morceau en cours de modification doit reprendre une fois les tags écrits. */
    private var resumeAfterEdit = false

    /**
     * À appeler avant de réécrire le fichier d'un morceau (éditeur de tags) : si ce morceau est en cours
     * de lecture, la lecture est suspendue le temps de l'écriture.
     */
    fun pauseForFileEdit(mediaId: String) {
        val mediaController = controller ?: return
        resumeAfterEdit = mediaController.isPlaying && mediaController.currentMediaItem?.mediaId == mediaId
        if (resumeAfterEdit) mediaController.pause()
    }

    /** Édition abandonnée ou échouée : reprend la lecture si elle avait été suspendue. */
    fun cancelFileEdit() {
        if (resumeAfterEdit) controller?.play()
        resumeAfterEdit = false
    }

    /**
     * Répercute de nouveaux titre / artiste / album sur les entrées de la file d'attente. Si le fichier a
     * été réécrit ([reloadSource]), la file est rechargée à l'identique (même morceau, même position) pour
     * que le lecteur relise le fichier modifié ; sinon seules les métadonnées sont remplacées, sans coupure.
     */
    fun applyEditedMetadata(
        mediaId: String,
        title: String,
        artist: String?,
        album: String?,
        reloadSource: Boolean
    ) {
        val mediaController = controller
        if (mediaController == null) {
            resumeAfterEdit = false
            return
        }
        val count = mediaController.mediaItemCount
        val indexes = (0 until count).filter { mediaController.getMediaItemAt(it).mediaId == mediaId }
        if (indexes.isNotEmpty()) {
            fun updated(item: MediaItem): MediaItem = item.buildUpon()
                .setMediaMetadata(
                    item.mediaMetadata.buildUpon()
                        .setTitle(title)
                        .setArtist(artist)
                        .setAlbumTitle(album)
                        .build()
                )
                .build()
            if (reloadSource) {
                val currentIndex = mediaController.currentMediaItemIndex
                val position = mediaController.currentPosition.coerceAtLeast(0L)
                val items = (0 until count).map { index ->
                    val item = mediaController.getMediaItemAt(index)
                    if (index in indexes) updated(item) else item
                }
                mediaController.setMediaItems(items, currentIndex, position)
                mediaController.prepare()
            } else {
                indexes.forEach { index ->
                    mediaController.replaceMediaItem(index, updated(mediaController.getMediaItemAt(index)))
                }
            }
        }
        if (resumeAfterEdit) mediaController.play()
        resumeAfterEdit = false
    }

    fun skipToNext() {
        controller?.seekToNextMediaItem()
    }

    fun skipToPrevious() {
        controller?.seekToPreviousMediaItem()
    }

    /**
     * Avance la lecture d'un pas (5 s) via COMMAND_SEEK_FORWARD (appui long « Suivant » du mini-lecteur et du grand lecteur).
     * Le pas est celui d'ExoPlayer (`setSeekForwardIncrementMs(5000)`), partagé avec l'écran de verrouillage et la notification.
     */
    fun seekForward(@Suppress("UNUSED_PARAMETER") stepMs: Long = SEEK_STEP_MS) {
        controller?.seekForward()
    }

    /** Recule la lecture d'un pas (5 s) via COMMAND_SEEK_BACK (appui long « Précédent »). */
    fun seekBackward(@Suppress("UNUSED_PARAMETER") stepMs: Long = SEEK_STEP_MS) {
        controller?.seekBack()
    }

    /** À appeler périodiquement (ex. toutes les 500 ms) pour rafraîchir la barre de progression. */
    fun refreshProgress() {
        val mediaController = controller ?: return
        _state.update {
            it.copy(
                positionMs = mediaController.currentPosition.coerceAtLeast(0L),
                durationMs = mediaController.duration.coerceAtLeast(0L)
            )
        }
    }

    companion object {
        /** Pas de saut unifié (avance / retour), en millisecondes. */
        const val SEEK_STEP_MS = 5_000L
    }
}
EOF

echo "  -> app/src/main/java/com/elg/music/playback/MusicPlaybackService.kt"
mkdir -p app/src/main/java/com/elg/music/playback
cat << 'EOF' > app/src/main/java/com/elg/music/playback/MusicPlaybackService.kt
package com.elg.music.playback

import android.app.PendingIntent
import android.content.Intent
import android.view.KeyEvent
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.session.MediaSession
import androidx.media3.session.MediaSessionService
import com.elg.music.data.local.PlaybackStateStore
import com.elg.music.data.local.SavedPlayback
import com.elg.music.data.repository.SongRepository
import com.elg.music.ui.main.MainActivity
import com.google.common.util.concurrent.Futures
import com.google.common.util.concurrent.ListenableFuture
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * Service de lecture en arrière-plan (Media3).
 *
 * Héberge l'[ExoPlayer] et la [MediaSession] associée : la notification de lecture
 * (contrôles + écran de verrouillage) est gérée automatiquement par Media3 dès que
 * la session est active, sans code de notification supplémentaire à écrire ici.
 *
 * La lecture est mise en pause automatiquement au débranchement du casque filaire ou
 * Bluetooth grâce à `setHandleAudioBecomingNoisy(true)`.
 *
 * La pochette de la notification et de l'écran de verrouillage vient d'[ArtworkBitmapLoader],
 * qui renvoie une pochette par défaut quand le fichier n'en contient pas.
 *
 * Les fichiers MIDI, que ExoPlayer ne décode pas, sont pris en charge par [MidiCompanion] et
 * [MidiSupport] : ils sont lus par le MediaPlayer natif d'Android.
 *
 * [AudioEffectsController] applique en direct les réglages de l'écran « Audio & effets » :
 * vitesse, pitch, égaliseur, bass boost et virtualizer.
 *
 * v1.5 : le pas de recherche ExoPlayer est fixé à 5 s (avance / retour) ; toutes les commandes COMMAND_SEEK_BACK et
 * COMMAND_SEEK_FORWARD (écran de verrouillage, notification, grand lecteur, mini-lecteur) l'utilisent donc.
 * La file d'attente, le morceau et la position sont sauvegardés dans le DataStore ([PlaybackStateStore]) et rechargés
 * en pause au démarrage du service. Les boutons physiques (écouteurs filaires, Bluetooth, geste TalkBack à deux doigts)
 * relancent la lecture même si l'application est fermée : le `MediaButtonReceiver` du manifeste démarre ce service.
 *
 * [SleepTimerController] (minuteur de sommeil avec fondu sonore) et [AbLoopController] (boucle A-B)
 * vivent aussi dans ce service : ils agissent sur la lecture même quand l'application est fermée.
 */
class MusicPlaybackService : MediaSessionService() {

    private var mediaSession: MediaSession? = null
    private var artworkLoader: ArtworkBitmapLoader? = null
    private var midiCompanion: MidiCompanion? = null
    private var audioEffects: AudioEffectsController? = null
    private var sleepTimer: SleepTimerController? = null
    private var abLoop: AbLoopController? = null

    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private lateinit var playbackStore: PlaybackStateStore
    private var restoreJob: Job? = null
    private var restoreFinished = false
    private var playWhenRestored = false
    private var periodicSaveJob: Job? = null

    override fun onCreate() {
        super.onCreate()

        val audioAttributes = AudioAttributes.Builder()
            .setUsage(C.USAGE_MEDIA)
            .setContentType(C.AUDIO_CONTENT_TYPE_MUSIC)
            .build()

        val player = ExoPlayer.Builder(this)
            .setAudioAttributes(audioAttributes, /* handleAudioFocus= */ true)
            .setHandleAudioBecomingNoisy(true)
            // Saut unifié de 5 s : pas de recherche commun à toutes les commandes COMMAND_SEEK_BACK / COMMAND_SEEK_FORWARD.
            .setSeekBackIncrementMs(SEEK_INCREMENT_MS)
            .setSeekForwardIncrementMs(SEEK_INCREMENT_MS)
            .build()
        playbackStore = PlaybackStateStore(this)

        val sessionActivityPendingIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE
        )

        val bitmapLoader = ArtworkBitmapLoader(this)
        artworkLoader = bitmapLoader

        val companion = MidiCompanion(this, player)
        companion.attach()
        midiCompanion = companion

        val effects = AudioEffectsController(this, player)
        effects.attach()
        audioEffects = effects

        val timer = SleepTimerController(this, player)
        timer.attach()
        sleepTimer = timer

        val loop = AbLoopController(player)
        loop.attach()
        abLoop = loop

        val sessionCallback = object : MediaSession.Callback {
            override fun onAddMediaItems(
                mediaSession: MediaSession,
                controller: MediaSession.ControllerInfo,
                mediaItems: MutableList<MediaItem>
            ): ListenableFuture<MutableList<MediaItem>> {
                val prepared = MidiSupport.replaceMidiWithSilence(this@MusicPlaybackService, mediaItems)
                return Futures.immediateFuture(prepared.toMutableList())
            }
        }

        mediaSession = MediaSession.Builder(this, player)
            .setSessionActivity(sessionActivityPendingIntent)
            .setBitmapLoader(bitmapLoader)
            .setCallback(sessionCallback)
            .build()

        attachPersistence(player)
        restoreLastPlayback(player)
    }

    // ===================== Mini-lecteur persistant =====================

    /** Photo de l'état de lecture à sauvegarder, ou null si la file d'attente est vide. */
    private fun snapshot(player: Player): SavedPlayback? {
        val count = player.mediaItemCount
        if (count == 0) return null
        val ids = (0 until count).mapNotNull { player.getMediaItemAt(it).mediaId.toLongOrNull() }
        if (ids.size != count) return null
        val index = player.currentMediaItemIndex.coerceIn(0, count - 1)
        return SavedPlayback(ids[index], player.currentPosition.coerceAtLeast(0L), ids, index)
    }

    private fun saveNow(player: Player) {
        val state = snapshot(player) ?: return
        serviceScope.launch(Dispatchers.IO) { runCatching { playbackStore.save(state) } }
    }

    private fun attachPersistence(player: Player) {
        player.addListener(object : Player.Listener {
            override fun onMediaItemTransition(mediaItem: MediaItem?, reason: Int) = saveNow(player)

            override fun onTimelineChanged(timeline: androidx.media3.common.Timeline, reason: Int) {
                if (restoreFinished) saveNow(player)
            }

            override fun onIsPlayingChanged(isPlaying: Boolean) {
                saveNow(player)
                periodicSaveJob?.cancel()
                if (isPlaying) {
                    periodicSaveJob = serviceScope.launch {
                        while (true) {
                            delay(SAVE_INTERVAL_MS)
                            saveNow(player)
                        }
                    }
                }
            }

            override fun onPositionDiscontinuity(
                oldPosition: Player.PositionInfo,
                newPosition: Player.PositionInfo,
                reason: Int
            ) {
                if (reason == Player.DISCONTINUITY_REASON_SEEK) saveNow(player)
            }
        })
    }

    /** Recharge la dernière file d'attente en pause (si l'utilisateur n'a rien lancé entre-temps). */
    private fun restoreLastPlayback(player: Player) {
        restoreJob = serviceScope.launch {
            try {
                val saved = playbackStore.load()
                if (saved != null && player.mediaItemCount == 0) {
                    val library = SongRepository(this@MusicPlaybackService).loadLibrary().associateBy { it.id }
                    val songs = saved.queueIds.mapNotNull { library[it] }
                    if (songs.isNotEmpty() && player.mediaItemCount == 0) {
                        val items = MidiSupport.replaceMidiWithSilence(
                            this@MusicPlaybackService,
                            songs.map(MediaItemFactory::fromSong)
                        )
                        val foundIndex = songs.indexOfFirst { it.id == saved.lastSongId }
                        val startIndex = foundIndex.coerceAtLeast(0)
                        val position = if (foundIndex >= 0) saved.lastPositionMs else 0L
                        player.setMediaItems(items, startIndex, position)
                        player.playWhenReady = false
                        player.prepare()
                    }
                }
            } catch (error: Exception) {
                // Permission audio absente ou bibliothèque illisible : le mini-lecteur restera masqué jusqu'à la prochaine lecture.
            } finally {
                restoreFinished = true
                if (playWhenRestored && player.mediaItemCount > 0) player.play()
                playWhenRestored = false
            }
        }
    }

    /**
     * Boutons physiques (écouteurs filaires, Bluetooth, geste TalkBack à deux doigts = KEYCODE_MEDIA_PLAY_PAUSE) reçus
     * alors que la file d'attente n'est pas encore rechargée : la lecture démarre dès que la restauration est terminée.
     */
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == Intent.ACTION_MEDIA_BUTTON) {
            val key = intent.getParcelableExtra(Intent.EXTRA_KEY_EVENT, KeyEvent::class.java)
            val isPlayKey = key != null && key.action == KeyEvent.ACTION_DOWN && key.keyCode in PLAY_KEYS
            val player = mediaSession?.player
            if (isPlayKey && player != null && !restoreFinished && player.mediaItemCount == 0) {
                playWhenRestored = true
            }
        }
        return super.onStartCommand(intent, flags, startId)
    }

    override fun onGetSession(controllerInfo: MediaSession.ControllerInfo): MediaSession? {
        return mediaSession
    }

    /** Arrête le service si rien ne joue lorsque l'utilisateur retire l'app des tâches récentes. */
    override fun onTaskRemoved(rootIntent: Intent?) {
        val session = mediaSession ?: return
        saveNow(session.player)
        if (!session.player.playWhenReady || session.player.mediaItemCount == 0) {
            stopSelf()
        }
    }

    override fun onDestroy() {
        mediaSession?.player?.let { player ->
            // Dernière sauvegarde, dans une portée indépendante pour qu'elle survive à l'arrêt du service.
            snapshot(player)?.let { state ->
                CoroutineScope(SupervisorJob() + Dispatchers.IO).launch { runCatching { playbackStore.save(state) } }
            }
        }
        periodicSaveJob?.cancel()
        restoreJob?.cancel()
        serviceScope.cancel()
        abLoop?.release()
        abLoop = null
        sleepTimer?.release()
        sleepTimer = null
        audioEffects?.release()
        audioEffects = null
        midiCompanion?.release()
        midiCompanion = null
        mediaSession?.let { session ->
            session.player.release()
            session.release()
        }
        mediaSession = null
        artworkLoader?.release()
        artworkLoader = null
        super.onDestroy()
    }

    private companion object {
        const val SEEK_INCREMENT_MS = 5_000L
        const val SAVE_INTERVAL_MS = 5_000L
        val PLAY_KEYS = setOf(
            KeyEvent.KEYCODE_MEDIA_PLAY,
            KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE,
            KeyEvent.KEYCODE_HEADSETHOOK
        )
    }
}
EOF

echo "  -> app/src/main/java/com/elg/music/ui/main/LibraryViewModel.kt"
mkdir -p app/src/main/java/com/elg/music/ui/main
cat << 'EOF' > app/src/main/java/com/elg/music/ui/main/LibraryViewModel.kt
package com.elg.music.ui.main

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.elg.music.R
import com.elg.music.data.local.LibraryPreferences
import com.elg.music.data.local.PlaylistStore
import com.elg.music.data.model.AlbumItem
import com.elg.music.data.model.ArtistItem
import com.elg.music.data.model.FolderItem
import com.elg.music.data.model.Playlist
import com.elg.music.data.model.PlaylistSummary
import com.elg.music.data.model.Song
import com.elg.music.data.model.SortOrder
import com.elg.music.data.repository.SongRepository
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.text.CollationKey
import java.text.Collator
import java.util.Locale

/** Onglet sélectionné dans la barre de filtres. */
enum class LibraryFilter { TITRES, ARTISTES, ALBUMS, PLAYLISTS, FAVORIS, DOSSIERS }

/** Écran réellement affiché : un onglet, ou le détail d'un artiste / album / dossier / playlist ouvert. */
enum class LibraryScreen {
    SONGS, FAVORITES,
    ARTIST_LIST, ARTIST_DETAIL,
    ALBUM_LIST, ALBUM_DETAIL,
    FOLDER_LIST, FOLDER_DETAIL,
    PLAYLIST_LIST, PLAYLIST_DETAIL
}

enum class CreatePlaylistResult { CREATED, EMPTY_NAME, DUPLICATE_NAME }

enum class AddToPlaylistResult { ADDED, ALREADY_PRESENT }

/**
 * État affiché par [MainActivity]. Il est toujours cohérent : la liste affichée, le critère de tri
 * et l'onglet proviennent d'un même calcul.
 *
 * [allSongs] est la bibliothèque complète (hors liste noire), déjà triée selon [sortOrder].
 * Les champs `visible*` et `open*` sont dérivés : selon l'écran, seuls certains sont renseignés ;
 * [visibleSongs] est toujours la liste de morceaux que touche l'utilisateur (Titres, Favoris, ou
 * contenu d'un artiste, album, dossier ou playlist ouvert).
 */
data class LibraryUiState(
    val isLoading: Boolean = true,
    val allSongs: List<Song> = emptyList(),
    val playlists: List<Playlist> = emptyList(),
    val searchQuery: String = "",
    val activeFilter: LibraryFilter = LibraryFilter.TITRES,
    val sortOrder: SortOrder = SortOrder.DEFAULT,
    val openFolderPath: String? = null,
    val openPlaylistId: String? = null,
    val openArtistKey: String? = null,
    val openAlbumKey: String? = null,
    val visibleSongs: List<Song> = emptyList(),
    val visibleFolders: List<FolderItem> = emptyList(),
    val visiblePlaylists: List<PlaylistSummary> = emptyList(),
    val visibleArtists: List<ArtistItem> = emptyList(),
    val visibleAlbums: List<AlbumItem> = emptyList(),
    val openFolder: FolderItem? = null,
    val openPlaylist: PlaylistSummary? = null,
    val openArtist: ArtistItem? = null,
    val openAlbum: AlbumItem? = null,
    val favoriteCount: Int = 0
) {
    val screen: LibraryScreen
        get() = when (activeFilter) {
            LibraryFilter.TITRES -> LibraryScreen.SONGS
            LibraryFilter.FAVORIS -> LibraryScreen.FAVORITES
            LibraryFilter.ARTISTES ->
                if (openArtistKey != null) LibraryScreen.ARTIST_DETAIL else LibraryScreen.ARTIST_LIST
            LibraryFilter.ALBUMS ->
                if (openAlbumKey != null) LibraryScreen.ALBUM_DETAIL else LibraryScreen.ALBUM_LIST
            LibraryFilter.DOSSIERS ->
                if (openFolderPath != null) LibraryScreen.FOLDER_DETAIL else LibraryScreen.FOLDER_LIST
            LibraryFilter.PLAYLISTS ->
                if (openPlaylistId != null) LibraryScreen.PLAYLIST_DETAIL else LibraryScreen.PLAYLIST_LIST
        }

    val isInDetailView: Boolean
        get() = screen == LibraryScreen.ARTIST_DETAIL || screen == LibraryScreen.ALBUM_DETAIL ||
            screen == LibraryScreen.FOLDER_DETAIL || screen == LibraryScreen.PLAYLIST_DETAIL
}

/**
 * Cerveau de l'écran principal, en flux réactif.
 *
 * Toutes les entrées (bibliothèque, playlists, recherche, onglet, dossier/album/artiste/playlist
 * ouvert, critère de tri, révision des favoris) sont réunies dans [inputs]. Chaque modification
 * déclenche UN calcul complet sur un thread d'arrière-plan (tri, regroupements, filtres), et le
 * résultat est publié en une seule fois dans [uiState] : l'écran ne voit jamais un état à moitié
 * appliqué, et le thread principal ne fait aucun tri. Si plusieurs modifications arrivent pendant
 * un calcul, seule la plus récente est calculée ensuite.
 */
class LibraryViewModel(application: Application) : AndroidViewModel(application) {

    private val appContext = application
    private val repository = SongRepository(application)
    private val libraryPreferences = LibraryPreferences(application)
    private val playlistStore = PlaylistStore(application)

    /** Entrées du calcul. `songs == null` signifie « chargement en cours ». */
    private data class Inputs(
        val songs: List<Song>? = null,
        val playlists: List<Playlist> = emptyList(),
        val searchQuery: String = "",
        val filter: LibraryFilter = LibraryFilter.TITRES,
        val sortOrder: SortOrder = SortOrder.DEFAULT,
        val openFolderPath: String? = null,
        val openPlaylistId: String? = null,
        val openArtistKey: String? = null,
        val openAlbumKey: String? = null,
        val favoritesRevision: Int = 0
    )

    private class KeyedSong(
        val song: Song,
        val titleKey: CollationKey,
        val artistKey: CollationKey,
        val albumKey: CollationKey
    )

    private class KeyedCache(val source: List<Song>, val keyed: List<KeyedSong>)

    private class SortCache(val source: List<Song>, val order: SortOrder, val result: List<Song>)

    // Caches déclarés AVANT uiState : le calcul démarre dès la création du flux.
    @Volatile
    private var keyedCache: KeyedCache? = null

    @Volatile
    private var sortCache: SortCache? = null

    private val inputs = MutableStateFlow(Inputs(sortOrder = libraryPreferences.getSortOrder()))

    val uiState: StateFlow<LibraryUiState> = inputs
        .map { compute(it) }
        .flowOn(Dispatchers.Default)
        .stateIn(
            viewModelScope,
            SharingStarted.Eagerly,
            LibraryUiState(sortOrder = inputs.value.sortOrder)
        )

    // ===================== Chargement =====================

    /** Lance (ou relance) le chargement complet de la bibliothèque depuis le MediaStore. */
    fun loadLibrary() {
        viewModelScope.launch {
            try {
                val loaded = withContext(Dispatchers.Default) {
                    repository.loadLibrary()
                        .filterNot { libraryPreferences.isBlacklisted(it.contentUri) }
                }
                inputs.update { it.copy(songs = loaded, playlists = loadPlaylists()) }
            } catch (cancellation: CancellationException) {
                throw cancellation
            } catch (error: Exception) {
                onLibraryUnavailable()
            }
        }
    }

    /** Arrête l'indicateur de chargement quand la bibliothèque ne peut pas être lue (permission refusée, erreur). */
    fun onLibraryUnavailable() {
        inputs.update { it.copy(songs = emptyList()) }
    }

    // ===================== Recherche, onglets, tri =====================

    fun onSearchQueryChanged(query: String) {
        inputs.update { it.copy(searchQuery = query) }
    }

    /** Change d'onglet. Quitte au passage le détail éventuellement ouvert. Sans effet si c'est déjà l'onglet actif. */
    fun onFilterSelected(filter: LibraryFilter) {
        inputs.update { current ->
            if (filter == current.filter) {
                current
            } else {
                current.copy(
                    filter = filter,
                    openFolderPath = null,
                    openPlaylistId = null,
                    openArtistKey = null,
                    openAlbumKey = null
                )
            }
        }
    }

    /** Critère de tri en vigueur (lu directement, sans attendre le calcul de l'affichage). */
    fun currentSortOrder(): SortOrder = inputs.value.sortOrder

    /**
     * Applique un nouveau critère de tri : l'enregistre pour les prochains lancements et déclenche
     * le recalcul en arrière-plan. Sans effet si le critère est déjà actif.
     */
    fun onSortOrderSelected(order: SortOrder) {
        if (order == inputs.value.sortOrder) return
        libraryPreferences.setSortOrder(order)
        inputs.update { it.copy(sortOrder = order) }
    }

    // ===================== Ouverture / fermeture des détails =====================

    fun openFolder(path: String) {
        inputs.update { it.copy(openFolderPath = path) }
    }

    fun openArtist(key: String) {
        inputs.update { it.copy(openArtistKey = key) }
    }

    fun openAlbum(key: String) {
        inputs.update { it.copy(openAlbumKey = key) }
    }

    fun openPlaylist(playlistId: String) {
        inputs.update { it.copy(openPlaylistId = playlistId) }
    }

    /** Revient de la vue détaillée à la liste de l'onglet. */
    fun closeDetail() {
        inputs.update {
            it.copy(openFolderPath = null, openPlaylistId = null, openArtistKey = null, openAlbumKey = null)
        }
    }

    // ===================== Favoris =====================

    fun isFavorite(song: Song): Boolean = libraryPreferences.isFavorite(song.contentUri)

    /** Bascule le statut favori, rafraîchit les vues concernées, et renvoie le nouvel état. */
    fun toggleFavorite(song: Song): Boolean {
        val nowFavorite = libraryPreferences.toggleFavorite(song.contentUri)
        inputs.update { it.copy(favoritesRevision = it.favoritesRevision + 1) }
        return nowFavorite
    }

    // ===================== Playlists =====================

    /** Playlists actuelles, triées par nom (lues directement, pour les boîtes de dialogue). */
    fun currentPlaylists(): List<Playlist> = inputs.value.playlists

    /**
     * Crée une playlist. Refuse un nom vide ou déjà utilisé (sans tenir compte de la casse).
     * Si [songToAdd] est fourni, le morceau est ajouté d'emblée à la nouvelle playlist.
     */
    fun createPlaylist(name: String, songToAdd: Song? = null): CreatePlaylistResult {
        val trimmed = name.trim()
        if (trimmed.isEmpty()) return CreatePlaylistResult.EMPTY_NAME
        val nameTaken = inputs.value.playlists.any { it.name.equals(trimmed, ignoreCase = true) }
        if (nameTaken) return CreatePlaylistResult.DUPLICATE_NAME

        val playlist = playlistStore.create(trimmed)
        if (songToAdd != null) {
            playlistStore.addSong(playlist.id, songToAdd.contentUri)
        }
        refreshPlaylists()
        return CreatePlaylistResult.CREATED
    }

    fun addSongToPlaylist(playlistId: String, song: Song): AddToPlaylistResult {
        val added = playlistStore.addSong(playlistId, song.contentUri)
        refreshPlaylists()
        return if (added) AddToPlaylistResult.ADDED else AddToPlaylistResult.ALREADY_PRESENT
    }

    /** Retire le morceau de la playlist actuellement ouverte. */
    fun removeSongFromOpenPlaylist(song: Song) {
        val playlistId = inputs.value.openPlaylistId ?: return
        playlistStore.removeSong(playlistId, song.contentUri)
        refreshPlaylists()
    }

    fun deletePlaylist(playlistId: String) {
        playlistStore.delete(playlistId)
        inputs.update { current ->
            current.copy(
                playlists = loadPlaylists(),
                openPlaylistId = if (current.openPlaylistId == playlistId) null else current.openPlaylistId
            )
        }
    }

    private fun refreshPlaylists() {
        inputs.update { it.copy(playlists = loadPlaylists()) }
    }

    private fun loadPlaylists(): List<Playlist> {
        val collator = newCollator()
        return playlistStore.getAll().sortedBy { collator.getCollationKey(it.name) }
    }

    // ===================== Actions sur les morceaux =====================

    /** Retrouve un morceau de la bibliothèque par son identifiant de lecture (mediaId), ou null. */
    fun findSong(mediaId: String?): Song? =
        if (mediaId == null) null else uiState.value.allSongs.firstOrNull { it.id.toString() == mediaId }

    /**
     * Morceaux lus par le bouton d'en-tête de l'écran courant, indépendamment de la recherche :
     * tous les favoris, ou tout l'artiste / album / dossier / playlist ouvert.
     */
    fun songsForBulkPlay(): List<Song> {
        val state = uiState.value
        return when (state.screen) {
            LibraryScreen.FAVORITES ->
                state.allSongs.filter { libraryPreferences.isFavorite(it.contentUri) }
            LibraryScreen.ARTIST_DETAIL ->
                state.allSongs.filter { artistKeyOf(it) == state.openArtistKey }
            LibraryScreen.ALBUM_DETAIL ->
                state.allSongs.filter { albumKeyOf(it) == state.openAlbumKey }
                    .sortedBy { trackSortValue(it) }
            LibraryScreen.FOLDER_DETAIL ->
                state.allSongs.filter { it.folderPath == state.openFolderPath }
            LibraryScreen.PLAYLIST_DETAIL -> playlistSongs(state.allSongs, state.playlists, state.openPlaylistId)
            else -> emptyList()
        }
    }

    /** Ajoute le morceau à la liste noire et le retire immédiatement de la vue. */
    fun blacklistSong(song: Song) {
        libraryPreferences.addToBlacklist(song.contentUri)
        removeSongLocally(song)
    }

    /** Retire le morceau de la bibliothèque affichée (par ex. après suppression physique confirmée). */
    fun removeSongLocally(song: Song) {
        inputs.update { current ->
            current.copy(songs = current.songs?.filterNot { it.id == song.id })
        }
    }

    // ===================== Calcul de l'état affiché (thread d'arrière-plan) =====================

    private fun newCollator(): Collator =
        Collator.getInstance(Locale.getDefault()).apply { strength = Collator.SECONDARY }

    private fun compute(input: Inputs): LibraryUiState {
        val loaded = input.songs
        val allSongs = if (loaded == null) emptyList() else sortedSongs(loaded, input.sortOrder)
        val query = input.searchQuery.trim()
        val songMatches: (Song) -> Boolean = { song ->
            query.isEmpty() ||
                song.title.contains(query, ignoreCase = true) ||
                song.artist?.contains(query, ignoreCase = true) == true
        }
        val base = LibraryUiState(
            isLoading = loaded == null,
            allSongs = allSongs,
            playlists = input.playlists,
            searchQuery = input.searchQuery,
            activeFilter = input.filter,
            sortOrder = input.sortOrder
        )

        return when (input.filter) {
            LibraryFilter.TITRES ->
                base.copy(visibleSongs = allSongs.filter(songMatches))

            LibraryFilter.FAVORIS -> {
                val favorites = allSongs.filter { libraryPreferences.isFavorite(it.contentUri) }
                base.copy(visibleSongs = favorites.filter(songMatches), favoriteCount = favorites.size)
            }

            LibraryFilter.ARTISTES -> {
                val artists = buildArtists(allSongs)
                val open = input.openArtistKey?.let { key -> artists.firstOrNull { it.key == key } }
                if (open != null) {
                    base.copy(
                        openArtistKey = open.key,
                        openArtist = open,
                        visibleSongs = allSongs.filter { artistKeyOf(it) == open.key }.filter(songMatches)
                    )
                } else {
                    base.copy(
                        visibleArtists = artists.filter { query.isEmpty() || it.name.contains(query, ignoreCase = true) }
                    )
                }
            }

            LibraryFilter.ALBUMS -> {
                val albums = buildAlbums(allSongs)
                val open = input.openAlbumKey?.let { key -> albums.firstOrNull { it.key == key } }
                if (open != null) {
                    base.copy(
                        openAlbumKey = open.key,
                        openAlbum = open,
                        visibleSongs = allSongs
                            .filter { albumKeyOf(it) == open.key }
                            .sortedBy { trackSortValue(it) }
                            .filter(songMatches)
                    )
                } else {
                    base.copy(
                        visibleAlbums = albums.filter { album ->
                            query.isEmpty() ||
                                album.title.contains(query, ignoreCase = true) ||
                                album.artistName.contains(query, ignoreCase = true)
                        }
                    )
                }
            }

            LibraryFilter.DOSSIERS -> {
                val folders = buildFolders(allSongs)
                val open = input.openFolderPath?.let { path -> folders.firstOrNull { it.path == path } }
                if (open != null) {
                    base.copy(
                        openFolderPath = open.path,
                        openFolder = open,
                        visibleSongs = allSongs.filter { it.folderPath == open.path }.filter(songMatches)
                    )
                } else {
                    base.copy(
                        visibleFolders = folders.filter { folder ->
                            query.isEmpty() ||
                                folder.name.contains(query, ignoreCase = true) ||
                                folder.displayPath.contains(query, ignoreCase = true)
                        }
                    )
                }
            }

            LibraryFilter.PLAYLISTS -> {
                val byUri = allSongs.associateBy { it.contentUri.toString() }
                val summaries = input.playlists.map { playlist ->
                    PlaylistSummary(
                        id = playlist.id,
                        name = playlist.name,
                        songCount = playlist.songUris.count { byUri.containsKey(it) },
                        createdAtMs = playlist.createdAtMs
                    )
                }
                val open = input.openPlaylistId?.let { id -> summaries.firstOrNull { it.id == id } }
                if (open != null) {
                    base.copy(
                        openPlaylistId = open.id,
                        openPlaylist = open,
                        visibleSongs = playlistSongs(allSongs, input.playlists, open.id).filter(songMatches)
                    )
                } else {
                    base.copy(
                        visiblePlaylists = summaries.filter {
                            query.isEmpty() || it.name.contains(query, ignoreCase = true)
                        }
                    )
                }
            }
        }
    }

    // ---------- Tri ----------

    /**
     * Trie la bibliothèque selon [order]. Les clés de collation (comparaison insensible à la casse,
     * qui range « Éléphant » parmi les E) sont calculées une seule fois par bibliothèque chargée ;
     * changer de critère ne fait ensuite que retrier. Le résultat est mis en cache : une recherche ou
     * un changement d'onglet ne retrie jamais. Chaque critère se termine par l'identifiant du
     * morceau, si bien que l'ordre est total et identique d'un lancement à l'autre.
     */
    private fun sortedSongs(source: List<Song>, order: SortOrder): List<Song> {
        sortCache?.let { cached ->
            if (cached.source === source && cached.order == order) return cached.result
        }
        val result = keyedSongs(source).sortedWith(comparatorFor(order)).map { it.song }
        sortCache = SortCache(source, order, result)
        return result
    }

    private fun keyedSongs(source: List<Song>): List<KeyedSong> {
        keyedCache?.let { cached -> if (cached.source === source) return cached.keyed }
        val collator = newCollator()
        val keyed = source.map { song ->
            KeyedSong(
                song = song,
                titleKey = collator.getCollationKey(song.title),
                artistKey = collator.getCollationKey(song.artist.orEmpty()),
                albumKey = collator.getCollationKey(song.album.orEmpty())
            )
        }
        keyedCache = KeyedCache(source, keyed)
        return keyed
    }

    private fun comparatorFor(order: SortOrder): Comparator<KeyedSong> {
        val byTitle = compareBy<KeyedSong> { it.titleKey }
        return when (order) {
            SortOrder.TITLE_ASC ->
                byTitle.thenBy { it.song.id }
            SortOrder.TITLE_DESC ->
                compareByDescending<KeyedSong> { it.titleKey }.thenBy { it.song.id }
            SortOrder.DATE_ADDED_NEWEST ->
                compareByDescending<KeyedSong> { it.song.dateAddedSeconds }.then(byTitle).thenBy { it.song.id }
            SortOrder.DATE_ADDED_OLDEST ->
                compareBy<KeyedSong> { it.song.dateAddedSeconds }.then(byTitle).thenBy { it.song.id }
            SortOrder.DURATION_LONGEST ->
                compareByDescending<KeyedSong> { it.song.durationMs }.then(byTitle).thenBy { it.song.id }
            SortOrder.DURATION_SHORTEST ->
                compareBy<KeyedSong> { it.song.durationMs }.then(byTitle).thenBy { it.song.id }
            SortOrder.ARTIST_ASC ->
                // Les morceaux sans artiste passent en dernier ; puis album, piste, titre.
                compareBy<KeyedSong> { it.song.artist == null }
                    .thenBy { it.artistKey }
                    .thenBy { it.song.album == null }
                    .thenBy { it.albumKey }
                    .thenBy { trackSortValue(it.song) }
                    .then(byTitle)
                    .thenBy { it.song.id }
            SortOrder.ALBUM_ASC ->
                compareBy<KeyedSong> { it.song.album == null }
                    .thenBy { it.albumKey }
                    .thenBy { trackSortValue(it.song) }
                    .then(byTitle)
                    .thenBy { it.song.id }
        }
    }

    // ---------- Regroupements ----------

    private fun buildFolders(songs: List<Song>): List<FolderItem> {
        val collator = newCollator()
        return songs
            .groupBy { it.folderPath }
            .map { (path, folderSongs) ->
                val trimmed = path.trim('/')
                FolderItem(
                    path = path,
                    name = if (trimmed.isEmpty()) {
                        appContext.getString(R.string.folder_root_name)
                    } else {
                        trimmed.substringAfterLast('/')
                    },
                    displayPath = if (trimmed.isEmpty()) "/" else "/$trimmed/",
                    songCount = folderSongs.size
                )
            }
            .sortedWith(compareBy<FolderItem> { collator.getCollationKey(it.name) }.thenBy { it.path })
    }

    private fun buildArtists(songs: List<Song>): List<ArtistItem> {
        val collator = newCollator()
        val unknown = appContext.getString(R.string.artist_unknown)
        return songs
            .groupBy { artistKeyOf(it) }
            .map { (key, artistSongs) ->
                ArtistItem(
                    key = key,
                    name = artistSongs.firstNotNullOfOrNull { it.artist } ?: unknown,
                    albumCount = artistSongs.map { albumKeyOf(it) }.distinct().size,
                    songCount = artistSongs.size,
                    artworkUri = artistSongs.first().contentUri
                )
            }
            .sortedWith(compareBy<ArtistItem> { collator.getCollationKey(it.name) }.thenBy { it.key })
    }

    private fun buildAlbums(songs: List<Song>): List<AlbumItem> {
        val collator = newCollator()
        val unknownArtist = appContext.getString(R.string.artist_unknown)
        val unknownAlbum = appContext.getString(R.string.album_unknown)
        return songs
            .groupBy { albumKeyOf(it) }
            .map { (key, albumSongs) ->
                val mainArtist = albumSongs.mapNotNull { it.artist }
                    .groupingBy { it }
                    .eachCount()
                    .maxByOrNull { it.value }
                    ?.key
                AlbumItem(
                    key = key,
                    title = albumSongs.firstNotNullOfOrNull { it.album } ?: unknownAlbum,
                    artistName = mainArtist ?: unknownArtist,
                    trackCount = albumSongs.size,
                    artworkUri = albumSongs.first().contentUri
                )
            }
            .sortedWith(compareBy<AlbumItem> { collator.getCollationKey(it.title) }.thenBy { it.key })
    }

    /** Morceaux de la playlist [playlistId], dans l'ordre d'ajout, sans ceux qui ne sont plus dans la bibliothèque. */
    private fun playlistSongs(allSongs: List<Song>, playlists: List<Playlist>, playlistId: String?): List<Song> {
        val playlist = playlists.firstOrNull { it.id == playlistId } ?: return emptyList()
        val byUri = allSongs.associateBy { it.contentUri.toString() }
        return playlist.songUris.mapNotNull { byUri[it] }
    }

    private companion object {
        const val UNKNOWN_ARTIST_KEY = "\u0000unknown-artist"

        fun artistKeyOf(song: Song): String =
            song.artist?.trim()?.lowercase(Locale.ROOT) ?: UNKNOWN_ARTIST_KEY

        fun albumKeyOf(song: Song): String =
            if (song.albumId > 0) "id:${song.albumId}" else "name:${song.album.orEmpty().lowercase(Locale.ROOT)}"

        /** Numéro de piste dans l'album (1001 = disque 1, piste 1) ; les pistes sans numéro passent en dernier. */
        fun trackSortValue(song: Song): Int {
            val track = song.trackNumber % 1000
            return if (track > 0) track else Int.MAX_VALUE
        }
    }
}
EOF

echo "  -> app/src/main/java/com/elg/music/ui/main/SongAdapter.kt"
mkdir -p app/src/main/java/com/elg/music/ui/main
cat << 'EOF' > app/src/main/java/com/elg/music/ui/main/SongAdapter.kt
package com.elg.music.ui.main

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import androidx.recyclerview.widget.RecyclerView
import com.elg.music.R
import com.elg.music.data.model.Song
import com.elg.music.databinding.ItemSongBinding

/**
 * Adapte la liste de [Song] pour le RecyclerView de l'écran principal.
 *
 * @param onSongClicked appelé quand l'utilisateur touche la ligne (lecture du morceau).
 * @param onMenuClicked appelé quand l'utilisateur touche le bouton "..." (menu contextuel).
 */
class SongAdapter(
    private val onSongClicked: (Song) -> Unit,
    private val onMenuClicked: (Song, View) -> Unit
) : ListAdapter<Song, SongAdapter.SongViewHolder>(SongDiffCallback()) {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): SongViewHolder {
        val binding = ItemSongBinding.inflate(LayoutInflater.from(parent.context), parent, false)
        return SongViewHolder(binding)
    }

    override fun onBindViewHolder(holder: SongViewHolder, position: Int) {
        holder.bind(getItem(position))
    }

    inner class SongViewHolder(private val binding: ItemSongBinding) :
        RecyclerView.ViewHolder(binding.root) {

        fun bind(song: Song) {
            val context = binding.root.context
            binding.textSongTitle.text = song.title

            val artist = song.artist
            if (artist != null) {
                binding.textSongArtist.text = artist
                binding.textSongArtist.visibility = View.VISIBLE
                binding.root.contentDescription =
                    context.getString(R.string.song_row_content_description, song.title, artist)
            } else {
                binding.textSongArtist.visibility = View.GONE
                binding.root.contentDescription =
                    context.getString(R.string.song_row_content_description_no_artist, song.title)
            }

            binding.buttonSongMenu.contentDescription =
                context.getString(R.string.song_menu_button_content_description, song.title)

            binding.root.setOnClickListener { onSongClicked(song) }
            binding.buttonSongMenu.setOnClickListener { anchor -> onMenuClicked(song, anchor) }
        }
    }

    private class SongDiffCallback : DiffUtil.ItemCallback<Song>() {
        override fun areItemsTheSame(oldItem: Song, newItem: Song): Boolean =
            oldItem.id == newItem.id

        override fun areContentsTheSame(oldItem: Song, newItem: Song): Boolean =
            oldItem == newItem
    }
}
EOF

echo "  -> app/src/main/java/com/elg/music/ui/main/MainActivity.kt"
mkdir -p app/src/main/java/com/elg/music/ui/main
cat << 'EOF' > app/src/main/java/com/elg/music/ui/main/MainActivity.kt
package com.elg.music.ui.main

import android.Manifest
import android.app.SearchManager
import android.content.DialogInterface
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Bundle
import android.provider.MediaStore
import android.provider.OpenableColumns
import android.view.Menu
import android.view.MenuItem
import android.view.View
import android.view.WindowManager
import android.view.inputmethod.EditorInfo
import android.widget.PopupMenu
import android.widget.Toast
import androidx.activity.OnBackPressedCallback
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.appcompat.app.AppCompatDelegate
import androidx.core.content.ContextCompat
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.doOnNextLayout
import androidx.core.view.updatePadding
import androidx.core.widget.doOnTextChanged
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.repeatOnLifecycle
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.preference.PreferenceManager
import androidx.recyclerview.widget.GridLayoutManager
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.elg.music.R
import com.elg.music.data.model.Playlist
import com.elg.music.data.model.PlaylistSummary
import com.elg.music.data.model.Song
import com.elg.music.data.model.SortOrder
import com.elg.music.data.repository.TagRepository
import com.elg.music.data.repository.TitleCleaner
import com.elg.music.data.repository.VaultRepository
import com.elg.music.databinding.ActivityMainBinding
import com.elg.music.databinding.DialogPlaylistNameBinding
import com.elg.music.playback.MidiSupport
import com.elg.music.playback.PlayerController
import com.elg.music.ui.ArtworkLoader
import com.elg.music.ui.about.AboutDialog
import com.elg.music.ui.applySystemBarPadding
import com.elg.music.ui.player.AbLoopSheet
import com.elg.music.ui.player.PlayerUi
import com.elg.music.ui.player.QueueSheet
import com.elg.music.ui.player.SleepTimerSheet
import com.elg.music.ui.settings.SettingsActivity
import com.elg.music.ui.settings.SettingsFragment
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import com.google.android.material.tabs.TabLayout
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch

class MainActivity : AppCompatActivity() {

    private lateinit var binding: ActivityMainBinding
    private lateinit var songAdapter: SongAdapter
    private lateinit var folderAdapter: FolderAdapter
    private lateinit var playlistAdapter: PlaylistAdapter
    private lateinit var artistAdapter: ArtistAdapter
    private lateinit var albumAdapter: AlbumAdapter
    private lateinit var linearLayoutManager: LinearLayoutManager
    private lateinit var gridLayoutManager: GridLayoutManager
    private lateinit var artworkLoader: ArtworkLoader
    private lateinit var playerUi: PlayerUi
    private var listItemAnimator: RecyclerView.ItemAnimator? = null
    private var progressJob: Job? = null
    private lateinit var songActions: SongActions
    private var lastAppliedSortOrder: SortOrder? = null
    private var lastScreen: LibraryScreen? = null

    // Demandes venues de l'extérieur, en attente de la fin du chargement de la bibliothèque.
    private var pendingViewUri: Uri? = null
    private var hasPendingSearch = false
    private var pendingSearchQuery = ""

    private val libraryViewModel: LibraryViewModel by lazy {
        ViewModelProvider(
            this,
            ViewModelProvider.AndroidViewModelFactory.getInstance(application)
        ).get(LibraryViewModel::class.java)
    }

    private val playerController: PlayerController by lazy { PlayerController(this) }

    /** Actif uniquement dans un détail (artiste, album, dossier, playlist) : « retour » revient à la liste. */
    private val detailBackCallback = object : OnBackPressedCallback(false) {
        override fun handleOnBackPressed() {
            libraryViewModel.closeDetail()
        }
    }

    /** Actif quand le grand lecteur est ouvert : « retour » le réduit. Enregistré en dernier, donc prioritaire. */
    private val sheetBackCallback = object : OnBackPressedCallback(false) {
        override fun handleOnBackPressed() {
            playerUi.collapse()
        }
    }

    private val permissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { results ->
        val audioGranted = results[Manifest.permission.READ_MEDIA_AUDIO] == true
        if (audioGranted) {
            libraryViewModel.loadLibrary()
        } else {
            libraryViewModel.onLibraryUnavailable()
            Toast.makeText(this, R.string.permission_denied_message, Toast.LENGTH_LONG).show()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        applyStoredTheme()
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)
        binding.root.applySystemBarPadding()
        setSupportActionBar(binding.toolbar)
        // Le titre « ELG Music » est dessiné par le logo de la barre d'en-tête (drapeau + titre).
        supportActionBar?.setDisplayShowTitleEnabled(false)
        ViewCompat.setAccessibilityHeading(binding.textBrandTitle, true)

        onBackPressedDispatcher.addCallback(this, detailBackCallback)
        onBackPressedDispatcher.addCallback(this, sheetBackCallback)

        artworkLoader = ArtworkLoader(this, lifecycleScope)
        songActions = SongActions(this, ::onSongDeleted)
        setupPlayerUi()
        setupRecyclerView()
        setupSearch()
        setupFilterTabs()
        setupSortButton()
        setupHeader()
        setupPlaylistFab()
        setupEmptyFavorites()
        observeLibraryState()
        observePlayerState()

        if (hasRequiredPermissions()) {
            libraryViewModel.loadLibrary()
        } else {
            permissionLauncher.launch(requiredPermissions())
        }
        if (savedInstanceState == null) handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    override fun onStart() {
        super.onStart()
        playerController.connect()
        progressJob = lifecycleScope.launch {
            while (isActive) {
                playerController.refreshProgress()
                delay(500L)
            }
        }
    }

    /** Retour depuis un autre écran : relit la bibliothèque si un morceau a quitté le coffre-fort ou si ses tags ont changé. */
    override fun onRestart() {
        super.onRestart()
        val vaultChanged = VaultRepository.consumeLibraryDirty()
        val tagsChanged = TagRepository.consumeLibraryDirty()
        if ((vaultChanged || tagsChanged) && hasRequiredPermissions()) {
            libraryViewModel.loadLibrary()
        }
    }

    override fun onStop() {
        progressJob?.cancel()
        progressJob = null
        playerUi.cancelSeekHold()
        playerController.disconnect()
        super.onStop()
    }

    override fun onCreateOptionsMenu(menu: Menu): Boolean {
        menuInflater.inflate(R.menu.menu_main, menu)
        return true
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        return when (item.itemId) {
            R.id.action_settings -> {
                startActivity(Intent(this, SettingsActivity::class.java))
                true
            }
            R.id.action_about -> {
                AboutDialog().show(supportFragmentManager, AboutDialog.TAG)
                true
            }
            else -> super.onOptionsItemSelected(item)
        }
    }

    // ===================== Thème =====================

    private fun applyStoredTheme() {
        val prefs = PreferenceManager.getDefaultSharedPreferences(this)
        val mode = when (prefs.getString(SettingsFragment.KEY_THEME, "system")) {
            "light" -> AppCompatDelegate.MODE_NIGHT_NO
            "dark" -> AppCompatDelegate.MODE_NIGHT_YES
            else -> AppCompatDelegate.MODE_NIGHT_FOLLOW_SYSTEM
        }
        AppCompatDelegate.setDefaultNightMode(mode)
    }

    // ===================== Permissions =====================

    private fun requiredPermissions(): Array<String> = arrayOf(
        Manifest.permission.READ_MEDIA_AUDIO,
        Manifest.permission.POST_NOTIFICATIONS
    )

    /**
     * Seul l'accès audio conditionne le chargement de la bibliothèque : les notifications
     * sont demandées en même temps mais restent facultatives (mini-lecteur toujours utilisable
     * sans notification persistante si l'utilisateur les refuse).
     */
    private fun hasRequiredPermissions(): Boolean =
        ContextCompat.checkSelfPermission(this, Manifest.permission.READ_MEDIA_AUDIO) ==
            PackageManager.PERMISSION_GRANTED

    // ===================== Lecteurs (capsule, grand lecteur, file d'attente) =====================

    private fun setupPlayerUi() {
        playerUi = PlayerUi(
            activity = this,
            binding = binding,
            playerController = playerController,
            artworkLoader = artworkLoader,
            scope = lifecycleScope,
            viewsBehindSheet = listOf(
                binding.toolbar, binding.searchBar, binding.tabLayoutFilters, binding.buttonSort,
                binding.headerBar, binding.recyclerSongs, binding.progressLoading,
                binding.textEmptyState, binding.layoutEmptyFavorites, binding.fabCreatePlaylist,
                binding.miniPlayer.root
            ),
            onQueueRequested = ::showQueue,
            onToggleFavorite = { mediaId ->
                libraryViewModel.findSong(mediaId)?.let { song -> toggleFavoriteWithMessage(song) }
            },
            onAddToPlaylist = { mediaId ->
                libraryViewModel.findSong(mediaId)?.let { song -> showAddToPlaylistDialog(song) }
            },
            isFavorite = { mediaId ->
                libraryViewModel.findSong(mediaId)?.let { song -> libraryViewModel.isFavorite(song) } ?: false
            },
            onSheetExpandedChanged = { expanded -> sheetBackCallback.isEnabled = expanded },
            onMoreOptionsRequested = ::showPlayerMenu
        )
    }

    private fun observePlayerState() {
        lifecycleScope.launch {
            repeatOnLifecycle(Lifecycle.State.STARTED) {
                playerController.state.collect { state -> playerUi.render(state) }
            }
        }
    }

    private fun showQueue() {
        val entries = playerController.queueSnapshot()
        if (entries.isEmpty()) return
        QueueSheet.show(this, entries, playerController.currentQueueIndex()) { index ->
            playerController.playQueueItem(index)
        }
    }

    // ===================== Listes (titres, artistes, albums, dossiers, playlists) =====================

    private fun setupRecyclerView() {
        songAdapter = SongAdapter(
            onSongClicked = ::onSongClicked,
            onMenuClicked = ::showSongMenu
        )
        folderAdapter = FolderAdapter(
            onFolderClicked = { folder -> libraryViewModel.openFolder(folder.path) }
        )
        playlistAdapter = PlaylistAdapter(
            onPlaylistClicked = { playlist -> libraryViewModel.openPlaylist(playlist.id) },
            onMenuClicked = ::showPlaylistMenu
        )
        artistAdapter = ArtistAdapter(
            artworkLoader = artworkLoader,
            onArtistClicked = { artist -> libraryViewModel.openArtist(artist.key) }
        )
        albumAdapter = AlbumAdapter(
            artworkLoader = artworkLoader,
            onAlbumClicked = { album -> libraryViewModel.openAlbum(album.key) }
        )
        linearLayoutManager = LinearLayoutManager(this)
        gridLayoutManager = GridLayoutManager(this, ALBUM_GRID_COLUMNS)
        binding.recyclerSongs.layoutManager = linearLayoutManager
        binding.recyclerSongs.adapter = songAdapter
        listItemAnimator = binding.recyclerSongs.itemAnimator
    }

    /**
     * Recherche : le texte tapé filtre la liste à chaque caractère ; le bouton « Supprimer la
     * recherche » (croix, visible seulement s'il y a du texte) efface tout le texte d'un geste et
     * remet le curseur dans le champ ; la touche « Rechercher » du clavier referme le clavier.
     */
    private fun setupSearch() {
        binding.editSearch.doOnTextChanged { text, _, _, _ ->
            val query = text?.toString().orEmpty()
            binding.buttonClearSearch.visibility = if (query.isEmpty()) View.GONE else View.VISIBLE
            libraryViewModel.onSearchQueryChanged(query)
        }
        binding.editSearch.setOnEditorActionListener { view, actionId, _ ->
            if (actionId == EditorInfo.IME_ACTION_SEARCH) {
                WindowCompat.getInsetsController(window, view).hide(WindowInsetsCompat.Type.ime())
                true
            } else {
                false
            }
        }
        binding.buttonClearSearch.setOnClickListener {
            binding.editSearch.text?.clear()
            binding.editSearch.requestFocus()
            WindowCompat.getInsetsController(window, binding.editSearch).show(WindowInsetsCompat.Type.ime())
        }
    }

    /**
     * Barre de filtres (Titres, Artistes, Albums, Playlists, Favoris, Dossiers). Toucher de
     * nouveau un onglet qui peut ouvrir un détail (artistes, albums, playlists, dossiers) revient
     * à sa liste.
     */
    private fun setupFilterTabs() {
        // L'onglet sélectionné est resynchronisé avec l'état (utile après une rotation d'écran),
        // avant d'écouter les changements pour ne pas déclencher d'action.
        binding.tabLayoutFilters
            .getTabAt(tabPositionFor(libraryViewModel.uiState.value.activeFilter))
            ?.select()

        binding.tabLayoutFilters.addOnTabSelectedListener(object : TabLayout.OnTabSelectedListener {
            override fun onTabSelected(tab: TabLayout.Tab) {
                libraryViewModel.onFilterSelected(filterAt(tab.position))
            }

            override fun onTabUnselected(tab: TabLayout.Tab) = Unit

            override fun onTabReselected(tab: TabLayout.Tab) {
                if (tab.position != TAB_POSITION_TITLES && tab.position != TAB_POSITION_FAVORITES) {
                    libraryViewModel.closeDetail()
                }
            }
        })
    }

    private fun filterAt(position: Int): LibraryFilter = when (position) {
        TAB_POSITION_ARTISTS -> LibraryFilter.ARTISTES
        TAB_POSITION_ALBUMS -> LibraryFilter.ALBUMS
        TAB_POSITION_PLAYLISTS -> LibraryFilter.PLAYLISTS
        TAB_POSITION_FAVORITES -> LibraryFilter.FAVORIS
        TAB_POSITION_FOLDERS -> LibraryFilter.DOSSIERS
        else -> LibraryFilter.TITRES
    }

    private fun tabPositionFor(filter: LibraryFilter): Int = when (filter) {
        LibraryFilter.TITRES -> TAB_POSITION_TITLES
        LibraryFilter.ARTISTES -> TAB_POSITION_ARTISTS
        LibraryFilter.ALBUMS -> TAB_POSITION_ALBUMS
        LibraryFilter.PLAYLISTS -> TAB_POSITION_PLAYLISTS
        LibraryFilter.FAVORIS -> TAB_POSITION_FAVORITES
        LibraryFilter.DOSSIERS -> TAB_POSITION_FOLDERS
    }

    /**
     * Bouton « Trier par » placé à droite de la barre de filtres : ouvre une boîte de dialogue à
     * choix unique (annoncée correctement par TalkBack) avec le critère actuel présélectionné.
     * Les libellés viennent des critères eux-mêmes, donc ne peuvent jamais être décalés.
     */
    private fun setupSortButton() {
        binding.buttonSort.setOnClickListener { showSortDialog() }
    }

    private fun showSortDialog() {
        val orders = SortOrder.entries
        val labels = orders.map { getString(it.labelRes) }.toTypedArray()
        val checkedIndex = orders.indexOf(libraryViewModel.currentSortOrder())
        MaterialAlertDialogBuilder(this)
            .setTitle(R.string.sort_dialog_title)
            .setSingleChoiceItems(labels, checkedIndex) { dialog, which ->
                libraryViewModel.onSortOrderSelected(orders[which])
                Toast.makeText(
                    this,
                    getString(R.string.sort_applied_message, labels[which]),
                    Toast.LENGTH_SHORT
                ).show()
                dialog.dismiss()
            }
            .setNegativeButton(R.string.sort_dialog_cancel, null)
            .show()
    }

    // ===================== En-tête contextuel, bouton + des playlists, favoris vides =====================

    private fun setupHeader() {
        binding.buttonHeaderBack.setOnClickListener { libraryViewModel.closeDetail() }
        binding.buttonHeaderPrimary.setOnClickListener { onHeaderPrimaryClicked() }
        binding.buttonHeaderSecondary.setOnClickListener {
            libraryViewModel.uiState.value.openPlaylist?.let { playlist -> confirmDeletePlaylist(playlist) }
        }
    }

    /**
     * Bouton principal de l'en-tête : lecture aléatoire de tous les favoris, ou lecture dans
     * l'ordre de tout l'artiste / album / dossier / playlist ouvert.
     */
    private fun onHeaderPrimaryClicked() {
        val songs = libraryViewModel.songsForBulkPlay()
        if (songs.isEmpty()) return
        val mediaItems = songs.map(::toMediaItem)
        if (libraryViewModel.uiState.value.screen == LibraryScreen.FAVORITES) {
            playerController.playSongsShuffled(mediaItems)
        } else {
            playerController.playSongs(mediaItems, 0)
        }
    }

    private fun setupPlaylistFab() {
        binding.fabCreatePlaylist.setOnClickListener { showCreatePlaylistDialog(songToAdd = null) }
    }

    private fun setupEmptyFavorites() {
        binding.buttonExploreLibrary.setOnClickListener {
            binding.tabLayoutFilters.getTabAt(TAB_POSITION_TITLES)?.select()
        }
    }

    private fun observeLibraryState() {
        lifecycleScope.launch {
            repeatOnLifecycle(Lifecycle.State.STARTED) {
                libraryViewModel.uiState.collect { state ->
                    renderLibrary(state)
                    renderHeader(state)
                    detailBackCallback.isEnabled = state.isInDetailView
                    processPendingRequests(state)
                }
            }
        }
    }

    private fun renderLibrary(state: LibraryUiState) {
        val screen = state.screen

        // Après un changement de tri ou d'écran : retour en haut de liste. Lors d'un changement de
        // tri, les animations de déplacement sont coupées le temps du recalcul : sinon des centaines
        // de lignes glissent en même temps (effet de « glitch »).
        val sortChanged = lastAppliedSortOrder != null && state.sortOrder != lastAppliedSortOrder
        lastAppliedSortOrder = state.sortOrder
        val screenChanged = lastScreen != null && screen != lastScreen
        lastScreen = screen
        if (sortChanged) binding.recyclerSongs.itemAnimator = null
        val afterCommit = Runnable {
            if (sortChanged || screenChanged) binding.recyclerSongs.scrollToPosition(0)
            if (sortChanged) {
                binding.recyclerSongs.doOnNextLayout { binding.recyclerSongs.itemAnimator = listItemAnimator }
                binding.recyclerSongs.postDelayed(
                    { binding.recyclerSongs.itemAnimator = listItemAnimator },
                    ANIMATOR_RESTORE_DELAY_MS
                )
            }
        }

        val targetManager: RecyclerView.LayoutManager =
            if (screen == LibraryScreen.ALBUM_LIST) gridLayoutManager else linearLayoutManager
        if (binding.recyclerSongs.layoutManager !== targetManager) {
            binding.recyclerSongs.layoutManager = targetManager
        }
        val targetAdapter: RecyclerView.Adapter<*> = when (screen) {
            LibraryScreen.FOLDER_LIST -> folderAdapter
            LibraryScreen.PLAYLIST_LIST -> playlistAdapter
            LibraryScreen.ARTIST_LIST -> artistAdapter
            LibraryScreen.ALBUM_LIST -> albumAdapter
            else -> songAdapter
        }
        if (binding.recyclerSongs.adapter !== targetAdapter) {
            binding.recyclerSongs.adapter = targetAdapter
        }
        when (screen) {
            LibraryScreen.FOLDER_LIST -> folderAdapter.submitList(state.visibleFolders, afterCommit)
            LibraryScreen.PLAYLIST_LIST -> playlistAdapter.submitList(state.visiblePlaylists, afterCommit)
            LibraryScreen.ARTIST_LIST -> artistAdapter.submitList(state.visibleArtists, afterCommit)
            LibraryScreen.ALBUM_LIST -> albumAdapter.submitList(state.visibleAlbums, afterCommit)
            else -> songAdapter.submitList(state.visibleSongs, afterCommit)
        }

        val isEmpty = when (screen) {
            LibraryScreen.FOLDER_LIST -> state.visibleFolders.isEmpty()
            LibraryScreen.PLAYLIST_LIST -> state.visiblePlaylists.isEmpty()
            LibraryScreen.ARTIST_LIST -> state.visibleArtists.isEmpty()
            LibraryScreen.ALBUM_LIST -> state.visibleAlbums.isEmpty()
            else -> state.visibleSongs.isEmpty()
        }
        val showFavoritesEmpty = !state.isLoading && isEmpty &&
            screen == LibraryScreen.FAVORITES && state.searchQuery.isBlank()
        val showTextEmpty = !state.isLoading && isEmpty && !showFavoritesEmpty

        binding.progressLoading.visibility = if (state.isLoading) View.VISIBLE else View.GONE
        binding.layoutEmptyFavorites.visibility = if (showFavoritesEmpty) View.VISIBLE else View.GONE
        binding.textEmptyState.visibility = if (showTextEmpty) View.VISIBLE else View.GONE
        if (showTextEmpty) {
            binding.textEmptyState.setText(emptyMessageFor(state))
        }
        binding.recyclerSongs.visibility = if (isEmpty || state.isLoading) View.GONE else View.VISIBLE

        // Bouton flottant « + » : uniquement sur la liste des playlists (et la liste ne passe pas dessous).
        val showFab = screen == LibraryScreen.PLAYLIST_LIST && !state.isLoading
        if (showFab) binding.fabCreatePlaylist.show() else binding.fabCreatePlaylist.hide()
        val bottomPaddingDp =
            if (screen == LibraryScreen.PLAYLIST_LIST) LIST_PADDING_WITH_FAB_DP else LIST_PADDING_DP
        binding.recyclerSongs.updatePadding(bottom = dpToPx(bottomPaddingDp))
    }

    private fun emptyMessageFor(state: LibraryUiState): Int = when {
        state.screen == LibraryScreen.SONGS -> R.string.main_placeholder_message
        state.searchQuery.isNotBlank() -> R.string.empty_search_message
        state.screen == LibraryScreen.ARTIST_LIST -> R.string.empty_artists_message
        state.screen == LibraryScreen.ALBUM_LIST -> R.string.empty_albums_message
        state.screen == LibraryScreen.FOLDER_LIST -> R.string.empty_folders_message
        state.screen == LibraryScreen.PLAYLIST_LIST -> R.string.empty_playlists_message
        state.screen == LibraryScreen.PLAYLIST_DETAIL -> R.string.empty_playlist_detail_message
        else -> R.string.main_placeholder_message
    }

    private fun renderHeader(state: LibraryUiState) {
        val screen = state.screen
        val artist = state.openArtist
        val album = state.openAlbum
        val folder = state.openFolder
        val playlist = state.openPlaylist

        val showFavoritesHeader = screen == LibraryScreen.FAVORITES && !state.isLoading && state.favoriteCount > 0
        val showArtistHeader = screen == LibraryScreen.ARTIST_DETAIL && artist != null
        val showAlbumHeader = screen == LibraryScreen.ALBUM_DETAIL && album != null
        val showFolderHeader = screen == LibraryScreen.FOLDER_DETAIL && folder != null
        val showPlaylistHeader = screen == LibraryScreen.PLAYLIST_DETAIL && playlist != null
        val showDetailHeader = showArtistHeader || showAlbumHeader || showFolderHeader || showPlaylistHeader

        binding.headerBar.visibility =
            if (showFavoritesHeader || showDetailHeader) View.VISIBLE else View.GONE
        binding.layoutHeaderTitleRow.visibility = if (showDetailHeader) View.VISIBLE else View.GONE
        binding.buttonHeaderSecondary.visibility = if (showPlaylistHeader) View.VISIBLE else View.GONE

        if (showFavoritesHeader) {
            binding.buttonHeaderPrimary.setText(R.string.favorites_shuffle_all)
            binding.buttonHeaderPrimary.visibility = View.VISIBLE
        }
        if (artist != null && showArtistHeader) {
            val albums = resources.getQuantityString(R.plurals.album_count, artist.albumCount, artist.albumCount)
            val songs = resources.getQuantityString(R.plurals.piece_count, artist.songCount, artist.songCount)
            binding.textHeaderTitle.text = artist.name
            binding.textHeaderSubtitle.text = getString(R.string.artist_details_format, albums, songs)
            binding.buttonHeaderPrimary.setText(R.string.playlist_play_all)
            binding.buttonHeaderPrimary.visibility = View.VISIBLE
        }
        if (album != null && showAlbumHeader) {
            val tracks = resources.getQuantityString(R.plurals.track_count, album.trackCount, album.trackCount)
            binding.textHeaderTitle.text = album.title
            binding.textHeaderSubtitle.text = getString(R.string.album_details_format, album.artistName, tracks)
            binding.buttonHeaderPrimary.setText(R.string.playlist_play_all)
            binding.buttonHeaderPrimary.visibility = View.VISIBLE
        }
        if (folder != null && showFolderHeader) {
            val countText = resources.getQuantityString(R.plurals.song_count, folder.songCount, folder.songCount)
            binding.textHeaderTitle.text = folder.name
            binding.textHeaderSubtitle.text =
                getString(R.string.folder_details_format, countText, folder.displayPath)
            binding.buttonHeaderPrimary.setText(R.string.folder_play_all)
            binding.buttonHeaderPrimary.visibility = View.VISIBLE
        }
        if (playlist != null && showPlaylistHeader) {
            binding.textHeaderTitle.text = playlist.name
            binding.textHeaderSubtitle.text =
                resources.getQuantityString(R.plurals.song_count, playlist.songCount, playlist.songCount)
            binding.buttonHeaderPrimary.setText(R.string.playlist_play_all)
            binding.buttonHeaderPrimary.visibility =
                if (playlist.songCount > 0) View.VISIBLE else View.GONE
        }
    }

    private fun dpToPx(dp: Int): Int = (dp * resources.displayMetrics.density).toInt()

    private fun onSongClicked(song: Song) {
        val songs = libraryViewModel.uiState.value.visibleSongs
        val index = songs.indexOfFirst { it.id == song.id }
        if (index == -1) return
        playerController.playSongs(songs.map(::toMediaItem), index)
    }

    private fun toMediaItem(song: Song): MediaItem {
        val metadata = MediaMetadata.Builder()
            .setTitle(song.title)
            .setArtist(song.artist)
            .setAlbumTitle(song.album)
            // L'Uri du fichier sert de clé à ArtworkBitmapLoader (pochette intégrée, sinon pochette par défaut).
            .setArtworkUri(song.contentUri)
            .setDurationMs(song.durationMs)
        if (song.isMidi) {
            // Fichier MIDI : le service joue un silence de même durée et le MediaPlayer natif joue le fichier.
            metadata.setExtras(Bundle().apply { putString(MidiSupport.EXTRA_MIDI_URI, song.contentUri.toString()) })
        }
        return MediaItem.Builder()
            .setMediaId(song.id.toString())
            .setUri(song.contentUri)
            .setMediaMetadata(metadata.build())
            .build()
    }

    // ===================== « Ouvrir avec » et recherche vocale =====================

    private fun handleIntent(received: Intent?) {
        val request = received ?: return
        when (request.action) {
            Intent.ACTION_VIEW -> {
                val uri = request.data ?: return
                pendingViewUri = uri
                request.action = Intent.ACTION_MAIN // demande consommée : pas de relecture après une rotation
            }
            MediaStore.INTENT_ACTION_MEDIA_PLAY_FROM_SEARCH -> {
                pendingSearchQuery = request.getStringExtra(SearchManager.QUERY).orEmpty()
                hasPendingSearch = true
                request.action = Intent.ACTION_MAIN
            }
            else -> return
        }
        processPendingRequests(libraryViewModel.uiState.value)
    }

    /** Exécute les demandes externes une fois la bibliothèque connue (ou sûrement indisponible). */
    private fun processPendingRequests(state: LibraryUiState) {
        if (state.isLoading) return
        pendingViewUri?.let { uri ->
            pendingViewUri = null
            playExternalAudio(uri, state.allSongs)
        }
        if (hasPendingSearch) {
            hasPendingSearch = false
            playFromSearch(pendingSearchQuery, state.allSongs)
        }
    }

    /** Lit le fichier ouvert depuis une autre application ; s'il est dans la bibliothèque, on lit la bibliothèque à partir de lui. */
    private fun playExternalAudio(uri: Uri, songs: List<Song>) {
        val index = songs.indexOfFirst { it.contentUri == uri }
        if (index >= 0) {
            playerController.playSongs(songs.map(::toMediaItem), index)
            return
        }
        try {
            val displayName = contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
                ?.use { cursor -> if (cursor.moveToFirst()) cursor.getString(0) else null }
                ?: uri.lastPathSegment
            val isMidi = contentResolver.getType(uri)?.contains("midi", ignoreCase = true) == true ||
                displayName?.endsWith(".mid", ignoreCase = true) == true ||
                displayName?.endsWith(".midi", ignoreCase = true) == true
            val metadata = MediaMetadata.Builder().setTitle(TitleCleaner(this).clean(displayName))
            if (isMidi) {
                metadata.setExtras(Bundle().apply { putString(MidiSupport.EXTRA_MIDI_URI, uri.toString()) })
            }
            val item = MediaItem.Builder()
                .setMediaId(uri.toString())
                .setUri(uri)
                .setMediaMetadata(metadata.build())
                .build()
            playerController.playSongs(listOf(item), 0)
        } catch (error: Exception) {
            Toast.makeText(this, R.string.view_audio_unreadable, Toast.LENGTH_LONG).show()
        }
    }

    /** « Lis <titre, artiste ou album> » : lit les morceaux correspondants ; sans mot-clé, lit toute la bibliothèque au hasard. */
    private fun playFromSearch(query: String, songs: List<Song>) {
        val needle = query.trim()
        if (needle.isEmpty()) {
            playerController.playSongsShuffled(songs.map(::toMediaItem))
            return
        }
        val matches = songs.filter { song ->
            song.title.contains(needle, ignoreCase = true) ||
                song.artist?.contains(needle, ignoreCase = true) == true ||
                song.album?.contains(needle, ignoreCase = true) == true
        }
        if (matches.isEmpty()) {
            Toast.makeText(this, getString(R.string.play_from_search_no_result, needle), Toast.LENGTH_LONG).show()
        } else {
            playerController.playSongs(matches.map(::toMediaItem), 0)
        }
    }

    // ===================== Menu contextuel par morceau =====================

    private fun toggleFavoriteWithMessage(song: Song) {
        val nowFavorite = libraryViewModel.toggleFavorite(song)
        val messageRes = if (nowFavorite) R.string.favorite_added_message else R.string.favorite_removed_message
        Toast.makeText(this, getString(messageRes, song.title), Toast.LENGTH_SHORT).show()
    }

    private fun showSongMenu(song: Song, anchor: View) {
        val popup = PopupMenu(this, anchor)
        popup.menuInflater.inflate(R.menu.menu_song_item, popup.menu)

        popup.menu.findItem(R.id.action_toggle_favorite).title = getString(
            if (libraryViewModel.isFavorite(song)) {
                R.string.song_menu_remove_favorite
            } else {
                R.string.song_menu_add_favorite
            }
        )
        // « Retirer de cette playlist » n'a de sens que dans le détail d'une playlist.
        popup.menu.findItem(R.id.action_remove_from_playlist).isVisible =
            libraryViewModel.uiState.value.screen == LibraryScreen.PLAYLIST_DETAIL

        popup.setOnMenuItemClickListener { item ->
            when (item.itemId) {
                R.id.action_toggle_favorite -> {
                    toggleFavoriteWithMessage(song)
                    true
                }
                R.id.action_add_to_playlist -> {
                    showAddToPlaylistDialog(song)
                    true
                }
                R.id.action_remove_from_playlist -> {
                    removeSongFromOpenPlaylist(song)
                    true
                }
                R.id.action_hide_song -> {
                    libraryViewModel.blacklistSong(song)
                    Toast.makeText(this, getString(R.string.song_hidden_message, song.title), Toast.LENGTH_SHORT)
                        .show()
                    true
                }
                R.id.action_ab_loop -> {
                    openAbLoopFor(song)
                    true
                }
                // Partager / Supprimer : actions communes au menu des listes et à celui du grand lecteur.
                else -> songActions.handleMenuItem(item.itemId, song)
            }
        }
        popup.show()
    }

    /**
     * Menu d'options du grand lecteur (bouton « Plus d'options »). Les actions portent sur un morceau
     * de la bibliothèque ; un fichier ouvert depuis une autre application n'en fait pas partie.
     */
    private fun showPlayerMenu(anchor: View, mediaId: String) {
        // Un fichier ouvert depuis une autre application n'est pas dans la bibliothèque (song == null) :
        // le menu ne propose alors que le minuteur de sommeil et la boucle A-B.
        val song = libraryViewModel.findSong(mediaId)
        songActions.showPlayerMenu(
            anchor = anchor,
            song = song,
            onSleepTimer = { SleepTimerSheet.show(this) },
            onAbLoop = { AbLoopSheet.show(this, playerController.state) }
        )
    }

    /** « Boucle A-B… » depuis la liste : possible seulement pour le morceau en cours de lecture. */
    private fun openAbLoopFor(song: Song) {
        if (playerController.state.value.mediaId == song.id.toString()) {
            AbLoopSheet.show(this, playerController.state)
        } else {
            Toast.makeText(
                this,
                getString(R.string.ab_loop_play_first_message, song.title),
                Toast.LENGTH_LONG
            ).show()
        }
    }

    /**
     * Le fichier a été supprimé du stockage : le morceau quitte la bibliothèque affichée et la file
     * d'attente. S'il était en cours de lecture, le lecteur passe immédiatement au morceau suivant.
     */
    private fun onSongDeleted(song: Song) {
        libraryViewModel.removeSongLocally(song)
        playerController.removeFromQueue(song.id.toString())
    }

    // ===================== Playlists : création, ajout, retrait, suppression =====================

    /**
     * « Ajouter à une playlist… » : propose « Nouvelle playlist… » puis les playlists existantes.
     * S'il n'en existe encore aucune, ouvre directement la création.
     */
    private fun showAddToPlaylistDialog(song: Song) {
        val playlists = libraryViewModel.currentPlaylists()
        if (playlists.isEmpty()) {
            showCreatePlaylistDialog(songToAdd = song)
            return
        }
        val labels = arrayOf(getString(R.string.playlist_add_new_option)) + playlists.map { it.name }
        MaterialAlertDialogBuilder(this)
            .setTitle(R.string.playlist_add_dialog_title)
            .setItems(labels) { _, which ->
                if (which == 0) {
                    showCreatePlaylistDialog(songToAdd = song)
                } else {
                    addSongToPlaylist(playlists[which - 1], song)
                }
            }
            .setNegativeButton(R.string.delete_dialog_cancel, null)
            .show()
    }

    private fun addSongToPlaylist(playlist: Playlist, song: Song) {
        val messageRes = when (libraryViewModel.addSongToPlaylist(playlist.id, song)) {
            AddToPlaylistResult.ADDED -> R.string.playlist_song_added_message
            AddToPlaylistResult.ALREADY_PRESENT -> R.string.playlist_song_already_message
        }
        Toast.makeText(this, getString(messageRes, song.title, playlist.name), Toast.LENGTH_SHORT).show()
    }

    /**
     * Dialogue « Nouvelle playlist ». Le nom est validé sans fermer le dialogue : un nom vide ou
     * déjà pris affiche l'erreur sous le champ. Si [songToAdd] est fourni, le morceau est ajouté
     * d'emblée à la playlist créée.
     */
    private fun showCreatePlaylistDialog(songToAdd: Song?) {
        val dialogBinding = DialogPlaylistNameBinding.inflate(layoutInflater)
        val dialog = MaterialAlertDialogBuilder(this)
            .setTitle(R.string.playlist_create_title)
            .setView(dialogBinding.root)
            .setPositiveButton(R.string.playlist_create_confirm, null)
            .setNegativeButton(R.string.delete_dialog_cancel, null)
            .create()

        dialog.setOnShowListener {
            val createButton = dialog.getButton(DialogInterface.BUTTON_POSITIVE)
            fun submit() {
                val name = dialogBinding.editPlaylistName.text?.toString().orEmpty()
                when (libraryViewModel.createPlaylist(name, songToAdd)) {
                    CreatePlaylistResult.CREATED -> {
                        dialog.dismiss()
                        val message = if (songToAdd != null) {
                            getString(R.string.playlist_created_with_song_message, name.trim(), songToAdd.title)
                        } else {
                            getString(R.string.playlist_created_message, name.trim())
                        }
                        Toast.makeText(this, message, Toast.LENGTH_SHORT).show()
                    }
                    CreatePlaylistResult.EMPTY_NAME ->
                        dialogBinding.inputLayoutPlaylistName.error =
                            getString(R.string.playlist_name_error_empty)
                    CreatePlaylistResult.DUPLICATE_NAME ->
                        dialogBinding.inputLayoutPlaylistName.error =
                            getString(R.string.playlist_name_error_duplicate)
                }
            }
            createButton.setOnClickListener { submit() }
            dialogBinding.editPlaylistName.doOnTextChanged { _, _, _, _ ->
                dialogBinding.inputLayoutPlaylistName.error = null
            }
            dialogBinding.editPlaylistName.setOnEditorActionListener { _, actionId, _ ->
                if (actionId == EditorInfo.IME_ACTION_DONE) {
                    submit()
                    true
                } else {
                    false
                }
            }
            dialogBinding.editPlaylistName.requestFocus()
            dialog.window?.setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_STATE_VISIBLE)
        }
        dialog.show()
    }

    private fun removeSongFromOpenPlaylist(song: Song) {
        val playlistName = libraryViewModel.uiState.value.openPlaylist?.name ?: return
        libraryViewModel.removeSongFromOpenPlaylist(song)
        Toast.makeText(
            this,
            getString(R.string.playlist_song_removed_message, song.title, playlistName),
            Toast.LENGTH_SHORT
        ).show()
    }

    private fun showPlaylistMenu(playlist: PlaylistSummary, anchor: View) {
        val popup = PopupMenu(this, anchor)
        popup.menuInflater.inflate(R.menu.menu_playlist_item, popup.menu)
        popup.setOnMenuItemClickListener { item ->
            when (item.itemId) {
                R.id.action_delete_playlist -> {
                    confirmDeletePlaylist(playlist)
                    true
                }
                else -> false
            }
        }
        popup.show()
    }

    private fun confirmDeletePlaylist(playlist: PlaylistSummary) {
        MaterialAlertDialogBuilder(this)
            .setTitle(R.string.playlist_delete_dialog_title)
            .setMessage(getString(R.string.playlist_delete_dialog_message, playlist.name))
            .setPositiveButton(R.string.delete_dialog_confirm) { _, _ ->
                libraryViewModel.deletePlaylist(playlist.id)
                Toast.makeText(
                    this,
                    getString(R.string.playlist_deleted_message, playlist.name),
                    Toast.LENGTH_SHORT
                ).show()
            }
            .setNegativeButton(R.string.delete_dialog_cancel, null)
            .show()
    }

    private companion object {
        private const val TAB_POSITION_TITLES = 0
        private const val TAB_POSITION_ARTISTS = 1
        private const val TAB_POSITION_ALBUMS = 2
        private const val TAB_POSITION_PLAYLISTS = 3
        private const val TAB_POSITION_FAVORITES = 4
        private const val TAB_POSITION_FOLDERS = 5
        private const val ALBUM_GRID_COLUMNS = 2
        private const val LIST_PADDING_DP = 8
        private const val LIST_PADDING_WITH_FAB_DP = 88
        private const val ANIMATOR_RESTORE_DELAY_MS = 400L
    }
}
EOF

echo "  -> app/src/main/java/com/elg/music/ui/about/AboutDialog.kt"
mkdir -p app/src/main/java/com/elg/music/ui/about
cat << 'EOF' > app/src/main/java/com/elg/music/ui/about/AboutDialog.kt
package com.elg.music.ui.about

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Toast
import com.elg.music.BuildConfig
import com.elg.music.R
import com.elg.music.databinding.DialogAboutBinding
import com.google.android.material.bottomsheet.BottomSheetDialogFragment

class AboutDialog : BottomSheetDialogFragment() {

    private var _binding: DialogAboutBinding? = null
    private val binding get() = _binding!!

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = DialogAboutBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        binding.textAboutVersion.text = getString(R.string.about_version_format, BuildConfig.VERSION_NAME)

        binding.buttonYoutubeMain.setOnClickListener {
            openUrl(getString(R.string.about_url_youtube_main))
        }
        binding.buttonYoutubeSecondary.setOnClickListener {
            openUrl(getString(R.string.about_url_youtube_secondary))
        }
        binding.buttonFacebook.setOnClickListener {
            openUrl(getString(R.string.about_url_facebook))
        }
        binding.buttonInstagram.setOnClickListener {
            openUrl(getString(R.string.about_url_instagram))
        }
        binding.buttonTwitch.setOnClickListener {
            openUrl(getString(R.string.about_url_twitch))
        }
        binding.buttonEmail.setOnClickListener {
            sendSupportEmail()
        }
    }

    private fun openUrl(url: String) {
        try {
            startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
        } catch (e: ActivityNotFoundException) {
            Toast.makeText(requireContext(), getString(R.string.about_error_no_app), Toast.LENGTH_SHORT).show()
        }
    }

    private fun sendSupportEmail() {
        val email = getString(R.string.about_email_address)
        val intent = Intent(Intent.ACTION_SENDTO).apply {
            data = Uri.parse("mailto:$email")
        }
        try {
            startActivity(intent)
        } catch (e: ActivityNotFoundException) {
            Toast.makeText(requireContext(), getString(R.string.about_error_no_email_app), Toast.LENGTH_SHORT).show()
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }

    companion object {
        const val TAG = "AboutDialog"
    }
}
EOF

echo "  -> app/src/main/java/com/elg/music/ui/settings/SettingsActivity.kt"
mkdir -p app/src/main/java/com/elg/music/ui/settings
cat << 'EOF' > app/src/main/java/com/elg/music/ui/settings/SettingsActivity.kt
package com.elg.music.ui.settings

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import com.elg.music.R
import com.elg.music.databinding.ActivitySettingsBinding
import com.elg.music.ui.applySystemBarPadding

class SettingsActivity : AppCompatActivity() {

    private lateinit var binding: ActivitySettingsBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivitySettingsBinding.inflate(layoutInflater)
        setContentView(binding.root)
        binding.root.applySystemBarPadding()

        setSupportActionBar(binding.toolbar)
        supportActionBar?.setDisplayHomeAsUpEnabled(true)
        binding.toolbar.setNavigationContentDescription(R.string.settings_back_description)

        if (savedInstanceState == null) {
            supportFragmentManager.beginTransaction()
                .replace(R.id.settingsContainer, SettingsFragment())
                .commit()
        }
    }

    override fun onSupportNavigateUp(): Boolean {
        finish()
        return true
    }
}
EOF

echo "  -> app/src/main/java/com/elg/music/ui/settings/SettingsFragment.kt"
mkdir -p app/src/main/java/com/elg/music/ui/settings
cat << 'EOF' > app/src/main/java/com/elg/music/ui/settings/SettingsFragment.kt
package com.elg.music.ui.settings

import android.content.Intent
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.appcompat.app.AppCompatDelegate
import androidx.preference.ListPreference
import androidx.preference.Preference
import androidx.preference.PreferenceFragmentCompat
import com.elg.music.R
import com.elg.music.ui.about.AboutDialog
import com.elg.music.ui.player.SleepTimerSheet
import com.elg.music.ui.vault.VaultActivity

/**
 * Contenu de l'écran Réglages.
 *
 * Pour cet incrément, seules les sections ayant une logique réelle et fonctionnelle
 * sont exposées : le thème (appliqué immédiatement) et l'accès au module À propos.
 * Les sections DSP, filtres de bibliothèque et maintenance seront ajoutées au fur et
 * à mesure que leurs moteurs respectifs seront implémentés.
 */
class SettingsFragment : PreferenceFragmentCompat() {

    override fun onCreatePreferences(savedInstanceState: Bundle?, rootKey: String?) {
        setPreferencesFromResource(R.xml.root_preferences, rootKey)

        findPreference<ListPreference>(KEY_THEME)?.setOnPreferenceChangeListener { _, newValue ->
            applyTheme(newValue as String)
            true
        }

        findPreference<Preference>(KEY_AUDIO)?.setOnPreferenceClickListener {
            startActivity(Intent(requireContext(), AudioSettingsActivity::class.java))
            true
        }

        findPreference<Preference>(KEY_SLEEP_TIMER)?.setOnPreferenceClickListener {
            SleepTimerSheet.show(requireActivity() as AppCompatActivity)
            true
        }

        findPreference<Preference>(KEY_VAULT)?.setOnPreferenceClickListener {
            startActivity(Intent(requireContext(), VaultActivity::class.java))
            true
        }

        findPreference<Preference>(KEY_ABOUT)?.setOnPreferenceClickListener {
            AboutDialog().show(parentFragmentManager, AboutDialog.TAG)
            true
        }
    }

    private fun applyTheme(value: String) {
        val mode = when (value) {
            THEME_LIGHT -> AppCompatDelegate.MODE_NIGHT_NO
            THEME_DARK -> AppCompatDelegate.MODE_NIGHT_YES
            else -> AppCompatDelegate.MODE_NIGHT_FOLLOW_SYSTEM
        }
        AppCompatDelegate.setDefaultNightMode(mode)
    }

    companion object {
        const val KEY_THEME = "pref_theme"
        const val KEY_ABOUT = "pref_about"
        const val KEY_AUDIO = "pref_audio"
        const val KEY_VAULT = "pref_vault"
        const val KEY_SLEEP_TIMER = "pref_sleep_timer"
        private const val THEME_LIGHT = "light"
        private const val THEME_DARK = "dark"
    }
}
EOF

echo "  -> .github/workflows/build.yml"
mkdir -p .github/workflows
cat << 'EOF' > .github/workflows/build.yml
name: Build ELG Music APK

on:
  push:
    branches: [ main ]
  workflow_dispatch:

permissions:
  contents: read

jobs:
  build:
    runs-on: ubuntu-24.04
    steps:
      - name: Checkout sources
        uses: actions/checkout@v7

      - name: Set up JDK 17
        uses: actions/setup-java@v6
        with:
          distribution: 'temurin'
          java-version: '17'

      - name: Generate ELG Music project files
        run: bash setup_elg_full.sh

      - name: Set up Android SDK
        uses: android-actions/setup-android@v3
        with:
          packages: ''

      - name: Install Android SDK platform 36
        run: sdkmanager "platforms;android-36"

      - name: Set up Gradle 8.14
        uses: gradle/actions/setup-gradle@v6
        with:
          gradle-version: '8.14'

      - name: Build debug APK
        run: gradle assembleDebug --no-daemon --stacktrace

      - name: Upload APK artifact
        uses: actions/upload-artifact@v7
        with:
          name: elg-music-debug-apk
          path: app/build/outputs/apk/debug/*.apk
EOF

echo "  -> app/src/main/java/com/elg/music/data/model/SortOrder.kt"
mkdir -p app/src/main/java/com/elg/music/data/model
cat << 'EOF' > app/src/main/java/com/elg/music/data/model/SortOrder.kt
package com.elg.music.data.model

import androidx.annotation.StringRes
import com.elg.music.R

/**
 * Critères de tri de la liste des titres (bouton « Trier par »).
 *
 * [storageKey] est la valeur écrite dans les préférences : elle est volontairement distincte
 * du nom de l'énumération et de son ordinal, pour que renommer ou réordonner les cas plus tard
 * ne casse pas le choix déjà enregistré par l'utilisateur.
 *
 * [labelRes] est le libellé affiché dans le dialogue : il est porté par le critère lui-même, ce
 * qui supprime tout risque de décalage entre la liste des libellés et celle des critères.
 */
enum class SortOrder(val storageKey: String, @StringRes val labelRes: Int) {
    TITLE_ASC("title_asc", R.string.sort_title_asc),
    TITLE_DESC("title_desc", R.string.sort_title_desc),
    DATE_ADDED_NEWEST("date_added_newest", R.string.sort_date_newest),
    DATE_ADDED_OLDEST("date_added_oldest", R.string.sort_date_oldest),
    DURATION_LONGEST("duration_longest", R.string.sort_duration_longest),
    DURATION_SHORTEST("duration_shortest", R.string.sort_duration_shortest),
    ARTIST_ASC("artist_asc", R.string.sort_artist),
    ALBUM_ASC("album_asc", R.string.sort_album);

    companion object {
        val DEFAULT = TITLE_ASC

        /** Retrouve un critère depuis sa clé enregistrée ; retombe sur [DEFAULT] si inconnue ou absente. */
        fun fromStorageKey(key: String?): SortOrder =
            entries.firstOrNull { it.storageKey == key } ?: DEFAULT
    }
}
EOF

echo "  -> app/src/main/java/com/elg/music/data/repository/TitleCleaner.kt"
mkdir -p app/src/main/java/com/elg/music/data/repository
cat << 'EOF' > app/src/main/java/com/elg/music/data/repository/TitleCleaner.kt
package com.elg.music.data.repository

import android.content.Context
import com.elg.music.R
import java.time.DateTimeException
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.time.format.FormatStyle
import java.util.Locale

/**
 * Rend lisible le titre affiché pour un morceau, à partir du titre brut du MediaStore.
 *
 * Quand un fichier n'a pas de tag « titre », Android renvoie le nom du fichier, avec souvent
 * l'extension, des tirets du bas ou le nom brut donné par WhatsApp. Le nettoyage :
 *  1. retire les extensions audio (.mp3, .wav, .aac, .flac, .m4a, etc.), y compris quand elles
 *     sont suivies d'un complément comme « .mp3 (Remix) », ainsi que le suffixe « -mp3 » collé
 *     par certains sites de téléchargement ;
 *  2. remplace les tirets du bas par des espaces ;
 *  3. transforme les noms bruts WhatsApp (« AUD-20260216-WA0006 », « PTT-… »,
 *     « WhatsApp Audio 2026-02-16 at … ») en « Note vocale du 16 févr. 2026 » ;
 *  4. compacte les espaces multiples.
 *
 * Si rien de lisible ne reste, renvoie le titre par défaut (« Sans titre »).
 */
class TitleCleaner(context: Context) {

    private val appContext = context.applicationContext
    private val defaultTitle = appContext.getString(R.string.default_song_title)

    fun clean(rawTitle: String?): String {
        var text = rawTitle?.trim().orEmpty()
        if (text.isEmpty()) return defaultTitle

        text = AUDIO_EXTENSION.replace(text, "")
        text = GLUED_MP3_SUFFIX.replace(text, "")
        text = text.replace('_', ' ')
        text = rewriteWhatsAppName(text)
        text = MULTIPLE_SPACES.replace(text, " ").trim()

        return if (text.isEmpty()) defaultTitle else text
    }

    /**
     * Remplace le préfixe brut WhatsApp par un libellé lisible, en conservant ce qui suit
     * (par ex. un « (Remix) » ajouté par l'utilisateur).
     */
    private fun rewriteWhatsAppName(text: String): String {
        val compact = WHATSAPP_COMPACT.find(text)
        if (compact != null) {
            val (year, month, day) = compact.destructured
            return voiceNoteTitle(year, month, day) + text.substring(compact.range.last + 1)
        }
        val verbose = WHATSAPP_VERBOSE.find(text)
        if (verbose != null) {
            val (year, month, day) = verbose.destructured
            return voiceNoteTitle(year, month, day) + text.substring(verbose.range.last + 1)
        }
        return text
    }

    private fun voiceNoteTitle(year: String, month: String, day: String): String {
        return try {
            val date = LocalDate.of(year.toInt(), month.toInt(), day.toInt())
            val formatted = DateTimeFormatter
                .ofLocalizedDate(FormatStyle.MEDIUM)
                .withLocale(Locale.getDefault())
                .format(date)
            appContext.getString(R.string.voice_note_title_with_date, formatted)
        } catch (invalidDate: DateTimeException) {
            appContext.getString(R.string.voice_note_title)
        }
    }

    private companion object {
        /** Extension audio précédée d'un point et suivie de la fin du titre, d'un séparateur ou d'une seconde extension. */
        val AUDIO_EXTENSION = Regex(
            "\\.(?:mp3|wav|aac|flac|m4a|m4b|ogg|oga|opus|wma|aiff?|alac|ape|amr|3gp|mp4)(?=$|[\\s)\\]_.-])",
            RegexOption.IGNORE_CASE
        )

        /** Suffixe « -mp3 » / « _mp3 » collé en fin de titre, éventuellement avant un « (1) ». */
        val GLUED_MP3_SUFFIX = Regex(
            "[-_]mp3(?=\\s*(?:\\(\\d+\\))?$)",
            RegexOption.IGNORE_CASE
        )

        /** AUD-20260216-WA0006 (audio) ou PTT-20260216-WA0006 (note vocale). */
        val WHATSAPP_COMPACT = Regex(
            "^(?:AUD|PTT)-(\\d{4})(\\d{2})(\\d{2})-WA\\d+",
            RegexOption.IGNORE_CASE
        )

        /** WhatsApp Audio 2026-02-16 at 10.11.12 (ou « à »). */
        val WHATSAPP_VERBOSE = Regex(
            "^WhatsApp (?:Audio|Ptt) (\\d{4})-(\\d{2})-(\\d{2})(?: (?:at|à) [0-9.]+)?",
            RegexOption.IGNORE_CASE
        )

        val MULTIPLE_SPACES = Regex("\\s{2,}")
    }
}
EOF

echo "  -> app/src/main/java/com/elg/music/playback/ArtworkBitmapLoader.kt"
mkdir -p app/src/main/java/com/elg/music/playback
cat << 'EOF' > app/src/main/java/com/elg/music/playback/ArtworkBitmapLoader.kt
package com.elg.music.playback

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.net.Uri
import android.util.Size
import androidx.core.content.ContextCompat
import androidx.media3.common.util.BitmapLoader
import com.elg.music.data.repository.CoverCache
import com.elg.music.R
import com.google.common.util.concurrent.ListenableFuture
import com.google.common.util.concurrent.ListeningExecutorService
import com.google.common.util.concurrent.MoreExecutors
import java.util.concurrent.Callable
import java.util.concurrent.Executors

/**
 * Fournit la pochette affichée par la notification de lecture et l'écran de verrouillage.
 *
 * L'Uri d'artwork de chaque morceau est l'Uri MediaStore du fichier audio lui-même : le système
 * en extrait la pochette intégrée (ou l'image du dossier) via `loadThumbnail`. Quand le fichier
 * n'a aucune pochette, la pochette par défaut ([R.drawable.ic_artwork_default]) est renvoyée à
 * la place : le chargement n'échoue donc jamais, et la notification n'affiche plus de grand
 * rectangle noir vide.
 *
 * Media3 redemande souvent la même image ; le dernier résultat est donc gardé en mémoire.
 */
class ArtworkBitmapLoader(context: Context) : BitmapLoader {

    private val appContext = context.applicationContext
    private val executor: ListeningExecutorService =
        MoreExecutors.listeningDecorator(Executors.newSingleThreadExecutor())

    private val fallbackBitmap: Bitmap by lazy { renderFallbackBitmap() }

    @Volatile
    private var lastResult: Pair<Uri, Bitmap>? = null

    override fun supportsMimeType(mimeType: String): Boolean = mimeType.startsWith("image/")

    override fun decodeBitmap(data: ByteArray): ListenableFuture<Bitmap> =
        executor.submit(Callable<Bitmap> {
            BitmapFactory.decodeByteArray(data, 0, data.size) ?: fallbackBitmap
        })

    override fun loadBitmap(uri: Uri): ListenableFuture<Bitmap> =
        executor.submit(Callable<Bitmap> { loadArtwork(uri) })

    /** Libère le thread de chargement ; à appeler quand le service de lecture est détruit. */
    fun release() {
        executor.shutdown()
    }

    private fun loadArtwork(uri: Uri): Bitmap {
        lastResult?.let { (cachedUri, cachedBitmap) ->
            if (cachedUri == uri) return cachedBitmap
        }
        val cached = CoverCache.mediaIdOf(uri)?.let { CoverCache.read(appContext, it) }
            ?.let { BitmapFactory.decodeByteArray(it, 0, it.size) }
        val bitmap = cached ?: try {
            appContext.contentResolver.loadThumbnail(uri, Size(ARTWORK_SIZE_PX, ARTWORK_SIZE_PX), null)
        } catch (noArtwork: Exception) {
            // Aucune pochette pour ce fichier (ou lecture impossible) : pochette par défaut.
            fallbackBitmap
        }
        lastResult = uri to bitmap
        return bitmap
    }

    private fun renderFallbackBitmap(): Bitmap {
        val bitmap = Bitmap.createBitmap(ARTWORK_SIZE_PX, ARTWORK_SIZE_PX, Bitmap.Config.ARGB_8888)
        val drawable = ContextCompat.getDrawable(appContext, R.drawable.ic_artwork_default)
        if (drawable != null) {
            drawable.setBounds(0, 0, ARTWORK_SIZE_PX, ARTWORK_SIZE_PX)
            drawable.draw(Canvas(bitmap))
        }
        return bitmap
    }

    private companion object {
        const val ARTWORK_SIZE_PX = 512
    }
}
EOF

echo "  -> app/src/main/java/com/elg/music/ui/SystemBarInsets.kt"
mkdir -p app/src/main/java/com/elg/music/ui
cat << 'EOF' > app/src/main/java/com/elg/music/ui/SystemBarInsets.kt
package com.elg.music.ui

import android.view.View
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat

/**
 * Garde le contenu de l'écran à l'intérieur de la zone libre : ni sous la barre d'état, ni sous
 * la barre de navigation (boutons ou geste), ni sous une encoche, et au-dessus du clavier quand
 * il est ouvert. Depuis Android 15 les applications s'affichent bord à bord : sans cette marge,
 * le titre passait sous l'heure et le mini-lecteur sous les boutons de navigation.
 *
 * À appeler sur la vue racine de chaque écran.
 */
fun View.applySystemBarPadding() {
    ViewCompat.setOnApplyWindowInsetsListener(this) { view, windowInsets ->
        val insets = windowInsets.getInsets(
            WindowInsetsCompat.Type.systemBars() or
                WindowInsetsCompat.Type.displayCutout() or
                WindowInsetsCompat.Type.ime()
        )
        view.setPadding(insets.left, insets.top, insets.right, insets.bottom)
        WindowInsetsCompat.CONSUMED
    }
}
EOF

echo "  -> app/src/main/res/drawable/ic_sort.xml"
mkdir -p app/src/main/res/drawable
cat << 'EOF' > app/src/main/res/drawable/ic_sort.xml
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#FF000000"
        android:pathData="M16,17.01V10h-2v7.01h-3L15,21l4,-3.99h-3zM9,3L5,6.99h3V14h2V6.99h3L9,3z" />
</vector>
EOF

echo "  -> app/src/main/res/drawable/ic_artwork_default.xml"
mkdir -p app/src/main/res/drawable
cat << 'EOF' > app/src/main/res/drawable/ic_artwork_default.xml
<?xml version="1.0" encoding="utf-8"?>
<!-- Pochette par défaut : fond bleu nuit (couleur de l'icône de l'application) + note de musique.
     Rendue en bitmap par ArtworkBitmapLoader pour la notification et l'écran de verrouillage. -->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="512dp"
    android:height="512dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <path
        android:fillColor="#1F2A44"
        android:pathData="M0,0h108v108h-108z" />
    <group
        android:scaleX="2.2"
        android:scaleY="2.2"
        android:translateX="27.6"
        android:translateY="27.6">
        <path
            android:fillColor="#E8EDFB"
            android:pathData="M12,3v10.55c-0.59,-0.34 -1.27,-0.55 -2,-0.55c-2.21,0 -4,1.79 -4,4s1.79,4 4,4s4,-1.79 4,-4L14,7h4L18,3L12,3z" />
    </group>
</vector>
EOF

echo "  -> app/src/main/java/com/elg/music/data/local/PlaylistStore.kt"
mkdir -p app/src/main/java/com/elg/music/data/local
cat << 'EOF' > app/src/main/java/com/elg/music/data/local/PlaylistStore.kt
package com.elg.music.data.local

import android.content.Context
import android.net.Uri
import com.elg.music.data.model.Playlist
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject
import java.util.UUID

/**
 * Enregistre les playlists de l'utilisateur en JSON dans des SharedPreferences dédiées.
 *
 * Format : un tableau d'objets {"id", "name", "createdAt", "songs": [uri, ...]}. Chaque morceau
 * est identifié par la chaîne de son Uri MediaStore, comme les favoris et la liste noire de
 * [LibraryPreferences]. Toutes les méthodes sont synchronisées : l'état enregistré reste cohérent
 * même si plusieurs écrans y accèdent.
 */
class PlaylistStore(context: Context) {

    private val prefs = context.applicationContext.getSharedPreferences(
        PREFS_NAME,
        Context.MODE_PRIVATE
    )

    @Synchronized
    fun getAll(): List<Playlist> = readAll()

    /** Crée une playlist vide. Le nom doit déjà avoir été validé (non vide, non dupliqué). */
    @Synchronized
    fun create(name: String): Playlist {
        val playlist = Playlist(
            id = UUID.randomUUID().toString(),
            name = name.trim(),
            createdAtMs = System.currentTimeMillis(),
            songUris = emptyList()
        )
        writeAll(readAll() + playlist)
        return playlist
    }

    @Synchronized
    fun delete(playlistId: String) {
        writeAll(readAll().filterNot { it.id == playlistId })
    }

    /** Ajoute un morceau à la fin de la playlist. Renvoie false s'il y est déjà (ou si la playlist n'existe plus). */
    @Synchronized
    fun addSong(playlistId: String, songUri: Uri): Boolean {
        val playlists = readAll()
        val index = playlists.indexOfFirst { it.id == playlistId }
        if (index == -1) return false
        val key = songUri.toString()
        val playlist = playlists[index]
        if (playlist.songUris.contains(key)) return false
        val updated = playlists.toMutableList()
        updated[index] = playlist.copy(songUris = playlist.songUris + key)
        writeAll(updated)
        return true
    }

    @Synchronized
    fun removeSong(playlistId: String, songUri: Uri) {
        val key = songUri.toString()
        writeAll(
            readAll().map { playlist ->
                if (playlist.id == playlistId) {
                    playlist.copy(songUris = playlist.songUris.filterNot { it == key })
                } else {
                    playlist
                }
            }
        )
    }

    private fun readAll(): List<Playlist> {
        val raw = prefs.getString(KEY_PLAYLISTS, null) ?: return emptyList()
        return try {
            val array = JSONArray(raw)
            val result = ArrayList<Playlist>(array.length())
            for (i in 0 until array.length()) {
                val item = array.getJSONObject(i)
                val songsJson = item.optJSONArray(FIELD_SONGS) ?: JSONArray()
                val uris = ArrayList<String>(songsJson.length())
                for (j in 0 until songsJson.length()) {
                    uris.add(songsJson.getString(j))
                }
                result.add(
                    Playlist(
                        id = item.getString(FIELD_ID),
                        name = item.getString(FIELD_NAME),
                        createdAtMs = item.optLong(FIELD_CREATED_AT, 0L),
                        songUris = uris
                    )
                )
            }
            result
        } catch (invalidJson: JSONException) {
            emptyList()
        }
    }

    private fun writeAll(playlists: List<Playlist>) {
        val array = JSONArray()
        for (playlist in playlists) {
            val item = JSONObject()
            item.put(FIELD_ID, playlist.id)
            item.put(FIELD_NAME, playlist.name)
            item.put(FIELD_CREATED_AT, playlist.createdAtMs)
            val songs = JSONArray()
            for (uri in playlist.songUris) {
                songs.put(uri)
            }
            item.put(FIELD_SONGS, songs)
            array.put(item)
        }
        prefs.edit().putString(KEY_PLAYLISTS, array.toString()).apply()
    }

    private companion object {
        const val PREFS_NAME = "elg_music_playlists"
        const val KEY_PLAYLISTS = "playlists_json"
        const val FIELD_ID = "id"
        const val FIELD_NAME = "name"
        const val FIELD_CREATED_AT = "createdAt"
        const val FIELD_SONGS = "songs"
    }
}
EOF

echo "  -> app/src/main/java/com/elg/music/data/model/FolderItem.kt"
mkdir -p app/src/main/java/com/elg/music/data/model
cat << 'EOF' > app/src/main/java/com/elg/music/data/model/FolderItem.kt
package com.elg.music.data.model

/**
 * Dossier physique contenant de la musique, tel que déduit du champ RELATIVE_PATH du MediaStore.
 *
 * @param path chemin relatif brut (ex. "Music/Afrobeat/"), identifiant unique du dossier ;
 *   chaîne vide pour la racine du stockage.
 * @param name nom affiché : dernier segment du chemin (ex. "Afrobeat").
 * @param displayPath chemin affiché, précédé d'une barre oblique (ex. "/Music/Afrobeat/").
 * @param songCount nombre de titres de la bibliothèque contenus dans ce dossier.
 */
data class FolderItem(
    val path: String,
    val name: String,
    val displayPath: String,
    val songCount: Int
)
EOF

echo "  -> app/src/main/java/com/elg/music/data/model/Playlist.kt"
mkdir -p app/src/main/java/com/elg/music/data/model
cat << 'EOF' > app/src/main/java/com/elg/music/data/model/Playlist.kt
package com.elg.music.data.model

/**
 * Playlist telle qu'enregistrée sur l'appareil.
 *
 * @param id identifiant unique (UUID), stable même si la playlist est renommée un jour.
 * @param name nom choisi par l'utilisateur.
 * @param createdAtMs date de création (millisecondes depuis 1970).
 * @param songUris morceaux dans l'ordre d'ajout, identifiés par la chaîne de leur Uri MediaStore
 *   (même convention que les favoris et la liste noire).
 */
data class Playlist(
    val id: String,
    val name: String,
    val createdAtMs: Long,
    val songUris: List<String>
)

/**
 * Vue d'une playlist pour l'affichage : [songCount] ne compte que les morceaux actuellement
 * présents dans la bibliothèque (un fichier supprimé ou masqué n'est pas compté).
 */
data class PlaylistSummary(
    val id: String,
    val name: String,
    val songCount: Int,
    val createdAtMs: Long
)
EOF

echo "  -> app/src/main/java/com/elg/music/ui/main/FolderAdapter.kt"
mkdir -p app/src/main/java/com/elg/music/ui/main
cat << 'EOF' > app/src/main/java/com/elg/music/ui/main/FolderAdapter.kt
package com.elg.music.ui.main

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import androidx.recyclerview.widget.RecyclerView
import com.elg.music.R
import com.elg.music.data.model.FolderItem
import com.elg.music.databinding.ItemFolderBinding

/**
 * Liste des dossiers de l'onglet Dossiers : nom, nombre de titres et chemin relatif.
 *
 * @param onFolderClicked appelé quand l'utilisateur touche un dossier (ouverture de son contenu).
 */
class FolderAdapter(
    private val onFolderClicked: (FolderItem) -> Unit
) : ListAdapter<FolderItem, FolderAdapter.FolderViewHolder>(FolderDiffCallback()) {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): FolderViewHolder {
        val binding = ItemFolderBinding.inflate(LayoutInflater.from(parent.context), parent, false)
        return FolderViewHolder(binding)
    }

    override fun onBindViewHolder(holder: FolderViewHolder, position: Int) {
        holder.bind(getItem(position))
    }

    inner class FolderViewHolder(private val binding: ItemFolderBinding) :
        RecyclerView.ViewHolder(binding.root) {

        fun bind(folder: FolderItem) {
            val context = binding.root.context
            val countText = context.resources.getQuantityString(
                R.plurals.song_count,
                folder.songCount,
                folder.songCount
            )
            binding.textFolderName.text = folder.name
            binding.textFolderDetails.text =
                context.getString(R.string.folder_details_format, countText, folder.displayPath)
            binding.root.contentDescription =
                context.getString(R.string.folder_row_content_description, folder.name, countText)
            binding.root.setOnClickListener { onFolderClicked(folder) }
        }
    }

    private class FolderDiffCallback : DiffUtil.ItemCallback<FolderItem>() {
        override fun areItemsTheSame(oldItem: FolderItem, newItem: FolderItem): Boolean =
            oldItem.path == newItem.path

        override fun areContentsTheSame(oldItem: FolderItem, newItem: FolderItem): Boolean =
            oldItem == newItem
    }
}
EOF

echo "  -> app/src/main/java/com/elg/music/ui/main/PlaylistAdapter.kt"
mkdir -p app/src/main/java/com/elg/music/ui/main
cat << 'EOF' > app/src/main/java/com/elg/music/ui/main/PlaylistAdapter.kt
package com.elg.music.ui.main

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import androidx.recyclerview.widget.RecyclerView
import com.elg.music.R
import com.elg.music.data.model.PlaylistSummary
import com.elg.music.databinding.ItemPlaylistBinding
import java.text.DateFormat
import java.util.Date

/**
 * Liste des playlists de l'onglet Playlists : nom, nombre de titres et date de création.
 *
 * @param onPlaylistClicked appelé quand l'utilisateur touche la ligne (ouverture de la playlist).
 * @param onMenuClicked appelé quand l'utilisateur touche le bouton "..." (options de la playlist).
 */
class PlaylistAdapter(
    private val onPlaylistClicked: (PlaylistSummary) -> Unit,
    private val onMenuClicked: (PlaylistSummary, View) -> Unit
) : ListAdapter<PlaylistSummary, PlaylistAdapter.PlaylistViewHolder>(PlaylistDiffCallback()) {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): PlaylistViewHolder {
        val binding = ItemPlaylistBinding.inflate(LayoutInflater.from(parent.context), parent, false)
        return PlaylistViewHolder(binding)
    }

    override fun onBindViewHolder(holder: PlaylistViewHolder, position: Int) {
        holder.bind(getItem(position))
    }

    inner class PlaylistViewHolder(private val binding: ItemPlaylistBinding) :
        RecyclerView.ViewHolder(binding.root) {

        fun bind(playlist: PlaylistSummary) {
            val context = binding.root.context
            val countText = context.resources.getQuantityString(
                R.plurals.song_count,
                playlist.songCount,
                playlist.songCount
            )
            val dateText = DateFormat.getDateInstance(DateFormat.MEDIUM)
                .format(Date(playlist.createdAtMs))

            binding.textPlaylistName.text = playlist.name
            binding.textPlaylistDetails.text =
                context.getString(R.string.playlist_row_details_format, countText, dateText)
            binding.root.contentDescription =
                context.getString(R.string.playlist_row_content_description, playlist.name, countText)
            binding.buttonPlaylistMenu.contentDescription =
                context.getString(R.string.playlist_menu_button_description, playlist.name)

            binding.root.setOnClickListener { onPlaylistClicked(playlist) }
            binding.buttonPlaylistMenu.setOnClickListener { anchor -> onMenuClicked(playlist, anchor) }
        }
    }

    private class PlaylistDiffCallback : DiffUtil.ItemCallback<PlaylistSummary>() {
        override fun areItemsTheSame(oldItem: PlaylistSummary, newItem: PlaylistSummary): Boolean =
            oldItem.id == newItem.id

        override fun areContentsTheSame(oldItem: PlaylistSummary, newItem: PlaylistSummary): Boolean =
            oldItem == newItem
    }
}
EOF

echo "  -> app/src/main/res/color/toggle_tint.xml"
mkdir -p app/src/main/res/color
cat << 'EOF' > app/src/main/res/color/toggle_tint.xml
<?xml version="1.0" encoding="utf-8"?>
<!-- Teinte des boutons à bascule du mini-lecteur (aléatoire, répétition) :
     couleur d'accent quand le mode est actif (état "selected"), couleur discrète sinon. -->
<selector xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:color="?attr/colorPrimary" android:state_selected="true" />
    <item android:color="?attr/colorOnSurfaceVariant" />
</selector>
EOF

echo "  -> app/src/main/res/drawable/ic_add.xml"
mkdir -p app/src/main/res/drawable
cat << 'EOF' > app/src/main/res/drawable/ic_add.xml
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#FF000000"
        android:pathData="M19,13h-6v6h-2v-6H5v-2h6V5h2v6h6v2z" />
</vector>
EOF

echo "  -> app/src/main/res/drawable/ic_arrow_back.xml"
mkdir -p app/src/main/res/drawable
cat << 'EOF' > app/src/main/res/drawable/ic_arrow_back.xml
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#FF000000"
        android:pathData="M20,11H7.83l5.59,-5.59L12,4l-8,8 8,8 1.41,-1.41L7.83,13H20v-2z" />
</vector>
EOF

echo "  -> app/src/main/res/drawable/ic_favorite_border.xml"
mkdir -p app/src/main/res/drawable
cat << 'EOF' > app/src/main/res/drawable/ic_favorite_border.xml
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="64dp"
    android:height="64dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#FF000000"
        android:pathData="M16.5,3c-1.74,0 -3.41,0.81 -4.5,2.09C10.91,3.81 9.24,3 7.5,3 4.42,3 2,5.42 2,8.5c0,3.78 3.4,6.86 8.55,11.54L12,21.35l1.45,-1.32C18.6,15.36 22,12.28 22,8.5 22,5.42 19.58,3 16.5,3zM12.1,18.55l-0.1,0.1 -0.1,-0.1C7.14,14.24 4,11.39 4,8.5 4,6.5 5.5,5 7.5,5c1.54,0 3.04,0.99 3.57,2.36h1.87C13.46,5.99 14.96,5 16.5,5c2,0 3.5,1.5 3.5,3.5 0,2.89 -3.14,5.74 -7.9,10.05z" />
</vector>
EOF

echo "  -> app/src/main/res/drawable/ic_folder.xml"
mkdir -p app/src/main/res/drawable
cat << 'EOF' > app/src/main/res/drawable/ic_folder.xml
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#FF000000"
        android:pathData="M10,4H4c-1.1,0 -1.99,0.9 -1.99,2L2,18c0,1.1 0.9,2 2,2h16c1.1,0 2,-0.9 2,-2V8c0,-1.1 -0.9,-2 -2,-2h-8l-2,-2z" />
</vector>
EOF

echo "  -> app/src/main/res/drawable/ic_playlist.xml"
mkdir -p app/src/main/res/drawable
cat << 'EOF' > app/src/main/res/drawable/ic_playlist.xml
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#FF000000"
        android:pathData="M15,6H3v2h12V6zM15,10H3v2h12v-2zM3,16h8v-2H3v2zM17,6v8.18c-0.31,-0.11 -0.65,-0.18 -1,-0.18 -1.66,0 -3,1.34 -3,3s1.34,3 3,3 3,-1.34 3,-3V8h3V6h-5z" />
</vector>
EOF

echo "  -> app/src/main/res/drawable/ic_repeat.xml"
mkdir -p app/src/main/res/drawable
cat << 'EOF' > app/src/main/res/drawable/ic_repeat.xml
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#FF000000"
        android:pathData="M7,7h10v3l4,-4 -4,-4v3L5,5v6h2L7,7zM17,17L7,17v-3l-4,4 4,4v-3h12v-6h-2v4z" />
</vector>
EOF

echo "  -> app/src/main/res/drawable/ic_repeat_one.xml"
mkdir -p app/src/main/res/drawable
cat << 'EOF' > app/src/main/res/drawable/ic_repeat_one.xml
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#FF000000"
        android:pathData="M7,7h10v3l4,-4 -4,-4v3L5,5v6h2L7,7zM17,17L7,17v-3l-4,4 4,4v-3h12v-6h-2v4zM13,15L13,9h-1l-2,1v1h1.5v4L13,15z" />
</vector>
EOF

echo "  -> app/src/main/res/drawable/ic_shuffle.xml"
mkdir -p app/src/main/res/drawable
cat << 'EOF' > app/src/main/res/drawable/ic_shuffle.xml
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#FF000000"
        android:pathData="M10.59,9.17L5.41,4 4,5.41l5.17,5.17 1.42,-1.41zM14.5,4l2.04,2.04L4,18.59 5.41,20 17.96,7.46 20,9.5L20,4h-5.5zM14.83,13.41l-1.41,1.41 3.13,3.13L14.5,20L20,20v-5.5l-2.04,2.04 -3.13,-3.13z" />
</vector>
EOF

echo "  -> app/src/main/res/layout/dialog_playlist_name.xml"
mkdir -p app/src/main/res/layout
cat << 'EOF' > app/src/main/res/layout/dialog_playlist_name.xml
<?xml version="1.0" encoding="utf-8"?>
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:paddingStart="24dp"
    android:paddingTop="8dp"
    android:paddingEnd="24dp">

    <com.google.android.material.textfield.TextInputLayout
        android:id="@+id/inputLayoutPlaylistName"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:hint="@string/playlist_name_hint">

        <com.google.android.material.textfield.TextInputEditText
            android:id="@+id/editPlaylistName"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:imeOptions="actionDone"
            android:inputType="textCapSentences"
            android:maxLength="60"
            android:maxLines="1" />

    </com.google.android.material.textfield.TextInputLayout>

</FrameLayout>
EOF

echo "  -> app/src/main/res/layout/item_folder.xml"
mkdir -p app/src/main/res/layout
cat << 'EOF' > app/src/main/res/layout/item_folder.xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    xmlns:tools="http://schemas.android.com/tools"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:background="?attr/selectableItemBackground"
    android:clickable="true"
    android:focusable="true"
    android:gravity="center_vertical"
    android:minHeight="64dp"
    android:orientation="horizontal"
    android:paddingStart="16dp"
    android:paddingTop="8dp"
    android:paddingEnd="16dp"
    android:paddingBottom="8dp">

    <ImageView
        android:layout_width="48dp"
        android:layout_height="48dp"
        android:importantForAccessibility="no"
        android:scaleType="centerInside"
        android:src="@drawable/ic_folder"
        app:tint="?attr/colorOnSurfaceVariant" />

    <LinearLayout
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:layout_marginStart="16dp"
        android:layout_weight="1"
        android:orientation="vertical">

        <TextView
            android:id="@+id/textFolderName"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:ellipsize="end"
            android:maxLines="1"
            android:textAppearance="?attr/textAppearanceBodyLarge"
            android:textStyle="bold"
            tools:text="Afrobeat" />

        <TextView
            android:id="@+id/textFolderDetails"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:layout_marginTop="2dp"
            android:ellipsize="middle"
            android:maxLines="1"
            android:textAppearance="?attr/textAppearanceBodyMedium"
            android:textColor="?attr/colorOnSurfaceVariant"
            tools:text="12 titres · /Music/Afrobeat/" />

    </LinearLayout>

</LinearLayout>
EOF

echo "  -> app/src/main/res/layout/item_playlist.xml"
mkdir -p app/src/main/res/layout
cat << 'EOF' > app/src/main/res/layout/item_playlist.xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    xmlns:tools="http://schemas.android.com/tools"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:background="?attr/selectableItemBackground"
    android:clickable="true"
    android:focusable="true"
    android:gravity="center_vertical"
    android:minHeight="64dp"
    android:orientation="horizontal"
    android:paddingStart="16dp"
    android:paddingTop="8dp"
    android:paddingEnd="4dp"
    android:paddingBottom="8dp">

    <ImageView
        android:layout_width="48dp"
        android:layout_height="48dp"
        android:importantForAccessibility="no"
        android:scaleType="centerInside"
        android:src="@drawable/ic_playlist"
        app:tint="?attr/colorOnSurfaceVariant" />

    <LinearLayout
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:layout_marginStart="16dp"
        android:layout_weight="1"
        android:orientation="vertical">

        <TextView
            android:id="@+id/textPlaylistName"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:ellipsize="end"
            android:maxLines="1"
            android:textAppearance="?attr/textAppearanceBodyLarge"
            android:textStyle="bold"
            tools:text="Ma playlist" />

        <TextView
            android:id="@+id/textPlaylistDetails"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:layout_marginTop="2dp"
            android:ellipsize="end"
            android:maxLines="1"
            android:textAppearance="?attr/textAppearanceBodyMedium"
            android:textColor="?attr/colorOnSurfaceVariant"
            tools:text="12 titres · créée le 29 sept. 2026" />

    </LinearLayout>

    <ImageButton
        android:id="@+id/buttonPlaylistMenu"
        android:layout_width="48dp"
        android:layout_height="48dp"
        android:background="?attr/selectableItemBackgroundBorderless"
        android:src="@drawable/ic_more_vert"
        app:tint="?attr/colorOnSurfaceVariant"
        tools:ignore="ContentDescription" />

</LinearLayout>
EOF

echo "  -> app/src/main/res/menu/menu_playlist_item.xml"
mkdir -p app/src/main/res/menu
cat << 'EOF' > app/src/main/res/menu/menu_playlist_item.xml
<?xml version="1.0" encoding="utf-8"?>
<menu xmlns:android="http://schemas.android.com/apk/res/android">

    <item
        android:id="@+id/action_delete_playlist"
        android:title="@string/playlist_delete_action" />

</menu>
EOF

echo "  -> app/src/main/java/com/elg/music/data/model/LibraryGroups.kt"
mkdir -p app/src/main/java/com/elg/music/data/model
cat << 'EOF' > app/src/main/java/com/elg/music/data/model/LibraryGroups.kt
package com.elg.music.data.model

import android.net.Uri

/**
 * Artiste de la bibliothèque (onglet Artistes).
 *
 * @param key identifiant de regroupement (nom en minuscules) ; unique par artiste.
 * @param name nom affiché ("Inconnu" si les morceaux n'ont pas d'artiste).
 * @param albumCount nombre d'albums différents de cet artiste.
 * @param songCount nombre de morceaux de cet artiste.
 * @param artworkUri Uri d'un morceau de l'artiste, dont on extrait la vignette ; null si aucun.
 */
data class ArtistItem(
    val key: String,
    val name: String,
    val albumCount: Int,
    val songCount: Int,
    val artworkUri: Uri?
)

/**
 * Album de la bibliothèque (onglet Albums).
 *
 * @param key identifiant de regroupement (identifiant d'album MediaStore, sinon nom d'album).
 * @param title titre affiché ("Album inconnu" si absent).
 * @param artistName artiste principal : le plus fréquent parmi les pistes ("Inconnu" si aucun).
 * @param trackCount nombre de pistes de l'album.
 * @param artworkUri Uri d'une piste de l'album, dont on extrait la pochette ; null si aucune.
 */
data class AlbumItem(
    val key: String,
    val title: String,
    val artistName: String,
    val trackCount: Int,
    val artworkUri: Uri?
)
EOF

echo "  -> app/src/main/java/com/elg/music/playback/MidiSupport.kt"
mkdir -p app/src/main/java/com/elg/music/playback
cat << 'EOF' > app/src/main/java/com/elg/music/playback/MidiSupport.kt
package com.elg.music.playback

import android.content.Context
import android.media.MediaPlayer
import android.net.Uri
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
import java.io.File
import java.io.FileOutputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.math.abs

/**
 * Lecture des fichiers MIDI (.mid / .midi), que ExoPlayer ne sait pas décoder.
 *
 * Principe, qui laisse toute la logique de file d'attente, de répétition, d'aléatoire, de
 * notification et de barre de progression à ExoPlayer :
 *  1. À l'ajout dans la file (voir [replaceMidiWithSilence]), un morceau MIDI est remplacé par un
 *     fichier WAV silencieux de même durée, mais garde son identifiant et ses métadonnées ; l'Uri
 *     du vrai fichier MIDI est conservée dans les extras des métadonnées ([EXTRA_MIDI_URI]).
 *  2. [MidiCompanion] écoute ExoPlayer : quand le morceau courant est un MIDI, il fait jouer le
 *     vrai fichier par le MediaPlayer natif d'Android, synchronisé sur l'état d'ExoPlayer
 *     (lecture, pause, déplacement dans le morceau, changement de morceau).
 */
object MidiSupport {

    /** Clé, dans les extras des métadonnées, de l'Uri du fichier MIDI à jouer. */
    const val EXTRA_MIDI_URI = "elg.midi_uri"

    private const val DEFAULT_MIDI_DURATION_MS = 180_000L
    private const val SILENCE_SAMPLE_RATE = 8000
    private const val MAX_SILENCE_SECONDS = 3600L

    fun midiUriOf(item: MediaItem?): Uri? =
        item?.mediaMetadata?.extras?.getString(EXTRA_MIDI_URI)?.let { Uri.parse(it) }

    /** Remplace chaque morceau MIDI par sa version silencieuse ; les autres morceaux sont inchangés. */
    fun replaceMidiWithSilence(context: Context, items: List<MediaItem>): List<MediaItem> =
        items.map { item ->
            if (midiUriOf(item) == null) {
                item
            } else {
                val durationMs = item.mediaMetadata.durationMs ?: DEFAULT_MIDI_DURATION_MS
                val silence = silenceFile(context, durationMs)
                item.buildUpon().setUri(Uri.fromFile(silence)).build()
            }
        }

    private fun silenceFile(context: Context, durationMs: Long): File {
        val seconds = ((durationMs + 999L) / 1000L).coerceIn(1L, MAX_SILENCE_SECONDS).toInt()
        val target = File(context.cacheDir, "midi_silence_${seconds}s.wav")
        if (target.exists() && target.length() > 0L) return target

        // Écriture dans un fichier temporaire puis renommage : jamais de fichier à moitié écrit.
        val temp = File(context.cacheDir, "midi_silence_${seconds}s.tmp")
        val dataSize = seconds * SILENCE_SAMPLE_RATE * 2 // 16 bits, mono
        val header = ByteBuffer.allocate(44).order(ByteOrder.LITTLE_ENDIAN)
        header.put("RIFF".toByteArray(Charsets.US_ASCII))
        header.putInt(36 + dataSize)
        header.put("WAVE".toByteArray(Charsets.US_ASCII))
        header.put("fmt ".toByteArray(Charsets.US_ASCII))
        header.putInt(16)
        header.putShort(1) // PCM
        header.putShort(1) // mono
        header.putInt(SILENCE_SAMPLE_RATE)
        header.putInt(SILENCE_SAMPLE_RATE * 2) // octets par seconde
        header.putShort(2) // octets par échantillon
        header.putShort(16) // bits par échantillon
        header.put("data".toByteArray(Charsets.US_ASCII))
        header.putInt(dataSize)
        FileOutputStream(temp).use { out ->
            out.write(header.array())
            val oneSecond = ByteArray(SILENCE_SAMPLE_RATE * 2)
            repeat(seconds) { out.write(oneSecond) }
        }
        if (!temp.renameTo(target)) {
            temp.copyTo(target, overwrite = true)
            temp.delete()
        }
        return target
    }
}

/**
 * Fait jouer un fichier MIDI par le [MediaPlayer] natif, en suivant [exoPlayer] qui, lui, joue le
 * silence de même durée (voir [MidiSupport]). Sans effet tant que le morceau courant n'est pas MIDI.
 */
class MidiCompanion(
    private val context: Context,
    private val exoPlayer: ExoPlayer
) : Player.Listener {

    private var midiPlayer: MediaPlayer? = null
    private var midiReady = false
    private var activeMediaId: String? = null

    fun attach() {
        exoPlayer.addListener(this)
        syncWithCurrentItem(restart = false)
    }

    fun release() {
        exoPlayer.removeListener(this)
        stopMidi()
    }

    override fun onMediaItemTransition(mediaItem: MediaItem?, reason: Int) {
        syncWithCurrentItem(restart = reason == Player.MEDIA_ITEM_TRANSITION_REASON_REPEAT)
    }

    override fun onIsPlayingChanged(isPlaying: Boolean) {
        if (isPlaying && midiPlayer == null) {
            // Relecture après la fin de la liste : on recrée le lecteur MIDI si besoin.
            syncWithCurrentItem(restart = true)
            return
        }
        val player = midiPlayer ?: return
        if (!midiReady) return // le démarrage se fera à la fin de la préparation
        try {
            if (isPlaying) {
                alignPosition(player)
                player.start()
            } else if (player.isPlaying) {
                player.pause()
            }
        } catch (illegalState: IllegalStateException) {
            stopMidi()
        }
    }

    override fun onPositionDiscontinuity(
        oldPosition: Player.PositionInfo,
        newPosition: Player.PositionInfo,
        reason: Int
    ) {
        val player = midiPlayer ?: return
        if (!midiReady) return
        if (reason == Player.DISCONTINUITY_REASON_SEEK ||
            reason == Player.DISCONTINUITY_REASON_SEEK_ADJUSTMENT
        ) {
            try {
                player.seekTo(newPosition.positionMs.toInt())
            } catch (illegalState: IllegalStateException) {
                stopMidi()
            }
        }
    }

    override fun onPlaybackStateChanged(playbackState: Int) {
        if (playbackState == Player.STATE_ENDED) stopMidi()
    }

    private fun syncWithCurrentItem(restart: Boolean) {
        val item = exoPlayer.currentMediaItem
        val uri = MidiSupport.midiUriOf(item)
        if (item == null || uri == null) {
            stopMidi()
            return
        }
        if (!restart && item.mediaId == activeMediaId && midiPlayer != null) return

        stopMidi()
        activeMediaId = item.mediaId
        val player = MediaPlayer()
        midiPlayer = player
        try {
            player.setAudioAttributes(
                android.media.AudioAttributes.Builder()
                    .setUsage(android.media.AudioAttributes.USAGE_MEDIA)
                    .setContentType(android.media.AudioAttributes.CONTENT_TYPE_MUSIC)
                    .build()
            )
            player.setDataSource(context, uri)
            player.setOnPreparedListener { prepared ->
                if (midiPlayer === prepared) {
                    midiReady = true
                    alignPosition(prepared)
                    if (exoPlayer.isPlaying) prepared.start()
                }
            }
            player.setOnErrorListener { _, _, _ ->
                stopMidi()
                true
            }
            player.prepareAsync()
        } catch (error: Exception) {
            stopMidi()
        }
    }

    private fun alignPosition(player: MediaPlayer) {
        val target = exoPlayer.currentPosition.toInt().coerceAtLeast(0)
        if (abs(player.currentPosition - target) > 400) player.seekTo(target)
    }

    private fun stopMidi() {
        midiPlayer?.let { player ->
            try {
                player.stop()
            } catch (illegalState: IllegalStateException) {
                // Lecteur pas encore préparé : rien à arrêter.
            }
            player.release()
        }
        midiPlayer = null
        midiReady = false
        activeMediaId = null
    }
}
EOF

echo "  -> app/src/main/java/com/elg/music/ui/ArtworkLoader.kt"
mkdir -p app/src/main/java/com/elg/music/ui
cat << 'EOF' > app/src/main/java/com/elg/music/ui/ArtworkLoader.kt
package com.elg.music.ui

import android.content.Context
import android.graphics.Bitmap
import android.net.Uri
import android.util.LruCache
import android.graphics.BitmapFactory
import android.util.Size
import android.widget.ImageView
import androidx.annotation.DrawableRes
import com.elg.music.data.repository.CoverCache
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * Charge les pochettes (vignettes) sans bibliothèque externe.
 *
 * La pochette d'un morceau est extraite du fichier lui-même par le système
 * (`ContentResolver.loadThumbnail`). Pendant le chargement, et si le fichier n'a pas de pochette,
 * l'image [placeholderRes] est affichée. Les vignettes sont gardées en mémoire (cache LRU), et les
 * fichiers sans pochette sont mémorisés pour ne pas être relus à chaque défilement.
 *
 * À utiliser depuis le thread principal uniquement.
 */
class ArtworkLoader(context: Context, private val scope: CoroutineScope) {

    private val appContext = context.applicationContext
    private val resolver = appContext.contentResolver

    private val cache = object : LruCache<String, Bitmap>(cacheSizeKb()) {
        override fun sizeOf(key: String, value: Bitmap): Int = value.byteCount / 1024
    }
    private val withoutArtwork = HashSet<String>()

    /**
     * Affiche la pochette de [uri] dans [target], à la taille [sizePx] (en pixels).
     * Une vue recyclée ne reçoit jamais la pochette d'une autre ligne : la clé demandée est
     * comparée à celle de la vue avant l'affichage.
     */
    fun load(target: ImageView, uri: Uri?, sizePx: Int, @DrawableRes placeholderRes: Int) {
        if (uri == null) {
            target.tag = null
            target.setImageResource(placeholderRes)
            return
        }
        val key = "$uri#$sizePx"
        target.tag = key
        val cached = cache.get(key)
        if (cached != null) {
            target.setImageBitmap(cached)
            return
        }
        target.setImageResource(placeholderRes)
        if (withoutArtwork.contains(key)) return

        scope.launch {
            val bitmap = withContext(Dispatchers.IO) { readThumbnail(uri, sizePx) }
            if (bitmap == null) {
                withoutArtwork.add(key)
            } else {
                cache.put(key, bitmap)
                if (target.tag == key) target.setImageBitmap(bitmap)
            }
        }
    }

    private fun readThumbnail(uri: Uri, sizePx: Int): Bitmap? {
        // Pochette du repli hybride (formats sans image interne) : conservée dans cacheDir/covers/.
        CoverCache.mediaIdOf(uri)?.let { id ->
            CoverCache.read(appContext, id)?.let { bytes ->
                val decoded = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
                if (decoded != null) {
                    // Recadrage carré centré, comme la vignette du système.
                    val side = minOf(decoded.width, decoded.height)
                    val square = Bitmap.createBitmap(decoded, (decoded.width - side) / 2, (decoded.height - side) / 2, side, side)
                    return Bitmap.createScaledBitmap(square, sizePx, sizePx, true)
                }
            }
        }
        return try {
            resolver.loadThumbnail(uri, Size(sizePx, sizePx), null)
        } catch (noArtwork: Exception) {
            null
        }
    }

    private fun cacheSizeKb(): Int = (Runtime.getRuntime().maxMemory() / 1024L / 8L).toInt()
}
EOF

echo "  -> app/src/main/java/com/elg/music/ui/main/AlbumAdapter.kt"
mkdir -p app/src/main/java/com/elg/music/ui/main
cat << 'EOF' > app/src/main/java/com/elg/music/ui/main/AlbumAdapter.kt
package com.elg.music.ui.main

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import androidx.recyclerview.widget.RecyclerView
import com.elg.music.R
import com.elg.music.data.model.AlbumItem
import com.elg.music.databinding.ItemAlbumBinding
import com.elg.music.ui.ArtworkLoader

/**
 * Grille des albums (onglet Albums, 2 colonnes) : grande vignette carrée, titre, puis
 * « Artiste | X piste(s) ».
 */
class AlbumAdapter(
    private val artworkLoader: ArtworkLoader,
    private val onAlbumClicked: (AlbumItem) -> Unit
) : ListAdapter<AlbumItem, AlbumAdapter.AlbumViewHolder>(AlbumDiffCallback()) {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): AlbumViewHolder {
        val binding = ItemAlbumBinding.inflate(LayoutInflater.from(parent.context), parent, false)
        return AlbumViewHolder(binding)
    }

    override fun onBindViewHolder(holder: AlbumViewHolder, position: Int) {
        holder.bind(getItem(position))
    }

    inner class AlbumViewHolder(private val binding: ItemAlbumBinding) :
        RecyclerView.ViewHolder(binding.root) {

        fun bind(album: AlbumItem) {
            val context = binding.root.context
            val tracks = context.resources.getQuantityString(R.plurals.track_count, album.trackCount, album.trackCount)
            val details = context.getString(R.string.album_details_format, album.artistName, tracks)

            binding.textAlbumTitle.text = album.title
            binding.textAlbumDetails.text = details
            binding.root.contentDescription =
                context.getString(R.string.album_row_content_description, album.title, details)
            binding.root.setOnClickListener { onAlbumClicked(album) }
            artworkLoader.load(
                binding.imageAlbum,
                album.artworkUri,
                COVER_SIZE_PX,
                R.drawable.ic_artwork_default
            )
        }
    }

    private class AlbumDiffCallback : DiffUtil.ItemCallback<AlbumItem>() {
        override fun areItemsTheSame(oldItem: AlbumItem, newItem: AlbumItem): Boolean =
            oldItem.key == newItem.key

        override fun areContentsTheSame(oldItem: AlbumItem, newItem: AlbumItem): Boolean =
            oldItem == newItem
    }

    private companion object {
        const val COVER_SIZE_PX = 480
    }
}
EOF

echo "  -> app/src/main/java/com/elg/music/ui/main/ArtistAdapter.kt"
mkdir -p app/src/main/java/com/elg/music/ui/main
cat << 'EOF' > app/src/main/java/com/elg/music/ui/main/ArtistAdapter.kt
package com.elg.music.ui.main

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import androidx.recyclerview.widget.RecyclerView
import com.elg.music.R
import com.elg.music.data.model.ArtistItem
import com.elg.music.databinding.ItemArtistBinding
import com.elg.music.ui.ArtworkLoader

/**
 * Liste verticale des artistes (onglet Artistes) : vignette circulaire, nom, puis
 * « X album(s) | Y morceau(x) ».
 */
class ArtistAdapter(
    private val artworkLoader: ArtworkLoader,
    private val onArtistClicked: (ArtistItem) -> Unit
) : ListAdapter<ArtistItem, ArtistAdapter.ArtistViewHolder>(ArtistDiffCallback()) {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ArtistViewHolder {
        val binding = ItemArtistBinding.inflate(LayoutInflater.from(parent.context), parent, false)
        return ArtistViewHolder(binding)
    }

    override fun onBindViewHolder(holder: ArtistViewHolder, position: Int) {
        holder.bind(getItem(position))
    }

    inner class ArtistViewHolder(private val binding: ItemArtistBinding) :
        RecyclerView.ViewHolder(binding.root) {

        fun bind(artist: ArtistItem) {
            val context = binding.root.context
            val albums = context.resources.getQuantityString(R.plurals.album_count, artist.albumCount, artist.albumCount)
            val songs = context.resources.getQuantityString(R.plurals.piece_count, artist.songCount, artist.songCount)
            val details = context.getString(R.string.artist_details_format, albums, songs)

            binding.textArtistName.text = artist.name
            binding.textArtistDetails.text = details
            binding.root.contentDescription =
                context.getString(R.string.artist_row_content_description, artist.name, details)
            binding.root.setOnClickListener { onArtistClicked(artist) }
            artworkLoader.load(
                binding.imageArtist,
                artist.artworkUri,
                THUMBNAIL_SIZE_PX,
                R.drawable.ic_artwork_default
            )
        }
    }

    private class ArtistDiffCallback : DiffUtil.ItemCallback<ArtistItem>() {
        override fun areItemsTheSame(oldItem: ArtistItem, newItem: ArtistItem): Boolean =
            oldItem.key == newItem.key

        override fun areContentsTheSame(oldItem: ArtistItem, newItem: ArtistItem): Boolean =
            oldItem == newItem
    }

    private companion object {
        const val THUMBNAIL_SIZE_PX = 192
    }
}
EOF

echo "  -> app/src/main/java/com/elg/music/ui/player/PlayerUi.kt"
mkdir -p app/src/main/java/com/elg/music/ui/player
cat << 'EOF' > app/src/main/java/com/elg/music/ui/player/PlayerUi.kt
package com.elg.music.ui.player

import android.annotation.SuppressLint
import android.view.MotionEvent
import android.view.View
import android.widget.SeekBar
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.accessibility.AccessibilityNodeInfoCompat
import androidx.media3.common.Player
import com.elg.music.R
import com.elg.music.databinding.ActivityMainBinding
import com.elg.music.playback.PlaybackUiState
import com.elg.music.playback.PlayerController
import com.elg.music.ui.ArtworkLoader
import com.google.android.material.bottomsheet.BottomSheetBehavior
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import java.util.Locale
import kotlin.math.abs

/**
 * Mini-lecteur (capsule flottante) et grand lecteur coulissant (BottomSheetBehavior).
 *
 * Le mini-lecteur affiche pochette, titre, artiste et les boutons précédent / lecture-pause /
 * suivant / file d'attente ; toucher la capsule ouvre le grand lecteur. Le grand lecteur ajoute
 * le bouton de réduction (V), la grande pochette, les raccourcis (file d'attente, favori, ajout à
 * une playlist), la barre de progression avec temps écoulé / durée, et les commandes principales
 * (aléatoire, précédent, lecture-pause, suivant, répétition).
 *
 * @param viewsBehindSheet vues de l'écran principal masquées à TalkBack tant que le grand lecteur
 *   est ouvert (sinon le lecteur d'écran lirait aussi ce qui se trouve derrière).
 * @param onQueueRequested ouvre la file d'attente.
 * @param onToggleFavorite bascule le favori du morceau dont on donne l'identifiant de lecture.
 * @param onAddToPlaylist ouvre le choix de playlist pour ce morceau.
 * @param isFavorite dit si ce morceau est un favori.
 * @param onSheetExpandedChanged prévenu quand le grand lecteur s'ouvre ou se ferme.
 * @param onMoreOptionsRequested ouvre le menu d'options du morceau en cours (bouton « Plus
 *   d'options » du grand lecteur) ; reçoit le bouton et l'identifiant de lecture du morceau.
 */
class PlayerUi(
    activity: AppCompatActivity,
    binding: ActivityMainBinding,
    private val playerController: PlayerController,
    private val artworkLoader: ArtworkLoader,
    private val scope: CoroutineScope,
    private val viewsBehindSheet: List<View>,
    private val onQueueRequested: () -> Unit,
    private val onToggleFavorite: (String) -> Unit,
    private val onAddToPlaylist: (String) -> Unit,
    private val isFavorite: (String) -> Boolean,
    private val onSheetExpandedChanged: (Boolean) -> Unit,
    private val onMoreOptionsRequested: (View, String) -> Unit = { _, _ -> }
) {

    private val context = activity
    private val mini = binding.miniPlayer
    private val sheet = binding.playerSheet
    private val behavior: BottomSheetBehavior<View> = BottomSheetBehavior.from<View>(sheet.root)

    private var seekHoldJob: Job? = null
    private var seekHoldTriggered = false
    private var isTrackingSeek = false
    private var lastArtworkKey: Any? = null
    private var lastRepeatMode = -1
    private var lastFavoriteMediaId: String? = null
    private var lastSeekAnnouncementSecond = -100L
    private var lastState = PlaybackUiState()

    val isExpanded: Boolean
        get() = behavior.state == BottomSheetBehavior.STATE_EXPANDED

    init {
        behavior.isHideable = true
        behavior.skipCollapsed = true
        behavior.isFitToContents = true
        behavior.state = BottomSheetBehavior.STATE_HIDDEN
        applyAccessibility(expanded = false)
        behavior.addBottomSheetCallback(object : BottomSheetBehavior.BottomSheetCallback() {
            override fun onStateChanged(bottomSheet: View, newState: Int) {
                when (newState) {
                    BottomSheetBehavior.STATE_EXPANDED -> {
                        applyAccessibility(expanded = true)
                        refreshFavoriteButton(force = true)
                        onSheetExpandedChanged(true)
                    }
                    BottomSheetBehavior.STATE_HIDDEN -> {
                        applyAccessibility(expanded = false)
                        onSheetExpandedChanged(false)
                    }
                    else -> Unit
                }
            }

            override fun onSlide(bottomSheet: View, slideOffset: Float) {}
        })

        // Capsule : toucher ouvre le grand lecteur ; TalkBack annonce l'action « Ouvrir le lecteur ».
        mini.root.setOnClickListener { expand() }
        ViewCompat.replaceAccessibilityAction(
            mini.root,
            AccessibilityNodeInfoCompat.AccessibilityActionCompat.ACTION_CLICK,
            context.getString(R.string.player_open_description),
            null
        )

        mini.buttonMiniPlayPause.setOnClickListener { playerController.togglePlayPause() }
        mini.buttonMiniQueue.setOnClickListener { onQueueRequested() }
        setupHoldToSeek(mini.buttonMiniPrevious, isForward = false)
        setupHoldToSeek(mini.buttonMiniNext, isForward = true)

        sheet.buttonPlayerCollapse.setOnClickListener { collapse() }
        sheet.buttonPlayerMore.setOnClickListener { anchor ->
            lastState.mediaId?.let { id -> onMoreOptionsRequested(anchor, id) }
        }
        sheet.buttonPlayerPlayPause.setOnClickListener { playerController.togglePlayPause() }
        sheet.buttonPlayerShuffle.setOnClickListener { playerController.toggleShuffle() }
        sheet.buttonPlayerRepeat.setOnClickListener { playerController.cycleRepeatMode() }
        sheet.buttonPlayerQueue.setOnClickListener { onQueueRequested() }
        sheet.buttonPlayerFavorite.setOnClickListener {
            lastState.mediaId?.let { id ->
                onToggleFavorite(id)
                refreshFavoriteButton(force = true)
            }
        }
        sheet.buttonPlayerAddPlaylist.setOnClickListener {
            lastState.mediaId?.let { id -> onAddToPlaylist(id) }
        }
        setupHoldToSeek(sheet.buttonPlayerPrevious, isForward = false)
        setupHoldToSeek(sheet.buttonPlayerNext, isForward = true)
        setupSeekBar()
    }

    fun expand() {
        if (lastState.title != null) behavior.state = BottomSheetBehavior.STATE_EXPANDED
    }

    fun collapse() {
        behavior.state = BottomSheetBehavior.STATE_HIDDEN
    }

    /** Arrête le défilement continu en cours (à appeler quand l'écran passe en arrière-plan). */
    fun cancelSeekHold() {
        seekHoldJob?.cancel()
        seekHoldJob = null
    }

    /** Met à jour les deux lecteurs à partir de l'état de lecture. */
    fun render(state: PlaybackUiState) {
        lastState = state
        val hasTrack = state.title != null
        mini.root.visibility = if (hasTrack) View.VISIBLE else View.GONE
        if (!hasTrack) {
            if (behavior.state != BottomSheetBehavior.STATE_HIDDEN) collapse()
            lastArtworkKey = null
            return
        }

        val artist = state.artist
        mini.textMiniTitle.text = state.title
        sheet.textPlayerTitle.text = state.title
        if (artist != null) {
            mini.textMiniArtist.text = artist
            mini.textMiniArtist.visibility = View.VISIBLE
            sheet.textPlayerArtist.text = artist
            sheet.textPlayerArtist.visibility = View.VISIBLE
        } else {
            mini.textMiniArtist.visibility = View.GONE
            sheet.textPlayerArtist.visibility = View.GONE
        }

        // Pochettes : rechargées seulement quand le morceau change.
        val artworkKey = state.artworkUri ?: state.mediaId
        if (artworkKey != lastArtworkKey) {
            lastArtworkKey = artworkKey
            artworkLoader.load(mini.imageMiniArt, state.artworkUri, MINI_ART_PX, R.drawable.ic_artwork_default)
            artworkLoader.load(sheet.imagePlayerArt, state.artworkUri, PLAYER_ART_PX, R.drawable.ic_artwork_default)
        }
        refreshFavoriteButton(force = false)

        val playPauseIcon = if (state.isPlaying) R.drawable.ic_pause else R.drawable.ic_play_arrow
        val playPauseDescription = context.getString(
            if (state.isPlaying) R.string.mini_player_pause_description else R.string.mini_player_play_description
        )
        mini.buttonMiniPlayPause.setImageResource(playPauseIcon)
        mini.buttonMiniPlayPause.contentDescription = playPauseDescription
        sheet.buttonPlayerPlayPause.setImageResource(playPauseIcon)
        sheet.buttonPlayerPlayPause.contentDescription = playPauseDescription

        renderShuffleAndRepeat(state)
        renderProgress(state)
    }

    // ===================== Détails =====================

    private fun renderShuffleAndRepeat(state: PlaybackUiState) {
        val shuffle = sheet.buttonPlayerShuffle
        shuffle.isSelected = state.shuffleEnabled
        ViewCompat.setStateDescription(
            shuffle,
            context.getString(if (state.shuffleEnabled) R.string.state_on else R.string.state_off)
        )

        // Le reste ne change que quand le mode de répétition change : inutile de le refaire à chaque tick.
        if (state.repeatMode == lastRepeatMode) return
        lastRepeatMode = state.repeatMode
        val repeat = sheet.buttonPlayerRepeat
        repeat.isSelected = state.repeatMode != Player.REPEAT_MODE_OFF
        repeat.setImageResource(
            if (state.repeatMode == Player.REPEAT_MODE_ONE) R.drawable.ic_repeat_one else R.drawable.ic_repeat
        )
        ViewCompat.setStateDescription(
            repeat,
            context.getString(
                when (state.repeatMode) {
                    Player.REPEAT_MODE_ALL -> R.string.state_repeat_all
                    Player.REPEAT_MODE_ONE -> R.string.state_repeat_one
                    else -> R.string.state_off
                }
            )
        )
    }

    private fun renderProgress(state: PlaybackUiState) {
        if (state.durationMs > 0L) {
            mini.progressMini.max = state.durationMs.toInt()
            mini.progressMini.setProgressCompat(state.positionMs.toInt(), true)
        }
        sheet.textPlayerDuration.text = formatTime(state.durationMs)
        sheet.seekPlayer.max = state.durationMs.coerceAtLeast(1L).toInt()
        if (!isTrackingSeek) {
            sheet.seekPlayer.progress = state.positionMs.toInt()
            sheet.textPlayerElapsed.text = formatTime(state.positionMs)
        }

        // Annonce TalkBack de la position, au plus toutes les 5 secondes pour ne pas la harceler.
        val second = state.positionMs / 1000L
        if (abs(second - lastSeekAnnouncementSecond) >= SEEK_ANNOUNCE_INTERVAL_S) {
            lastSeekAnnouncementSecond = second
            ViewCompat.setStateDescription(
                sheet.seekPlayer,
                context.getString(
                    R.string.player_seek_state,
                    formatTime(state.positionMs),
                    formatTime(state.durationMs)
                )
            )
        }
    }

    private fun setupSeekBar() {
        sheet.seekPlayer.setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
            override fun onProgressChanged(seekBar: SeekBar, progress: Int, fromUser: Boolean) {
                if (!fromUser) return
                sheet.textPlayerElapsed.text = formatTime(progress.toLong())
                // Déplacement par les actions d'accessibilité (TalkBack) : pas de glissement du doigt.
                if (!isTrackingSeek) playerController.seekTo(progress.toLong())
            }

            override fun onStartTrackingTouch(seekBar: SeekBar) {
                isTrackingSeek = true
            }

            override fun onStopTrackingTouch(seekBar: SeekBar) {
                isTrackingSeek = false
                playerController.seekTo(seekBar.progress.toLong())
            }
        })
    }

    private fun refreshFavoriteButton(force: Boolean) {
        val mediaId = lastState.mediaId
        if (!force && mediaId == lastFavoriteMediaId) return
        lastFavoriteMediaId = mediaId
        val favorite = mediaId != null && isFavorite(mediaId)
        sheet.buttonPlayerFavorite.setImageResource(
            if (favorite) R.drawable.ic_favorite else R.drawable.ic_favorite_border
        )
        sheet.buttonPlayerFavorite.contentDescription = context.getString(
            if (favorite) R.string.song_menu_remove_favorite else R.string.song_menu_add_favorite
        )
    }

    /** Ouvert : le lecteur est lu par TalkBack et l'écran derrière est masqué. Fermé : l'inverse. */
    private fun applyAccessibility(expanded: Boolean) {
        sheet.root.importantForAccessibility = if (expanded) {
            View.IMPORTANT_FOR_ACCESSIBILITY_YES
        } else {
            View.IMPORTANT_FOR_ACCESSIBILITY_NO_HIDE_DESCENDANTS
        }
        val behind = if (expanded) {
            View.IMPORTANT_FOR_ACCESSIBILITY_NO_HIDE_DESCENDANTS
        } else {
            View.IMPORTANT_FOR_ACCESSIBILITY_AUTO
        }
        viewsBehindSheet.forEach { it.importantForAccessibility = behind }
    }

    /**
     * Clic simple = morceau précédent/suivant. Appui long = avance/recul continu par tranches de
     * [SEEK_STEP_MS] tant que le bouton est maintenu, sans bloquer le thread UI (coroutine).
     * `performClick()` est appelé explicitement pour préserver le comportement d'accessibilité
     * standard (TalkBack) puisque le clic simple est détecté via `setOnTouchListener`.
     */
    @SuppressLint("ClickableViewAccessibility")
    private fun setupHoldToSeek(button: View, isForward: Boolean) {
        button.setOnClickListener {
            if (isForward) playerController.skipToNext() else playerController.skipToPrevious()
        }
        button.setOnTouchListener { view, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    seekHoldTriggered = false
                    seekHoldJob = scope.launch {
                        delay(LONG_PRESS_THRESHOLD_MS)
                        while (isActive) {
                            seekHoldTriggered = true
                            if (isForward) {
                                playerController.seekForward(SEEK_STEP_MS)
                            } else {
                                playerController.seekBackward(SEEK_STEP_MS)
                            }
                            delay(SEEK_REPEAT_INTERVAL_MS)
                        }
                    }
                    true
                }
                MotionEvent.ACTION_UP -> {
                    cancelSeekHold()
                    if (!seekHoldTriggered) view.performClick()
                    true
                }
                MotionEvent.ACTION_CANCEL -> {
                    cancelSeekHold()
                    true
                }
                else -> false
            }
        }
    }

    private fun formatTime(ms: Long): String {
        val totalSeconds = (ms / 1000L).coerceAtLeast(0L)
        val hours = totalSeconds / 3600L
        val minutes = (totalSeconds % 3600L) / 60L
        val seconds = totalSeconds % 60L
        return if (hours > 0L) {
            String.format(Locale.getDefault(), "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            String.format(Locale.getDefault(), "%d:%02d", minutes, seconds)
        }
    }

    private companion object {
        const val MINI_ART_PX = 132
        const val PLAYER_ART_PX = 720
        const val SEEK_ANNOUNCE_INTERVAL_S = 5L
        const val LONG_PRESS_THRESHOLD_MS = 500L
        const val SEEK_STEP_MS = 5000L
        const val SEEK_REPEAT_INTERVAL_MS = 400L
    }
}
EOF

echo "  -> app/src/main/java/com/elg/music/ui/player/QueueSheet.kt"
mkdir -p app/src/main/java/com/elg/music/ui/player
cat << 'EOF' > app/src/main/java/com/elg/music/ui/player/QueueSheet.kt
package com.elg.music.ui.player

import android.content.Context
import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.ListAdapter
import androidx.recyclerview.widget.RecyclerView
import com.elg.music.R
import com.elg.music.databinding.ItemQueueBinding
import com.elg.music.databinding.LayoutQueueSheetBinding
import com.elg.music.playback.QueueEntry
import com.google.android.material.bottomsheet.BottomSheetDialog

/** Ligne affichée dans la file d'attente. */
data class QueueRow(val index: Int, val title: String, val artist: String?, val isCurrent: Boolean)

/**
 * Feuille « File d'attente » : liste des morceaux à lire, le morceau en cours étant mis en évidence
 * et affiché en premier plan. Toucher un morceau le lance.
 */
object QueueSheet {

    fun show(context: Context, entries: List<QueueEntry>, currentIndex: Int, onPick: (Int) -> Unit) {
        val dialog = BottomSheetDialog(context)
        val binding = LayoutQueueSheetBinding.inflate(LayoutInflater.from(context))

        val defaultTitle = context.getString(R.string.default_song_title)
        val rows = entries.map { entry ->
            QueueRow(
                index = entry.index,
                title = entry.title.ifBlank { defaultTitle },
                artist = entry.artist,
                isCurrent = entry.index == currentIndex
            )
        }
        val adapter = QueueAdapter { row ->
            onPick(row.index)
            dialog.dismiss()
        }
        binding.recyclerQueue.layoutManager = LinearLayoutManager(context)
        binding.recyclerQueue.adapter = adapter
        binding.recyclerQueue.layoutParams.height =
            (context.resources.displayMetrics.heightPixels * 0.6f).toInt()
        adapter.submitList(rows) {
            val position = rows.indexOfFirst { it.isCurrent }
            if (position >= 0) {
                (binding.recyclerQueue.layoutManager as LinearLayoutManager)
                    .scrollToPositionWithOffset(position, 0)
            }
        }

        dialog.setContentView(binding.root)
        dialog.show()
    }

    private class QueueAdapter(
        private val onRowClicked: (QueueRow) -> Unit
    ) : ListAdapter<QueueRow, QueueAdapter.QueueViewHolder>(QueueDiffCallback()) {

        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): QueueViewHolder {
            val binding = ItemQueueBinding.inflate(LayoutInflater.from(parent.context), parent, false)
            return QueueViewHolder(binding)
        }

        override fun onBindViewHolder(holder: QueueViewHolder, position: Int) {
            holder.bind(getItem(position))
        }

        inner class QueueViewHolder(private val binding: ItemQueueBinding) :
            RecyclerView.ViewHolder(binding.root) {

            fun bind(row: QueueRow) {
                val context = binding.root.context
                binding.textQueueTitle.text = row.title
                binding.textQueueTitle.setTypeface(null, if (row.isCurrent) android.graphics.Typeface.BOLD else android.graphics.Typeface.NORMAL)
                if (row.artist != null) {
                    binding.textQueueArtist.text = row.artist
                    binding.textQueueArtist.visibility = android.view.View.VISIBLE
                } else {
                    binding.textQueueArtist.visibility = android.view.View.GONE
                }
                binding.imageQueueCurrent.visibility =
                    if (row.isCurrent) android.view.View.VISIBLE else android.view.View.INVISIBLE
                binding.root.contentDescription = if (row.isCurrent) {
                    context.getString(R.string.queue_row_current_description, row.title, row.artist.orEmpty())
                } else {
                    context.getString(R.string.queue_row_description, row.title, row.artist.orEmpty())
                }
                binding.root.setOnClickListener { onRowClicked(row) }
            }
        }

        private class QueueDiffCallback : DiffUtil.ItemCallback<QueueRow>() {
            override fun areItemsTheSame(oldItem: QueueRow, newItem: QueueRow): Boolean =
                oldItem.index == newItem.index

            override fun areContentsTheSame(oldItem: QueueRow, newItem: QueueRow): Boolean =
                oldItem == newItem
        }
    }
}
EOF

echo "  -> app/src/main/res/drawable/ic_close.xml"
mkdir -p app/src/main/res/drawable
cat << 'EOF' > app/src/main/res/drawable/ic_close.xml
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#FF000000"
        android:pathData="M19,6.41L17.59,5 12,10.59 6.41,5 5,6.41 10.59,12 5,17.59 6.41,19 12,13.41 17.59,19 19,17.59 13.41,12z" />
</vector>
EOF

echo "  -> app/src/main/res/drawable/ic_expand_more.xml"
mkdir -p app/src/main/res/drawable
cat << 'EOF' > app/src/main/res/drawable/ic_expand_more.xml
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#FF000000"
        android:pathData="M16.59,8.59L12,13.17 7.41,8.59 6,10l6,6 6,-6z" />
</vector>
EOF

echo "  -> app/src/main/res/drawable/ic_favorite.xml"
mkdir -p app/src/main/res/drawable
cat << 'EOF' > app/src/main/res/drawable/ic_favorite.xml
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#FF000000"
        android:pathData="M12,21.35l-1.45,-1.32C5.4,15.36 2,12.28 2,8.5 2,5.42 4.42,3 7.5,3c1.74,0 3.41,0.81 4.5,2.09C13.09,3.81 14.76,3 16.5,3 19.58,3 22,5.42 22,8.5c0,3.78 -3.4,6.86 -8.55,11.54L12,21.35z" />
</vector>
EOF

echo "  -> app/src/main/res/drawable/ic_flag_rca.xml"
mkdir -p app/src/main/res/drawable
cat << 'EOF' > app/src/main/res/drawable/ic_flag_rca.xml
<?xml version="1.0" encoding="utf-8"?>
<!-- Drapeau de la République centrafricaine (proportions 2:3) :
     quatre bandes horizontales égales (bleu, blanc, vert, jaune), une bande verticale rouge centrée
     de même largeur qu'une bande horizontale, et une étoile jaune à cinq branches dans le
     canton (bleu, côté gauche), centrée à 0,14 x la longueur depuis le guindant. -->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="36dp"
    android:height="24dp"
    android:viewportWidth="120"
    android:viewportHeight="80">
    <path android:fillColor="#0033A0" android:pathData="M0,0h120v20h-120z" />
    <path android:fillColor="#FFFFFF" android:pathData="M0,20h120v20h-120z" />
    <path android:fillColor="#009A44" android:pathData="M0,40h120v20h-120z" />
    <path android:fillColor="#FFD100" android:pathData="M0,60h120v20h-120z" />
    <path android:fillColor="#D21034" android:pathData="M50,0h20v80h-20z" />
    <path android:fillColor="#FFD100" android:pathData="M16.80,2.80 L18.42,7.78 L23.65,7.78 L19.42,10.85 L21.03,15.82 L16.80,12.75 L12.57,15.82 L14.18,10.85 L9.95,7.78 L15.18,7.78 Z" />
</vector>
EOF

echo "  -> app/src/main/res/drawable/ic_flag_rca_strip.xml"
mkdir -p app/src/main/res/drawable
cat << 'EOF' > app/src/main/res/drawable/ic_flag_rca_strip.xml
<?xml version="1.0" encoding="utf-8"?>
<!-- Liseré fin dessiné sous le titre : bleu, blanc, rouge (bande centrale), vert, jaune. -->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="100dp"
    android:height="4dp"
    android:viewportWidth="100"
    android:viewportHeight="4">
    <path android:fillColor="#0033A0" android:pathData="M0,0h22v4h-22z" />
    <path android:fillColor="#FFFFFF" android:pathData="M22,0h22v4h-22z" />
    <path android:fillColor="#D21034" android:pathData="M44,0h12v4h-12z" />
    <path android:fillColor="#009A44" android:pathData="M56,0h22v4h-22z" />
    <path android:fillColor="#FFD100" android:pathData="M78,0h22v4h-22z" />
</vector>
EOF

echo "  -> app/src/main/res/drawable/ic_search.xml"
mkdir -p app/src/main/res/drawable
cat << 'EOF' > app/src/main/res/drawable/ic_search.xml
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#FF000000"
        android:pathData="M15.5,14h-0.79l-0.28,-0.27C15.41,12.59 16,11.11 16,9.5 16,5.91 13.09,3 9.5,3S3,5.91 3,9.5 5.91,16 9.5,16c1.61,0 3.09,-0.59 4.23,-1.57l0.27,0.28v0.79l5,4.99L20.49,19l-4.99,-5zM9.5,14C7.01,14 5,11.99 5,9.5S7.01,5 9.5,5 14,7.01 14,9.5 11.99,14 9.5,14z" />
</vector>
EOF

echo "  -> app/src/main/res/layout/item_album.xml"
mkdir -p app/src/main/res/layout
cat << 'EOF' > app/src/main/res/layout/item_album.xml
<?xml version="1.0" encoding="utf-8"?>
<androidx.constraintlayout.widget.ConstraintLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    xmlns:tools="http://schemas.android.com/tools"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:background="?attr/selectableItemBackground"
    android:clickable="true"
    android:focusable="true"
    android:padding="8dp">

    <com.google.android.material.imageview.ShapeableImageView
        android:id="@+id/imageAlbum"
        android:layout_width="0dp"
        android:layout_height="0dp"
        android:importantForAccessibility="no"
        android:scaleType="centerCrop"
        app:layout_constraintDimensionRatio="H,1:1"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toTopOf="parent"
        app:shapeAppearanceOverlay="@style/ShapeAppearance.Elg.RoundedLarge" />

    <TextView
        android:id="@+id/textAlbumTitle"
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:layout_marginTop="8dp"
        android:ellipsize="end"
        android:gravity="center"
        android:maxLines="1"
        android:textAppearance="?attr/textAppearanceBodyLarge"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toBottomOf="@id/imageAlbum"
        tools:text="Titre de l'album" />

    <TextView
        android:id="@+id/textAlbumDetails"
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:layout_marginTop="2dp"
        android:ellipsize="end"
        android:gravity="center"
        android:maxLines="1"
        android:textAppearance="?attr/textAppearanceBodyMedium"
        android:textColor="?attr/colorOnSurfaceVariant"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toBottomOf="@id/textAlbumTitle"
        tools:text="Artiste | 12 pistes" />

</androidx.constraintlayout.widget.ConstraintLayout>
EOF

echo "  -> app/src/main/res/layout/item_artist.xml"
mkdir -p app/src/main/res/layout
cat << 'EOF' > app/src/main/res/layout/item_artist.xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    xmlns:tools="http://schemas.android.com/tools"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:background="?attr/selectableItemBackground"
    android:clickable="true"
    android:focusable="true"
    android:gravity="center_vertical"
    android:minHeight="72dp"
    android:orientation="horizontal"
    android:paddingStart="16dp"
    android:paddingTop="8dp"
    android:paddingEnd="16dp"
    android:paddingBottom="8dp">

    <com.google.android.material.imageview.ShapeableImageView
        android:id="@+id/imageArtist"
        android:layout_width="56dp"
        android:layout_height="56dp"
        android:importantForAccessibility="no"
        android:scaleType="centerCrop"
        app:shapeAppearanceOverlay="@style/ShapeAppearance.Elg.Circle" />

    <LinearLayout
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:layout_marginStart="16dp"
        android:layout_weight="1"
        android:orientation="vertical">

        <TextView
            android:id="@+id/textArtistName"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:ellipsize="end"
            android:maxLines="1"
            android:textAppearance="?attr/textAppearanceBodyLarge"
            android:textStyle="bold"
            tools:text="Nom de l'artiste" />

        <TextView
            android:id="@+id/textArtistDetails"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:layout_marginTop="2dp"
            android:ellipsize="end"
            android:maxLines="1"
            android:textAppearance="?attr/textAppearanceBodyMedium"
            android:textColor="?attr/colorOnSurfaceVariant"
            tools:text="2 albums | 14 morceaux" />

    </LinearLayout>

</LinearLayout>
EOF

echo "  -> app/src/main/res/layout/item_queue.xml"
mkdir -p app/src/main/res/layout
cat << 'EOF' > app/src/main/res/layout/item_queue.xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    xmlns:tools="http://schemas.android.com/tools"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:background="?attr/selectableItemBackground"
    android:clickable="true"
    android:focusable="true"
    android:gravity="center_vertical"
    android:minHeight="56dp"
    android:orientation="horizontal"
    android:paddingStart="16dp"
    android:paddingTop="6dp"
    android:paddingEnd="16dp"
    android:paddingBottom="6dp">

    <ImageView
        android:id="@+id/imageQueueCurrent"
        android:layout_width="24dp"
        android:layout_height="24dp"
        android:importantForAccessibility="no"
        android:src="@drawable/ic_play_arrow"
        app:tint="?attr/colorPrimary" />

    <LinearLayout
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:layout_marginStart="16dp"
        android:layout_weight="1"
        android:orientation="vertical">

        <TextView
            android:id="@+id/textQueueTitle"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:ellipsize="end"
            android:maxLines="1"
            android:textAppearance="?attr/textAppearanceBodyLarge"
            tools:text="Titre" />

        <TextView
            android:id="@+id/textQueueArtist"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:ellipsize="end"
            android:maxLines="1"
            android:textAppearance="?attr/textAppearanceBodyMedium"
            android:textColor="?attr/colorOnSurfaceVariant"
            tools:text="Artiste" />

    </LinearLayout>

</LinearLayout>
EOF

echo "  -> app/src/main/res/layout/layout_player_sheet.xml"
mkdir -p app/src/main/res/layout
cat << 'EOF' > app/src/main/res/layout/layout_player_sheet.xml
<?xml version="1.0" encoding="utf-8"?>
<!-- Grand lecteur coulissant : réduire (V), grande pochette, raccourcis (file d'attente, favori,
     ajouter à une playlist), barre de progression avec temps, puis commandes principales. -->
<androidx.constraintlayout.widget.ConstraintLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    xmlns:tools="http://schemas.android.com/tools"
    android:id="@+id/sheetRoot"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:accessibilityPaneTitle="@string/player_pane_title"
    android:background="?attr/colorSurface"
    android:clickable="true"
    android:focusable="true">

    <ImageButton
        android:id="@+id/buttonPlayerCollapse"
        android:layout_width="48dp"
        android:layout_height="48dp"
        android:layout_marginStart="8dp"
        android:layout_marginTop="4dp"
        android:background="?attr/selectableItemBackgroundBorderless"
        android:contentDescription="@string/player_collapse_description"
        android:src="@drawable/ic_expand_more"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toTopOf="parent"
        app:tint="?attr/colorOnSurface" />

    <ImageButton
        android:id="@+id/buttonPlayerMore"
        android:layout_width="48dp"
        android:layout_height="48dp"
        android:layout_marginTop="4dp"
        android:layout_marginEnd="8dp"
        android:background="?attr/selectableItemBackgroundBorderless"
        android:contentDescription="@string/player_more_options_description"
        android:src="@drawable/ic_more_vert"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintTop_toTopOf="parent"
        app:tint="?attr/colorOnSurface" />

    <com.google.android.material.imageview.ShapeableImageView
        android:id="@+id/imagePlayerArt"
        android:layout_width="0dp"
        android:layout_height="0dp"
        android:layout_marginStart="40dp"
        android:layout_marginTop="12dp"
        android:layout_marginEnd="40dp"
        android:importantForAccessibility="no"
        android:scaleType="centerCrop"
        android:src="@drawable/ic_artwork_default"
        app:layout_constraintDimensionRatio="H,1:1"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toBottomOf="@id/buttonPlayerCollapse"
        app:shapeAppearanceOverlay="@style/ShapeAppearance.Elg.RoundedLarge" />

    <TextView
        android:id="@+id/textPlayerTitle"
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:layout_marginStart="24dp"
        android:layout_marginTop="24dp"
        android:layout_marginEnd="24dp"
        android:ellipsize="end"
        android:gravity="center"
        android:maxLines="2"
        android:textAppearance="?attr/textAppearanceTitleLarge"
        android:textStyle="bold"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toBottomOf="@id/imagePlayerArt"
        tools:text="Titre du morceau" />

    <TextView
        android:id="@+id/textPlayerArtist"
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:layout_marginStart="24dp"
        android:layout_marginTop="4dp"
        android:layout_marginEnd="24dp"
        android:ellipsize="end"
        android:gravity="center"
        android:maxLines="1"
        android:textAppearance="?attr/textAppearanceBodyLarge"
        android:textColor="?attr/colorOnSurfaceVariant"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toBottomOf="@id/textPlayerTitle"
        tools:text="Artiste" />

    <LinearLayout
        android:id="@+id/layoutPlayerShortcuts"
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:layout_marginStart="24dp"
        android:layout_marginEnd="24dp"
        android:layout_marginBottom="4dp"
        android:gravity="center_vertical"
        android:orientation="horizontal"
        app:layout_constraintBottom_toTopOf="@id/seekPlayer"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent">

        <ImageButton
            android:id="@+id/buttonPlayerQueue"
            android:layout_width="0dp"
            android:layout_height="48dp"
            android:layout_weight="1"
            android:background="?attr/selectableItemBackgroundBorderless"
            android:contentDescription="@string/queue_button_description"
            android:src="@drawable/ic_playlist"
            app:tint="?attr/colorOnSurface" />

        <ImageButton
            android:id="@+id/buttonPlayerFavorite"
            android:layout_width="0dp"
            android:layout_height="48dp"
            android:layout_weight="1"
            android:background="?attr/selectableItemBackgroundBorderless"
            android:contentDescription="@string/song_menu_add_favorite"
            android:src="@drawable/ic_favorite_border"
            app:tint="?attr/colorOnSurface" />

        <ImageButton
            android:id="@+id/buttonPlayerAddPlaylist"
            android:layout_width="0dp"
            android:layout_height="48dp"
            android:layout_weight="1"
            android:background="?attr/selectableItemBackgroundBorderless"
            android:contentDescription="@string/player_add_to_playlist_description"
            android:src="@drawable/ic_add"
            app:tint="?attr/colorOnSurface" />

    </LinearLayout>

    <SeekBar
        android:id="@+id/seekPlayer"
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:layout_marginStart="12dp"
        android:layout_marginEnd="12dp"
        android:contentDescription="@string/player_seek_description"
        android:minHeight="48dp"
        app:layout_constraintBottom_toTopOf="@id/textPlayerElapsed"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent" />

    <TextView
        android:id="@+id/textPlayerElapsed"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_marginStart="28dp"
        android:layout_marginBottom="16dp"
        android:importantForAccessibility="no"
        android:text="@string/player_time_zero"
        android:textAppearance="?attr/textAppearanceBodyMedium"
        app:layout_constraintBottom_toTopOf="@id/layoutPlayerControls"
        app:layout_constraintStart_toStartOf="parent" />

    <TextView
        android:id="@+id/textPlayerDuration"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_marginEnd="28dp"
        android:importantForAccessibility="no"
        android:text="@string/player_time_zero"
        android:textAppearance="?attr/textAppearanceBodyMedium"
        app:layout_constraintBaseline_toBaselineOf="@id/textPlayerElapsed"
        app:layout_constraintEnd_toEndOf="parent" />

    <LinearLayout
        android:id="@+id/layoutPlayerControls"
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:layout_marginStart="16dp"
        android:layout_marginEnd="16dp"
        android:layout_marginBottom="32dp"
        android:gravity="center_vertical"
        android:orientation="horizontal"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent">

        <ImageButton
            android:id="@+id/buttonPlayerShuffle"
            android:layout_width="0dp"
            android:layout_height="56dp"
            android:layout_weight="1"
            android:background="?attr/selectableItemBackgroundBorderless"
            android:contentDescription="@string/mini_player_shuffle_description"
            android:src="@drawable/ic_shuffle"
            app:tint="@color/toggle_tint" />

        <ImageButton
            android:id="@+id/buttonPlayerPrevious"
            android:layout_width="0dp"
            android:layout_height="56dp"
            android:layout_weight="1"
            android:background="?attr/selectableItemBackgroundBorderless"
            android:contentDescription="@string/mini_player_previous_description"
            android:src="@drawable/ic_skip_previous"
            app:tint="?attr/colorOnSurface" />

        <ImageButton
            android:id="@+id/buttonPlayerPlayPause"
            android:layout_width="0dp"
            android:layout_height="72dp"
            android:layout_weight="1.4"
            android:background="?attr/selectableItemBackgroundBorderless"
            android:contentDescription="@string/mini_player_play_description"
            android:padding="18dp"
            android:scaleType="fitCenter"
            android:src="@drawable/ic_play_arrow"
            app:tint="?attr/colorOnSurface" />

        <ImageButton
            android:id="@+id/buttonPlayerNext"
            android:layout_width="0dp"
            android:layout_height="56dp"
            android:layout_weight="1"
            android:background="?attr/selectableItemBackgroundBorderless"
            android:contentDescription="@string/mini_player_next_description"
            android:src="@drawable/ic_skip_next"
            app:tint="?attr/colorOnSurface" />

        <ImageButton
            android:id="@+id/buttonPlayerRepeat"
            android:layout_width="0dp"
            android:layout_height="56dp"
            android:layout_weight="1"
            android:background="?attr/selectableItemBackgroundBorderless"
            android:contentDescription="@string/mini_player_repeat_description"
            android:src="@drawable/ic_repeat"
            app:tint="@color/toggle_tint" />

    </LinearLayout>

</androidx.constraintlayout.widget.ConstraintLayout>
EOF

echo "  -> app/src/main/res/layout/layout_queue_sheet.xml"
mkdir -p app/src/main/res/layout
cat << 'EOF' > app/src/main/res/layout/layout_queue_sheet.xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:orientation="vertical">

    <TextView
        android:id="@+id/textQueueHeading"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:accessibilityHeading="true"
        android:paddingStart="24dp"
        android:paddingTop="16dp"
        android:paddingEnd="24dp"
        android:paddingBottom="8dp"
        android:text="@string/queue_title"
        android:textAppearance="?attr/textAppearanceTitleMedium" />

    <androidx.recyclerview.widget.RecyclerView
        android:id="@+id/recyclerQueue"
        android:layout_width="match_parent"
        android:layout_height="300dp"
        android:clipToPadding="false"
        android:paddingBottom="16dp" />

</LinearLayout>
EOF

echo "  -> app/src/main/res/values/shapes.xml"
mkdir -p app/src/main/res/values
cat << 'EOF' > app/src/main/res/values/shapes.xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="ShapeAppearance.Elg.Circle" parent="">
        <item name="cornerFamily">rounded</item>
        <item name="cornerSize">50%</item>
    </style>
    <style name="ShapeAppearance.Elg.Rounded" parent="">
        <item name="cornerFamily">rounded</item>
        <item name="cornerSize">12dp</item>
    </style>
    <style name="ShapeAppearance.Elg.RoundedLarge" parent="">
        <item name="cornerFamily">rounded</item>
        <item name="cornerSize">28dp</item>
    </style>
    <style name="ShapeAppearance.Elg.FlagCorner" parent="">
        <item name="cornerFamily">rounded</item>
        <item name="cornerSize">4dp</item>
    </style>
</resources>
EOF

echo "  -> gradle/wrapper/gradle-wrapper.properties"
mkdir -p gradle/wrapper
cat << 'EOF' > gradle/wrapper/gradle-wrapper.properties
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.14-bin.zip
networkTimeout=10000
validateDistributionUrl=true
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF

echo "  -> app/src/main/java/com/elg/music/data/local/SettingsRepository.kt"
mkdir -p app/src/main/java/com/elg/music/data/local
cat << 'EOF' > app/src/main/java/com/elg/music/data/local/SettingsRepository.kt
package com.elg.music.data.local

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.emptyPreferences
import androidx.datastore.preferences.core.floatPreferencesKey
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import java.io.IOException

/** Une seule instance DataStore par fichier : la délégation doit rester au niveau du fichier. */
private val Context.elgSettingsDataStore: DataStore<Preferences> by preferencesDataStore(name = "elg_settings")

/**
 * Réglages avancés de la v1.4, avec les mêmes champs que `elg_settings_config.json`
 * (voir CLAUDE.md, section 4.A). Les valeurs par défaut sont celles d'une installation neuve :
 * aucun effet audio actif, vitesse et pitch neutres.
 *
 * @param bandLevels niveaux de l'égaliseur 5 bandes (60 Hz, 230 Hz, 910 Hz, 3,6 kHz, 14 kHz), en dB.
 * @param bassBoost intensité du renfort des graves, de 0 à 100 %.
 * @param virtualizer intensité de la spatialisation 3D, de 0 à 100 %.
 * @param playbackSpeed vitesse de lecture, de 0,25x à 2,5x.
 * @param playbackPitch tonalité, de 0,5x à 2,0x.
 * @param sleepTimerDefaultMin durée par défaut du minuteur de sommeil, en minutes.
 * @param fadeOutEnabled fondu sonore sur les 30 dernières secondes avant l'arrêt du minuteur.
 * @param driveModeTheme thème du mode conduite.
 */
data class AppSettings(
    val equalizerEnabled: Boolean = false,
    val bandLevels: List<Int> = List(BAND_COUNT) { 0 },
    val bassBoost: Int = 0,
    val virtualizer: Int = 0,
    val playbackSpeed: Float = 1.0f,
    val playbackPitch: Float = 1.0f,
    val sleepTimerDefaultMin: Int = 30,
    val fadeOutEnabled: Boolean = true,
    val driveModeTheme: String = "dark_neon"
) {
    companion object {
        const val BAND_COUNT = 5
    }
}

/**
 * Accès au DataStore (Jetpack DataStore Preferences) qui conserve les réglages avancés.
 *
 * Il coexiste avec [LibraryPreferences] (favoris, liste noire, tri) et avec les préférences du thème
 * (écran Réglages) : ces stockages existants ne sont ni déplacés ni modifiés. Les prochaines étapes
 * de la v1.4 (effets audio, minuteur, import/export JSON, réinitialisation) s'appuient sur ce dépôt.
 *
 * Chaque valeur est relue avec une borne de sécurité : un fichier altéré ne peut jamais produire
 * une vitesse, un pitch ou un niveau hors des plages prévues.
 */
class SettingsRepository(context: Context) {

    private val store = context.applicationContext.elgSettingsDataStore

    /** Réglages courants ; émet une nouvelle valeur à chaque modification. */
    val settings: Flow<AppSettings> = store.data
        .catch { error ->
            if (error is IOException) emit(emptyPreferences()) else throw error
        }
        .map { it.toSettings() }

    /** Lecture unique des réglages courants. */
    suspend fun current(): AppSettings = settings.first()

    suspend fun setEqualizerEnabled(enabled: Boolean) {
        store.edit { it[KEY_EQUALIZER_ENABLED] = enabled }
    }

    suspend fun setBandLevels(levels: List<Int>) {
        store.edit { it[KEY_BAND_LEVELS] = normalizeBands(levels).joinToString(",") }
    }

    suspend fun setBassBoost(percent: Int) {
        store.edit { it[KEY_BASS_BOOST] = percent.coerceIn(0, 100) }
    }

    suspend fun setVirtualizer(percent: Int) {
        store.edit { it[KEY_VIRTUALIZER] = percent.coerceIn(0, 100) }
    }

    suspend fun setPlaybackSpeed(speed: Float) {
        store.edit { it[KEY_PLAYBACK_SPEED] = speed.coerceIn(MIN_SPEED, MAX_SPEED) }
    }

    suspend fun setPlaybackPitch(pitch: Float) {
        store.edit { it[KEY_PLAYBACK_PITCH] = pitch.coerceIn(MIN_PITCH, MAX_PITCH) }
    }

    suspend fun setSleepTimerDefaultMin(minutes: Int) {
        store.edit { it[KEY_SLEEP_TIMER_DEFAULT] = minutes.coerceAtLeast(0) }
    }

    suspend fun setFadeOutEnabled(enabled: Boolean) {
        store.edit { it[KEY_FADE_OUT_ENABLED] = enabled }
    }

    suspend fun setDriveModeTheme(theme: String) {
        store.edit { it[KEY_DRIVE_MODE_THEME] = theme }
    }

    /** Applique vitesse et pitch en une seule écriture (préréglages Nightcore, Deep Voice, Dictée). */
    suspend fun setSpeedAndPitch(speed: Float, pitch: Float) {
        store.edit {
            it[KEY_PLAYBACK_SPEED] = speed.coerceIn(MIN_SPEED, MAX_SPEED)
            it[KEY_PLAYBACK_PITCH] = pitch.coerceIn(MIN_PITCH, MAX_PITCH)
        }
    }

    /** Active l'égaliseur et applique d'un coup les niveaux d'un préréglage. */
    suspend fun setEqualizerPreset(levels: List<Int>) {
        store.edit {
            it[KEY_EQUALIZER_ENABLED] = true
            it[KEY_BAND_LEVELS] = normalizeBands(levels).joinToString(",")
        }
    }

    /** Remplace tous les réglages d'un coup (restauration depuis `elg_settings_config.json`). */
    suspend fun replaceAll(settings: AppSettings) {
        store.edit { prefs ->
            prefs[KEY_EQUALIZER_ENABLED] = settings.equalizerEnabled
            prefs[KEY_BAND_LEVELS] = normalizeBands(settings.bandLevels).joinToString(",")
            prefs[KEY_BASS_BOOST] = settings.bassBoost.coerceIn(0, 100)
            prefs[KEY_VIRTUALIZER] = settings.virtualizer.coerceIn(0, 100)
            prefs[KEY_PLAYBACK_SPEED] = settings.playbackSpeed.coerceIn(MIN_SPEED, MAX_SPEED)
            prefs[KEY_PLAYBACK_PITCH] = settings.playbackPitch.coerceIn(MIN_PITCH, MAX_PITCH)
            prefs[KEY_SLEEP_TIMER_DEFAULT] = settings.sleepTimerDefaultMin.coerceAtLeast(0)
            prefs[KEY_FADE_OUT_ENABLED] = settings.fadeOutEnabled
            prefs[KEY_DRIVE_MODE_THEME] = settings.driveModeTheme
        }
    }

    /** Vrai si l'utilisateur a déjà accepté l'avertissement légal de l'éditeur de tags (v1.5). */
    suspend fun isTagEditorDisclaimerAccepted(): Boolean =
        store.data
            .catch { error -> if (error is IOException) emit(emptyPreferences()) else throw error }
            .first()[KEY_TAG_DISCLAIMER_ACCEPTED] ?: false

    /** Mémorise définitivement le consentement : la boîte de dialogue ne sera plus affichée. */
    suspend fun setTagEditorDisclaimerAccepted(accepted: Boolean = true) {
        store.edit { it[KEY_TAG_DISCLAIMER_ACCEPTED] = accepted }
    }

    /** Revient aux valeurs d'une installation neuve (réinitialisation usine) ; le consentement légal est conservé. */
    suspend fun resetAll() {
        store.edit { prefs ->
            val consent = prefs[KEY_TAG_DISCLAIMER_ACCEPTED]
            prefs.clear()
            if (consent != null) prefs[KEY_TAG_DISCLAIMER_ACCEPTED] = consent
        }
    }

    private fun Preferences.toSettings(): AppSettings {
        val defaults = AppSettings()
        return AppSettings(
            equalizerEnabled = this[KEY_EQUALIZER_ENABLED] ?: defaults.equalizerEnabled,
            bandLevels = parseBands(this[KEY_BAND_LEVELS]),
            bassBoost = (this[KEY_BASS_BOOST] ?: defaults.bassBoost).coerceIn(0, 100),
            virtualizer = (this[KEY_VIRTUALIZER] ?: defaults.virtualizer).coerceIn(0, 100),
            playbackSpeed = (this[KEY_PLAYBACK_SPEED] ?: defaults.playbackSpeed).coerceIn(MIN_SPEED, MAX_SPEED),
            playbackPitch = (this[KEY_PLAYBACK_PITCH] ?: defaults.playbackPitch).coerceIn(MIN_PITCH, MAX_PITCH),
            sleepTimerDefaultMin = (this[KEY_SLEEP_TIMER_DEFAULT] ?: defaults.sleepTimerDefaultMin).coerceAtLeast(0),
            fadeOutEnabled = this[KEY_FADE_OUT_ENABLED] ?: defaults.fadeOutEnabled,
            driveModeTheme = this[KEY_DRIVE_MODE_THEME] ?: defaults.driveModeTheme
        )
    }

    /** Relit « 0,3,2,-1,4 » ; toute valeur manquante ou illisible retombe sur 0. */
    private fun parseBands(raw: String?): List<Int> =
        normalizeBands(raw?.split(',')?.map { it.trim().toIntOrNull() ?: 0 }.orEmpty())

    /** Force exactement [AppSettings.BAND_COUNT] niveaux, chacun borné à ±15 dB. */
    private fun normalizeBands(levels: List<Int>): List<Int> =
        List(AppSettings.BAND_COUNT) { index ->
            (levels.getOrNull(index) ?: 0).coerceIn(-MAX_BAND_DB, MAX_BAND_DB)
        }

    private companion object {
        const val MIN_SPEED = 0.25f
        const val MAX_SPEED = 2.5f
        const val MIN_PITCH = 0.5f
        const val MAX_PITCH = 2.0f
        const val MAX_BAND_DB = 15

        val KEY_EQUALIZER_ENABLED = booleanPreferencesKey("equalizer_enabled")
        val KEY_BAND_LEVELS = stringPreferencesKey("band_levels")
        val KEY_BASS_BOOST = intPreferencesKey("bass_boost")
        val KEY_VIRTUALIZER = intPreferencesKey("virtualizer")
        val KEY_PLAYBACK_SPEED = floatPreferencesKey("playback_speed")
        val KEY_PLAYBACK_PITCH = floatPreferencesKey("playback_pitch")
        val KEY_SLEEP_TIMER_DEFAULT = intPreferencesKey("sleep_timer_default")
        val KEY_FADE_OUT_ENABLED = booleanPreferencesKey("fade_out_enabled")
        val KEY_DRIVE_MODE_THEME = stringPreferencesKey("drive_mode_theme")
        val KEY_TAG_DISCLAIMER_ACCEPTED = booleanPreferencesKey("tag_editor_disclaimer_accepted")
    }
}
EOF

echo "  -> app/src/main/java/com/elg/music/data/local/ElgDatabase.kt"
mkdir -p app/src/main/java/com/elg/music/data/local
cat << 'EOF' > app/src/main/java/com/elg/music/data/local/ElgDatabase.kt
package com.elg.music.data.local

import android.content.Context
import androidx.room.ColumnInfo
import androidx.room.Dao
import androidx.room.Database
import androidx.room.Delete
import androidx.room.Entity
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.PrimaryKey
import androidx.room.Query
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase
import kotlinx.coroutines.flow.Flow

/**
 * Morceau rangé dans le coffre-fort audio (étape « Coffre-fort » de la v1.4).
 *
 * Le fichier lui-même est déplacé dans `filesDir/vault/` : cette ligne conserve ce qu'il faut pour
 * l'afficher dans le coffre et, si l'utilisateur le démasque, le remettre à sa place d'origine.
 *
 * @param fileName nom du fichier dans `filesDir/vault/`.
 * @param originalRelativePath dossier d'origine (RELATIVE_PATH du MediaStore, ex. "Music/Afrobeat/").
 * @param addedAtMs date de mise au coffre (millisecondes depuis 1970).
 */
@Entity(tableName = "vault_entries")
data class VaultEntryEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0L,
    val fileName: String,
    val title: String,
    val artist: String?,
    val album: String?,
    val durationMs: Long,
    val mimeType: String?,
    val originalRelativePath: String,
    val addedAtMs: Long
)

@Dao
interface VaultDao {

    @Insert
    suspend fun insert(entry: VaultEntryEntity): Long

    @Query("SELECT * FROM vault_entries ORDER BY addedAtMs DESC")
    fun observeAll(): Flow<List<VaultEntryEntity>>

    @Query("SELECT * FROM vault_entries ORDER BY addedAtMs DESC")
    suspend fun getAll(): List<VaultEntryEntity>

    @Delete
    suspend fun delete(entry: VaultEntryEntity)

    /** Vide le coffre (réinitialisation usine) ; les fichiers sont supprimés à part par l'appelant. */
    @Query("DELETE FROM vault_entries")
    suspend fun clear()
}

/**
 * Tags saisis dans l'éditeur (étape 6 de la v1.4), une ligne par morceau (identifiant MediaStore).
 * Une chaîne vide signifie « champ absent ».
 *
 * @param fileWritten vrai si les tags ont été écrits dans le fichier (MP3) : la bibliothèque les lit alors
 *   depuis le MediaStore. Sinon (FLAC, M4A, OGG…), cette ligne prime à l'affichage de la bibliothèque.
 */
@Entity(tableName = "tag_entries")
data class TagEntryEntity(
    @PrimaryKey val mediaId: Long,
    val title: String,
    val artist: String,
    val album: String,
    val albumArtist: String,
    val genre: String,
    val year: String,
    val trackNumber: String,
    val trackTotal: String,
    val discNumber: String,
    val composer: String,
    val copyright: String,
    val publisher: String,
    val encoder: String,
    val language: String,
    val comment: String,
    val lyrics: String,
    @ColumnInfo(defaultValue = "''") val recordingMonth: String = "",
    @ColumnInfo(defaultValue = "''") val recordingDay: String = "",
    val fileWritten: Boolean,
    val updatedAtMs: Long
)

@Dao
interface TagDao {

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(entry: TagEntryEntity)

    @Query("SELECT * FROM tag_entries WHERE mediaId = :mediaId")
    suspend fun get(mediaId: Long): TagEntryEntity?

    @Query("SELECT * FROM tag_entries")
    suspend fun getAll(): List<TagEntryEntity>

    /** Vide les tags enregistrés (réinitialisation usine). */
    @Query("DELETE FROM tag_entries")
    suspend fun clear()
}

/**
 * Base Room locale de l'application. Elle reste volontairement petite : les favoris, la liste noire,
 * les playlists et le tri restent dans leurs stockages actuels, pour ne rien casser du socle v1.3.
 */
@Database(entities = [VaultEntryEntity::class, TagEntryEntity::class], version = 3, exportSchema = false)
abstract class ElgDatabase : RoomDatabase() {

    abstract fun vaultDao(): VaultDao

    abstract fun tagDao(): TagDao

    companion object {
        private const val DATABASE_NAME = "elg_music.db"

        private val TAG_TEXT_COLUMNS = listOf(
            "title", "artist", "album", "albumArtist", "genre", "year", "trackNumber", "trackTotal",
            "discNumber", "composer", "copyright", "publisher", "encoder", "language", "comment", "lyrics"
        )

        /** Version 1 -> 2 : ajoute la table des tags, sans toucher au coffre-fort existant. */
        private val MIGRATION_1_2 = object : Migration(1, 2) {
            override fun migrate(db: SupportSQLiteDatabase) {
                val textColumns = TAG_TEXT_COLUMNS.joinToString(", ") { "`$it` TEXT NOT NULL" }
                db.execSQL(
                    "CREATE TABLE IF NOT EXISTS `tag_entries` (`mediaId` INTEGER NOT NULL, $textColumns, " +
                        "`fileWritten` INTEGER NOT NULL, `updatedAtMs` INTEGER NOT NULL, PRIMARY KEY(`mediaId`))"
                )
            }
        }

        /** Version 2 -> 3 (V1.06) : ajoute le mois et le jour de la date d'enregistrement, sans toucher aux données. */
        private val MIGRATION_2_3 = object : Migration(2, 3) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL("ALTER TABLE `tag_entries` ADD COLUMN `recordingMonth` TEXT NOT NULL DEFAULT ''")
                db.execSQL("ALTER TABLE `tag_entries` ADD COLUMN `recordingDay` TEXT NOT NULL DEFAULT ''")
            }
        }

        @Volatile
        private var instance: ElgDatabase? = null

        fun get(context: Context): ElgDatabase =
            instance ?: synchronized(this) {
                instance ?: Room.databaseBuilder(
                    context.applicationContext,
                    ElgDatabase::class.java,
                    DATABASE_NAME
                )
                    .addMigrations(MIGRATION_1_2, MIGRATION_2_3)
                    .build().also { instance = it }
            }
    }
}
EOF

echo "  -> app/src/main/java/com/elg/music/ui/main/SongActions.kt"
mkdir -p app/src/main/java/com/elg/music/ui/main
cat << 'EOF' > app/src/main/java/com/elg/music/ui/main/SongActions.kt
package com.elg.music.ui.main

import android.app.Activity
import android.app.RecoverableSecurityException
import android.content.ClipData
import android.content.Intent
import android.provider.MediaStore
import android.view.View
import android.widget.PopupMenu
import android.widget.Toast
import androidx.activity.result.IntentSenderRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import com.elg.music.R
import com.elg.music.data.model.Song
import com.elg.music.ui.tags.TagEditorActivity
import com.elg.music.ui.vault.VaultActions
import com.google.android.material.dialog.MaterialAlertDialogBuilder

/**
 * Actions communes sur un morceau, partagées par le menu à trois points des listes (Titres, artistes,
 * albums, playlists, dossiers, favoris) et par le menu d'options du grand lecteur.
 *
 * Les deux menus utilisent les mêmes identifiants (`action_share_song`, `action_delete_song`) et
 * passent par [handleMenuItem] : une action ajoutée ici apparaît identique aux deux endroits.
 *
 * Doit être créée dans `onCreate` de l'Activity, car elle enregistre le lanceur de la demande de
 * suppression du système (Android exige cet enregistrement avant que l'écran démarre).
 *
 * @param onSongDeleted appelée une fois le fichier réellement supprimé : l'écran retire le morceau
 *   de la bibliothèque et de la file d'attente (le lecteur passe alors au morceau suivant).
 */
class SongActions(
    private val activity: AppCompatActivity,
    private val onSongDeleted: (Song) -> Unit
) {

    private var pendingDeleteSong: Song? = null

    /** « Masquer cette musique » (coffre-fort) : même action dans les deux menus. */
    private val vaultActions = VaultActions(activity, onSongDeleted)

    private val deleteRequestLauncher = activity.registerForActivityResult(
        ActivityResultContracts.StartIntentSenderForResult()
    ) { result ->
        val song = pendingDeleteSong
        pendingDeleteSong = null
        if (result.resultCode == Activity.RESULT_OK && song != null) {
            notifyDeleted(song)
        }
    }

    /** Traite une entrée de menu partagée ; renvoie false si l'identifiant n'est pas géré ici. */
    fun handleMenuItem(itemId: Int, song: Song): Boolean = when (itemId) {
        R.id.action_share_song -> {
            share(song)
            true
        }
        R.id.action_edit_tags -> {
            activity.startActivity(TagEditorActivity.newIntent(activity, song.id))
            true
        }
        R.id.action_vault_song -> {
            vaultActions.hide(song)
            true
        }
        R.id.action_delete_song -> {
            confirmAndDelete(song)
            true
        }
        else -> false
    }

    /**
     * Menu d'options du grand lecteur, accroché au bouton « Plus d'options ». Le minuteur de sommeil et la
     * boucle A-B portent sur la lecture en cours et sont toujours proposés ; partager, masquer et supprimer
     * ne le sont que pour un morceau de la bibliothèque ([song] non nul), pas pour un fichier ouvert depuis
     * une autre application.
     */
    fun showPlayerMenu(
        anchor: View,
        song: Song?,
        onSleepTimer: () -> Unit = {},
        onAbLoop: () -> Unit = {}
    ) {
        val popup = PopupMenu(activity, anchor)
        popup.menuInflater.inflate(R.menu.menu_player_options, popup.menu)
        val isLibrarySong = song != null
        popup.menu.findItem(R.id.action_share_song).isVisible = isLibrarySong
        popup.menu.findItem(R.id.action_edit_tags).isVisible = isLibrarySong
        popup.menu.findItem(R.id.action_vault_song).isVisible = isLibrarySong
        popup.menu.findItem(R.id.action_delete_song).isVisible = isLibrarySong
        popup.setOnMenuItemClickListener { item ->
            when (item.itemId) {
                R.id.action_sleep_timer -> {
                    onSleepTimer()
                    true
                }
                R.id.action_ab_loop -> {
                    onAbLoop()
                    true
                }
                else -> if (song != null) handleMenuItem(item.itemId, song) else false
            }
        }
        popup.show()
    }

    /** Ouvre le sélecteur de partage Android avec le fichier audio (Uri content:// du MediaStore). */
    fun share(song: Song) {
        val mimeType = song.mimeType?.takeIf { it.startsWith("audio/") } ?: "audio/*"
        val shareIntent = Intent(Intent.ACTION_SEND).apply {
            type = mimeType
            putExtra(Intent.EXTRA_STREAM, song.contentUri)
            clipData = ClipData.newRawUri(song.title, song.contentUri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        activity.startActivity(
            Intent.createChooser(shareIntent, activity.getString(R.string.share_chooser_title))
        )
    }

    /** Demande confirmation, puis supprime physiquement le fichier audio. */
    fun confirmAndDelete(song: Song) {
        MaterialAlertDialogBuilder(activity)
            .setTitle(R.string.delete_dialog_title)
            .setMessage(activity.getString(R.string.delete_dialog_message, song.title))
            .setPositiveButton(R.string.delete_dialog_confirm) { _, _ -> delete(song) }
            .setNegativeButton(R.string.delete_dialog_cancel, null)
            .show()
    }

    private fun delete(song: Song) {
        try {
            val removedRows = activity.contentResolver.delete(song.contentUri, null, null)
            if (removedRows > 0) notifyDeleted(song) else requestSystemDelete(song, null)
        } catch (security: SecurityException) {
            requestSystemDelete(song, security)
        } catch (error: Exception) {
            showDeleteError()
        }
    }

    /**
     * Fichier appartenant à une autre application : la suppression passe par la demande de
     * confirmation du système (`MediaStore.createDeleteRequest`). Si l'exception fournit déjà une
     * action récupérable, elle est utilisée en priorité.
     */
    private fun requestSystemDelete(song: Song, security: SecurityException?) {
        try {
            val intentSender = (security as? RecoverableSecurityException)
                ?.userAction?.actionIntent?.intentSender
                ?: MediaStore.createDeleteRequest(activity.contentResolver, listOf(song.contentUri)).intentSender
            pendingDeleteSong = song
            deleteRequestLauncher.launch(IntentSenderRequest.Builder(intentSender).build())
        } catch (error: Exception) {
            pendingDeleteSong = null
            showDeleteError()
        }
    }

    private fun notifyDeleted(song: Song) {
        onSongDeleted(song)
        Toast.makeText(
            activity,
            activity.getString(R.string.song_deleted_message, song.title),
            Toast.LENGTH_SHORT
        ).show()
    }

    private fun showDeleteError() {
        Toast.makeText(activity, R.string.delete_error_message, Toast.LENGTH_LONG).show()
    }
}
EOF

echo "  -> app/src/main/res/menu/menu_player_options.xml"
mkdir -p app/src/main/res/menu
cat << 'EOF' > app/src/main/res/menu/menu_player_options.xml
<?xml version="1.0" encoding="utf-8"?>
<!-- Menu d'options du grand lecteur : mêmes identifiants que menu_song_item.xml pour les actions
     communes (partager, supprimer), traitées ensemble par SongActions.handleMenuItem. -->
<menu xmlns:android="http://schemas.android.com/apk/res/android">

    <item
        android:id="@+id/action_sleep_timer"
        android:title="@string/menu_sleep_timer" />

    <item
        android:id="@+id/action_ab_loop"
        android:title="@string/menu_ab_loop" />

    <item
        android:id="@+id/action_edit_tags"
        android:title="@string/song_menu_edit_tags" />

    <item
        android:id="@+id/action_share_song"
        android:title="@string/song_menu_share" />

    <item
        android:id="@+id/action_vault_song"
        android:title="@string/song_menu_vault" />

    <item
        android:id="@+id/action_delete_song"
        android:title="@string/song_menu_delete" />

</menu>
EOF

echo "  -> app/src/main/java/com/elg/music/data/local/AudioPresets.kt"
mkdir -p app/src/main/java/com/elg/music/data/local
cat << 'EOF' > app/src/main/java/com/elg/music/data/local/AudioPresets.kt
package com.elg.music.data.local

import androidx.annotation.StringRes
import com.elg.music.R

/**
 * Plages des réglages audio avancés (CLAUDE.md, section 3.B) : vitesse de 0,25x à 2,5x,
 * pitch de 0,5x à 2,0x, niveaux de l'égaliseur de -15 à +15 dB, pas de 0,05 pour la vitesse et le pitch.
 */
object AudioRanges {
    const val MIN_SPEED = 0.25f
    const val MAX_SPEED = 2.5f
    const val MIN_PITCH = 0.5f
    const val MAX_PITCH = 2.0f
    const val STEP = 0.05f
    const val MAX_BAND_DB = 15

    /** Fréquences centrales des 5 bandes de l'égaliseur, en Hz (60 Hz, 230 Hz, 910 Hz, 3,6 kHz, 14 kHz). */
    val BAND_FREQUENCIES_HZ = intArrayOf(60, 230, 910, 3600, 14000)
}

/**
 * Préréglages de l'égaliseur graphique 5 bandes (niveaux en dB, dans l'ordre 60 Hz → 14 kHz).
 * [CUSTOM] n'a pas de niveaux propres : il désigne tout réglage qui ne correspond à aucun préréglage.
 */
enum class EqPreset(@StringRes val labelRes: Int, val levels: List<Int>?) {
    FLAT(R.string.eq_preset_flat, listOf(0, 0, 0, 0, 0)),
    BASS(R.string.eq_preset_bass, listOf(6, 4, 1, 0, 0)),
    ROCK(R.string.eq_preset_rock, listOf(5, 3, -1, 3, 5)),
    POP(R.string.eq_preset_pop, listOf(-1, 2, 4, 2, -1)),
    JAZZ(R.string.eq_preset_jazz, listOf(4, 2, -2, 2, 4)),
    VOCAL(R.string.eq_preset_vocal, listOf(-2, 0, 3, 4, 1)),
    CUSTOM(R.string.eq_preset_custom, null);

    companion object {
        /** Préréglage dont les niveaux sont exactement [levels] ; [CUSTOM] si aucun ne correspond. */
        fun match(levels: List<Int>): EqPreset =
            entries.firstOrNull { it.levels != null && it.levels == levels } ?: CUSTOM
    }
}

/** Préréglages rapides de vitesse et de pitch (CLAUDE.md, section 3.B). */
enum class SpeedPreset(@StringRes val labelRes: Int, val speed: Float, val pitch: Float) {
    NORMAL(R.string.speed_preset_normal, 1.00f, 1.00f),
    NIGHTCORE(R.string.speed_preset_nightcore, 1.20f, 1.20f),
    DEEP_VOICE(R.string.speed_preset_deep_voice, 0.85f, 0.80f),
    DICTATION(R.string.speed_preset_dictation, 0.75f, 1.00f)
}
EOF

echo "  -> app/src/main/java/com/elg/music/playback/AudioEffectsController.kt"
mkdir -p app/src/main/java/com/elg/music/playback
cat << 'EOF' > app/src/main/java/com/elg/music/playback/AudioEffectsController.kt
package com.elg.music.playback

import android.content.Context
import android.media.audiofx.BassBoost
import android.media.audiofx.Equalizer
import android.media.audiofx.Virtualizer
import androidx.media3.common.C
import androidx.media3.common.PlaybackParameters
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
import com.elg.music.data.local.AppSettings
import com.elg.music.data.local.AudioRanges
import com.elg.music.data.local.SettingsRepository
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlin.math.abs
import kotlin.math.ln

/**
 * Moteur audio avancé (étape 3 de la v1.4) : applique au lecteur de [MusicPlaybackService]
 * les réglages enregistrés dans [SettingsRepository].
 *
 *  - Vitesse et pitch : `PlaybackParameters` d'ExoPlayer (traitement Sonic intégré, sans effet de bord
 *    sur la file d'attente : les réglages restent d'un morceau à l'autre).
 *  - Égaliseur 5 bandes, Bass Boost et Virtualizer : effets `android.media.audiofx` attachés à la
 *    session audio d'ExoPlayer. Ils sont recréés si la session audio change.
 *
 * Le contrôleur observe les réglages (flux DataStore) : l'écran Audio n'a qu'à les écrire, et le
 * changement est entendu aussitôt, même si l'écran est ensuite fermé. Les effets matériels varient
 * selon les appareils : chaque appel est protégé, un effet non pris en charge reste simplement inactif.
 *
 * À utiliser sur le thread principal (celui d'ExoPlayer dans le service).
 */
class AudioEffectsController(
    context: Context,
    private val player: ExoPlayer
) : Player.Listener {

    private val repository = SettingsRepository(context)
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private var collectJob: Job? = null

    private var equalizer: Equalizer? = null
    private var bassBoost: BassBoost? = null
    private var virtualizer: Virtualizer? = null
    private var boundSessionId = C.AUDIO_SESSION_ID_UNSET
    private var latest = AppSettings()

    fun attach() {
        player.addListener(this)
        bindSession(player.audioSessionId)
        collectJob = scope.launch {
            repository.settings.collect { settings ->
                latest = settings
                applyPlayback(settings)
                applyEffects(settings)
            }
        }
    }

    fun release() {
        collectJob?.cancel()
        collectJob = null
        player.removeListener(this)
        releaseEffects()
        scope.cancel()
    }

    override fun onAudioSessionIdChanged(audioSessionId: Int) {
        bindSession(audioSessionId)
    }

    // ===================== Session audio et effets =====================

    private fun bindSession(sessionId: Int) {
        if (sessionId == boundSessionId) return
        releaseEffects()
        boundSessionId = sessionId
        if (sessionId == C.AUDIO_SESSION_ID_UNSET) return
        equalizer = createEffect { Equalizer(0, sessionId) }
        bassBoost = createEffect { BassBoost(0, sessionId) }
        virtualizer = createEffect { Virtualizer(0, sessionId) }
        applyEffects(latest)
    }

    private inline fun <T> createEffect(factory: () -> T): T? =
        try {
            factory()
        } catch (unsupported: RuntimeException) {
            null
        }

    private fun releaseEffects() {
        equalizer?.let { effect -> runCatching { effect.release() } }
        bassBoost?.let { effect -> runCatching { effect.release() } }
        virtualizer?.let { effect -> runCatching { effect.release() } }
        equalizer = null
        bassBoost = null
        virtualizer = null
    }

    // ===================== Application des réglages =====================

    private fun applyPlayback(settings: AppSettings) {
        val target = PlaybackParameters(settings.playbackSpeed, settings.playbackPitch)
        if (player.playbackParameters != target) {
            player.setPlaybackParameters(target)
        }
    }

    private fun applyEffects(settings: AppSettings) {
        equalizer?.let { applyEqualizer(it, settings) }
        bassBoost?.let { applyBassBoost(it, settings.bassBoost) }
        virtualizer?.let { applyVirtualizer(it, settings.virtualizer) }
    }

    /**
     * Les 5 niveaux réglés par l'utilisateur sont répartis sur les bandes réelles de l'appareil :
     * chaque bande matérielle reçoit le niveau de la bande réglable dont la fréquence est la plus proche.
     */
    private fun applyEqualizer(effect: Equalizer, settings: AppSettings) {
        try {
            val range = effect.bandLevelRange
            val minMillibel = range[0].toInt()
            val maxMillibel = range[1].toInt()
            val bandCount = effect.numberOfBands.toInt()
            for (band in 0 until bandCount) {
                val centerHz = effect.getCenterFreq(band.toShort()) / 1000
                val sourceIndex = nearestBandIndex(centerHz)
                val levelDb = settings.bandLevels.getOrNull(sourceIndex) ?: 0
                val levelMillibel = (levelDb * 100).coerceIn(minMillibel, maxMillibel)
                effect.setBandLevel(band.toShort(), levelMillibel.toShort())
            }
            effect.setEnabled(settings.equalizerEnabled)
        } catch (unsupported: RuntimeException) {
            // Effet indisponible sur cet appareil : reste inactif.
        }
    }

    private fun applyBassBoost(effect: BassBoost, percent: Int) {
        try {
            if (effect.getStrengthSupported()) {
                effect.setStrength((percent.coerceIn(0, 100) * 10).toShort())
            }
            effect.setEnabled(percent > 0)
        } catch (unsupported: RuntimeException) {
            // Effet indisponible sur cet appareil : reste inactif.
        }
    }

    private fun applyVirtualizer(effect: Virtualizer, percent: Int) {
        try {
            if (effect.getStrengthSupported()) {
                effect.setStrength((percent.coerceIn(0, 100) * 10).toShort())
            }
            effect.setEnabled(percent > 0)
        } catch (unsupported: RuntimeException) {
            // Effet indisponible sur cet appareil : reste inactif.
        }
    }

    /** Indice (0 à 4) de la bande réglable dont la fréquence est la plus proche de [centerHz], à l'échelle logarithmique. */
    private fun nearestBandIndex(centerHz: Int): Int {
        val safeHz = centerHz.coerceAtLeast(1).toDouble()
        var bestIndex = 0
        var bestDistance = Double.MAX_VALUE
        AudioRanges.BAND_FREQUENCIES_HZ.forEachIndexed { index, targetHz ->
            val distance = abs(ln(safeHz / targetHz.toDouble()))
            if (distance < bestDistance) {
                bestDistance = distance
                bestIndex = index
            }
        }
        return bestIndex
    }
}
EOF

echo "  -> app/src/main/java/com/elg/music/ui/settings/AudioSettingsActivity.kt"
mkdir -p app/src/main/java/com/elg/music/ui/settings
cat << 'EOF' > app/src/main/java/com/elg/music/ui/settings/AudioSettingsActivity.kt
package com.elg.music.ui.settings

import android.os.Bundle
import android.view.LayoutInflater
import android.view.ViewGroup
import android.widget.SeekBar
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.repeatOnLifecycle
import com.elg.music.R
import com.elg.music.data.local.AppSettings
import com.elg.music.data.local.AudioRanges
import com.elg.music.data.local.EqPreset
import com.elg.music.data.local.SettingsRepository
import com.elg.music.data.local.SpeedPreset
import com.elg.music.databinding.ActivityAudioSettingsBinding
import com.elg.music.databinding.ItemSliderRowBinding
import com.elg.music.ui.applySystemBarPadding
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import kotlinx.coroutines.launch
import java.util.Locale
import kotlin.math.roundToInt

/**
 * Écran « Audio & effets » (étape 3 de la v1.4) : vitesse et pitch avec préréglages rapides,
 * égaliseur 5 bandes avec préréglages, Bass Boost et Virtualizer.
 *
 * L'écran ne parle pas directement au lecteur : il écrit dans [SettingsRepository] (DataStore) et
 * `AudioEffectsController`, dans le service de lecture, applique les valeurs en direct.
 */
class AudioSettingsActivity : AppCompatActivity() {

    private lateinit var binding: ActivityAudioSettingsBinding
    private lateinit var repository: SettingsRepository
    private lateinit var speedRow: SliderRow
    private lateinit var pitchRow: SliderRow
    private lateinit var bassRow: SliderRow
    private lateinit var virtualizerRow: SliderRow
    private val bandRows = ArrayList<SliderRow>()

    private var latest = AppSettings()
    private var rendering = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityAudioSettingsBinding.inflate(layoutInflater)
        setContentView(binding.root)
        binding.root.applySystemBarPadding()

        setSupportActionBar(binding.toolbar)
        supportActionBar?.setDisplayHomeAsUpEnabled(true)
        binding.toolbar.setNavigationContentDescription(R.string.settings_back_description)

        repository = SettingsRepository(this)
        buildRows()
        setupControls()
        observeSettings()
    }

    override fun onSupportNavigateUp(): Boolean {
        finish()
        return true
    }

    // ===================== Construction de l'écran =====================

    private fun buildRows() {
        val inflater = layoutInflater

        speedRow = SliderRow(
            inflater, binding.layoutSpeedPitch, getString(R.string.audio_speed_label),
            maxProgress = progressForSpeed(AudioRanges.MAX_SPEED),
            format = { progress -> formatMultiplier(speedForProgress(progress)) }
        ) { progress ->
            val speed = speedForProgress(progress)
            latest = latest.copy(playbackSpeed = speed)
            lifecycleScope.launch { repository.setPlaybackSpeed(speed) }
        }

        pitchRow = SliderRow(
            inflater, binding.layoutSpeedPitch, getString(R.string.audio_pitch_label),
            maxProgress = progressForPitch(AudioRanges.MAX_PITCH),
            format = { progress -> formatMultiplier(pitchForProgress(progress)) }
        ) { progress ->
            val pitch = pitchForProgress(progress)
            latest = latest.copy(playbackPitch = pitch)
            lifecycleScope.launch { repository.setPlaybackPitch(pitch) }
        }

        val bandLabels = resources.getStringArray(R.array.eq_band_labels)
        for (index in 0 until AppSettings.BAND_COUNT) {
            bandRows.add(
                SliderRow(
                    inflater, binding.layoutBands, bandLabels[index],
                    maxProgress = AudioRanges.MAX_BAND_DB * 2,
                    format = { progress -> formatDecibels(progress - AudioRanges.MAX_BAND_DB) }
                ) { progress ->
                    val levels = latest.bandLevels.toMutableList()
                    levels[index] = progress - AudioRanges.MAX_BAND_DB
                    latest = latest.copy(bandLevels = levels)
                    lifecycleScope.launch { repository.setBandLevels(levels) }
                }
            )
        }

        bassRow = SliderRow(
            inflater, binding.layoutEffects, getString(R.string.audio_bass_boost_label),
            maxProgress = 100,
            format = { progress -> "$progress %" }
        ) { progress ->
            latest = latest.copy(bassBoost = progress)
            lifecycleScope.launch { repository.setBassBoost(progress) }
        }

        virtualizerRow = SliderRow(
            inflater, binding.layoutEffects, getString(R.string.audio_virtualizer_label),
            maxProgress = 100,
            format = { progress -> "$progress %" }
        ) { progress ->
            latest = latest.copy(virtualizer = progress)
            lifecycleScope.launch { repository.setVirtualizer(progress) }
        }
    }

    private fun setupControls() {
        binding.chipSpeedNormal.setOnClickListener { applySpeedPreset(SpeedPreset.NORMAL) }
        binding.chipSpeedNightcore.setOnClickListener { applySpeedPreset(SpeedPreset.NIGHTCORE) }
        binding.chipSpeedDeepVoice.setOnClickListener { applySpeedPreset(SpeedPreset.DEEP_VOICE) }
        binding.chipSpeedDictation.setOnClickListener { applySpeedPreset(SpeedPreset.DICTATION) }

        binding.switchEqualizer.setOnCheckedChangeListener { _, checked ->
            if (rendering) return@setOnCheckedChangeListener
            latest = latest.copy(equalizerEnabled = checked)
            lifecycleScope.launch { repository.setEqualizerEnabled(checked) }
        }
        binding.buttonEqPreset.setOnClickListener { showEqPresetDialog() }
        binding.buttonResetAudio.setOnClickListener { resetAudio() }
    }

    private fun observeSettings() {
        lifecycleScope.launch {
            repeatOnLifecycle(Lifecycle.State.STARTED) {
                repository.settings.collect { settings -> render(settings) }
            }
        }
    }

    // ===================== Affichage de l'état =====================

    private fun render(settings: AppSettings) {
        rendering = true
        latest = settings
        speedRow.show(progressForSpeed(settings.playbackSpeed))
        pitchRow.show(progressForPitch(settings.playbackPitch))
        bandRows.forEachIndexed { index, row ->
            row.show((settings.bandLevels.getOrNull(index) ?: 0) + AudioRanges.MAX_BAND_DB)
        }
        bassRow.show(settings.bassBoost)
        virtualizerRow.show(settings.virtualizer)
        binding.switchEqualizer.isChecked = settings.equalizerEnabled
        binding.buttonEqPreset.text = getString(
            R.string.eq_preset_button_format,
            getString(EqPreset.match(settings.bandLevels).labelRes)
        )
        rendering = false
    }

    // ===================== Actions =====================

    private fun applySpeedPreset(preset: SpeedPreset) {
        latest = latest.copy(playbackSpeed = preset.speed, playbackPitch = preset.pitch)
        lifecycleScope.launch { repository.setSpeedAndPitch(preset.speed, preset.pitch) }
    }

    private fun showEqPresetDialog() {
        val presets = EqPreset.entries
        val labels = presets.map { getString(it.labelRes) }.toTypedArray()
        val checkedIndex = presets.indexOf(EqPreset.match(latest.bandLevels))
        MaterialAlertDialogBuilder(this)
            .setTitle(R.string.eq_preset_dialog_title)
            .setSingleChoiceItems(labels, checkedIndex) { dialog, which ->
                applyEqPreset(presets[which])
                dialog.dismiss()
            }
            .setNegativeButton(R.string.sort_dialog_cancel, null)
            .show()
    }

    /** Choisir un préréglage active l'égaliseur ; « Custom » conserve les niveaux actuels. */
    private fun applyEqPreset(preset: EqPreset) {
        val levels = preset.levels ?: latest.bandLevels
        latest = latest.copy(equalizerEnabled = true, bandLevels = levels)
        lifecycleScope.launch { repository.setEqualizerPreset(levels) }
    }

    /** Remet à neutre tout ce que fait cet écran ; minuteur et mode conduite ne sont pas touchés. */
    private fun resetAudio() {
        val neutral = latest.copy(
            equalizerEnabled = false,
            bandLevels = List(AppSettings.BAND_COUNT) { 0 },
            bassBoost = 0,
            virtualizer = 0,
            playbackSpeed = 1.0f,
            playbackPitch = 1.0f
        )
        latest = neutral
        lifecycleScope.launch { repository.replaceAll(neutral) }
        Toast.makeText(this, R.string.audio_reset_done_message, Toast.LENGTH_SHORT).show()
    }

    // ===================== Conversions curseur <-> valeur =====================

    private fun speedForProgress(progress: Int): Float = roundToStep(AudioRanges.MIN_SPEED + progress * AudioRanges.STEP)

    private fun pitchForProgress(progress: Int): Float = roundToStep(AudioRanges.MIN_PITCH + progress * AudioRanges.STEP)

    private fun progressForSpeed(speed: Float): Int =
        ((speed - AudioRanges.MIN_SPEED) / AudioRanges.STEP).roundToInt()

    private fun progressForPitch(pitch: Float): Int =
        ((pitch - AudioRanges.MIN_PITCH) / AudioRanges.STEP).roundToInt()

    private fun roundToStep(value: Float): Float = (value * 100f).roundToInt() / 100f

    private fun formatMultiplier(value: Float): String = String.format(Locale.getDefault(), "%.2fx", value)

    private fun formatDecibels(db: Int): String =
        if (db == 0) "0 dB" else String.format(Locale.getDefault(), "%+d dB", db)

    /**
     * Ligne « libellé + valeur + curseur ». Tant que le doigt tient le curseur, l'état relu depuis le
     * DataStore ne le déplace pas (sinon le curseur sauterait en arrière pendant le glissement).
     */
    private class SliderRow(
        inflater: LayoutInflater,
        parent: ViewGroup,
        label: String,
        maxProgress: Int,
        private val format: (Int) -> String,
        private val onUserChange: (Int) -> Unit
    ) {
        private val rowBinding = ItemSliderRowBinding.inflate(inflater, parent, false)
        private var dragging = false

        init {
            rowBinding.textSliderLabel.text = label
            rowBinding.seekSlider.max = maxProgress
            rowBinding.seekSlider.contentDescription = label
            rowBinding.textSliderValue.text = format(0)
            rowBinding.seekSlider.setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
                override fun onProgressChanged(seekBar: SeekBar, progress: Int, fromUser: Boolean) {
                    val text = format(progress)
                    rowBinding.textSliderValue.text = text
                    ViewCompat.setStateDescription(seekBar, text)
                    if (fromUser) onUserChange(progress)
                }

                override fun onStartTrackingTouch(seekBar: SeekBar) {
                    dragging = true
                }

                override fun onStopTrackingTouch(seekBar: SeekBar) {
                    dragging = false
                }
            })
            parent.addView(rowBinding.root)
        }

        fun show(progress: Int) {
            if (dragging) return
            rowBinding.seekSlider.progress = progress.coerceIn(0, rowBinding.seekSlider.max)
        }
    }
}
EOF

echo "  -> app/src/main/res/layout/activity_audio_settings.xml"
mkdir -p app/src/main/res/layout
cat << 'EOF' > app/src/main/res/layout/activity_audio_settings.xml
<?xml version="1.0" encoding="utf-8"?>
<androidx.constraintlayout.widget.ConstraintLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="match_parent">

    <com.google.android.material.appbar.MaterialToolbar
        android:id="@+id/toolbar"
        android:layout_width="0dp"
        android:layout_height="?attr/actionBarSize"
        android:background="?attr/colorSurface"
        app:title="@string/audio_settings_title"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toTopOf="parent" />

    <androidx.core.widget.NestedScrollView
        android:layout_width="0dp"
        android:layout_height="0dp"
        android:clipToPadding="false"
        android:fillViewport="true"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toBottomOf="@id/toolbar">

        <LinearLayout
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:orientation="vertical"
            android:paddingStart="16dp"
            android:paddingTop="8dp"
            android:paddingEnd="16dp"
            android:paddingBottom="32dp">

            <!-- ===== VITESSE ET TONALITÉ ===== -->
            <TextView
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:accessibilityHeading="true"
                android:text="@string/audio_section_speed_pitch"
                android:textAppearance="?attr/textAppearanceTitleMedium"
                android:textColor="?attr/colorPrimary" />

            <com.google.android.material.chip.ChipGroup
                android:id="@+id/chipGroupSpeedPresets"
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:layout_marginTop="8dp"
                app:chipSpacingHorizontal="8dp">

                <com.google.android.material.chip.Chip
                    android:id="@+id/chipSpeedNormal"
                    style="@style/Widget.Material3.Chip.Assist"
                    android:layout_width="wrap_content"
                    android:layout_height="wrap_content"
                    android:text="@string/speed_preset_normal" />

                <com.google.android.material.chip.Chip
                    android:id="@+id/chipSpeedNightcore"
                    style="@style/Widget.Material3.Chip.Assist"
                    android:layout_width="wrap_content"
                    android:layout_height="wrap_content"
                    android:text="@string/speed_preset_nightcore" />

                <com.google.android.material.chip.Chip
                    android:id="@+id/chipSpeedDeepVoice"
                    style="@style/Widget.Material3.Chip.Assist"
                    android:layout_width="wrap_content"
                    android:layout_height="wrap_content"
                    android:text="@string/speed_preset_deep_voice" />

                <com.google.android.material.chip.Chip
                    android:id="@+id/chipSpeedDictation"
                    style="@style/Widget.Material3.Chip.Assist"
                    android:layout_width="wrap_content"
                    android:layout_height="wrap_content"
                    android:text="@string/speed_preset_dictation" />

            </com.google.android.material.chip.ChipGroup>

            <LinearLayout
                android:id="@+id/layoutSpeedPitch"
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:orientation="vertical" />

            <com.google.android.material.divider.MaterialDivider
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:layout_marginTop="16dp"
                android:layout_marginBottom="16dp" />

            <!-- ===== ÉGALISEUR ===== -->
            <TextView
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:accessibilityHeading="true"
                android:text="@string/audio_section_equalizer"
                android:textAppearance="?attr/textAppearanceTitleMedium"
                android:textColor="?attr/colorPrimary" />

            <com.google.android.material.materialswitch.MaterialSwitch
                android:id="@+id/switchEqualizer"
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:layout_marginTop="4dp"
                android:minHeight="48dp"
                android:text="@string/audio_equalizer_switch"
                android:textAppearance="?attr/textAppearanceBodyLarge" />

            <Button
                android:id="@+id/buttonEqPreset"
                style="@style/Widget.Material3.Button.TonalButton"
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:layout_marginTop="4dp"
                android:minHeight="48dp" />

            <LinearLayout
                android:id="@+id/layoutBands"
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:orientation="vertical" />

            <com.google.android.material.divider.MaterialDivider
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:layout_marginTop="16dp"
                android:layout_marginBottom="16dp" />

            <!-- ===== EFFETS SONORES ===== -->
            <TextView
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:accessibilityHeading="true"
                android:text="@string/audio_section_effects"
                android:textAppearance="?attr/textAppearanceTitleMedium"
                android:textColor="?attr/colorPrimary" />

            <LinearLayout
                android:id="@+id/layoutEffects"
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:orientation="vertical" />

            <TextView
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:layout_marginTop="12dp"
                android:text="@string/audio_effects_note"
                android:textAppearance="?attr/textAppearanceBodyMedium"
                android:textColor="?attr/colorOnSurfaceVariant" />

            <Button
                android:id="@+id/buttonResetAudio"
                style="@style/Widget.Material3.Button.TextButton"
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:layout_marginTop="16dp"
                android:minHeight="48dp"
                android:text="@string/audio_reset_button" />

        </LinearLayout>

    </androidx.core.widget.NestedScrollView>

</androidx.constraintlayout.widget.ConstraintLayout>
EOF

echo "  -> app/src/main/res/layout/item_slider_row.xml"
mkdir -p app/src/main/res/layout
cat << 'EOF' > app/src/main/res/layout/item_slider_row.xml
<?xml version="1.0" encoding="utf-8"?>
<!-- Ligne de réglage réutilisable de l'écran Audio : libellé, valeur affichée, curseur. -->
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:orientation="vertical"
    android:paddingTop="8dp">

    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:gravity="center_vertical"
        android:orientation="horizontal">

        <TextView
            android:id="@+id/textSliderLabel"
            android:layout_width="0dp"
            android:layout_height="wrap_content"
            android:layout_weight="1"
            android:textAppearance="?attr/textAppearanceBodyLarge"
            tools:text="Vitesse de lecture" />

        <TextView
            android:id="@+id/textSliderValue"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:layout_marginStart="12dp"
            android:importantForAccessibility="no"
            android:textAppearance="?attr/textAppearanceBodyMedium"
            android:textColor="?attr/colorPrimary"
            tools:text="1.00x" />

    </LinearLayout>

    <SeekBar
        android:id="@+id/seekSlider"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:minHeight="48dp" />

</LinearLayout>
EOF

echo "  -> app/src/main/java/com/elg/music/data/local/VaultPinStore.kt"
mkdir -p app/src/main/java/com/elg/music/data/local
cat << 'EOF' > app/src/main/java/com/elg/music/data/local/VaultPinStore.kt
package com.elg.music.data.local

import android.content.Context
import android.os.SystemClock
import android.provider.Settings
import android.util.Base64
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.emptyPreferences
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.longPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.first
import java.io.IOException
import java.security.MessageDigest
import java.security.SecureRandom

/** DataStore dédié à la sécurité du coffre-fort : une seule instance par fichier, déclarée au niveau du fichier. */
private val Context.elgVaultDataStore: DataStore<Preferences> by preferencesDataStore(name = "elg_vault_security")

/** Résultat de la vérification d'un code PIN. */
sealed interface PinCheckResult {
    /** Code correct. */
    data object Success : PinCheckResult

    /** Code incorrect ; [attemptsLeft] essais restants avant le premier blocage temporaire. */
    data class Wrong(val attemptsLeft: Int) : PinCheckResult

    /** Trop d'essais : saisie bloquée encore [remainingSeconds] secondes. */
    data class Locked(val remainingSeconds: Int) : PinCheckResult
}

/**
 * Code PIN du coffre-fort audio (4 ou 6 chiffres), conservé dans Jetpack DataStore.
 *
 * Le code n'est jamais enregistré en clair : seul son condensat SHA-256 salé l'est. Un sel aléatoire
 * de 16 octets est tiré à chaque création du code, et le condensat est recalculé en
 * [HASH_ROUNDS] tours pour ralentir toute attaque par essais successifs. La comparaison se fait en
 * temps constant.
 *
 * Anti-force brute (v1.5) : après [MAX_ATTEMPTS] erreurs de suite, la saisie est bloquée 30 secondes (niveau 1).
 * Ensuite, chaque nouvel échec après un déblocage fait monter d'un niveau la pénalité (backoff progressif) :
 * 30 s, 1 min, 2 min, 3 min, 5 min, 10 min, 15 min, 30 min, puis 1 heure au niveau maximal.
 * Le niveau (`lockout_level`) et la fin du blocage (`lockout_end_timestamp`) sont conservés dans le DataStore :
 * fermer l'application, la retirer du multitâche ou redémarrer le téléphone ne raccourcit pas le délai.
 * Pendant le même démarrage du téléphone, le délai est mesuré sur l'horloge monotone (`elapsedRealtime`), qui ne
 * se règle pas depuis les paramètres ; après un redémarrage, c'est l'horodatage enregistré qui fait foi.
 * Un code correct remet le compteur d'échecs et le niveau à zéro.
 *
 * Ce stockage est indépendant de [SettingsRepository] : l'export JSON des réglages et la
 * réinitialisation de l'audio ne touchent jamais au code PIN.
 */
class VaultPinStore(context: Context) {

    private val appContext = context.applicationContext
    private val store = appContext.elgVaultDataStore

    private suspend fun readPrefs(): Preferences =
        store.data
            .catch { error -> if (error is IOException) emit(emptyPreferences()) else throw error }
            .first()

    /** Vrai si un code PIN a déjà été créé. */
    suspend fun hasPin(): Boolean {
        val prefs = readPrefs()
        return prefs[KEY_PIN_HASH] != null && prefs[KEY_PIN_SALT] != null
    }

    /** Enregistre un nouveau code (remplace l'ancien) et remet à zéro les essais ratés et la pénalité. */
    suspend fun setPin(pin: String) {
        require(isValidFormat(pin)) { "Le code PIN doit comporter 4 ou 6 chiffres." }
        val salt = ByteArray(SALT_BYTES).also { SecureRandom().nextBytes(it) }
        val hash = hashPin(pin, salt)
        store.edit { prefs ->
            prefs[KEY_PIN_SALT] = Base64.encodeToString(salt, Base64.NO_WRAP)
            prefs[KEY_PIN_HASH] = Base64.encodeToString(hash, Base64.NO_WRAP)
            prefs[KEY_FAILED_ATTEMPTS] = 0
            prefs[KEY_LOCKOUT_LEVEL] = 0
            prefs[KEY_LOCKOUT_END] = 0L
            prefs[KEY_LOCKOUT_END_ELAPSED] = 0L
            prefs[KEY_LOCKOUT_BOOT] = currentBootCount()
        }
    }

    /** Secondes restantes avant la fin du blocage en cours (0 si la saisie est possible). */
    suspend fun remainingLockSeconds(): Int {
        val remaining = remainingLockMillis(readPrefs())
        // V1.06 : 0 = aucun blocage. secondsFor() renvoie au minimum 1 seconde ; l'utiliser pour un temps nul
        // faisait afficher « Réessayez dans 00:01 » en permanence, dès l'ouverture, sans aucun code saisi.
        return if (remaining <= 0L) 0 else secondsFor(remaining)
    }

    /** Niveau de pénalité actuel (0 = aucun blocage imposé jusqu'ici, 9 = niveau maximal). */
    suspend fun lockoutLevel(): Int = readPrefs()[KEY_LOCKOUT_LEVEL] ?: 0

    /** Vérifie un code saisi, en tenant compte du blocage temporaire, du compteur d'essais et du niveau de pénalité. */
    suspend fun verify(pin: String): PinCheckResult {
        val prefs = readPrefs()
        val saltText = prefs[KEY_PIN_SALT]
        val hashText = prefs[KEY_PIN_HASH]
        if (saltText == null || hashText == null) return PinCheckResult.Wrong(0)

        val remaining = remainingLockMillis(prefs)
        if (remaining > 0L) return PinCheckResult.Locked(secondsFor(remaining))

        val salt = runCatching { Base64.decode(saltText, Base64.NO_WRAP) }.getOrNull()
        val expected = runCatching { Base64.decode(hashText, Base64.NO_WRAP) }.getOrNull()
        if (salt == null || expected == null) return PinCheckResult.Wrong(0)

        if (MessageDigest.isEqual(expected, hashPin(pin, salt))) {
            store.edit { editable ->
                editable[KEY_FAILED_ATTEMPTS] = 0
                editable[KEY_LOCKOUT_LEVEL] = 0
                editable[KEY_LOCKOUT_END] = 0L
                editable[KEY_LOCKOUT_END_ELAPSED] = 0L
            }
            return PinCheckResult.Success
        }

        val level = prefs[KEY_LOCKOUT_LEVEL] ?: 0
        val failed = (prefs[KEY_FAILED_ATTEMPTS] ?: 0) + 1
        // Niveau 0 : cinq erreurs sont tolérées. Dès qu'un blocage a eu lieu, un seul échec suffit à monter d'un niveau.
        if (level == 0 && failed < MAX_ATTEMPTS) {
            store.edit { editable -> editable[KEY_FAILED_ATTEMPTS] = failed }
            return PinCheckResult.Wrong(MAX_ATTEMPTS - failed)
        }
        val nextLevel = (level + 1).coerceAtMost(LOCK_DURATIONS_S.size)
        val durationMs = LOCK_DURATIONS_S[nextLevel - 1] * 1000L
        val endWall = System.currentTimeMillis() + durationMs
        val endElapsed = SystemClock.elapsedRealtime() + durationMs
        store.edit { editable ->
            editable[KEY_FAILED_ATTEMPTS] = 0
            editable[KEY_LOCKOUT_LEVEL] = nextLevel
            editable[KEY_LOCKOUT_END] = endWall
            editable[KEY_LOCKOUT_END_ELAPSED] = endElapsed
            editable[KEY_LOCKOUT_BOOT] = currentBootCount()
        }
        return PinCheckResult.Locked(secondsFor(durationMs))
    }

    /** Millisecondes de blocage restantes, sur l'horloge monotone si le téléphone n'a pas redémarré depuis. */
    private fun remainingLockMillis(prefs: Preferences): Long {
        val endWall = prefs[KEY_LOCKOUT_END] ?: 0L
        if (endWall <= 0L) return 0L
        val sameBoot = (prefs[KEY_LOCKOUT_BOOT] ?: -1) == currentBootCount() && currentBootCount() >= 0
        val endElapsed = prefs[KEY_LOCKOUT_END_ELAPSED] ?: 0L
        val fromWall = (endWall - System.currentTimeMillis()).coerceAtLeast(0L)
        if (sameBoot && endElapsed > 0L) {
            return (endElapsed - SystemClock.elapsedRealtime()).coerceIn(0L, LOCK_DURATIONS_S.last() * 1000L)
        }
        // Après redémarrage : horodatage enregistré (borné pour qu'un réglage d'horloge ne bloque pas indéfiniment).
        return fromWall.coerceAtMost(LOCK_DURATIONS_S.last() * 1000L)
    }

    private fun currentBootCount(): Int =
        runCatching { Settings.Global.getInt(appContext.contentResolver, Settings.Global.BOOT_COUNT, -1) }.getOrDefault(-1)

    /** Supprime le code PIN et le compteur d'essais (réinitialisation usine, étape ultérieure). */
    suspend fun clear() {
        store.edit { it.clear() }
    }

    /** SHA-256 du sel suivi du code, puis recalculé en tours successifs avec le sel. */
    private fun hashPin(pin: String, salt: ByteArray): ByteArray {
        val digest = MessageDigest.getInstance("SHA-256")
        var result = digest.digest(salt + pin.toByteArray(Charsets.UTF_8))
        repeat(HASH_ROUNDS - 1) {
            digest.update(result)
            digest.update(salt)
            result = digest.digest()
        }
        return result
    }

    private fun secondsFor(millis: Long): Int = ((millis + 999L) / 1000L).toInt().coerceAtLeast(1)

    companion object {
        private const val SALT_BYTES = 16
        private const val HASH_ROUNDS = 10_000
        private const val MAX_ATTEMPTS = 5

        /** Durées de blocage par niveau, en secondes : 30 s, 1, 2, 3, 5, 10, 15, 30 minutes, puis 1 heure. */
        val LOCK_DURATIONS_S = longArrayOf(30L, 60L, 120L, 180L, 300L, 600L, 900L, 1800L, 3600L)

        private val KEY_PIN_SALT = stringPreferencesKey("pin_salt")
        private val KEY_PIN_HASH = stringPreferencesKey("pin_hash")
        private val KEY_FAILED_ATTEMPTS = intPreferencesKey("failed_attempts")
        private val KEY_LOCKOUT_LEVEL = intPreferencesKey("lockout_level")
        private val KEY_LOCKOUT_END = longPreferencesKey("lockout_end_timestamp")
        private val KEY_LOCKOUT_END_ELAPSED = longPreferencesKey("lockout_end_elapsed")
        private val KEY_LOCKOUT_BOOT = intPreferencesKey("lockout_boot_count")

        /** Un code valide comporte exactement 4 ou 6 chiffres. */
        fun isValidFormat(pin: String): Boolean =
            (pin.length == 4 || pin.length == 6) && pin.all { it in '0'..'9' }
    }
}
EOF

echo "  -> app/src/main/java/com/elg/music/data/repository/VaultRepository.kt"
mkdir -p app/src/main/java/com/elg/music/data/repository
cat << 'EOF' > app/src/main/java/com/elg/music/data/repository/VaultRepository.kt
package com.elg.music.data.repository

import android.content.ContentValues
import android.content.Context
import android.net.Uri
import android.os.Bundle
import android.provider.MediaStore
import android.provider.OpenableColumns
import android.webkit.MimeTypeMap
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import com.elg.music.data.local.ElgDatabase
import com.elg.music.data.local.VaultEntryEntity
import com.elg.music.data.model.Song
import com.elg.music.playback.MidiSupport
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.withContext
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.util.Locale

/**
 * Coffre-fort audio (étape 4 de la v1.4) : range des morceaux dans le stockage privé de l'application
 * (`filesDir/vault/`), hors de portée du MediaStore et des autres applications, et les en ressort.
 *
 * Mise au coffre en deux temps, pour ne jamais perdre un fichier :
 *  1. [stage] copie le fichier dans le coffre et enregistre sa ligne dans la base Room ;
 *  2. l'appelant supprime ensuite l'original (suppression système éventuellement confirmée par
 *     l'utilisateur). Si la suppression échoue ou est refusée, [discard] annule la copie.
 *
 * Le nom d'un fichier du coffre est `<horodatage>_<nom d'origine>` : le nom d'origine se retrouve en
 * retirant le préfixe, ce qui évite d'ajouter une colonne à la base Room déjà en place.
 */
class VaultRepository(context: Context) {

    private val appContext = context.applicationContext
    private val resolver = appContext.contentResolver
    private val dao = ElgDatabase.get(appContext).vaultDao()

    /** Dossier privé du coffre : `context.filesDir/vault/`. */
    private val vaultDir: File by lazy {
        File(appContext.filesDir, VAULT_DIR_NAME).apply { mkdirs() }
    }

    /** Contenu du coffre, du plus récent au plus ancien ; émet à chaque modification. */
    fun observeEntries(): Flow<List<VaultEntryEntity>> = dao.observeAll()

    fun fileOf(entry: VaultEntryEntity): File = File(vaultDir, entry.fileName)

    /** Identifiant de lecture d'un morceau du coffre (distinct des identifiants MediaStore). */
    fun mediaIdOf(entry: VaultEntryEntity): String = "$MEDIA_ID_PREFIX${entry.id}"

    /**
     * Copie [song] dans le coffre et enregistre sa ligne. L'original n'est PAS touché.
     * En cas d'échec, la copie partielle est effacée et l'exception est relancée.
     */
    suspend fun stage(song: Song): VaultEntryEntity = withContext(Dispatchers.IO) {
        val displayName = queryDisplayName(song.contentUri)
            ?: "${song.title}.${extensionFor(song.mimeType)}"
        val target = uniqueTarget(sanitize(displayName))
        try {
            val input = resolver.openInputStream(song.contentUri)
                ?: throw IOException("Fichier audio illisible")
            input.use { source ->
                FileOutputStream(target).use { output -> source.copyTo(output) }
            }
            if (target.length() == 0L) throw IOException("Copie vide")
            val entry = VaultEntryEntity(
                fileName = target.name,
                title = song.title,
                artist = song.artist,
                album = song.album,
                durationMs = song.durationMs,
                mimeType = song.mimeType,
                originalRelativePath = song.folderPath,
                addedAtMs = System.currentTimeMillis()
            )
            entry.copy(id = dao.insert(entry))
        } catch (error: Exception) {
            target.delete()
            throw error
        }
    }

    /**
     * Efface une entrée du coffre : fichier et ligne. Sert à annuler une mise au coffre et à la
     * suppression définitive. Non annulable : la base et le disque ne doivent jamais rester à moitié nettoyés.
     */
    suspend fun discard(entry: VaultEntryEntity) {
        withContext(NonCancellable + Dispatchers.IO) {
            fileOf(entry).delete()
            dao.delete(entry)
        }
    }

    /**
     * Démasque un morceau : le fichier retourne dans le MediaStore, dans son dossier d'origine si
     * Android l'accepte pour l'audio, sinon dans `Music/ELG Music/`. Renvoie false si la restauration
     * échoue ; le fichier reste alors dans le coffre, intact.
     */
    suspend fun restore(entry: VaultEntryEntity): Boolean = withContext(Dispatchers.IO) {
        val source = fileOf(entry)
        if (!source.exists()) {
            // Fichier disparu : la ligne ne mène plus nulle part, on la retire.
            dao.delete(entry)
            return@withContext false
        }
        val displayName = originalNameOf(entry)
        val mimeType = entry.mimeType?.takeIf { it.isNotBlank() } ?: mimeFor(displayName)

        val restored = insertIntoMediaStore(source, displayName, mimeType, entry.originalRelativePath) != null ||
            insertIntoMediaStore(source, displayName, mimeType, FALLBACK_RELATIVE_PATH) != null
        if (!restored) return@withContext false

        source.delete()
        dao.delete(entry)
        markLibraryDirty()
        true
    }

    /** Élément de lecture Media3 pour un morceau du coffre (lu directement depuis le stockage privé). */
    fun toMediaItem(entry: VaultEntryEntity): MediaItem {
        val uri = Uri.fromFile(fileOf(entry))
        val metadata = MediaMetadata.Builder()
            .setTitle(entry.title)
            .setArtist(entry.artist)
            .setAlbumTitle(entry.album)
            // Clé de ArtworkBitmapLoader : sans pochette lisible, la pochette par défaut est utilisée.
            .setArtworkUri(uri)
            .setDurationMs(entry.durationMs)
        if (entry.mimeType?.contains("midi", ignoreCase = true) == true) {
            metadata.setExtras(Bundle().apply { putString(MidiSupport.EXTRA_MIDI_URI, uri.toString()) })
        }
        return MediaItem.Builder()
            .setMediaId(mediaIdOf(entry))
            .setUri(uri)
            .setMediaMetadata(metadata.build())
            .build()
    }

    // ===================== Détails =====================

    private fun queryDisplayName(uri: Uri): String? =
        try {
            resolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
                ?.use { cursor -> if (cursor.moveToFirst()) cursor.getString(0) else null }
                ?.takeIf { it.isNotBlank() }
        } catch (error: RuntimeException) {
            null
        }

    /** Nom de fichier libre dans le coffre : l'horodatage avance d'une milliseconde tant que le nom est pris. */
    private fun uniqueTarget(safeName: String): File {
        var stamp = System.currentTimeMillis()
        var candidate = File(vaultDir, "${stamp}_$safeName")
        while (candidate.exists()) {
            stamp += 1L
            candidate = File(vaultDir, "${stamp}_$safeName")
        }
        return candidate
    }

    /** Retire les caractères interdits dans un nom de fichier et borne la longueur en gardant l'extension. */
    private fun sanitize(name: String): String {
        val cleaned = INVALID_FILE_CHARS.replace(name.trim(), "_")
        val extension = cleaned.substringAfterLast('.', "")
        val hasExtension = extension.isNotEmpty() && extension.length <= MAX_EXTENSION_LENGTH
        val base = if (hasExtension) cleaned.dropLast(extension.length + 1) else cleaned
        val shortBase = base.take(MAX_BASE_NAME_LENGTH).ifBlank { "audio" }
        return if (hasExtension) "$shortBase.$extension" else shortBase
    }

    private fun originalNameOf(entry: VaultEntryEntity): String =
        entry.fileName.substringAfter('_', entry.fileName)

    private fun extensionFor(mimeType: String?): String =
        mimeType?.let { MimeTypeMap.getSingleton().getExtensionFromMimeType(it) } ?: "mp3"

    private fun mimeFor(fileName: String): String {
        val extension = fileName.substringAfterLast('.', "").lowercase(Locale.ROOT)
        return MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension) ?: "audio/mpeg"
    }

    /** "Music/Afrobeat" devient "Music/Afrobeat/" ; un chemin vide (racine) est refusé par le MediaStore. */
    private fun normalizeRelativePath(path: String): String? {
        val trimmed = path.trim().trim('/')
        return if (trimmed.isEmpty()) null else "$trimmed/"
    }

    /**
     * Crée l'entrée MediaStore (en attente), y écrit le fichier, puis la publie. Renvoie null si
     * Android refuse ce dossier pour l'audio ou si l'écriture échoue ; l'entrée à moitié créée est alors retirée.
     */
    private fun insertIntoMediaStore(
        source: File,
        displayName: String,
        mimeType: String,
        relativePath: String
    ): Uri? {
        val path = normalizeRelativePath(relativePath) ?: return null
        val collection = MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        val pending = ContentValues().apply {
            put(MediaStore.Audio.Media.DISPLAY_NAME, displayName)
            put(MediaStore.Audio.Media.MIME_TYPE, mimeType)
            put(MediaStore.Audio.Media.RELATIVE_PATH, path)
            put(MediaStore.Audio.Media.IS_PENDING, 1)
        }
        val uri = try {
            resolver.insert(collection, pending)
        } catch (error: RuntimeException) {
            null
        }
        if (uri == null) return null

        return try {
            val output = resolver.openOutputStream(uri) ?: throw IOException("Écriture impossible")
            output.use { out -> source.inputStream().use { input -> input.copyTo(out) } }
            val published = ContentValues().apply { put(MediaStore.Audio.Media.IS_PENDING, 0) }
            resolver.update(uri, published, null, null)
            uri
        } catch (error: Exception) {
            runCatching { resolver.delete(uri, null, null) }
            null
        }
    }

    companion object {
        /** Préfixe des identifiants de lecture du coffre (« vault:12 »). */
        const val MEDIA_ID_PREFIX = "vault:"

        private const val VAULT_DIR_NAME = "vault"
        private const val FALLBACK_RELATIVE_PATH = "Music/ELG Music/"
        private const val MAX_EXTENSION_LENGTH = 5
        private const val MAX_BASE_NAME_LENGTH = 100
        private val INVALID_FILE_CHARS = Regex("[\\\\/:*?\"<>|\\p{Cntrl}]")

        @Volatile
        private var libraryDirty = false

        /** Signale à l'écran principal que la bibliothèque doit être relue (un morceau y est revenu). */
        fun markLibraryDirty() {
            libraryDirty = true
        }

        /** Lit puis efface le signal « bibliothèque à relire ». */
        fun consumeLibraryDirty(): Boolean {
            val dirty = libraryDirty
            libraryDirty = false
            return dirty
        }
    }
}
EOF

echo "  -> app/src/main/java/com/elg/music/ui/vault/PinDialogs.kt"
mkdir -p app/src/main/java/com/elg/music/ui/vault
cat << 'EOF' > app/src/main/java/com/elg/music/ui/vault/PinDialogs.kt
package com.elg.music.ui.vault

import android.content.Context
import android.content.DialogInterface
import android.view.View
import android.view.WindowManager
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputMethodManager
import androidx.annotation.StringRes
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.core.widget.doOnTextChanged
import androidx.lifecycle.lifecycleScope
import com.elg.music.R
import com.elg.music.data.local.PinCheckResult
import com.elg.music.data.local.VaultPinStore
import com.elg.music.databinding.DialogPinBinding
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.util.Locale

/**
 * Boîtes de dialogue du code PIN du coffre-fort. Les deux fonctions renvoient le dialogue affiché,
 * pour que l'écran puisse le refermer s'il quitte le premier plan.
 *
 * Le code se saisit sur 4 ou 6 chiffres, masqué (avec un œil pour l'afficher). Les erreurs
 * apparaissent sous le champ sans fermer le dialogue.
 */
object PinDialogs {

    /**
     * Création (ou changement) du code : saisie puis confirmation.
     *
     * @param onCreated appelé une fois le code enregistré.
     * @param onCancel appelé si l'utilisateur annule (bouton « Annuler », retour).
     */
    fun showCreate(
        activity: AppCompatActivity,
        store: VaultPinStore,
        @StringRes titleRes: Int,
        onCreated: () -> Unit,
        onCancel: () -> Unit = {}
    ): AlertDialog {
        val binding = DialogPinBinding.inflate(activity.layoutInflater)
        binding.textPinMessage.setText(R.string.vault_pin_create_message)
        binding.inputLayoutPinConfirm.visibility = View.VISIBLE

        val dialog = MaterialAlertDialogBuilder(activity)
            .setTitle(titleRes)
            .setView(binding.root)
            .setPositiveButton(R.string.vault_pin_confirm_button, null)
            .setNegativeButton(R.string.vault_pin_cancel) { dialogInterface, _ -> dialogInterface.cancel() }
            .setOnCancelListener { onCancel() }
            .create()
        dialog.setCanceledOnTouchOutside(false)

        dialog.setOnShowListener {
            val confirmButton = dialog.getButton(DialogInterface.BUTTON_POSITIVE)
            fun submit() {
                val pin = binding.editPin.text?.toString().orEmpty()
                val confirmation = binding.editPinConfirm.text?.toString().orEmpty()
                when {
                    !VaultPinStore.isValidFormat(pin) ->
                        binding.inputLayoutPin.error = activity.getString(R.string.vault_pin_error_format)
                    pin != confirmation ->
                        binding.inputLayoutPinConfirm.error = activity.getString(R.string.vault_pin_error_mismatch)
                    else -> {
                        confirmButton.isEnabled = false
                        activity.lifecycleScope.launch {
                            store.setPin(pin)
                            dialog.dismiss()
                            onCreated()
                        }
                    }
                }
            }
            confirmButton.setOnClickListener { submit() }
            binding.editPin.doOnTextChanged { _, _, _, _ -> binding.inputLayoutPin.error = null }
            binding.editPinConfirm.doOnTextChanged { _, _, _, _ -> binding.inputLayoutPinConfirm.error = null }
            binding.editPinConfirm.setOnEditorActionListener { _, actionId, _ ->
                if (actionId == EditorInfo.IME_ACTION_DONE) {
                    submit()
                    true
                } else {
                    false
                }
            }
            binding.editPin.requestFocus()
            dialog.window?.setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_STATE_VISIBLE)
        }
        dialog.show()
        return dialog
    }

    /**
     * Déverrouillage : saisie du code existant. Après 5 erreurs de suite, l'interface est verrouillée : le clavier
     * se ferme, le champ et le bouton de validation sont désactivés, et un décompte « Réessayez dans mm:ss » défile
     * seconde par seconde. La pénalité grandit à chaque nouvel échec (voir [VaultPinStore]) et survit à la fermeture
     * de l'application : si le dialogue est rouvert pendant un blocage, le décompte reprend là où il en était.
     *
     * @param onUnlocked appelé quand le code est correct.
     * @param onCancel appelé si l'utilisateur annule.
     */
    fun showUnlock(
        activity: AppCompatActivity,
        store: VaultPinStore,
        onUnlocked: () -> Unit,
        onCancel: () -> Unit = {}
    ): AlertDialog {
        val binding = DialogPinBinding.inflate(activity.layoutInflater)
        binding.textPinMessage.setText(R.string.vault_pin_unlock_message)
        binding.editPin.imeOptions = EditorInfo.IME_ACTION_DONE

        val dialog = MaterialAlertDialogBuilder(activity)
            .setTitle(R.string.vault_pin_unlock_title)
            .setView(binding.root)
            .setPositiveButton(R.string.vault_pin_confirm_button, null)
            .setNegativeButton(R.string.vault_pin_cancel) { dialogInterface, _ -> dialogInterface.cancel() }
            .setOnCancelListener { onCancel() }
            .create()
        dialog.setCanceledOnTouchOutside(false)

        var countdownJob: Job? = null
        dialog.setOnDismissListener { countdownJob?.cancel() }

        dialog.setOnShowListener {
            val confirmButton = dialog.getButton(DialogInterface.BUTTON_POSITIVE)

            fun hideKeyboard() {
                val manager = activity.getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
                manager.hideSoftInputFromWindow(binding.editPin.windowToken, 0)
                binding.editPin.clearFocus()
            }

            fun setLocked(locked: Boolean) {
                binding.editPin.isEnabled = !locked
                binding.inputLayoutPin.isEnabled = !locked
                confirmButton.isEnabled = !locked
            }

            /** Verrouille l'interface et affiche le décompte jusqu'à la fin du blocage. */
            fun startLockCountdown(initialSeconds: Int) {
                countdownJob?.cancel()
                binding.editPin.text?.clear()
                setLocked(true)
                hideKeyboard()
                countdownJob = activity.lifecycleScope.launch {
                    var left = initialSeconds
                    while (left > 0) {
                        binding.inputLayoutPin.error =
                            activity.getString(R.string.vault_pin_error_locked_countdown, formatCountdown(left))
                        delay(1000L)
                        // Relecture du temps réellement restant : le décompte reste exact même si l'écran a été mis en veille.
                        left = store.remainingLockSeconds()
                    }
                    binding.inputLayoutPin.error = null
                    setLocked(false)
                    binding.editPin.requestFocus()
                    dialog.window?.setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_STATE_VISIBLE)
                }
            }

            fun submit() {
                if (!binding.editPin.isEnabled) return
                val pin = binding.editPin.text?.toString().orEmpty()
                if (!VaultPinStore.isValidFormat(pin)) {
                    binding.inputLayoutPin.error = activity.getString(R.string.vault_pin_error_format)
                    return
                }
                confirmButton.isEnabled = false
                activity.lifecycleScope.launch {
                    when (val result = store.verify(pin)) {
                        PinCheckResult.Success -> {
                            dialog.dismiss()
                            onUnlocked()
                        }
                        is PinCheckResult.Wrong -> {
                            confirmButton.isEnabled = true
                            binding.editPin.text?.clear()
                            binding.inputLayoutPin.error =
                                activity.getString(R.string.vault_pin_error_wrong, result.attemptsLeft)
                        }
                        is PinCheckResult.Locked -> startLockCountdown(result.remainingSeconds)
                    }
                }
            }
            confirmButton.setOnClickListener { submit() }
            binding.editPin.doOnTextChanged { _, _, _, _ ->
                if (binding.editPin.isEnabled) binding.inputLayoutPin.error = null
            }
            binding.editPin.setOnEditorActionListener { _, actionId, _ ->
                if (actionId == EditorInfo.IME_ACTION_DONE) {
                    submit()
                    true
                } else {
                    false
                }
            }

            // Un blocage encore actif (application rouverte, téléphone redémarré) est repris immédiatement.
            activity.lifecycleScope.launch {
                val remaining = store.remainingLockSeconds()
                if (remaining > 0) {
                    startLockCountdown(remaining)
                } else {
                    binding.editPin.requestFocus()
                    dialog.window?.setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_STATE_VISIBLE)
                }
            }
        }
        dialog.show()
        return dialog
    }

    /** « 00:30 », « 05:00 », « 60:00 » : minutes et secondes. */
    private fun formatCountdown(totalSeconds: Int): String =
        String.format(Locale.US, "%02d:%02d", totalSeconds / 60, totalSeconds % 60)
}
EOF

echo "  -> app/src/main/java/com/elg/music/ui/vault/VaultActions.kt"
mkdir -p app/src/main/java/com/elg/music/ui/vault
cat << 'EOF' > app/src/main/java/com/elg/music/ui/vault/VaultActions.kt
package com.elg.music.ui.vault

import android.app.Activity
import android.provider.MediaStore
import android.widget.Toast
import androidx.activity.result.IntentSenderRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.elg.music.R
import com.elg.music.data.local.VaultEntryEntity
import com.elg.music.data.local.VaultPinStore
import com.elg.music.data.model.Song
import com.elg.music.data.repository.VaultRepository
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * Action « Masquer cette musique » (coffre-fort), partagée par le menu à trois points des listes et par
 * le menu d'options du grand lecteur : [com.elg.music.ui.main.SongActions] y renvoie l'identifiant
 * `action_vault_song`, donc les deux menus se comportent à l'identique.
 *
 * Déroulement : confirmation → création du code PIN si c'est la première fois → copie du fichier dans
 * le coffre → suppression de l'original (demande système si le fichier appartient à une autre
 * application) → le morceau quitte la bibliothèque et la file d'attente. Le fichier n'est jamais
 * supprimé avant que sa copie soit en place ; si la suppression est refusée, la copie est annulée.
 *
 * Doit être créée dans `onCreate` de l'Activity (enregistrement du lanceur de la demande système).
 *
 * @param onSongHidden appelée une fois le morceau réellement sorti du MediaStore : l'écran le retire
 *   de la bibliothèque et de la file d'attente (le lecteur passe alors au morceau suivant).
 */
class VaultActions(
    private val activity: AppCompatActivity,
    private val onSongHidden: (Song) -> Unit
) {

    private val pinStore = VaultPinStore(activity)
    private val repository = VaultRepository(activity)

    private var inProgress = false
    private var pendingSong: Song? = null
    private var pendingEntry: VaultEntryEntity? = null

    private val deleteRequestLauncher = activity.registerForActivityResult(
        ActivityResultContracts.StartIntentSenderForResult()
    ) { result ->
        val song = pendingSong
        val entry = pendingEntry
        pendingSong = null
        pendingEntry = null
        if (song == null || entry == null) {
            inProgress = false
            return@registerForActivityResult
        }
        if (result.resultCode == Activity.RESULT_OK) {
            completeHide(song)
        } else {
            activity.lifecycleScope.launch {
                repository.discard(entry)
                inProgress = false
                Toast.makeText(activity, R.string.vault_hide_cancelled_message, Toast.LENGTH_SHORT).show()
            }
        }
    }

    /** Demande confirmation, puis met le morceau au coffre-fort. */
    fun hide(song: Song) {
        if (inProgress) return
        MaterialAlertDialogBuilder(activity)
            .setTitle(R.string.vault_hide_dialog_title)
            .setMessage(activity.getString(R.string.vault_hide_dialog_message, song.title))
            .setPositiveButton(R.string.vault_hide_confirm) { _, _ -> ensurePinThenHide(song) }
            .setNegativeButton(R.string.delete_dialog_cancel, null)
            .show()
    }

    /** Première utilisation : le code PIN est créé avant que le moindre fichier ne parte au coffre. */
    private fun ensurePinThenHide(song: Song) {
        activity.lifecycleScope.launch {
            if (pinStore.hasPin()) {
                startHide(song)
            } else {
                PinDialogs.showCreate(
                    activity = activity,
                    store = pinStore,
                    titleRes = R.string.vault_pin_create_title,
                    onCreated = { startHide(song) }
                )
            }
        }
    }

    private fun startHide(song: Song) {
        if (inProgress) return
        inProgress = true
        activity.lifecycleScope.launch {
            val entry = try {
                repository.stage(song)
            } catch (cancellation: CancellationException) {
                inProgress = false
                throw cancellation
            } catch (error: Exception) {
                inProgress = false
                showError()
                return@launch
            }

            var removedRows = 0
            try {
                removedRows = withContext(Dispatchers.IO) {
                    activity.contentResolver.delete(song.contentUri, null, null)
                }
            } catch (cancellation: CancellationException) {
                // Copie conservée : au pire un doublon dans le coffre, jamais un fichier perdu.
                inProgress = false
                throw cancellation
            } catch (security: SecurityException) {
                // Fichier d'une autre application : passe par la demande système ci-dessous.
                removedRows = 0
            } catch (error: Exception) {
                repository.discard(entry)
                inProgress = false
                showError()
                return@launch
            }

            if (removedRows > 0) completeHide(song) else requestSystemDelete(song, entry)
        }
    }

    /** Suppression de l'original confirmée par le système (`MediaStore.createDeleteRequest`). */
    private fun requestSystemDelete(song: Song, entry: VaultEntryEntity) {
        try {
            val intentSender = MediaStore
                .createDeleteRequest(activity.contentResolver, listOf(song.contentUri))
                .intentSender
            pendingSong = song
            pendingEntry = entry
            deleteRequestLauncher.launch(IntentSenderRequest.Builder(intentSender).build())
        } catch (error: Exception) {
            pendingSong = null
            pendingEntry = null
            activity.lifecycleScope.launch {
                repository.discard(entry)
                inProgress = false
                showError()
            }
        }
    }

    private fun completeHide(song: Song) {
        inProgress = false
        onSongHidden(song)
        Toast.makeText(
            activity,
            activity.getString(R.string.vault_hidden_message, song.title),
            Toast.LENGTH_SHORT
        ).show()
    }

    private fun showError() {
        Toast.makeText(activity, R.string.vault_hide_error_message, Toast.LENGTH_LONG).show()
    }
}
EOF

echo "  -> app/src/main/java/com/elg/music/ui/vault/VaultAdapter.kt"
mkdir -p app/src/main/java/com/elg/music/ui/vault
cat << 'EOF' > app/src/main/java/com/elg/music/ui/vault/VaultAdapter.kt
package com.elg.music.ui.vault

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import androidx.recyclerview.widget.RecyclerView
import com.elg.music.R
import com.elg.music.data.local.VaultEntryEntity
import com.elg.music.databinding.ItemSongBinding

/**
 * Liste des morceaux du coffre-fort. Réutilise la ligne de morceau de la bibliothèque (`item_song`) :
 * même apparence, même bouton « ... » (ici : démasquer ou supprimer définitivement).
 *
 * @param onEntryClicked appelé quand l'utilisateur touche la ligne (lecture du coffre à partir de ce morceau).
 * @param onMenuClicked appelé quand l'utilisateur touche le bouton "..." (menu du morceau).
 */
class VaultAdapter(
    private val onEntryClicked: (VaultEntryEntity) -> Unit,
    private val onMenuClicked: (VaultEntryEntity, View) -> Unit
) : ListAdapter<VaultEntryEntity, VaultAdapter.VaultViewHolder>(VaultDiffCallback()) {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): VaultViewHolder {
        val binding = ItemSongBinding.inflate(LayoutInflater.from(parent.context), parent, false)
        return VaultViewHolder(binding)
    }

    override fun onBindViewHolder(holder: VaultViewHolder, position: Int) {
        holder.bind(getItem(position))
    }

    inner class VaultViewHolder(private val binding: ItemSongBinding) :
        RecyclerView.ViewHolder(binding.root) {

        fun bind(entry: VaultEntryEntity) {
            val context = binding.root.context
            binding.textSongTitle.text = entry.title

            val artist = entry.artist
            if (artist != null) {
                binding.textSongArtist.text = artist
                binding.textSongArtist.visibility = View.VISIBLE
                binding.root.contentDescription =
                    context.getString(R.string.song_row_content_description, entry.title, artist)
            } else {
                binding.textSongArtist.visibility = View.GONE
                binding.root.contentDescription =
                    context.getString(R.string.song_row_content_description_no_artist, entry.title)
            }

            binding.buttonSongMenu.contentDescription =
                context.getString(R.string.song_menu_button_content_description, entry.title)

            binding.root.setOnClickListener { onEntryClicked(entry) }
            binding.buttonSongMenu.setOnClickListener { anchor -> onMenuClicked(entry, anchor) }
        }
    }

    private class VaultDiffCallback : DiffUtil.ItemCallback<VaultEntryEntity>() {
        override fun areItemsTheSame(oldItem: VaultEntryEntity, newItem: VaultEntryEntity): Boolean =
            oldItem.id == newItem.id

        override fun areContentsTheSame(oldItem: VaultEntryEntity, newItem: VaultEntryEntity): Boolean =
            oldItem == newItem
    }
}
EOF

echo "  -> app/src/main/java/com/elg/music/ui/vault/VaultActivity.kt"
mkdir -p app/src/main/java/com/elg/music/ui/vault
cat << 'EOF' > app/src/main/java/com/elg/music/ui/vault/VaultActivity.kt
package com.elg.music.ui.vault

import android.os.Bundle
import android.view.Menu
import android.view.MenuItem
import android.view.View
import android.view.WindowManager
import android.widget.PopupMenu
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.repeatOnLifecycle
import androidx.recyclerview.widget.LinearLayoutManager
import com.elg.music.R
import com.elg.music.data.local.VaultEntryEntity
import com.elg.music.data.local.VaultPinStore
import com.elg.music.data.repository.VaultRepository
import com.elg.music.databinding.ActivityVaultBinding
import com.elg.music.playback.PlaybackUiState
import com.elg.music.playback.PlayerController
import com.elg.music.ui.applySystemBarPadding
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch

/**
 * Coffre-fort audio (Réglages → Coffre-fort) : consulter, lire, démasquer ou supprimer définitivement
 * les morceaux masqués.
 *
 * L'accès est protégé par le code PIN : à la première ouverture, l'écran demande d'en créer un ; ensuite
 * il le demande à chaque ouverture, et de nouveau dès que l'écran quitte le premier plan (sauf simple
 * rotation). Tant qu'il est verrouillé, la liste n'est ni chargée ni affichée. La capture d'écran et
 * l'aperçu dans les applications récentes sont interdits (FLAG_SECURE).
 *
 * La lecture passe par le même service que le reste de l'application : un morceau du coffre se lit
 * comme les autres, avec notification et commandes.
 */
class VaultActivity : AppCompatActivity() {

    private lateinit var binding: ActivityVaultBinding
    private lateinit var pinStore: VaultPinStore
    private lateinit var repository: VaultRepository
    private lateinit var adapter: VaultAdapter
    private val playerController: PlayerController by lazy { PlayerController(this) }

    private var unlocked = false
    private var promptShowing = false
    private var activePinDialog: AlertDialog? = null
    private var observeJob: Job? = null
    private var entries: List<VaultEntryEntity> = emptyList()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE)
        binding = ActivityVaultBinding.inflate(layoutInflater)
        setContentView(binding.root)
        binding.root.applySystemBarPadding()

        setSupportActionBar(binding.toolbar)
        supportActionBar?.setDisplayHomeAsUpEnabled(true)
        binding.toolbar.setNavigationContentDescription(R.string.settings_back_description)

        pinStore = VaultPinStore(this)
        repository = VaultRepository(this)
        adapter = VaultAdapter(onEntryClicked = ::playFrom, onMenuClicked = ::showEntryMenu)
        binding.recyclerVault.layoutManager = LinearLayoutManager(this)
        binding.recyclerVault.adapter = adapter
        binding.buttonVaultPlayPause.setOnClickListener { playerController.togglePlayPause() }

        // Conservé seulement lors d'une rotation d'écran (voir onStop) : jamais après un passage en arrière-plan.
        unlocked = savedInstanceState?.getBoolean(KEY_UNLOCKED, false) ?: false
        showLockedState()
        observePlayback()
    }

    override fun onStart() {
        super.onStart()
        playerController.connect()
        if (unlocked) startObserving() else requestUnlock()
    }

    override fun onStop() {
        playerController.disconnect()
        observeJob?.cancel()
        observeJob = null
        activePinDialog?.dismiss()
        activePinDialog = null
        promptShowing = false
        if (!isChangingConfigurations) {
            unlocked = false
            showLockedState()
        }
        super.onStop()
    }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        outState.putBoolean(KEY_UNLOCKED, unlocked)
    }

    override fun onCreateOptionsMenu(menu: Menu): Boolean {
        menuInflater.inflate(R.menu.menu_vault, menu)
        return true
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        return when (item.itemId) {
            R.id.action_vault_change_pin -> {
                if (unlocked) changePin()
                true
            }
            else -> super.onOptionsItemSelected(item)
        }
    }

    override fun onSupportNavigateUp(): Boolean {
        finish()
        return true
    }

    // ===================== Verrouillage =====================

    private fun requestUnlock() {
        if (promptShowing) return
        promptShowing = true
        lifecycleScope.launch {
            val hasPin = pinStore.hasPin()
            if (!lifecycle.currentState.isAtLeast(Lifecycle.State.STARTED)) {
                promptShowing = false
                return@launch
            }
            activePinDialog = if (hasPin) {
                PinDialogs.showUnlock(
                    activity = this@VaultActivity,
                    store = pinStore,
                    onUnlocked = ::onUnlocked,
                    onCancel = ::onPinCancelled
                )
            } else {
                PinDialogs.showCreate(
                    activity = this@VaultActivity,
                    store = pinStore,
                    titleRes = R.string.vault_pin_create_title,
                    onCreated = ::onUnlocked,
                    onCancel = ::onPinCancelled
                )
            }
        }
    }

    private fun onUnlocked() {
        promptShowing = false
        activePinDialog = null
        unlocked = true
        renderNowPlaying(playerController.state.value)
        startObserving()
    }

    private fun onPinCancelled() {
        promptShowing = false
        activePinDialog = null
        finish()
    }

    /** Écran verrouillé : ni liste, ni message, ni barre de lecture. */
    private fun showLockedState() {
        entries = emptyList()
        adapter.submitList(emptyList())
        binding.recyclerVault.visibility = View.GONE
        binding.textVaultEmpty.visibility = View.GONE
        binding.layoutVaultNowPlaying.visibility = View.GONE
    }

    private fun changePin() {
        activePinDialog = PinDialogs.showCreate(
            activity = this,
            store = pinStore,
            titleRes = R.string.vault_pin_change_title,
            onCreated = {
                activePinDialog = null
                Toast.makeText(this, R.string.vault_pin_changed_message, Toast.LENGTH_SHORT).show()
            },
            onCancel = { activePinDialog = null }
        )
    }

    // ===================== Liste =====================

    private fun startObserving() {
        observeJob?.cancel()
        observeJob = lifecycleScope.launch {
            repository.observeEntries().collect { list -> render(list) }
        }
    }

    private fun render(list: List<VaultEntryEntity>) {
        entries = list
        adapter.submitList(list)
        val empty = list.isEmpty()
        binding.textVaultEmpty.visibility = if (empty) View.VISIBLE else View.GONE
        binding.recyclerVault.visibility = if (empty) View.GONE else View.VISIBLE
    }

    private fun observePlayback() {
        lifecycleScope.launch {
            repeatOnLifecycle(Lifecycle.State.STARTED) {
                playerController.state.collect { state -> renderNowPlaying(state) }
            }
        }
    }

    /** La barre de lecture n'apparaît que pour un morceau du coffre, et seulement une fois déverrouillé. */
    private fun renderNowPlaying(state: PlaybackUiState) {
        val isVaultTrack = unlocked &&
            state.title != null &&
            state.mediaId?.startsWith(VaultRepository.MEDIA_ID_PREFIX) == true
        binding.layoutVaultNowPlaying.visibility = if (isVaultTrack) View.VISIBLE else View.GONE
        if (!isVaultTrack) return
        binding.textVaultNowPlaying.text = state.title
        binding.buttonVaultPlayPause.setImageResource(
            if (state.isPlaying) R.drawable.ic_pause else R.drawable.ic_play_arrow
        )
        binding.buttonVaultPlayPause.contentDescription = getString(
            if (state.isPlaying) R.string.mini_player_pause_description else R.string.mini_player_play_description
        )
    }

    // ===================== Actions sur un morceau =====================

    private fun playFrom(entry: VaultEntryEntity) {
        val index = entries.indexOfFirst { it.id == entry.id }
        if (index == -1) return
        playerController.playSongs(entries.map(repository::toMediaItem), index)
    }

    private fun showEntryMenu(entry: VaultEntryEntity, anchor: View) {
        val popup = PopupMenu(this, anchor)
        popup.menuInflater.inflate(R.menu.menu_vault_item, popup.menu)
        popup.setOnMenuItemClickListener { item ->
            when (item.itemId) {
                R.id.action_vault_restore -> {
                    restoreEntry(entry)
                    true
                }
                R.id.action_vault_delete -> {
                    confirmDelete(entry)
                    true
                }
                else -> false
            }
        }
        popup.show()
    }

    /** Remet le morceau dans la bibliothèque ; l'écran principal la relira à son retour au premier plan. */
    private fun restoreEntry(entry: VaultEntryEntity) {
        playerController.removeFromQueue(repository.mediaIdOf(entry))
        lifecycleScope.launch {
            val restored = repository.restore(entry)
            val messageRes =
                if (restored) R.string.vault_restore_done_message else R.string.vault_restore_error_message
            Toast.makeText(this@VaultActivity, getString(messageRes, entry.title), Toast.LENGTH_SHORT).show()
        }
    }

    private fun confirmDelete(entry: VaultEntryEntity) {
        MaterialAlertDialogBuilder(this)
            .setTitle(R.string.vault_delete_dialog_title)
            .setMessage(getString(R.string.vault_delete_dialog_message, entry.title))
            .setPositiveButton(R.string.delete_dialog_confirm) { _, _ ->
                playerController.removeFromQueue(repository.mediaIdOf(entry))
                lifecycleScope.launch {
                    repository.discard(entry)
                    Toast.makeText(
                        this@VaultActivity,
                        getString(R.string.vault_deleted_message, entry.title),
                        Toast.LENGTH_SHORT
                    ).show()
                }
            }
            .setNegativeButton(R.string.delete_dialog_cancel, null)
            .show()
    }

    private companion object {
        const val KEY_UNLOCKED = "vault_unlocked"
    }
}
EOF

echo "  -> app/src/main/res/layout/dialog_pin.xml"
mkdir -p app/src/main/res/layout
cat << 'EOF' > app/src/main/res/layout/dialog_pin.xml
<?xml version="1.0" encoding="utf-8"?>
<!-- Dialogue du code PIN du coffre-fort : message, champ du code, et champ de confirmation (création seulement). -->
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:orientation="vertical"
    android:paddingStart="24dp"
    android:paddingTop="8dp"
    android:paddingEnd="24dp">

    <TextView
        android:id="@+id/textPinMessage"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_marginBottom="12dp"
        android:textAppearance="?attr/textAppearanceBodyMedium"
        android:textColor="?attr/colorOnSurfaceVariant" />

    <com.google.android.material.textfield.TextInputLayout
        android:id="@+id/inputLayoutPin"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:hint="@string/vault_pin_hint"
        app:endIconMode="password_toggle">

        <com.google.android.material.textfield.TextInputEditText
            android:id="@+id/editPin"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:imeOptions="actionNext"
            android:importantForAutofill="no"
            android:inputType="numberPassword"
            android:maxLength="6"
            android:maxLines="1" />

    </com.google.android.material.textfield.TextInputLayout>

    <com.google.android.material.textfield.TextInputLayout
        android:id="@+id/inputLayoutPinConfirm"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_marginTop="8dp"
        android:hint="@string/vault_pin_confirm_hint"
        android:visibility="gone"
        app:endIconMode="password_toggle">

        <com.google.android.material.textfield.TextInputEditText
            android:id="@+id/editPinConfirm"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:imeOptions="actionDone"
            android:importantForAutofill="no"
            android:inputType="numberPassword"
            android:maxLength="6"
            android:maxLines="1" />

    </com.google.android.material.textfield.TextInputLayout>

</LinearLayout>
EOF

echo "  -> app/src/main/res/layout/activity_vault.xml"
mkdir -p app/src/main/res/layout
cat << 'EOF' > app/src/main/res/layout/activity_vault.xml
<?xml version="1.0" encoding="utf-8"?>
<androidx.constraintlayout.widget.ConstraintLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    xmlns:tools="http://schemas.android.com/tools"
    android:layout_width="match_parent"
    android:layout_height="match_parent">

    <com.google.android.material.appbar.MaterialToolbar
        android:id="@+id/toolbar"
        android:layout_width="0dp"
        android:layout_height="?attr/actionBarSize"
        android:background="?attr/colorSurface"
        app:title="@string/vault_title"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toTopOf="parent" />

    <androidx.recyclerview.widget.RecyclerView
        android:id="@+id/recyclerVault"
        android:layout_width="0dp"
        android:layout_height="0dp"
        android:clipToPadding="false"
        android:paddingBottom="8dp"
        android:visibility="gone"
        app:layout_constraintBottom_toTopOf="@id/layoutVaultNowPlaying"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toBottomOf="@id/toolbar"
        tools:listitem="@layout/item_song" />

    <TextView
        android:id="@+id/textVaultEmpty"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_marginStart="32dp"
        android:layout_marginEnd="32dp"
        android:gravity="center"
        android:text="@string/vault_empty_message"
        android:textAppearance="?attr/textAppearanceBodyLarge"
        android:visibility="gone"
        app:layout_constraintBottom_toTopOf="@id/layoutVaultNowPlaying"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toBottomOf="@id/toolbar" />

    <!-- Barre de lecture minimale : visible seulement quand un morceau du coffre est en cours. -->
    <LinearLayout
        android:id="@+id/layoutVaultNowPlaying"
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:background="?attr/colorSurfaceContainerHigh"
        android:gravity="center_vertical"
        android:orientation="horizontal"
        android:paddingStart="16dp"
        android:paddingEnd="8dp"
        android:visibility="gone"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        tools:visibility="visible">

        <TextView
            android:id="@+id/textVaultNowPlaying"
            android:layout_width="0dp"
            android:layout_height="wrap_content"
            android:layout_weight="1"
            android:ellipsize="end"
            android:maxLines="1"
            android:textAppearance="?attr/textAppearanceTitleSmall"
            tools:text="Titre en cours de lecture" />

        <ImageButton
            android:id="@+id/buttonVaultPlayPause"
            android:layout_width="56dp"
            android:layout_height="56dp"
            android:background="?attr/selectableItemBackgroundBorderless"
            android:contentDescription="@string/mini_player_play_description"
            android:src="@drawable/ic_play_arrow"
            app:tint="?attr/colorOnSurface" />

    </LinearLayout>

</androidx.constraintlayout.widget.ConstraintLayout>
EOF

echo "  -> app/src/main/res/menu/menu_vault.xml"
mkdir -p app/src/main/res/menu
cat << 'EOF' > app/src/main/res/menu/menu_vault.xml
<?xml version="1.0" encoding="utf-8"?>
<menu xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto">

    <item
        android:id="@+id/action_vault_change_pin"
        android:title="@string/vault_menu_change_pin"
        app:showAsAction="never" />

</menu>
EOF

echo "  -> app/src/main/res/menu/menu_vault_item.xml"
mkdir -p app/src/main/res/menu
cat << 'EOF' > app/src/main/res/menu/menu_vault_item.xml
<?xml version="1.0" encoding="utf-8"?>
<menu xmlns:android="http://schemas.android.com/apk/res/android">

    <item
        android:id="@+id/action_vault_restore"
        android:title="@string/vault_menu_restore" />

    <item
        android:id="@+id/action_vault_delete"
        android:title="@string/vault_menu_delete" />

</menu>
EOF

echo "  -> app/src/main/res/xml/data_extraction_rules.xml"
mkdir -p app/src/main/res/xml
cat << 'EOF' > app/src/main/res/xml/data_extraction_rules.xml
<?xml version="1.0" encoding="utf-8"?>
<!-- Le coffre-fort ne doit jamais quitter l'appareil : ni sauvegarde dans le cloud, ni transfert vers un
     autre téléphone. Sans cela, le code PIN et la base seraient restaurés sans les fichiers audio. -->
<data-extraction-rules>
    <cloud-backup>
        <exclude domain="file" path="vault" />
        <exclude domain="file" path="datastore/elg_vault_security.preferences_pb" />
        <exclude domain="database" path="elg_music.db" />
        <exclude domain="database" path="elg_music.db-wal" />
        <exclude domain="database" path="elg_music.db-shm" />
        <exclude domain="database" path="elg_music.db-journal" />
    </cloud-backup>
    <device-transfer>
        <exclude domain="file" path="vault" />
        <exclude domain="file" path="datastore/elg_vault_security.preferences_pb" />
        <exclude domain="database" path="elg_music.db" />
        <exclude domain="database" path="elg_music.db-wal" />
        <exclude domain="database" path="elg_music.db-shm" />
        <exclude domain="database" path="elg_music.db-journal" />
    </device-transfer>
</data-extraction-rules>
EOF

echo "  -> app/src/main/java/com/elg/music/playback/SleepTimerHub.kt"
mkdir -p app/src/main/java/com/elg/music/playback
cat << 'EOF' > app/src/main/java/com/elg/music/playback/SleepTimerHub.kt
package com.elg.music.playback

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/** Mode du minuteur de sommeil. */
enum class SleepTimerMode { IDLE, COUNTDOWN, END_OF_TRACK }

/**
 * État du minuteur de sommeil, publié par [SleepTimerController] (service de lecture) et affiché par l'écran.
 *
 * @param remainingMs temps restant avant l'arrêt (0 si inconnu).
 * @param fading vrai pendant le fondu sonore des 30 dernières secondes.
 */
data class SleepTimerState(
    val mode: SleepTimerMode = SleepTimerMode.IDLE,
    val remainingMs: Long = 0L,
    val fading: Boolean = false
) {
    val isActive: Boolean
        get() = mode != SleepTimerMode.IDLE
}

/** Ordres envoyés au minuteur depuis l'interface. */
sealed interface SleepTimerRequest {
    data class StartCountdown(val minutes: Int) : SleepTimerRequest
    data object StartEndOfTrack : SleepTimerRequest
    data object Cancel : SleepTimerRequest
}

/**
 * Point de rencontre, dans le processus de l'application, entre l'interface et le minuteur qui vit dans
 * [MusicPlaybackService] : l'interface envoie des ordres et observe [state].
 *
 * Tant que le service de lecture n'est pas actif, [send] renvoie false : il n'y a alors aucune lecture à arrêter.
 */
object SleepTimerHub {

    private val _state = MutableStateFlow(SleepTimerState())
    val state: StateFlow<SleepTimerState> = _state.asStateFlow()

    @Volatile
    private var handler: ((SleepTimerRequest) -> Unit)? = null

    /** Vrai quand le service de lecture est là pour exécuter les ordres. */
    val isServiceAttached: Boolean
        get() = handler != null

    /** Envoie un ordre ; renvoie false si le service de lecture n'est pas actif. */
    fun send(request: SleepTimerRequest): Boolean {
        val target = handler ?: return false
        target(request)
        return true
    }

    internal fun attach(newHandler: (SleepTimerRequest) -> Unit) {
        handler = newHandler
    }

    internal fun detach(oldHandler: (SleepTimerRequest) -> Unit) {
        if (handler === oldHandler) handler = null
    }

    internal fun publish(newState: SleepTimerState) {
        _state.value = newState
    }
}
EOF

echo "  -> app/src/main/java/com/elg/music/playback/SleepTimerController.kt"
mkdir -p app/src/main/java/com/elg/music/playback
cat << 'EOF' > app/src/main/java/com/elg/music/playback/SleepTimerController.kt
package com.elg.music.playback

import android.content.Context
import android.os.SystemClock
import androidx.media3.common.C
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
import com.elg.music.data.local.SettingsRepository
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch

/**
 * Minuteur de sommeil (étape 5 de la v1.4), hébergé par [MusicPlaybackService] : il continue donc de
 * compter quand l'application est fermée, tant que la lecture est en cours.
 *
 *  - Décompte : la lecture est mise en pause quand la durée choisie (15, 30, 45, 60 min) est écoulée.
 *  - Fin de la piste : la lecture s'arrête exactement à la fin du morceau en cours
 *    (`pauseAtEndOfMediaItems` d'ExoPlayer), sans laisser entendre le début du suivant.
 *  - Fondu sonore (option, réglage `fadeOutEnabled` du DataStore) : le volume du lecteur baisse
 *    progressivement pendant les 30 dernières secondes, puis est remis à 100 % une fois la pause effective.
 *
 * Doit être utilisé sur le thread principal (celui d'ExoPlayer dans le service).
 */
class SleepTimerController(
    context: Context,
    private val player: ExoPlayer
) : Player.Listener {

    private val repository = SettingsRepository(context)
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private var settingsJob: Job? = null
    private var tickJob: Job? = null
    private var volumeRestoreJob: Job? = null

    private var fadeEnabled = true
    private var mode = SleepTimerMode.IDLE
    private var endAtRealtimeMs = 0L

    private val requestHandler: (SleepTimerRequest) -> Unit = { request ->
        scope.launch { handle(request) }
    }

    fun attach() {
        player.addListener(this)
        settingsJob = scope.launch {
            repository.settings.collect { settings -> fadeEnabled = settings.fadeOutEnabled }
        }
        SleepTimerHub.attach(requestHandler)
        SleepTimerHub.publish(SleepTimerState())
    }

    fun release() {
        SleepTimerHub.detach(requestHandler)
        settingsJob?.cancel()
        settingsJob = null
        stopTick()
        volumeRestoreJob?.cancel()
        player.setPauseAtEndOfMediaItems(false)
        player.volume = 1f
        player.removeListener(this)
        mode = SleepTimerMode.IDLE
        SleepTimerHub.publish(SleepTimerState())
        scope.cancel()
    }

    // ===================== Ordres =====================

    private fun handle(request: SleepTimerRequest) {
        when (request) {
            is SleepTimerRequest.StartCountdown -> startCountdown(request.minutes)
            SleepTimerRequest.StartEndOfTrack -> startEndOfTrack()
            SleepTimerRequest.Cancel -> cancel()
        }
    }

    private fun startCountdown(minutes: Int) {
        resetBeforeStart()
        mode = SleepTimerMode.COUNTDOWN
        endAtRealtimeMs = SystemClock.elapsedRealtime() + minutes.coerceIn(1, MAX_MINUTES) * 60_000L
        startTick()
    }

    private fun startEndOfTrack() {
        resetBeforeStart()
        mode = SleepTimerMode.END_OF_TRACK
        player.setPauseAtEndOfMediaItems(true)
        startTick()
    }

    private fun cancel() {
        stopTick()
        volumeRestoreJob?.cancel()
        player.setPauseAtEndOfMediaItems(false)
        player.volume = 1f
        mode = SleepTimerMode.IDLE
        SleepTimerHub.publish(SleepTimerState())
    }

    private fun resetBeforeStart() {
        stopTick()
        volumeRestoreJob?.cancel()
        player.setPauseAtEndOfMediaItems(false)
        player.volume = 1f
    }

    // ===================== Décompte et fondu =====================

    private fun startTick() {
        tickJob?.cancel()
        onTick()
        tickJob = scope.launch {
            while (isActive) {
                delay(TICK_MS)
                onTick()
            }
        }
    }

    private fun stopTick() {
        tickJob?.cancel()
        tickJob = null
    }

    private fun onTick() {
        if (mode == SleepTimerMode.IDLE) return
        val remaining = remainingMs()
        if (mode == SleepTimerMode.COUNTDOWN && remaining != null && remaining <= 0L) {
            expire()
            return
        }
        val fading = fadeEnabled && remaining != null && remaining <= FADE_MS
        val target = if (fading) {
            val ratio = (remaining!!.toFloat() / FADE_MS).coerceIn(0f, 1f)
            ratio * ratio // courbe douce : le fondu est plus naturel à l'oreille qu'une descente linéaire
        } else {
            1f
        }
        if (player.volume != target) player.volume = target
        SleepTimerHub.publish(SleepTimerState(mode, remaining ?: 0L, fading))
    }

    /** Temps restant : durée choisie (décompte) ou fin du morceau en cours (tient compte de la vitesse). */
    private fun remainingMs(): Long? = when (mode) {
        SleepTimerMode.COUNTDOWN -> (endAtRealtimeMs - SystemClock.elapsedRealtime()).coerceAtLeast(0L)
        SleepTimerMode.END_OF_TRACK -> {
            val duration = player.duration
            if (duration == C.TIME_UNSET || duration <= 0L) {
                null
            } else {
                val speed = player.playbackParameters.speed.coerceAtLeast(0.1f)
                ((duration - player.currentPosition).coerceAtLeast(0L) / speed).toLong()
            }
        }
        SleepTimerMode.IDLE -> null
    }

    /** Décompte terminé : pause, puis volume remis à 100 % une fois le son réellement coupé. */
    private fun expire() {
        stopTick()
        mode = SleepTimerMode.IDLE
        SleepTimerHub.publish(SleepTimerState())
        player.pause()
        scheduleVolumeRestore()
    }

    /** Fin de piste atteinte : le lecteur s'est mis en pause tout seul. */
    private fun finishEndOfTrack() {
        stopTick()
        mode = SleepTimerMode.IDLE
        player.setPauseAtEndOfMediaItems(false)
        SleepTimerHub.publish(SleepTimerState())
        scheduleVolumeRestore()
    }

    private fun scheduleVolumeRestore() {
        volumeRestoreJob?.cancel()
        volumeRestoreJob = scope.launch {
            delay(VOLUME_RESTORE_DELAY_MS)
            if (mode == SleepTimerMode.IDLE) player.volume = 1f
        }
    }

    // ===================== Événements du lecteur =====================

    override fun onPlayWhenReadyChanged(playWhenReady: Boolean, reason: Int) {
        if (mode == SleepTimerMode.END_OF_TRACK && !playWhenReady &&
            reason == Player.PLAY_WHEN_READY_CHANGE_REASON_END_OF_MEDIA_ITEM
        ) {
            finishEndOfTrack()
        }
    }

    override fun onPlaybackStateChanged(playbackState: Int) {
        if (mode == SleepTimerMode.END_OF_TRACK && playbackState == Player.STATE_ENDED) {
            finishEndOfTrack()
        }
    }

    private companion object {
        const val TICK_MS = 250L
        const val FADE_MS = 30_000L
        const val MAX_MINUTES = 600
        const val VOLUME_RESTORE_DELAY_MS = 500L
    }
}
EOF

echo "  -> app/src/main/java/com/elg/music/playback/AbLoopController.kt"
mkdir -p app/src/main/java/com/elg/music/playback
cat << 'EOF' > app/src/main/java/com/elg/music/playback/AbLoopController.kt
package com.elg.music.playback

import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch

/** Boucle A-B du morceau en cours : points de début (A) et de fin (B), en millisecondes. */
data class AbLoopState(
    val aMs: Long? = null,
    val bMs: Long? = null,
    val enabled: Boolean = false
) {
    val isComplete: Boolean
        get() = aMs != null && bMs != null
}

/** Ordres envoyés à la boucle A-B depuis l'interface. */
sealed interface AbLoopRequest {
    data object MarkA : AbLoopRequest
    data object MarkB : AbLoopRequest
    data class SetEnabled(val enabled: Boolean) : AbLoopRequest
    data object Clear : AbLoopRequest
}

/** Résultat d'un ordre ; tout sauf [OK] est un refus à expliquer à l'utilisateur. */
enum class AbLoopResult { OK, NOT_ATTACHED, NO_TRACK, NEEDS_A, TOO_SHORT, INCOMPLETE }

/**
 * Point de rencontre entre l'interface et la boucle A-B qui vit dans [MusicPlaybackService]
 * (même principe que [SleepTimerHub]). À appeler depuis le thread principal.
 */
object AbLoopHub {

    private val _state = MutableStateFlow(AbLoopState())
    val state: StateFlow<AbLoopState> = _state.asStateFlow()

    @Volatile
    private var handler: ((AbLoopRequest) -> AbLoopResult)? = null

    fun send(request: AbLoopRequest): AbLoopResult {
        val target = handler ?: return AbLoopResult.NOT_ATTACHED
        return target(request)
    }

    internal fun attach(newHandler: (AbLoopRequest) -> AbLoopResult) {
        handler = newHandler
    }

    internal fun detach(oldHandler: (AbLoopRequest) -> AbLoopResult) {
        if (handler === oldHandler) handler = null
    }

    internal fun publish(newState: AbLoopState) {
        _state.value = newState
    }
}

/**
 * Contrôleur de boucle A-B (étape 5 de la v1.4), hébergé par [MusicPlaybackService].
 *
 * Les points A et B sont posés à la position de lecture du moment. Quand la boucle est activée,
 * la lecture revient en A dès qu'elle atteint B (contrôle toutes les [POLL_MS] ms, uniquement
 * pendant la lecture). Les points appartiennent au morceau : ils sont effacés quand on change de
 * morceau (sauf répétition du même titre).
 *
 * Doit être utilisé sur le thread principal.
 */
class AbLoopController(private val player: ExoPlayer) : Player.Listener {

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private var loopJob: Job? = null

    private var pointA: Long? = null
    private var pointB: Long? = null
    private var enabled = false

    private val requestHandler: (AbLoopRequest) -> AbLoopResult = { request -> handle(request) }

    fun attach() {
        player.addListener(this)
        AbLoopHub.attach(requestHandler)
        AbLoopHub.publish(AbLoopState())
    }

    fun release() {
        AbLoopHub.detach(requestHandler)
        loopJob?.cancel()
        loopJob = null
        player.removeListener(this)
        AbLoopHub.publish(AbLoopState())
        scope.cancel()
    }

    override fun onMediaItemTransition(mediaItem: MediaItem?, reason: Int) {
        if (reason == Player.MEDIA_ITEM_TRANSITION_REASON_REPEAT) return
        if (pointA != null || pointB != null || enabled) reset()
    }

    private fun handle(request: AbLoopRequest): AbLoopResult {
        when (request) {
            AbLoopRequest.MarkA -> {
                if (player.currentMediaItem == null) return AbLoopResult.NO_TRACK
                val position = player.currentPosition.coerceAtLeast(0L)
                pointA = position
                val end = pointB
                if (end != null && end - position < MIN_LOOP_MS) {
                    pointB = null
                    enabled = false
                }
            }
            AbLoopRequest.MarkB -> {
                if (player.currentMediaItem == null) return AbLoopResult.NO_TRACK
                val start = pointA ?: return AbLoopResult.NEEDS_A
                val position = player.currentPosition.coerceAtLeast(0L)
                if (position - start < MIN_LOOP_MS) return AbLoopResult.TOO_SHORT
                pointB = position
                enabled = true
            }
            is AbLoopRequest.SetEnabled -> {
                if (request.enabled && (pointA == null || pointB == null)) return AbLoopResult.INCOMPLETE
                enabled = request.enabled
            }
            AbLoopRequest.Clear -> {
                pointA = null
                pointB = null
                enabled = false
            }
        }
        sync()
        return AbLoopResult.OK
    }

    private fun reset() {
        pointA = null
        pointB = null
        enabled = false
        sync()
    }

    /** Publie l'état et démarre ou arrête le contrôle de position selon que la boucle est active. */
    private fun sync() {
        AbLoopHub.publish(AbLoopState(pointA, pointB, enabled))
        if (!enabled) {
            loopJob?.cancel()
            loopJob = null
            return
        }
        if (loopJob?.isActive == true) return
        loopJob = scope.launch {
            while (isActive) {
                delay(POLL_MS)
                val start = pointA ?: continue
                val end = pointB ?: continue
                if (player.isPlaying && player.currentPosition >= end) {
                    player.seekTo(start)
                }
            }
        }
    }

    private companion object {
        const val POLL_MS = 80L
        const val MIN_LOOP_MS = 1_000L
    }
}
EOF

echo "  -> app/src/main/java/com/elg/music/ui/player/SleepTimerSheet.kt"
mkdir -p app/src/main/java/com/elg/music/ui/player
cat << 'EOF' > app/src/main/java/com/elg/music/ui/player/SleepTimerSheet.kt
package com.elg.music.ui.player

import android.view.LayoutInflater
import android.view.View
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.elg.music.R
import com.elg.music.data.local.SettingsRepository
import com.elg.music.databinding.LayoutSleepTimerSheetBinding
import com.elg.music.playback.SleepTimerHub
import com.elg.music.playback.SleepTimerMode
import com.elg.music.playback.SleepTimerRequest
import com.elg.music.playback.SleepTimerState
import com.google.android.material.bottomsheet.BottomSheetBehavior
import com.google.android.material.bottomsheet.BottomSheetDialog
import kotlinx.coroutines.launch
import java.util.Locale

/**
 * Feuille « Minuteur de sommeil » : durée (15, 30, 45, 60 min ou fin de la piste), option de fondu
 * sonore, démarrage et annulation. Utilisée par Réglages et par le menu du grand lecteur.
 *
 * La feuille n'arrête rien elle-même : elle envoie l'ordre à [SleepTimerHub], exécuté par le
 * minuteur du service de lecture. La durée choisie devient la durée par défaut (DataStore), et
 * « fin de la piste » est enregistrée comme 0.
 */
object SleepTimerSheet {

    fun show(activity: AppCompatActivity) {
        val repository = SettingsRepository(activity)
        activity.lifecycleScope.launch {
            val settings = repository.current()
            open(activity, repository, settings.sleepTimerDefaultMin, settings.fadeOutEnabled)
        }
    }

    private fun open(
        activity: AppCompatActivity,
        repository: SettingsRepository,
        defaultMinutes: Int,
        fadeEnabled: Boolean
    ) {
        if (activity.isFinishing || activity.isDestroyed) return
        val binding = LayoutSleepTimerSheetBinding.inflate(LayoutInflater.from(activity))
        val dialog = BottomSheetDialog(activity)
        dialog.setContentView(binding.root)
        dialog.setOnShowListener { dialog.behavior.state = BottomSheetBehavior.STATE_EXPANDED }

        binding.radioGroupSleep.check(
            when (defaultMinutes) {
                0 -> R.id.radioSleepEnd
                15 -> R.id.radioSleep15
                45 -> R.id.radioSleep45
                60 -> R.id.radioSleep60
                else -> R.id.radioSleep30
            }
        )
        binding.switchSleepFade.isChecked = fadeEnabled
        binding.switchSleepFade.setOnCheckedChangeListener { _, checked ->
            activity.lifecycleScope.launch { repository.setFadeOutEnabled(checked) }
        }

        binding.buttonSleepStart.setOnClickListener {
            val minutes = when (binding.radioGroupSleep.checkedRadioButtonId) {
                R.id.radioSleepEnd -> 0
                R.id.radioSleep15 -> 15
                R.id.radioSleep45 -> 45
                R.id.radioSleep60 -> 60
                else -> 30
            }
            activity.lifecycleScope.launch { repository.setSleepTimerDefaultMin(minutes) }
            val request = if (minutes == 0) {
                SleepTimerRequest.StartEndOfTrack
            } else {
                SleepTimerRequest.StartCountdown(minutes)
            }
            if (SleepTimerHub.send(request)) {
                val message = if (minutes == 0) {
                    activity.getString(R.string.sleep_timer_started_end)
                } else {
                    activity.getString(R.string.sleep_timer_started_minutes, minutes)
                }
                Toast.makeText(activity, message, Toast.LENGTH_SHORT).show()
                dialog.dismiss()
            } else {
                binding.textSleepStatus.setText(R.string.sleep_timer_no_playback)
            }
        }
        binding.buttonSleepCancel.setOnClickListener {
            SleepTimerHub.send(SleepTimerRequest.Cancel)
            Toast.makeText(activity, R.string.sleep_timer_cancelled, Toast.LENGTH_SHORT).show()
            dialog.dismiss()
        }

        fun render(state: SleepTimerState) {
            binding.buttonSleepCancel.visibility = if (state.isActive) View.VISIBLE else View.GONE
            binding.textSleepFading.visibility = if (state.fading) View.VISIBLE else View.GONE
            binding.textSleepStatus.text = when (state.mode) {
                SleepTimerMode.COUNTDOWN ->
                    activity.getString(R.string.sleep_timer_status_countdown, formatTime(state.remainingMs))
                SleepTimerMode.END_OF_TRACK ->
                    if (state.remainingMs > 0L) {
                        activity.getString(
                            R.string.sleep_timer_status_end_of_track_remaining,
                            formatTime(state.remainingMs)
                        )
                    } else {
                        activity.getString(R.string.sleep_timer_status_end_of_track)
                    }
                SleepTimerMode.IDLE ->
                    activity.getString(
                        if (SleepTimerHub.isServiceAttached) {
                            R.string.sleep_timer_status_idle
                        } else {
                            R.string.sleep_timer_no_playback
                        }
                    )
            }
        }

        val observeJob = activity.lifecycleScope.launch {
            SleepTimerHub.state.collect { state -> render(state) }
        }
        dialog.setOnDismissListener { observeJob.cancel() }
        dialog.show()
    }

    private fun formatTime(ms: Long): String {
        val totalSeconds = ((ms + 999L) / 1000L).coerceAtLeast(0L)
        val hours = totalSeconds / 3600L
        val minutes = (totalSeconds % 3600L) / 60L
        val seconds = totalSeconds % 60L
        return if (hours > 0L) {
            String.format(Locale.getDefault(), "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            String.format(Locale.getDefault(), "%d:%02d", minutes, seconds)
        }
    }
}
EOF

echo "  -> app/src/main/java/com/elg/music/ui/player/AbLoopSheet.kt"
mkdir -p app/src/main/java/com/elg/music/ui/player
cat << 'EOF' > app/src/main/java/com/elg/music/ui/player/AbLoopSheet.kt
package com.elg.music.ui.player

import android.view.LayoutInflater
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.elg.music.R
import com.elg.music.databinding.LayoutAbLoopSheetBinding
import com.elg.music.playback.AbLoopHub
import com.elg.music.playback.AbLoopRequest
import com.elg.music.playback.AbLoopResult
import com.elg.music.playback.AbLoopState
import com.elg.music.playback.PlaybackUiState
import com.google.android.material.bottomsheet.BottomSheetBehavior
import com.google.android.material.bottomsheet.BottomSheetDialog
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import java.util.Locale

/**
 * Feuille « Boucle A-B » : marquer le début (A) et la fin (B) d'un passage pendant la lecture,
 * activer ou désactiver la répétition en boucle, effacer. La position actuelle est affichée en direct
 * pour aider à placer les points. Les ordres passent par [AbLoopHub] (contrôleur du service de lecture).
 *
 * @param playback état de lecture, pour afficher la position actuelle.
 */
object AbLoopSheet {

    fun show(activity: AppCompatActivity, playback: StateFlow<PlaybackUiState>) {
        val binding = LayoutAbLoopSheetBinding.inflate(LayoutInflater.from(activity))
        val dialog = BottomSheetDialog(activity)
        dialog.setContentView(binding.root)
        dialog.setOnShowListener { dialog.behavior.state = BottomSheetBehavior.STATE_EXPANDED }

        var rendering = false

        fun render(state: AbLoopState) {
            rendering = true
            val unset = activity.getString(R.string.ab_loop_not_set)
            binding.textAbPointA.text = activity.getString(
                R.string.ab_loop_point_a_format, state.aMs?.let(::formatTenths) ?: unset
            )
            binding.textAbPointB.text = activity.getString(
                R.string.ab_loop_point_b_format, state.bMs?.let(::formatTenths) ?: unset
            )
            binding.switchAbRepeat.isEnabled = state.isComplete
            binding.switchAbRepeat.isChecked = state.enabled
            binding.buttonAbClear.isEnabled = state.aMs != null || state.bMs != null
            rendering = false
        }

        fun report(result: AbLoopResult) {
            val messageRes = when (result) {
                AbLoopResult.OK -> null
                AbLoopResult.NOT_ATTACHED, AbLoopResult.NO_TRACK -> R.string.ab_loop_error_no_track
                AbLoopResult.NEEDS_A -> R.string.ab_loop_error_needs_a
                AbLoopResult.TOO_SHORT -> R.string.ab_loop_error_too_short
                AbLoopResult.INCOMPLETE -> R.string.ab_loop_error_incomplete
            }
            if (messageRes != null) Toast.makeText(activity, messageRes, Toast.LENGTH_SHORT).show()
            render(AbLoopHub.state.value)
        }

        binding.buttonAbMarkA.setOnClickListener { report(AbLoopHub.send(AbLoopRequest.MarkA)) }
        binding.buttonAbMarkB.setOnClickListener { report(AbLoopHub.send(AbLoopRequest.MarkB)) }
        binding.switchAbRepeat.setOnCheckedChangeListener { _, checked ->
            if (!rendering) report(AbLoopHub.send(AbLoopRequest.SetEnabled(checked)))
        }
        binding.buttonAbClear.setOnClickListener {
            report(AbLoopHub.send(AbLoopRequest.Clear))
            Toast.makeText(activity, R.string.ab_loop_cleared_message, Toast.LENGTH_SHORT).show()
        }

        val stateJob = activity.lifecycleScope.launch {
            AbLoopHub.state.collect { state -> render(state) }
        }
        val positionJob = activity.lifecycleScope.launch {
            playback.collect { state ->
                binding.textAbPosition.text =
                    activity.getString(R.string.ab_loop_position_format, formatTenths(state.positionMs))
            }
        }
        dialog.setOnDismissListener {
            stateJob.cancel()
            positionJob.cancel()
        }
        dialog.show()
    }

    /** « 1:23.4 » : minutes, secondes et dixièmes. */
    private fun formatTenths(ms: Long): String {
        val safe = ms.coerceAtLeast(0L)
        val totalSeconds = safe / 1000L
        val tenths = (safe % 1000L) / 100L
        return String.format(Locale.getDefault(), "%d:%02d.%d", totalSeconds / 60L, totalSeconds % 60L, tenths)
    }
}
EOF

echo "  -> app/src/main/res/layout/layout_sleep_timer_sheet.xml"
mkdir -p app/src/main/res/layout
cat << 'EOF' > app/src/main/res/layout/layout_sleep_timer_sheet.xml
<?xml version="1.0" encoding="utf-8"?>
<!-- Feuille « Minuteur de sommeil » : statut, durée, fondu sonore, démarrer / annuler. -->
<androidx.core.widget.NestedScrollView xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="wrap_content">

    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="vertical"
        android:paddingStart="24dp"
        android:paddingTop="16dp"
        android:paddingEnd="24dp"
        android:paddingBottom="24dp">

        <TextView
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:accessibilityHeading="true"
            android:text="@string/sleep_timer_title"
            android:textAppearance="?attr/textAppearanceTitleMedium" />

        <TextView
            android:id="@+id/textSleepStatus"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:layout_marginTop="8dp"
            android:textAppearance="?attr/textAppearanceBodyMedium"
            android:textColor="?attr/colorPrimary" />

        <TextView
            android:id="@+id/textSleepFading"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:layout_marginTop="2dp"
            android:text="@string/sleep_timer_fading"
            android:textAppearance="?attr/textAppearanceBodyMedium"
            android:textColor="?attr/colorOnSurfaceVariant"
            android:visibility="gone" />

        <RadioGroup
            android:id="@+id/radioGroupSleep"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:layout_marginTop="8dp"
            android:orientation="vertical">

            <com.google.android.material.radiobutton.MaterialRadioButton
                android:id="@+id/radioSleep15"
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:minHeight="48dp"
                android:text="@string/sleep_timer_option_15" />

            <com.google.android.material.radiobutton.MaterialRadioButton
                android:id="@+id/radioSleep30"
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:minHeight="48dp"
                android:text="@string/sleep_timer_option_30" />

            <com.google.android.material.radiobutton.MaterialRadioButton
                android:id="@+id/radioSleep45"
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:minHeight="48dp"
                android:text="@string/sleep_timer_option_45" />

            <com.google.android.material.radiobutton.MaterialRadioButton
                android:id="@+id/radioSleep60"
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:minHeight="48dp"
                android:text="@string/sleep_timer_option_60" />

            <com.google.android.material.radiobutton.MaterialRadioButton
                android:id="@+id/radioSleepEnd"
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:minHeight="48dp"
                android:text="@string/sleep_timer_option_end" />

        </RadioGroup>

        <com.google.android.material.materialswitch.MaterialSwitch
            android:id="@+id/switchSleepFade"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:layout_marginTop="8dp"
            android:minHeight="48dp"
            android:text="@string/sleep_timer_fade_switch"
            android:textAppearance="?attr/textAppearanceBodyLarge" />

        <LinearLayout
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:layout_marginTop="16dp"
            android:gravity="center_vertical"
            android:orientation="horizontal">

            <Button
                android:id="@+id/buttonSleepStart"
                style="@style/Widget.Material3.Button.TonalButton"
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:minHeight="48dp"
                android:text="@string/sleep_timer_start" />

            <Button
                android:id="@+id/buttonSleepCancel"
                style="@style/Widget.Material3.Button.TextButton"
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:layout_marginStart="8dp"
                android:minHeight="48dp"
                android:text="@string/sleep_timer_cancel"
                android:visibility="gone" />

        </LinearLayout>

    </LinearLayout>

</androidx.core.widget.NestedScrollView>
EOF

echo "  -> app/src/main/res/layout/layout_ab_loop_sheet.xml"
mkdir -p app/src/main/res/layout
cat << 'EOF' > app/src/main/res/layout/layout_ab_loop_sheet.xml
<?xml version="1.0" encoding="utf-8"?>
<!-- Feuille « Boucle A-B » : position actuelle, points A et B, marquer, répéter, effacer. -->
<androidx.core.widget.NestedScrollView xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="wrap_content">

    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="vertical"
        android:paddingStart="24dp"
        android:paddingTop="16dp"
        android:paddingEnd="24dp"
        android:paddingBottom="24dp">

        <TextView
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:accessibilityHeading="true"
            android:text="@string/ab_loop_title"
            android:textAppearance="?attr/textAppearanceTitleMedium" />

        <TextView
            android:id="@+id/textAbHint"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:layout_marginTop="8dp"
            android:text="@string/ab_loop_hint"
            android:textAppearance="?attr/textAppearanceBodyMedium"
            android:textColor="?attr/colorOnSurfaceVariant" />

        <TextView
            android:id="@+id/textAbPosition"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:layout_marginTop="16dp"
            android:textAppearance="?attr/textAppearanceBodyLarge"
            android:textColor="?attr/colorPrimary" />

        <TextView
            android:id="@+id/textAbPointA"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:layout_marginTop="8dp"
            android:textAppearance="?attr/textAppearanceBodyLarge" />

        <TextView
            android:id="@+id/textAbPointB"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:layout_marginTop="4dp"
            android:textAppearance="?attr/textAppearanceBodyLarge" />

        <LinearLayout
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:layout_marginTop="16dp"
            android:gravity="center_vertical"
            android:orientation="horizontal">

            <Button
                android:id="@+id/buttonAbMarkA"
                style="@style/Widget.Material3.Button.TonalButton"
                android:layout_width="0dp"
                android:layout_height="wrap_content"
                android:layout_weight="1"
                android:minHeight="48dp"
                android:text="@string/ab_loop_mark_a" />

            <Button
                android:id="@+id/buttonAbMarkB"
                style="@style/Widget.Material3.Button.TonalButton"
                android:layout_width="0dp"
                android:layout_height="wrap_content"
                android:layout_marginStart="12dp"
                android:layout_weight="1"
                android:minHeight="48dp"
                android:text="@string/ab_loop_mark_b" />

        </LinearLayout>

        <com.google.android.material.materialswitch.MaterialSwitch
            android:id="@+id/switchAbRepeat"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:layout_marginTop="12dp"
            android:enabled="false"
            android:minHeight="48dp"
            android:text="@string/ab_loop_repeat_switch"
            android:textAppearance="?attr/textAppearanceBodyLarge" />

        <Button
            android:id="@+id/buttonAbClear"
            style="@style/Widget.Material3.Button.TextButton"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:minHeight="48dp"
            android:text="@string/ab_loop_clear" />

    </LinearLayout>

</androidx.core.widget.NestedScrollView>
EOF

echo "  -> app/debug.keystore"
mkdir -p app
base64 -d << 'EOF' > app/debug.keystore
MIIKZgIBAzCCChAGCSqGSIb3DQEHAaCCCgEEggn9MIIJ+TCCBcAGCSqGSIb3DQEHAaCCBbEEggWt
MIIFqTCCBaUGCyqGSIb3DQEMCgECoIIFQDCCBTwwZgYJKoZIhvcNAQUNMFkwOAYJKoZIhvcNAQUM
MCsEFAZFpApsW3CzRzpojWTdikPUeJYYAgInEAIBIDAMBggqhkiG9w0CCQUAMB0GCWCGSAFlAwQB
KgQQqZHb2KzxF3jPZoYkTmpOGgSCBNDTrHm1HZcaMVvIiPV/3kt5PASRsPEnIl7p0MBvK/vAjRcw
N9xE9NqtOC3FCAk4S61PORtFCq2rjhv72Y5H6q4Am9p+M7tA0MyXc6zshGhttvHXabH63NzL3dCH
guivWqueOQy9nvoWAIvQ9EbSasRF6W8InXUO8JlTGNJO5V4f1EgS7N5/82/Dz/wKoExycF5Lkt1X
Gk3NDsfbVhcVy5zU2DFmepCvkITzlPZaDcSM23E2dLG8gGMcbFiOcGffqk3842N2QcdOERbPmp38
LKn/KYbyg0zfQ7Uq9Nc/a8RppjfW+CDI6zl3pFUNnqf/l7efF8JcHQidYMRqJXqI83PWQzrSS7DA
ArvJxTE0UwN9WTQcBZZcNTMgDxu6LneYa95vAeHMJ7pxNbO/4ZwXyJ9weeAnyNEG2l/OmazaZp74
4EFCY7TKyyfVf1uIT7zVeni4K5C58z4aKt992JU7ERUt8HgkdLaHZ7pmGjB+N60VE5dCZDqSfX4J
Ax92pVkfQ5+arl7rhY+bcHe9+GPWYXgCAg6ygJu1ooP3UtOZeOgx6MjxkY8ptZ+UNfRGTXbydrxE
nH34tk3GT8Fn8YViMUicVG85ktZUytm9b/K0EH2VyP8GK3F2YhhvDHaXXdifat8KFgyO9gwM1mlc
r9mIO4UGFL+LLJVxtMMO73+NP7P0vt8p7yK4O6exrYb2VVwUnoqn6vE5qMIyDErZpqpzWOOlRUK0
gC2GK3UQ4vVtrduCHAv6Pvj447zOx6Hb2JlThcRjybsqRkgGT8J2et7jLGfxTa5AQ1a1K5Hcueb2
YTb/uy8FiAUp3UtFM/30NrmFwk+ntNUyYUZOB2ej+T3s9cyaJ7wlNYOU4egOU4596EHPC7uSMho6
rCb7VcTOWMvL4SITBIw/XqQADnYdDd5sS1jhFC6qV6Uv6t3sfOPigeRtbS1LIkXA3SHxsUhXkbhl
Xrou1x34njodsb9o0M6wI8Q8mfZBWHbmCJJLV8X3UVaW14wp8XFOlloQmkz2RFN70bdqNpjj9B9w
fzOE6m3jIQbmlEW2wbPM0dV7gZaPHk+ycF1ja2fWDz2yfdu3hS6Rg17cSF9ZeIJnn3Sr0LWWi2Tu
onywRRboRjwFK7eS0edZLA9n4oFU+Dro4YakCBoiQIRbMq027sKWGFE3cBNAPfMMBV8rz3ZV2Plr
DddtyLvSWjG0qng0gtI3bbXpjBsO1Ut+ds+NoizmJG3owhy/m6MOS7vQpyetiirosADZVy++fKoB
eaUQOt+iEmUiTEmta2KFDSJrLZY+V/I8hWwptk2KA8mbsTGclYUJiL9mmwfQW2JJ9O7it+F0gNap
ex/F6YTvgkcYfkKVl0Zcvf0os1dcqLLjLQc9ym2UTD1pYBMqTrIBH+K1A9aIxHTD++OEF6CNij/B
PKfoWMjhCJErX+sbSqzBN240tf7nN+uL/yns0Rk6cpTx3FLYWQuyvgMh3U52W75EBdEEOlAMKfsz
dDZGfrFBIF6vrRvLWK/w86G4ndsGYNH6WmtIXSznuS6GppRtUDzUXJTTa+XDlNHKgwgKM/eAUWP2
PRGQoXau9LPr3SlTbVRsReFL/7g9nCmIPITH42GBirZUAORBluv32vawTKjaXnzBCH41fDLnDGyz
CzFSMC0GCSqGSIb3DQEJFDEgHh4AYQBuAGQAcgBvAGkAZABkAGUAYgB1AGcAawBlAHkwIQYJKoZI
hvcNAQkVMRQEElRpbWUgMTc5MDY1OTk5NjU5MjCCBDEGCSqGSIb3DQEHBqCCBCIwggQeAgEAMIIE
FwYJKoZIhvcNAQcBMGYGCSqGSIb3DQEFDTBZMDgGCSqGSIb3DQEFDDArBBSrX1wpudjgLKuh0oZ1
gKAjSc9EzAICJxACASAwDAYIKoZIhvcNAgkFADAdBglghkgBZQMEASoEEJ5kC75m1Y00S1mt6rGZ
lpuAggOghK1GCVHgbc8o9iH2OP5v21Pro2SAh7G0M546tLkuGQBIU1G1uxEB2WPIoNMuyTh1WBz1
nvz2zEiHYMXgx4eMzm+VK9eyxmgYM078jlk/q2n7v626hvwyu5bjV9+FQpLpmmRy3Z73Dd8Gh0vL
Rw/uAO+p/Fd0UVrCJtZiLVP871ffU+4F6X+9VjpFycdaadrq9bqVaMDRVQXBhunIfr1W+albxAiE
VKQcF4Wg9cqTIpVTd8DppDxZl+doBRBySpYeh4azeB8hiT0njRmdOi8pPEzxRr6f1LwNqKY/tD3i
aBTOwdk+uYjxmgZ5u7s+idkW0WT6jW5dTbOmRxnoZi3YB5D00Gx+zlgnabfm0kcLVBV6BrG6X6xO
+n2bk5QnZzn5WqYEg7XY1qpy4w7E8nd7QS28qFoPcHHdlDNySMH+AYekn4okf234yonlgvQRXGxF
rUD+qeO4dPN8ZlLs51a/A4rE+MhtF94pghk+hFIrP19kr/2eYWdnOzxZlo9ccazIyymDLtPMXm5k
YvcRgc6kObhCIc8VPYfqcL9Yho4o3NBsnxroskmtsSU0FzIsFTgo8Ffu4lIMHQ2RHrzja14bQrNu
Iy07nMrn2dy98lEtjYCnyf2bulolO4QyvTZX4YNtlb+w3r2Sx4/wviImRcerl5AaQqbCKUUBdGV/
5ZGw71zbxbUQ8+3j379utbd10o5NXvR47MpmTQ1+3TT6ES+P058h7Elq58ycYzzZOFD8PjpZW659
Cpo4A8hei8NDibnzVM1oD8+t3axTv305fxbC2f9p1HrXk+egY5axDulxlEfHqvEjVB2NzvDForEw
YhfRyA7HAqxYa9YQH1QOfXIbr7/cEYhuu3HJXJoXjc/C+sswW0I1p4kUvO5hXO3uIMc1zkDHhccQ
w6FnqaE0YtdjWPi40fLQHy1G3rGt/qkVpXRviNA7dtnP+QE5OypF8GkQr4V6kb5zAxSjWYja1Lnh
NDt7qpknahaJisLxhtspqRdDpAs7c6uqhKcLcXFCeLfiLBXAjw1KUz0r/5lgVAx+BSUWPlvp1BIH
0OfkQwKgWAQMc0bEWpHM7AABwaCUSPqX00alDO3UZmnvj0+hsmpZfxis9rdQnJ6Ni5JXs0TU11cN
/zSoRDeLLmDgV/WKPZtgjmfQdTxqHQ4bd9VqZmdoZF8+4Tz47CCr+8gH1sfBhTIO9CN0GS9jqniD
y9JwxcA+yK3w1eVcdaXXfDs/93wQYTBNMDEwDQYJYIZIAWUDBAIBBQAEIM0vr/LzqBMMYVJ11T7K
+B9JIHaZnUQGhyZDcFGbsNCxBBQ0JBpndO4lwG0E/ortI4RgX2H0bAICJxA=
EOF

echo "  -> app/src/main/java/com/elg/music/data/model/TagData.kt"
mkdir -p app/src/main/java/com/elg/music/data/model
cat << 'EOF' > app/src/main/java/com/elg/music/data/model/TagData.kt
package com.elg.music.data.model

import android.net.Uri
import java.util.Locale

/**
 * Métadonnées modifiables d'un morceau (éditeur de tags, étape 6 de la v1.4).
 * Une chaîne vide signifie « champ absent ».
 */
data class TagData(
    val title: String = "",
    val artist: String = "",
    val album: String = "",
    val albumArtist: String = "",
    val genre: String = "",
    val year: String = "",
    val trackNumber: String = "",
    val trackTotal: String = "",
    val discNumber: String = "",
    val composer: String = "",
    val copyright: String = "",
    val publisher: String = "",
    val encoder: String = "",
    val language: String = "",
    val comment: String = "",
    val lyrics: String = "",
    /** Mois de la date d'enregistrement (« 1 » à « 12 »), vide si non renseigné ; l'année est [year]. */
    val recordingMonth: String = "",
    /** Jour de la date d'enregistrement (« 1 » à « 31 »), vide si non renseigné ; nécessite le mois. */
    val recordingDay: String = ""
) {
    /**
     * Date écrite dans les fichiers (ISO 8601) : « 2023 », « 2023-01 » ou « 2023-01-15 ».
     * L'année seule est renvoyée si le mois est absent ou si l'année n'a pas 4 chiffres.
     */
    val dateText: String
        get() {
            val y = year.trim()
            if (y.length != 4) return y
            val m = recordingMonth.toIntOrNull()?.takeIf { it in 1..12 } ?: return y
            val withMonth = String.format(Locale.ROOT, "%s-%02d", y, m)
            val d = recordingDay.toIntOrNull()?.takeIf { it in 1..31 } ?: return withMonth
            return String.format(Locale.ROOT, "%s-%02d", withMonth, d)
        }
}

/** Fichier audio tel que décrit par le MediaStore (source de l'éditeur de tags). */
data class AudioFileInfo(
    val id: Long,
    val uri: Uri,
    val displayName: String,
    val mimeType: String?,
    val sizeBytes: Long,
    val relativePath: String,
    val dataPath: String?,
    val mediaStoreTitle: String?,
    val durationMs: Long
) {
    /** Chemin complet (ex. /storage/emulated/0/Music/Titre.mp3). */
    val fullPath: String
        get() = dataPath?.takeIf { it.isNotBlank() }
            ?: ("/storage/emulated/0/" + relativePath + displayName)
}

/** Inspecteur technique : format, débit (kbps), fréquence d'échantillonnage (Hz), taille, chemin. */
data class TechInfo(
    val format: String,
    val bitrateKbps: Int?,
    val sampleRateHz: Int?,
    val sizeBytes: Long,
    val path: String
)

/** Date d'enregistrement décomposée ; une chaîne vide signifie « absent ». */
data class RecordingDateParts(val year: String, val month: String, val day: String)

/** Lecture des dates ISO 8601 partielles (« 2023 », « 2023-01 », « 2023-01-15 », « 20230115 »). */
object RecordingDate {

    private val FLEXIBLE = Regex("^(\\d{4})(?:-?(\\d{2})(?:-?(\\d{2}))?)?")
    private val STRICT_PREFIX = Regex("^\\d{4}(?:-\\d{2}(?:-\\d{2})?)?")

    fun parse(text: String): RecordingDateParts {
        val match = FLEXIBLE.find(text.trim()) ?: return RecordingDateParts("", "", "")
        val month = match.groupValues[2].toIntOrNull()?.takeIf { it in 1..12 }
        val day = if (month != null) match.groupValues[3].toIntOrNull()?.takeIf { it in 1..31 } else null
        return RecordingDateParts(match.groupValues[1], month?.toString().orEmpty(), day?.toString().orEmpty())
    }

    /** Début « AAAA[-MM[-JJ]] » d'une date ISO (l'heure éventuelle qui suit est ignorée). */
    fun isoPrefix(text: String): String = STRICT_PREFIX.find(text.trim())?.value.orEmpty()
}
EOF

echo "  -> app/src/main/java/com/elg/music/data/repository/Id3TagCodec.kt"
mkdir -p app/src/main/java/com/elg/music/data/repository
cat << 'EOF' > app/src/main/java/com/elg/music/data/repository/Id3TagCodec.kt
package com.elg.music.data.repository

import com.elg.music.data.model.RecordingDate
import com.elg.music.data.model.TagData
import java.io.BufferedInputStream
import java.io.ByteArrayOutputStream
import java.io.InputStream
import java.nio.charset.Charset

/**
 * Lecture et écriture des tags ID3v2 des fichiers MP3, sans bibliothèque externe.
 *
 * L'écriture produit toujours un tag ID3v2.4 (textes en UTF-8). Les images (APIC), TXXX, PRIV et
 * autres images du fichier d'origine sont conservées telles quelles, sauf les champs gérés par
 * l'éditeur. Les images dont le cadre est compressé ou chiffré sont abandonnées (elles ne peuvent
 * pas être recopiées sans les comprendre). Les tags ID3v2.2 ne sont pas conservés.
 */
object Id3TagCodec {

    class Frame(val id: String, val data: ByteArray)

    class ParsedTag(val frames: List<Frame>)

    private const val HEADER_SIZE = 10
    private const val FRAME_HEADER_SIZE = 10
    private const val MAX_TAG_BYTES = 32 * 1024 * 1024

    private val LATIN1: Charset = Charsets.ISO_8859_1
    private val UTF8: Charset = Charsets.UTF_8

    /** Cadres obsolètes en ID3v2.4 : retirés à l'écriture (remplacés par TDRC, etc.). */
    private val OBSOLETE_FRAMES = setOf("TYER", "TDAT", "TIME", "TRDA", "TORY", "TSIZ", "IPLS", "RVAD", "EQUA")

    /** Cadres écrits par l'éditeur : l'ancienne valeur est toujours remplacée. */
    private val MANAGED_TEXT_FRAMES = setOf(
        "TIT2", "TPE1", "TALB", "TPE2", "TCON", "TDRC", "TRCK", "TPOS",
        "TCOM", "TCOP", "TPUB", "TENC", "TLAN"
    )

    private val ID3V1_GENRES = listOf(
        "Blues", "Classic Rock", "Country", "Dance", "Disco", "Funk", "Grunge", "Hip-Hop", "Jazz", "Metal",
        "New Age", "Oldies", "Other", "Pop", "R&B", "Rap", "Reggae", "Rock", "Techno", "Industrial",
        "Alternative", "Ska", "Death Metal", "Pranks", "Soundtrack", "Euro-Techno", "Ambient", "Trip-Hop",
        "Vocal", "Jazz+Funk", "Fusion", "Trance", "Classical", "Instrumental", "Acid", "House", "Game",
        "Sound Clip", "Gospel", "Noise", "Alt. Rock", "Bass", "Soul", "Punk", "Space", "Meditative",
        "Instrumental Pop", "Instrumental Rock", "Ethnic", "Gothic", "Darkwave", "Techno-Industrial",
        "Electronic", "Pop-Folk", "Eurodance", "Dream", "Southern Rock", "Comedy", "Cult", "Gangsta",
        "Top 40", "Christian Rap", "Pop/Funk", "Jungle", "Native American", "Cabaret", "New Wave",
        "Psychedelic", "Rave", "Showtunes", "Trailer", "Lo-Fi", "Tribal", "Acid Punk", "Acid Jazz",
        "Polka", "Retro", "Musical", "Rock & Roll", "Hard Rock"
    )

    // ===================== Lecture =====================

    /**
     * Lit le tag ID3v2 placé au début du flux et le consomme : à la sortie, le flux est positionné
     * sur les données audio. Renvoie null (flux inchangé) s'il n'y a pas de tag.
     */
    fun readTag(input: BufferedInputStream): ParsedTag? {
        input.mark(HEADER_SIZE)
        val header = ByteArray(HEADER_SIZE)
        val read = readFully(input, header)
        val isTag = read == HEADER_SIZE &&
            header[0] == 'I'.code.toByte() && header[1] == 'D'.code.toByte() && header[2] == '3'.code.toByte()
        val major = header[3].toInt() and 0xFF
        val sizeBytesValid = (6..9).all { (header[it].toInt() and 0x80) == 0 }
        if (!isTag || major !in 2..4 || !sizeBytesValid) {
            input.reset()
            return null
        }
        val flags = header[5].toInt() and 0xFF
        val size = synchsafe(header, 6)
        if (size < 0 || size > MAX_TAG_BYTES) {
            input.reset()
            return null
        }
        val body = ByteArray(size)
        val got = readFully(input, body)
        if (major == 4 && (flags and 0x10) != 0) {
            readFully(input, ByteArray(HEADER_SIZE)) // pied de tag « 3DI »
        }
        return ParsedTag(parseFrames(major, flags, body.copyOf(got)))
    }

    private fun parseFrames(major: Int, flags: Int, raw: ByteArray): List<Frame> {
        if (major < 3) return emptyList()
        var body = raw
        if (major == 3 && (flags and 0x80) != 0) body = undoUnsync(body)
        var pos = 0
        if ((flags and 0x40) != 0) {
            if (body.size < 4) return emptyList()
            val extended = if (major == 4) synchsafe(body, 0) else bigEndian(body, 0) + 4
            if (extended < 0 || extended > body.size) return emptyList()
            pos = extended
        }
        val perFrameUnsync = major == 4 && (flags and 0x80) != 0
        val frames = ArrayList<Frame>()
        while (pos + FRAME_HEADER_SIZE <= body.size) {
            if (body[pos] == 0.toByte()) break
            val id = String(body, pos, 4, LATIN1)
            if (!id.all { it in 'A'..'Z' || it in '0'..'9' }) break
            val size = if (major == 4) synchsafe(body, pos + 4) else bigEndian(body, pos + 4)
            val formatFlags = body[pos + 9].toInt() and 0xFF
            pos += FRAME_HEADER_SIZE
            if (size < 0 || pos + size > body.size) break
            var data = body.copyOfRange(pos, pos + size)
            pos += size
            val unusable = if (major == 4) (formatFlags and 0x4F) != 0 else (formatFlags and 0xE0) != 0
            if (unusable || data.isEmpty()) continue
            if (perFrameUnsync) data = undoUnsync(data)
            frames.add(Frame(id, data))
        }
        return frames
    }

    /** Extrait les champs de l'éditeur ; les champs absents restent vides. */
    fun extract(frames: List<Frame>): TagData {
        fun text(id: String): String =
            frames.firstOrNull { it.id == id }?.let { textOf(it.data) }.orEmpty()

        val (trackNumber, trackTotal) = splitPair(text("TRCK"))
        val disc = splitPair(text("TPOS")).first
        val recorded = RecordingDate.parse(text("TDRC"))
        val hasDate = recorded.year.isNotEmpty()
        val dateYear = recorded.year.ifEmpty { Regex("^\\d{4}").find(text("TYER"))?.value.orEmpty() }
        val commentIndex = pickDescribedIndex(frames, "COMM")
        val lyricsIndex = pickDescribedIndex(frames, "USLT")
        return TagData(
            title = text("TIT2"),
            artist = text("TPE1"),
            album = text("TALB"),
            albumArtist = text("TPE2"),
            genre = genreName(text("TCON")),
            year = dateYear,
            recordingMonth = if (hasDate) recorded.month else "",
            recordingDay = if (hasDate) recorded.day else "",
            trackNumber = trackNumber,
            trackTotal = trackTotal,
            discNumber = disc,
            composer = text("TCOM"),
            copyright = text("TCOP"),
            publisher = text("TPUB"),
            encoder = text("TENC"),
            language = text("TLAN"),
            comment = if (commentIndex >= 0) parseDescribed(frames[commentIndex].data)?.text.orEmpty() else "",
            lyrics = if (lyricsIndex >= 0) parseDescribed(frames[lyricsIndex].data)?.text.orEmpty() else ""
        )
    }

    /** Image intégrée : la pochette de face (type 3) si elle existe, sinon la première image. */
    fun extractCover(frames: List<Frame>): ByteArray? {
        var fallback: ByteArray? = null
        for (frame in frames) {
            if (frame.id != "APIC") continue
            val data = frame.data
            if (data.size < 4) continue
            val encoding = data[0].toInt() and 0xFF
            var index = 1
            while (index < data.size && data[index] != 0.toByte()) index++
            index++ // fin du type MIME
            if (index >= data.size) continue
            val pictureType = data[index].toInt() and 0xFF
            index++
            val wide = encoding == 1 || encoding == 2
            if (wide) {
                while (index + 1 < data.size && !(data[index] == 0.toByte() && data[index + 1] == 0.toByte())) index += 2
                index += 2
            } else {
                while (index < data.size && data[index] != 0.toByte()) index++
                index += 1
            }
            if (index >= data.size) continue
            val image = data.copyOfRange(index, data.size)
            if (pictureType == 3) return image
            if (fallback == null) fallback = image
        }
        return fallback
    }

    // ===================== Écriture =====================

    /**
     * Construit le tag ID3v2.4 complet : champs de l'éditeur + cadres conservés du tag d'origine.
     * Si [coverJpeg] est fourni, il remplace toutes les images ; sinon les images existantes restent.
     */
    fun buildTag(existing: List<Frame>, tags: TagData, coverJpeg: ByteArray?): ByteArray {
        val commentIndex = pickDescribedIndex(existing, "COMM")
        val lyricsIndex = pickDescribedIndex(existing, "USLT")
        val oldDate = existing.firstOrNull { it.id == "TDRC" }?.let { textOf(it.data) }.orEmpty()

        val preserved = existing.filterIndexed { index, frame ->
            frame.id !in MANAGED_TEXT_FRAMES &&
                frame.id !in OBSOLETE_FRAMES &&
                !(frame.id == "COMM" && index == commentIndex) &&
                !(frame.id == "USLT" && index == lyricsIndex) &&
                !(coverJpeg != null && frame.id == "APIC")
        }

        val out = ByteArrayOutputStream()
        fun textFrame(id: String, value: String) {
            if (value.isNotBlank()) writeFrame(out, id, byteArrayOf(3) + value.toByteArray(UTF8))
        }

        textFrame("TIT2", tags.title)
        textFrame("TPE1", tags.artist)
        textFrame("TALB", tags.album)
        textFrame("TPE2", tags.albumArtist)
        textFrame("TCON", tags.genre)
        // Date d'enregistrement (ISO 8601 : année, année-mois ou année-mois-jour). L'ancienne valeur, heure comprise,
        // n'est conservée que si la date saisie est strictement la même.
        val newDate = tags.dateText
        val oldPrefix = RecordingDate.isoPrefix(oldDate)
        val date = if (newDate.isNotBlank() && oldPrefix == newDate && oldDate.length > oldPrefix.length) oldDate else newDate
        textFrame("TDRC", date)
        textFrame("TRCK", pair(tags.trackNumber, tags.trackTotal))
        textFrame("TPOS", tags.discNumber)
        textFrame("TCOM", tags.composer)
        textFrame("TCOP", tags.copyright)
        textFrame("TPUB", tags.publisher)
        textFrame("TENC", tags.encoder)
        textFrame("TLAN", tags.language)

        val lang = languageCode(tags.language)
        if (tags.comment.isNotBlank()) writeFrame(out, "COMM", describedFrame(lang, tags.comment))
        if (tags.lyrics.isNotBlank()) writeFrame(out, "USLT", describedFrame(lang, tags.lyrics))
        if (coverJpeg != null) {
            val apic = byteArrayOf(0) + "image/jpeg".toByteArray(LATIN1) + byteArrayOf(0, 3, 0) + coverJpeg
            writeFrame(out, "APIC", apic)
        }
        for (frame in preserved) writeFrame(out, frame.id, frame.data)

        val body = out.toByteArray()
        val header = byteArrayOf(
            'I'.code.toByte(), 'D'.code.toByte(), '3'.code.toByte(), 4, 0, 0
        ) + synchsafeBytes(body.size)
        return header + body
    }

    private fun writeFrame(out: ByteArrayOutputStream, id: String, data: ByteArray) {
        if (data.size > 0x0FFFFFFF) return
        out.write(id.toByteArray(LATIN1))
        out.write(synchsafeBytes(data.size))
        out.write(0)
        out.write(0)
        out.write(data)
    }

    private fun describedFrame(language: String, text: String): ByteArray =
        byteArrayOf(3) + language.toByteArray(LATIN1) + byteArrayOf(0) + text.toByteArray(UTF8)

    /** Code de langue ISO 639-2 sur 3 lettres ; « und » (indéterminée) si la saisie n'en est pas un. */
    private fun languageCode(value: String): String {
        val code = value.trim().lowercase()
        return if (code.length == 3 && code.all { it in 'a'..'z' }) code else "und"
    }

    private fun pair(number: String, total: String): String = when {
        number.isBlank() -> ""
        total.isBlank() -> number
        else -> "$number/$total"
    }

    fun splitPair(value: String): Pair<String, String> {
        val parts = value.split('/')
        return parts[0].trim() to parts.getOrElse(1) { "" }.trim()
    }

    // ===================== Décodage de textes =====================

    private class Described(val descriptor: String, val text: String)

    private fun textOf(data: ByteArray): String {
        if (data.size < 2) return ""
        val encoding = data[0].toInt() and 0xFF
        return cleanValues(decode(encoding, data, 1, data.size - 1))
    }

    private fun decode(encoding: Int, bytes: ByteArray, offset: Int, length: Int): String {
        if (length <= 0 || offset < 0 || offset + length > bytes.size) return ""
        val charset = when (encoding) {
            0 -> LATIN1
            1 -> Charsets.UTF_16
            2 -> Charsets.UTF_16BE
            else -> UTF8
        }
        return String(bytes, offset, length, charset).removePrefix("\uFEFF")
    }

    /** Valeurs multiples séparées par un octet nul : réunies avec « ; ». */
    private fun cleanValues(raw: String): String =
        raw.split('\u0000').map { it.trim() }.filter { it.isNotEmpty() }.joinToString("; ")

    private fun parseDescribed(data: ByteArray): Described? {
        if (data.size < 5) return null
        val encoding = data[0].toInt() and 0xFF
        val start = 4
        val wide = encoding == 1 || encoding == 2
        var end = start
        if (wide) {
            while (end + 1 < data.size && !(data[end] == 0.toByte() && data[end + 1] == 0.toByte())) end += 2
        } else {
            while (end < data.size && data[end] != 0.toByte()) end++
        }
        val descriptor = decode(encoding, data, start, end - start)
        val textStart = end + if (wide) 2 else 1
        val text = if (textStart >= data.size) "" else decode(encoding, data, textStart, data.size - textStart)
        return Described(descriptor.trim(), text.trimEnd('\u0000'))
    }

    /** Cadre COMM / USLT à modifier : celui sans descripteur, sinon le premier qui n'est pas de type « iTun… ». */
    private fun pickDescribedIndex(frames: List<Frame>, id: String): Int {
        var fallback = -1
        for ((index, frame) in frames.withIndex()) {
            if (frame.id != id) continue
            val parsed = parseDescribed(frame.data) ?: continue
            if (parsed.descriptor.isEmpty()) return index
            if (fallback == -1 && !parsed.descriptor.startsWith("iTun", ignoreCase = true)) fallback = index
        }
        return fallback
    }

    /** « (13) », « (13)Pop » ou « 13 » deviennent le nom du genre ID3v1 ; un texte libre reste tel quel. */
    private fun genreName(raw: String): String {
        val value = raw.trim()
        Regex("^\\((\\d{1,3})\\)(.*)$").find(value)?.let { match ->
            val refinement = match.groupValues[2].trim()
            if (refinement.isNotEmpty()) return refinement
            return ID3V1_GENRES.getOrElse(match.groupValues[1].toInt()) { value }
        }
        if (value.isNotEmpty() && value.all { it in '0'..'9' }) {
            return ID3V1_GENRES.getOrElse(value.toInt()) { value }
        }
        return value
    }

    // ===================== Octets =====================

    private fun readFully(input: InputStream, buffer: ByteArray): Int {
        var total = 0
        while (total < buffer.size) {
            val count = input.read(buffer, total, buffer.size - total)
            if (count < 0) break
            total += count
        }
        return total
    }

    private fun synchsafe(bytes: ByteArray, offset: Int): Int =
        ((bytes[offset].toInt() and 0x7F) shl 21) or
            ((bytes[offset + 1].toInt() and 0x7F) shl 14) or
            ((bytes[offset + 2].toInt() and 0x7F) shl 7) or
            (bytes[offset + 3].toInt() and 0x7F)

    private fun bigEndian(bytes: ByteArray, offset: Int): Int =
        ((bytes[offset].toInt() and 0xFF) shl 24) or
            ((bytes[offset + 1].toInt() and 0xFF) shl 16) or
            ((bytes[offset + 2].toInt() and 0xFF) shl 8) or
            (bytes[offset + 3].toInt() and 0xFF)

    private fun synchsafeBytes(value: Int): ByteArray = byteArrayOf(
        ((value shr 21) and 0x7F).toByte(),
        ((value shr 14) and 0x7F).toByte(),
        ((value shr 7) and 0x7F).toByte(),
        (value and 0x7F).toByte()
    )

    /** Retire l'octet 0x00 inséré après chaque 0xFF par la désynchronisation. */
    private fun undoUnsync(data: ByteArray): ByteArray {
        val out = ByteArrayOutputStream(data.size)
        var index = 0
        while (index < data.size) {
            val value = data[index]
            out.write(value.toInt())
            if (value == 0xFF.toByte() && index + 1 < data.size && data[index + 1] == 0.toByte()) index++
            index++
        }
        return out.toByteArray()
    }
}
EOF

echo "  -> app/src/main/java/com/elg/music/data/repository/FilenameTagParser.kt"
mkdir -p app/src/main/java/com/elg/music/data/repository
cat << 'EOF' > app/src/main/java/com/elg/music/data/repository/FilenameTagParser.kt
package com.elg.music.data.repository

/**
 * Déduit titre, artiste et numéro de piste d'un nom de fichier
 * (« 01 - Artiste - Titre.mp3 », « Artiste - Titre.mp3 », « 03. Titre.mp3 »).
 */
object FilenameTagParser {

    data class Result(val title: String?, val artist: String?, val trackNumber: String?) {
        val isEmpty: Boolean
            get() = title == null && artist == null && trackNumber == null
    }

    private val EXTENSION = Regex("\\.[A-Za-z0-9]{2,5}$")
    private val GLUED_MP3 = Regex("[-_]mp3$", RegexOption.IGNORE_CASE)
    private val TRACK_PREFIX = Regex("^(\\d{1,3})\\s*[-._)]\\s*(.+)$")
    private val SEPARATOR = Regex("\\s+[-\u2013\u2014]\\s+")
    private val SPACES = Regex("\\s{2,}")

    fun parse(fileName: String): Result {
        var text = EXTENSION.replace(fileName.trim(), "")
        text = GLUED_MP3.replace(text, "")
        text = SPACES.replace(text.replace('_', ' '), " ").trim()
        if (text.isEmpty()) return Result(null, null, null)

        var track: String? = null
        val prefix = TRACK_PREFIX.find(text)
        if (prefix != null) {
            track = prefix.groupValues[1].trimStart('0').ifEmpty { "0" }
            text = prefix.groupValues[2].trim()
        }

        val parts = text.split(SEPARATOR).map { it.trim() }.filter { it.isNotEmpty() }
        return when {
            parts.size >= 2 ->
                Result(
                    title = parts.drop(1).joinToString(" - "),
                    artist = parts[0],
                    trackNumber = track
                )
            parts.size == 1 -> Result(title = parts[0], artist = null, trackNumber = track)
            else -> Result(null, null, track)
        }
    }
}
EOF

echo "  -> app/src/main/java/com/elg/music/data/repository/TagRepository.kt"
mkdir -p app/src/main/java/com/elg/music/data/repository
cat << 'EOF' > app/src/main/java/com/elg/music/data/repository/TagRepository.kt
package com.elg.music.data.repository

import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaMetadataRetriever
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.ParcelFileDescriptor
import android.provider.MediaStore
import android.util.Size
import com.elg.music.data.local.ElgDatabase
import com.elg.music.data.local.TagEntryEntity
import com.elg.music.data.model.AudioFileInfo
import com.elg.music.data.model.TagData
import com.elg.music.data.model.TechInfo
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.withContext
import java.io.BufferedInputStream
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileNotFoundException
import java.io.FileOutputStream
import java.io.IOException
import kotlin.math.max
import kotlin.math.roundToInt

/** Résultat d'un enregistrement de tags. */
sealed interface SaveOutcome {
    /** [fileRewritten] : vrai si les tags ont été écrits physiquement dans le fichier (MP3). */
    data class Saved(val fileRewritten: Boolean) : SaveOutcome

    /** Le système demande l'autorisation d'écriture (MediaStore.createWriteRequest). */
    data object NeedsPermission : SaveOutcome

    data class Failed(val message: String?) : SaveOutcome
}

/** Tout ce que l'éditeur affiche pour un fichier. */
class TagBundle(
    val tags: TagData,
    val coverBytes: ByteArray?,
    val tech: TechInfo,
    val isMp3: Boolean
)

/** Pochette choisie dans la galerie : JPEG prêt à intégrer + aperçu. */
class PreparedCover(val jpeg: ByteArray, val preview: Bitmap)

/**
 * Éditeur de tags (étape 6, moteur d'écriture physique de la v1.5) : lecture, écriture et persistance des métadonnées.
 *
 *  - Formats gérés (MP3, M4A/AAC/ALAC, FLAC, OGG/Opus, WAV, AIFF, WMA, APE, WavPack, MKV/WebM) : le fichier est
 *    reconstruit dans le cache (tags + pochette) par [AudioTagWriter] / [Id3TagCodec], puis réécrit physiquement via un
 *    descripteur de fichier système (`openFileDescriptor(uri, "rw")`) après autorisation
 *    (`MediaStore.createWriteRequest`). L'original est conservé dans le cache pendant l'écriture et restauré en cas d'échec.
 *  - Formats sans structure d'image interne (MIDI, AMR, AC-3, DTS bruts), ou fichier que l'écrivain ne sait pas modifier
 *    sans risque : repli hybride. Titre, artiste, etc. sont enregistrés dans la base Room et le MediaStore, la pochette dans
 *    `cacheDir/covers/` ([CoverCache]) ; le fichier d'origine n'est jamais touché.
 *  - Dans tous les cas, une ligne Room garde la dernière saisie.
 */
class TagRepository(context: Context) {

    private val appContext = context.applicationContext
    private val resolver = appContext.contentResolver
    private val dao = ElgDatabase.get(appContext).tagDao()
    private val titleCleaner = TitleCleaner(appContext)

    // ===================== Lecture =====================

    @Suppress("DEPRECATION")
    suspend fun loadFileInfo(id: Long): AudioFileInfo? = withContext(Dispatchers.IO) {
        val uri = ContentUris.withAppendedId(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, id)
        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.DISPLAY_NAME,
            MediaStore.Audio.Media.MIME_TYPE,
            MediaStore.Audio.Media.SIZE,
            MediaStore.Audio.Media.RELATIVE_PATH,
            MediaStore.Audio.Media.DATA,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.DURATION
        )
        try {
            resolver.query(uri, projection, null, null, null)?.use { cursor ->
                if (!cursor.moveToFirst()) {
                    null
                } else {
                    AudioFileInfo(
                        id = cursor.getLong(0),
                        uri = uri,
                        displayName = cursor.getString(1).orEmpty(),
                        mimeType = cursor.getString(2),
                        sizeBytes = cursor.getLong(3),
                        relativePath = cursor.getString(4).orEmpty(),
                        dataPath = cursor.getString(5),
                        mediaStoreTitle = cursor.getString(6),
                        durationMs = cursor.getLong(7)
                    )
                }
            }
        } catch (error: Exception) {
            null
        }
    }

    fun isMp3(info: AudioFileInfo): Boolean {
        val mime = info.mimeType
        return mime.equals("audio/mpeg", ignoreCase = true) ||
            mime.equals("audio/mp3", ignoreCase = true) ||
            info.displayName.endsWith(".mp3", ignoreCase = true)
    }

    /** Conteneur déduit de l'extension et du type MIME (la signature binaire confirme au moment de l'écriture). */
    fun containerOf(info: AudioFileInfo): AudioContainer = AudioTagWriter.classify(info.displayName, info.mimeType)

    /** Vrai si ce format peut être réécrit physiquement (sinon : repli Room + cache de pochettes). */
    fun isFileWritable(info: AudioFileInfo): Boolean = containerOf(info) != AudioContainer.UNSUPPORTED

    suspend fun readTags(info: AudioFileInfo): TagBundle = withContext(Dispatchers.IO) {
        val mp3 = isMp3(info)
        var tags = TagData()
        var bitrate: Int? = null
        var sampleRate: Int? = null
        var embeddedPicture: ByteArray? = null

        val retriever = MediaMetadataRetriever()
        try {
            retriever.setDataSource(appContext, info.uri)
            fun meta(key: Int): String = retriever.extractMetadata(key)?.trim().orEmpty()
            val track = Id3TagCodec.splitPair(meta(MediaMetadataRetriever.METADATA_KEY_CD_TRACK_NUMBER))
            tags = TagData(
                title = meta(MediaMetadataRetriever.METADATA_KEY_TITLE),
                artist = meta(MediaMetadataRetriever.METADATA_KEY_ARTIST),
                album = meta(MediaMetadataRetriever.METADATA_KEY_ALBUM),
                albumArtist = meta(MediaMetadataRetriever.METADATA_KEY_ALBUMARTIST),
                genre = meta(MediaMetadataRetriever.METADATA_KEY_GENRE),
                year = Regex("^\\d{4}").find(meta(MediaMetadataRetriever.METADATA_KEY_YEAR))?.value.orEmpty(),
                trackNumber = track.first,
                trackTotal = track.second,
                discNumber = Id3TagCodec.splitPair(meta(MediaMetadataRetriever.METADATA_KEY_DISC_NUMBER)).first,
                composer = meta(MediaMetadataRetriever.METADATA_KEY_COMPOSER)
            )
            bitrate = meta(MediaMetadataRetriever.METADATA_KEY_BITRATE).toIntOrNull()?.div(1000)
            sampleRate = meta(MediaMetadataRetriever.METADATA_KEY_SAMPLERATE).toIntOrNull()
            if (!mp3) embeddedPicture = retriever.embeddedPicture
        } catch (error: Exception) {
            // Métadonnées illisibles : l'éditeur s'ouvre avec des champs vides.
        } finally {
            runCatching { retriever.release() }
        }

        var cover: ByteArray? = null
        if (mp3) {
            try {
                resolver.openInputStream(info.uri)?.use { raw ->
                    val parsed = Id3TagCodec.readTag(BufferedInputStream(raw, BUFFER_BYTES))
                    if (parsed != null) {
                        tags = tags.overlay(Id3TagCodec.extract(parsed.frames))
                        cover = Id3TagCodec.extractCover(parsed.frames)
                    }
                }
            } catch (error: Exception) {
                // Tag illisible : on garde ce que le système a pu lire.
            }
        } else {
            try {
                val entry = dao.get(info.id)
                if (entry != null) {
                    // Fichier réécrit : le fichier fait foi, la base complète les champs que le système ne relit pas
                    // (paroles, copyright…). Repli hybride : la dernière saisie de la base prime.
                    tags = if (entry.fileWritten) entry.toTagData().overlay(tags) else tags.overlay(entry.toTagData())
                }
            } catch (error: Exception) {
                // Base indisponible : valeurs du fichier.
            }
            cover = CoverCache.read(appContext, info.id) ?: embeddedPicture
        }

        if (tags.title.isBlank()) {
            tags = tags.copy(title = titleCleaner.clean(info.mediaStoreTitle ?: info.displayName))
        }

        val extension = info.displayName.substringAfterLast('.', "").uppercase()
        val format = listOfNotNull(
            extension.ifBlank { null },
            info.mimeType?.let { "($it)" }
        ).joinToString(" ").ifBlank { "?" }

        TagBundle(
            tags = tags,
            coverBytes = cover,
            tech = TechInfo(format, bitrate, sampleRate, info.sizeBytes, info.fullPath),
            isMp3 = mp3
        )
    }

    /** Pochette à afficher : image intégrée si présente, sinon vignette du système ; null si aucune. */
    suspend fun loadCoverBitmap(info: AudioFileInfo, embedded: ByteArray?): Bitmap? =
        withContext(Dispatchers.IO) {
            if (embedded != null) {
                val decoded = decodeSampled(embedded)
                if (decoded != null) return@withContext decoded
            }
            try {
                resolver.loadThumbnail(info.uri, Size(PREVIEW_PX, PREVIEW_PX), null)
            } catch (noArtwork: Exception) {
                null
            }
        }

    /** Prépare l'image choisie dans la galerie : réduite à [COVER_MAX_PX] et recompressée en JPEG. */
    suspend fun prepareCover(source: Uri): PreparedCover? = withContext(Dispatchers.IO) {
        try {
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            resolver.openInputStream(source)?.use { BitmapFactory.decodeStream(it, null, bounds) }
            if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return@withContext null
            var sample = 1
            while (bounds.outWidth / sample > COVER_MAX_PX * 2 || bounds.outHeight / sample > COVER_MAX_PX * 2) {
                sample *= 2
            }
            val options = BitmapFactory.Options().apply { inSampleSize = sample }
            val decoded = resolver.openInputStream(source)?.use { BitmapFactory.decodeStream(it, null, options) }
                ?: return@withContext null
            val longest = max(decoded.width, decoded.height)
            val scaled = if (longest > COVER_MAX_PX) {
                val ratio = COVER_MAX_PX.toFloat() / longest
                Bitmap.createScaledBitmap(
                    decoded,
                    (decoded.width * ratio).roundToInt().coerceAtLeast(1),
                    (decoded.height * ratio).roundToInt().coerceAtLeast(1),
                    true
                )
            } else {
                decoded
            }
            val out = ByteArrayOutputStream()
            scaled.compress(Bitmap.CompressFormat.JPEG, 90, out)
            PreparedCover(out.toByteArray(), scaled)
        } catch (error: Exception) {
            null
        }
    }

    private fun decodeSampled(bytes: ByteArray): Bitmap? {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeByteArray(bytes, 0, bytes.size, bounds)
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null
        var sample = 1
        while (bounds.outWidth / sample > PREVIEW_PX * 2 || bounds.outHeight / sample > PREVIEW_PX * 2) sample *= 2
        val options = BitmapFactory.Options().apply { inSampleSize = sample }
        return BitmapFactory.decodeByteArray(bytes, 0, bytes.size, options)
    }

    // ===================== Écriture =====================

    /**
     * Enregistre les tags. Non annulable : le fichier, le MediaStore et la base Room ne doivent jamais
     * rester à moitié à jour. Renvoie [SaveOutcome.NeedsPermission] si le système doit d'abord
     * accorder l'écriture (rien n'a alors été modifié).
     */
    suspend fun save(
        info: AudioFileInfo,
        tags: TagData,
        coverJpeg: ByteArray?,
        allowFileWrite: Boolean
    ): SaveOutcome = withContext(NonCancellable + Dispatchers.IO) {
        var rewritten = false
        try {
            if (allowFileWrite) {
                rewritten = rewriteFile(info, tags, coverJpeg)
                if (rewritten) {
                    runCatching { updateMediaStore(info, tags) }
                    refreshScan(info)
                } else {
                    try {
                        updateMediaStore(info, tags)
                    } catch (denied: SecurityException) {
                        throw denied
                    } catch (other: Exception) {
                        // La base Room prend le relais à l'affichage.
                    }
                }
            }
        } catch (denied: SecurityException) {
            return@withContext SaveOutcome.NeedsPermission
        } catch (error: Exception) {
            return@withContext SaveOutcome.Failed(error.message)
        }

        // Pochette : intégrée au fichier si possible, sinon conservée dans le cache sécurisé d'ELG Music.
        if (coverJpeg != null) {
            runCatching {
                if (rewritten) CoverCache.delete(appContext, info.id) else CoverCache.save(appContext, info.id, coverJpeg)
            }
        }

        try {
            dao.upsert(tags.toEntity(info.id, rewritten))
        } catch (error: Exception) {
            return@withContext SaveOutcome.Failed(error.message)
        }
        markLibraryDirty()
        SaveOutcome.Saved(rewritten)
    }

    /**
     * Réécriture physique du fichier audio. Renvoie false (fichier intact) quand le format n'est pas pris en charge :
     * l'appelant bascule alors sur le repli Room + cache.
     *
     * Le fichier est d'abord copié dans le cache, le nouveau fichier y est construit, puis il est recopié sur
     * l'original par un descripteur système. En cas d'échec en cours de route, l'original est restauré.
     */
    private fun rewriteFile(info: AudioFileInfo, tags: TagData, coverJpeg: ByteArray?): Boolean {
        val declared = containerOf(info)
        if (declared == AudioContainer.UNSUPPORTED) return false

        val stamp = System.nanoTime()
        val original = File(appContext.cacheDir, "tag_src_$stamp.tmp")
        val rebuilt = File(appContext.cacheDir, "tag_new_$stamp.tmp")
        try {
            val needed = info.sizeBytes * 2 + (coverJpeg?.size ?: 0) + MIN_FREE_BYTES
            if (appContext.cacheDir.usableSpace < needed) throw IOException("Espace de stockage insuffisant")

            val input = resolver.openInputStream(info.uri) ?: throw IOException("Fichier illisible")
            input.use { raw -> FileOutputStream(original).use { out -> raw.copyTo(out, BUFFER_BYTES) } }
            if (original.length() <= 0L) throw IOException("Fichier vide")

            val head = ByteArray(16)
            val headLength = original.inputStream().use { it.read(head) }.coerceAtLeast(0)
            val sniffed = AudioTagWriter.sniff(head, headLength)
            if (sniffed == AudioContainer.UNSUPPORTED) return false
            val container = sniffed ?: declared

            if (container == AudioContainer.MP3) {
                buildMp3(original, rebuilt, tags, coverJpeg)
            } else {
                try {
                    AudioTagWriter.write(container, original, rebuilt, tags, coverJpeg)
                } catch (cannot: Exception) {
                    // Structure inhabituelle ou fichier abîmé : on ne risque rien, repli Room + cache.
                    return false
                }
            }
            if (rebuilt.length() <= 0L) throw IOException("Fichier reconstruit vide")
            if (rebuilt.length() < original.length() / 2 && coverJpeg == null) throw IOException("Fichier reconstruit incohérent")

            writeThrough(info.uri, rebuilt, original)
            return true
        } finally {
            original.delete()
            rebuilt.delete()
        }
    }

    /** MP3 : nouveau tag ID3v2.4 (pochette APIC comprise) suivi des données audio d'origine. */
    private fun buildMp3(source: File, target: File, tags: TagData, coverJpeg: ByteArray?) {
        source.inputStream().use { raw ->
            val buffered = BufferedInputStream(raw, BUFFER_BYTES)
            val old = Id3TagCodec.readTag(buffered)
            val newTag = Id3TagCodec.buildTag(old?.frames.orEmpty(), tags, coverJpeg)
            FileOutputStream(target).use { out ->
                out.write(newTag)
                buffered.copyTo(out)
            }
            if (target.length() - newTag.size <= 0L) throw IOException("Aucune donnée audio")
        }
    }

    /**
     * Écrit [newFile] sur le fichier réel par un descripteur de fichier système en lecture/écriture. L'ouverture
     * échoue avant toute troncature si le système n'a pas accordé l'accès ([SecurityException]) : le fichier
     * d'origine reste alors intact. Une erreur pendant la copie déclenche la restauration depuis [backup].
     */
    private fun writeThrough(uri: Uri, newFile: File, backup: File) {
        var attempt = 0
        while (true) {
            try {
                copyOver(uri, newFile)
                return
            } catch (denied: SecurityException) {
                throw denied
            } catch (io: IOException) {
                attempt++
                if (attempt >= 2) {
                    runCatching { copyOver(uri, backup) }
                    throw io
                }
            }
        }
    }

    private fun copyOver(uri: Uri, source: File) {
        val descriptor: ParcelFileDescriptor = try {
            resolver.openFileDescriptor(uri, "rw")
        } catch (notAllowed: FileNotFoundException) {
            throw SecurityException(notAllowed.message)
        } ?: throw IOException("Écriture impossible")
        ParcelFileDescriptor.AutoCloseOutputStream(descriptor).use { out ->
            val channel = out.channel
            channel.truncate(0L)
            channel.position(0L)
            source.inputStream().use { it.copyTo(out, BUFFER_BYTES) }
            out.flush()
            out.fd.sync()
        }
    }

    private fun updateMediaStore(info: AudioFileInfo, tags: TagData) {
        val track = tags.trackNumber.toIntOrNull()
        val disc = tags.discNumber.toIntOrNull() ?: 0
        val values = ContentValues().apply {
            put(MediaStore.Audio.Media.TITLE, tags.title)
            put(MediaStore.Audio.Media.ARTIST, tags.artist.ifBlank { null })
            put(MediaStore.Audio.Media.ALBUM, tags.album.ifBlank { null })
            put(MediaStore.Audio.Media.COMPOSER, tags.composer.ifBlank { null })
            put(MediaStore.Audio.Media.YEAR, tags.year.toIntOrNull())
            put(MediaStore.Audio.Media.TRACK, if (track != null) disc * 1000 + track else null)
        }
        val extended = ContentValues(values).apply {
            put(MediaStore.Audio.Media.ALBUM_ARTIST, tags.albumArtist.ifBlank { null })
            put(MediaStore.Audio.Media.GENRE, tags.genre.ifBlank { null })
        }
        try {
            resolver.update(info.uri, extended, null, null)
        } catch (unknownColumn: IllegalArgumentException) {
            resolver.update(info.uri, values, null, null)
        }
    }

    private fun refreshScan(info: AudioFileInfo) {
        val path = info.dataPath?.takeIf { it.isNotBlank() } ?: return
        runCatching {
            MediaScannerConnection.scanFile(
                appContext,
                arrayOf(path),
                arrayOf(info.mimeType ?: "audio/*"),
                null
            )
        }
    }

    // ===================== Conversions =====================

    private fun TagData.overlay(top: TagData): TagData = TagData(
        title = top.title.ifBlank { title },
        artist = top.artist.ifBlank { artist },
        album = top.album.ifBlank { album },
        albumArtist = top.albumArtist.ifBlank { albumArtist },
        genre = top.genre.ifBlank { genre },
        year = top.year.ifBlank { year },
        trackNumber = top.trackNumber.ifBlank { trackNumber },
        trackTotal = top.trackTotal.ifBlank { trackTotal },
        discNumber = top.discNumber.ifBlank { discNumber },
        composer = top.composer.ifBlank { composer },
        copyright = top.copyright.ifBlank { copyright },
        publisher = top.publisher.ifBlank { publisher },
        encoder = top.encoder.ifBlank { encoder },
        language = top.language.ifBlank { language },
        comment = top.comment.ifBlank { comment },
        lyrics = top.lyrics.ifBlank { lyrics },
        recordingMonth = top.recordingMonth.ifBlank { recordingMonth },
        recordingDay = top.recordingDay.ifBlank { recordingDay }
    )

    private fun TagEntryEntity.toTagData(): TagData = TagData(
        title = title, artist = artist, album = album, albumArtist = albumArtist, genre = genre,
        year = year, trackNumber = trackNumber, trackTotal = trackTotal, discNumber = discNumber,
        composer = composer, copyright = copyright, publisher = publisher, encoder = encoder,
        language = language, comment = comment, lyrics = lyrics,
        recordingMonth = recordingMonth, recordingDay = recordingDay
    )

    private fun TagData.toEntity(mediaId: Long, fileWritten: Boolean): TagEntryEntity = TagEntryEntity(
        mediaId = mediaId, title = title, artist = artist, album = album, albumArtist = albumArtist,
        genre = genre, year = year, trackNumber = trackNumber, trackTotal = trackTotal,
        discNumber = discNumber, composer = composer, copyright = copyright, publisher = publisher,
        encoder = encoder, language = language, comment = comment, lyrics = lyrics,
        recordingMonth = recordingMonth, recordingDay = recordingDay,
        fileWritten = fileWritten, updatedAtMs = System.currentTimeMillis()
    )

    companion object {
        private const val BUFFER_BYTES = 64 * 1024
        private const val MIN_FREE_BYTES = 8L * 1024 * 1024
        private const val COVER_MAX_PX = 800
        private const val PREVIEW_PX = 600

        @Volatile
        private var libraryDirty = false

        /** Signale à l'écran principal que la bibliothèque doit être relue (tags modifiés). */
        fun markLibraryDirty() {
            libraryDirty = true
        }

        /** Lit puis efface le signal « bibliothèque à relire ». */
        fun consumeLibraryDirty(): Boolean {
            val dirty = libraryDirty
            libraryDirty = false
            return dirty
        }
    }
}
EOF

echo "  -> app/src/main/java/com/elg/music/ui/tags/TagEditorActivity.kt"
mkdir -p app/src/main/java/com/elg/music/ui/tags
cat << 'EOF' > app/src/main/java/com/elg/music/ui/tags/TagEditorActivity.kt
package com.elg.music.ui.tags

import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Bundle
import android.provider.MediaStore
import android.text.InputFilter
import android.text.InputType
import android.text.format.Formatter
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import androidx.activity.result.IntentSenderRequest
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.annotation.StringRes
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.core.widget.doOnTextChanged
import androidx.lifecycle.lifecycleScope
import com.elg.music.R
import com.elg.music.data.local.SettingsRepository
import com.elg.music.data.model.AudioFileInfo
import com.elg.music.data.model.TagData
import com.elg.music.data.model.TechInfo
import com.elg.music.data.repository.FilenameTagParser
import com.elg.music.data.repository.SaveOutcome
import com.elg.music.data.repository.TagRepository
import com.elg.music.data.repository.TitleCleaner
import com.elg.music.databinding.ActivityTagEditorBinding
import com.elg.music.databinding.ItemTagFieldBinding
import com.elg.music.databinding.ItemTagMonthBinding
import com.elg.music.playback.PlayerController
import com.elg.music.ui.applySystemBarPadding
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.text.NumberFormat
import java.time.LocalDate
import java.time.YearMonth
import java.util.Locale

private const val TEXT_WORDS = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_FLAG_CAP_WORDS
private const val TEXT_PLAIN = InputType.TYPE_CLASS_TEXT
private const val TEXT_NUMBER = InputType.TYPE_CLASS_NUMBER
private const val TEXT_MULTILINE =
    InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_FLAG_MULTI_LINE or InputType.TYPE_TEXT_FLAG_CAP_SENTENCES

/** Champs du formulaire, dans l'ordre d'affichage. */
private enum class TagField(@StringRes val labelRes: Int, val inputType: Int, val maxLength: Int) {
    TITLE(R.string.tag_field_title, TEXT_WORDS, 200),
    ARTIST(R.string.tag_field_artist, TEXT_WORDS, 200),
    ALBUM(R.string.tag_field_album, TEXT_WORDS, 200),
    ALBUM_ARTIST(R.string.tag_field_album_artist, TEXT_WORDS, 200),
    GENRE(R.string.tag_field_genre, TEXT_WORDS, 100),
    YEAR(R.string.tag_field_year, TEXT_NUMBER, 4),
    RECORD_DAY(R.string.tag_field_record_day, TEXT_NUMBER, 2),
    DISC(R.string.tag_field_disc, TEXT_NUMBER, 4),
    TRACK(R.string.tag_field_track, TEXT_NUMBER, 4),
    TRACK_TOTAL(R.string.tag_field_track_total, TEXT_NUMBER, 4),
    COMPOSER(R.string.tag_field_composer, TEXT_WORDS, 200),
    COPYRIGHT(R.string.tag_field_copyright, TEXT_PLAIN, 200),
    PUBLISHER(R.string.tag_field_publisher, TEXT_WORDS, 200),
    ENCODER(R.string.tag_field_encoder, TEXT_PLAIN, 200),
    LANGUAGE(R.string.tag_field_language, TEXT_PLAIN, 40),
    COMMENT(R.string.tag_field_comment, TEXT_MULTILINE, 4000),
    LYRICS(R.string.tag_field_lyrics, TEXT_MULTILINE, 30000);

    val isNumeric: Boolean
        get() = inputType == TEXT_NUMBER
}

private class FieldRow(val binding: ItemTagFieldBinding) {
    var value: String
        get() = binding.editTagField.text?.toString().orEmpty().trim()
        set(newValue) {
            binding.editTagField.setText(newValue)
        }
}

/**
 * Éditeur de tags « Studio Edition » (étape 6 de la v1.4).
 *
 * À la première ouverture, un avertissement légal doit être accepté (consentement mémorisé dans le DataStore, puis ignoré) ; « Annuler » ferme l'écran. L'édition
 * couvre 16 champs, la pochette (depuis la galerie), un inspecteur technique et le remplissage
 * depuis le nom de fichier. L'enregistrement passe par [TagRepository] : écriture dans le fichier
 * MP3 après `MediaStore.createWriteRequest`, mise à jour du MediaStore et de la base Room, puis
 * mise à jour du lecteur en cours ; l'écran principal relit la bibliothèque à son retour.
 */
class TagEditorActivity : AppCompatActivity() {

    private lateinit var binding: ActivityTagEditorBinding
    private lateinit var repository: TagRepository
    private lateinit var settings: SettingsRepository
    private val playerController: PlayerController by lazy { PlayerController(this) }

    private val rows = LinkedHashMap<TagField, FieldRow>()
    private var monthBinding: ItemTagMonthBinding? = null
    private var selectedMonth = 0
    private var songId = INVALID_ID
    private var fileInfo: AudioFileInfo? = null
    private var fileWritable = false
    private var loaded = false
    private var warningAccepted = false
    private var warningDialog: AlertDialog? = null
    private var saving = false
    private var writeRequested = false
    private var newCoverJpeg: ByteArray? = null
    private var savedForm: Bundle? = null

    private val pickImage = registerForActivityResult(ActivityResultContracts.PickVisualMedia()) { uri ->
        if (uri != null) onImagePicked(uri)
    }

    private val writeRequestLauncher = registerForActivityResult(
        ActivityResultContracts.StartIntentSenderForResult()
    ) { result ->
        onWriteRequestResult(result.resultCode == RESULT_OK)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityTagEditorBinding.inflate(layoutInflater)
        setContentView(binding.root)
        binding.root.applySystemBarPadding()

        setSupportActionBar(binding.toolbar)
        supportActionBar?.setDisplayHomeAsUpEnabled(true)
        binding.toolbar.setNavigationContentDescription(R.string.settings_back_description)

        songId = intent.getLongExtra(EXTRA_SONG_ID, INVALID_ID)
        if (songId == INVALID_ID) {
            finish()
            return
        }
        repository = TagRepository(this)
        settings = SettingsRepository(this)
        warningAccepted = savedInstanceState?.getBoolean(KEY_ACCEPTED, false) ?: false
        savedForm = savedInstanceState?.getBundle(KEY_FORM)
        newCoverJpeg = savedInstanceState?.getByteArray(KEY_COVER)

        buildFields()
        setupActions()
        if (warningAccepted) {
            loadData()
        } else {
            // v1.5 : le consentement est mémorisé dans le DataStore ; une fois donné, la boîte de dialogue
            // n'est plus jamais affichée, quel que soit le morceau édité.
            lifecycleScope.launch {
                if (settings.isTagEditorDisclaimerAccepted()) {
                    warningAccepted = true
                    loadData()
                } else {
                    showWarning()
                }
            }
        }
    }

    override fun onStart() {
        super.onStart()
        playerController.connect()
    }

    override fun onStop() {
        playerController.disconnect()
        super.onStop()
    }

    override fun onDestroy() {
        warningDialog?.dismiss()
        warningDialog = null
        super.onDestroy()
    }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        outState.putBoolean(KEY_ACCEPTED, warningAccepted)
        if (loaded) {
            outState.putBundle(KEY_FORM, Bundle().apply {
                rows.forEach { (field, row) -> putString(field.name, row.value) }
                putInt(KEY_MONTH, selectedMonth)
            })
        }
        newCoverJpeg?.let { outState.putByteArray(KEY_COVER, it) }
    }

    override fun onSupportNavigateUp(): Boolean {
        finish()
        return true
    }

    // ===================== Avertissement légal =====================

    private fun showWarning() {
        warningDialog?.dismiss()
        val dialog = MaterialAlertDialogBuilder(this)
            .setTitle(R.string.tag_warning_title)
            .setMessage(R.string.tag_warning_message)
            .setNegativeButton(R.string.tag_warning_cancel) { dialogInterface, _ -> dialogInterface.cancel() }
            .setPositiveButton(R.string.tag_warning_accept) { _, _ ->
                warningAccepted = true
                lifecycleScope.launch { settings.setTagEditorDisclaimerAccepted(true) }
                loadData()
            }
            .setOnCancelListener { finish() }
            .create()
        dialog.setCanceledOnTouchOutside(false)
        warningDialog = dialog
        dialog.show()
    }

    // ===================== Construction du formulaire =====================

    private fun buildFields() {
        addRow(TagField.TITLE)
        addRow(TagField.ARTIST)
        addRow(TagField.ALBUM)
        addRow(TagField.ALBUM_ARTIST)
        addRow(TagField.GENRE)
        addDateSection()
        addRow(TagField.TRACK, TagField.TRACK_TOTAL)
        addRow(TagField.DISC)
        addRow(TagField.COMPOSER)
        addRow(TagField.COPYRIGHT)
        addRow(TagField.PUBLISHER)
        addRow(TagField.ENCODER)
        addRow(TagField.LANGUAGE)
        addRow(TagField.COMMENT)
        addRow(TagField.LYRICS)
    }

    private fun addRow(vararg fields: TagField) {
        val container = binding.layoutTagFields
        if (fields.size == 1) {
            container.addView(createField(fields[0], container).binding.root)
            return
        }
        val line = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }
        fields.forEachIndexed { index, field ->
            val view = createField(field, line).binding.root
            view.layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f).apply {
                if (index > 0) marginStart = (12 * resources.displayMetrics.density).toInt()
            }
            line.addView(view)
        }
        container.addView(line)
    }

    private fun monthChoices(): List<String> = resources.getStringArray(R.array.tag_month_choices).toList()

    /**
     * Date d'enregistrement (facultative) : jour saisi à la main, mois choisi dans une liste déroulante
     * (janvier à décembre), année saisie à la main (c'est le champ « Année »).
     */
    private fun addDateSection() {
        val container = binding.layoutTagFields
        val density = resources.displayMetrics.density
        val gap = (12 * density).toInt()
        container.addView(TextView(this).apply {
            setText(R.string.tag_section_record_date)
            setTextAppearance(com.google.android.material.R.style.TextAppearance_Material3_LabelLarge)
            setPadding(0, (16 * density).toInt(), 0, 0)
        })

        val line = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }

        val dayView = createField(TagField.RECORD_DAY, line).binding.root
        dayView.layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 0.8f)
        line.addView(dayView)

        val month = ItemTagMonthBinding.inflate(layoutInflater, line, false)
        monthBinding = month
        month.autoTagMonth.isSaveEnabled = false
        month.autoTagMonth.setOnItemClickListener { parent, _, position, _ ->
            val chosen = parent.getItemAtPosition(position)?.toString().orEmpty()
            selectedMonth = monthChoices().indexOf(chosen).coerceAtLeast(0)
            month.inputLayoutTagMonth.error = null
        }
        month.root.layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1.6f).apply {
            marginStart = gap
        }
        line.addView(month.root)

        val yearView = createField(TagField.YEAR, line).binding.root
        yearView.layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f).apply {
            marginStart = gap
        }
        line.addView(yearView)

        container.addView(line)
    }

    /** Sélectionne le mois (0 = aucun, 1 = janvier … 12 = décembre) dans la liste déroulante. */
    private fun setMonth(month: Int) {
        selectedMonth = month.coerceIn(0, 12)
        val label = if (selectedMonth == 0) "" else monthChoices().getOrNull(selectedMonth).orEmpty()
        monthBinding?.autoTagMonth?.setText(label, false)
        monthBinding?.inputLayoutTagMonth?.error = null
    }

    private fun createField(field: TagField, parent: ViewGroup): FieldRow {
        val itemBinding = ItemTagFieldBinding.inflate(layoutInflater, parent, false)
        val row = FieldRow(itemBinding)
        val edit = itemBinding.editTagField
        itemBinding.inputLayoutTagField.hint = getString(field.labelRes)
        edit.inputType = field.inputType
        edit.filters = arrayOf(InputFilter.LengthFilter(field.maxLength))
        // Les champs sont créés en code avec le même identifiant : leur état est géré par onSaveInstanceState.
        edit.isSaveEnabled = false
        if (field == TagField.COMMENT || field == TagField.LYRICS) {
            edit.minLines = if (field == TagField.LYRICS) 6 else 3
            edit.maxLines = 14
            edit.gravity = Gravity.TOP or Gravity.START
        } else {
            edit.maxLines = 1
        }
        edit.doOnTextChanged { _, _, _, _ -> itemBinding.inputLayoutTagField.error = null }
        rows[field] = row
        return row
    }

    private fun setupActions() {
        binding.buttonChangeCover.setOnClickListener {
            pickImage.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly))
        }
        binding.buttonAutoFill.setOnClickListener { autoFillFromFilename() }
        binding.buttonTagSave.setOnClickListener { startSave() }
        binding.buttonTagCancel.setOnClickListener { finish() }
    }

    // ===================== Chargement =====================

    private fun loadData() {
        binding.progressTagLoading.visibility = View.VISIBLE
        lifecycleScope.launch {
            val info = repository.loadFileInfo(songId)
            if (info == null) {
                Toast.makeText(this@TagEditorActivity, R.string.tag_load_error, Toast.LENGTH_LONG).show()
                finish()
                return@launch
            }
            fileInfo = info
            fileWritable = repository.isFileWritable(info)
            val bundle = repository.readTags(info)

            fillForm(bundle.tags)
            savedForm?.let { form ->
                rows.forEach { (field, row) -> form.getString(field.name)?.let { row.value = it } }
                if (form.containsKey(KEY_MONTH)) setMonth(form.getInt(KEY_MONTH))
                savedForm = null
            }
            renderTech(bundle.tech)
            // v1.5 : la pochette se change pour tous les formats (intégrée au fichier, ou conservée dans le cache sécurisé).
            binding.buttonChangeCover.isEnabled = true
            binding.textTagCoverNote.visibility = if (fileWritable) View.GONE else View.VISIBLE
            binding.textTagFormatNote.visibility = if (fileWritable) View.GONE else View.VISIBLE

            val pending = newCoverJpeg
            if (pending != null) {
                BitmapFactory.decodeByteArray(pending, 0, pending.size)?.let { binding.imageTagCover.setImageBitmap(it) }
            } else {
                repository.loadCoverBitmap(info, bundle.coverBytes)?.let { binding.imageTagCover.setImageBitmap(it) }
            }

            loaded = true
            binding.progressTagLoading.visibility = View.GONE
            binding.scrollTagEditor.visibility = View.VISIBLE
            binding.layoutTagActions.visibility = View.VISIBLE
        }
    }

    private fun fillForm(tags: TagData) {
        set(TagField.TITLE, tags.title)
        set(TagField.ARTIST, tags.artist)
        set(TagField.ALBUM, tags.album)
        set(TagField.ALBUM_ARTIST, tags.albumArtist)
        set(TagField.GENRE, tags.genre)
        set(TagField.YEAR, tags.year)
        set(TagField.RECORD_DAY, tags.recordingDay)
        setMonth(tags.recordingMonth.toIntOrNull() ?: 0)
        set(TagField.TRACK, tags.trackNumber)
        set(TagField.TRACK_TOTAL, tags.trackTotal)
        set(TagField.DISC, tags.discNumber)
        set(TagField.COMPOSER, tags.composer)
        set(TagField.COPYRIGHT, tags.copyright)
        set(TagField.PUBLISHER, tags.publisher)
        set(TagField.ENCODER, tags.encoder)
        set(TagField.LANGUAGE, tags.language)
        set(TagField.COMMENT, tags.comment)
        set(TagField.LYRICS, tags.lyrics)
    }

    private fun set(field: TagField, value: String) {
        rows[field]?.value = value
    }

    private fun value(field: TagField): String = rows[field]?.value.orEmpty()

    private fun renderTech(tech: TechInfo) {
        val unknown = getString(R.string.tag_tech_unknown)
        binding.textTechFormat.text = getString(R.string.tag_tech_format, tech.format)
        binding.textTechBitrate.text =
            getString(R.string.tag_tech_bitrate, tech.bitrateKbps?.let { "$it kbps" } ?: unknown)
        binding.textTechSampleRate.text = getString(
            R.string.tag_tech_sample_rate,
            tech.sampleRateHz?.let { String.format(Locale.getDefault(), "%.1f kHz", it / 1000.0) } ?: unknown
        )
        binding.textTechSize.text = getString(
            R.string.tag_tech_size,
            Formatter.formatFileSize(this, tech.sizeBytes),
            NumberFormat.getIntegerInstance().format(tech.sizeBytes)
        )
        binding.textTechPath.text = getString(R.string.tag_tech_path, tech.path)
    }

    // ===================== Actions =====================

    private fun autoFillFromFilename() {
        val info = fileInfo ?: return
        val parsed = FilenameTagParser.parse(info.displayName)
        if (parsed.isEmpty) {
            Toast.makeText(this, R.string.tag_autofill_nothing, Toast.LENGTH_SHORT).show()
            return
        }
        parsed.title?.let { set(TagField.TITLE, it) }
        parsed.artist?.let { set(TagField.ARTIST, it) }
        parsed.trackNumber?.let { set(TagField.TRACK, it) }
        Toast.makeText(this, R.string.tag_autofill_done, Toast.LENGTH_SHORT).show()
    }

    private fun onImagePicked(uri: Uri) {
        lifecycleScope.launch {
            val prepared = repository.prepareCover(uri)
            if (prepared == null) {
                Toast.makeText(this@TagEditorActivity, R.string.tag_cover_error, Toast.LENGTH_LONG).show()
                return@launch
            }
            newCoverJpeg = prepared.jpeg
            binding.imageTagCover.setImageBitmap(prepared.preview)
            Toast.makeText(this@TagEditorActivity, R.string.tag_cover_updated, Toast.LENGTH_SHORT).show()
        }
    }

    /** Valide le formulaire ; renvoie null (en signalant l'erreur sous le champ) si une saisie est invalide. */
    private fun collectTags(): TagData? {
        var firstInvalid: TagField? = null
        fun invalid(field: TagField, messageRes: Int) {
            rows[field]?.binding?.inputLayoutTagField?.error = getString(messageRes)
            if (firstInvalid == null) firstInvalid = field
        }
        if (value(TagField.TITLE).isEmpty()) invalid(TagField.TITLE, R.string.tag_error_title_empty)
        for (field in TagField.entries) {
            if (!field.isNumeric) continue
            val text = value(field)
            if (text.isNotEmpty() && (text.length > 4 || !text.all { it in '0'..'9' })) {
                invalid(field, R.string.tag_error_number)
            }
        }
        // Date d'enregistrement (facultative) : jour + mois + année cohérents, et pas dans le futur.
        var monthInvalid = false
        val dayText = value(TagField.RECORD_DAY)
        val yearText = value(TagField.YEAR)
        if (dayText.isNotEmpty() || selectedMonth != 0) {
            val yearValue = yearText.takeIf { it.length == 4 && it.all { c -> c in '0'..'9' } }?.toInt()
            val dayValue = dayText.toIntOrNull()
            if (yearValue == null) {
                invalid(TagField.YEAR, R.string.tag_error_date_year_required)
            } else if (dayText.isNotEmpty() && selectedMonth == 0) {
                monthInvalid = true
                monthBinding?.inputLayoutTagMonth?.error = getString(R.string.tag_error_date_month_required)
            } else {
                val lastDay = YearMonth.of(yearValue, selectedMonth.coerceAtLeast(1)).lengthOfMonth()
                if (dayText.isNotEmpty() && (dayValue == null || dayValue !in 1..lastDay)) {
                    invalid(TagField.RECORD_DAY, R.string.tag_error_date_day_invalid)
                } else {
                    val candidate = LocalDate.of(yearValue, selectedMonth.coerceAtLeast(1), dayValue ?: 1)
                    if (candidate.isAfter(LocalDate.now())) {
                        if (dayText.isNotEmpty()) {
                            invalid(TagField.RECORD_DAY, R.string.tag_error_date_future)
                        } else {
                            monthInvalid = true
                            monthBinding?.inputLayoutTagMonth?.error = getString(R.string.tag_error_date_future)
                        }
                    }
                }
            }
        }
        firstInvalid?.let { field ->
            rows[field]?.binding?.editTagField?.requestFocus()
            return null
        }
        if (monthInvalid) {
            monthBinding?.autoTagMonth?.requestFocus()
            return null
        }
        return TagData(
            title = value(TagField.TITLE),
            artist = value(TagField.ARTIST),
            album = value(TagField.ALBUM),
            albumArtist = value(TagField.ALBUM_ARTIST),
            genre = value(TagField.GENRE),
            year = value(TagField.YEAR),
            trackNumber = value(TagField.TRACK),
            trackTotal = value(TagField.TRACK_TOTAL),
            discNumber = value(TagField.DISC),
            composer = value(TagField.COMPOSER),
            copyright = value(TagField.COPYRIGHT),
            publisher = value(TagField.PUBLISHER),
            encoder = value(TagField.ENCODER),
            language = value(TagField.LANGUAGE),
            comment = value(TagField.COMMENT),
            lyrics = value(TagField.LYRICS),
            recordingMonth = if (selectedMonth in 1..12) selectedMonth.toString() else "",
            recordingDay = dayText.toIntOrNull()?.toString().orEmpty()
        )
    }

    // ===================== Enregistrement =====================

    private fun startSave() {
        if (saving || !loaded) return
        if (collectTags() == null) return
        saving = true
        writeRequested = false
        setBusy(true)
        // Le fichier MP3 va être réécrit : la lecture de ce morceau est suspendue le temps de l'opération.
        val info = fileInfo
        if (fileWritable && info != null) playerController.pauseForFileEdit(info.id.toString())
        runSave(allowFileWrite = true)
    }

    private fun runSave(allowFileWrite: Boolean) {
        val info = fileInfo ?: return
        val tags = collectTags() ?: run {
            endSaving()
            return
        }
        lifecycleScope.launch {
            val outcome = repository.save(info, tags, newCoverJpeg, allowFileWrite)
            when (outcome) {
                is SaveOutcome.Saved -> finishSaved(info, tags, outcome.fileRewritten)
                SaveOutcome.NeedsPermission -> requestWriteAccess(info)
                is SaveOutcome.Failed -> {
                    endSaving()
                    playerController.cancelFileEdit()
                    Toast.makeText(
                        this@TagEditorActivity,
                        getString(R.string.tag_save_error, outcome.message ?: getString(R.string.tag_tech_unknown)),
                        Toast.LENGTH_LONG
                    ).show()
                }
            }
        }
    }

    /** Demande au système l'autorisation d'écrire dans ce fichier (MediaStore.createWriteRequest). */
    private fun requestWriteAccess(info: AudioFileInfo) {
        if (writeRequested) {
            onWriteAccessUnavailable(R.string.tag_write_refused)
            return
        }
        writeRequested = true
        try {
            val sender = MediaStore.createWriteRequest(contentResolver, listOf(info.uri)).intentSender
            writeRequestLauncher.launch(IntentSenderRequest.Builder(sender).build())
        } catch (error: Exception) {
            onWriteAccessUnavailable(R.string.tag_write_refused)
        }
    }

    private fun onWriteRequestResult(granted: Boolean) {
        if (!saving) return
        if (granted) {
            runSave(allowFileWrite = true)
        } else {
            onWriteAccessUnavailable(R.string.tag_write_denied)
        }
    }

    /** Autorisation absente : un MP3 n'est pas modifié ; les autres formats sont enregistrés dans la base seulement. */
    private fun onWriteAccessUnavailable(messageRes: Int) {
        if (fileWritable) {
            endSaving()
            playerController.cancelFileEdit()
            Toast.makeText(this, messageRes, Toast.LENGTH_LONG).show()
        } else {
            runSave(allowFileWrite = false)
        }
    }

    private fun finishSaved(info: AudioFileInfo, tags: TagData, fileRewritten: Boolean) {
        val displayTitle = TitleCleaner(this).clean(tags.title)
        playerController.applyEditedMetadata(
            mediaId = info.id.toString(),
            title = displayTitle,
            artist = tags.artist.ifBlank { null },
            album = tags.album.ifBlank { null },
            reloadSource = fileRewritten
        )
        Toast.makeText(
            this,
            if (fileRewritten) R.string.tag_saved_file else R.string.tag_saved_library,
            Toast.LENGTH_LONG
        ).show()
        lifecycleScope.launch {
            delay(300L)
            finish()
        }
    }

    private fun endSaving() {
        saving = false
        setBusy(false)
    }

    private fun setBusy(busy: Boolean) {
        binding.buttonTagSave.isEnabled = !busy
        binding.buttonTagCancel.isEnabled = !busy
        binding.buttonAutoFill.isEnabled = !busy
        binding.buttonChangeCover.isEnabled = !busy
        binding.progressTagLoading.visibility = if (busy) View.VISIBLE else View.GONE
    }

    companion object {
        private const val EXTRA_SONG_ID = "elg.tag_editor.song_id"
        private const val INVALID_ID = -1L
        private const val KEY_ACCEPTED = "tag_warning_accepted"
        private const val KEY_FORM = "tag_form"
        private const val KEY_COVER = "tag_new_cover"
        private const val KEY_MONTH = "tag_record_month"

        fun newIntent(context: Context, songId: Long): Intent =
            Intent(context, TagEditorActivity::class.java).putExtra(EXTRA_SONG_ID, songId)
    }
}
EOF

echo "  -> app/src/main/res/layout/activity_tag_editor.xml"
mkdir -p app/src/main/res/layout
cat << 'EOF' > app/src/main/res/layout/activity_tag_editor.xml
<?xml version="1.0" encoding="utf-8"?>
<androidx.constraintlayout.widget.ConstraintLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="match_parent">

    <com.google.android.material.appbar.MaterialToolbar
        android:id="@+id/toolbar"
        android:layout_width="0dp"
        android:layout_height="?attr/actionBarSize"
        android:background="?attr/colorSurface"
        app:title="@string/tag_editor_title"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toTopOf="parent" />

    <ProgressBar
        android:id="@+id/progressTagLoading"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:visibility="gone"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toBottomOf="@id/toolbar" />

    <androidx.core.widget.NestedScrollView
        android:id="@+id/scrollTagEditor"
        android:layout_width="0dp"
        android:layout_height="0dp"
        android:clipToPadding="false"
        android:visibility="gone"
        app:layout_constraintBottom_toTopOf="@id/layoutTagActions"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toBottomOf="@id/toolbar">

        <LinearLayout
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:orientation="vertical"
            android:paddingStart="16dp"
            android:paddingTop="8dp"
            android:paddingEnd="16dp"
            android:paddingBottom="24dp">

            <ImageView
                android:layout_width="match_parent"
                android:layout_height="3dp"
                android:importantForAccessibility="no"
                android:scaleType="fitXY"
                android:src="@drawable/ic_flag_rca_strip" />

            <!-- ===== EN-TÊTE : POCHETTE ===== -->
            <LinearLayout
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:layout_marginTop="16dp"
                android:gravity="center_vertical"
                android:orientation="horizontal">

                <com.google.android.material.imageview.ShapeableImageView
                    android:id="@+id/imageTagCover"
                    android:layout_width="120dp"
                    android:layout_height="120dp"
                    android:contentDescription="@string/tag_cover_description"
                    android:scaleType="centerCrop"
                    android:src="@drawable/ic_artwork_default"
                    app:shapeAppearanceOverlay="@style/ShapeAppearance.Elg.RoundedLarge" />

                <LinearLayout
                    android:layout_width="0dp"
                    android:layout_height="wrap_content"
                    android:layout_marginStart="16dp"
                    android:layout_weight="1"
                    android:orientation="vertical">

                    <Button
                        android:id="@+id/buttonChangeCover"
                        style="@style/Widget.Material3.Button.OutlinedButton"
                        android:layout_width="wrap_content"
                        android:layout_height="wrap_content"
                        android:minHeight="48dp"
                        android:text="@string/tag_cover_change" />

                    <TextView
                        android:id="@+id/textTagCoverNote"
                        android:layout_width="match_parent"
                        android:layout_height="wrap_content"
                        android:layout_marginTop="4dp"
                        android:text="@string/tag_cover_mp3_only"
                        android:textAppearance="?attr/textAppearanceBodySmall"
                        android:textColor="?attr/colorOnSurfaceVariant"
                        android:visibility="gone" />

                </LinearLayout>

            </LinearLayout>

            <Button
                android:id="@+id/buttonAutoFill"
                style="@style/Widget.Material3.Button.TonalButton"
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:layout_marginTop="12dp"
                android:minHeight="48dp"
                android:text="@string/tag_autofill_button" />

            <TextView
                android:id="@+id/textTagFormatNote"
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:layout_marginTop="8dp"
                android:text="@string/tag_non_mp3_note"
                android:textAppearance="?attr/textAppearanceBodyMedium"
                android:textColor="?attr/colorOnSurfaceVariant"
                android:visibility="gone" />

            <!-- ===== FORMULAIRE ===== -->
            <TextView
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:layout_marginTop="20dp"
                android:accessibilityHeading="true"
                android:text="@string/tag_section_info"
                android:textAppearance="?attr/textAppearanceTitleMedium"
                android:textColor="?attr/colorPrimary" />

            <LinearLayout
                android:id="@+id/layoutTagFields"
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:orientation="vertical" />

            <com.google.android.material.divider.MaterialDivider
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:layout_marginTop="24dp"
                android:layout_marginBottom="16dp" />

            <!-- ===== INSPECTEUR TECHNIQUE ===== -->
            <TextView
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:accessibilityHeading="true"
                android:text="@string/tag_section_tech"
                android:textAppearance="?attr/textAppearanceTitleMedium"
                android:textColor="?attr/colorPrimary" />

            <TextView
                android:id="@+id/textTechFormat"
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:layout_marginTop="8dp"
                android:textAppearance="?attr/textAppearanceBodyLarge" />

            <TextView
                android:id="@+id/textTechBitrate"
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:layout_marginTop="4dp"
                android:textAppearance="?attr/textAppearanceBodyLarge" />

            <TextView
                android:id="@+id/textTechSampleRate"
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:layout_marginTop="4dp"
                android:textAppearance="?attr/textAppearanceBodyLarge" />

            <TextView
                android:id="@+id/textTechSize"
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:layout_marginTop="4dp"
                android:textAppearance="?attr/textAppearanceBodyLarge" />

            <TextView
                android:id="@+id/textTechPath"
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:layout_marginTop="4dp"
                android:textAppearance="?attr/textAppearanceBodyLarge"
                android:textIsSelectable="true" />

        </LinearLayout>

    </androidx.core.widget.NestedScrollView>

    <LinearLayout
        android:id="@+id/layoutTagActions"
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:background="?attr/colorSurfaceContainerHigh"
        android:gravity="center_vertical|end"
        android:orientation="horizontal"
        android:padding="8dp"
        android:visibility="gone"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent">

        <Button
            android:id="@+id/buttonTagCancel"
            style="@style/Widget.Material3.Button.TextButton"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:minHeight="48dp"
            android:text="@string/tag_cancel" />

        <Button
            android:id="@+id/buttonTagSave"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:layout_marginStart="8dp"
            android:minHeight="48dp"
            android:text="@string/tag_save" />

    </LinearLayout>

</androidx.constraintlayout.widget.ConstraintLayout>
EOF

echo "  -> app/src/main/res/layout/item_tag_field.xml"
mkdir -p app/src/main/res/layout
cat << 'EOF' > app/src/main/res/layout/item_tag_field.xml
<?xml version="1.0" encoding="utf-8"?>
<!-- Champ de formulaire de l'éditeur de tags, instancié par TagEditorActivity pour chaque métadonnée. -->
<com.google.android.material.textfield.TextInputLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:id="@+id/inputLayoutTagField"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:layout_marginTop="8dp">

    <com.google.android.material.textfield.TextInputEditText
        android:id="@+id/editTagField"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:importantForAutofill="no" />

</com.google.android.material.textfield.TextInputLayout>
EOF

echo "  -> app/src/main/res/layout/item_tag_month.xml"
mkdir -p app/src/main/res/layout
cat << 'EOF' > app/src/main/res/layout/item_tag_month.xml
<?xml version="1.0" encoding="utf-8"?>
<!-- Liste déroulante du mois de la date d'enregistrement (éditeur de tags, V1.06). -->
<com.google.android.material.textfield.TextInputLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:id="@+id/inputLayoutTagMonth"
    style="@style/Widget.Material3.TextInputLayout.OutlinedBox.ExposedDropdownMenu"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:layout_marginTop="8dp"
    android:hint="@string/tag_field_record_month">

    <com.google.android.material.textfield.MaterialAutoCompleteTextView
        android:id="@+id/autoTagMonth"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:inputType="none"
        app:simpleItems="@array/tag_month_choices" />

</com.google.android.material.textfield.TextInputLayout>
EOF

echo "  -> app/src/main/java/com/elg/music/data/local/PlaybackStateStore.kt"
mkdir -p app/src/main/java/com/elg/music/data/local
cat << 'EOF' > app/src/main/java/com/elg/music/data/local/PlaybackStateStore.kt
package com.elg.music.data.local

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.emptyPreferences
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.longPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.first
import java.io.IOException

/** DataStore dédié à la reprise de lecture : une seule instance par fichier. */
private val Context.elgPlaybackDataStore: DataStore<Preferences> by preferencesDataStore(name = "elg_playback_state")

/** Dernier état de lecture connu : file d'attente (identifiants MediaStore), morceau en cours et position. */
data class SavedPlayback(
    val lastSongId: Long,
    val lastPositionMs: Long,
    val queueIds: List<Long>,
    val queueIndex: Int
)

/**
 * Mini-lecteur persistant (v1.5) : sauvegarde `last_song_id`, `last_position` et `queue_ids` dans Jetpack DataStore.
 * Au démarrage, le service recharge la file d'attente en pause : le mini-lecteur reste visible et réactif, même
 * après la fermeture de l'application ou le redémarrage du téléphone.
 */
class PlaybackStateStore(context: Context) {

    private val store = context.applicationContext.elgPlaybackDataStore

    suspend fun save(state: SavedPlayback) {
        if (state.queueIds.isEmpty()) return
        store.edit { prefs ->
            prefs[KEY_LAST_SONG_ID] = state.lastSongId
            prefs[KEY_LAST_POSITION] = state.lastPositionMs.coerceAtLeast(0L)
            prefs[KEY_QUEUE_IDS] = state.queueIds.take(MAX_QUEUE).joinToString(",")
            prefs[KEY_QUEUE_INDEX] = state.queueIndex.coerceAtLeast(0)
        }
    }

    suspend fun load(): SavedPlayback? {
        val prefs = store.data
            .catch { error -> if (error is IOException) emit(emptyPreferences()) else throw error }
            .first()
        val ids = prefs[KEY_QUEUE_IDS]?.split(',')?.mapNotNull { it.trim().toLongOrNull() }.orEmpty()
        if (ids.isEmpty()) return null
        val songId = prefs[KEY_LAST_SONG_ID] ?: ids.first()
        val savedIndex = prefs[KEY_QUEUE_INDEX] ?: 0
        val index = if (savedIndex in ids.indices && ids[savedIndex] == songId) savedIndex else ids.indexOf(songId).coerceAtLeast(0)
        return SavedPlayback(songId, prefs[KEY_LAST_POSITION] ?: 0L, ids, index)
    }

    suspend fun clear() {
        store.edit { it.clear() }
    }

    private companion object {
        const val MAX_QUEUE = 5000
        val KEY_LAST_SONG_ID = longPreferencesKey("last_song_id")
        val KEY_LAST_POSITION = longPreferencesKey("last_position")
        val KEY_QUEUE_IDS = stringPreferencesKey("queue_ids")
        val KEY_QUEUE_INDEX = intPreferencesKey("queue_index")
    }
}
EOF

echo "  -> app/src/main/java/com/elg/music/playback/MediaItemFactory.kt"
mkdir -p app/src/main/java/com/elg/music/playback
cat << 'EOF' > app/src/main/java/com/elg/music/playback/MediaItemFactory.kt
package com.elg.music.playback

import android.os.Bundle
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import com.elg.music.data.model.Song

/** Construit les [MediaItem] du lecteur à partir d'un [Song] (même format que l'écran principal). */
object MediaItemFactory {

    fun fromSong(song: Song): MediaItem {
        val metadata = MediaMetadata.Builder()
            .setTitle(song.title)
            .setArtist(song.artist)
            .setAlbumTitle(song.album)
            // L'Uri du fichier sert de clé à ArtworkBitmapLoader (pochette intégrée, sinon pochette par défaut).
            .setArtworkUri(song.contentUri)
            .setDurationMs(song.durationMs)
        if (song.isMidi) {
            metadata.setExtras(Bundle().apply { putString(MidiSupport.EXTRA_MIDI_URI, song.contentUri.toString()) })
        }
        return MediaItem.Builder()
            .setMediaId(song.id.toString())
            .setUri(song.contentUri)
            .setMediaMetadata(metadata.build())
            .build()
    }
}
EOF

echo "  -> app/src/main/java/com/elg/music/data/repository/AudioTagWriter.kt"
mkdir -p app/src/main/java/com/elg/music/data/repository
cat << 'EOF' > app/src/main/java/com/elg/music/data/repository/AudioTagWriter.kt
package com.elg.music.data.repository

import android.graphics.BitmapFactory
import android.util.Base64
import com.elg.music.data.model.TagData
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.IOException
import java.io.OutputStream
import java.io.RandomAccessFile
import java.util.Locale

/** Familles de conteneurs audio dont ELG Music sait réécrire les métadonnées et la pochette. */
enum class AudioContainer { MP3, MP4, FLAC, OGG, WAV, AIFF, ASF, APE, WAVPACK, MATROSKA, UNSUPPORTED }

/** Le fichier a une structure que l'écrivain ne sait pas modifier sans risque : repli sur Room + cache. */
class UnsupportedContainerException(message: String) : IOException(message)

/**
 * Point d'entrée du marquage multi-formats (v1.5).
 *
 * Chaque écrivain lit le fichier d'origine ([source]) et produit un fichier complet ([target]) ; la
 * recopie sur le fichier réel, via un descripteur système, est faite par [TagRepository]. Le fichier
 * d'origine n'est donc jamais touché tant que le nouveau fichier n'est pas entièrement construit.
 *
 * Un champ vide signifie « champ supprimé » ; une pochette `null` signifie « pochette inchangée ».
 */
object AudioTagWriter {

    /** Classement par extension et type MIME (sert à l'interface ; l'écriture confirme par la signature binaire). */
    fun classify(displayName: String, mime: String?): AudioContainer {
        val ext = displayName.substringAfterLast('.', "").lowercase(Locale.ROOT)
        val type = mime?.lowercase(Locale.ROOT).orEmpty()
        return when {
            ext in setOf("mp3", "mp2", "aac", "adts") -> AudioContainer.MP3
            ext in setOf("m4a", "m4b", "m4r", "mp4", "alac") -> AudioContainer.MP4
            ext == "flac" -> AudioContainer.FLAC
            ext in setOf("ogg", "oga", "opus") -> AudioContainer.OGG
            ext in setOf("wav", "wave") -> AudioContainer.WAV
            ext in setOf("aif", "aiff", "aifc") -> AudioContainer.AIFF
            ext in setOf("wma", "asf") -> AudioContainer.ASF
            ext == "ape" -> AudioContainer.APE
            ext == "wv" -> AudioContainer.WAVPACK
            ext in setOf("mkv", "mka", "webm") -> AudioContainer.MATROSKA
            ext in setOf("mid", "midi", "amr", "awb", "ac3", "dts", "3gp", "3ga") -> AudioContainer.UNSUPPORTED
            type == "audio/mpeg" || type == "audio/mp3" || type == "audio/aac" -> AudioContainer.MP3
            type == "audio/flac" || type == "audio/x-flac" -> AudioContainer.FLAC
            type == "audio/ogg" || type == "application/ogg" || type == "audio/opus" -> AudioContainer.OGG
            type == "audio/x-wav" || type == "audio/wav" || type == "audio/vnd.wave" -> AudioContainer.WAV
            type == "audio/aiff" || type == "audio/x-aiff" -> AudioContainer.AIFF
            type == "audio/mp4" || type == "audio/x-m4a" || type == "audio/m4a" -> AudioContainer.MP4
            type == "audio/x-ms-wma" || type == "video/x-ms-asf" -> AudioContainer.ASF
            type == "audio/x-matroska" || type == "video/x-matroska" || type == "audio/webm" -> AudioContainer.MATROSKA
            type == "audio/x-ape" || type == "audio/ape" -> AudioContainer.APE
            else -> AudioContainer.UNSUPPORTED
        }
    }

    /**
     * Reconnaît le conteneur d'après les premiers octets du fichier. Renvoie null si la signature
     * n'est pas concluante (l'appelant se rabat alors sur [classify]).
     */
    fun sniff(head: ByteArray, length: Int): AudioContainer? {
        fun starts(text: String, offset: Int = 0): Boolean {
            if (length < offset + text.length) return false
            for (i in text.indices) if (head[offset + i] != text[i].code.toByte()) return false
            return true
        }
        return when {
            starts("fLaC") -> AudioContainer.FLAC
            starts("OggS") -> AudioContainer.OGG
            starts("RIFF") && starts("WAVE", 8) -> AudioContainer.WAV
            starts("FORM") && (starts("AIFF", 8) || starts("AIFC", 8)) -> AudioContainer.AIFF
            starts("MAC ") -> AudioContainer.APE
            starts("wvpk") -> AudioContainer.WAVPACK
            starts("ftyp", 4) -> AudioContainer.MP4
            length >= 4 && head[0] == 0x1A.toByte() && head[1] == 0x45.toByte() &&
                head[2] == 0xDF.toByte() && head[3] == 0xA3.toByte() -> AudioContainer.MATROSKA
            length >= 4 && head[0] == 0x30.toByte() && head[1] == 0x26.toByte() &&
                head[2] == 0xB2.toByte() && head[3] == 0x75.toByte() -> AudioContainer.ASF
            starts("MThd") || starts("#!AMR") -> AudioContainer.UNSUPPORTED
            length >= 2 && head[0] == 0x0B.toByte() && head[1] == 0x77.toByte() -> AudioContainer.UNSUPPORTED
            length >= 4 && head[0] == 0x7F.toByte() && head[1] == 0xFE.toByte() &&
                head[2] == 0x80.toByte() && head[3] == 0x01.toByte() -> AudioContainer.UNSUPPORTED
            starts("ID3") -> AudioContainer.MP3
            length >= 2 && head[0] == 0xFF.toByte() && (head[1].toInt() and 0xE0) == 0xE0 -> AudioContainer.MP3
            else -> null
        }
    }

    /** Écrit dans [target] une copie de [source] portant les nouveaux tags (tous formats sauf MP3, traité par [Id3TagCodec]). */
    fun write(container: AudioContainer, source: File, target: File, tags: TagData, coverJpeg: ByteArray?) {
        when (container) {
            AudioContainer.FLAC -> FlacTagWriter.write(source, target, tags, coverJpeg)
            AudioContainer.OGG -> OggTagWriter.write(source, target, tags, coverJpeg)
            AudioContainer.MP4 -> Mp4TagWriter.write(source, target, tags, coverJpeg)
            AudioContainer.WAV -> RiffTagWriter.write(source, target, tags, coverJpeg, bigEndian = false)
            AudioContainer.AIFF -> RiffTagWriter.write(source, target, tags, coverJpeg, bigEndian = true)
            AudioContainer.APE, AudioContainer.WAVPACK -> Apev2TagWriter.write(source, target, tags, coverJpeg)
            AudioContainer.ASF -> AsfTagWriter.write(source, target, tags, coverJpeg)
            AudioContainer.MATROSKA -> MatroskaTagWriter.write(source, target, tags, coverJpeg)
            AudioContainer.MP3, AudioContainer.UNSUPPORTED ->
                throw UnsupportedContainerException("Conteneur non géré par l'écrivain multi-formats")
        }
    }
}

/** Petits utilitaires binaires partagés par les écrivains. */
internal object Bin {
    fun le16(v: Int): ByteArray = byteArrayOf(v.toByte(), (v shr 8).toByte())
    fun le32(v: Long): ByteArray = byteArrayOf(v.toByte(), (v shr 8).toByte(), (v shr 16).toByte(), (v shr 24).toByte())
    fun le64(v: Long): ByteArray = ByteArray(8) { (v shr (8 * it)).toByte() }
    fun be16(v: Int): ByteArray = byteArrayOf((v shr 8).toByte(), v.toByte())
    fun be32(v: Long): ByteArray = byteArrayOf((v shr 24).toByte(), (v shr 16).toByte(), (v shr 8).toByte(), v.toByte())

    fun readLe32(b: ByteArray, o: Int): Long =
        (b[o].toLong() and 0xFF) or ((b[o + 1].toLong() and 0xFF) shl 8) or
            ((b[o + 2].toLong() and 0xFF) shl 16) or ((b[o + 3].toLong() and 0xFF) shl 24)

    fun readLe16(b: ByteArray, o: Int): Int = (b[o].toInt() and 0xFF) or ((b[o + 1].toInt() and 0xFF) shl 8)

    fun readLe64(b: ByteArray, o: Int): Long = readLe32(b, o) or (readLe32(b, o + 4) shl 32)

    fun readBe32(b: ByteArray, o: Int): Long =
        ((b[o].toLong() and 0xFF) shl 24) or ((b[o + 1].toLong() and 0xFF) shl 16) or
            ((b[o + 2].toLong() and 0xFF) shl 8) or (b[o + 3].toLong() and 0xFF)

    fun readBe64(b: ByteArray, o: Int): Long = (readBe32(b, o) shl 32) or readBe32(b, o + 4)

    fun readBytes(raf: RandomAccessFile, offset: Long, length: Int): ByteArray {
        val data = ByteArray(length)
        raf.seek(offset)
        raf.readFully(data)
        return data
    }

    /** Recopie [start, end) du fichier dans [out]. */
    fun copyRange(raf: RandomAccessFile, start: Long, end: Long, out: OutputStream) {
        val buffer = ByteArray(64 * 1024)
        raf.seek(start)
        var remaining = end - start
        while (remaining > 0) {
            val read = raf.read(buffer, 0, minOf(buffer.size.toLong(), remaining).toInt())
            if (read < 0) throw IOException("Fin de fichier inattendue")
            out.write(buffer, 0, read)
            remaining -= read
        }
    }

    fun concat(vararg parts: ByteArray): ByteArray {
        val out = ByteArrayOutputStream()
        parts.forEach { out.write(it) }
        return out.toByteArray()
    }

    fun ascii(text: String): ByteArray = text.toByteArray(Charsets.US_ASCII)
}

/** Commentaires Vorbis (FLAC et Ogg Vorbis / Opus) : lecture, fusion et construction. */
internal object VorbisComments {

    /** Champs gérés par l'éditeur : remplacés à chaque enregistrement (les autres sont conservés). */
    private val MANAGED = setOf(
        "TITLE", "ARTIST", "ALBUM", "ALBUMARTIST", "ALBUM ARTIST", "GENRE", "DATE", "YEAR",
        "TRACKNUMBER", "TRACKTOTAL", "TOTALTRACKS", "DISCNUMBER", "COMPOSER", "COPYRIGHT",
        "ORGANIZATION", "PUBLISHER", "ENCODER", "LANGUAGE", "COMMENT", "DESCRIPTION", "LYRICS", "UNSYNCEDLYRICS"
    )

    class Parsed(val vendor: String, val comments: List<String>)

    /** Lit « vendeur + liste de commentaires » à partir de [offset] (sans l'en-tête de paquet). */
    fun parse(data: ByteArray, offset: Int): Parsed {
        var p = offset
        fun u32(): Int {
            if (p + 4 > data.size) throw UnsupportedContainerException("Commentaires Vorbis tronqués")
            val v = Bin.readLe32(data, p).toInt()
            p += 4
            return v
        }
        val vendorLength = u32()
        if (vendorLength < 0 || p + vendorLength > data.size) throw UnsupportedContainerException("Vendeur Vorbis invalide")
        val vendor = String(data, p, vendorLength, Charsets.UTF_8)
        p += vendorLength
        val count = u32()
        val comments = ArrayList<String>()
        var index = 0
        while (index < count && p + 4 <= data.size) {
            val length = u32()
            if (length < 0 || p + length > data.size) break
            comments.add(String(data, p, length, Charsets.UTF_8))
            p += length
            index++
        }
        return Parsed(vendor, comments)
    }

    /** Corps d'un bloc PICTURE FLAC (type 3 = pochette de face), JPEG. */
    fun pictureBlock(jpeg: ByteArray): ByteArray {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeByteArray(jpeg, 0, jpeg.size, bounds)
        val mime = Bin.ascii("image/jpeg")
        return Bin.concat(
            Bin.be32(3), Bin.be32(mime.size.toLong()), mime,
            Bin.be32(0), // description vide
            Bin.be32(maxOf(bounds.outWidth, 0).toLong()), Bin.be32(maxOf(bounds.outHeight, 0).toLong()),
            Bin.be32(24), Bin.be32(0),
            Bin.be32(jpeg.size.toLong()), jpeg
        )
    }

    /**
     * Construit les données de commentaires (vendeur + liste). Les commentaires non gérés sont conservés ;
     * si [cover] est fourni, il remplace toute image METADATA_BLOCK_PICTURE existante (cas Ogg).
     * [includePicture] n'est vrai que pour Ogg : dans FLAC, l'image est un bloc distinct.
     */
    fun build(existing: Parsed?, tags: TagData, cover: ByteArray?, includePicture: Boolean): ByteArray {
        val lines = ArrayList<String>()
        existing?.comments?.forEach { line ->
            val key = line.substringBefore('=', "").uppercase(Locale.ROOT)
            if (key.isEmpty() || key in MANAGED) return@forEach
            if (key == "METADATA_BLOCK_PICTURE" && cover != null && includePicture) return@forEach
            lines.add(line)
        }
        fun add(key: String, value: String) {
            if (value.isNotBlank()) lines.add("$key=${value.trim()}")
        }
        add("TITLE", tags.title)
        add("ARTIST", tags.artist)
        add("ALBUM", tags.album)
        add("ALBUMARTIST", tags.albumArtist)
        add("GENRE", tags.genre)
        add("DATE", tags.dateText)
        add("TRACKNUMBER", tags.trackNumber)
        add("TRACKTOTAL", tags.trackTotal)
        add("DISCNUMBER", tags.discNumber)
        add("COMPOSER", tags.composer)
        add("COPYRIGHT", tags.copyright)
        add("ORGANIZATION", tags.publisher)
        add("ENCODER", tags.encoder)
        add("LANGUAGE", tags.language)
        add("COMMENT", tags.comment)
        add("LYRICS", tags.lyrics)
        if (includePicture && cover != null) {
            lines.add("METADATA_BLOCK_PICTURE=" + Base64.encodeToString(pictureBlock(cover), Base64.NO_WRAP))
        }
        val vendor = (existing?.vendor ?: "ELG Music").toByteArray(Charsets.UTF_8)
        val out = ByteArrayOutputStream()
        out.write(Bin.le32(vendor.size.toLong()))
        out.write(vendor)
        out.write(Bin.le32(lines.size.toLong()))
        lines.forEach { line ->
            val bytes = line.toByteArray(Charsets.UTF_8)
            out.write(Bin.le32(bytes.size.toLong()))
            out.write(bytes)
        }
        return out.toByteArray()
    }
}
EOF

echo "  -> app/src/main/java/com/elg/music/data/repository/CoverCache.kt"
mkdir -p app/src/main/java/com/elg/music/data/repository
cat << 'EOF' > app/src/main/java/com/elg/music/data/repository/CoverCache.kt
package com.elg.music.data.repository

import android.content.Context
import android.net.Uri
import java.io.File

/**
 * Repli hybride (formats sans structure d'image interne : MIDI, AMR, AC-3, DTS bruts, ou fichier que le système
 * refuse de réécrire) : la pochette choisie est conservée dans `cacheDir/covers/`, sans toucher au fichier audio.
 */
object CoverCache {

    private fun directory(context: Context): File =
        File(context.applicationContext.cacheDir, "covers").also { it.mkdirs() }

    fun fileFor(context: Context, mediaId: Long): File = File(directory(context), "$mediaId.jpg")

    fun save(context: Context, mediaId: Long, jpeg: ByteArray) {
        val target = fileFor(context, mediaId)
        val temp = File(target.parentFile, "$mediaId.tmp")
        temp.writeBytes(jpeg)
        if (!temp.renameTo(target)) {
            target.writeBytes(jpeg)
            temp.delete()
        }
    }

    fun delete(context: Context, mediaId: Long) {
        fileFor(context, mediaId).delete()
    }

    fun read(context: Context, mediaId: Long): ByteArray? =
        fileFor(context, mediaId).takeIf { it.isFile && it.length() > 0 }?.let { runCatching { it.readBytes() }.getOrNull() }

    /** Identifiant MediaStore d'une Uri `content://media/external/audio/media/<id>`, ou null. */
    fun mediaIdOf(uri: Uri?): Long? = uri?.lastPathSegment?.toLongOrNull()
}
EOF

echo "  -> app/src/main/java/com/elg/music/data/repository/FlacTagWriter.kt"
mkdir -p app/src/main/java/com/elg/music/data/repository
cat << 'EOF' > app/src/main/java/com/elg/music/data/repository/FlacTagWriter.kt
package com.elg.music.data.repository

import com.elg.music.data.model.TagData
import java.io.BufferedOutputStream
import java.io.File
import java.io.FileOutputStream
import java.io.RandomAccessFile

/**
 * FLAC : métadonnées Vorbis Comment (bloc 4) et pochette dans un bloc METADATA_BLOCK_PICTURE (bloc 6).
 * Les blocs STREAMINFO, SEEKTABLE, APPLICATION et CUESHEET sont conservés ; le remplissage (PADDING) est retiré.
 */
object FlacTagWriter {

    private class Block(val type: Int, val body: ByteArray)

    fun write(source: File, target: File, tags: TagData, cover: ByteArray?) {
        RandomAccessFile(source, "r").use { raf ->
            val magic = ByteArray(4)
            raf.readFully(magic)
            if (String(magic, Charsets.US_ASCII) != "fLaC") throw UnsupportedContainerException("Signature FLAC absente")

            var streamInfo: Block? = null
            val others = ArrayList<Block>()
            val pictures = ArrayList<Block>()
            var existing: VorbisComments.Parsed? = null
            var last = false
            while (!last) {
                val header = raf.readUnsignedByte()
                last = (header and 0x80) != 0
                val type = header and 0x7F
                val length = (raf.readUnsignedByte() shl 16) or (raf.readUnsignedByte() shl 8) or raf.readUnsignedByte()
                val body = ByteArray(length)
                raf.readFully(body)
                when (type) {
                    0 -> streamInfo = Block(0, body)
                    1 -> Unit // PADDING
                    4 -> existing = VorbisComments.parse(body, 0)
                    6 -> if (cover == null) pictures.add(Block(6, body))
                    127 -> throw UnsupportedContainerException("Bloc FLAC invalide")
                    else -> others.add(Block(type, body))
                }
            }
            val audioStart = raf.filePointer
            val info = streamInfo ?: throw UnsupportedContainerException("STREAMINFO absent")

            val blocks = ArrayList<Block>()
            blocks.add(info)
            blocks.add(Block(4, VorbisComments.build(existing, tags, cover, includePicture = false)))
            blocks.addAll(others)
            if (cover != null) blocks.add(Block(6, VorbisComments.pictureBlock(cover)))
            blocks.addAll(pictures)

            BufferedOutputStream(FileOutputStream(target), 64 * 1024).use { out ->
                out.write(magic)
                blocks.forEachIndexed { index, block ->
                    if (block.body.size > 0xFFFFFF) throw UnsupportedContainerException("Bloc FLAC trop volumineux")
                    val flag = if (index == blocks.lastIndex) 0x80 else 0
                    out.write(flag or block.type)
                    out.write(block.body.size shr 16)
                    out.write(block.body.size shr 8)
                    out.write(block.body.size)
                    out.write(block.body)
                }
                Bin.copyRange(raf, audioStart, raf.length(), out)
            }
        }
    }
}
EOF

echo "  -> app/src/main/java/com/elg/music/data/repository/OggTagWriter.kt"
mkdir -p app/src/main/java/com/elg/music/data/repository
cat << 'EOF' > app/src/main/java/com/elg/music/data/repository/OggTagWriter.kt
package com.elg.music.data.repository

import com.elg.music.data.model.TagData
import java.io.BufferedOutputStream
import java.io.ByteArrayOutputStream
import java.io.EOFException
import java.io.File
import java.io.FileOutputStream
import java.io.OutputStream
import java.io.RandomAccessFile

/**
 * Ogg Vorbis et Ogg Opus : le paquet de commentaires (Vorbis Comment) est reconstruit, les pages d'en-tête
 * sont recomposées, puis les pages audio sont recopiées (numéros de page et CRC recalculés si besoin).
 * La pochette est une entrée METADATA_BLOCK_PICTURE encodée en Base64, comme le fait FLAC.
 * Seuls les flux à un seul programme logique sont gérés ; les autres basculent sur le repli Room + cache.
 */
object OggTagWriter {

    private val CRC_TABLE = IntArray(256).also { table ->
        for (i in 0 until 256) {
            var r = i shl 24
            repeat(8) {
                r = if ((r and Int.MIN_VALUE) != 0) (r shl 1) xor 0x04C11DB7 else r shl 1
            }
            table[i] = r
        }
    }

    private fun crc(bytes: ByteArray): Int {
        var c = 0
        for (b in bytes) c = (c shl 8) xor CRC_TABLE[((c ushr 24) xor (b.toInt() and 0xFF)) and 0xFF]
        return c
    }

    private class Page(
        val headerType: Int,
        val granule: Long,
        val serial: Long,
        val sequence: Long,
        val segments: ByteArray,
        val data: ByteArray,
        val totalLength: Int
    )

    private fun readPage(raf: RandomAccessFile): Page? {
        val start = raf.filePointer
        if (start + 27 > raf.length()) return null
        val header = ByteArray(27)
        raf.readFully(header)
        if (String(header, 0, 4, Charsets.US_ASCII) != "OggS") {
            raf.seek(start)
            return null
        }
        val count = header[26].toInt() and 0xFF
        val segments = ByteArray(count)
        raf.readFully(segments)
        var dataLength = 0
        for (s in segments) dataLength += s.toInt() and 0xFF
        val data = ByteArray(dataLength)
        try {
            raf.readFully(data)
        } catch (eof: EOFException) {
            raf.seek(start)
            return null
        }
        return Page(
            headerType = header[5].toInt() and 0xFF,
            granule = Bin.readLe64(header, 6),
            serial = Bin.readLe32(header, 14),
            sequence = Bin.readLe32(header, 18),
            segments = segments,
            data = data,
            totalLength = 27 + count + dataLength
        )
    }

    private fun serialize(page: Page): ByteArray {
        val out = ByteArray(page.totalLength)
        "OggS".toByteArray(Charsets.US_ASCII).copyInto(out, 0)
        out[4] = 0
        out[5] = page.headerType.toByte()
        Bin.le64(page.granule).copyInto(out, 6)
        Bin.le32(page.serial).copyInto(out, 14)
        Bin.le32(page.sequence).copyInto(out, 18)
        out[26] = page.segments.size.toByte()
        page.segments.copyInto(out, 27)
        page.data.copyInto(out, 27 + page.segments.size)
        Bin.le32(crc(out).toLong() and 0xFFFFFFFFL).copyInto(out, 22)
        return out
    }

    /** Découpe [packets] en pages (255 segments au plus par page, paquets répartis sur plusieurs pages si besoin). */
    private fun paginate(
        packets: List<ByteArray>,
        serial: Long,
        firstSequence: Long,
        beginOfStream: Boolean
    ): List<Page> {
        val pages = ArrayList<Page>()
        var sequence = firstSequence
        val lacing = ByteArrayOutputStream()
        val data = ByteArrayOutputStream()
        var continued = false
        var first = true

        fun flush(nextContinued: Boolean) {
            if (lacing.size() == 0) return
            var type = if (continued) 0x01 else 0
            if (first && beginOfStream) type = type or 0x02
            first = false
            val page = Page(type, 0L, serial, sequence, lacing.toByteArray(), data.toByteArray(), 0)
            pages.add(Page(page.headerType, page.granule, page.serial, page.sequence, page.segments, page.data,
                27 + page.segments.size + page.data.size))
            sequence++
            lacing.reset()
            data.reset()
            continued = nextContinued
        }

        for (packet in packets) {
            var offset = 0
            var remaining = packet.size
            while (true) {
                val take = minOf(remaining, 255)
                lacing.write(take)
                data.write(packet, offset, take)
                offset += take
                remaining -= take
                val packetEnds = take < 255
                if (lacing.size() == 255) flush(nextContinued = !packetEnds)
                if (packetEnds) break
            }
        }
        flush(nextContinued = false)
        return pages
    }

    fun write(source: File, target: File, tags: TagData, cover: ByteArray?) {
        RandomAccessFile(source, "r").use { raf ->
            val firstPage = readPage(raf) ?: throw UnsupportedContainerException("Page Ogg illisible")
            val serial = firstPage.serial
            val identification = firstPage.data
            val isOpus = identification.size >= 8 && String(identification, 0, 8, Charsets.US_ASCII) == "OpusHead"
            val isVorbis = identification.size >= 7 && identification[0] == 1.toByte() &&
                String(identification, 1, 6, Charsets.US_ASCII) == "vorbis"
            if (!isOpus && !isVorbis) throw UnsupportedContainerException("Flux Ogg non géré (ni Vorbis ni Opus)")
            // L'identification doit tenir seule dans sa page (un seul paquet complet).
            if (firstPage.segments.isEmpty() || (firstPage.segments.last().toInt() and 0xFF) == 255) {
                throw UnsupportedContainerException("Page d'identification inhabituelle")
            }
            val headerPackets = if (isOpus) 2 else 3

            val packets = ArrayList<ByteArray>()
            packets.add(identification)
            val current = ByteArrayOutputStream()
            var oldHeaderPages = 1
            var endedCleanly = true
            while (packets.size < headerPackets) {
                val page = readPage(raf) ?: throw UnsupportedContainerException("En-têtes Ogg incomplets")
                if (page.serial != serial) throw UnsupportedContainerException("Flux Ogg multiplexé")
                oldHeaderPages++
                var offset = 0
                endedCleanly = true
                for ((index, segment) in page.segments.withIndex()) {
                    val size = segment.toInt() and 0xFF
                    current.write(page.data, offset, size)
                    offset += size
                    endedCleanly = true
                    if (size < 255) {
                        packets.add(current.toByteArray())
                        current.reset()
                        if (packets.size == headerPackets && index != page.segments.lastIndex) endedCleanly = false
                    }
                }
                if (packets.size == headerPackets && (!endedCleanly || current.size() != 0)) {
                    throw UnsupportedContainerException("Les en-têtes Ogg ne se terminent pas en fin de page")
                }
            }
            val audioStart = raf.filePointer

            val commentPacket = packets[1]
            val existing = try {
                if (isOpus) {
                    if (commentPacket.size < 8) null else VorbisComments.parse(commentPacket, 8)
                } else {
                    if (commentPacket.size < 7) null else VorbisComments.parse(commentPacket, 7)
                }
            } catch (broken: UnsupportedContainerException) {
                null
            }
            val commentData = VorbisComments.build(existing, tags, cover, includePicture = true)
            val newComment = if (isOpus) {
                Bin.concat(Bin.ascii("OpusTags"), commentData)
            } else {
                Bin.concat(byteArrayOf(3), Bin.ascii("vorbis"), commentData, byteArrayOf(1))
            }

            val newPages = ArrayList<Page>()
            newPages.addAll(paginate(listOf(identification), serial, 0L, beginOfStream = true))
            val rest = ArrayList<ByteArray>()
            rest.add(newComment)
            if (isVorbis) rest.add(packets[2])
            newPages.addAll(paginate(rest, serial, newPages.size.toLong(), beginOfStream = false))
            val delta = newPages.size - oldHeaderPages

            BufferedOutputStream(FileOutputStream(target), 64 * 1024).use { out ->
                newPages.forEach { out.write(serialize(it)) }
                copyAudioPages(raf, audioStart, serial, delta.toLong(), out)
            }
        }
    }

    private fun copyAudioPages(raf: RandomAccessFile, start: Long, serial: Long, delta: Long, out: OutputStream) {
        raf.seek(start)
        while (true) {
            val position = raf.filePointer
            val page = readPage(raf)
            if (page == null) {
                // Fin du fichier, ou octets étrangers : recopiés tels quels.
                Bin.copyRange(raf, position, raf.length(), out)
                return
            }
            if (delta == 0L || page.serial != serial) {
                Bin.copyRange(raf, position, position + page.totalLength, out)
            } else {
                val renumbered = Page(page.headerType, page.granule, page.serial, page.sequence + delta,
                    page.segments, page.data, page.totalLength)
                out.write(serialize(renumbered))
            }
        }
    }
}
EOF

echo "  -> app/src/main/java/com/elg/music/data/repository/Mp4TagWriter.kt"
mkdir -p app/src/main/java/com/elg/music/data/repository
cat << 'EOF' > app/src/main/java/com/elg/music/data/repository/Mp4TagWriter.kt
package com.elg.music.data.repository

import com.elg.music.data.model.TagData
import java.io.BufferedOutputStream
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.io.RandomAccessFile

/**
 * M4A / AAC / ALAC (conteneur MP4) : les tags vivent dans moov › udta › meta › ilst, la pochette dans l'atome
 * `covr`. Le bloc `moov` est reconstruit ; si sa taille change et qu'il précède les données (`mdat`), les
 * décalages des tables stco / co64 sont corrigés. Les MP4 fragmentés (moof) ne sont pas modifiés.
 */
object Mp4TagWriter {

    private class TopBox(val type: String, val start: Long, val size: Long, val headerSize: Int)

    private class Child(val type: String, val payload: ByteArray)

    private const val COPYRIGHT_SIGN = "\u00A9"
    private val T_TITLE = COPYRIGHT_SIGN + "nam"
    private val T_ARTIST = COPYRIGHT_SIGN + "ART"
    private val T_ALBUM = COPYRIGHT_SIGN + "alb"
    private val T_GENRE = COPYRIGHT_SIGN + "gen"
    private val T_YEAR = COPYRIGHT_SIGN + "day"
    private val T_COMPOSER = COPYRIGHT_SIGN + "wrt"
    private val T_ENCODER = COPYRIGHT_SIGN + "too"
    private val T_COMMENT = COPYRIGHT_SIGN + "cmt"
    private val T_LYRICS = COPYRIGHT_SIGN + "lyr"

    private val MANAGED_ATOMS = setOf(
        T_TITLE, T_ARTIST, T_ALBUM, "aART", T_GENRE, "gnre", T_YEAR, "trkn", "disk",
        T_COMPOSER, "cprt", T_ENCODER, T_COMMENT, T_LYRICS
    )
    private val MANAGED_FREEFORM = setOf("PUBLISHER", "LANGUAGE")
    private val CONTAINERS = setOf("trak", "mdia", "minf", "stbl")

    fun write(source: File, target: File, tags: TagData, cover: ByteArray?) {
        RandomAccessFile(source, "r").use { raf ->
            val total = raf.length()
            val top = ArrayList<TopBox>()
            var position = 0L
            while (position + 8 <= total) {
                raf.seek(position)
                var size = raf.readInt().toLong() and 0xFFFFFFFFL
                val typeBytes = ByteArray(4)
                raf.readFully(typeBytes)
                val type = String(typeBytes, Charsets.ISO_8859_1)
                var header = 8
                if (size == 1L) {
                    size = raf.readLong()
                    header = 16
                } else if (size == 0L) {
                    size = total - position
                }
                if (size < header || position + size > total) throw UnsupportedContainerException("Boîte MP4 invalide")
                top.add(TopBox(type, position, size, header))
                position += size
            }
            if (top.any { it.type == "moof" }) throw UnsupportedContainerException("MP4 fragmenté non géré")
            val moov = top.firstOrNull { it.type == "moov" } ?: throw UnsupportedContainerException("Bloc moov absent")
            val oldPayloadSize = moov.size - moov.headerSize
            if (oldPayloadSize > 64L * 1024 * 1024) throw UnsupportedContainerException("Bloc moov trop volumineux")

            val oldPayload = Bin.readBytes(raf, moov.start + moov.headerSize, oldPayloadSize.toInt())
            val newPayload = rebuildMoov(oldPayload, tags, cover)
            val delta = newPayload.size.toLong() - oldPayload.size.toLong()
            if (delta != 0L) patchChunkOffsets(newPayload, 0, newPayload.size, moov.start, delta)

            BufferedOutputStream(FileOutputStream(target), 64 * 1024).use { out ->
                for (box in top) {
                    if (box === moov) {
                        out.write(Bin.be32(8L + newPayload.size))
                        out.write(Bin.ascii("moov"))
                        out.write(newPayload)
                    } else {
                        Bin.copyRange(raf, box.start, box.start + box.size, out)
                    }
                }
            }
        }
    }

    // ===================== Lecture / assemblage de boîtes =====================

    private fun parseChildren(data: ByteArray, from: Int): List<Child> {
        val out = ArrayList<Child>()
        var p = from
        while (p + 8 <= data.size) {
            var size = Bin.readBe32(data, p)
            val type = String(data, p + 4, 4, Charsets.ISO_8859_1)
            var header = 8
            if (size == 1L) {
                if (p + 16 > data.size) break
                size = Bin.readBe64(data, p + 8)
                header = 16
            } else if (size == 0L) {
                size = (data.size - p).toLong()
            }
            if (size < header || p + size > data.size) break
            out.add(Child(type, data.copyOfRange(p + header, p + size.toInt())))
            p += size.toInt()
        }
        return out
    }

    private fun box(type: String, payload: ByteArray): ByteArray =
        Bin.concat(Bin.be32(8L + payload.size), type.toByteArray(Charsets.ISO_8859_1), payload)

    private fun assemble(children: List<Child>): ByteArray {
        val out = ByteArrayOutputStream()
        children.forEach { out.write(box(it.type, it.payload)) }
        return out.toByteArray()
    }

    private fun dataBox(flags: Int, content: ByteArray): ByteArray =
        box("data", Bin.concat(byteArrayOf(0, (flags shr 16).toByte(), (flags shr 8).toByte(), flags.toByte()),
            byteArrayOf(0, 0, 0, 0), content))

    private fun textItem(type: String, value: String): Child =
        Child(type, dataBox(1, value.toByteArray(Charsets.UTF_8)))

    private fun freeformItem(name: String, value: String): Child {
        val mean = box("mean", Bin.concat(byteArrayOf(0, 0, 0, 0), Bin.ascii("com.apple.iTunes")))
        val nameBox = box("name", Bin.concat(byteArrayOf(0, 0, 0, 0), Bin.ascii(name)))
        return Child("----", Bin.concat(mean, nameBox, dataBox(1, value.toByteArray(Charsets.UTF_8))))
    }

    private fun freeformName(payload: ByteArray): String? {
        val nameChild = parseChildren(payload, 0).firstOrNull { it.type == "name" } ?: return null
        if (nameChild.payload.size <= 4) return null
        return String(nameChild.payload, 4, nameChild.payload.size - 4, Charsets.UTF_8).uppercase()
    }

    private fun number(value: String): Int = value.trim().toIntOrNull()?.coerceIn(0, 65535) ?: 0

    private fun defaultHandler(): ByteArray = Bin.concat(
        byteArrayOf(0, 0, 0, 0, 0, 0, 0, 0),
        Bin.ascii("mdir"), Bin.ascii("appl"),
        ByteArray(8), byteArrayOf(0)
    )

    private fun rebuildMoov(moovPayload: ByteArray, tags: TagData, cover: ByteArray?): ByteArray {
        val moovChildren = parseChildren(moovPayload, 0).toMutableList()
        val udtaIndex = moovChildren.indexOfFirst { it.type == "udta" }
        val udtaChildren: MutableList<Child> =
            if (udtaIndex >= 0) parseChildren(moovChildren[udtaIndex].payload, 0).toMutableList() else mutableListOf<Child>()

        val metaIndex = udtaChildren.indexOfFirst { it.type == "meta" }
        val metaChildren: MutableList<Child> = if (metaIndex >= 0) {
            val payload = udtaChildren[metaIndex].payload
            if (payload.size < 4) mutableListOf<Child>() else parseChildren(payload, 4).toMutableList()
        } else {
            mutableListOf<Child>()
        }
        if (metaChildren.none { it.type == "hdlr" }) metaChildren.add(0, Child("hdlr", defaultHandler()))

        val ilstIndex = metaChildren.indexOfFirst { it.type == "ilst" }
        val existingItems: List<Child> =
            if (ilstIndex >= 0) parseChildren(metaChildren[ilstIndex].payload, 0) else emptyList<Child>()

        val items = ArrayList<Child>()
        for (item in existingItems) {
            when {
                item.type in MANAGED_ATOMS -> Unit
                item.type == "covr" && cover != null -> Unit
                item.type == "----" && freeformName(item.payload) in MANAGED_FREEFORM -> Unit
                else -> items.add(item)
            }
        }
        fun text(type: String, value: String) {
            if (value.isNotBlank()) items.add(textItem(type, value.trim()))
        }
        text(T_TITLE, tags.title)
        text(T_ARTIST, tags.artist)
        text(T_ALBUM, tags.album)
        text("aART", tags.albumArtist)
        text(T_GENRE, tags.genre)
        text(T_YEAR, tags.dateText)
        text(T_COMPOSER, tags.composer)
        text("cprt", tags.copyright)
        text(T_ENCODER, tags.encoder)
        text(T_COMMENT, tags.comment)
        text(T_LYRICS, tags.lyrics)
        if (tags.trackNumber.isNotBlank() || tags.trackTotal.isNotBlank()) {
            items.add(Child("trkn", dataBox(0, Bin.concat(
                byteArrayOf(0, 0), Bin.be16(number(tags.trackNumber)), Bin.be16(number(tags.trackTotal)), byteArrayOf(0, 0)
            ))))
        }
        if (tags.discNumber.isNotBlank()) {
            items.add(Child("disk", dataBox(0, Bin.concat(
                byteArrayOf(0, 0), Bin.be16(number(tags.discNumber)), byteArrayOf(0, 0)
            ))))
        }
        if (tags.publisher.isNotBlank()) items.add(freeformItem("PUBLISHER", tags.publisher.trim()))
        if (tags.language.isNotBlank()) items.add(freeformItem("LANGUAGE", tags.language.trim()))
        if (cover != null) items.add(Child("covr", dataBox(13, cover)))

        val newIlst = Child("ilst", assemble(items))
        if (ilstIndex >= 0) metaChildren[ilstIndex] = newIlst else metaChildren.add(newIlst)

        val newMeta = Child("meta", Bin.concat(byteArrayOf(0, 0, 0, 0), assemble(metaChildren)))
        if (metaIndex >= 0) udtaChildren[metaIndex] = newMeta else udtaChildren.add(newMeta)

        val newUdta = Child("udta", assemble(udtaChildren))
        if (udtaIndex >= 0) moovChildren[udtaIndex] = newUdta else moovChildren.add(newUdta)
        return assemble(moovChildren)
    }

    // ===================== Correction des décalages de données =====================

    /**
     * Les tables stco / co64 contiennent la position absolue des blocs audio : si `moov` a grossi ou rétréci
     * et se trouve avant eux, chaque position située après l'ancien début de `moov` est décalée de [delta].
     */
    private fun patchChunkOffsets(data: ByteArray, from: Int, to: Int, oldMoovStart: Long, delta: Long) {
        var p = from
        while (p + 8 <= to) {
            var size = Bin.readBe32(data, p)
            val type = String(data, p + 4, 4, Charsets.ISO_8859_1)
            var header = 8
            if (size == 1L) {
                size = Bin.readBe64(data, p + 8)
                header = 16
            } else if (size == 0L) {
                size = (to - p).toLong()
            }
            if (size < header || p + size > to) return
            val payloadStart = p + header
            val end = p + size.toInt()
            when (type) {
                in CONTAINERS -> patchChunkOffsets(data, payloadStart, end, oldMoovStart, delta)
                "stco" -> {
                    val count = Bin.readBe32(data, payloadStart + 4).toInt()
                    var entry = payloadStart + 8
                    repeat(count) {
                        if (entry + 4 > end) return@repeat
                        val offset = Bin.readBe32(data, entry)
                        if (offset > oldMoovStart) {
                            val moved = offset + delta
                            if (moved < 0 || moved > 0xFFFFFFFFL) throw UnsupportedContainerException("Décalage stco hors limites")
                            Bin.be32(moved).copyInto(data, entry)
                        }
                        entry += 4
                    }
                }
                "co64" -> {
                    val count = Bin.readBe32(data, payloadStart + 4).toInt()
                    var entry = payloadStart + 8
                    repeat(count) {
                        if (entry + 8 > end) return@repeat
                        val offset = Bin.readBe64(data, entry)
                        if (offset > oldMoovStart) {
                            val moved = offset + delta
                            Bin.be32(moved shr 32).copyInto(data, entry)
                            Bin.be32(moved and 0xFFFFFFFFL).copyInto(data, entry + 4)
                        }
                        entry += 8
                    }
                }
            }
            p = end
        }
    }
}
EOF

echo "  -> app/src/main/java/com/elg/music/data/repository/RiffTagWriter.kt"
mkdir -p app/src/main/java/com/elg/music/data/repository
cat << 'EOF' > app/src/main/java/com/elg/music/data/repository/RiffTagWriter.kt
package com.elg.music.data.repository

import com.elg.music.data.model.TagData
import java.io.BufferedInputStream
import java.io.BufferedOutputStream
import java.io.ByteArrayInputStream
import java.io.File
import java.io.FileOutputStream
import java.io.RandomAccessFile

/**
 * WAV (RIFF, petit-boutiste) et AIFF (IFF, gros-boutiste) : le tag ID3v2.4 est stocké dans un chunk `id3 `
 * (WAV) ou `ID3 ` (AIFF) placé en fin de fichier, pochette APIC comprise. Les anciens chunks ID3 sont
 * remplacés ; tous les autres chunks (fmt, data, LIST…) sont recopiés tels quels.
 */
object RiffTagWriter {

    private class Chunk(val id: String, val dataStart: Long, val length: Long)

    fun write(source: File, target: File, tags: TagData, cover: ByteArray?, bigEndian: Boolean) {
        RandomAccessFile(source, "r").use { raf ->
            val total = raf.length()
            if (total < 12) throw UnsupportedContainerException("Fichier trop court")
            val header = Bin.readBytes(raf, 0, 12)
            val form = String(header, 0, 4, Charsets.US_ASCII)
            if (form == "RF64" || form == "BW64") throw UnsupportedContainerException("RF64 non géré")
            val expected = if (bigEndian) "FORM" else "RIFF"
            if (form != expected) throw UnsupportedContainerException("En-tête $expected absent")

            val chunks = ArrayList<Chunk>()
            var position = 12L
            while (position + 8 <= total) {
                val head = Bin.readBytes(raf, position, 8)
                val id = String(head, 0, 4, Charsets.ISO_8859_1)
                val length = if (bigEndian) Bin.readBe32(head, 4) else Bin.readLe32(head, 4)
                val dataStart = position + 8
                if (dataStart + length > total) {
                    // Dernier chunk tronqué : le fichier est trop abîmé pour être réécrit sans risque.
                    throw UnsupportedContainerException("Chunk $id tronqué")
                }
                chunks.add(Chunk(id, dataStart, length))
                position = dataStart + length + (length and 1L)
            }

            val isId3 = { chunk: Chunk -> chunk.id.equals("id3 ", ignoreCase = true) }
            val oldId3 = chunks.lastOrNull(isId3)
            val oldFrames: List<Id3TagCodec.Frame> = if (oldId3 != null && oldId3.length in 10..(8L * 1024 * 1024)) {
                val data = Bin.readBytes(raf, oldId3.dataStart, oldId3.length.toInt())
                try {
                    Id3TagCodec.readTag(BufferedInputStream(ByteArrayInputStream(data)))?.frames.orEmpty()
                } catch (broken: Exception) {
                    emptyList<Id3TagCodec.Frame>()
                }
            } else {
                emptyList<Id3TagCodec.Frame>()
            }
            val newTag = Id3TagCodec.buildTag(oldFrames, tags, cover)
            val tagChunkId = if (bigEndian) "ID3 " else "id3 "

            val kept = chunks.filterNot(isId3)
            var riffSize = 4L
            kept.forEach { riffSize += 8 + it.length + (it.length and 1L) }
            riffSize += 8 + newTag.size + (newTag.size.toLong() and 1L)
            if (riffSize > 0xFFFFFFFFL) throw UnsupportedContainerException("Fichier trop volumineux pour RIFF/IFF classique")

            BufferedOutputStream(FileOutputStream(target), 64 * 1024).use { out ->
                out.write(Bin.ascii(expected))
                out.write(if (bigEndian) Bin.be32(riffSize) else Bin.le32(riffSize))
                out.write(header, 8, 4)
                for (chunk in kept) {
                    out.write(Bin.ascii(chunk.id.padEnd(4, ' ').substring(0, 4)))
                    out.write(if (bigEndian) Bin.be32(chunk.length) else Bin.le32(chunk.length))
                    Bin.copyRange(raf, chunk.dataStart, chunk.dataStart + chunk.length, out)
                    if ((chunk.length and 1L) == 1L) out.write(0)
                }
                out.write(Bin.ascii(tagChunkId))
                out.write(if (bigEndian) Bin.be32(newTag.size.toLong()) else Bin.le32(newTag.size.toLong()))
                out.write(newTag)
                if ((newTag.size and 1) == 1) out.write(0)
            }
        }
    }
}
EOF

echo "  -> app/src/main/java/com/elg/music/data/repository/Apev2TagWriter.kt"
mkdir -p app/src/main/java/com/elg/music/data/repository
cat << 'EOF' > app/src/main/java/com/elg/music/data/repository/Apev2TagWriter.kt
package com.elg.music.data.repository

import com.elg.music.data.model.TagData
import java.io.BufferedOutputStream
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.io.RandomAccessFile
import java.util.Locale

/**
 * Monkey's Audio (APE) et WavPack (WV) : tag APEv2 placé en fin de fichier (avant un éventuel ID3v1).
 * La pochette est l'élément binaire « Cover Art (Front) » (nom de fichier terminé par un zéro, puis l'image).
 * Les éléments APEv2 qui ne sont pas gérés par l'éditeur sont conservés.
 */
object Apev2TagWriter {

    private const val HEADER_FLAG = 0x80000000L
    private const val IS_HEADER = 0x20000000L
    private const val CONTAINS_HEADER = 0x80000000L
    private const val CONTAINS_FOOTER_MASK = 0x40000000L
    private val MANAGED = setOf(
        "TITLE", "ARTIST", "ALBUM", "ALBUM ARTIST", "ALBUMARTIST", "GENRE", "YEAR", "TRACK", "DISC", "DISCNUMBER",
        "COMPOSER", "COPYRIGHT", "PUBLISHER", "ENCODEDBY", "ENCODER", "LANGUAGE", "COMMENT", "LYRICS", "UNSYNCEDLYRICS"
    )

    private class Item(val key: String, val flags: Long, val value: ByteArray)

    fun write(source: File, target: File, tags: TagData, cover: ByteArray?) {
        RandomAccessFile(source, "r").use { raf ->
            val total = raf.length()
            var end = total
            var id3v1: ByteArray? = null
            if (total >= 128) {
                val tail = Bin.readBytes(raf, total - 128, 3)
                if (String(tail, Charsets.US_ASCII) == "TAG") {
                    id3v1 = Bin.readBytes(raf, total - 128, 128)
                    end = total - 128
                }
            }

            var audioEnd = end
            var existing = emptyList<Item>()
            if (end >= 32) {
                val footer = Bin.readBytes(raf, end - 32, 32)
                if (String(footer, 0, 8, Charsets.US_ASCII) == "APETAGEX") {
                    val tagSize = Bin.readLe32(footer, 12)
                    val count = Bin.readLe32(footer, 16).toInt()
                    val flags = Bin.readLe32(footer, 20)
                    val hasHeader = (flags and CONTAINS_HEADER) != 0L
                    val bodyLength = tagSize - 32
                    if (bodyLength in 0..(32L * 1024 * 1024) && end - 32 - bodyLength >= 0) {
                        val itemsStart = end - 32 - bodyLength
                        val body = Bin.readBytes(raf, itemsStart, bodyLength.toInt())
                        existing = parseItems(body, count)
                        audioEnd = itemsStart - if (hasHeader) 32 else 0
                        if (audioEnd < 0) throw UnsupportedContainerException("Tag APEv2 incohérent")
                    }
                }
            }

            val items = ArrayList<Item>()
            existing.forEach { item ->
                val key = item.key.uppercase(Locale.ROOT)
                if (key in MANAGED) return@forEach
                if (cover != null && key.startsWith("COVER ART")) return@forEach
                items.add(item)
            }
            fun text(key: String, value: String) {
                if (value.isNotBlank()) items.add(Item(key, 0L, value.trim().toByteArray(Charsets.UTF_8)))
            }
            text("Title", tags.title)
            text("Artist", tags.artist)
            text("Album", tags.album)
            text("Album Artist", tags.albumArtist)
            text("Genre", tags.genre)
            text("Year", tags.dateText)
            if (tags.trackNumber.isNotBlank()) {
                text("Track", if (tags.trackTotal.isNotBlank()) "${tags.trackNumber.trim()}/${tags.trackTotal.trim()}" else tags.trackNumber)
            }
            text("Disc", tags.discNumber)
            text("Composer", tags.composer)
            text("Copyright", tags.copyright)
            text("Publisher", tags.publisher)
            text("EncodedBy", tags.encoder)
            text("Language", tags.language)
            text("Comment", tags.comment)
            text("Lyrics", tags.lyrics)
            if (cover != null) {
                items.add(Item("Cover Art (Front)", 2L, Bin.concat(Bin.ascii("cover.jpg"), byteArrayOf(0), cover)))
            }

            val body = ByteArrayOutputStream()
            items.forEach { item ->
                body.write(Bin.le32(item.value.size.toLong()))
                body.write(Bin.le32(item.flags))
                body.write(item.key.toByteArray(Charsets.UTF_8))
                body.write(0)
                body.write(item.value)
            }
            val bodyBytes = body.toByteArray()
            val tagSize = bodyBytes.size + 32L

            fun block(isHeader: Boolean): ByteArray {
                val flags = CONTAINS_HEADER or (if (isHeader) IS_HEADER else 0L)
                return Bin.concat(
                    Bin.ascii("APETAGEX"), Bin.le32(2000), Bin.le32(tagSize), Bin.le32(items.size.toLong()),
                    Bin.le32(flags), ByteArray(8)
                )
            }

            BufferedOutputStream(FileOutputStream(target), 64 * 1024).use { out ->
                Bin.copyRange(raf, 0, audioEnd, out)
                if (items.isNotEmpty()) {
                    out.write(block(true))
                    out.write(bodyBytes)
                    out.write(block(false))
                }
                id3v1?.let { out.write(it) }
            }
        }
    }

    private fun parseItems(body: ByteArray, count: Int): List<Item> {
        val items = ArrayList<Item>()
        var p = 0
        var read = 0
        while (read < count && p + 8 < body.size) {
            val valueSize = Bin.readLe32(body, p)
            val flags = Bin.readLe32(body, p + 4)
            p += 8
            var keyEnd = p
            while (keyEnd < body.size && body[keyEnd] != 0.toByte()) keyEnd++
            if (keyEnd >= body.size) break
            val key = String(body, p, keyEnd - p, Charsets.UTF_8)
            p = keyEnd + 1
            if (valueSize < 0 || p + valueSize > body.size) break
            items.add(Item(key, flags and 0x7L, body.copyOfRange(p, p + valueSize.toInt())))
            p += valueSize.toInt()
            read++
        }
        return items
    }
}
EOF

echo "  -> app/src/main/java/com/elg/music/data/repository/AsfTagWriter.kt"
mkdir -p app/src/main/java/com/elg/music/data/repository
cat << 'EOF' > app/src/main/java/com/elg/music/data/repository/AsfTagWriter.kt
package com.elg.music.data.repository

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import com.elg.music.data.model.TagData
import java.io.BufferedOutputStream
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.io.RandomAccessFile
import java.util.Locale

/**
 * WMA (conteneur ASF) : les titres, artistes et droits vont dans l'objet « Content Description », les autres champs
 * et la pochette (`WM/Picture`, image de face) dans l'objet « Extended Content Description ».
 * Le champ valeur d'un descripteur étendu est limité à 65 535 octets : la pochette est donc recompressée si besoin.
 * L'objet « File Properties » (taille du fichier) est mis à jour ; les autres objets d'en-tête sont conservés.
 */
object AsfTagWriter {

    private val HEADER_GUID = guid("75B22630-668E-11CF-A6D9-00AA0062CE6C")
    private val CONTENT_DESCRIPTION = guid("75B22633-668E-11CF-A6D9-00AA0062CE6C")
    private val EXTENDED_CONTENT = guid("D2D0A440-E307-11D2-97F0-00A0C95EA850")
    private val FILE_PROPERTIES = guid("8CABDCA1-A947-11CF-8EE4-00C00C205365")

    private const val MAX_VALUE_BYTES = 65535
    private val MANAGED = setOf(
        "WM/ALBUMTITLE", "WM/ALBUMARTIST", "WM/GENRE", "WM/YEAR", "WM/TRACKNUMBER", "WM/TRACK", "WM/PARTOFSET",
        "WM/COMPOSER", "WM/PUBLISHER", "WM/ENCODINGSETTINGS", "WM/LANGUAGE", "WM/LYRICS", "WM/PICTURE"
    )

    private class AsfObject(val guid: ByteArray, val body: ByteArray)
    private class Descriptor(val name: String, val type: Int, val value: ByteArray)

    private fun guid(text: String): ByteArray {
        val p = text.split('-')
        val bytes = ByteArray(16)
        fun hex(s: String): ByteArray = ByteArray(s.length / 2) { s.substring(it * 2, it * 2 + 2).toInt(16).toByte() }
        hex(p[0]).reversedArray().copyInto(bytes, 0)
        hex(p[1]).reversedArray().copyInto(bytes, 4)
        hex(p[2]).reversedArray().copyInto(bytes, 6)
        hex(p[3]).copyInto(bytes, 8)
        hex(p[4]).copyInto(bytes, 10)
        return bytes
    }

    private fun utf16(text: String, terminated: Boolean = true): ByteArray {
        val raw = text.toByteArray(Charsets.UTF_16LE)
        return if (terminated) raw + byteArrayOf(0, 0) else raw
    }

    fun write(source: File, target: File, tags: TagData, cover: ByteArray?) {
        RandomAccessFile(source, "r").use { raf ->
            val total = raf.length()
            val head = Bin.readBytes(raf, 0, 30)
            if (!head.copyOfRange(0, 16).contentEquals(HEADER_GUID)) throw UnsupportedContainerException("En-tête ASF absent")
            val headerSize = Bin.readLe64(head, 16)
            val objectCount = Bin.readLe32(head, 24).toInt()
            if (headerSize < 30 || headerSize > total || headerSize > 64L * 1024 * 1024) {
                throw UnsupportedContainerException("En-tête ASF invalide")
            }
            val headerBody = Bin.readBytes(raf, 30, (headerSize - 30).toInt())

            val objects = ArrayList<AsfObject>()
            var p = 0
            repeat(objectCount) {
                if (p + 24 > headerBody.size) throw UnsupportedContainerException("Objet ASF tronqué")
                val size = Bin.readLe64(headerBody, p + 16)
                if (size < 24 || p + size > headerBody.size) throw UnsupportedContainerException("Taille d'objet ASF invalide")
                objects.add(AsfObject(headerBody.copyOfRange(p, p + 16), headerBody.copyOfRange(p + 24, p + size.toInt())))
                p += size.toInt()
            }

            val oldExtended = objects.firstOrNull { it.guid.contentEquals(EXTENDED_CONTENT) }
            val preserved: List<Descriptor> =
                if (oldExtended != null) parseDescriptors(oldExtended.body) else emptyList<Descriptor>()
            val oldContent = objects.firstOrNull { it.guid.contentEquals(CONTENT_DESCRIPTION) }

            val descriptors = ArrayList<Descriptor>()
            preserved.forEach { d ->
                val key = d.name.uppercase(Locale.ROOT)
                if (key in MANAGED && !(key == "WM/PICTURE" && cover == null)) return@forEach
                descriptors.add(d)
            }
            fun text(name: String, value: String) {
                if (value.isNotBlank()) descriptors.add(Descriptor(name, 0, utf16(value.trim())))
            }
            text("WM/AlbumTitle", tags.album)
            text("WM/AlbumArtist", tags.albumArtist)
            text("WM/Genre", tags.genre)
            text("WM/Year", tags.dateText)
            if (tags.trackNumber.isNotBlank()) text("WM/TrackNumber", tags.trackNumber)
            if (tags.discNumber.isNotBlank()) text("WM/PartOfSet", tags.discNumber)
            text("WM/Composer", tags.composer)
            text("WM/Publisher", tags.publisher)
            text("WM/EncodingSettings", tags.encoder)
            text("WM/Language", tags.language)
            text("WM/Lyrics", tags.lyrics)
            if (cover != null) {
                val fitted = fitCover(cover)
                val picture = Bin.concat(
                    byteArrayOf(3), Bin.le32(fitted.size.toLong()), utf16("image/jpeg"), utf16(""), fitted
                )
                descriptors.add(Descriptor("WM/Picture", 1, picture))
            }
            descriptors.forEach {
                if (it.value.size > MAX_VALUE_BYTES) throw UnsupportedContainerException("Valeur ASF trop grande (${it.name})")
            }

            // Content Description : titre, auteur, copyright, description, évaluation.
            fun oldField(index: Int): String = oldContent?.let { readContentField(it.body, index) }.orEmpty()
            val rating = oldField(4)
            val content = ByteArrayOutputStream().also { out ->
                val fields = listOf(tags.title.trim(), tags.artist.trim(), tags.copyright.trim(), tags.comment.trim(), rating)
                val encoded = fields.map { if (it.isEmpty()) ByteArray(0) else utf16(it) }
                encoded.forEach { if (it.size > MAX_VALUE_BYTES) throw UnsupportedContainerException("Champ ASF trop long") }
                encoded.forEach { out.write(Bin.le16(it.size)) }
                encoded.forEach { out.write(it) }
            }.toByteArray()

            val extended = ByteArrayOutputStream().also { out ->
                out.write(Bin.le16(descriptors.size))
                descriptors.forEach { d ->
                    val name = utf16(d.name)
                    out.write(Bin.le16(name.size))
                    out.write(name)
                    out.write(Bin.le16(d.type))
                    out.write(Bin.le16(d.value.size))
                    out.write(d.value)
                }
            }.toByteArray()

            val rebuilt = ArrayList<AsfObject>()
            var contentPlaced = false
            var extendedPlaced = false
            for (obj in objects) {
                when {
                    obj.guid.contentEquals(CONTENT_DESCRIPTION) -> {
                        rebuilt.add(AsfObject(CONTENT_DESCRIPTION, content)); contentPlaced = true
                    }
                    obj.guid.contentEquals(EXTENDED_CONTENT) -> {
                        if (descriptors.isNotEmpty()) rebuilt.add(AsfObject(EXTENDED_CONTENT, extended))
                        extendedPlaced = true
                    }
                    else -> rebuilt.add(obj)
                }
            }
            // Après File Properties (objet 1) pour respecter l'ordre usuel.
            val insertAt = (rebuilt.indexOfFirst { it.guid.contentEquals(FILE_PROPERTIES) } + 1).coerceAtLeast(0)
            if (!contentPlaced) rebuilt.add(insertAt, AsfObject(CONTENT_DESCRIPTION, content))
            if (!extendedPlaced && descriptors.isNotEmpty()) {
                rebuilt.add((insertAt + 1).coerceAtMost(rebuilt.size), AsfObject(EXTENDED_CONTENT, extended))
            }

            var newHeaderSize = 30L
            rebuilt.forEach { newHeaderSize += 24 + it.body.size }
            val newTotal = newHeaderSize + (total - headerSize)

            BufferedOutputStream(FileOutputStream(target), 64 * 1024).use { out ->
                out.write(HEADER_GUID)
                out.write(Bin.le64(newHeaderSize))
                out.write(Bin.le32(rebuilt.size.toLong()))
                out.write(head, 28, 2)
                for (obj in rebuilt) {
                    var body = obj.body
                    if (obj.guid.contentEquals(FILE_PROPERTIES) && body.size >= 40) {
                        body = body.copyOf()
                        Bin.le64(newTotal).copyInto(body, 16) // identifiant du fichier (16 octets) puis taille
                    }
                    out.write(obj.guid)
                    out.write(Bin.le64(24L + body.size))
                    out.write(body)
                }
                Bin.copyRange(raf, headerSize, total, out)
            }
        }
    }

    private fun readContentField(body: ByteArray, index: Int): String {
        if (body.size < 10) return ""
        var offset = 10
        for (i in 0 until index) offset += Bin.readLe16(body, i * 2)
        val length = Bin.readLe16(body, index * 2)
        if (length < 2 || offset + length > body.size) return ""
        return String(body, offset, length - 2, Charsets.UTF_16LE)
    }

    private fun parseDescriptors(body: ByteArray): List<Descriptor> {
        val out = ArrayList<Descriptor>()
        if (body.size < 2) return out
        val count = Bin.readLe16(body, 0)
        var p = 2
        repeat(count) {
            if (p + 2 > body.size) return out
            val nameLength = Bin.readLe16(body, p); p += 2
            if (p + nameLength + 4 > body.size) return out
            val name = String(body, p, maxOf(nameLength - 2, 0), Charsets.UTF_16LE); p += nameLength
            val type = Bin.readLe16(body, p); p += 2
            val valueLength = Bin.readLe16(body, p); p += 2
            if (p + valueLength > body.size) return out
            out.add(Descriptor(name, type, body.copyOfRange(p, p + valueLength))); p += valueLength
        }
        return out
    }

    /** Recompresse la pochette en JPEG jusqu'à tenir dans la limite d'un descripteur ASF. */
    private fun fitCover(jpeg: ByteArray): ByteArray {
        val limit = MAX_VALUE_BYTES - 64
        if (jpeg.size <= limit) return jpeg
        val decoded = BitmapFactory.decodeByteArray(jpeg, 0, jpeg.size)
            ?: throw UnsupportedContainerException("Pochette illisible")
        var side = maxOf(decoded.width, decoded.height)
        var quality = 80
        while (true) {
            val ratio = minOf(1f, side.toFloat() / maxOf(decoded.width, decoded.height))
            val scaled = Bitmap.createScaledBitmap(
                decoded, maxOf((decoded.width * ratio).toInt(), 1), maxOf((decoded.height * ratio).toInt(), 1), true
            )
            val out = ByteArrayOutputStream()
            scaled.compress(Bitmap.CompressFormat.JPEG, quality, out)
            if (out.size() <= limit) return out.toByteArray()
            if (quality > 40) quality -= 15 else side = (side * 0.8f).toInt()
            if (side < 64) throw UnsupportedContainerException("Pochette trop volumineuse pour ASF")
        }
    }
}
EOF

echo "  -> app/src/main/java/com/elg/music/data/repository/MatroskaTagWriter.kt"
mkdir -p app/src/main/java/com/elg/music/data/repository
cat << 'EOF' > app/src/main/java/com/elg/music/data/repository/MatroskaTagWriter.kt
package com.elg.music.data.repository

import com.elg.music.data.model.TagData
import java.io.BufferedOutputStream
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.io.RandomAccessFile
import java.security.SecureRandom

/**
 * MKV / MKA / WebM : les métadonnées sont écrites dans un élément `Tags` et la pochette dans un élément
 * `Attachments` (fichier joint `cover.jpg`), tous deux ajoutés à la fin du Segment. Les anciens éléments `Tags` sont
 * neutralisés en place (remplacés par un élément Void de même taille), ce qui laisse intacts les index (SeekHead, Cues).
 * Les pièces jointes déjà présentes (polices de sous-titres…) sont conservées.
 */
object MatroskaTagWriter {

    private const val ID_EBML = 0x1A45DFA3L
    private const val ID_SEGMENT = 0x18538067L
    private const val ID_TAGS = 0x1254C367L
    private const val ID_TAG = 0x7373L
    private const val ID_TARGETS = 0x63C0L
    private const val ID_SIMPLE_TAG = 0x67C8L
    private const val ID_TAG_NAME = 0x45A3L
    private const val ID_TAG_STRING = 0x4487L
    private const val ID_ATTACHMENTS = 0x1941A469L
    private const val ID_ATTACHED_FILE = 0x61A7L
    private const val ID_FILE_DESC = 0x467EL
    private const val ID_FILE_NAME = 0x466EL
    private const val ID_FILE_MIME = 0x4660L
    private const val ID_FILE_DATA = 0x465CL
    private const val ID_FILE_UID = 0x46AEL

    private class Header(val id: Long, val idLength: Int, val sizeLength: Int, val size: Long, val unknown: Boolean)

    private fun readHeader(raf: RandomAccessFile, position: Long, limit: Long): Header? {
        if (position + 2 > limit) return null
        raf.seek(position)
        val first = raf.read()
        if (first <= 0) return null
        val idLength = Integer.numberOfLeadingZeros(first) - 24 + 1
        if (idLength !in 1..4) return null
        var id = first.toLong()
        repeat(idLength - 1) { id = (id shl 8) or raf.readUnsignedByte().toLong() }
        val sizeFirst = raf.read()
        if (sizeFirst <= 0) return null
        val sizeLength = Integer.numberOfLeadingZeros(sizeFirst) - 24 + 1
        if (sizeLength !in 1..8) return null
        var value = (sizeFirst and ((1 shl (8 - sizeLength)) - 1)).toLong()
        var allOnes = value == ((1L shl (8 - sizeLength)) - 1)
        repeat(sizeLength - 1) {
            val b = raf.readUnsignedByte()
            if (b != 0xFF) allOnes = false
            value = (value shl 8) or b.toLong()
        }
        return Header(id, idLength, sizeLength, value, allOnes)
    }

    // ===================== Encodage EBML =====================

    private fun idBytes(id: Long): ByteArray {
        var length = 1
        while ((id ushr (8 * length)) != 0L) length++
        return ByteArray(length) { (id ushr (8 * (length - 1 - it))).toByte() }
    }

    private fun sizeBytes(size: Long, length: Int = minimalSizeLength(size)): ByteArray {
        val out = ByteArray(length)
        var v = size
        for (i in length - 1 downTo 0) {
            out[i] = v.toByte()
            v = v ushr 8
        }
        out[0] = (out[0].toInt() or (0x80 shr (length - 1))).toByte()
        return out
    }

    private fun minimalSizeLength(size: Long): Int {
        for (length in 1..8) if (size < (1L shl (7 * length)) - 1) return length
        throw UnsupportedContainerException("Élément Matroska trop grand")
    }

    private fun element(id: Long, payload: ByteArray): ByteArray =
        Bin.concat(idBytes(id), sizeBytes(payload.size.toLong()), payload)

    private fun uintElement(id: Long, value: Long): ByteArray {
        var length = 1
        while (length < 8 && (value ushr (8 * length)) != 0L) length++
        return element(id, ByteArray(length) { (value ushr (8 * (length - 1 - it))).toByte() })
    }

    private fun textElement(id: Long, text: String): ByteArray = element(id, text.toByteArray(Charsets.UTF_8))

    private fun simpleTag(name: String, value: String): ByteArray =
        element(ID_SIMPLE_TAG, Bin.concat(textElement(ID_TAG_NAME, name), textElement(ID_TAG_STRING, value)))

    private fun buildTags(tags: TagData): ByteArray? {
        val simple = ByteArrayOutputStream()
        fun add(name: String, value: String) {
            if (value.isNotBlank()) simple.write(simpleTag(name, value.trim()))
        }
        add("TITLE", tags.title)
        add("ARTIST", tags.artist)
        add("ALBUM", tags.album)
        add("ALBUM_ARTIST", tags.albumArtist)
        add("GENRE", tags.genre)
        add("DATE_RELEASED", tags.dateText)
        add("PART_NUMBER", tags.trackNumber)
        add("TOTAL_PARTS", tags.trackTotal)
        add("DISC_NUMBER", tags.discNumber)
        add("COMPOSER", tags.composer)
        add("COPYRIGHT", tags.copyright)
        add("PUBLISHER", tags.publisher)
        add("ENCODER", tags.encoder)
        add("LANGUAGE", tags.language)
        add("COMMENT", tags.comment)
        add("LYRICS", tags.lyrics)
        if (simple.size() == 0) return null
        val tag = element(ID_TAG, Bin.concat(element(ID_TARGETS, ByteArray(0)), simple.toByteArray()))
        return element(ID_TAGS, tag)
    }

    private fun buildAttachments(jpeg: ByteArray): ByteArray {
        val uid = (SecureRandom().nextLong() ushr 2) or 1L
        val file = element(
            ID_ATTACHED_FILE,
            Bin.concat(
                textElement(ID_FILE_DESC, "Cover"),
                textElement(ID_FILE_NAME, "cover.jpg"),
                textElement(ID_FILE_MIME, "image/jpeg"),
                uintElement(ID_FILE_UID, uid),
                element(ID_FILE_DATA, jpeg)
            )
        )
        return element(ID_ATTACHMENTS, file)
    }

    // ===================== Écriture =====================

    private class Patch(val offset: Long, val bytes: ByteArray)

    fun write(source: File, target: File, tags: TagData, cover: ByteArray?) {
        RandomAccessFile(source, "r").use { raf ->
            val total = raf.length()
            val ebml = readHeader(raf, 0, total)
            if (ebml == null || ebml.id != ID_EBML) throw UnsupportedContainerException("En-tête EBML absent")
            val segmentPosition = ebml.idLength + ebml.sizeLength + ebml.size
            val segment = readHeader(raf, segmentPosition, total)
            if (segment == null || segment.id != ID_SEGMENT) throw UnsupportedContainerException("Segment Matroska absent")
            val payloadStart = segmentPosition + segment.idLength + segment.sizeLength
            val segmentEnd = if (segment.unknown) total else payloadStart + segment.size
            if (segmentEnd > total) throw UnsupportedContainerException("Segment tronqué")

            val patches = ArrayList<Patch>()
            var position = payloadStart
            while (position < segmentEnd) {
                val child = readHeader(raf, position, segmentEnd) ?: break
                if (child.unknown) break
                val headerLength = child.idLength + child.sizeLength
                val elementLength = headerLength + child.size
                if (position + elementLength > segmentEnd) break
                if (child.id == ID_TAGS) {
                    // Void (ID 0xEC, 1 octet) : taille codée sur (taille du champ d'origine + 3) octets, de même longueur totale.
                    val voidSizeLength = child.sizeLength + (child.idLength - 1)
                    if (voidSizeLength in 1..8 && child.size < (1L shl (7 * voidSizeLength)) - 1) {
                        val bytes = Bin.concat(byteArrayOf(0xEC.toByte()), sizeBytes(child.size, voidSizeLength))
                        patches.add(Patch(position, bytes))
                    } else {
                        throw UnsupportedContainerException("Impossible de neutraliser l'ancien élément Tags")
                    }
                }
                position += elementLength
            }

            val appended = ByteArrayOutputStream()
            buildTags(tags)?.let { appended.write(it) }
            if (cover != null) appended.write(buildAttachments(cover))
            val extra = appended.toByteArray()

            if (!segment.unknown && extra.isNotEmpty()) {
                val newSize = segment.size + extra.size
                if (newSize >= (1L shl (7 * segment.sizeLength)) - 1) {
                    throw UnsupportedContainerException("Taille du Segment trop grande pour son champ")
                }
                patches.add(Patch(segmentPosition + segment.idLength, sizeBytes(newSize, segment.sizeLength)))
            }
            patches.sortBy { it.offset }

            BufferedOutputStream(FileOutputStream(target), 64 * 1024).use { out ->
                var cursor = 0L
                for (patch in patches) {
                    Bin.copyRange(raf, cursor, patch.offset, out)
                    out.write(patch.bytes)
                    cursor = patch.offset + patch.bytes.size
                }
                Bin.copyRange(raf, cursor, segmentEnd, out)
                out.write(extra)
                Bin.copyRange(raf, segmentEnd, total, out)
            }
        }
    }
}
EOF

echo "[3/3] Verification rapide de la presence des fichiers cles..."
MISSING=0
if [ ! -s "app/debug.keystore" ]; then echo "MANQUANT: app/debug.keystore"; MISSING=1; fi
if [ ! -f "app/src/main/java/com/elg/music/data/local/SettingsRepository.kt" ]; then echo "MANQUANT: app/src/main/java/com/elg/music/data/local/SettingsRepository.kt"; MISSING=1; fi
if [ ! -f "app/src/main/java/com/elg/music/data/local/ElgDatabase.kt" ]; then echo "MANQUANT: app/src/main/java/com/elg/music/data/local/ElgDatabase.kt"; MISSING=1; fi
if [ ! -f "app/src/main/java/com/elg/music/ui/main/SongActions.kt" ]; then echo "MANQUANT: app/src/main/java/com/elg/music/ui/main/SongActions.kt"; MISSING=1; fi
if [ ! -f "app/src/main/res/menu/menu_player_options.xml" ]; then echo "MANQUANT: app/src/main/res/menu/menu_player_options.xml"; MISSING=1; fi
if [ ! -f "app/src/main/java/com/elg/music/data/local/AudioPresets.kt" ]; then echo "MANQUANT: app/src/main/java/com/elg/music/data/local/AudioPresets.kt"; MISSING=1; fi
if [ ! -f "app/src/main/java/com/elg/music/playback/AudioEffectsController.kt" ]; then echo "MANQUANT: app/src/main/java/com/elg/music/playback/AudioEffectsController.kt"; MISSING=1; fi
if [ ! -f "app/src/main/java/com/elg/music/ui/settings/AudioSettingsActivity.kt" ]; then echo "MANQUANT: app/src/main/java/com/elg/music/ui/settings/AudioSettingsActivity.kt"; MISSING=1; fi
if [ ! -f "app/src/main/res/layout/activity_audio_settings.xml" ]; then echo "MANQUANT: app/src/main/res/layout/activity_audio_settings.xml"; MISSING=1; fi
if [ ! -f "app/src/main/res/layout/item_slider_row.xml" ]; then echo "MANQUANT: app/src/main/res/layout/item_slider_row.xml"; MISSING=1; fi
if [ ! -f "app/src/main/java/com/elg/music/data/local/VaultPinStore.kt" ]; then echo "MANQUANT: app/src/main/java/com/elg/music/data/local/VaultPinStore.kt"; MISSING=1; fi
if [ ! -f "app/src/main/java/com/elg/music/data/repository/VaultRepository.kt" ]; then echo "MANQUANT: app/src/main/java/com/elg/music/data/repository/VaultRepository.kt"; MISSING=1; fi
if [ ! -f "app/src/main/java/com/elg/music/ui/vault/PinDialogs.kt" ]; then echo "MANQUANT: app/src/main/java/com/elg/music/ui/vault/PinDialogs.kt"; MISSING=1; fi
if [ ! -f "app/src/main/java/com/elg/music/ui/vault/VaultActions.kt" ]; then echo "MANQUANT: app/src/main/java/com/elg/music/ui/vault/VaultActions.kt"; MISSING=1; fi
if [ ! -f "app/src/main/java/com/elg/music/ui/vault/VaultAdapter.kt" ]; then echo "MANQUANT: app/src/main/java/com/elg/music/ui/vault/VaultAdapter.kt"; MISSING=1; fi
if [ ! -f "app/src/main/java/com/elg/music/ui/vault/VaultActivity.kt" ]; then echo "MANQUANT: app/src/main/java/com/elg/music/ui/vault/VaultActivity.kt"; MISSING=1; fi
if [ ! -f "app/src/main/res/layout/dialog_pin.xml" ]; then echo "MANQUANT: app/src/main/res/layout/dialog_pin.xml"; MISSING=1; fi
if [ ! -f "app/src/main/res/layout/activity_vault.xml" ]; then echo "MANQUANT: app/src/main/res/layout/activity_vault.xml"; MISSING=1; fi
if [ ! -f "app/src/main/res/menu/menu_vault.xml" ]; then echo "MANQUANT: app/src/main/res/menu/menu_vault.xml"; MISSING=1; fi
if [ ! -f "app/src/main/res/menu/menu_vault_item.xml" ]; then echo "MANQUANT: app/src/main/res/menu/menu_vault_item.xml"; MISSING=1; fi
if [ ! -f "app/src/main/res/xml/data_extraction_rules.xml" ]; then echo "MANQUANT: app/src/main/res/xml/data_extraction_rules.xml"; MISSING=1; fi
if [ ! -f "app/src/main/java/com/elg/music/playback/SleepTimerHub.kt" ]; then echo "MANQUANT: app/src/main/java/com/elg/music/playback/SleepTimerHub.kt"; MISSING=1; fi
if [ ! -f "app/src/main/java/com/elg/music/playback/SleepTimerController.kt" ]; then echo "MANQUANT: app/src/main/java/com/elg/music/playback/SleepTimerController.kt"; MISSING=1; fi
if [ ! -f "app/src/main/java/com/elg/music/playback/AbLoopController.kt" ]; then echo "MANQUANT: app/src/main/java/com/elg/music/playback/AbLoopController.kt"; MISSING=1; fi
if [ ! -f "app/src/main/java/com/elg/music/ui/player/SleepTimerSheet.kt" ]; then echo "MANQUANT: app/src/main/java/com/elg/music/ui/player/SleepTimerSheet.kt"; MISSING=1; fi
if [ ! -f "app/src/main/java/com/elg/music/ui/player/AbLoopSheet.kt" ]; then echo "MANQUANT: app/src/main/java/com/elg/music/ui/player/AbLoopSheet.kt"; MISSING=1; fi
if [ ! -f "app/src/main/res/layout/layout_sleep_timer_sheet.xml" ]; then echo "MANQUANT: app/src/main/res/layout/layout_sleep_timer_sheet.xml"; MISSING=1; fi
if [ ! -f "app/src/main/res/layout/layout_ab_loop_sheet.xml" ]; then echo "MANQUANT: app/src/main/res/layout/layout_ab_loop_sheet.xml"; MISSING=1; fi
if [ ! -f "app/build.gradle" ]; then echo "MANQUANT: app/build.gradle"; MISSING=1; fi
if [ ! -f "app/src/main/java/com/elg/music/ui/main/MainActivity.kt" ]; then echo "MANQUANT: app/src/main/java/com/elg/music/ui/main/MainActivity.kt"; MISSING=1; fi
if [ ! -f "app/src/main/java/com/elg/music/playback/MusicPlaybackService.kt" ]; then echo "MANQUANT: app/src/main/java/com/elg/music/playback/MusicPlaybackService.kt"; MISSING=1; fi
if [ ! -f ".github/workflows/build.yml" ]; then echo "MANQUANT: .github/workflows/build.yml"; MISSING=1; fi
if [ ! -f "app/src/main/java/com/elg/music/data/model/TagData.kt" ]; then echo "MANQUANT: app/src/main/java/com/elg/music/data/model/TagData.kt"; MISSING=1; fi
if [ ! -f "app/src/main/java/com/elg/music/data/repository/Id3TagCodec.kt" ]; then echo "MANQUANT: app/src/main/java/com/elg/music/data/repository/Id3TagCodec.kt"; MISSING=1; fi
if [ ! -f "app/src/main/java/com/elg/music/data/repository/FilenameTagParser.kt" ]; then echo "MANQUANT: app/src/main/java/com/elg/music/data/repository/FilenameTagParser.kt"; MISSING=1; fi
if [ ! -f "app/src/main/java/com/elg/music/data/repository/TagRepository.kt" ]; then echo "MANQUANT: app/src/main/java/com/elg/music/data/repository/TagRepository.kt"; MISSING=1; fi
if [ ! -f "app/src/main/java/com/elg/music/ui/tags/TagEditorActivity.kt" ]; then echo "MANQUANT: app/src/main/java/com/elg/music/ui/tags/TagEditorActivity.kt"; MISSING=1; fi
if [ ! -f "app/src/main/res/layout/activity_tag_editor.xml" ]; then echo "MANQUANT: app/src/main/res/layout/activity_tag_editor.xml"; MISSING=1; fi
if [ ! -f "app/src/main/res/layout/item_tag_field.xml" ]; then echo "MANQUANT: app/src/main/res/layout/item_tag_field.xml"; MISSING=1; fi
if [ ! -f "app/src/main/res/layout/item_tag_month.xml" ]; then echo "MANQUANT: app/src/main/res/layout/item_tag_month.xml"; MISSING=1; fi
if [ ! -f "app/src/main/java/com/elg/music/data/local/PlaybackStateStore.kt" ]; then echo "MANQUANT: app/src/main/java/com/elg/music/data/local/PlaybackStateStore.kt"; MISSING=1; fi
if [ ! -f "app/src/main/java/com/elg/music/playback/MediaItemFactory.kt" ]; then echo "MANQUANT: app/src/main/java/com/elg/music/playback/MediaItemFactory.kt"; MISSING=1; fi
if [ ! -f "app/src/main/java/com/elg/music/data/repository/AudioTagWriter.kt" ]; then echo "MANQUANT: app/src/main/java/com/elg/music/data/repository/AudioTagWriter.kt"; MISSING=1; fi
if [ ! -f "app/src/main/java/com/elg/music/data/repository/CoverCache.kt" ]; then echo "MANQUANT: app/src/main/java/com/elg/music/data/repository/CoverCache.kt"; MISSING=1; fi
if [ ! -f "app/src/main/java/com/elg/music/data/repository/FlacTagWriter.kt" ]; then echo "MANQUANT: app/src/main/java/com/elg/music/data/repository/FlacTagWriter.kt"; MISSING=1; fi
if [ ! -f "app/src/main/java/com/elg/music/data/repository/OggTagWriter.kt" ]; then echo "MANQUANT: app/src/main/java/com/elg/music/data/repository/OggTagWriter.kt"; MISSING=1; fi
if [ ! -f "app/src/main/java/com/elg/music/data/repository/Mp4TagWriter.kt" ]; then echo "MANQUANT: app/src/main/java/com/elg/music/data/repository/Mp4TagWriter.kt"; MISSING=1; fi
if [ ! -f "app/src/main/java/com/elg/music/data/repository/RiffTagWriter.kt" ]; then echo "MANQUANT: app/src/main/java/com/elg/music/data/repository/RiffTagWriter.kt"; MISSING=1; fi
if [ ! -f "app/src/main/java/com/elg/music/data/repository/Apev2TagWriter.kt" ]; then echo "MANQUANT: app/src/main/java/com/elg/music/data/repository/Apev2TagWriter.kt"; MISSING=1; fi
if [ ! -f "app/src/main/java/com/elg/music/data/repository/AsfTagWriter.kt" ]; then echo "MANQUANT: app/src/main/java/com/elg/music/data/repository/AsfTagWriter.kt"; MISSING=1; fi
if [ ! -f "app/src/main/java/com/elg/music/data/repository/MatroskaTagWriter.kt" ]; then echo "MANQUANT: app/src/main/java/com/elg/music/data/repository/MatroskaTagWriter.kt"; MISSING=1; fi
if [ "$MISSING" -eq 0 ]; then
  echo ""
  echo "=== ELG MUSIC : PROJET ET WORKFLOW GITHUB ACTIONS INSTALLES AVEC SUCCES ==="
  echo "Commitez et poussez ces fichiers (y compris .github/workflows/build.yml), le workflow se declenchera automatiquement."
else
  echo "Des fichiers cles sont manquants, verifiez les erreurs ci-dessus."
  exit 1
fi
