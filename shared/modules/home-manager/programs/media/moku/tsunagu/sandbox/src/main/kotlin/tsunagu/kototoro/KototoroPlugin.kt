package tsunagu.kototoro

import tsunagu.loader.ContentType
import tsunagu.loader.ContentTypeClassifier
import tsunagu.loader.Dex2JarConverter
import tsunagu.loader.ExtensionLoadException
import tsunagu.loader.LoadedExtension
import java.io.File
import java.net.URL
import java.net.URLClassLoader
import java.nio.file.Files
import java.security.MessageDigest
import java.util.concurrent.ConcurrentHashMap
import java.util.zip.ZipFile

/**
 * Kototoro parser plugins (a bare classes.dex in a jar, no AndroidManifest) exposed as one
 * Tsunagu extension per parser, with ids of the form "org.skepsun.kototoro.parsers.<SOURCE>".
 *
 * Nothing in this file may reference org.skepsun.* or tsunagu.kototoro.bridge.*: those
 * classes only exist inside the per-plugin class loader built by [pluginLoader].
 */
object KototoroPlugin {
    const val PACKAGE = "org.skepsun.kototoro.parsers"

    data class CatalogueEntry(
        val id: String,
        val title: String,
        val lang: String,
        val contentType: ContentType,
    )

    // Converted jars keyed by plugin content hash; every per-parser copy of the same
    // plugin version shares one dex2jar pass.
    private val converted = ConcurrentHashMap<String, File>()

    fun isPlugin(file: File): Boolean {
        if (file.extension != "jar") return false
        return runCatching {
            ZipFile(file).use { it.getEntry("classes.dex") != null && it.getEntry("AndroidManifest.xml") == null }
        }.getOrDefault(false)
    }

    fun isCatalogueRequest(extensionId: String): Boolean = extensionId == PACKAGE

    fun catalogue(file: File): List<CatalogueEntry> {
        val loader = pluginLoader(file)
        try {
            @Suppress("UNCHECKED_CAST")
            val rows = entry(loader).getMethod("catalogue").invoke(null) as List<Array<String>>
            return rows.map { (name, title, lang, type) ->
                CatalogueEntry("$PACKAGE.$name", title, lang, ContentType.valueOf(type))
            }
        } finally {
            loader.close()
        }
    }

    fun load(file: File, extensionId: String): LoadedExtension {
        val name = extensionId.removePrefix("$PACKAGE.")
        if (name == extensionId || name.isEmpty()) {
            throw ExtensionLoadException("$extensionId is not a Kototoro parser id")
        }
        val loader = pluginLoader(file)
        val source = entry(loader).getMethod("create", String::class.java).invoke(null, name)
            ?: throw ExtensionLoadException("Kototoro plugin ${file.name} has no parser $name")
        val contentType = ContentTypeClassifier.classify(source.javaClass)
            ?: throw ExtensionLoadException("could not classify Kototoro parser $name")
        return LoadedExtension(extensionId, source, loader, contentType)
    }

    private fun entry(loader: ClassLoader): Class<*> = loader.loadClass("tsunagu.kototoro.bridge.Entry")

    private fun pluginLoader(file: File): URLClassLoader {
        val hash = MessageDigest.getInstance("SHA-256").digest(file.readBytes()).joinToString("") { "%02x".format(it) }
        val jar = converted.compute(hash) { _, cached ->
            cached?.takeIf { it.exists() } ?: Dex2JarConverter.convert(file)
        }!!
        val self = KototoroPlugin::class.java.protectionDomain.codeSource.location
        val urls = arrayOf(jar.toURI().toURL()) + runtimeLibs() + self
        return PrefixFirstClassLoader(urls, KototoroPlugin::class.java.classLoader)
    }

    // jsoup and androidx.collection at the versions the plugin was built against; the sandbox's
    // own jsoup is older. Shipped as nested jars so they never leak into Tachiyomi extensions,
    // named *.lib because Shadow unpacks any *.jar it finds among resources.
    private val libs: Array<URL> by lazy {
        val dir = Files.createTempDirectory("tsunagu-kototoro-libs").toFile().apply { deleteOnExit() }
        val index = KototoroPlugin::class.java.getResource("/kototoro/libs/index.txt")?.readText().orEmpty()
        index.lines().filter { it.isNotBlank() }.map { name ->
            val out = File(dir, name.removeSuffix(".lib") + ".jar").apply { deleteOnExit() }
            KototoroPlugin::class.java.getResourceAsStream("/kototoro/libs/$name")!!.use { input ->
                out.outputStream().use { input.copyTo(it) }
            }
            out.toURI().toURL()
        }.toTypedArray()
    }

    private fun runtimeLibs(): Array<URL> = libs
}

/** Loads the listed packages from its own URLs first and everything else from the parent. */
private class PrefixFirstClassLoader(
    urls: Array<URL>,
    parent: ClassLoader,
) : URLClassLoader(urls, parent) {
    private val ownPrefixes = listOf("org.skepsun.", "org.jsoup.", "androidx.collection.", "tsunagu.kototoro.bridge.")

    override fun loadClass(name: String, resolve: Boolean): Class<*> {
        if (ownPrefixes.none { name.startsWith(it) }) return super.loadClass(name, resolve)
        synchronized(getClassLoadingLock(name)) {
            val c = findLoadedClass(name) ?: findClass(name)
            if (resolve) resolveClass(c)
            return c
        }
    }

    override fun getResource(name: String): URL? = findResource(name) ?: super.getResource(name)
}
