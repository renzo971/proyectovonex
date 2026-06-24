# Fix Mapping Issues - Prompt Template

## Problem Analysis

When you encounter a mapping issue, paste the error message below:

```
[PASTE ERROR MESSAGE HERE]
```

## Error Pattern Recognition

Analyze the error to identify:

1. **Entity Type**: Which entity? (Instruction, Restriction, Allegement)
2. **Missing Fields**: Which required fields are missing from the API response?
3. **Entity ID**: What is the UUID of the affected entity?
4. **Expected vs Actual**: Compare the required fields vs actual response

### Example Error Breakdown

```
Error: object has missing required properties (["instructionType"])
Required: ["allegementId","clientOfTheCounterparty","clientOfTheParticipant","commonIdentification",
           "counterpartyDetails","createdAt","financialInstrumentIdentification","instructionType",
           "marketInfrastructureReference","movementType","partyDetails","paymentType",
           "quantityAndAccountDetails","senderReference","settlementAmount","settlementParameters",
           "status","tradeDetails"]
Missing: ["instructionType"]
```

## Fix Strategy

**IMPORTANT:** Before making any mapping changes, verify that the required fields exist in the State DTO classes.

**State DTO Location:** Generated files are located at:
`infrastructure\target\generated-sources\jsonschema2pojo\com\acme\securities\settlement\events`

Follow the data flow to locate and fix the issue:

### Step 1: Verify Field Existence in State DTO

Before modifying any mapper, check if the field exists in the generated State classes:
- `SettlementTransactionState` (for Instructions and Allegements)
- `RestrictionState` (for Restrictions)

If the field is missing from the State DTO, the issue is upstream (Kafka message structure or schema).

### Step 2: Identify the Data Flow Layer

Determine where the field is lost:

```
ISO 20022 Message (Kafka)
    ↓
SettlementTransactionState DTO      ← Check if field exists in generated State class
    ↓
StateMapper (ISO → Domain)          ← Check if field is mapped from ISO
    ↓
Domain Object (Allegement)          ← Check if field exists in domain
    ↓
Elasticsearch JSON Document         ← Check if field is stored
    ↓
Domain Mapper (JSON → Domain)       ← Check if field is deserialized
    ↓
API Mapper (Domain → API)           ← Check if field is mapped to API model
    ↓
API Response
```

## Testing Instructions

### Test Flow Decision Tree

```
Did you change any of:
- JSON test data files (integration-test/resources/data/kafkaMessages/*.json)
- State DTO classes (SettlementTransactionState, RestrictionState)
- StateMapper classes ({Entity}StateMapper.java)
    │
    ├─ YES → Full Flow Test (Repopulate + Check ES + Check API)
    │
    └─ NO → API Only Test (Just check API response)
```

### Full Flow Test (When Test Data/Mapping Changed)

```powershell
# Step 1: Populate test data (triggers Kafka → Camel → Elasticsearch flow)
Invoke-WebRequest -Uri 'http://localhost:8080/api/v1/cph/test-data/populate' -Method POST -Headers @{'accept'='*/*'}

# Step 2: Wait for async processing (Camel pipeline + ES indexing)
Start-Sleep -Seconds 5

# Step 3: Check Elasticsearch document directly
Invoke-WebRequest -Uri 'http://localhost:9200/cph-{entity}s/_doc/{id}' -UseBasicParsing | 
    Select-Object -ExpandProperty Content | 
    ConvertFrom-Json | 
    ConvertTo-Json -Depth 10

# Expected: Field should be present in ES document
# If missing → Problem in StateMapper or domain serialization

# Step 4: Check API response
Invoke-WebRequest -Uri 'http://localhost:8080/tenants/cph/settlement/v1/{entity}s/{id}' -Headers @{'accept'='application/json'} -UseBasicParsing | 
    Select-Object -ExpandProperty Content | 
    ConvertFrom-Json

# Expected: Field should be present in API response
# If missing → Problem in API mapper
```

### API Only Test (When Only Mapper Changed)

```powershell
# Check API response directly (no need to repopulate data)
Invoke-WebRequest -Uri 'http://localhost:8080/tenants/cph/settlement/v1/{entity}s/{id}' -Headers @{'accept'='application/json'} -UseBasicParsing | 
    Select-Object -ExpandProperty Content | 
    ConvertFrom-Json

# Expected: Field should now be present in API response
```

### Automated Test Command

Replace placeholders and run:

```powershell
# Configuration
$tenant = "cph"
$entityType = "allegements"  # or "instructions" or "restrictions"
$entityId = "bf56094c-bd28-4f56-ab52-d98c4dcde8af"
$changedTestDataOrMapping = $true  # Set to $false if only API mapper changed

# Execute test flow
if ($changedTestDataOrMapping) {
    Write-Host "🔄 Populating test data..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri "http://localhost:8080/api/v1/$tenant/test-data/populate" -Method POST -Headers @{'accept'='*/*'}
    
    Write-Host "⏳ Waiting for processing..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5
    
    Write-Host "📦 Checking Elasticsearch document..." -ForegroundColor Cyan
    $esDoc = Invoke-WebRequest -Uri "http://localhost:9200/$tenant-$entityType/_doc/$entityId" -UseBasicParsing | 
        Select-Object -ExpandProperty Content | 
        ConvertFrom-Json
    
    Write-Host "Elasticsearch Document:" -ForegroundColor Green
    $esDoc | ConvertTo-Json -Depth 10
    Write-Host ""
}

Write-Host "🌐 Checking API response..." -ForegroundColor Cyan
$apiResponse = Invoke-WebRequest -Uri "http://localhost:8080/tenants/$tenant/settlement/v1/$entityType/$entityId" -Headers @{'accept'='application/json'} -UseBasicParsing | 
    Select-Object -ExpandProperty Content | 
    ConvertFrom-Json

Write-Host "API Response:" -ForegroundColor Green
$apiResponse | ConvertTo-Json -Depth 10
```

### Test
```powershell
# Full flow test (data changed)
Invoke-WebRequest -Uri 'http://localhost:8080/api/v1/cph/test-data/populate' -Method POST -Headers @{'accept'='*/*'}
Start-Sleep -Seconds 5
Invoke-WebRequest -Uri 'http://localhost:9200/cph-allegements/_doc/bf56094c-bd28-4f56-ab52-d98c4dcde8af' -UseBasicParsing | Select-Object -ExpandProperty Content | ConvertFrom-Json | ConvertTo-Json -Depth 10
Invoke-WebRequest -Uri 'http://localhost:8080/tenants/cph/settlement/v1/allegements/bf56094c-bd28-4f56-ab52-d98c4dcde8af' -Headers @{'accept'='application/json'} -UseBasicParsing | Select-Object -ExpandProperty Content | ConvertFrom-Json
```

### Result
✅ `instructionType` now present in both Elasticsearch and API response

---

## Quick Reference: Entity-Specific Paths

### Allegement
- **State DTO**: `infrastructure/target/generated-sources/jsonschema2pojo/com/acme/securities/settlement/events/SettlementTransactionState.java`
- **Domain**: `domain/model/allegement/Allegement.java`
- **StateMapper**: `infrastructure/mapper/allegement/AllegementStateMapper.java`
- **API Mapper**: `infrastructure/mapper/allegement/AllegementMapper.java`
- **Test Data**: `integration-test/resources/data/kafkaMessages/InstructionStatusAdvice.json`
- **ES Index**: `{tenant}-allegements`
- **API Path**: `/tenants/{tenant}/settlement/v1/allegements/{id}`

### Instruction
- **State DTO**: `infrastructure/target/generated-sources/jsonschema2pojo/com/acme/securities/settlement/events/SettlementTransactionState.java`
- **Domain**: `domain/model/instruction/Instruction.java`
- **StateMapper**: `infrastructure/mapper/instruction/InstructionStateMapper.java`
- **API Mapper**: `infrastructure/mapper/instruction/InstructionMapper.java`
- **Test Data**: `integration-test/resources/data/kafkaMessages/InstructionStatusAdvice.json`
- **ES Index**: `{tenant}-instructions`
- **API Path**: `/tenants/{tenant}/settlement/v1/instructions/{id}`

### Restriction
- **State DTO**: `infrastructure/target/generated-sources/jsonschema2pojo/com/acme/securities/settlement/events/RestrictionState.java`
- **Domain**: `domain/model/restriction/Restriction.java`
- **StateMapper**: `infrastructure/mapper/restriction/RestrictionStateMapper.java`
- **API Mapper**: `infrastructure/mapper/restriction/RestrictionMapper.java`
- **Test Data**: `integration-test/resources/data/kafkaMessages/RestrictionStatusAdvice.json`
- **ES Index**: `{tenant}-restrictions`
- **API Path**: `/tenants/{tenant}/settlement/v1/restrictions/{id}`

---
