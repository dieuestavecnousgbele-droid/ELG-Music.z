#!/usr/bin/env bash
set -e

echo "=== ELG Music : projet complet + workflow GitHub Actions ==="
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

echo "[2/3] Ecriture des 44 fichiers..."
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
cat << 'EOF' > app/build.gradle
apply plugin: 'com.android.application'
apply plugin: 'kotlin-android'

android {
    namespace 'com.elg.music'
    compileSdk 36

    defaultConfig {
        applicationId 'com.elg.music'
        minSdk 33
        targetSdk 36
        versionCode 2
        versionName '1.01'

        testInstrumentationRunner 'androidx.test.runner.AndroidJUnitRunner'
    }

    buildTypes {
        release {
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

    // --- Firebase : ajouté dès que google-services.json est fourni ---

    // --- Tests ---
    testImplementation 'junit:junit:4.13.2'
    androidTestImplementation 'androidx.test.ext:junit:1.3.0'
    androidTestImplementation 'androidx.test.espresso:espresso-core:3.7.0'
}
EOF

echo "  -> app/proguard-rules.pro"
cat << 'EOF' > app/proguard-rules.pro
# Règles ProGuard/R8 propres à ELG Music.
# Media3 embarque ses propres règles consommateur : aucune règle globale n'est nécessaire.
EOF

echo "  -> app/src/main/AndroidManifest.xml"
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
            android:launchMode="singleTop"
            android:windowSoftInputMode="adjustResize">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
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
            </intent-filter>
        </service>

    </application>

</manifest>
EOF

echo "  -> app/src/main/res/values/strings.xml"
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

    <!-- Même ordre que l'énumération SortOrder : A-Z, Z-A, plus récents, plus anciens -->
    <string-array name="sort_option_labels">
        <item>Nom du titre (A à Z)</item>
        <item>Nom du titre (Z à A)</item>
        <item>Date d\'ajout (plus récents en premier)</item>
        <item>Date d\'ajout (plus anciens en premier)</item>
    </string-array>

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
cat << 'EOF' > app/src/main/res/values/colors.xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#1F2A44</color>
</resources>
EOF

echo "  -> app/src/main/res/xml/root_preferences.xml"
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
cat << 'EOF' > app/src/main/res/mipmap-anydpi/ic_launcher.xml
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
    <monochrome android:drawable="@drawable/ic_launcher_foreground" />
</adaptive-icon>
EOF

echo "  -> app/src/main/res/mipmap-anydpi/ic_launcher_round.xml"
cat << 'EOF' > app/src/main/res/mipmap-anydpi/ic_launcher_round.xml
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
    <monochrome android:drawable="@drawable/ic_launcher_foreground" />
</adaptive-icon>
EOF

echo "  -> app/src/main/res/menu/menu_main.xml"
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
cat << 'EOF' > app/src/main/res/menu/menu_song_item.xml
<?xml version="1.0" encoding="utf-8"?>
<menu xmlns:android="http://schemas.android.com/apk/res/android">

    <item
        android:id="@+id/action_toggle_favorite"
        android:title="@string/song_menu_add_favorite" />

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
        app:title="@string/app_name"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toTopOf="parent" />

    <androidx.appcompat.widget.SearchView
        android:id="@+id/searchView"
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:background="?attr/colorSurface"
        android:paddingBottom="4dp"
        app:iconifiedByDefault="false"
        app:queryHint="@string/search_hint"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toBottomOf="@id/toolbar" />

    <com.google.android.material.tabs.TabLayout
        android:id="@+id/tabLayoutFilters"
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:background="?attr/colorSurface"
        app:tabGravity="start"
        app:tabMode="scrollable"
        app:layout_constraintEnd_toStartOf="@id/buttonSort"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toBottomOf="@id/searchView">

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
        app:layout_constraintTop_toBottomOf="@id/tabLayoutFilters"
        tools:listitem="@layout/item_song" />

    <ProgressBar
        android:id="@+id/progressLoading"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        app:layout_constraintBottom_toTopOf="@id/miniPlayer"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toBottomOf="@id/tabLayoutFilters" />

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
        app:layout_constraintTop_toBottomOf="@id/tabLayoutFilters" />

    <include
        android:id="@+id/miniPlayer"
        layout="@layout/layout_mini_player"
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent" />

</androidx.constraintlayout.widget.ConstraintLayout>
EOF

echo "  -> app/src/main/res/layout/activity_settings.xml"
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
cat << 'EOF' > app/src/main/res/layout/layout_mini_player.xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    xmlns:tools="http://schemas.android.com/tools"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:background="?attr/colorSurface"
    android:elevation="8dp"
    android:orientation="vertical"
    tools:visibility="visible">

    <com.google.android.material.progressindicator.LinearProgressIndicator
        android:id="@+id/progressMini"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:max="100"
        app:trackThickness="2dp" />

    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:gravity="center_vertical"
        android:minHeight="64dp"
        android:orientation="horizontal"
        android:paddingStart="16dp"
        android:paddingTop="4dp"
        android:paddingEnd="12dp"
        android:paddingBottom="4dp">

        <LinearLayout
            android:layout_width="0dp"
            android:layout_height="wrap_content"
            android:layout_marginEnd="8dp"
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
                android:textAppearance="?attr/textAppearanceBodyMedium"
                android:textColor="?attr/colorOnSurfaceVariant"
                android:visibility="gone"
                tools:text="Artiste"
                tools:visibility="visible" />

        </LinearLayout>

        <ImageButton
            android:id="@+id/buttonMiniPrevious"
            android:layout_width="48dp"
            android:layout_height="48dp"
            android:background="?attr/selectableItemBackgroundBorderless"
            android:contentDescription="@string/mini_player_previous_description"
            android:src="@drawable/ic_skip_previous"
            app:tint="?attr/colorOnSurface" />

        <ImageButton
            android:id="@+id/buttonMiniPlayPause"
            android:layout_width="48dp"
            android:layout_height="48dp"
            android:layout_marginStart="4dp"
            android:background="?attr/selectableItemBackgroundBorderless"
            android:contentDescription="@string/mini_player_play_description"
            android:src="@drawable/ic_play_arrow"
            app:tint="?attr/colorOnSurface" />

        <ImageButton
            android:id="@+id/buttonMiniNext"
            android:layout_width="48dp"
            android:layout_height="48dp"
            android:layout_marginStart="4dp"
            android:background="?attr/selectableItemBackgroundBorderless"
            android:contentDescription="@string/mini_player_next_description"
            android:src="@drawable/ic_skip_next"
            app:tint="?attr/colorOnSurface" />

    </LinearLayout>

</LinearLayout>
EOF

echo "  -> app/src/main/res/layout/item_song.xml"
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
 */
data class Song(
    val id: Long,
    val title: String,
    val artist: String?,
    val album: String?,
    val durationMs: Long,
    val contentUri: Uri,
    val albumId: Long,
    val dateAddedSeconds: Long = 0L
)
EOF

echo "  -> app/src/main/java/com/elg/music/data/repository/SongRepository.kt"
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
 * Applique automatiquement deux filtres du cahier des charges (section 5) :
 *  - exclusion des dossiers de messagerie (WhatsApp, Telegram, mémos vocaux) ;
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
            pathColumn
        )

        val selection = "${MediaStore.Audio.Media.IS_MUSIC} != 0"

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
                        dateAddedSeconds = dateAddedSeconds
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

        private val EXCLUDED_FOLDER_KEYWORDS = listOf(
            "whatsapp audio",
            "whatsapp voice notes",
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
cat << 'EOF' > app/src/main/java/com/elg/music/playback/PlayerController.kt
package com.elg.music.playback

import android.content.ComponentName
import android.content.Context
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

/** État de lecture exposé à l'interface (mini-lecteur). */
data class PlaybackUiState(
    val isConnected: Boolean = false,
    val isPlaying: Boolean = false,
    val title: String? = null,
    val artist: String? = null,
    val positionMs: Long = 0L,
    val durationMs: Long = 0L
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

    private val _state = MutableStateFlow(PlaybackUiState())
    val state: StateFlow<PlaybackUiState> = _state.asStateFlow()

    private val playerListener = object : Player.Listener {
        override fun onIsPlayingChanged(isPlaying: Boolean) {
            _state.update { it.copy(isPlaying = isPlaying) }
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
            _state.update {
                it.copy(
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
            _state.update {
                it.copy(
                    isConnected = true,
                    isPlaying = mediaController.isPlaying,
                    title = mediaController.mediaMetadata.title?.toString(),
                    artist = mediaController.mediaMetadata.artist?.toString(),
                    positionMs = mediaController.currentPosition.coerceAtLeast(0L),
                    durationMs = mediaController.duration.coerceAtLeast(0L)
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

    /** Construit la file d'attente à partir des morceaux visibles et lance la lecture à [startIndex]. */
    fun playSongs(mediaItems: List<MediaItem>, startIndex: Int) {
        controller?.apply {
            setMediaItems(mediaItems, startIndex, 0L)
            prepare()
            play()
        }
    }

    fun togglePlayPause() {
        controller?.apply {
            if (isPlaying) pause() else play()
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
cat << 'EOF' > app/src/main/java/com/elg/music/playback/MusicPlaybackService.kt
package com.elg.music.playback

import android.app.PendingIntent
import android.content.Intent
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.session.MediaSession
import androidx.media3.session.MediaSessionService
import com.elg.music.ui.main.MainActivity

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
 */
class MusicPlaybackService : MediaSessionService() {

    private var mediaSession: MediaSession? = null
    private var artworkLoader: ArtworkBitmapLoader? = null

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

        mediaSession = MediaSession.Builder(this, player)
            .setSessionActivity(sessionActivityPendingIntent)
            .setBitmapLoader(bitmapLoader)
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
cat << 'EOF' > app/src/main/java/com/elg/music/ui/main/LibraryViewModel.kt
package com.elg.music.ui.main

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.elg.music.data.local.LibraryPreferences
import com.elg.music.data.model.Song
import com.elg.music.data.model.SortOrder
import com.elg.music.data.repository.SongRepository
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.text.CollationKey
import java.text.Collator
import java.util.Locale

/**
 * Mode d'affichage sélectionné dans la barre d'onglets.
 * Seuls TITRES et FAVORIS ont une logique réelle pour cet incrément ; les autres onglets
 * (Artistes, Albums, Playlists, Dossiers) sont visibles mais annoncent "Bientôt disponible".
 */
enum class LibraryFilter { TITRES, FAVORIS }

/**
 * État affiché par [com.elg.music.ui.main.MainActivity].
 *
 * [allSongs] est la bibliothèque complète (hors morceaux mis en liste noire), déjà triée selon
 * [sortOrder]. [visibleSongs] est la liste réellement affichée, après filtrage par [activeFilter]
 * et [searchQuery] ; le filtrage conserve l'ordre de tri.
 */
data class LibraryUiState(
    val isLoading: Boolean = true,
    val allSongs: List<Song> = emptyList(),
    val visibleSongs: List<Song> = emptyList(),
    val searchQuery: String = "",
    val activeFilter: LibraryFilter = LibraryFilter.TITRES,
    val sortOrder: SortOrder = SortOrder.DEFAULT
)

class LibraryViewModel(application: Application) : AndroidViewModel(application) {

    private val repository = SongRepository(application)
    private val libraryPreferences = LibraryPreferences(application)

    private val _uiState = MutableStateFlow(LibraryUiState(sortOrder = libraryPreferences.getSortOrder()))
    val uiState: StateFlow<LibraryUiState> = _uiState.asStateFlow()

    /** Lance (ou relance) le chargement complet de la bibliothèque depuis le MediaStore. */
    fun loadLibrary() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            try {
                // Lecture du MediaStore et tri hors du thread principal ; si l'utilisateur change
                // de critère pendant le chargement, la liste est retriée avec le nouveau critère.
                val orderUsed = _uiState.value.sortOrder
                val songs = withContext(Dispatchers.IO) {
                    val library = repository.loadLibrary()
                        .filterNot { libraryPreferences.isBlacklisted(it.contentUri) }
                    sortSongs(library, orderUsed)
                }
                _uiState.update { current ->
                    val sortedSongs =
                        if (current.sortOrder == orderUsed) songs else sortSongs(songs, current.sortOrder)
                    current.copy(
                        isLoading = false,
                        allSongs = sortedSongs,
                        visibleSongs = applyFilters(sortedSongs, current.searchQuery, current.activeFilter)
                    )
                }
            } catch (cancellation: CancellationException) {
                throw cancellation
            } catch (error: Exception) {
                onLibraryUnavailable()
            }
        }
    }

    /** Arrête l'indicateur de chargement quand la bibliothèque ne peut pas être lue (permission refusée, erreur). */
    fun onLibraryUnavailable() {
        _uiState.update { current ->
            current.copy(
                isLoading = false,
                allSongs = emptyList(),
                visibleSongs = emptyList()
            )
        }
    }

    fun onSearchQueryChanged(query: String) {
        _uiState.update { current ->
            current.copy(
                searchQuery = query,
                visibleSongs = applyFilters(current.allSongs, query, current.activeFilter)
            )
        }
    }

    /** Change l'onglet actif (Titres/Favoris) et recalcule la liste visible en conséquence. */
    fun onFilterSelected(filter: LibraryFilter) {
        _uiState.update { current ->
            current.copy(
                activeFilter = filter,
                visibleSongs = applyFilters(current.allSongs, current.searchQuery, filter)
            )
        }
    }

    /**
     * Applique un nouveau critère de tri : l'enregistre pour les prochains lancements, retrie la
     * bibliothèque et recalcule la liste visible. Sans effet si le critère est déjà actif.
     */
    fun onSortOrderSelected(order: SortOrder) {
        if (order == _uiState.value.sortOrder) return
        libraryPreferences.setSortOrder(order)
        _uiState.update { current ->
            val sortedSongs = sortSongs(current.allSongs, order)
            current.copy(
                sortOrder = order,
                allSongs = sortedSongs,
                visibleSongs = applyFilters(sortedSongs, current.searchQuery, current.activeFilter)
            )
        }
    }

    fun isFavorite(song: Song): Boolean = libraryPreferences.isFavorite(song.contentUri)

    /** Bascule le statut favori, rafraîchit la vue (utile si l'onglet Favoris est actif), et renvoie le nouvel état. */
    fun toggleFavorite(song: Song): Boolean {
        val nowFavorite = libraryPreferences.toggleFavorite(song.contentUri)
        _uiState.update { current ->
            current.copy(
                visibleSongs = applyFilters(current.allSongs, current.searchQuery, current.activeFilter)
            )
        }
        return nowFavorite
    }

    /** Ajoute le morceau à la liste noire et le retire immédiatement de la vue. */
    fun blacklistSong(song: Song) {
        libraryPreferences.addToBlacklist(song.contentUri)
        removeSongLocally(song)
    }

    /** Retire le morceau de la bibliothèque affichée (par ex. après suppression physique confirmée). */
    fun removeSongLocally(song: Song) {
        _uiState.update { current ->
            val updatedAll = current.allSongs.filterNot { it.id == song.id }
            current.copy(
                allSongs = updatedAll,
                visibleSongs = applyFilters(updatedAll, current.searchQuery, current.activeFilter)
            )
        }
    }

    /**
     * Trie la bibliothèque. Le tri par titre ignore la casse et range les lettres accentuées
     * avec leur lettre de base (« Éléphant » parmi les E) grâce à un [Collator] ; à égalité,
     * l'ordre du MediaStore est conservé (le tri est stable). Le tri par date d'ajout
     * départage les ex æquo par titre.
     */
    private fun sortSongs(songs: List<Song>, order: SortOrder): List<Song> {
        // Les clés de collation sont calculées une seule fois par morceau : comparer des clés
        // est bien plus rapide que de comparer les titres deux à deux sur une grosse bibliothèque.
        val collator = Collator.getInstance(Locale.getDefault()).apply { strength = Collator.SECONDARY }
        val keyed = songs.map { KeyedSong(it, collator.getCollationKey(it.title)) }
        val sorted = when (order) {
            SortOrder.TITLE_ASC ->
                keyed.sortedWith(compareBy<KeyedSong> { it.titleKey })
            SortOrder.TITLE_DESC ->
                keyed.sortedWith(compareByDescending<KeyedSong> { it.titleKey })
            SortOrder.DATE_ADDED_NEWEST ->
                keyed.sortedWith(
                    compareByDescending<KeyedSong> { it.song.dateAddedSeconds }.thenBy { it.titleKey }
                )
            SortOrder.DATE_ADDED_OLDEST ->
                keyed.sortedWith(
                    compareBy<KeyedSong> { it.song.dateAddedSeconds }.thenBy { it.titleKey }
                )
        }
        return sorted.map { it.song }
    }

    private class KeyedSong(val song: Song, val titleKey: CollationKey)

    private fun applyFilters(songs: List<Song>, query: String, filter: LibraryFilter): List<Song> {
        val base = when (filter) {
            LibraryFilter.FAVORIS -> songs.filter { libraryPreferences.isFavorite(it.contentUri) }
            LibraryFilter.TITRES -> songs
        }
        if (query.isBlank()) return base
        val needle = query.trim()
        return base.filter { song ->
            song.title.contains(needle, ignoreCase = true) ||
                song.artist?.contains(needle, ignoreCase = true) == true
        }
    }
}
EOF

echo "  -> app/src/main/java/com/elg/music/ui/main/SongAdapter.kt"
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
cat << 'EOF' > app/src/main/java/com/elg/music/ui/main/MainActivity.kt
package com.elg.music.ui.main

import android.Manifest
import android.annotation.SuppressLint
import android.app.RecoverableSecurityException
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import android.provider.MediaStore
import android.view.Menu
import android.view.MenuItem
import android.view.MotionEvent
import android.view.View
import android.widget.PopupMenu
import android.widget.Toast
import androidx.activity.result.IntentSenderRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.appcompat.app.AppCompatDelegate
import androidx.appcompat.widget.SearchView
import androidx.core.content.ContextCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.repeatOnLifecycle
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.preference.PreferenceManager
import androidx.recyclerview.widget.LinearLayoutManager
import com.elg.music.R
import com.elg.music.data.model.Song
import com.elg.music.data.model.SortOrder
import com.elg.music.databinding.ActivityMainBinding
import com.elg.music.playback.PlaybackUiState
import com.elg.music.playback.PlayerController
import com.elg.music.ui.about.AboutDialog
import com.elg.music.ui.applySystemBarPadding
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
    private var progressJob: Job? = null
    private var seekHoldJob: Job? = null
    private var seekHoldTriggered = false
    private var pendingDeleteSong: Song? = null
    private var lastAppliedSortOrder: SortOrder? = null

    private val libraryViewModel: LibraryViewModel by lazy {
        ViewModelProvider(
            this,
            ViewModelProvider.AndroidViewModelFactory.getInstance(application)
        ).get(LibraryViewModel::class.java)
    }

    private val playerController: PlayerController by lazy { PlayerController(this) }

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

    private val deleteRequestLauncher = registerForActivityResult(
        ActivityResultContracts.StartIntentSenderForResult()
    ) { result ->
        val song = pendingDeleteSong
        pendingDeleteSong = null
        if (result.resultCode == RESULT_OK && song != null) {
            libraryViewModel.removeSongLocally(song)
            Toast.makeText(this, getString(R.string.song_deleted_message, song.title), Toast.LENGTH_SHORT).show()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        applyStoredTheme()
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)
        binding.root.applySystemBarPadding()
        setSupportActionBar(binding.toolbar)

        setupRecyclerView()
        setupSearch()
        setupFilterTabs()
        setupSortButton()
        setupMiniPlayerControls()
        observeLibraryState()
        observePlayerState()

        if (hasRequiredPermissions()) {
            libraryViewModel.loadLibrary()
        } else {
            permissionLauncher.launch(requiredPermissions())
        }
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
        seekHoldJob?.cancel()
        seekHoldJob = null
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

    // ===================== Liste des morceaux =====================

    private fun setupRecyclerView() {
        songAdapter = SongAdapter(
            onSongClicked = ::onSongClicked,
            onMenuClicked = ::showSongMenu
        )
        binding.recyclerSongs.layoutManager = LinearLayoutManager(this)
        binding.recyclerSongs.adapter = songAdapter
    }

    private fun setupSearch() {
        binding.searchView.setOnQueryTextListener(object : SearchView.OnQueryTextListener {
            override fun onQueryTextSubmit(query: String?): Boolean = false

            override fun onQueryTextChange(newText: String?): Boolean {
                libraryViewModel.onSearchQueryChanged(newText.orEmpty())
                return true
            }
        })
    }

    /**
     * Barre de filtres (Titres, Artistes, Albums, Playlists, Favoris, Dossiers).
     * Seuls Titres (position 0) et Favoris (position 4) ont une logique réelle pour cet
     * incrément ; les autres onglets restent visibles (conformément au cahier des charges)
     * mais annoncent honnêtement qu'ils ne sont pas encore disponibles plutôt que de filtrer
     * silencieusement de façon incorrecte.
     */
    private fun setupFilterTabs() {
        binding.tabLayoutFilters.addOnTabSelectedListener(object : TabLayout.OnTabSelectedListener {
            override fun onTabSelected(tab: TabLayout.Tab) {
                when (tab.position) {
                    TAB_POSITION_TITLES -> libraryViewModel.onFilterSelected(LibraryFilter.TITRES)
                    TAB_POSITION_FAVORITES -> libraryViewModel.onFilterSelected(LibraryFilter.FAVORIS)
                    else -> Toast.makeText(
                        this@MainActivity,
                        R.string.filter_not_available_message,
                        Toast.LENGTH_SHORT
                    ).show()
                }
            }

            override fun onTabUnselected(tab: TabLayout.Tab) = Unit

            override fun onTabReselected(tab: TabLayout.Tab) = Unit
        })
    }

    /**
     * Bouton « Trier par » placé à droite de la barre de filtres : ouvre une boîte de dialogue à
     * choix unique (annoncée correctement par TalkBack) avec le critère actuel présélectionné.
     * Le choix est enregistré par le ViewModel et restauré au prochain lancement.
     */
    private fun setupSortButton() {
        binding.buttonSort.setOnClickListener { showSortDialog() }
    }

    private fun showSortDialog() {
        val labels = resources.getStringArray(R.array.sort_option_labels)
        val orders = SortOrder.entries
        val checkedIndex = orders.indexOf(libraryViewModel.uiState.value.sortOrder)
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

    private fun observeLibraryState() {
        lifecycleScope.launch {
            repeatOnLifecycle(Lifecycle.State.STARTED) {
                libraryViewModel.uiState.collect { state ->
                    // Après un changement de tri, on revient en haut de la liste pour voir le nouvel ordre.
                    val sortChanged =
                        lastAppliedSortOrder != null && state.sortOrder != lastAppliedSortOrder
                    lastAppliedSortOrder = state.sortOrder
                    songAdapter.submitList(state.visibleSongs) {
                        if (sortChanged) binding.recyclerSongs.scrollToPosition(0)
                    }
                    binding.progressLoading.visibility = if (state.isLoading) View.VISIBLE else View.GONE
                    val isEmpty = !state.isLoading && state.visibleSongs.isEmpty()
                    binding.textEmptyState.visibility = if (isEmpty) View.VISIBLE else View.GONE
                    binding.recyclerSongs.visibility =
                        if (isEmpty || state.isLoading) View.GONE else View.VISIBLE
                }
            }
        }
    }

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
            .build()
        return MediaItem.Builder()
            .setMediaId(song.id.toString())
            .setUri(song.contentUri)
            .setMediaMetadata(metadata)
            .build()
    }

    // ===================== Menu contextuel par morceau =====================

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

        popup.setOnMenuItemClickListener { item ->
            when (item.itemId) {
                R.id.action_toggle_favorite -> {
                    val nowFavorite = libraryViewModel.toggleFavorite(song)
                    val messageRes =
                        if (nowFavorite) R.string.favorite_added_message else R.string.favorite_removed_message
                    Toast.makeText(this, getString(messageRes, song.title), Toast.LENGTH_SHORT).show()
                    true
                }
                R.id.action_hide_song -> {
                    libraryViewModel.blacklistSong(song)
                    Toast.makeText(this, getString(R.string.song_hidden_message, song.title), Toast.LENGTH_SHORT)
                        .show()
                    true
                }
                R.id.action_share_song -> {
                    shareSong(song)
                    true
                }
                R.id.action_delete_song -> {
                    confirmAndDeleteSong(song)
                    true
                }
                else -> false
            }
        }
        popup.show()
    }

    private fun shareSong(song: Song) {
        val shareIntent = Intent(Intent.ACTION_SEND).apply {
            type = "audio/*"
            putExtra(Intent.EXTRA_STREAM, song.contentUri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        startActivity(Intent.createChooser(shareIntent, getString(R.string.share_chooser_title)))
    }

    private fun confirmAndDeleteSong(song: Song) {
        MaterialAlertDialogBuilder(this)
            .setTitle(R.string.delete_dialog_title)
            .setMessage(getString(R.string.delete_dialog_message, song.title))
            .setPositiveButton(R.string.delete_dialog_confirm) { _, _ -> deleteSong(song) }
            .setNegativeButton(R.string.delete_dialog_cancel, null)
            .show()
    }

    private fun deleteSong(song: Song) {
        try {
            contentResolver.delete(song.contentUri, null, null)
            libraryViewModel.removeSongLocally(song)
            Toast.makeText(this, getString(R.string.song_deleted_message, song.title), Toast.LENGTH_SHORT).show()
        } catch (security: SecurityException) {
            // Fichier appartenant à une autre application : sur Android 11+ la suppression passe par
            // une demande de confirmation du système (createDeleteRequest). Si l'exception fournit
            // déjà une action récupérable, on l'utilise en priorité.
            val intentSender = (security as? RecoverableSecurityException)
                ?.userAction?.actionIntent?.intentSender
                ?: MediaStore.createDeleteRequest(contentResolver, listOf(song.contentUri)).intentSender
            pendingDeleteSong = song
            deleteRequestLauncher.launch(IntentSenderRequest.Builder(intentSender).build())
        }
    }

    // ===================== Mini-lecteur =====================

    private fun setupMiniPlayerControls() {
        binding.miniPlayer.buttonMiniPlayPause.setOnClickListener { playerController.togglePlayPause() }
        setupHoldToSeek(binding.miniPlayer.buttonMiniPrevious, isForward = false)
        setupHoldToSeek(binding.miniPlayer.buttonMiniNext, isForward = true)
    }

    /**
     * Clic simple = morceau précédent/suivant. Appui long = avance/recul continu par tranches
     * de [SEEK_STEP_MS] tant que le bouton est maintenu, sans bloquer le thread UI (coroutine).
     * `performClick()` est appelé explicitement pour préserver le comportement d'accessibilité
     * standard (TalkBack) puisque le clic simple est désormais détecté via `setOnTouchListener`.
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
                    seekHoldJob = lifecycleScope.launch {
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
                    seekHoldJob?.cancel()
                    seekHoldJob = null
                    if (!seekHoldTriggered) {
                        view.performClick()
                    }
                    true
                }
                MotionEvent.ACTION_CANCEL -> {
                    seekHoldJob?.cancel()
                    seekHoldJob = null
                    true
                }
                else -> false
            }
        }
    }

    private fun observePlayerState() {
        lifecycleScope.launch {
            repeatOnLifecycle(Lifecycle.State.STARTED) {
                playerController.state.collect { state -> updateMiniPlayer(state) }
            }
        }
    }

    private fun updateMiniPlayer(state: PlaybackUiState) {
        val hasTrack = state.title != null
        binding.miniPlayer.root.visibility = if (hasTrack) View.VISIBLE else View.GONE
        if (!hasTrack) return

        binding.miniPlayer.textMiniTitle.text = state.title
        if (state.artist != null) {
            binding.miniPlayer.textMiniArtist.text = state.artist
            binding.miniPlayer.textMiniArtist.visibility = View.VISIBLE
        } else {
            binding.miniPlayer.textMiniArtist.visibility = View.GONE
        }

        binding.miniPlayer.buttonMiniPlayPause.setImageResource(
            if (state.isPlaying) R.drawable.ic_pause else R.drawable.ic_play_arrow
        )
        binding.miniPlayer.buttonMiniPlayPause.contentDescription = getString(
            if (state.isPlaying) R.string.mini_player_pause_description else R.string.mini_player_play_description
        )

        if (state.durationMs > 0) {
            binding.miniPlayer.progressMini.max = state.durationMs.toInt()
            binding.miniPlayer.progressMini.setProgressCompat(state.positionMs.toInt(), true)
        }
    }

    private companion object {
        private const val TAB_POSITION_TITLES = 0
        private const val TAB_POSITION_FAVORITES = 4
        private const val LONG_PRESS_THRESHOLD_MS = 500L
        private const val SEEK_STEP_MS = 5000L
        private const val SEEK_REPEAT_INTERVAL_MS = 400L
    }
}
EOF

echo "  -> app/src/main/java/com/elg/music/ui/about/AboutDialog.kt"
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

      - name: Set up Gradle 8.13
        uses: gradle/actions/setup-gradle@v6
        with:
          gradle-version: '8.13'

      - name: Build debug APK
        run: gradle assembleDebug --no-daemon --stacktrace

      - name: Upload APK artifact
        uses: actions/upload-artifact@v7
        with:
          name: elg-music-debug-apk
          path: app/build/outputs/apk/debug/*.apk
EOF

echo "  -> app/src/main/java/com/elg/music/data/model/SortOrder.kt"
cat << 'EOF' > app/src/main/java/com/elg/music/data/model/SortOrder.kt
package com.elg.music.data.model

/**
 * Critères de tri de la liste des titres (bouton « Trier par »).
 *
 * [storageKey] est la valeur écrite dans les préférences : elle est volontairement distincte
 * du nom de l'énumération et de son ordinal, pour que renommer ou réordonner les cas plus tard
 * ne casse pas le choix déjà enregistré par l'utilisateur.
 */
enum class SortOrder(val storageKey: String) {
    TITLE_ASC("title_asc"),
    TITLE_DESC("title_desc"),
    DATE_ADDED_NEWEST("date_added_newest"),
    DATE_ADDED_OLDEST("date_added_oldest");

    companion object {
        val DEFAULT = TITLE_ASC

        /** Retrouve un critère depuis sa clé enregistrée ; retombe sur [DEFAULT] si inconnue ou absente. */
        fun fromStorageKey(key: String?): SortOrder =
            entries.firstOrNull { it.storageKey == key } ?: DEFAULT
    }
}
EOF

echo "  -> app/src/main/java/com/elg/music/data/repository/TitleCleaner.kt"
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

echo "[3/3] Verification rapide de la presence des fichiers cles..."
MISSING=0
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
