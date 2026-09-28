package tsunagu.kototoro.bridge

import org.skepsun.kototoro.parsers.model.ContentParserSource
import org.skepsun.kototoro.parsers.model.ContentType

/** Reflective entry point called by tsunagu.kototoro.KototoroPlugin; only plain JVM types cross it. */
object Entry {
    // Matched by suffix so every video (and novel) variant of ContentType is covered.
    private val VIDEO = ContentType.entries.filter { it.name.endsWith("VIDEO") }.toSet()

    // Novels need LNReader-style text chapters, which the bridge does not map.
    private val UNSUPPORTED = ContentType.entries.filter { it.name.endsWith("NOVEL") }.toSet()

    /** One row per usable parser: name, title, lang, MANGA|ANIME. */
    @JvmStatic
    fun catalogue(): List<Array<String>> = ContentParserSource.entries
        .filter { !it.isBroken && it.contentType !in UNSUPPORTED }
        .map { src ->
            arrayOf(
                src.name,
                src.title,
                src.locale.ifBlank { "all" },
                if (src.contentType in VIDEO) "ANIME" else "MANGA",
            )
        }

    @JvmStatic
    fun create(name: String): Any? {
        val source = ContentParserSource.entries.find { it.name == name } ?: return null
        val parser = Host.newParserInstance(source)
        return if (source.contentType in VIDEO) KototoroAnimeSource(parser) else KototoroMangaSource(parser)
    }
}
