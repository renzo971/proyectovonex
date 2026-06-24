> **Note:** Java package examples below use `com.acme.securities` as a fictional placeholder. Replace with your organization's package root before generating production code.

# Test Data Flow - Step-by-Step Instructions

## Quick Flow Reference

```
POST /test-data/populate 
  ↓
KafkaTestDataPublisher 
  ↓
JSON files (integration-test/resources/data/kafkaMessages/*.json)
  ↓
Kafka topics (acme.sec.{tenant}.settlement.*.state.v1)
  ↓
Camel Consumer Pipeline
  ↓
DeserializeProcessor
  ↓
StateMapper (ISO codes → Domain)
  ↓
Domain Objects
  ↓
Elasticsearch JSON docs ({tenant}-instructions/restrictions/allegements)
  ↓
Repository.findById()
  ↓
QueryHandler
  ↓
DomainMapper (Domain → API)
  ↓
Controller
  ↓
OpenAPI-validated Response
```

---

## Step 1: Trigger Test Data Population

**Endpoint:** `POST /api/v1/{tenant}/test-data/populate`

**Example:**
```bash
curl -X POST http://localhost:8080/api/v1/demo/test-data/populate
```

**What happens:**
- `TestDataController.populateTestData()` is called
- Calls `KafkaTestDataPublisher.publishTestData(tenant)`

---

## Step 2: Load Test JSON Files

**Location:** `integration-test/src/test/resources/data/kafkaMessages/`

**Files loaded:**
- `InstructionStatusAdvice.json` (ISO 20022: sese.024.001.13)
- `RestrictionStatusAdvice.json` (ISO 20022: semt.014.001.07)
- `InstructionModificationStatusAdvice.json`
- `InstructionCancellationStatusAdvice.json`
- `RestrictionCancellationStatusAdvice.json`

**Format:** ISO 20022 messages with ISO codes (BICFI, ISIN, etc.)

---

## Step 3: Publish to Kafka Topics

**KafkaTestDataPublisher actions:**
1. Read JSON file from resources
2. Serialize in Confluent wire format: `[0x00][schema_id][json_bytes]`
3. Publish to tenant-specific topic

**Topics:**
- `acme.sec.{tenant}.settlement.transactions.state.v1` (Instructions & Allegements)
- `acme.sec.{tenant}.settlement.restrictions.state.v1` (Restrictions)

**Example:** `acme.sec.demo.settlement.transactions.state.v1`

---

## Step 4: Camel Consumes Messages

**Pipelines:**
- `InstructionReadModelConsumerPipelineRoutes`
- `RestrictionReadModelConsumerPipelineRoutes`
- `AllegementReadModelConsumerPipelineRoutes`

**Stages:** Kafka Ingest → Deserialize → Map → Split → Generate ID → Serialize → Batch → Bulk Index

---

## Step 5: Deserialize Confluent Wire Format

**Component:** `DeserializeProcessor<SettlementTransactionState>`

**Input:** `byte[]` (Confluent format)  
**Output:** `SettlementTransactionState` DTO (ISO 20022 structure)

**State DTO Classes:**
- **Location:** `infrastructure/target/generated-sources/jsonschema2pojo/com/acme/securities/settlement/events/`
- **Files:** `SettlementTransactionState.java`, `RestrictionState.java`
- **Note:** These are auto-generated from JSON Schema. Verify field existence here before modifying mappers.

---

## Step 6: Map ISO Codes to Domain Objects

**Component:** `InstructionStateMapper` / `RestrictionStateMapper` / `AllegementStateMapper`

**Important:** Before modifying any mapper, verify the field exists in the State DTO class at:
`infrastructure/target/generated-sources/jsonschema2pojo/com/acme/securities/settlement/events/`

**Transformation:**
- ISO field `SctiesMvmntTp: "DELI"` → Domain enum `SecuritiesMovementType.DELIVERY`
- ISO field `AcctOwnrTxId: "TxId9ad501a36b53"` → Domain field `senderReference: "TxId9ad501a36b53"`
- ISO amounts/dates/parties → Domain value objects

**Output:** `List<Instruction>` / `List<Restriction>` / `List<Allegement>`

---

## Step 7: Store in Elasticsearch

**Index names:**
- `{tenant}-instructions` (e.g., `demo-instructions`)
- `{tenant}-restrictions` (e.g., `demo-restrictions`)
- `{tenant}-allegements` (e.g., `demo-allegements`)

**Process:**
1. Domain object → JSON serialization via Jackson
2. Bulk index via `ElasticsearchBulkProcessor`
3. Document ID = entity UUID (e.g., instructionId)

**Verify:**
```bash
GET /demo-instructions/_search
```

---

## Step 8: Query via API (Get by ID)

**Endpoint:** `GET /api/v1/{tenant}/instructions/{instructionId}`

**Flow:**
1. `InstructionController.getInstruction()` receives request
2. Creates `GetInstructionByIdQueryHandler` via factory
3. Handler calls `InstructionRepository.findCurrentDataById()`
4. Repository executes: `GET /{tenant}-instructions/_doc/{id}` in Elasticsearch
5. Returns JSON document

---

## Step 9: Map Elasticsearch JSON to Domain

**Component:** `InstructionMapper.fromJsonToDomainInstruction()`

**Input:** JSON string from Elasticsearch  
**Output:** `Instruction` domain object

---

## Step 10: Map Domain to API Model

**Component:** `InstructionMapper.fromDomainToApiInstruction()`

**Input:** `Instruction` domain object  
**Output:** `com.acme.securities.settlement.infrastructure.web.controller.model.Instruction` (OpenAPI-generated)

**Transformation:**
- Domain enum `SecuritiesMovementType.DELIVERY` → API string `"DELIVERY"`
- Domain UUID `instructionId` → API string with UUID format
- All nested objects mapped field-by-field

---

## Step 11: Return OpenAPI-Validated Response

**Controller:**
```java
return Response.ok(apiInstruction).build();
```

**Response validates against:** `docs/openapi.settlement-api.bundled.json`

**HTTP 200 Response:**
```json
{
  "instructionId": "123e4567-e89b-12d3-a456-426614174000",
  "senderReference": "TxId9ad501a36b53",
  "instructionType": "SETTLEMENT_INSTRUCTION",
  "securitiesMovementType": "DELIVERY",
  "status": { "processingStatus": "ACKNOWLEDGED_ACCEPTED" },
  "securities": { "isin": "DK0000009FT9" }
}
```

---

## Complete Example

```bash
# 1. Populate test data
curl -X POST http://localhost:8080/api/v1/demo/test-data/populate

# 2. Wait for processing (usually 2-5 seconds)
sleep 5

# 3. Get instruction by ID (replace with actual ID from test data)
curl -X GET http://localhost:8080/api/v1/demo/instructions/123e4567-e89b-12d3-a456-426614174000

# 4. Search instructions
curl -X POST http://localhost:8080/api/v1/demo/searches/instructions \
  -H "Content-Type: application/json" \
  -d '{"filters": {"isin": "DK0000009FT9"}, "pagination": {"page": 0, "size": 10}}'
```
