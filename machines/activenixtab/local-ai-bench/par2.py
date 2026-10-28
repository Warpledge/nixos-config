import json, sys, time, urllib.request, concurrent.futures as cf
B, N = sys.argv[1], int(sys.argv[2])
def chat(i):
    b = {"messages": [{"role": "user", "content": f"Write a Python function #{i} that merges overlapping intervals, with tests."}],
         "max_tokens": 3000, "temperature": 1.0, "top_p": 0.95, "chat_template_kwargs": {"enable_thinking": True, "medium_effort": True}}
    r = urllib.request.Request(B + "/v1/chat/completions", json.dumps(b).encode(), {"Content-Type": "application/json"})
    return json.load(urllib.request.urlopen(r, timeout=1800))["usage"]["completion_tokens"]
t0 = time.time()
with cf.ThreadPoolExecutor(N) as ex:
    n = sum(ex.map(chat, range(N)))
print(f"parallel{N} thinking total tps", round(n / (time.time() - t0), 1))
