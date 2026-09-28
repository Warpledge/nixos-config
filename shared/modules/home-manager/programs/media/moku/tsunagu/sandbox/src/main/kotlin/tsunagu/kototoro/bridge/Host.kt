package tsunagu.kototoro.bridge

import eu.kanade.tachiyomi.network.NetworkHelper
import okhttp3.CookieJar
import okhttp3.HttpUrl
import okhttp3.Interceptor
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Protocol
import okhttp3.Request
import okhttp3.Response
import okhttp3.ResponseBody.Companion.toResponseBody
import org.graalvm.polyglot.Context
import org.koin.core.context.GlobalContext
import org.skepsun.kototoro.parsers.ContentLoaderContext
import org.skepsun.kototoro.parsers.ContentParser
import org.skepsun.kototoro.parsers.bitmap.Bitmap
import org.skepsun.kototoro.parsers.bitmap.Rect
import org.skepsun.kototoro.parsers.config.ContentSourceConfig
import org.skepsun.kototoro.parsers.model.Content
import org.skepsun.kototoro.parsers.model.ContentParserSource
import org.skepsun.kototoro.parsers.model.ContentSource
import org.skepsun.kototoro.parsers.network.UserAgents
import org.skepsun.kototoro.parsers.util.LinkResolver
import java.awt.image.BufferedImage
import java.io.ByteArrayOutputStream
import java.io.File
import java.net.HttpCookie
import java.net.URI
import java.net.URLEncoder
import java.util.concurrent.ConcurrentHashMap
import javax.imageio.ImageIO

/** The app-side services Kototoro parsers call back into, backed by Tsunagu's network stack. */
object Host : ContentLoaderContext() {
    private val network: NetworkHelper by lazy { GlobalContext.get().get() }

    // Tsunagu's shared cookie jar, the one its Cloudflare solver also fills.
    override val cookieJar: CookieJar by lazy { network.client.cookieJar }

    /** The store keeps expired cookies and sends them anyway, so a logout has to remove them. */
    fun removeCookies(host: String, names: Collection<String>) {
        val uri = URI("https://$host/")
        names.forEach { network.cookieStore.remove(uri, HttpCookie(it, "").apply { path = "/" }) }
    }

    override val httpClient: OkHttpClient by lazy {
        network.client.newBuilder()
            .addInterceptor(ParserInterceptor(null))
            .build()
    }

    private val parsers = ConcurrentHashMap<ContentSource, ContentParser>()

    // The generated factory is internal to the plugin, so it is reached reflectively.
    private val factory by lazy {
        Class.forName("org.skepsun.kototoro.parsers.ContentParserFactoryKt", true, Host::class.java.classLoader)
            .getDeclaredMethod("newParser", ContentParserSource::class.java, ContentLoaderContext::class.java)
            .apply { isAccessible = true }
    }

    override fun newParserInstance(source: ContentSource): ContentParser =
        parsers.getOrPut(source) { factory.invoke(null, source as ContentParserSource, this) as ContentParser }

    fun clientFor(parser: ContentParser): OkHttpClient =
        network.client.newBuilder().addInterceptor(ParserInterceptor(parser)).build()

    /**
     * Some parsers decrypt images into temp files and return file:// URIs, which
     * Tsunagu only fetches over HTTP. They are handed out as http://[LOCAL_HOST]/… and served
     * from disk by [ParserInterceptor]; anything outside the temp dir is left as is.
     */
    fun httpUrlFor(url: String): String {
        if (!url.startsWith("file:")) return url
        val file = runCatching { File(URI(url)).canonicalFile }.getOrNull() ?: return url
        if (!file.path.startsWith(tempDir.path + File.separator)) return url
        return "http://$LOCAL_HOST/file?path=" + URLEncoder.encode(file.path, Charsets.UTF_8)
    }

    fun localFile(url: HttpUrl): File? {
        if (url.host != LOCAL_HOST) return null
        val file = File(url.queryParameter("path") ?: return null).canonicalFile
        return file.takeIf { it.path.startsWith(tempDir.path + File.separator) && it.isFile }
    }

    private val tempDir = File(System.getProperty("java.io.tmpdir")).canonicalFile
    const val LOCAL_HOST = "kototoro.local"

    override fun newLinkResolver(link: HttpUrl): LinkResolver = object : LinkResolver {
        override val link: HttpUrl = link
        override suspend fun getSource(): ContentSource? = null
        override suspend fun getContent(): Content? = null
    }

    @Deprecated("Provide a base url")
    override suspend fun evaluateJs(script: String): String? = evaluateJs("", script)

    override suspend fun evaluateJs(baseUrl: String, script: String): String? =
        Context.newBuilder("js").allowAllAccess(false).build().use { ctx ->
            ctx.eval("js", script)?.takeUnless { it.isNull }?.toString()
        }

    private val configs = ConcurrentHashMap<ContentSource, ContentSourceConfig>()

    override fun getConfig(source: ContentSource): ContentSourceConfig =
        configs.getOrPut(source) { PrefsConfig(prefsOf(source)) }

    override fun getDefaultUserAgent(): String = UserAgents.CHROME_DESKTOP

    override fun redrawImageResponse(response: Response, redraw: (Bitmap) -> Bitmap): Response {
        val src = response.body.byteStream().use(ImageIO::read) ?: error("cannot decode image ${response.request.url}")
        val out = redraw(AwtBitmap(src)) as AwtBitmap
        val png = ByteArrayOutputStream().also { ImageIO.write(out.image, "png", it) }.toByteArray()
        return response.newBuilder().body(png.toResponseBody("image/png".toMediaType())).build()
    }

    override fun createBitmap(width: Int, height: Int): Bitmap =
        AwtBitmap(BufferedImage(width, height, BufferedImage.TYPE_INT_ARGB))
}

/**
 * Adds the parser's Referer and routes the request through the parser, which is itself an
 * OkHttp interceptor (image descrambling, auth headers). Parser-issued requests carry their
 * source as a tag; requests Tsunagu builds for a bridged source use [bound].
 */
private class ParserInterceptor(private val bound: ContentParser?) : Interceptor {
    override fun intercept(chain: Interceptor.Chain): Response {
        val request = chain.request()
        if (request.url.host == Host.LOCAL_HOST) {
            val file = Host.localFile(request.url)
            return Response.Builder()
                .request(request)
                .protocol(Protocol.HTTP_1_1)
                .code(if (file != null) 200 else 404)
                .message(if (file != null) "OK" else "Not Found")
                .body((file?.readBytes() ?: ByteArray(0)).toResponseBody(mediaTypeOf(file)))
                .build()
        }
        val parser = request.tag(ContentSource::class.java)?.let(Host::newParserInstance) ?: bound
            ?: return chain.proceed(request)
        val withReferer = if (request.header("Referer") == null) {
            request.newBuilder().header("Referer", "https://${parser.domain}/").build()
        } else {
            request
        }
        return parser.intercept(ProxyChain(chain, withReferer))
    }

    private class ProxyChain(private val delegate: Interceptor.Chain, private val request: Request) :
        Interceptor.Chain by delegate {
        override fun request(): Request = request
    }

    private fun mediaTypeOf(file: File?) = when (file?.extension?.lowercase()) {
        "png" -> "image/png"
        "webp" -> "image/webp"
        "gif" -> "image/gif"
        else -> "image/jpeg"
    }.toMediaType()
}

private class AwtBitmap(val image: BufferedImage) : Bitmap {
    override val width: Int get() = image.width
    override val height: Int get() = image.height

    override fun drawBitmap(sourceBitmap: Bitmap, src: Rect, dst: Rect) {
        val source = (sourceBitmap as AwtBitmap).image
        image.createGraphics().apply {
            drawImage(source, dst.left, dst.top, dst.right, dst.bottom, src.left, src.top, src.right, src.bottom, null)
            dispose()
        }
    }
}
