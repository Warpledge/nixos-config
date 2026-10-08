package tsunagu.kototoro.bridge

import androidx.preference.PreferenceScreen
import eu.kanade.tachiyomi.animesource.ConfigurableAnimeSource
import eu.kanade.tachiyomi.animesource.model.AnimeFilter
import eu.kanade.tachiyomi.animesource.model.AnimeFilterList
import eu.kanade.tachiyomi.animesource.model.AnimesPage
import eu.kanade.tachiyomi.animesource.model.SAnime
import eu.kanade.tachiyomi.animesource.model.SEpisode
import eu.kanade.tachiyomi.animesource.model.Video
import eu.kanade.tachiyomi.animesource.online.AnimeHttpSource
import okhttp3.Headers
import okhttp3.OkHttpClient
import org.skepsun.kototoro.parsers.ContentParser
import org.skepsun.kototoro.parsers.model.ContentListFilter
import org.skepsun.kototoro.parsers.model.ContentTag
import org.skepsun.kototoro.parsers.model.SortOrder
import rx.Observable

/** Kototoro video parsers: each chapter is an episode and each page of it a playable stream. */
class KototoroAnimeSource internal constructor(parser: ContentParser) : AnimeHttpSource(), ConfigurableAnimeSource {
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
        AnimesPage(items.map(::toSAnime), hasNext)
    }

    override fun fetchPopularAnime(page: Int): Observable<AnimesPage> = page(page, a.popularOrder, ContentListFilter.EMPTY)

    override fun fetchLatestUpdates(page: Int): Observable<AnimesPage> =
        page(page, a.latestOrder ?: a.popularOrder, ContentListFilter.EMPTY)

    override fun fetchSearchAnime(page: Int, query: String, filters: AnimeFilterList): Observable<AnimesPage> {
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

    override fun getFilterList(): AnimeFilterList = AnimeFilterList(
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

    override suspend fun getAnimeDetails(anime: SAnime): SAnime = toSAnime(a.details(anime.url)).apply { initialized = true }

    override suspend fun getEpisodeList(anime: SAnime): List<SEpisode> = a.chapterList(anime.url).map { chapter ->
        SEpisode.create().apply {
            url = chapter.url
            name = chapter.name.replace("Chapter", "Episode")
            episode_number = chapter.number
            date_upload = chapter.uploadDate
            scanlator = chapter.scanlator
        }
    }

    override suspend fun getVideoList(episode: SEpisode): List<Video> {
        val streams = a.pages(episode.url)
        val videos = streams.mapIndexed { index, (url, headers) ->
            Video(
                videoUrl = runCatching { a.resolve(url) }.getOrDefault(url),
                videoTitle = if (streams.size > 1) "${a.title} ${index + 1}" else a.title,
                headers = a.headers(headers),
            )
        }
        // Parsers list sources in site order; a direct file link there is often dead while the
        // HLS copy plays, so default to the first HLS source.
        (videos.firstOrNull { ".m3u8" in it.videoUrl } ?: videos.firstOrNull())?.preferred = true
        return videos
    }

    private fun toSAnime(item: Item): SAnime = SAnime.create().apply {
        url = item.url
        title = item.title
        thumbnail_url = item.cover
        description = item.description
        author = item.author
        genre = item.genre
        status = item.status
    }

    private class SortFilter(values: Array<String>, state: Int) : AnimeFilter.Select<String>("Sort", values, state)

    private class TagBox(title: String, val tag: ContentTag) : AnimeFilter.TriState(title)

    private class TagCheck(title: String, val tag: ContentTag) : AnimeFilter.CheckBox(title)

    private class TagGroup(name: String, boxes: List<AnimeFilter<*>>) : AnimeFilter.Group<AnimeFilter<*>>(name, boxes)

    // An exclusive category: one tag or none.
    private class TagSelect(name: String, private val tags: List<Pair<String, ContentTag>>) :
        AnimeFilter.Select<String>(name, arrayOf("Any") + tags.map { it.first }) {
        fun tag(): ContentTag? = tags.getOrNull(state - 1)?.second
    }
}
