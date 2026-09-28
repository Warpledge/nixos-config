package tsunagu.kototoro.bridge

import android.app.Application
import android.content.Context
import android.content.SharedPreferences
import androidx.preference.EditTextPreference
import androidx.preference.ListPreference
import androidx.preference.Preference
import androidx.preference.PreferenceScreen
import androidx.preference.SwitchPreferenceCompat
import kotlinx.coroutines.withTimeoutOrNull
import okhttp3.Cookie
import okhttp3.HttpUrl.Companion.toHttpUrl
import org.koin.core.context.GlobalContext
import org.skepsun.kototoro.parsers.ContentParser
import org.skepsun.kototoro.parsers.config.ConfigKey
import org.skepsun.kototoro.parsers.config.ContentSourceConfig
import org.skepsun.kototoro.parsers.model.ContentSource
import java.security.MessageDigest

// Stable and distinct from any Tachiyomi source that shares the site's name and language.
internal fun sourceId(source: ContentSource): Long =
    MessageDigest.getInstance("MD5").digest("kototoro/${source.name}".toByteArray())
        .take(8).fold(0L) { acc, b -> (acc shl 8) or (b.toLong() and 0xff) } and Long.MAX_VALUE

/** The file Tsunagu's preference API reads and writes for this source. */
internal fun prefsOf(source: ContentSource): SharedPreferences =
    GlobalContext.get().get<Application>().getSharedPreferences("source_${sourceId(source)}", 0)

/** A parser's config backed by its stored preferences; unset or blank values fall back to the key's default. */
internal class PrefsConfig(private val prefs: SharedPreferences) : ContentSourceConfig {
    @Suppress("UNCHECKED_CAST")
    override fun <T> get(key: ConfigKey<T>): T {
        val name = Fields.key(key)
        val default = key.defaultValue
        if (!prefs.contains(name)) return default
        val value: Any? = if (default is Boolean) {
            prefs.getBoolean(name, default)
        } else {
            prefs.getString(name, null)?.takeIf { it.isNotBlank() } ?: default
        }
        return value as T
    }
}

/** Kototoro config keys as a Tachiyomi preference screen, plus a cookie login for parsers that need one. */
internal class Settings(private val parser: ContentParser) {
    private val prefs by lazy { prefsOf(parser.source) }
    private val auth = parser.authorizationProvider

    private val keys: List<ConfigKey<*>> by lazy {
        ArrayList<ConfigKey<*>>().also(parser::onCreateConfig).distinctBy { Fields.key(it) }
    }

    fun setup(screen: PreferenceScreen) {
        syncLogin()
        val context = screen.context
        keys.mapNotNull { preference(context, it) }.forEach(screen::addPreference)
        loginPreference(context)?.let(screen::addPreference)
    }

    private fun preference(context: Context?, key: ConfigKey<*>): Preference? {
        val name = Fields.key(key)
        return when (key) {
            is ConfigKey.Domain -> Fields.presets(key).takeIf { it.size > 1 }
                ?.let { list(context, name, "Domain", it.associateWith { d -> d }, key.defaultValue) }
            is ConfigKey.PreferredLanguage -> list(context, name, Fields.title(key), Fields.presets(key), key.defaultValue)
            is ConfigKey.PreferredImageServer -> list(context, name, "Image server", key.presetValues, key.defaultValue)
            is ConfigKey.UserAgent -> text(context, name, "User agent", key.defaultValue)
            is ConfigKey.Text -> text(context, name, Fields.title(key), key.defaultValue)
            is ConfigKey.Toggle -> switch(context, name, Fields.title(key), key.defaultValue)
            is ConfigKey.ShowSuspiciousContent -> switch(context, name, "Show suspicious content", key.defaultValue)
            is ConfigKey.SplitByTranslations -> switch(context, name, "Split chapters by translation", key.defaultValue)
        }
    }

    // Kototoro maps value -> label, and either side may be null ("automatic").
    private fun list(context: Context?, name: String, label: String, presets: Map<*, *>, default: String?) =
        ListPreference(context).apply {
            key = name
            title = label
            entryValues = presets.keys.map { (it as String?).orEmpty() }.toTypedArray()
            entries = presets.map { (value, title) -> (title as String?) ?: (value as String?) ?: "Automatic" }.toTypedArray()
            setDefaultValue(default.orEmpty())
        }

    private fun text(context: Context?, name: String, label: String, default: String?) = EditTextPreference(context).apply {
        key = name
        title = label
        summary = "Leave empty for the default"
        setDefaultValue(default.orEmpty())
    }

    private fun switch(context: Context?, name: String, label: String, default: Boolean) = SwitchPreferenceCompat(context).apply {
        key = name
        title = label
        setDefaultValue(default)
    }

    private fun loginPreference(context: Context?): Preference? {
        val provider = auth ?: return null
        val status = when (runCatching { runBlockingIO { withTimeoutOrNull(5_000) { provider.isAuthorized() } } }.getOrNull()) {
            true -> "Logged in. "
            false -> "Not logged in. "
            null -> ""
        }
        return EditTextPreference(context).apply {
            key = COOKIES
            title = "Login cookies"
            summary = status + "Log in at ${provider.authUrl} in a browser, then paste that site's cookies " +
                "here as name=value; name=value. Clear the field to log out."
            setDefaultValue("")
        }
    }

    // Tsunagu's cookie store only lives in sandbox memory, so what was applied is tracked the same way.
    @Volatile private var applied: String? = null

    /**
     * Writes the pasted cookies into Tsunagu's cookie jar for every domain the parser can use, and
     * removes the ones a previous value set. Parsers check the jar themselves to decide whether
     * they are logged in, so this runs before each request batch.
     */
    fun syncLogin() {
        if (auth == null) return
        val raw = prefs.getString(COOKIES, "").orEmpty()
        val previous = applied
        if (raw == previous) return
        val wanted = parseCookies(raw)
        val dropped = parseCookies(previous.orEmpty()).keys - wanted.keys
        val hosts = setOf(parser.domain) + Fields.presets(parser.configKeyDomain)
        for (host in hosts) {
            if (wanted.isNotEmpty()) {
                Host.cookieJar.saveFromResponse("https://$host/".toHttpUrl(), wanted.map { (name, value) -> cookie(host, name, value) })
            }
            Host.removeCookies(host, dropped)
        }
        applied = raw
    }

    private fun cookie(host: String, name: String, value: String) = Cookie.Builder()
        .name(name).value(value).domain(host).path("/").expiresAt(Long.MAX_VALUE).secure().build()

    private fun parseCookies(raw: String): Map<String, String> = raw.removePrefix("Cookie:").split(';')
        .mapNotNull { part ->
            val eq = part.indexOf('=')
            if (eq <= 0) null else part.substring(0, eq).trim() to part.substring(eq + 1).trim()
        }
        .filter { (name, _) -> name.isNotEmpty() }
        .toMap()

    private companion object {
        const val COOKIES = "kototoro_login_cookies"
    }
}
