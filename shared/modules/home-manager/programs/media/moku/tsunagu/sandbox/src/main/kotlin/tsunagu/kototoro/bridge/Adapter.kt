package tsunagu.kototoro.bridge

import okhttp3.Headers
import org.skepsun.kototoro.parsers.ContentParser
import org.skepsun.kototoro.parsers.model.Content
import org.skepsun.kototoro.parsers.model.ContentChapter
import org.skepsun.kototoro.parsers.model.ContentListFilter
import org.skepsun.kototoro.parsers.model.ContentPage
import org.skepsun.kototoro.parsers.model.ContentParserSource
import org.skepsun.kototoro.parsers.model.ContentState
import org.skepsun.kototoro.parsers.model.ContentTag
import org.skepsun.kototoro.parsers.model.SortOrder
import java.util.concurrent.ConcurrentHashMap

/** Shared SManga/SAnime fields, filled from a Kototoro [Content]. */
internal class Item(
    val url: String,
    val title: String,
    val cover: String?,
    val description: String?,
    val author: String?,
    val genre: String?,
    val status: Int,
)

/** Shared SChapter/SEpisode fields, filled from a Kototoro [ContentChapter]. */
internal class Chapter(
    val url: String,
    val name: String,
    val number: Float,
    val uploadDate: Long,
    val scanlator: String?,
)

/** One tag category; an exclusive one takes a single tag at a time. */
internal class TagCategory(val title: String, val exclusive: Boolean, val tags: List<Pair<String, ContentTag>>)

/** Parser-side state shared by the manga and anime sources: model caches, paging and filters. */
internal class Adapter(val parser: ContentParser) {
    private val source = parser.source
    val title: String = (source as? ContentParserSource)?.title ?: source.name
    val lang: String = source.locale.ifBlank { "all" }
    val baseUrl: String get() = "https://${parser.domain}"

    val id: Long = sourceId(source)
    val settings = Settings(parser)

    private val sortOrders = parser.availableSortOrders.sortedBy { it.ordinal }
    val popularOrder: SortOrder = SortOrder.POPULARITY.takeIf { it in sortOrders } ?: sortOrders.first()
    val latestOrder: SortOrder? = listOf(SortOrder.UPDATED, SortOrder.NEWEST, SortOrder.ADDED).firstOrNull { it in sortOrders }
    val sortNames: Array<String> = sortOrders.map { it.label() }.toTypedArray()
    val popularIndex: Int = sortOrders.indexOf(popularOrder)

    val tagsExcludable: Boolean get() = parser.filterCapabilities.isTagsExclusionSupported

    /** The parser's tag categories in its own order; a flat tag list becomes one sorted "Tags" group. */
    val categories: List<TagCategory> by lazy {
        val options = runCatching { runBlockingIO { parser.getFilterOptions() } }.getOrNull() ?: return@lazy emptyList()
        val grouped = options.tagGroups.ifEmpty { options.effectiveTagGroups }.map { g ->
            TagCategory(
                Fields.title(g).ifBlank { "Tags" },
                Fields.isExclusive(g),
                Fields.tags(g).map { Fields.title(it) to it },
            )
        }
        grouped.filter { it.tags.isNotEmpty() }.ifEmpty {
            val flat = options.availableTags.map { Fields.title(it) to it }.sortedBy { it.first.lowercase() }
            if (flat.isEmpty()) emptyList() else listOf(TagCategory("Tags", false, flat))
        }
    }

    private val contents = ConcurrentHashMap<String, Content>()
    private val chapters = ConcurrentHashMap<String, ContentChapter>()
    private val pages = ConcurrentHashMap<String, ContentPage>()

    // Kototoro pages by item offset, Tachiyomi by page number: remember where each page ended.
    private val pageEnds = ConcurrentHashMap<String, MutableMap<Int, Int>>()

    suspend fun list(page: Int, order: SortOrder, filter: ContentListFilter): Pair<List<Item>, Boolean> {
        val key = "$order|$filter"
        val ends = pageEnds.getOrPut(key) { ConcurrentHashMap() }
        val offset = if (page <= 1) 0 else ends[page - 1] ?: ((page - 1) * (ends[1] ?: 20))
        settings.syncLogin()
        val results = parser.getList(offset, order, filter)
        ends[page] = offset + results.size
        results.forEach { contents[Fields.url(it)] = it }
        return results.map(::item) to results.isNotEmpty()
    }

    fun filter(query: String, orderIndex: Int?, include: List<ContentTag>, exclude: List<ContentTag>): Pair<SortOrder, ContentListFilter> {
        val caps = parser.filterCapabilities
        val order = orderIndex?.let { sortOrders.getOrNull(it) } ?: popularOrder
        val withTags = query.isBlank() || caps.isSearchWithFiltersSupported
        val included = if (!withTags) emptySet() else if (caps.isMultipleTagsSupported) include.toSet() else include.take(1).toSet()
        val excluded = if (withTags && caps.isTagsExclusionSupported) exclude.toSet() else emptySet()
        return order to ContentListFilter(query = query.ifBlank { null }, tags = included, tagsExclude = excluded)
    }

    private fun content(url: String): Content = contents[url] ?: Content(
        id = parser.generateUid(url),
        title = "",
        altTitles = emptySet(),
        url = url,
        publicUrl = url.toAbsoluteUrl(parser.domain),
        rating = RATING_UNKNOWN,
        contentRating = null,
        coverUrl = null,
        tags = emptySet(),
        state = null,
        authors = emptySet(),
        source = source,
    )

    private suspend fun detailed(url: String): Content {
        settings.syncLogin()
        return parser.getDetails(content(url)).also { detailed ->
            contents[url] = detailed
            Fields.chapters(detailed)?.forEach { chapters[Fields.url(it)] = it }
        }
    }

    suspend fun details(url: String): Item = item(detailed(url))

    /** Newest first, as Tachiyomi expects. */
    suspend fun chapterList(url: String): List<Chapter> =
        Fields.chapters(detailed(url)).orEmpty().asReversed().map { c ->
            Chapter(
                url = Fields.url(c),
                name = Fields.title(c)?.takeIf { it.isNotBlank() }
                    ?: Fields.number(c).let { n -> if (n > 0f) "Chapter ${n.clean()}" else "Chapter" },
                number = Fields.number(c),
                uploadDate = Fields.uploadDate(c),
                scanlator = listOfNotNull(Fields.branch(c), Fields.scanlator(c))
                    .filter { it.isNotBlank() }.joinToString(" · ").ifBlank { null },
            )
        }

    private fun chapter(url: String): ContentChapter = chapters[url] ?: ContentChapter(
        id = parser.generateUid(url),
        title = null,
        number = 0f,
        volume = 0,
        url = url,
        scanlator = null,
        uploadDate = 0L,
        branch = null,
        source = source,
    )

    /** Page URLs of a chapter, with any per-page request headers. */
    suspend fun pages(chapterUrl: String): List<Pair<String, Map<String, String>?>> =
        parser.getPages(chapter(chapterUrl).also { settings.syncLogin() }).map { page ->
            val url = Fields.url(page)
            pages[url] = page
            url to Fields.headers(page)
        }

    suspend fun resolve(pageUrl: String): String {
        val page = pages[pageUrl] ?: ContentPage(parser.generateUid(pageUrl), pageUrl, null, null, source)
        return Host.httpUrlFor(parser.getPageUrl(page))
    }

    fun headers(extra: Map<String, String>? = null): Headers = Headers.Builder().apply {
        parser.getRequestHeaders().forEach { (name, value) -> set(name, value) }
        if (get("Referer") == null) set("Referer", "$baseUrl/")
        extra?.forEach { (name, value) -> set(name, value) }
    }.build()

    private fun item(c: Content) = Item(
        url = Fields.url(c),
        title = Fields.title(c),
        cover = Fields.cover(c)?.let(Host::httpUrlFor),
        description = Fields.description(c),
        author = Fields.authors(c).joinToString().ifBlank { null },
        genre = Fields.tags(c).joinToString { Fields.title(it) }.ifBlank { null },
        // SManga/SAnime status constants
        status = when (Fields.state(c)) {
            ContentState.ONGOING -> 1
            ContentState.FINISHED -> 2
            ContentState.ABANDONED -> 5
            ContentState.PAUSED -> 6
            else -> 0
        },
    )
}

// Top-level Kototoro helpers are invisible to the compiler once the plugin is dex'd (no
// .kotlin_module), so these mirror util/ContentParserEnv.kt, util/Parse.kt and model/Constants.kt.

private const val RATING_UNKNOWN = -1f

private fun ContentParser.generateUid(url: String): Long {
    var h = 1125899906842597L
    source.name.forEach { h = 31 * h + it.code }
    url.forEach { h = 31 * h + it.code }
    return h
}

private fun String.toAbsoluteUrl(domain: String): String = when {
    startsWith("//") -> "https:$this"
    startsWith('/') -> "https://$domain$this"
    Regex("^\\w{2,6}://", RegexOption.IGNORE_CASE).containsMatchIn(this) -> this
    else -> "https://$domain/$this"
}

private fun Float.clean(): String = if (this % 1f == 0f) toInt().toString() else toString()

private fun SortOrder.label(): String = name.lowercase().split('_')
    .joinToString(" ") { part -> part.replaceFirstChar { it.uppercase() } }
    .replace(" Asc", " (ascending)")
    .replace(" Desc", " (descending)")

internal fun <T> runBlockingIO(block: suspend () -> T): T =
    kotlinx.coroutines.runBlocking(kotlinx.coroutines.Dispatchers.IO) { block() }
