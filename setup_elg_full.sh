#!/usr/bin/env bash
set -e

echo "=== ELG Music v1.04 : projet complet + workflow GitHub Actions ==="
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

echo "[2/3] Ecriture des 87 fichiers..."
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
        versionCode 5
        versionName '1.04'

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

    <!-- ===================== BLUETOOTH (reprise automatique) ===================== -->
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />

    <!-- ===================== RÉSEAU (Gemini, Firebase, mises à jour) ===================== -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

    <!-- ===================== COFFRE-FORT PRIVÉ ===================== -->
    <uses-permission android:name="android.permission.USE_BIOMETRIC" />

    <application
        android:allowBackup="true"
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

        songs
    }

    private fun isFromExcludedFolder(path: String?): Boolean {
        if (path.isNullOrBlank()) return false
        val lower = path.lowercase(Locale.ROOT)
        return EXCLUDED_FOLDER_KEYWORDS.any { lower.contains(it) }
    }

    companion object {
        private const val MIN_DURATION_MS = 30_000L
        private const val UNKNOWN_ARTIST_TAG = "<unknown>"

        /** Types MIME reconnus : MP3, WAV, FLAC, M4A, AAC, OGG, OPUS, AMR, WMA et MIDI. */
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
            "audio/midi", "audio/x-midi", "audio/mid", "audio/sp-midi"
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

    fun skipToNext() {
        controller?.seekToNextMediaItem()
    }

    fun skipToPrevious() {
        controller?.seekToPreviousMediaItem()
    }

    /** Avance la lecture de [stepMs] dans le morceau courant (utilisé par l'appui long "Suivant"). */
    fun seekForward(stepMs: Long) {
        val mediaController = controller ?: return
        mediaController.seekTo((mediaController.currentPosition + stepMs).coerceAtLeast(0L))
    }

    /** Recule la lecture de [stepMs] dans le morceau courant (utilisé par l'appui long "Précédent"). */
    fun seekBackward(stepMs: Long) {
        val mediaController = controller ?: return
        mediaController.seekTo((mediaController.currentPosition - stepMs).coerceAtLeast(0L))
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
}
EOF

echo "  -> app/src/main/java/com/elg/music/playback/MusicPlaybackService.kt"
mkdir -p app/src/main/java/com/elg/music/playback
cat << 'EOF' > app/src/main/java/com/elg/music/playback/MusicPlaybackService.kt
package com.elg.music.playback

import android.app.PendingIntent
import android.content.Intent
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.session.MediaSession
import androidx.media3.session.MediaSessionService
import com.elg.music.ui.main.MainActivity
import com.google.common.util.concurrent.Futures
import com.google.common.util.concurrent.ListenableFuture

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
 */
class MusicPlaybackService : MediaSessionService() {

    private var mediaSession: MediaSession? = null
    private var artworkLoader: ArtworkBitmapLoader? = null
    private var midiCompanion: MidiCompanion? = null

    override fun onCreate() {
        super.onCreate()

        val audioAttributes = AudioAttributes.Builder()
            .setUsage(C.USAGE_MEDIA)
            .setContentType(C.AUDIO_CONTENT_TYPE_MUSIC)
            .build()

        val player = ExoPlayer.Builder(this)
            .setAudioAttributes(audioAttributes, /* handleAudioFocus= */ true)
            .setHandleAudioBecomingNoisy(true)
            .build()

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
    }

    override fun onGetSession(controllerInfo: MediaSession.ControllerInfo): MediaSession? {
        return mediaSession
    }

    /** Arrête le service si rien ne joue lorsque l'utilisateur retire l'app des tâches récentes. */
    override fun onTaskRemoved(rootIntent: Intent?) {
        val session = mediaSession ?: return
        if (!session.player.playWhenReady || session.player.mediaItemCount == 0) {
            stopSelf()
        }
    }

    override fun onDestroy() {
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
import com.elg.music.data.repository.TitleCleaner
import com.elg.music.databinding.ActivityMainBinding
import com.elg.music.databinding.DialogPlaylistNameBinding
import com.elg.music.playback.MidiSupport
import com.elg.music.playback.PlayerController
import com.elg.music.ui.ArtworkLoader
import com.elg.music.ui.about.AboutDialog
import com.elg.music.ui.applySystemBarPadding
import com.elg.music.ui.player.PlayerUi
import com.elg.music.ui.player.QueueSheet
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
        val song = libraryViewModel.findSong(mediaId)
        if (song == null) {
            Toast.makeText(this, R.string.player_menu_unavailable, Toast.LENGTH_SHORT).show()
            return
        }
        songActions.showPlayerMenu(anchor, song)
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

import android.os.Bundle
import androidx.appcompat.app.AppCompatDelegate
import androidx.preference.ListPreference
import androidx.preference.Preference
import androidx.preference.PreferenceFragmentCompat
import com.elg.music.R
import com.elg.music.ui.about.AboutDialog

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
        val bitmap = try {
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
import android.util.Size
import android.widget.ImageView
import androidx.annotation.DrawableRes
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

    private val resolver = context.applicationContext.contentResolver

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

    private fun readThumbnail(uri: Uri, sizePx: Int): Bitmap? =
        try {
            resolver.loadThumbnail(uri, Size(sizePx, sizePx), null)
        } catch (noArtwork: Exception) {
            null
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

    /** Revient aux valeurs d'une installation neuve (réinitialisation usine). */
    suspend fun resetAll() {
        store.edit { it.clear() }
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
    }
}
EOF

echo "  -> app/src/main/java/com/elg/music/data/local/ElgDatabase.kt"
mkdir -p app/src/main/java/com/elg/music/data/local
cat << 'EOF' > app/src/main/java/com/elg/music/data/local/ElgDatabase.kt
package com.elg.music.data.local

import android.content.Context
import androidx.room.Dao
import androidx.room.Database
import androidx.room.Delete
import androidx.room.Entity
import androidx.room.Insert
import androidx.room.PrimaryKey
import androidx.room.Query
import androidx.room.Room
import androidx.room.RoomDatabase
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
 * Base Room locale de l'application. Elle reste volontairement petite : les favoris, la liste noire,
 * les playlists et le tri restent dans leurs stockages actuels, pour ne rien casser du socle v1.3.
 */
@Database(entities = [VaultEntryEntity::class], version = 1, exportSchema = false)
abstract class ElgDatabase : RoomDatabase() {

    abstract fun vaultDao(): VaultDao

    companion object {
        private const val DATABASE_NAME = "elg_music.db"

        @Volatile
        private var instance: ElgDatabase? = null

        fun get(context: Context): ElgDatabase =
            instance ?: synchronized(this) {
                instance ?: Room.databaseBuilder(
                    context.applicationContext,
                    ElgDatabase::class.java,
                    DATABASE_NAME
                ).build().also { instance = it }
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
        R.id.action_delete_song -> {
            confirmAndDelete(song)
            true
        }
        else -> false
    }

    /** Menu d'options du grand lecteur, accroché au bouton « Plus d'options ». */
    fun showPlayerMenu(anchor: View, song: Song) {
        val popup = PopupMenu(activity, anchor)
        popup.menuInflater.inflate(R.menu.menu_player_options, popup.menu)
        popup.setOnMenuItemClickListener { item -> handleMenuItem(item.itemId, song) }
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
        android:id="@+id/action_share_song"
        android:title="@string/song_menu_share" />

    <item
        android:id="@+id/action_delete_song"
        android:title="@string/song_menu_delete" />

</menu>
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

echo "[3/3] Verification rapide de la presence des fichiers cles..."
MISSING=0
if [ ! -s "app/debug.keystore" ]; then echo "MANQUANT: app/debug.keystore"; MISSING=1; fi
if [ ! -f "app/src/main/java/com/elg/music/data/local/SettingsRepository.kt" ]; then echo "MANQUANT: app/src/main/java/com/elg/music/data/local/SettingsRepository.kt"; MISSING=1; fi
if [ ! -f "app/src/main/java/com/elg/music/data/local/ElgDatabase.kt" ]; then echo "MANQUANT: app/src/main/java/com/elg/music/data/local/ElgDatabase.kt"; MISSING=1; fi
if [ ! -f "app/src/main/java/com/elg/music/ui/main/SongActions.kt" ]; then echo "MANQUANT: app/src/main/java/com/elg/music/ui/main/SongActions.kt"; MISSING=1; fi
if [ ! -f "app/src/main/res/menu/menu_player_options.xml" ]; then echo "MANQUANT: app/src/main/res/menu/menu_player_options.xml"; MISSING=1; fi
if [ ! -f "app/build.gradle" ]; then echo "MANQUANT: app/build.gradle"; MISSING=1; fi
if [ ! -f "app/src/main/java/com/elg/music/ui/main/MainActivity.kt" ]; then echo "MANQUANT: app/src/main/java/com/elg/music/ui/main/MainActivity.kt"; MISSING=1; fi
if [ ! -f "app/src/main/java/com/elg/music/playback/MusicPlaybackService.kt" ]; then echo "MANQUANT: app/src/main/java/com/elg/music/playback/MusicPlaybackService.kt"; MISSING=1; fi
if [ ! -f ".github/workflows/build.yml" ]; then echo "MANQUANT: .github/workflows/build.yml"; MISSING=1; fi
if [ "$MISSING" -eq 0 ]; then
  echo ""
  echo "=== ELG MUSIC : PROJET ET WORKFLOW GITHUB ACTIONS INSTALLES AVEC SUCCES ==="
  echo "Commitez et poussez ces fichiers (y compris .github/workflows/build.yml), le workflow se declenchera automatiquement."
else
  echo "Des fichiers cles sont manquants, verifiez les erreurs ci-dessus."
  exit 1
fi
