#!/usr/bin/env bash
# ============================================================================
# ELG Music v1.6 - MODULE 3 (Reglages) - Increment 1
# A executer APRES setup_elg_full.sh (voir build.yml) : il ETEND le projet
# genere, sans rien supprimer. Idempotent : peut etre relance sans risque.
#
# Ajoute :
#   [F] Exporter / Restaurer les reglages (elg_settings_config.json)
#   [F] Reinitialisation usine (PIN verifie avant effacement)
#   [A] Saut des silences (ExoPlayer)
#   [G] Raccourci vers les autorisations de l'application
# Reutilise : SettingsRepository / AppSettings / AudioEffectsController /
#             VaultPinStore / PinDialogs / SleepTimerHub (v1.5, inchanges).
# ============================================================================
set -euo pipefail

BASE="app/src/main/java/com/elg/music"
RES="app/src/main/res"

if [ ! -f "$BASE/data/local/SettingsRepository.kt" ]; then
  echo "ERREUR : projet absent. Lancez d'abord : bash setup_elg_full.sh"
  exit 1
fi

echo "[v1.6/M3] Creation des nouveaux fichiers..."

# ----------------------------------------------------------------------------
# 1. Format JSON de sauvegarde (schema CLAUDE.md 4.A + skip_silence)
# ----------------------------------------------------------------------------
echo "  -> $BASE/data/local/SettingsBackup.kt"
cat << 'EOF' > "$BASE/data/local/SettingsBackup.kt"
package com.elg.music.data.local

import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject
import kotlin.math.roundToInt

/**
 * Sauvegarde et restauration des réglages avancés dans `elg_settings_config.json`
 * (schéma de CLAUDE.md, section 4.A). Les clés absentes reprennent leur valeur par défaut, si bien
 * qu'un fichier de la v1.4 ou de la v1.5 reste importable.
 *
 * L'import est STRICT : un fichier qui n'est pas d'ELG Music, ou dont une valeur sort des plages
 * prévues, est refusé en entier (rien n'est appliqué). Le code PIN du coffre-fort n'est jamais exporté.
 */
object SettingsBackup {

    const val FILE_NAME = "elg_settings_config.json"

    private const val PACKAGE_NAME = "com.elg.music"
    private const val FORMAT_VERSION = 1.6
    private const val MIN_VERSION = 1.4
    private const val VERSION_EPSILON = 0.0001
    private const val MAX_SLEEP_MINUTES = 1440
    private const val MAX_THEME_LENGTH = 32

    fun toJson(settings: AppSettings): String {
        val audio = JSONObject()
            .put("equalizer_enabled", settings.equalizerEnabled)
            .put("band_levels", JSONArray(settings.bandLevels))
            .put("bass_boost", settings.bassBoost)
            .put("virtualizer", settings.virtualizer)
            .put("playback_speed", settings.playbackSpeed.round2())
            .put("playback_pitch", settings.playbackPitch.round2())
        val preferences = JSONObject()
            .put("sleep_timer_default", settings.sleepTimerDefaultMin)
            .put("fade_out_enabled", settings.fadeOutEnabled)
            .put("drive_mode_theme", settings.driveModeTheme)
            .put("skip_silence", settings.skipSilence)
        return JSONObject()
            .put("package", PACKAGE_NAME)
            .put("version", FORMAT_VERSION)
            .put("audio_settings", audio)
            .put("app_preferences", preferences)
            .toString(2)
    }

    /** @throws IllegalArgumentException avec un message lisible si le fichier est refusé. */
    fun fromJson(text: String): AppSettings {
        val root = try {
            JSONObject(text)
        } catch (error: JSONException) {
            fail("ce n'est pas un fichier JSON valide")
        }
        if (root.optString("package") != PACKAGE_NAME) fail("ce fichier ne provient pas d'ELG Music")
        val version = root.optDouble("version", Double.NaN)
        if (version.isNaN() || version < MIN_VERSION - VERSION_EPSILON || version > FORMAT_VERSION + VERSION_EPSILON) {
            fail("version de configuration non prise en charge")
        }

        val defaults = AppSettings()
        val audio = root.optJSONObject("audio_settings") ?: JSONObject()
        val preferences = root.optJSONObject("app_preferences") ?: JSONObject()

        val bandsJson = audio.optJSONArray("band_levels")
        val bands = if (bandsJson == null) {
            defaults.bandLevels
        } else {
            if (bandsJson.length() != AppSettings.BAND_COUNT) fail("l'égaliseur doit comporter 5 niveaux")
            List(AppSettings.BAND_COUNT) { index ->
                val level = bandsJson.optInt(index, Int.MIN_VALUE)
                if (level < -AudioRanges.MAX_BAND_DB || level > AudioRanges.MAX_BAND_DB) {
                    fail("niveau d'égaliseur hors limites (±${AudioRanges.MAX_BAND_DB} dB)")
                }
                level
            }
        }

        val bass = audio.optInt("bass_boost", defaults.bassBoost)
        if (bass !in 0..100) fail("Bass Boost hors limites (0 à 100)")
        val virtualizer = audio.optInt("virtualizer", defaults.virtualizer)
        if (virtualizer !in 0..100) fail("spatialisation hors limites (0 à 100)")

        val speed = audio.optDouble("playback_speed", defaults.playbackSpeed.toDouble()).toFloat()
        if (speed.isNaN() || speed < AudioRanges.MIN_SPEED || speed > AudioRanges.MAX_SPEED) {
            fail("vitesse hors limites (0,25x à 2,5x)")
        }
        val pitch = audio.optDouble("playback_pitch", defaults.playbackPitch.toDouble()).toFloat()
        if (pitch.isNaN() || pitch < AudioRanges.MIN_PITCH || pitch > AudioRanges.MAX_PITCH) {
            fail("tonalité hors limites (0,5x à 2,0x)")
        }

        val sleepDefault = preferences.optInt("sleep_timer_default", defaults.sleepTimerDefaultMin)
        if (sleepDefault !in 0..MAX_SLEEP_MINUTES) fail("durée du minuteur hors limites")
        val theme = preferences.optString("drive_mode_theme", defaults.driveModeTheme)
        if (theme.isBlank() || theme.length > MAX_THEME_LENGTH) fail("thème du mode conduite invalide")

        return AppSettings(
            equalizerEnabled = audio.optBoolean("equalizer_enabled", defaults.equalizerEnabled),
            bandLevels = bands,
            bassBoost = bass,
            virtualizer = virtualizer,
            playbackSpeed = speed,
            playbackPitch = pitch,
            sleepTimerDefaultMin = sleepDefault,
            fadeOutEnabled = preferences.optBoolean("fade_out_enabled", defaults.fadeOutEnabled),
            driveModeTheme = theme,
            skipSilence = preferences.optBoolean("skip_silence", defaults.skipSilence)
        )
    }

    private fun fail(message: String): Nothing = throw IllegalArgumentException(message)

    private fun Float.round2(): Double = (this * 100f).roundToInt() / 100.0
}
EOF

# ----------------------------------------------------------------------------
# 2. Branchement des nouvelles lignes de Reglages
# ----------------------------------------------------------------------------
echo "  -> $BASE/ui/settings/SettingsMaintenance.kt"
cat << 'EOF' > "$BASE/ui/settings/SettingsMaintenance.kt"
package com.elg.music.ui.settings

import android.content.Intent
import android.net.Uri
import android.provider.Settings
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.appcompat.app.AppCompatDelegate
import androidx.lifecycle.lifecycleScope
import androidx.preference.ListPreference
import androidx.preference.Preference
import androidx.preference.PreferenceFragmentCompat
import androidx.preference.SwitchPreferenceCompat
import com.elg.music.R
import com.elg.music.data.local.AppSettings
import com.elg.music.data.local.SettingsBackup
import com.elg.music.data.local.SettingsRepository
import com.elg.music.data.local.VaultPinStore
import com.elg.music.playback.SleepTimerHub
import com.elg.music.playback.SleepTimerRequest
import com.elg.music.ui.vault.PinDialogs
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File

/**
 * Lignes de l'écran Réglages ajoutées en v1.6 (module 3) : saut des silences, autorisations,
 * export / restauration JSON et réinitialisation usine.
 *
 * S'installe depuis [SettingsFragment.onCreatePreferences] (les sélecteurs de fichiers doivent être
 * enregistrés avant la fin de la création du fragment). Tout passe par les classes existantes de la v1.5 :
 * [SettingsRepository], [VaultPinStore] et [PinDialogs].
 */
class SettingsMaintenance(private val fragment: PreferenceFragmentCompat) {

    private val appContext = fragment.requireContext().applicationContext
    private val repository = SettingsRepository(appContext)
    private val pinStore = VaultPinStore(appContext)

    private val activity: AppCompatActivity
        get() = fragment.requireActivity() as AppCompatActivity

    private val exportLauncher = fragment.registerForActivityResult(
        ActivityResultContracts.CreateDocument("application/json")
    ) { uri: Uri? ->
        if (uri != null) writeExport(uri)
    }

    private val importLauncher = fragment.registerForActivityResult(
        ActivityResultContracts.OpenDocument()
    ) { uri: Uri? ->
        if (uri != null) readImport(uri)
    }

    fun install() {
        fragment.findPreference<SwitchPreferenceCompat>(KEY_SKIP_SILENCE)?.let { preference ->
            // Valeur gardée dans le DataStore (SettingsRepository), pas dans les SharedPreferences.
            preference.isPersistent = false
            preference.setOnPreferenceChangeListener { _, newValue ->
                val enabled = newValue as Boolean
                fragment.lifecycleScope.launch { repository.setSkipSilence(enabled) }
                true
            }
            fragment.lifecycleScope.launch {
                repository.settings.collect { settings -> preference.isChecked = settings.skipSilence }
            }
        }

        fragment.findPreference<Preference>(KEY_PERMISSIONS)?.setOnPreferenceClickListener {
            val intent = Intent(
                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                Uri.fromParts("package", appContext.packageName, null)
            )
            fragment.startActivity(intent)
            true
        }

        fragment.findPreference<Preference>(KEY_EXPORT)?.setOnPreferenceClickListener {
            exportLauncher.launch(SettingsBackup.FILE_NAME)
            true
        }

        fragment.findPreference<Preference>(KEY_IMPORT)?.setOnPreferenceClickListener {
            importLauncher.launch(arrayOf("*/*"))
            true
        }

        fragment.findPreference<Preference>(KEY_RESET)?.setOnPreferenceClickListener {
            confirmReset()
            true
        }
    }

    // ===================== Export =====================

    private fun writeExport(uri: Uri) {
        fragment.lifecycleScope.launch {
            val success = runCatching {
                val json = SettingsBackup.toJson(repository.current())
                withContext(Dispatchers.IO) {
                    val stream = appContext.contentResolver.openOutputStream(uri, "wt")
                        ?: throw IllegalStateException("flux indisponible")
                    stream.use { it.write(json.toByteArray(Charsets.UTF_8)) }
                }
            }.isSuccess
            toast(if (success) R.string.m3_export_done else R.string.m3_export_failed)
        }
    }

    // ===================== Restauration =====================

    /** Le fichier est lu et validé AVANT toute confirmation : un fichier refusé ne modifie rien. */
    private fun readImport(uri: Uri) {
        fragment.lifecycleScope.launch {
            val result = runCatching {
                withContext(Dispatchers.IO) {
                    val bytes = appContext.contentResolver.openInputStream(uri)?.use { it.readBytes() }
                    if (bytes == null || bytes.size > MAX_IMPORT_BYTES) {
                        throw IllegalArgumentException(appContext.getString(R.string.m3_import_unreadable))
                    }
                    SettingsBackup.fromJson(String(bytes, Charsets.UTF_8))
                }
            }
            result.onSuccess { settings -> confirmImport(settings) }
            result.onFailure { error ->
                toast(appContext.getString(R.string.m3_import_invalid, error.message ?: "?"))
            }
        }
    }

    private fun confirmImport(settings: AppSettings) {
        MaterialAlertDialogBuilder(activity)
            .setTitle(R.string.m3_import_dialog_title)
            .setMessage(R.string.m3_import_dialog_message)
            .setPositiveButton(R.string.m3_import_confirm) { _, _ ->
                fragment.lifecycleScope.launch {
                    repository.replaceAll(settings)
                    toast(R.string.m3_import_done)
                }
            }
            .setNegativeButton(R.string.m3_cancel, null)
            .show()
    }

    // ===================== Réinitialisation usine =====================

    private fun confirmReset() {
        MaterialAlertDialogBuilder(activity)
            .setTitle(R.string.m3_reset_dialog_title)
            .setMessage(R.string.m3_reset_dialog_message)
            .setPositiveButton(R.string.m3_reset_confirm) { _, _ -> startReset() }
            .setNegativeButton(R.string.m3_cancel, null)
            .show()
    }

    /**
     * Si un code PIN existe, il est exigé avant d'effacer quoi que ce soit : sinon, une réinitialisation
     * suffirait à contourner le coffre-fort et à lire les morceaux masqués.
     */
    private fun startReset() {
        fragment.lifecycleScope.launch {
            if (pinStore.hasPin()) {
                PinDialogs.showUnlock(activity, pinStore, onUnlocked = { performReset(clearPin = true) })
            } else {
                performReset(clearPin = false)
            }
        }
    }

    /** Réglages, thème, cache et PIN. Ne supprime jamais de musique, de favori ni de playlist. */
    private fun performReset(clearPin: Boolean) {
        fragment.lifecycleScope.launch {
            runCatching {
                repository.resetAll()
                if (clearPin) pinStore.clear()
                withContext(Dispatchers.IO) { clearCache(appContext.cacheDir) }
            }
            SleepTimerHub.send(SleepTimerRequest.Cancel)
            fragment.findPreference<ListPreference>(SettingsFragment.KEY_THEME)?.value = THEME_SYSTEM
            toast(R.string.m3_reset_done)
            AppCompatDelegate.setDefaultNightMode(AppCompatDelegate.MODE_NIGHT_FOLLOW_SYSTEM)
        }
    }

    /** Vide le cache, sauf `covers/` : les pochettes des formats non réinscriptibles n'existent qu'à cet endroit. */
    private fun clearCache(directory: File) {
        directory.listFiles()?.forEach { child ->
            if (child.name != COVERS_DIRECTORY) child.deleteRecursively()
        }
    }

    private fun toast(resId: Int) {
        Toast.makeText(appContext, resId, Toast.LENGTH_SHORT).show()
    }

    private fun toast(text: String) {
        Toast.makeText(appContext, text, Toast.LENGTH_LONG).show()
    }

    private companion object {
        const val KEY_SKIP_SILENCE = "pref_skip_silence"
        const val KEY_PERMISSIONS = "pref_permissions"
        const val KEY_EXPORT = "pref_export_settings"
        const val KEY_IMPORT = "pref_import_settings"
        const val KEY_RESET = "pref_factory_reset"
        const val THEME_SYSTEM = "system"
        const val COVERS_DIRECTORY = "covers"
        const val MAX_IMPORT_BYTES = 256 * 1024
    }
}
EOF

# ----------------------------------------------------------------------------
# 3. Modifications MINIMALES des fichiers existants (ancres exactes, une seule
#    occurrence exigee ; sinon le script s'arrete avec un message clair)
# ----------------------------------------------------------------------------
echo "[v1.6/M3] Extension des fichiers existants..."
python3 - << 'PYEOF'
import sys
from pathlib import Path

BASE = "app/src/main/java/com/elg/music"
RES = "app/src/main/res"

def apply(path, marker, edits):
    p = Path(path)
    text = p.read_text(encoding="utf-8")
    if marker in text:
        print("  = deja a jour : " + path)
        return
    for anchor, mode, new in edits:
        n = text.count(anchor)
        if n != 1:
            sys.exit("ERREUR : ancre trouvee %d fois (1 attendue) dans %s :\n  %r" % (n, path, anchor))
        if mode == "after":
            text = text.replace(anchor, anchor + new)
        elif mode == "before":
            text = text.replace(anchor, new + anchor)
        else:
            text = text.replace(anchor, new)
    p.write_text(text, encoding="utf-8")
    print("  ~ etendu : " + path)

# --- SettingsRepository : champ skipSilence + cle DataStore + lecture/ecriture ---
apply(BASE + "/data/local/SettingsRepository.kt", "KEY_SKIP_SILENCE", [
    ('val driveModeTheme: String = "dark_neon"', "replace",
     'val driveModeTheme: String = "dark_neon",\n    val skipSilence: Boolean = false'),
    ('suspend fun setDriveModeTheme(theme: String) {', "before",
     'suspend fun setSkipSilence(enabled: Boolean) {\n        store.edit { it[KEY_SKIP_SILENCE] = enabled }\n    }\n\n    '),
    ('prefs[KEY_DRIVE_MODE_THEME] = settings.driveModeTheme', "after",
     '\n            prefs[KEY_SKIP_SILENCE] = settings.skipSilence'),
    ('driveModeTheme = this[KEY_DRIVE_MODE_THEME] ?: defaults.driveModeTheme', "after",
     ',\n            skipSilence = this[KEY_SKIP_SILENCE] ?: defaults.skipSilence'),
    ('val KEY_TAG_DISCLAIMER_ACCEPTED = booleanPreferencesKey("tag_editor_disclaimer_accepted")', "after",
     '\n        val KEY_SKIP_SILENCE = booleanPreferencesKey("skip_silence")'),
])

# --- AudioEffectsController : applique le saut des silences au lecteur ---
apply(BASE + "/playback/AudioEffectsController.kt", "setSkipSilenceEnabled", [
    ('val target = PlaybackParameters(settings.playbackSpeed, settings.playbackPitch)', "before",
     'player.setSkipSilenceEnabled(settings.skipSilence)\n        '),
])

# --- SettingsFragment : installe les nouvelles lignes ---
apply(BASE + "/ui/settings/SettingsFragment.kt", "SettingsMaintenance(this)", [
    ('setPreferencesFromResource(R.xml.root_preferences, rootKey)', "after",
     '\n        SettingsMaintenance(this).install()'),
])

# --- root_preferences.xml : nouvelles lignes ---
apply(RES + "/xml/root_preferences.xml", "pref_export_settings", [
    ('app:summary="@string/settings_sleep_timer_summary" />', "after",
     '\n\n        <SwitchPreferenceCompat\n'
     '            app:key="pref_skip_silence"\n'
     '            app:title="@string/m3_skip_silence_title"\n'
     '            app:summary="@string/m3_skip_silence_summary" />'),
    ('app:summary="@string/settings_vault_summary" />', "after",
     '\n\n        <Preference\n'
     '            app:key="pref_permissions"\n'
     '            app:title="@string/m3_permissions_title"\n'
     '            app:summary="@string/m3_permissions_summary" />'),
    ('<PreferenceCategory app:title="@string/settings_category_about">', "before",
     '<PreferenceCategory app:title="@string/m3_category_backup">\n\n'
     '        <Preference\n'
     '            app:key="pref_export_settings"\n'
     '            app:title="@string/m3_export_title"\n'
     '            app:summary="@string/m3_export_summary" />\n\n'
     '        <Preference\n'
     '            app:key="pref_import_settings"\n'
     '            app:title="@string/m3_import_title"\n'
     '            app:summary="@string/m3_import_summary" />\n\n'
     '        <Preference\n'
     '            app:key="pref_factory_reset"\n'
     '            app:title="@string/m3_reset_title"\n'
     '            app:summary="@string/m3_reset_summary" />\n\n'
     '    </PreferenceCategory>\n\n    '),
])

# --- strings.xml : apostrophes echappees (\') comme dans tout le projet ---
STRINGS = r'''    <!-- ===================== v1.6 MODULE 3 : REGLAGES ===================== -->
    <string name="m3_skip_silence_title">Saut des silences</string>
    <string name="m3_skip_silence_summary">Passe automatiquement les silences dans les morceaux (désactivé par défaut)</string>
    <string name="m3_permissions_title">Autorisations de l\'application</string>
    <string name="m3_permissions_summary">Musique et audio (requise), notifications (facultative)</string>
    <string name="m3_category_backup">Sauvegarde &amp; réinitialisation</string>
    <string name="m3_export_title">Exporter les réglages</string>
    <string name="m3_export_summary">Enregistre la configuration dans elg_settings_config.json</string>
    <string name="m3_import_title">Restaurer les réglages</string>
    <string name="m3_import_summary">Importe un fichier elg_settings_config.json</string>
    <string name="m3_reset_title">Réinitialisation usine</string>
    <string name="m3_reset_summary">Réglages, thème, cache et code PIN. Vos musiques ne sont jamais supprimées.</string>
    <string name="m3_export_done">Réglages exportés</string>
    <string name="m3_export_failed">Échec de l\'export</string>
    <string name="m3_import_dialog_title">Restaurer ces réglages ?</string>
    <string name="m3_import_dialog_message">Les réglages audio actuels (égaliseur, vitesse, tonalité, minuteur…) seront remplacés par ceux du fichier.</string>
    <string name="m3_import_confirm">Restaurer</string>
    <string name="m3_import_done">Réglages restaurés</string>
    <string name="m3_import_invalid">Fichier refusé : %1$s</string>
    <string name="m3_import_unreadable">fichier illisible ou trop volumineux</string>
    <string name="m3_reset_dialog_title">Réinitialiser ELG Music ?</string>
    <string name="m3_reset_dialog_message">Remet à zéro les réglages audio, le thème, le cache et le code PIN du coffre-fort.\n\nVos musiques, favoris et playlists ne sont pas touchés. Les morceaux masqués restent dans le coffre-fort. Si un code PIN existe, il vous sera demandé avant la réinitialisation.</string>
    <string name="m3_reset_confirm">Réinitialiser</string>
    <string name="m3_reset_done">Réinitialisation effectuée</string>
    <string name="m3_cancel">Annuler</string>

'''
apply(RES + "/values/strings.xml", "m3_skip_silence_title", [
    ('</resources>', "before", STRINGS),
])
PYEOF

# ----------------------------------------------------------------------------
# 4. Garde-fous : XML bien forme + toutes les chaines m3_ referencees existent
# ----------------------------------------------------------------------------
echo "[v1.6/M3] Verification..."
python3 - << 'PYEOF'
import re, sys
from pathlib import Path
from xml.dom import minidom

for f in ("app/src/main/res/values/strings.xml", "app/src/main/res/xml/root_preferences.xml"):
    try:
        minidom.parse(f)
    except Exception as e:
        sys.exit("ERREUR XML dans %s : %s" % (f, e))

strings = Path("app/src/main/res/values/strings.xml").read_text(encoding="utf-8")
defined = set(re.findall(r'<string name="(m3_[a-z_]+)"', strings))
used = set()
for kt in Path("app/src/main/java/com/elg/music").rglob("*.kt"):
    used |= set(re.findall(r"R\.string\.(m3_[a-z_]+)", kt.read_text(encoding="utf-8")))
xml_used = set(re.findall(r"@string/(m3_[a-z_]+)", Path("app/src/main/res/xml/root_preferences.xml").read_text(encoding="utf-8")))
missing = (used | xml_used) - defined
if missing:
    sys.exit("ERREUR : chaines manquantes : " + ", ".join(sorted(missing)))

# apostrophe non echappee dans une chaine m3_ = echec aapt
for name, value in re.findall(r'<string name="(m3_[a-z_]+)">(.*?)</string>', strings, flags=re.S):
    if re.search(r"(?<!\\)'", value):
        sys.exit("ERREUR : apostrophe non echappee dans " + name)
print("  OK : %d chaines m3_, XML valides." % len(defined))
PYEOF

echo ""
echo "=== v1.6 MODULE 3 (increment 1) : INSTALLE ==="
