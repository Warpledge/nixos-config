import json, sys, time, urllib.request, concurrent.futures as cf
B = sys.argv[1]
def chat(c, think, mt=600, kw=None):
    b = {"messages": [{"role": "user", "content": c}], "max_tokens": mt, "temperature": 1.0, "top_p": 0.95,
         "chat_template_kwargs": {"enable_thinking": think, **(kw or {})}}
    r = urllib.request.Request(B + "/v1/chat/completions", json.dumps(b).encode(), {"Content-Type": "application/json"})
    return json.load(urllib.request.urlopen(r, timeout=1800))
o = chat("Write about 300 words on how warehouses are lit at night.", False)
print("single nothink tps", round(o["timings"]["predicted_per_second"], 1), "draft acc", o["timings"].get("draft_n_accepted"), "/", o["timings"].get("draft_n"))
o = chat("Write a Python function that merges overlapping intervals, with tests.", True, 6000)
print("single think tps", round(o["timings"]["predicted_per_second"], 1), "tokens", o["usage"]["completion_tokens"], "draft acc", o["timings"].get("draft_n_accepted"), "/", o["timings"].get("draft_n"))
o = chat("Write a Python function that merges overlapping intervals, with tests.", True, 6000, {"medium_effort": True})
print("medium_effort tokens", o["usage"]["completion_tokens"], "tps", round(o["timings"]["predicted_per_second"], 1))
t0 = time.time()
with cf.ThreadPoolExecutor(4) as ex:
    n = sum(ex.map(lambda i: chat(f"Write about 250 words on topic #{i}: a forklift's night shift.", False, 400)["usage"]["completion_tokens"], range(4)))
print("parallel4 total tps", round(n / (time.time() - t0), 1))
