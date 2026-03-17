# API Reference Template

Documentation template for REST API endpoints.

---

## Template

```markdown
# {{ENDPOINT_NAME}}

> **Last Updated:** {{DATE}}

{{ONE_LINE_DESCRIPTION}}

## Request

`{{METHOD}} {{PATH}}`

### Headers

| Header | Required | Description |
|--------|----------|-------------|
| `Authorization` | Yes | Bearer token from authentication |
| `Content-Type` | Yes | `application/json` |

### Path Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `{{PARAM}}` | string | {{PARAM_DESCRIPTION}} |

### Query Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `{{QUERY_PARAM}}` | {{TYPE}} | {{DEFAULT}} | {{DESCRIPTION}} |

### Request Body

```json
{
  "{{FIELD_1}}": "{{EXAMPLE_1}}",
  "{{FIELD_2}}": {{EXAMPLE_2}}
}
```

### Body Schema

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `{{FIELD_1}}` | string | Yes | {{FIELD_1_DESC}} |
| `{{FIELD_2}}` | number | No | {{FIELD_2_DESC}} |

## Response

### Success ({{STATUS_CODE}} {{STATUS_TEXT}})

```json
{
  "id": "{{ID_EXAMPLE}}",
  "{{FIELD}}": "{{VALUE}}",
  "createdAt": "{{ISO_DATE}}"
}
```

### Response Schema

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Unique identifier |
| `{{FIELD}}` | {{TYPE}} | {{DESCRIPTION}} |
| `createdAt` | string | ISO 8601 timestamp |

### Error Responses

| Status | Code | Description |
|--------|------|-------------|
| 400 | `VALIDATION_ERROR` | Invalid input data |
| 401 | `UNAUTHORIZED` | Missing or invalid token |
| 403 | `FORBIDDEN` | Insufficient permissions |
| 404 | `NOT_FOUND` | Resource not found |
| 409 | `CONFLICT` | Resource already exists |

### Error Response Format

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Email is required",
    "details": [
      {"field": "email", "message": "Required field"}
    ]
  }
}
```

## Examples

### cURL

```bash
curl -X {{METHOD}} \
  {{BASE_URL}}{{PATH}} \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"{{FIELD}}": "{{VALUE}}"}'
```

### TypeScript

```typescript
const response = await fetch('{{BASE_URL}}{{PATH}}', {
  method: '{{METHOD}}',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    {{FIELD}}: '{{VALUE}}',
  }),
});

const data = await response.json();
```

## Related

- [{{RELATED_ENDPOINT}}](./{{related}}.md)
- [Authentication](./authentication.md)

---
_Source: `{{SOURCE_FILE}}`_
```

---

## Usage Notes

### One API Per Page

From remotion skill: Each endpoint gets its own page. Don't combine multiple endpoints.

### Required Sections

| Section | When to Include |
|---------|-----------------|
| Request | Always |
| Headers | If auth or special headers |
| Path Parameters | If URL has params |
| Query Parameters | If filters/pagination |
| Request Body | For POST/PUT/PATCH |
| Response | Always |
| Errors | Always |
| Examples | Recommended |

### Error Documentation

Document all possible error responses with:
- HTTP status code
- Application error code
- Human-readable description
- When this error occurs

---

## Source Attribution

Based on patricio0312rev api-docs-generator skill with OpenAPI patterns.
