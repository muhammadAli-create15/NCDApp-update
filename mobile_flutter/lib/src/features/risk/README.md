# Risk Assessment Component

This component provides users with a clear, visual assessment of their key risk factors for Non-Communicable Diseases (NCDs). It translates complex health metrics into an easy-to-understand, color-coded system.

## Features

- Color-coded risk levels (Normal, Moderate, High, Very High)
- Individual risk factor cards with visual indicators
- Detailed view for each risk factor with:
  - Visual representation of current value
  - Risk range chart
  - Educational content about the risk factor
  - Personalized recommendations based on risk level
- Overall risk score calculation based on individual factors

## Implementation Details

### Core Models

1. **RiskLevel (Enum)**: Defines the severity scale with appropriate colors
   - `normal`: Green (#4CAF50)
   - `moderate`: Yellow (#FFEB3B)
   - `high`: Orange (#FF9800)
   - `veryHigh`: Red (#FF5252)

2. **RiskFactor**: Data model for each health metric
   - Basic properties: id, title, value, unit, description
   - Risk assessment: riskLevel
   - Metadata: lastUpdated, iconData

3. **UserHealthData**: Raw health metrics storage
   - Physical measurements: weight, height, BMI
   - Blood metrics: cholesterol (total, HDL, LDL), triglycerides, blood sugar
   - Vitals: blood pressure (systolic, diastolic)
   - Other factors: smoking status, age, gender

### Utility Classes

**RiskCalculator**: Contains the logic to determine risk levels
   - Individual calculation methods for each health metric
   - Overall risk score aggregation
   - Utility methods to generate risk factors from health data

### User Interface Components

1. **RiskFactorCard**: Reusable card widget for displaying risk factors
   - Visual indicator of risk level
   - Concise display of key information

2. **RiskScreen**: Main screen for risk assessment
   - Overall risk summary card
   - List of all risk factors
   - Action buttons for updating health data

3. **RiskDetailScreen**: Detailed view for each risk factor
   - Visual representation of current value
   - Educational content about the factor
   - Risk range chart
   - Personalized recommendations

## Usage

The Risk Assessment feature can be accessed through the main navigation menu or by tapping on the "Risk Assessment" card on the home screen.

## Medical Guidelines

Risk calculations are based on established medical guidelines:

- **BMI**: Normal (< 23), Moderate (23-24.9), High (25-29.9), Very High (≥ 30)
- **LDL Cholesterol**: Normal (< 100 mg/dL), Moderate (100-129 mg/dL), High (130-159 mg/dL), Very High (≥ 160 mg/dL)
- **Blood Pressure**: Normal (< 120/80 mmHg), Moderate (120-129/80-84 mmHg), High (130-139/85-89 mmHg), Very High (≥ 140/90 mmHg)
- **Blood Sugar (Fasting)**: Normal (< 100 mg/dL), Moderate (100-125 mg/dL), High (≥ 126 mg/dL)

## Future Enhancements

- User input form for health data updates
- Historical tracking of risk factors over time
- PDF report generation
- Integration with connected health devices