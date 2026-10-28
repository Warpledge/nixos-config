import base64, json, sys, time, urllib.request
B, IMG = sys.argv[1], sys.argv[2]
b64 = base64.b64encode(open(IMG, "rb").read()).decode()
for think in (False, True):
    body = {"messages": [{"role": "user", "content": [
        {"type": "image_url", "image_url": {"url": "data:image/png;base64," + b64}},
        {"type": "text", "text": "This is a frame from a first-person horror game set in a warehouse. Describe what is in the frame, list any text you can read, and say whether anything looks broken (missing textures, clipping, z-fighting, wrong lighting)."}]}],
        "max_tokens": 3000, "chat_template_kwargs": {"enable_thinking": think}}
    t0 = time.time()
    o = json.load(urllib.request.urlopen(urllib.request.Request(B + "/v1/chat/completions", json.dumps(body).encode(), {"Content-Type": "application/json"}), timeout=900))
    print(f"--- think={think} {time.time()-t0:.1f}s")
    print(o["choices"][0]["message"]["content"])
