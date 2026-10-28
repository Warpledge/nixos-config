// Cursor smear: when the cursor jumps, it stretches from where it was to where
// it is and the tail catches up, fading out. Typing one cell at a time doesn't
// trigger it.

const float DURATION = 0.2; // seconds the smear lasts
const float OPACITY = 0.6; // at the head, at the start

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    fragColor = texture(iChannel0, fragCoord / iResolution.xy);

    float t = clamp((iTime - iTimeCursorChange) / DURATION, 0.0, 1.0);
    if (t >= 1.0) return;

    // Cursor rects are top-left corner plus size, with y pointing up
    vec2 head = iCurrentCursor.xy + vec2(iCurrentCursor.z, -iCurrentCursor.w) * 0.5;
    vec2 from = iPreviousCursor.xy + vec2(iPreviousCursor.z, -iPreviousCursor.w) * 0.5;
    if (distance(head, from) < iCurrentCursor.w) return;

    // The tail eases in toward the head
    vec2 tail = mix(from, head, 1.0 - pow(1.0 - t, 3.0));

    // A bar cursor is 1-2 px wide, so size the smear from the line height too
    float radius = max(iCurrentCursor.z, iCurrentCursor.w * 0.35) * 0.5;
    vec2 pa = fragCoord - head;
    vec2 ba = tail - head;
    float h = clamp(dot(pa, ba) / max(dot(ba, ba), 1e-4), 0.0, 1.0);
    float d = length(pa - ba * h) - mix(radius, radius * 0.3, h);

    float a = (1.0 - smoothstep(-1.0, 1.0, d)) * OPACITY * (1.0 - h * 0.6) * (1.0 - t);
    fragColor.rgb = mix(fragColor.rgb, iCurrentCursorColor.rgb, a);
}
