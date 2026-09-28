package tsunagu.kototoro.bridge

import androidx.preference.PreferenceScreen
import eu.kanade.tachiyomi.source.ConfigurableSource
import eu.kanade.tachiyomi.source.model.Filter
import eu.kanade.tachiyomi.source.model.FilterList
import eu.kanade.tachiyomi.source.model.MangasPage
import eu.kanade.tachiyomi.source.model.Page
import eu.kanade.tachiyomi.source.model.SChapter
import eu.kanade.tachiyomi.source.model.SManga
import eu.kanade.tachiyomi.source.online.HttpSource
import okhttp3.Headers
import okhttp3.OkHttpClient
import org.skepsun.kototoro.parsers.ContentParser
import org.skepsun.kototoro.parsers.model.ContentListFilter
import org.skepsun.kototoro.parsers.model.ContentTag
import org.skepsun.kototoro.parsers.model.SortOrder
import rx.Observable

class KototoroMangaSource internal constructor(parser: ContentParser) : HttpSource(), ConfigurableSource {
    private val a = Adapter(parser)

    override val name: String = a.title
    override val lang: String = a.lang
    override val baseUrl: String get() = a.baseUrl
    override val id: Long = a.id
    override val supportsLatest: Boolean = a.latestOrder != null
    override val client: OkHttpClient by lazy { Host.clientFor(parser) }

    override fun headersBuilder(): Headers.Builder = a.headers().newBuilder()

    private fun page(page: Int, order: SortOrder, filter: ContentListFilter) = Observable.fromCallable {
        val (items, hasNext) = runBlockingIO { a.list(page, order, filter) }
        MangasPage(items.map(::toSManga), hasNext)
    }

    override fun fetchPopularManga(page: Int): Observable<MangasPage> = page(page, a.popularOrder, ContentListFilter.EMPTY)

    override fun fetchLatestUpdates(page: Int): Observable<MangasPage> =
        page(page, a.latestOrder ?: a.popularOrder, ContentListFilter.EMPTY)

    override fun fetchSearchManga(page: Int, query: String, filters: FilterList): Observable<MangasPage> {
        val sort = filters.filterIsInstance<SortFilter>().firstOrNull()?.state
        val include = mutableListOf<ContentTag>()
        val exclude = mutableListOf<ContentTag>()
        filters.forEach { f ->
            when (f) {
                is TagSelect -> f.tag()?.let(include::add)
                is TagGroup -> f.state.forEach { box ->
                    when (box) {
                        is TagBox -> if (box.isIncluded()) include += box.tag else if (box.isExcluded()) exclude += box.tag
                        is TagCheck -> if (box.state) include += box.tag
                        else -> {}
                    }
                }
                else -> {}
            }
        }
        val (order, filter) = a.filter(query, sort, include, exclude)
        return page(page, order, filter)
    }

    override fun getFilterList(): FilterList = FilterList(
        buildList {
            if (a.sortNames.size > 1) add(SortFilter(a.sortNames, a.popularIndex))
            a.categories.forEach { c ->
                if (c.exclusive) {
                    add(TagSelect(c.title, c.tags))
                } else {
                    add(TagGroup(c.title, c.tags.map { (title, tag) -> if (a.tagsExcludable) TagBox(title, tag) else TagCheck(title, tag) }))
                }
            }
        },
    )

    override fun setupPreferenceScreen(screen: PreferenceScreen) = a.settings.setup(screen)

    override fun fetchMangaDetails(manga: SManga): Observable<SManga> = Observable.fromCallable {
        toSManga(runBlockingIO { a.details(manga.url) }).apply { initialized = true }
    }

    override fun fetchChapterList(manga: SManga): Observable<List<SChapter>> = Observable.fromCallable {
        runBlockingIO { a.chapterList(manga.url) }.map { chapter ->
            SChapter.create().apply {
                url = chapter.url
                name = chapter.name
                chapter_number = chapter.number
                date_upload = chapter.uploadDate
                scanlator = chapter.scanlator
            }
        }
    }

    override suspend fun getPageList(chapter: SChapter): List<Page> =
        a.pages(chapter.url).mapIndexed { index, (url, _) -> Page(index, url) }

    override suspend fun getImageUrl(page: Page): String = a.resolve(page.url)

    private fun toSManga(item: Item): SManga = SManga.create().apply {
        url = item.url
        title = item.title
        thumbnail_url = item.cover
        description = item.description
        author = item.author
        genre = item.genre
        status = item.status
    }

    private class SortFilter(values: Array<String>, state: Int) : Filter.Select<String>("Sort", values, state)

    private class TagBox(title: String, val tag: ContentTag) : Filter.TriState(title)

    private class TagCheck(title: String, val tag: ContentTag) : Filter.CheckBox(title)

    private class TagGroup(name: String, boxes: List<Filter<*>>) : Filter.Group<Filter<*>>(name, boxes)

    // An exclusive category: one tag or none.
    private class TagSelect(name: String, private val tags: List<Pair<String, ContentTag>>) :
        Filter.Select<String>(name, arrayOf("Any") + tags.map { it.first }) {
        fun tag(): ContentTag? = tags.getOrNull(state - 1)?.second
    }
}
