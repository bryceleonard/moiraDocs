# Mobile Stack Recommendation: Expo + Storybook Web

**Date**: September 9, 2025  
**Decision**: Use Expo for mobile development with Storybook Web for component development and testing  
**Status**: Recommended approach for September MVP

---

## 🎯 Recommended Architecture

### **Expo + Storybook Web Strategy**
- **Mobile Development**: Expo (React Native) for iOS/Android apps
- **Component Development**: Storybook running in web environment  
- **Design System**: Shared components between mobile and web via React Native Web
- **Testing**: Visual regression testing via Chromatic/Percy on web Storybook

---

## ✅ Why This Approach Works Best

### **Development Velocity**
- ✅ **Fastest setup**: Expo handles native toolchain complexity
- ✅ **Hot reload**: Instant feedback during component development
- ✅ **Design system reuse**: Same components work for mobile app and potential web admin portal

### **Team Collaboration**
- ✅ **Designer review**: Components reviewable in browser without device setup
- ✅ **Stakeholder demos**: Shareable Storybook links for component approval
- ✅ **Visual regression**: Automated screenshot diffing prevents UI churn

### **Quality & Consistency**
- ✅ **Pixel-perfect enforcement**: Visual regression testing catches design drift
- ✅ **Accessibility testing**: Built-in a11y checks in Storybook
- ✅ **Documentation**: Auto-generated component docs with usage examples

---

## 🏗️ Technical Implementation

### **Project Structure**
```
MoiraMVP/
├── mobile/                     # Expo React Native app
│   ├── src/
│   │   ├── components/         # Shared component library
│   │   ├── screens/           # App screens
│   │   └── services/          # API clients, auth, etc.
│   ├── app.json               # Expo configuration
│   └── package.json
├── storybook/                  # Web Storybook for components
│   ├── stories/               # Component stories
│   ├── main.js               # Storybook config
│   └── package.json
└── design-tokens/             # Shared tokens (colors, typography, spacing)
```

### **Key Dependencies**
```json
// mobile/package.json
{
  "dependencies": {
    "expo": "~49.0.0",
    "react-native": "0.72.x",
    "expo-av": "~13.4.0",          // For audio recording
    "expo-camera": "~13.4.0",     // For future camera features
    "react-native-web": "~0.19.0" // Web compatibility
  }
}

// storybook/package.json
{
  "devDependencies": {
    "@storybook/react": "^7.0.0",
    "@storybook/addon-react-native-web": "^0.0.20",
    "@storybook/addon-essentials": "^7.0.0"
  }
}
```

---

## 🔧 Implementation Strategy

### **Component Development Pattern**
```typescript
// src/components/Button/Button.tsx
interface ButtonProps {
  title: string;
  onPress: () => void;
  variant?: 'primary' | 'secondary';
  disabled?: boolean;
}

export const Button: React.FC<ButtonProps> = ({ 
  title, 
  onPress, 
  variant = 'primary',
  disabled = false 
}) => (
  <TouchableOpacity
    style={[styles.button, styles[variant], disabled && styles.disabled]}
    onPress={onPress}
    disabled={disabled}
    testID="button"
  >
    <Text style={[styles.text, styles[`${variant}Text`]]}>{title}</Text>
  </TouchableOpacity>
);

// Button.stories.tsx
export default {
  title: 'Components/Button',
  component: Button,
  parameters: {
    design: {
      type: 'figma',
      url: 'https://figma.com/file/...'
    }
  }
};

export const Primary = {
  args: {
    title: 'Primary Button',
    variant: 'primary',
    onPress: () => console.log('Button pressed')
  }
};

export const AllStates = () => (
  <View style={{ gap: 16 }}>
    <Button title="Default" onPress={() => {}} />
    <Button title="Disabled" onPress={() => {}} disabled />
    <Button title="Secondary" variant="secondary" onPress={() => {}} />
  </View>
);
```

### **Platform-Specific Component Handling**
```typescript
// src/components/AudioRecorder/AudioRecorder.tsx
import { Audio } from 'expo-av';

// Mock for Storybook web environment
const AudioMock = {
  requestPermissionsAsync: () => Promise.resolve({ status: 'granted' }),
  Recording: class MockRecording {
    prepareToRecordAsync = () => Promise.resolve();
    startAsync = () => Promise.resolve();
    stopAndUnloadAsync = () => Promise.resolve({ uri: 'mock://audio.m4a' });
  }
};

// Conditional import based on environment
const AudioAPI = process.env.STORYBOOK ? AudioMock : Audio;

export const AudioRecorder: React.FC<AudioRecorderProps> = ({ onRecordingComplete }) => {
  const [recording, setRecording] = useState<Audio.Recording | null>(null);
  const [isRecording, setIsRecording] = useState(false);

  const startRecording = async () => {
    try {
      const permission = await AudioAPI.requestPermissionsAsync();
      if (permission.status !== 'granted') return;

      const recordingInstance = new AudioAPI.Recording();
      await recordingInstance.prepareToRecordAsync(Audio.RECORDING_OPTIONS_PRESET_HIGH_QUALITY);
      await recordingInstance.startAsync();
      
      setRecording(recordingInstance);
      setIsRecording(true);
    } catch (err) {
      console.error('Failed to start recording', err);
    }
  };

  // Component implementation...
};

// AudioRecorder.stories.tsx
export const Default = {
  args: {
    onRecordingComplete: (uri: string) => console.log('Recording completed:', uri)
  }
};
```

---

## 🎨 Design System Integration

### **Design Tokens Setup**
```typescript
// design-tokens/tokens.ts
export const tokens = {
  colors: {
    primary: {
      50: '#f0f9ff',
      500: '#3b82f6', 
      900: '#1e3a8a'
    },
    semantic: {
      success: '#10b981',
      warning: '#f59e0b',
      error: '#ef4444'
    }
  },
  typography: {
    fontFamily: {
      sans: 'Inter',
      mono: 'SF Mono'
    },
    fontSize: {
      sm: 14,
      base: 16,
      lg: 18,
      xl: 20
    }
  },
  spacing: {
    xs: 4,
    sm: 8, 
    md: 16,
    lg: 24,
    xl: 32
  }
};

// src/styles/styles.ts
import { StyleSheet } from 'react-native';
import { tokens } from '../../design-tokens/tokens';

export const globalStyles = StyleSheet.create({
  button: {
    paddingHorizontal: tokens.spacing.md,
    paddingVertical: tokens.spacing.sm,
    borderRadius: 8,
    alignItems: 'center'
  },
  buttonPrimary: {
    backgroundColor: tokens.colors.primary[500]
  },
  text: {
    fontFamily: tokens.typography.fontFamily.sans,
    fontSize: tokens.typography.fontSize.base
  }
});
```

---

## 🔄 Development Workflow

### **Daily Development Process**
1. **Component Development**: Build components in Expo with hot reload
2. **Story Creation**: Create comprehensive Storybook stories with all states
3. **Visual Review**: Designer reviews components in Storybook browser
4. **Testing**: Visual regression tests catch pixel differences
5. **Integration**: Components used in actual Expo app screens

### **CI/CD Pipeline**
```yaml
# .github/workflows/mobile-ci.yml
name: Mobile CI
on: [push, pull_request]

jobs:
  storybook-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Node
        uses: actions/setup-node@v3
        with:
          node-version: '18'
      
      - name: Install dependencies
        run: npm ci
        working-directory: ./storybook
      
      - name: Build Storybook
        run: npm run build-storybook
        working-directory: ./storybook
      
      - name: Visual regression tests
        run: npm run chromatic
        working-directory: ./storybook
        env:
          CHROMATIC_PROJECT_TOKEN: ${{ secrets.CHROMATIC_PROJECT_TOKEN }}

  expo-build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Expo
        uses: expo/expo-github-action@v8
        with:
          expo-version: latest
          token: ${{ secrets.EXPO_TOKEN }}
      
      - name: Install dependencies
        run: npm ci
        working-directory: ./mobile
      
      - name: EAS Build
        run: eas build --platform all --non-interactive
        working-directory: ./mobile
```

---

## ⚠️ Limitations & Workarounds

### **Platform-Specific Testing**
- **Limitation**: Audio recording, camera, device APIs can't be fully tested in web Storybook
- **Workaround**: Create focused device tests for platform-specific functionality

```typescript
// __tests__/AudioRecorder.device.test.tsx
import { render, fireEvent } from '@testing-library/react-native';
import { AudioRecorder } from '../AudioRecorder';

// This test only runs on actual device/simulator
describe('AudioRecorder - Device', () => {
  it('requests audio permissions', async () => {
    const { getByTestId } = render(<AudioRecorder />);
    
    fireEvent.press(getByTestId('record-button'));
    
    // Test actual platform permissions
    expect(Audio.requestPermissionsAsync).toHaveBeenCalled();
  });
});
```

### **Navigation Context**
- **Limitation**: Navigation hooks don't work in isolated Storybook stories
- **Workaround**: Mock navigation context in stories

```typescript
// NavigationDecorator.tsx
export const NavigationDecorator = (Story: any) => (
  <NavigationContainer>
    <Story />
  </NavigationContainer>
);

// Component.stories.tsx
export const WithNavigation = {
  decorators: [NavigationDecorator],
  args: { /* story args */ }
};
```

---

## 📋 Implementation Timeline

### **Week 1: Foundation Setup**
- [ ] Initialize Expo project with TypeScript
- [ ] Set up Storybook with React Native Web  
- [ ] Configure design tokens and base styles
- [ ] Create primitive components (Button, Input, Text)
- [ ] Set up Chromatic for visual regression

### **Week 2: Core Components**  
- [ ] Build essential UI components
- [ ] Create comprehensive Storybook stories
- [ ] Implement platform-specific mocks (Audio, Camera)
- [ ] Configure CI pipeline for visual regression

### **Week 3: Integration**
- [ ] Integrate component library with main Expo app
- [ ] Implement actual recording functionality
- [ ] Create device-specific test suite

### **Week 4: Optimization**
- [ ] Performance testing and optimization
- [ ] Cross-platform validation (iOS/Android)
- [ ] Final design system documentation

---

## 🎯 Success Criteria

### **Component Library Quality**
- ✅ All components have comprehensive Storybook stories
- ✅ >90% visual regression test pass rate
- ✅ 100% accessibility compliance (WCAG AA)
- ✅ Design system tokens used consistently across all components

### **Development Experience**
- ✅ <30 second component iteration cycle (change → see result)
- ✅ Designer can review all components without device setup
- ✅ New team members can contribute components within 1 day of setup

### **Mobile App Integration**
- ✅ Audio recording works flawlessly on iOS/Android devices
- ✅ UI components render consistently between Storybook and device
- ✅ Performance meets production standards (60fps interactions)

This approach balances rapid development velocity with design system quality, giving you the foundation for pixel-perfect UI implementation without getting stuck in endless revision cycles.
