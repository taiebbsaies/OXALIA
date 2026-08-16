# External AI service setup — OXALIA

Exam inference is fully decoupled from the mobile app and the rest of the
backend behind the `ModelAdapter` interface
(`oxalia_back/app/core/model_adapter.py`). Two adapters exist today:

- `StubModelAdapter` — placeholder, returns random findings. Used by default.
- `HttpModelAdapter` — calls a real external AI service over HTTP.

Switching between them is a single environment variable — no code changes,
no changes to routers, repositories, or the mobile app (which already treats
`result_json` as an opaque dict).

## 1. Configure the external service

In `oxalia_back/.env`:

```
USE_STUB_MODEL=false
AI_SERVICE_URL=https://your-ai-service.example.com/predict
AI_SERVICE_API_KEY=your-api-key   # optional, omit if the service is public
AI_SERVICE_TIMEOUT_SECONDS=30
```

Leave `USE_STUB_MODEL=true` (the default) to keep using the placeholder
while no real service is configured yet.

## 2. Expected request/response contract

`HttpModelAdapter` sends a `multipart/form-data` `POST` to `AI_SERVICE_URL`
with the exam image as the `file` field, and (if `AI_SERVICE_API_KEY` is set)
an `Authorization: Bearer <key>` header.

It expects a JSON response shaped like:

```json
{
  "findings": [
    { "label": "Pneumonia", "probability": 0.87 },
    { "label": "No Finding", "probability": 0.12 }
  ]
}
```

## 3. Swapping to a different AI service later

If the real service (e.g. the final OXALIA 2D model) returns a different
response shape, only `_parse_response()` in
`oxalia_back/app/core/http_model_adapter.py` needs to change — it maps the
raw external payload to our stable `{"model_version", "findings",
"processed_file"}` shape. Everything downstream (storage, API, mobile app)
is unaffected.

For a fully custom integration (e.g. loading local model weights instead of
calling an HTTP service), implement a new class satisfying `ModelAdapter`
and select it in `oxalia_back/app/services/inference_orchestrator.py`.

## 4. Testing end-to-end

1. Set `USE_STUB_MODEL=false` and fill in `AI_SERVICE_URL` (and
   `AI_SERVICE_API_KEY` if needed) in `.env`.
2. Restart the backend.
3. Upload an exam from the mobile app as usual — inference now calls the
   configured external service instead of the stub.
4. If the exam ends up `FAILED`, check the backend logs: `HttpModelAdapter`
   raises on missing configuration, HTTP errors, and timeouts, which the
   orchestrator already turns into a failed exam + push notification.
