#!/usr/bin/env bash
# ============================================================================
# ELG Music v1.6 — MODULE 3 (Settings) — Phase 1 : couche logique
# Extension MODULAIRE : ne crée que des NOUVEAUX fichiers, n'écrase rien.
# Idempotent : un fichier déjà présent est ignoré (ELG_FORCE=1 pour réécrire
# uniquement les fichiers créés par CE script).
# Exécution : depuis la racine du dépôt GitHub (étape dédiée de build.yml).
# ============================================================================
set -euo pipefail

ROOT="${1:-.}"
SRC="$ROOT/app/src/main/java/com/elg/music"
CREATED=0
SKIPPED=0

if [ ! -d "$ROOT/app/src/main" ]; then
  echo "❌ app/src/main introuvable : lancer depuis la racine du dépôt."
  exit 1
fi

write_file() {
  local path="$1"
  if [ -e "$path" ] && [ "${ELG_FORCE:-0}" != "1" ]; then
    echo "⏭  existe déjà : ${path#$ROOT/}"
    SKIPPED=$((SKIPPED + 1))
    cat > /dev/null
  else
    mkdir -p "$(dirname "$path")"
    cat > "$path"
    echo "✅ créé : ${path#$ROOT/}"
    CREATED=$((CREATED + 1))
  fi
}

# --- Vérification (non bloquante) des dépendances déjà présentes en v1.5 ----
GRADLE_FILE=""
for f in "$ROOT/app/build.gradle" "$ROOT/app/build.gradle.kts"; do
  [ -f "$f" ] && GRADLE_FILE="$f"
done
if [ -n "$GRADLE_FILE" ]; then
  grep -q "datastore-preferences" "$GRADLE_FILE" || echo "⚠️  datastore-preferences absent de $GRADLE_FILE"
  grep -q "lifecycle-viewmodel" "$GRADLE_FILE"   || echo "⚠️  lifecycle-viewmodel(-ktx) absent de $GRADLE_FILE"
  grep -q "coroutines-android" "$GRADLE_FILE"    || echo "⚠️  kotlinx-coroutines-android absent de $GRADLE_FILE"
fi

# ============================================================================
# 1. MODÈLE DE DONNÉES
# ============================================================================
write_file "$SRC/settings/AppSettings.kt" <<'EOF'
package com.elg.music.settings

import com.elg.music.dsp.EqualizerPresets

enum class QueueMode { ALL_TRACKS, SELECTED_ONLY }
enum class AddOrder { TOP, BOTTOM, AFTER_CURRENT }
enum class DarkMode { SYSTEM, ALWAYS_ON, ALWAYS_OFF, OLED }
enum class ReplayGainMode { TRACK, ALBUM }
enum class SpatialMode { DISABLED, AUTOMATIC, FILM, MUSIC, VOICE }
enum class TabType { SPOTIFY, FAVORITES, PLAYLISTS, TRACKS, ALBUMS, ARTISTS, GENRES, FOLDERS, COMPOSERS }

object SettingsLimits {
    const val SPEED_MIN = 0.25f
    const val SPEED_MAX = 2.5f
    const val PITCH_MIN = 0.5f
    const val PITCH_MAX = 2.0f
    const val EQ_MIN_DB = -12f
    const val EQ_MAX_DB = 12f
    const val EQ_BANDS = 5
    const val CROSSFADE_MAX_MS = 12_000
    const val SLEEP_MAX_MINUTES = 23 * 60 + 59
}

internal inline fun <reified E : Enum<E>> enumOr(name: String?, default: E): E =
    name?.let { runCatching { enumValueOf<E>(it) }.getOrNull() } ?: default

private fun Float.clampOr(min: Float, max: Float, fallback: Float): Float =
    if (isNaN()) fallback else coerceIn(min, max)

/**
 * Source unique de vérité des réglages v1.6 (sections A, B, C, D).
 * Le coffre-fort (section E) reste géré par le code v1.5 validé.
 */
data class AppSettings(
    // ── A : Lecture ──
    val sleepDefaultMinutes: Int = 30,            // 0 = désactivé
    val sleepFadeOut: Boolean = true,             // fondu linéaire 30 s
    val speed: Float = 1.0f,                      // 0.25x → 2.5x
    val crossfadeMs: Int = 0,                     // 0 → 12000 (moteur : étape ultérieure)
    val skipSilence: Boolean = false,
    val lockscreenControls: Boolean = true,
    // ── B : Listes de lecture ──
    val queueMode: QueueMode = QueueMode.ALL_TRACKS,
    val addOrder: AddOrder = AddOrder.BOTTOM,
    val preventDuplicates: Boolean = true,
    // ── C : Général ──
    val visibleTabs: Set<TabType> = setOf(
        TabType.SPOTIFY, TabType.FAVORITES, TabType.PLAYLISTS, TabType.TRACKS,
        TabType.ALBUMS, TabType.ARTISTS, TabType.FOLDERS
    ),
    val darkMode: DarkMode = DarkMode.SYSTEM,
    val externalDevices: Boolean = true,
    // ── D : Qualité & effets ──
    val eqEnabled: Boolean = false,
    val eqPreset: String = "Flat",
    val eqBands: List<Float> = List(SettingsLimits.EQ_BANDS) { 0f },
    val bassBoost: Int = 0,                       // 0..100 %
    val virtualizer: Int = 0,                     // 0..100 %
    val pitch: Float = 1.0f,                      // 0.5x → 2.0x
    val preservePitch: Boolean = true,            // true => pitch effectif = 1.0
    val replayGain: Boolean = false,              // moteur : étape ultérieure
    val replayGainMode: ReplayGainMode = ReplayGainMode.TRACK,
    val spatialMode: SpatialMode = SpatialMode.DISABLED // moteur : étape ultérieure
) {
    /** Corrige silencieusement toute valeur hors limites (usage : écritures UI). */
    fun sanitized(): AppSettings = copy(
        sleepDefaultMinutes = sleepDefaultMinutes.coerceIn(0, SettingsLimits.SLEEP_MAX_MINUTES),
        speed = speed.clampOr(SettingsLimits.SPEED_MIN, SettingsLimits.SPEED_MAX, 1f),
        crossfadeMs = crossfadeMs.coerceIn(0, SettingsLimits.CROSSFADE_MAX_MS),
        visibleTabs = visibleTabs.ifEmpty { setOf(TabType.TRACKS) },
        eqPreset = if (eqPreset == EqualizerPresets.CUSTOM || EqualizerPresets.bands(eqPreset) != null)
            eqPreset else EqualizerPresets.CUSTOM,
        eqBands = if (eqBands.size == SettingsLimits.EQ_BANDS)
            eqBands.map { it.clampOr(SettingsLimits.EQ_MIN_DB, SettingsLimits.EQ_MAX_DB, 0f) }
        else List(SettingsLimits.EQ_BANDS) { 0f },
        bassBoost = bassBoost.coerceIn(0, 100),
        virtualizer = virtualizer.coerceIn(0, 100),
        pitch = pitch.clampOr(SettingsLimits.PITCH_MIN, SettingsLimits.PITCH_MAX, 1f)
    )

    /** Validation STRICTE (usage : import JSON). null = valide. */
    fun validationError(): String? = when {
        sleepDefaultMinutes !in 0..SettingsLimits.SLEEP_MAX_MINUTES -> "Minuteur hors limites"
        speed.isNaN() || speed !in SettingsLimits.SPEED_MIN..SettingsLimits.SPEED_MAX ->
            "Vitesse hors limites (0.25 – 2.5)"
        pitch.isNaN() || pitch !in SettingsLimits.PITCH_MIN..SettingsLimits.PITCH_MAX ->
            "Pitch hors limites (0.5 – 2.0)"
        crossfadeMs !in 0..SettingsLimits.CROSSFADE_MAX_MS -> "Fondu enchaîné hors limites (0 – 12 s)"
        eqBands.size != SettingsLimits.EQ_BANDS -> "L'égaliseur doit comporter 5 bandes"
        eqBands.any { it.isNaN() || it !in SettingsLimits.EQ_MIN_DB..SettingsLimits.EQ_MAX_DB } ->
            "Niveau d'égaliseur hors limites (±12 dB)"
        eqPreset != EqualizerPresets.CUSTOM && EqualizerPresets.bands(eqPreset) == null ->
            "Preset d'égaliseur inconnu"
        bassBoost !in 0..100 -> "Bass Boost hors limites (0 – 100)"
        virtualizer !in 0..100 -> "Virtualizer hors limites (0 – 100)"
        visibleTabs.isEmpty() -> "Au moins un onglet doit rester visible"
        else -> null
    }
}
EOF

# ============================================================================
# 2. PRESETS ÉGALISEUR + PRESETS RAPIDES
# ============================================================================
write_file "$SRC/dsp/EqualizerPresets.kt" <<'EOF'
package com.elg.music.dsp

/** Bandes : 60 Hz, 230 Hz, 910 Hz, 3.6 kHz, 14 kHz — niveaux en dB (±12). */
object EqualizerPresets {
    const val CUSTOM = "Custom"

    val BAND_FREQS_HZ: IntArray = intArrayOf(60, 230, 910, 3_600, 14_000)

    private val table: LinkedHashMap<String, List<Float>> = linkedMapOf(
        "Flat" to listOf(0f, 0f, 0f, 0f, 0f),
        "Bass" to listOf(6f, 4f, 0f, 0f, 1f),
        "Rock" to listOf(5f, 1f, -2f, 4f, 3f),
        "Pop" to listOf(0f, 2f, -1f, 3f, 1f),
        "Jazz" to listOf(2f, 0f, 1f, 0f, 2f),
        "Vocal" to listOf(0f, -1f, 3f, 2f, 0f)
    )

    /** Noms affichables, "Custom" en dernier. */
    val names: List<String> get() = table.keys.toList() + CUSTOM

    /** null pour "Custom" ou un nom inconnu. */
    fun bands(name: String): List<Float>? = table[name]
}
EOF

write_file "$SRC/dsp/QuickPreset.kt" <<'EOF'
package com.elg.music.dsp

/** Presets rapides — valeurs conformes au cahier des charges validé. */
enum class QuickPreset(
    val label: String,
    val speed: Float,
    val pitch: Float,
    val eqPreset: String,
    val bassBoost: Int
) {
    NIGHTCORE("🌙 Nightcore", 1.20f, 1.20f, "Pop", 0),
    DEEP_VOICE("🔊 Deep Voice / Slowed", 0.85f, 0.80f, "Bass", 75),
    DICTATION("📖 Dictée / Apprentissage", 0.75f, 1.0f, "Vocal", 0)
}
EOF

# ============================================================================
# 3. PERSISTANCE (DataStore Preferences dédié "elg_settings_v16")
# ============================================================================
write_file "$SRC/settings/SettingsJson.kt" <<'EOF'
package com.elg.music.settings

import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject
import kotlin.math.roundToInt

/**
 * Format de `elg_settings_config.json` (compatible avec le schéma v1.4 :
 * les clés absentes reprennent leur valeur par défaut).
 */
object SettingsJson {
    private const val PKG = "com.elg.music"
    const val SCHEMA_VERSION = 1
    const val APP_VERSION = 1.6

    private fun Float.r2(): Double = (this * 100f).roundToInt() / 100.0

    fun toJson(s: AppSettings): String {
        val audio = JSONObject()
            .put("equalizer_enabled", s.eqEnabled)
            .put("equalizer_preset", s.eqPreset)
            .put("band_levels", JSONArray(s.eqBands.map { it.r2() }))
            .put("bass_boost", s.bassBoost)
            .put("virtualizer", s.virtualizer)
            .put("playback_speed", s.speed.r2())
            .put("playback_pitch", s.pitch.r2())
            .put("preserve_pitch", s.preservePitch)
            .put("replay_gain_enabled", s.replayGain)
            .put("replay_gain_mode", s.replayGainMode.name)
            .put("spatial_mode", s.spatialMode.name)

        val prefs = JSONObject()
            .put("sleep_timer_default", s.sleepDefaultMinutes)
            .put("fade_out_enabled", s.sleepFadeOut)
            .put("crossfade_ms", s.crossfadeMs)
            .put("skip_silence", s.skipSilence)
            .put("lockscreen_controls", s.lockscreenControls)
            .put("queue_mode", s.queueMode.name)
            .put("add_order", s.addOrder.name)
            .put("prevent_duplicates", s.preventDuplicates)
            .put("visible_tabs", JSONArray(s.visibleTabs.map { it.name }))
            .put("dark_mode", s.darkMode.name)
            .put("external_devices", s.externalDevices)

        return JSONObject()
            .put("package", PKG)
            .put("version", APP_VERSION)
            .put("schema_version", SCHEMA_VERSION)
            .put("audio_settings", audio)
            .put("app_preferences", prefs)
            .toString(2)
    }

    /** @throws IllegalArgumentException message lisible si le fichier est invalide. */
    fun fromJson(text: String): AppSettings {
        val root = try {
            JSONObject(text)
        } catch (e: JSONException) {
            throw IllegalArgumentException("Fichier JSON invalide")
        }
        require(root.optString("package") == PKG) { "Ce fichier n'appartient pas à ELG Music" }
        val ver = root.optDouble("version", Double.NaN)
        require(!ver.isNaN() && ver >= 1.0 && ver <= APP_VERSION + 1e-6) {
            "Version de configuration non supportée"
        }

        val d = AppSettings()
        val a = root.optJSONObject("audio_settings") ?: JSONObject()
        val p = root.optJSONObject("app_preferences") ?: JSONObject()

        val bands = a.optJSONArray("band_levels")?.let { arr ->
            require(arr.length() == SettingsLimits.EQ_BANDS) { "L'égaliseur doit comporter 5 bandes" }
            try {
                List(SettingsLimits.EQ_BANDS) { arr.getDouble(it).toFloat() }
            } catch (e: JSONException) {
                throw IllegalArgumentException("Niveaux d'égaliseur invalides")
            }
        } ?: d.eqBands

        val tabs = p.optJSONArray("visible_tabs")?.let { arr ->
            try {
                (0 until arr.length()).map { TabType.valueOf(arr.getString(it)) }.toSet()
            } catch (e: Exception) {
                throw IllegalArgumentException("Liste d'onglets invalide")
            }
        } ?: d.visibleTabs

        val s = AppSettings(
            sleepDefaultMinutes = p.optInt("sleep_timer_default", d.sleepDefaultMinutes),
            sleepFadeOut = p.optBoolean("fade_out_enabled", d.sleepFadeOut),
            speed = a.optDouble("playback_speed", d.speed.toDouble()).toFloat(),
            crossfadeMs = p.optInt("crossfade_ms", d.crossfadeMs),
            skipSilence = p.optBoolean("skip_silence", d.skipSilence),
            lockscreenControls = p.optBoolean("lockscreen_controls", d.lockscreenControls),
            queueMode = p.optEnum("queue_mode", d.queueMode),
            addOrder = p.optEnum("add_order", d.addOrder),
            preventDuplicates = p.optBoolean("prevent_duplicates", d.preventDuplicates),
            visibleTabs = tabs,
            darkMode = p.optEnum("dark_mode", d.darkMode),
            externalDevices = p.optBoolean("external_devices", d.externalDevices),
            eqEnabled = a.optBoolean("equalizer_enabled", d.eqEnabled),
            eqPreset = a.optString("equalizer_preset", d.eqPreset),
            eqBands = bands,
            bassBoost = a.optInt("bass_boost", d.bassBoost),
            virtualizer = a.optInt("virtualizer", d.virtualizer),
            pitch = a.optDouble("playback_pitch", d.pitch.toDouble()).toFloat(),
            preservePitch = a.optBoolean("preserve_pitch", d.preservePitch),
            replayGain = a.optBoolean("replay_gain_enabled", d.replayGain),
            replayGainMode = a.optEnum("replay_gain_mode", d.replayGainMode),
            spatialMode = a.optEnum("spatial_mode", d.spatialMode)
        )
        s.validationError()?.let { throw IllegalArgumentException(it) }
        return s
    }

    private inline fun <reified E : Enum<E>> JSONObject.optEnum(key: String, default: E): E {
        if (!has(key)) return default
        return try {
            enumValueOf<E>(getString(key))
        } catch (e: Exception) {
            throw IllegalArgumentException("Valeur invalide pour « $key »")
        }
    }
}
EOF

write_file "$SRC/settings/SettingsRepository.kt" <<'EOF'
package com.elg.music.settings

import android.content.Context
import androidx.datastore.preferences.core.MutablePreferences
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.emptyPreferences
import androidx.datastore.preferences.core.floatPreferencesKey
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.core.stringSetPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import java.io.IOException

// Store DÉDIÉ v1.6 : n'interfère pas avec les DataStore existants (coffre-fort, lecteur…).
private val Context.elgSettingsV16DataStore by preferencesDataStore(name = "elg_settings_v16")

class SettingsRepository private constructor(context: Context) {

    private val store = context.applicationContext.elgSettingsV16DataStore

    val settings: Flow<AppSettings> = store.data
        .catch { e -> if (e is IOException) emit(emptyPreferences()) else throw e }
        .map { it.toSettings() }

    suspend fun current(): AppSettings = settings.first()

    /** Lecture-modification-écriture atomique (une seule transaction DataStore). */
    suspend fun update(transform: (AppSettings) -> AppSettings) {
        store.edit { prefs -> prefs.write(transform(prefs.toSettings()).sanitized()) }
    }

    /** Import : valide d'abord, n'écrit qu'en cas de succès (atomique). */
    suspend fun importJson(json: String): Result<AppSettings> = runCatching {
        val parsed = SettingsJson.fromJson(json)
        update { parsed }
        parsed
    }

    fun exportJson(settings: AppSettings): String = SettingsJson.toJson(settings)

    /** Réinitialise UNIQUEMENT les réglages v1.6 (jamais les fichiers audio). */
    suspend fun resetAll() {
        store.edit { it.clear() }
    }

    // ── Clés ──
    private object K {
        val SLEEP_MIN = intPreferencesKey("sleep_default_minutes")
        val SLEEP_FADE = booleanPreferencesKey("sleep_fade_out")
        val SPEED = floatPreferencesKey("speed")
        val CROSSFADE = intPreferencesKey("crossfade_ms")
        val SKIP_SILENCE = booleanPreferencesKey("skip_silence")
        val LOCKSCREEN = booleanPreferencesKey("lockscreen_controls")
        val QUEUE_MODE = stringPreferencesKey("queue_mode")
        val ADD_ORDER = stringPreferencesKey("add_order")
        val NO_DUPES = booleanPreferencesKey("prevent_duplicates")
        val TABS = stringSetPreferencesKey("visible_tabs")
        val DARK = stringPreferencesKey("dark_mode")
        val EXTERNAL = booleanPreferencesKey("external_devices")
        val EQ_ON = booleanPreferencesKey("eq_enabled")
        val EQ_PRESET = stringPreferencesKey("eq_preset")
        val EQ_BANDS = stringPreferencesKey("eq_bands")
        val BASS = intPreferencesKey("bass_boost")
        val VIRT = intPreferencesKey("virtualizer")
        val PITCH = floatPreferencesKey("pitch")
        val PRESERVE = booleanPreferencesKey("preserve_pitch")
        val RG_ON = booleanPreferencesKey("replay_gain")
        val RG_MODE = stringPreferencesKey("replay_gain_mode")
        val SPATIAL = stringPreferencesKey("spatial_mode")
    }

    private fun Preferences.toSettings(): AppSettings {
        val d = AppSettings()
        return AppSettings(
            sleepDefaultMinutes = this[K.SLEEP_MIN] ?: d.sleepDefaultMinutes,
            sleepFadeOut = this[K.SLEEP_FADE] ?: d.sleepFadeOut,
            speed = this[K.SPEED] ?: d.speed,
            crossfadeMs = this[K.CROSSFADE] ?: d.crossfadeMs,
            skipSilence = this[K.SKIP_SILENCE] ?: d.skipSilence,
            lockscreenControls = this[K.LOCKSCREEN] ?: d.lockscreenControls,
            queueMode = enumOr(this[K.QUEUE_MODE], d.queueMode),
            addOrder = enumOr(this[K.ADD_ORDER], d.addOrder),
            preventDuplicates = this[K.NO_DUPES] ?: d.preventDuplicates,
            visibleTabs = this[K.TABS]
                ?.mapNotNull { runCatching { TabType.valueOf(it) }.getOrNull() }
                ?.toSet() ?: d.visibleTabs,
            darkMode = enumOr(this[K.DARK], d.darkMode),
            externalDevices = this[K.EXTERNAL] ?: d.externalDevices,
            eqEnabled = this[K.EQ_ON] ?: d.eqEnabled,
            eqPreset = this[K.EQ_PRESET] ?: d.eqPreset,
            eqBands = this[K.EQ_BANDS]?.let(::parseBands) ?: d.eqBands,
            bassBoost = this[K.BASS] ?: d.bassBoost,
            virtualizer = this[K.VIRT] ?: d.virtualizer,
            pitch = this[K.PITCH] ?: d.pitch,
            preservePitch = this[K.PRESERVE] ?: d.preservePitch,
            replayGain = this[K.RG_ON] ?: d.replayGain,
            replayGainMode = enumOr(this[K.RG_MODE], d.replayGainMode),
            spatialMode = enumOr(this[K.SPATIAL], d.spatialMode)
        ).sanitized()
    }

    private fun MutablePreferences.write(s: AppSettings) {
        this[K.SLEEP_MIN] = s.sleepDefaultMinutes
        this[K.SLEEP_FADE] = s.sleepFadeOut
        this[K.SPEED] = s.speed
        this[K.CROSSFADE] = s.crossfadeMs
        this[K.SKIP_SILENCE] = s.skipSilence
        this[K.LOCKSCREEN] = s.lockscreenControls
        this[K.QUEUE_MODE] = s.queueMode.name
        this[K.ADD_ORDER] = s.addOrder.name
        this[K.NO_DUPES] = s.preventDuplicates
        this[K.TABS] = s.visibleTabs.map { it.name }.toSet()
        this[K.DARK] = s.darkMode.name
        this[K.EXTERNAL] = s.externalDevices
        this[K.EQ_ON] = s.eqEnabled
        this[K.EQ_PRESET] = s.eqPreset
        this[K.EQ_BANDS] = s.eqBands.joinToString(",")
        this[K.BASS] = s.bassBoost
        this[K.VIRT] = s.virtualizer
        this[K.PITCH] = s.pitch
        this[K.PRESERVE] = s.preservePitch
        this[K.RG_ON] = s.replayGain
        this[K.RG_MODE] = s.replayGainMode.name
        this[K.SPATIAL] = s.spatialMode.name
    }

    private fun parseBands(csv: String): List<Float>? =
        csv.split(',').mapNotNull { it.trim().toFloatOrNull() }
            .takeIf { it.size == SettingsLimits.EQ_BANDS }

    companion object {
        @Volatile private var instance: SettingsRepository? = null

        fun get(context: Context): SettingsRepository =
            instance ?: synchronized(this) {
                instance ?: SettingsRepository(context.applicationContext).also { instance = it }
            }
    }
}
EOF

# ============================================================================
# 4. MOTEUR DSP (effets audio système liés à la session ExoPlayer)
# ============================================================================
write_file "$SRC/dsp/DspController.kt" <<'EOF'
package com.elg.music.dsp

import android.media.audiofx.BassBoost
import android.media.audiofx.Equalizer
import android.media.audiofx.Virtualizer
import android.util.Log
import androidx.media3.common.PlaybackParameters
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
import kotlin.math.abs
import kotlin.math.ln
import kotlin.math.roundToInt

/** Paramètres effectifs appliqués au lecteur (pitch déjà résolu). */
data class DspParams(
    val speed: Float = 1f,
    val pitch: Float = 1f,
    val eqEnabled: Boolean = false,
    val bandsDb: List<Float> = List(5) { 0f },
    val bassBoost: Int = 0,      // 0..100
    val virtualizer: Int = 0     // 0..100
)

/**
 * Applique vitesse/pitch (Media3 PlaybackParameters) et les effets
 * Equalizer / BassBoost / Virtualizer sur la session audio d'ExoPlayer.
 * À utiliser sur le thread principal (thread applicatif d'ExoPlayer).
 */
class DspController(private val player: ExoPlayer) : Player.Listener {

    private var eq: Equalizer? = null
    private var bass: BassBoost? = null
    private var virt: Virtualizer? = null
    private var boundSession = 0
    private var last = DspParams()

    fun start() {
        player.addListener(this)
        rebind(player.audioSessionId)
    }

    fun release() {
        player.removeListener(this)
        releaseEffects()
    }

    fun apply(params: DspParams) {
        last = params
        player.setPlaybackParameters(PlaybackParameters(params.speed, params.pitch))
        applyEffects(params)
    }

    override fun onAudioSessionIdChanged(audioSessionId: Int) {
        rebind(audioSessionId)
    }

    // ── Effets ──
    private fun rebind(session: Int) {
        if (session == boundSession && (eq != null || bass != null || virt != null)) return
        releaseEffects()
        if (session == 0) return // session non encore attribuée
        eq = runCatching { Equalizer(0, session) }.onFailure { Log.w(TAG, "Equalizer indisponible", it) }.getOrNull()
        bass = runCatching { BassBoost(0, session) }.onFailure { Log.w(TAG, "BassBoost indisponible", it) }.getOrNull()
        virt = runCatching { Virtualizer(0, session) }.onFailure { Log.w(TAG, "Virtualizer indisponible", it) }.getOrNull()
        boundSession = session
        applyEffects(last)
    }

    private fun releaseEffects() {
        runCatching { eq?.release() }
        runCatching { bass?.release() }
        runCatching { virt?.release() }
        eq = null; bass = null; virt = null
        boundSession = 0
    }

    private fun applyEffects(p: DspParams) {
        eq?.let { e -> runCatching { applyEqualizer(e, p) }.onFailure { Log.w(TAG, "EQ", it) } }
        bass?.let { b ->
            runCatching {
                if (b.strengthSupported) {
                    b.setStrength((p.bassBoost * 10).coerceIn(0, 1000).toShort())
                    b.setEnabled(p.bassBoost > 0)
                }
            }.onFailure { Log.w(TAG, "BassBoost", it) }
        }
        virt?.let { v ->
            runCatching {
                if (v.strengthSupported) {
                    v.setStrength((p.virtualizer * 10).coerceIn(0, 1000).toShort())
                    v.setEnabled(p.virtualizer > 0)
                }
            }.onFailure { Log.w(TAG, "Virtualizer", it) }
        }
    }

    /**
     * Mappe nos 5 bandes (60/230/910/3600/14000 Hz) sur les bandes réelles de
     * l'appareil (plus proche fréquence en échelle logarithmique ; moyenne si
     * plusieurs bandes cibles tombent sur la même bande matérielle).
     */
    private fun applyEqualizer(e: Equalizer, p: DspParams) {
        val range = e.bandLevelRange
        val minMb = range[0].toInt()
        val maxMb = range[1].toInt()
        val n = e.numberOfBands.toInt()
        val sums = FloatArray(n)
        val counts = IntArray(n)

        EqualizerPresets.BAND_FREQS_HZ.forEachIndexed { i, hz ->
            var best = 0
            var bestDist = Double.MAX_VALUE
            for (b in 0 until n) {
                val centerHz = e.getCenterFreq(b.toShort()) / 1000.0 // milliHertz → Hz
                val dist = abs(ln(centerHz) - ln(hz.toDouble()))
                if (dist < bestDist) { bestDist = dist; best = b }
            }
            sums[best] += p.bandsDb.getOrElse(i) { 0f }
            counts[best]++
        }
        for (b in 0 until n) {
            val db = if (counts[b] > 0) sums[b] / counts[b] else 0f
            val mb = (db * 100f).roundToInt().coerceIn(minMb, maxMb)
            e.setBandLevel(b.toShort(), mb.toShort())
        }
        e.setEnabled(p.eqEnabled)
    }

    private companion object { const val TAG = "ElgDsp" }
}
EOF

# ============================================================================
# 5. MINUTEUR DE SOMMEIL (fondu linéaire 30 s, précision par horloge monotone)
# ============================================================================
write_file "$SRC/sleep/SleepTimerManager.kt" <<'EOF'
package com.elg.music.sleep

import android.os.SystemClock
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch

/** Doit vivre dans le service de lecture (là où se trouve l'ExoPlayer). Thread principal. */
class SleepTimerManager(
    private val player: ExoPlayer,
    private val scope: CoroutineScope
) : Player.Listener {

    enum class Mode { OFF, TIMED, END_OF_TRACK }

    data class State(
        val mode: Mode = Mode.OFF,
        val remainingMs: Long = 0L,
        val fading: Boolean = false
    )

    private val _state = MutableStateFlow(State())
    val state: StateFlow<State> = _state.asStateFlow()

    private var job: Job? = null
    private var baseVolume = 1f

    fun start() { player.addListener(this) }

    fun release() {
        cancel()
        player.removeListener(this)
    }

    fun startTimed(durationMs: Long, fadeOut: Boolean, fadeMs: Long = DEFAULT_FADE_MS) {
        require(durationMs > 0) { "Durée invalide" }
        cancel()
        baseVolume = player.volume
        val endAt = SystemClock.elapsedRealtime() + durationMs
        _state.value = State(Mode.TIMED, durationMs)
        job = scope.launch {
            while (isActive) {
                val remaining = endAt - SystemClock.elapsedRealtime()
                if (remaining <= 0L) break
                val fading = fadeOut && remaining <= fadeMs
                if (fading) {
                    // Fondu LINÉAIRE : 1.0 → 0.0 sur les 30 dernières secondes
                    player.volume = baseVolume * (remaining.toFloat() / fadeMs).coerceIn(0f, 1f)
                }
                _state.value = State(Mode.TIMED, remaining, fading)
                delay(TICK_MS)
            }
            if (isActive) finish()
        }
    }

    /** « Fin de la piste » : pause automatique à la fin du morceau en cours. */
    fun startEndOfTrack() {
        cancel()
        player.pauseAtEndOfMediaItems = true
        _state.value = State(Mode.END_OF_TRACK)
    }

    fun cancel() {
        job?.cancel()
        job = null
        player.pauseAtEndOfMediaItems = false
        if (_state.value.mode != Mode.OFF) player.volume = baseVolume
        _state.value = State()
    }

    private fun finish() {
        player.pause()
        player.volume = baseVolume
        job = null
        _state.value = State()
    }

    override fun onPlayWhenReadyChanged(playWhenReady: Boolean, reason: Int) {
        if (_state.value.mode == Mode.END_OF_TRACK &&
            !playWhenReady &&
            reason == Player.PLAY_WHEN_READY_CHANGE_REASON_END_OF_MEDIA_ITEM
        ) {
            cancel() // pause déjà effectuée par le lecteur ; on remet l'état à zéro
        }
    }

    private companion object {
        const val DEFAULT_FADE_MS = 30_000L
        const val TICK_MS = 250L
    }
}
EOF

# ============================================================================
# 6. MOTEUR GLOBAL (point d'intégration UNIQUE avec le service de lecture)
# ============================================================================
write_file "$SRC/engine/ElgAudioEngine.kt" <<'EOF'
package com.elg.music.engine

import android.content.Context
import androidx.media3.exoplayer.ExoPlayer
import com.elg.music.dsp.DspController
import com.elg.music.dsp.DspParams
import com.elg.music.settings.AppSettings
import com.elg.music.settings.SettingsRepository
import com.elg.music.sleep.SleepTimerManager
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch

/**
 * Pont entre les réglages persistés (DataStore) et le lecteur.
 * Le service de lecture appelle attach()/detach() ; l'UI n'écrit que dans le
 * SettingsRepository et le moteur réagit automatiquement.
 */
object ElgAudioEngine {

    private var scope: CoroutineScope? = null
    private var dsp: DspController? = null
    private var sleep: SleepTimerManager? = null

    private val _sleepState = MutableStateFlow(SleepTimerManager.State())
    val sleepState: StateFlow<SleepTimerManager.State> = _sleepState.asStateFlow()

    @Synchronized
    fun attach(context: Context, player: ExoPlayer) {
        detach()
        val repo = SettingsRepository.get(context)
        val s = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
        scope = s

        val dspController = DspController(player).also { it.start() }
        val sleepManager = SleepTimerManager(player, s).also { it.start() }
        dsp = dspController
        sleep = sleepManager

        s.launch { sleepManager.state.collect { _sleepState.value = it } }
        s.launch {
            repo.settings.map { it.toDspParams() }.distinctUntilChanged()
                .collect { dspController.apply(it) }
        }
        s.launch {
            repo.settings.map { it.skipSilence }.distinctUntilChanged()
                .collect { player.skipSilenceEnabled = it }
        }
    }

    @Synchronized
    fun detach() {
        sleep?.release()
        dsp?.release()
        scope?.cancel()
        sleep = null; dsp = null; scope = null
        _sleepState.value = SleepTimerManager.State()
    }

    /** @return false si le lecteur n'est pas encore attaché. */
    fun startSleepTimer(minutes: Int, fadeOut: Boolean): Boolean {
        val m = sleep ?: return false
        if (minutes <= 0) { m.cancel(); return true }
        m.startTimed(minutes * 60_000L, fadeOut)
        return true
    }

    fun startSleepEndOfTrack(): Boolean {
        val m = sleep ?: return false
        m.startEndOfTrack()
        return true
    }

    fun cancelSleepTimer() { sleep?.cancel() }

    private fun AppSettings.toDspParams() = DspParams(
        speed = speed,
        pitch = if (preservePitch) 1f else pitch,
        eqEnabled = eqEnabled,
        bandsDb = eqBands,
        bassBoost = bassBoost,
        virtualizer = virtualizer
    )
}
EOF

# ============================================================================
# 7. VIEWMODEL (View-system / XML, MVI léger : StateFlow + SharedFlow)
# ============================================================================
write_file "$SRC/settings/ElgSettingsViewModel.kt" <<'EOF'
package com.elg.music.settings

import android.app.Application
import android.net.Uri
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.elg.music.dsp.EqualizerPresets
import com.elg.music.dsp.QuickPreset
import com.elg.music.engine.ElgAudioEngine
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

sealed interface SettingsEffect {
    data class Message(val text: String) : SettingsEffect
}

class ElgSettingsViewModel(app: Application) : AndroidViewModel(app) {

    private val repo = SettingsRepository.get(app)

    val settings: StateFlow<AppSettings> = repo.settings
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), AppSettings())

    val sleepState = ElgAudioEngine.sleepState

    private val _effects = MutableSharedFlow<SettingsEffect>(extraBufferCapacity = 8)
    val effects: SharedFlow<SettingsEffect> = _effects.asSharedFlow()

    private fun edit(transform: (AppSettings) -> AppSettings) {
        viewModelScope.launch { repo.update(transform) }
    }

    private fun say(text: String) { _effects.tryEmit(SettingsEffect.Message(text)) }

    // ── A : Lecture ──
    fun setSpeed(v: Float) = edit { it.copy(speed = v) }
    fun setCrossfadeMs(v: Int) = edit { it.copy(crossfadeMs = v) }
    fun setSkipSilence(v: Boolean) = edit { it.copy(skipSilence = v) }
    fun setLockscreenControls(v: Boolean) = edit { it.copy(lockscreenControls = v) }
    fun setSleepFadeOut(v: Boolean) = edit { it.copy(sleepFadeOut = v) }

    fun startSleepTimer(minutes: Int) {
        val fade = settings.value.sleepFadeOut
        edit { it.copy(sleepDefaultMinutes = minutes) }
        if (ElgAudioEngine.startSleepTimer(minutes, fade)) {
            say(if (minutes > 0) "Minuteur : $minutes min" else "Minuteur désactivé")
        } else say("Lecteur indisponible : lance d'abord une lecture")
    }

    fun startSleepEndOfTrack() {
        say(if (ElgAudioEngine.startSleepEndOfTrack()) "Arrêt à la fin de la piste"
        else "Lecteur indisponible : lance d'abord une lecture")
    }

    fun cancelSleepTimer() { ElgAudioEngine.cancelSleepTimer(); say("Minuteur annulé") }

    // ── B : Listes de lecture ──
    fun setQueueMode(v: QueueMode) = edit { it.copy(queueMode = v) }
    fun setAddOrder(v: AddOrder) = edit { it.copy(addOrder = v) }
    fun setPreventDuplicates(v: Boolean) = edit { it.copy(preventDuplicates = v) }

    // ── C : Général ──
    fun setTabVisible(tab: TabType, visible: Boolean) = edit {
        val next = if (visible) it.visibleTabs + tab else it.visibleTabs - tab
        it.copy(visibleTabs = next) // sanitized() garantit ≥ 1 onglet
    }
    fun setDarkMode(v: DarkMode) = edit { it.copy(darkMode = v) }
    fun setExternalDevices(v: Boolean) = edit { it.copy(externalDevices = v) }

    // ── D : Qualité & effets ──
    fun setEqEnabled(v: Boolean) = edit { it.copy(eqEnabled = v) }

    fun setEqBand(index: Int, db: Float) = edit { s ->
        if (index !in 0 until SettingsLimits.EQ_BANDS) s
        else s.copy(
            eqBands = s.eqBands.toMutableList().also { it[index] = db },
            eqPreset = EqualizerPresets.CUSTOM
        )
    }

    fun setEqPreset(name: String) = edit { s ->
        val bands = EqualizerPresets.bands(name)
        when {
            bands != null -> s.copy(eqPreset = name, eqBands = bands, eqEnabled = true)
            name == EqualizerPresets.CUSTOM -> s.copy(eqPreset = name)
            else -> s
        }
    }

    fun setBassBoost(v: Int) = edit { it.copy(bassBoost = v) }
    fun setVirtualizer(v: Int) = edit { it.copy(virtualizer = v) }
    fun setPitch(v: Float) = edit { it.copy(pitch = v, preservePitch = false) }
    fun setPreservePitch(v: Boolean) = edit { it.copy(preservePitch = v) }
    fun setReplayGain(v: Boolean) = edit { it.copy(replayGain = v) }
    fun setReplayGainMode(v: ReplayGainMode) = edit { it.copy(replayGainMode = v) }
    fun setSpatialMode(v: SpatialMode) = edit { it.copy(spatialMode = v) }

    fun applyQuickPreset(q: QuickPreset) {
        edit {
            it.copy(
                speed = q.speed,
                pitch = q.pitch,
                preservePitch = q.pitch == 1f,
                eqEnabled = true,
                eqPreset = q.eqPreset,
                eqBands = EqualizerPresets.bands(q.eqPreset) ?: it.eqBands,
                bassBoost = q.bassBoost
            )
        }
        say("Preset : ${q.label}")
    }

    // ── F : Import / Export / Reset ──
    fun exportTo(uri: Uri) {
        viewModelScope.launch {
            val result = runCatching {
                val json = SettingsJson.toJson(repo.current())
                withContext(Dispatchers.IO) {
                    val out = getApplication<Application>().contentResolver.openOutputStream(uri, "wt")
                        ?: error("Impossible d'écrire le fichier")
                    out.use { it.write(json.toByteArray(Charsets.UTF_8)) }
                }
            }
            say(if (result.isSuccess) "Configuration exportée" else "Échec de l'export")
        }
    }

    fun importFrom(uri: Uri) {
        viewModelScope.launch {
            val text = runCatching {
                withContext(Dispatchers.IO) {
                    val bytes = getApplication<Application>().contentResolver.openInputStream(uri)
                        ?.use { it.readBytes() } ?: error("Fichier illisible")
                    require(bytes.size <= MAX_IMPORT_BYTES) { "Fichier trop volumineux" }
                    String(bytes, Charsets.UTF_8)
                }
            }
            val outcome = text.fold(
                onSuccess = { repo.importJson(it) },
                onFailure = { Result.failure(it) }
            )
            say(
                outcome.fold(
                    onSuccess = { "Configuration restaurée" },
                    onFailure = { "Import refusé : ${it.message ?: "fichier invalide"}" }
                )
            )
        }
    }

    /**
     * Réinitialisation usine : réglages v1.6 + cache. Ne touche JAMAIS aux
     * musiques. [extraReset] : crochet pour réinitialiser le coffre-fort/PIN
     * du code v1.5 (store existant, non modifié ici).
     */
    fun factoryReset(extraReset: suspend () -> Unit = {}) {
        viewModelScope.launch {
            runCatching {
                ElgAudioEngine.cancelSleepTimer()
                repo.resetAll()
                extraReset()
                withContext(Dispatchers.IO) {
                    getApplication<Application>().cacheDir.listFiles()?.forEach { it.deleteRecursively() }
                }
            }.fold(
                onSuccess = { say("Réinitialisation effectuée") },
                onFailure = { say("Échec de la réinitialisation") }
            )
        }
    }

    private companion object { const val MAX_IMPORT_BYTES = 256 * 1024 }
}
EOF

echo ""
echo "════════════════════════════════════════════════════"
echo " Module 3 / Phase 1 — créés : $CREATED | ignorés : $SKIPPED"
echo "════════════════════════════════════════════════════"
echo " Intégration (2 lignes dans ton MediaSessionService existant) :"
echo "   onCreate()  : ElgAudioEngine.attach(this, player)"
echo "   onDestroy() : ElgAudioEngine.detach()   // avant player.release()"
echo " (import com.elg.music.engine.ElgAudioEngine ; player = l'ExoPlayer sous-jacent)"
