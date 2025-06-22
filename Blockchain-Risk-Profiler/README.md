# Blockchain Risk Evaluation Framework (BREF) Smart Contract

A comprehensive decentralized risk assessment platform for blockchain accounts that enables authorized evaluators to assess risk across multiple dimensions, automatically calculates weighted composite risk scores, and provides transparent risk management capabilities for DeFi protocols and financial applications.

## Features

- **Multi-dimensional risk assessment** across four key areas:
  - Credit risk
  - Liquidity risk  
  - Collateral risk
  - Transaction history risk
- **Weighted scoring system** with configurable importance factors
- **Role-based access control** for risk evaluators
- **Automated composite score calculation** using weighted averages
- **Batch assessment capabilities** for efficient evaluations
- **Transparent audit trail** with timestamps and evaluator tracking

## Risk Dimensions

The framework evaluates accounts across four primary risk dimensions:

| Dimension | ID | Default Weight | Description |
|-----------|----|--------------| ----------- |
| Credit Risk | 0 | 3 | Assessment of creditworthiness and payment history |
| Liquidity Risk | 1 | 2 | Evaluation of asset liquidity and market depth |
| Collateral Risk | 2 | 3 | Analysis of collateral quality and coverage |
| Transaction History | 3 | 2 | Review of historical transaction patterns |

## System Architecture

### Core Components

- **Risk Evaluators**: Authorized principals who can submit risk assessments
- **System Administrator**: Controls evaluator permissions and system configuration
- **Risk Scores**: Individual dimension scores (0-100 scale)
- **Composite Scores**: Weighted average of all dimension scores
- **Account Profiles**: Comprehensive risk profiles with evaluation history

### Data Storage

- `authorized-risk-evaluators`: Registry of authorized risk evaluators
- `account-risk-dimension-scores`: Individual risk scores per account/dimension
- `risk-dimension-weights`: Importance weights for each risk dimension
- `comprehensive-account-profiles`: Complete account risk profiles

## Installation and Deployment

1. Deploy the smart contract to the Stacks blockchain
2. The deployer automatically becomes the first authorized evaluator
3. Initialize the framework with default settings:
   ```clarity
   (contract-call? .bref-contract initialize-risk-framework)
   ```

## Usage

### For System Administrators

#### Initialize the Framework
```clarity
(contract-call? .bref-contract initialize-risk-framework)
```

#### Authorize Risk Evaluators
```clarity
(contract-call? .bref-contract authorize-risk-evaluator 'SP1ABC...XYZ)
```

#### Configure Risk Dimension Weights
```clarity
(contract-call? .bref-contract configure-dimension-weight u0 u5)
```

#### Transfer Administration
```clarity
(contract-call? .bref-contract transfer-system-administration 'SP1NEW...ADMIN)
```

### For Risk Evaluators

#### Submit Individual Risk Assessment
```clarity
(contract-call? .bref-contract submit-risk-evaluation 
  'SP1TARGET...ACCOUNT  ; target account
  u0                    ; credit risk dimension
  u75)                  ; risk score (0-100)
```

#### Submit Comprehensive Risk Assessment
```clarity
(contract-call? .bref-contract submit-comprehensive-evaluation
  'SP1TARGET...ACCOUNT  ; target account
  u75                   ; credit score
  u60                   ; liquidity score
  u80                   ; collateral score
  u65)                  ; history score
```

#### Refresh Composite Score
```clarity
(contract-call? .bref-contract refresh-composite-score 'SP1TARGET...ACCOUNT)
```

### For Data Consumers

#### Get Account Risk Profile
```clarity
(contract-call? .bref-contract fetch-account-risk-profile 'SP1TARGET...ACCOUNT)
```

#### Get Dimension-Specific Score
```clarity
(contract-call? .bref-contract fetch-dimension-risk-score 
  'SP1TARGET...ACCOUNT 
  u0)  ; dimension ID
```

#### Calculate Composite Risk Score
```clarity
(contract-call? .bref-contract compute-composite-risk-score 'SP1TARGET...ACCOUNT)
```

#### Check Evaluator Authorization
```clarity
(contract-call? .bref-contract check-evaluator-authorization 'SP1EVALUATOR...ADDRESS)
```

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| 100 | ERR-UNAUTHORIZED-EVALUATOR-ACCESS | Caller is not an authorized evaluator |
| 101 | ERR-RISK-SCORE-OUT-OF-BOUNDS | Risk score not between 0-100 |
| 102 | ERR-ACCOUNT-ADDRESS-NOT-FOUND | Account address not found |
| 103 | ERR-INVALID-IMPORTANCE-WEIGHT | Weight not between 1-10 |
| 104 | ERR-UNKNOWN-RISK-DIMENSION | Invalid risk dimension ID |
| 105 | ERR-INVALID-PRINCIPAL-ADDRESS | Invalid or zero principal address |
| 106 | ERR-ADMIN-AUTHORIZATION-REQUIRED | Admin privileges required |

## Risk Score Calculation

The composite risk score is calculated as a weighted average:

```
Composite Score = (Credit×Weight₁ + Liquidity×Weight₂ + Collateral×Weight₃ + History×Weight₄) 
                 / (Weight₁ + Weight₂ + Weight₃ + Weight₄)
```

### Default Weights:
- Credit Risk: 3
- Liquidity Risk: 2  
- Collateral Risk: 3
- Transaction History: 2

## Security Considerations

- **Access Control**: Only authorized evaluators can submit risk assessments
- **Input Validation**: All inputs are validated for range and format
- **Immutable Records**: Risk evaluations create an immutable audit trail
- **Admin Controls**: System administrator can manage evaluator permissions
- **Score Bounds**: Risk scores are constrained to 0-100 range

## Integration Examples

### DeFi Lending Protocol
```clarity
;; Check borrower risk before loan approval
(let ((risk-profile (contract-call? .bref-contract fetch-account-risk-profile borrower-address)))
  (if (<= (get overall-risk-score risk-profile) u50)
    (approve-loan borrower-address loan-amount)
    (reject-loan-high-risk)))
```

### Insurance Platform
```clarity
;; Calculate premium based on risk score
(let ((composite-score (contract-call? .bref-contract compute-composite-risk-score client-address)))
  (calculate-premium base-premium composite-score))
```