package tsunagu.kototoro.bridge;

import java.util.List;
import java.util.Map;
import java.util.Set;
import org.skepsun.kototoro.parsers.config.ConfigKey;
import org.skepsun.kototoro.parsers.model.Content;
import org.skepsun.kototoro.parsers.model.ContentChapter;
import org.skepsun.kototoro.parsers.model.ContentPage;
import org.skepsun.kototoro.parsers.model.ContentState;
import org.skepsun.kototoro.parsers.model.ContentTag;
import org.skepsun.kototoro.parsers.model.ContentTagGroup;

/**
 * Field reads for Kototoro's @JvmField models. d8 drops @JvmField (class-file retention), so
 * Kotlin compiled against the dex'd plugin would call getters that do not exist; Java reads
 * the public fields directly.
 */
final class Fields {
    private Fields() {}

    static String url(Content c) { return c.url; }
    static String title(Content c) { return c.title; }
    static String cover(Content c) { return c.largeCoverUrl != null ? c.largeCoverUrl : c.coverUrl; }
    static String description(Content c) { return c.description; }
    static Set<ContentTag> tags(Content c) { return c.tags; }
    static Set<String> authors(Content c) { return c.authors; }
    static ContentState state(Content c) { return c.state; }
    static List<ContentChapter> chapters(Content c) { return c.chapters; }

    static String url(ContentChapter c) { return c.url; }
    static String title(ContentChapter c) { return c.title; }
    static float number(ContentChapter c) { return c.number; }
    static long uploadDate(ContentChapter c) { return c.uploadDate; }
    static String branch(ContentChapter c) { return c.branch; }
    static String scanlator(ContentChapter c) { return c.scanlator; }

    static String url(ContentPage p) { return p.url; }
    static Map<String, String> headers(ContentPage p) { return p.headers; }

    static String title(ContentTag t) { return t.title; }

    static String title(ContentTagGroup g) { return g.title; }
    static Set<ContentTag> tags(ContentTagGroup g) { return g.tags; }
    static boolean isExclusive(ContentTagGroup g) { return g.isExclusive; }

    static String key(ConfigKey<?> k) { return k.key; }
    static String title(ConfigKey.Text k) { return k.title; }
    static String title(ConfigKey.Toggle k) { return k.title; }
    static String title(ConfigKey.PreferredLanguage k) { return k.title; }
    static String[] presets(ConfigKey.Domain k) { return k.presetValues; }
    static Map<String, String> presets(ConfigKey.PreferredLanguage k) { return k.presetValues; }
}
