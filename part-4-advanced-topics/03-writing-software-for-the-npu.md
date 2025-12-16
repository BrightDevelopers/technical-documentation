# Chapter 10: Writing Software for the NPU

[← Back to Part 4: Advanced Topics](README.md) | [↑ Main](../README.md)

---

## Neural Processing Unit Development

This chapter covers AI/ML capabilities on BrightSign players with integrated Neural Processing Unit (NPU) support. As of 2025, BrightSign has introduced NPU capabilities in their Series 6 players, enabling on-device AI processing for digital signage applications.

## NPU Overview

### Neural Processing Unit Architecture

A Neural Processing Unit (NPU) is a specialized processor designed to accelerate AI and machine learning workloads. BrightSign's NPU integration enables:

- **On-device AI processing** without impacting content playback performance
- **Dedicated acceleration** for AI tasks separate from CPU/GPU workloads
- **Power efficiency** consuming only a few extra watts compared to CPU-based AI processing
- **Edge computing** capabilities for real-time inference without cloud connectivity

### Hardware Availability

BrightSign Series 6 players include NPU support:

- **HD6**: Standard model with NPU for AI-enabled applications
- **XD6**: Enhanced model with NPU, 4K graphics, and PoE+ support
- **XS6**: Embedded system-on-chip with integrated NPU

**Important Note**: NPU support is available on Series 6 and newer players. Check your specific model documentation to confirm NPU capabilities.

### Capabilities

NPUs provide specialized processing for:

- Computer vision tasks (object detection, classification, tracking)
- Audio processing (speech recognition, audio classification)
- Real-time inference on video streams
- Low-latency pattern recognition
- Parallel processing of neural network operations

NPUs operate primarily with 8-bit integer (INT8) data types for maximum efficiency, though some support 16-bit floating point (FP16/BF16) operations.

## AI/ML Model Support

### Model Formats

While BrightSign has announced AI toolkits for Series 6 players, specific documentation about supported model formats is limited. Industry-standard NPU implementations typically support:

**TensorFlow Lite**
- Lightweight framework designed for edge devices
- Optimized for mobile and embedded deployment
- Supports INT8 and FP16 quantization
- Smaller model size and faster inference

**ONNX Runtime**
- Open standard for machine learning models
- Cross-platform deployment
- Support for multiple quantization schemes
- Execution providers for NPU acceleration

**Note**: For definitive information about which model formats are supported on BrightSign NPU hardware, consult BrightSign technical documentation or contact their support team directly.

### Supported Operations

NPU-accelerated operations typically include:

- Convolutional layers (Conv2D, DepthwiseConv2D)
- Fully connected layers (Dense)
- Pooling operations (MaxPool, AvgPool)
- Activation functions (ReLU, ReLU6, Sigmoid)
- Batch normalization
- Element-wise operations (Add, Multiply)
- Concatenation and reshaping

### Model Constraints

NPU implementations often have specific requirements:

- **Fixed input shapes**: Dynamic shapes may not be supported or may reduce performance
- **INT8 quantization**: Required for maximum NPU acceleration
- **Operator support**: Some operations may fall back to CPU if not NPU-accelerated
- **Model size**: Limited on-device memory requires compact models

## Model Optimization

### Quantization

Quantization reduces model precision from 32-bit floating point to 8-bit integers, providing significant benefits:

**Benefits**:
- 4x reduction in model size
- 2-4x faster inference speed
- Lower memory bandwidth requirements
- Reduced power consumption

**Quantization Types**:

1. **Post-Training Quantization (PTQ)**
   - Simplest approach requiring no retraining
   - Converts pre-trained FP32 model to INT8
   - May result in 1-3% accuracy loss
   - Fast implementation process

2. **Quantization-Aware Training (QAT)**
   - Simulates quantization during training
   - Better accuracy preservation (<1% loss)
   - Requires access to training pipeline
   - Longer implementation time

**TensorFlow Lite Quantization Example**:

```python
import tensorflow as tf

# Load your trained model
model = tf.keras.models.load_model('model.h5')

# Create converter
converter = tf.lite.TFLiteConverter.from_keras_model(model)

# Enable INT8 quantization
converter.optimizations = [tf.lite.Optimize.DEFAULT]

# Provide representative dataset for calibration
def representative_dataset():
    for _ in range(100):
        # Yield sample data matching your input shape
        yield [np.random.randn(1, 224, 224, 3).astype(np.float32)]

converter.representative_dataset = representative_dataset

# Set input/output to INT8
converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
converter.inference_input_type = tf.int8
converter.inference_output_type = tf.int8

# Convert model
tflite_model = converter.convert()

# Save quantized model
with open('model_quantized.tflite', 'wb') as f:
    f.write(tflite_model)
```

**ONNX Quantization Example**:

```python
from onnxruntime.quantization import quantize_dynamic, QuantType

# Dynamic quantization (weights only)
quantize_dynamic(
    model_input='model.onnx',
    model_output='model_int8.onnx',
    weight_type=QuantType.QInt8
)

# Static quantization with calibration
from onnxruntime.quantization import quantize_static, CalibrationDataReader

class DataReader(CalibrationDataReader):
    def __init__(self, calibration_data):
        self.data = calibration_data
        self.index = 0

    def get_next(self):
        if self.index < len(self.data):
            result = {'input': self.data[self.index]}
            self.index += 1
            return result
        return None

# Perform static quantization
quantize_static(
    model_input='model.onnx',
    model_output='model_static_int8.onnx',
    calibration_data_reader=DataReader(calibration_samples)
)
```

### Pruning

Pruning removes redundant weights from neural networks:

**Magnitude-based Pruning**:
- Removes weights with smallest absolute values
- Can remove 50-90% of weights with minimal accuracy loss
- Creates sparse networks

**Structured Pruning**:
- Removes entire channels, filters, or layers
- Better hardware compatibility
- Actual speedup on NPU devices

**TensorFlow Model Optimization Toolkit Example**:

```python
import tensorflow_model_optimization as tfmot

# Define pruning schedule
pruning_params = {
    'pruning_schedule': tfmot.sparsity.keras.PolynomialDecay(
        initial_sparsity=0.0,
        final_sparsity=0.5,
        begin_step=0,
        end_step=1000
    )
}

# Apply pruning to model
model_for_pruning = tfmot.sparsity.keras.prune_low_magnitude(
    model, **pruning_params
)

# Compile and train
model_for_pruning.compile(
    optimizer='adam',
    loss='categorical_crossentropy',
    metrics=['accuracy']
)

# Add pruning callbacks
callbacks = [
    tfmot.sparsity.keras.UpdatePruningStep(),
    tfmot.sparsity.keras.PruningSummaries(log_dir='logs')
]

model_for_pruning.fit(
    train_data, train_labels,
    epochs=10,
    callbacks=callbacks
)

# Strip pruning wrappers and export
model_for_export = tfmot.sparsity.keras.strip_pruning(model_for_pruning)
```

### Combined Optimization

Combining pruning and quantization achieves maximum compression:

```python
# 1. Prune the model
pruned_model = apply_pruning(original_model)

# 2. Fine-tune pruned model
pruned_model.fit(train_data, epochs=5)

# 3. Quantize the pruned model
converter = tf.lite.TFLiteConverter.from_keras_model(pruned_model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
converter.representative_dataset = representative_dataset

tflite_model = converter.convert()
```

This approach can reduce model size by 10x while maintaining accuracy within 1-2% of the original.

## Inference Pipeline

### Loading Models

The specific API for loading models on BrightSign NPU will depend on the runtime provided. General pattern for edge AI inference:

**Conceptual BrightScript/JavaScript Pattern**:

```javascript
// Note: This is conceptual - actual API may differ
var AIRuntime = require("@brightsign/ai-runtime");
var inference = new AIRuntime();

// Load model
inference.loadModel({
    modelPath: "/storage/models/object_detector.tflite",
    accelerator: "npu",
    threads: 1
}).then(function(model) {
    console.log("Model loaded successfully");
    // Model ready for inference
}).catch(function(error) {
    console.log("Failed to load model: " + error);
});
```

### Preprocessing Data

Input data must match the model's expected format:

**Image Preprocessing**:

```javascript
// Conceptual preprocessing for video frame
function preprocessFrame(videoFrame, inputWidth, inputHeight) {
    // 1. Resize frame to model input size
    var resized = resizeImage(videoFrame, inputWidth, inputHeight);

    // 2. Normalize pixel values (model dependent)
    // Common: scale to [0, 1] or [-1, 1]
    var normalized = normalizePixels(resized,
        mean=[127.5, 127.5, 127.5],
        std=[127.5, 127.5, 127.5]
    );

    // 3. Convert to required format (RGB vs BGR)
    var formatted = convertColorSpace(normalized, "RGB");

    // 4. Convert to INT8 if required by quantized model
    var quantized = floatToInt8(formatted);

    return quantized;
}
```

**Audio Preprocessing**:

```javascript
// Conceptual audio preprocessing for speech recognition
function preprocessAudio(audioBuffer, sampleRate) {
    // 1. Resample to model's expected sample rate (e.g., 16kHz)
    var resampled = resampleAudio(audioBuffer, sampleRate, 16000);

    // 2. Extract features (MFCC, spectrogram, etc.)
    var features = extractMFCC(resampled, {
        numMfccCoeffs: 13,
        frameLength: 512,
        frameStep: 160
    });

    // 3. Normalize features
    var normalized = normalizeFeatures(features);

    return normalized;
}
```

### Running Inference

**Single Frame Inference**:

```javascript
// Conceptual inference execution
function runInference(model, inputData) {
    return model.run({
        input: inputData
    }).then(function(results) {
        return results;
    });
}

// Example usage
var preprocessed = preprocessFrame(videoFrame, 224, 224);
runInference(model, preprocessed).then(function(output) {
    var predictions = output.predictions;
    console.log("Inference complete:", predictions);
});
```

**Streaming Inference**:

```javascript
// Conceptual streaming inference from video input
var VideoInputClass = require("@brightsign/videoinput");
var videoInput = new VideoInputClass();

// Set up frame capture
function processVideoStream(model) {
    videoInput.addEventListener('frame', function(frameEvent) {
        var frame = frameEvent.data;

        // Preprocess
        var input = preprocessFrame(frame, 224, 224);

        // Run inference
        runInference(model, input).then(function(results) {
            handleInferenceResults(results);
        });
    });
}
```

### Postprocessing

Convert raw model outputs to usable results:

**Object Detection Postprocessing**:

```javascript
function postprocessDetections(output, confidenceThreshold, iouThreshold) {
    var boxes = output.boxes;          // Bounding box coordinates
    var scores = output.scores;        // Confidence scores
    var classes = output.classes;      // Class IDs

    // Filter by confidence
    var filtered = [];
    for (var i = 0; i < scores.length; i++) {
        if (scores[i] > confidenceThreshold) {
            filtered.push({
                box: boxes[i],
                score: scores[i],
                class: classes[i],
                label: classLabels[classes[i]]
            });
        }
    }

    // Apply Non-Maximum Suppression
    var final = applyNMS(filtered, iouThreshold);

    return final;
}

// Usage
var detections = postprocessDetections(
    modelOutput,
    confidenceThreshold=0.5,
    iouThreshold=0.4
);
```

**Classification Postprocessing**:

```javascript
function postprocessClassification(output, topK) {
    var probabilities = softmax(output.logits);

    // Get top K predictions
    var indexed = probabilities.map(function(prob, idx) {
        return {score: prob, classId: idx};
    });

    indexed.sort(function(a, b) {
        return b.score - a.score;
    });

    return indexed.slice(0, topK).map(function(item) {
        return {
            label: classLabels[item.classId],
            confidence: item.score
        };
    });
}
```

## Computer Vision

### Object Detection

Object detection identifies and locates multiple objects in images or video streams.

**Use Cases**:
- People counting for audience analytics
- Product recognition in retail displays
- Vehicle detection for traffic monitoring
- Safety monitoring (PPE detection, restricted area alerts)

**Popular Models**:
- **YOLO (You Only Look Once)**: Fast, single-pass detection
- **SSD (Single Shot Detector)**: Balance of speed and accuracy
- **MobileNet-SSD**: Lightweight for embedded devices
- **EfficientDet**: High accuracy with efficient architecture

**Implementation Pattern**:

```javascript
// Conceptual object detection implementation
function detectObjects(videoFrame, model) {
    // Preprocess
    var input = preprocessFrame(videoFrame, 300, 300);

    // Inference
    return model.run(input).then(function(output) {
        // Postprocess
        var detections = postprocessDetections(output, 0.5, 0.4);

        // Filter for specific classes (e.g., people only)
        var people = detections.filter(function(det) {
            return det.label === "person";
        });

        return {
            totalDetections: detections.length,
            peopleCount: people.length,
            detections: detections
        };
    });
}
```

### Classification

Image classification assigns labels to entire images.

**Use Cases**:
- Scene recognition (indoor/outdoor, day/night)
- Product categorization
- Content moderation
- Quality control

**Popular Models**:
- **MobileNetV2/V3**: Efficient mobile-friendly architecture
- **EfficientNet**: Scaled models for various resource constraints
- **ResNet variants**: Higher accuracy for complex tasks
- **SqueezeNet**: Ultra-compact for extreme resource constraints

### Face Recognition

Face recognition identifies individuals from facial features.

**Privacy Considerations**:
- Process all data locally on device (no cloud transmission)
- Store only facial embeddings, not actual images
- Provide clear signage about AI usage
- Comply with GDPR, CCPA, and local privacy regulations
- Consider using demographic analytics without identification

**Two-Stage Approach**:

1. **Face Detection**: Locate faces in frame
2. **Face Recognition/Analysis**: Identify or analyze detected faces

**Implementation Pattern**:

```javascript
// Conceptual face detection and demographic analysis
function analyzeFaces(videoFrame, faceDetector, demographicModel) {
    // Stage 1: Detect faces
    return faceDetector.run(videoFrame).then(function(faces) {
        if (faces.length === 0) {
            return {faceCount: 0, demographics: []};
        }

        // Stage 2: Analyze each face
        var analyses = faces.map(function(face) {
            var faceCrop = cropRegion(videoFrame, face.box);
            return demographicModel.run(faceCrop);
        });

        return Promise.all(analyses).then(function(demographics) {
            return {
                faceCount: faces.length,
                demographics: demographics  // age, gender estimates
            };
        });
    });
}
```

### Scene Analysis

Scene analysis understands overall image content and context.

**Applications**:
- Lighting condition detection (adjust display brightness)
- Weather recognition (adapt outdoor signage content)
- Crowd density estimation
- Activity recognition

## Audio Processing

### Speech Recognition

Speech recognition converts spoken words to text.

**Use Cases**:
- Voice-controlled interactive displays
- Accessibility features
- Command recognition for touchless interaction
- Audio analytics

**Common Approaches**:

1. **Keyword Spotting**: Detect specific wake words or commands
2. **Full Speech-to-Text**: Convert continuous speech to text
3. **Command Recognition**: Limited vocabulary for specific actions

**Conceptual Implementation**:

```javascript
// Conceptual keyword spotting
function detectKeywords(audioBuffer, model, keywords) {
    // Preprocess audio
    var features = preprocessAudio(audioBuffer, 16000);

    // Run inference
    return model.run(features).then(function(output) {
        var probabilities = softmax(output.logits);

        // Find highest probability keyword
        var maxIdx = argmax(probabilities);
        var confidence = probabilities[maxIdx];

        if (confidence > 0.8) {
            return {
                keyword: keywords[maxIdx],
                confidence: confidence,
                detected: true
            };
        }

        return {detected: false};
    });
}
```

### Audio Classification

Audio classification categorizes sounds and acoustic events.

**Applications**:
- Ambient sound detection (music, speech, silence)
- Emergency sound detection (alarms, breaking glass)
- Background noise classification
- Audio quality monitoring

**Event Detection**:

```javascript
// Conceptual audio event detection
function detectAudioEvents(audioBuffer, model, eventTypes) {
    var features = extractAudioFeatures(audioBuffer);

    return model.run(features).then(function(output) {
        var events = [];

        for (var i = 0; i < output.length; i++) {
            if (output[i] > 0.7) {
                events.push({
                    type: eventTypes[i],
                    confidence: output[i]
                });
            }
        }

        return events;
    });
}
```

### Noise Reduction

While NPUs typically focus on inference rather than signal processing, ML-based noise reduction is possible:

**Use Cases**:
- Clean audio for speech recognition
- Improve audio quality in noisy environments
- Enhance voice commands in public spaces

## Real-time Processing

### Streaming Inference

Streaming inference processes continuous data streams efficiently.

**Frame Rate Management**:

```javascript
// Conceptual frame skipping for performance
var InferenceThrottler = function(targetFPS) {
    this.targetFPS = targetFPS;
    this.frameInterval = 1000 / targetFPS;
    this.lastInferenceTime = 0;

    this.shouldProcess = function() {
        var now = Date.now();
        if (now - this.lastInferenceTime >= this.frameInterval) {
            this.lastInferenceTime = now;
            return true;
        }
        return false;
    };
};

// Usage
var throttler = new InferenceThrottler(10);  // 10 FPS

function processVideoStream(videoFrame, model) {
    if (throttler.shouldProcess()) {
        runInference(model, videoFrame);
    }
}
```

**Async Processing**:

```javascript
// Non-blocking inference with queue
var InferenceQueue = function() {
    this.processing = false;
    this.latestFrame = null;

    this.submit = function(frame) {
        this.latestFrame = frame;  // Always keep latest
        if (!this.processing) {
            this.process();
        }
    };

    this.process = function() {
        var self = this;
        if (this.latestFrame === null) {
            this.processing = false;
            return;
        }

        this.processing = true;
        var frame = this.latestFrame;
        this.latestFrame = null;

        runInference(model, frame).then(function(results) {
            handleResults(results);
            self.process();  // Process next if available
        });
    };
};
```

### Performance Optimization

**Optimization Strategies**:

1. **Use INT8 Quantization**: 2-4x speedup over FP32
2. **Optimize Input Resolution**: Smaller inputs = faster inference
3. **Batch Processing**: Process multiple inputs together when possible
4. **Model Architecture**: Use mobile-optimized models (MobileNet, EfficientNet)
5. **Skip Frames**: Don't process every frame if not necessary

**Performance Monitoring**:

```javascript
// Conceptual performance tracking
var PerformanceMonitor = function() {
    this.inferenceTimes = [];
    this.maxSamples = 100;

    this.recordInference = function(startTime, endTime) {
        var duration = endTime - startTime;
        this.inferenceTimes.push(duration);

        if (this.inferenceTimes.length > this.maxSamples) {
            this.inferenceTimes.shift();
        }
    };

    this.getStats = function() {
        var avg = this.inferenceTimes.reduce(function(a, b) {
            return a + b;
        }, 0) / this.inferenceTimes.length;

        var max = Math.max.apply(null, this.inferenceTimes);
        var min = Math.min.apply(null, this.inferenceTimes);

        return {
            avgMs: avg,
            maxMs: max,
            minMs: min,
            fps: 1000 / avg
        };
    };
};

// Usage
var perfMonitor = new PerformanceMonitor();

function runInferenceWithTracking(model, input) {
    var startTime = Date.now();

    return model.run(input).then(function(results) {
        var endTime = Date.now();
        perfMonitor.recordInference(startTime, endTime);

        var stats = perfMonitor.getStats();
        console.log("Inference: " + stats.avgMs + "ms, " + stats.fps + " FPS");

        return results;
    });
}
```

### Latency Management

**Latency Sources**:
- **Preprocessing**: Image resize, normalization, format conversion
- **Data transfer**: Moving data to NPU
- **Inference**: Model execution time
- **Postprocessing**: NMS, softmax, filtering

**Optimization Tips**:

1. **Minimize Preprocessing**: Use models that accept formats close to your input
2. **Static Shapes**: Fixed input sizes enable better NPU optimization
3. **Reduce Postprocessing**: Simplify output handling
4. **Asynchronous Execution**: Don't block on inference results

**Target Latencies**:
- **Real-time video (30 FPS)**: <33ms per frame
- **Interactive applications**: <100ms for responsiveness
- **Batch processing**: Latency less critical than throughput

## Hardware Integration

### Camera Input

BrightSign players support HDMI input which can be used with external cameras.

**Video Input Integration**:

```javascript
var VideoInputClass = require("@brightsign/videoinput");
var vi = new VideoInputClass();

// Get input status
vi.getStatus().then(function(status) {
    if (status.devicePresent) {
        console.log("Camera connected:");
        console.log("Resolution: " + status.width + "x" + status.height);
        console.log("Frame rate: " + status.frameRate);
        console.log("Color space: " + status.colorSpace);

        // Ready for AI processing
        startInferenceOnVideoInput(vi);
    } else {
        console.log("No camera connected");
    }
});

// Monitor for camera connection changes
vi.addEventListener('hdmiinputchange', function(event) {
    console.log("Camera connection changed");
    checkCameraStatus();
});
```

### Sensor Fusion

Combine AI inference with other sensor inputs for richer applications.

**Example: Motion + Vision**:

```javascript
// Conceptual sensor fusion
var GpioClass = require("@brightsign/gpio");
var gpio = new GpioClass();

// Motion sensor on GPIO
gpio.enableInput(0);  // PIR motion sensor

var motionDetected = false;

gpio.addEventListener('inputchange', function(event) {
    if (event.input === 0 && event.state === true) {
        motionDetected = true;
        console.log("Motion detected, starting AI vision");
        startVisionProcessing();
    }
});

// Only run expensive vision AI when motion detected
function startVisionProcessing() {
    if (motionDetected) {
        // Run object detection or face recognition
        processVideoFrame(currentFrame);
    }
}
```

**Combining Multiple Inputs**:

```javascript
// Conceptual multi-modal AI application
function multiModalAnalysis() {
    var results = {
        visual: null,
        audio: null,
        motion: false,
        timestamp: Date.now()
    };

    // Visual AI
    if (cameraActive) {
        results.visual = detectObjects(currentVideoFrame);
    }

    // Audio AI
    if (audioAvailable) {
        results.audio = classifyAudio(currentAudioBuffer);
    }

    // Motion sensor
    results.motion = gpio.isInputActive(0);

    // Fuse results for decision making
    return fuseResults(results);
}

function fuseResults(results) {
    // Example: High confidence person + voice detected + motion
    if (results.visual && results.visual.peopleCount > 0 &&
        results.audio && results.audio.containsSpeech &&
        results.motion) {
        return {
            event: "person_interacting",
            confidence: 0.95
        };
    }

    return {event: "none", confidence: 0.0};
}
```

### GPIO Integration with AI Results

Control hardware outputs based on AI inference results.

**Example: Trigger Actions Based on Detection**:

```javascript
var ControlPortClass = require("@brightsign/controlport");
var controlPort = new ControlPortClass();

// Configure GPIO outputs
controlPort.enableOutput(0);  // LED indicator
controlPort.enableOutput(1);  // Relay for external device

// Control outputs based on AI results
function handleDetectionResults(detections) {
    var personDetected = detections.some(function(det) {
        return det.label === "person" && det.score > 0.7;
    });

    if (personDetected) {
        // Turn on LED
        controlPort.setOutputState(0, true);

        // Trigger external device
        controlPort.setOutputState(1, true);

        // Auto-off after 5 seconds
        setTimeout(function() {
            controlPort.setOutputState(0, false);
            controlPort.setOutputState(1, false);
        }, 5000);
    }
}

// Integrate with inference pipeline
function processFrameWithActions(videoFrame, model) {
    detectObjects(videoFrame, model).then(function(results) {
        handleDetectionResults(results.detections);
        updateDisplay(results);
    });
}
```

## Development Tools

### Model Conversion

Convert models from training frameworks to deployment formats.

**TensorFlow to TensorFlow Lite**:

```bash
# Using TensorFlow Lite converter
python -c "
import tensorflow as tf

# Load SavedModel
converter = tf.lite.TFLiteConverter.from_saved_model('saved_model/')

# Optimize
converter.optimizations = [tf.lite.Optimize.DEFAULT]

# Convert
tflite_model = converter.convert()

# Save
with open('model.tflite', 'wb') as f:
    f.write(tflite_model)
"
```

**PyTorch to ONNX**:

```bash
# Export PyTorch model to ONNX
python -c "
import torch
import torchvision

# Load model
model = torchvision.models.mobilenet_v2(pretrained=True)
model.eval()

# Create dummy input
dummy_input = torch.randn(1, 3, 224, 224)

# Export
torch.onnx.export(
    model,
    dummy_input,
    'mobilenet_v2.onnx',
    input_names=['input'],
    output_names=['output'],
    dynamic_axes={'input': {0: 'batch'}, 'output': {0: 'batch'}}
)
"
```

**ONNX to TensorFlow Lite**:

```bash
# Install onnx-tf
pip install onnx-tf

# Convert ONNX to TensorFlow
onnx-tf convert -i model.onnx -o model_tf/

# Convert TensorFlow to TFLite
python -c "
import tensorflow as tf

converter = tf.lite.TFLiteConverter.from_saved_model('model_tf/')
tflite_model = converter.convert()

with open('model.tflite', 'wb') as f:
    f.write(tflite_model)
"
```

### Testing Frameworks

Test models before deployment to BrightSign hardware.

**Validate Model Accuracy**:

```python
import numpy as np
import tensorflow as tf

# Load TFLite model
interpreter = tf.lite.Interpreter(model_path='model.tflite')
interpreter.allocate_tensors()

# Get input/output details
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

# Test with sample data
def test_model(test_images, test_labels):
    correct = 0
    total = len(test_images)

    for image, label in zip(test_images, test_labels):
        # Preprocess
        input_data = preprocess(image)

        # Run inference
        interpreter.set_tensor(input_details[0]['index'], input_data)
        interpreter.invoke()
        output = interpreter.get_tensor(output_details[0]['index'])

        # Check prediction
        predicted = np.argmax(output)
        if predicted == label:
            correct += 1

    accuracy = correct / total
    print(f"Accuracy: {accuracy * 100:.2f}%")
    return accuracy

# Run tests
accuracy = test_model(test_images, test_labels)
```

**Benchmark Inference Speed**:

```python
import time

def benchmark_model(interpreter, num_runs=100):
    # Warm up
    for _ in range(10):
        interpreter.invoke()

    # Benchmark
    times = []
    for _ in range(num_runs):
        start = time.time()
        interpreter.invoke()
        end = time.time()
        times.append((end - start) * 1000)  # Convert to ms

    avg_time = np.mean(times)
    std_time = np.std(times)
    fps = 1000 / avg_time

    print(f"Avg inference time: {avg_time:.2f}ms ± {std_time:.2f}ms")
    print(f"Throughput: {fps:.1f} FPS")

    return {
        'avg_ms': avg_time,
        'std_ms': std_time,
        'fps': fps
    }

benchmark_model(interpreter)
```

### Performance Profiling

Profile model execution to identify bottlenecks.

**TensorFlow Lite Profiling**:

```python
# Enable profiling
interpreter = tf.lite.Interpreter(
    model_path='model.tflite',
    experimental_enable_op_profiling=True
)
interpreter.allocate_tensors()

# Run inference
interpreter.invoke()

# Get profiling information
profiling_data = interpreter.get_tensor_details()

# Analyze per-operator timing
for op in profiling_data:
    print(f"Op: {op['name']}")
    print(f"  Time: {op['execution_time_us']} us")
```

**Identify Slow Operations**:

```python
def profile_and_analyze(interpreter):
    # Run with profiling
    interpreter.invoke()

    # Get operator details
    ops = []
    for i in range(interpreter._get_ops_details()):
        op_details = interpreter._get_op_details(i)
        ops.append({
            'name': op_details['op_name'],
            'time_us': op_details['execution_time_us']
        })

    # Sort by execution time
    ops.sort(key=lambda x: x['time_us'], reverse=True)

    # Display top slow operations
    print("Top 10 slowest operations:")
    for i, op in enumerate(ops[:10]):
        print(f"{i+1}. {op['name']}: {op['time_us']} us")

    return ops
```

## Use Cases

### Smart Signage

Dynamic content adaptation based on audience.

**Demographic-Based Content**:

```javascript
// Conceptual smart signage implementation
function smartSignageController(aiResults) {
    var demographics = aiResults.demographics;
    var peopleCount = aiResults.faceCount;

    // No audience - show default content
    if (peopleCount === 0) {
        displayContent("default.mp4");
        return;
    }

    // Analyze audience
    var avgAge = averageAge(demographics);
    var genderRatio = calculateGenderRatio(demographics);

    // Select content based on audience
    var content;
    if (avgAge < 25 && genderRatio.male > 0.6) {
        content = "young_male_targeted.mp4";
    } else if (avgAge > 50) {
        content = "senior_targeted.mp4";
    } else if (genderRatio.female > 0.7) {
        content = "female_targeted.mp4";
    } else {
        content = "general_audience.mp4";
    }

    displayContent(content);

    // Log analytics
    logAudienceEvent({
        timestamp: Date.now(),
        count: peopleCount,
        avgAge: avgAge,
        genderRatio: genderRatio,
        contentShown: content
    });
}
```

**Privacy-Compliant Analytics**:

```javascript
// Process demographics without storing faces
function privacyCompliantAnalytics(videoFrame, faceModel) {
    return faceModel.run(videoFrame).then(function(results) {
        // Extract only aggregate demographics
        var analytics = {
            timestamp: Date.now(),
            count: results.faceCount,
            ageGroups: {
                under18: 0,
                age18to35: 0,
                age36to55: 0,
                over55: 0
            },
            gender: {
                male: 0,
                female: 0
            },
            attentionTime: results.avgAttentionTime
        };

        // Aggregate demographics (no individual data stored)
        results.demographics.forEach(function(demo) {
            // Age grouping
            if (demo.estimatedAge < 18) analytics.ageGroups.under18++;
            else if (demo.estimatedAge < 36) analytics.ageGroups.age18to35++;
            else if (demo.estimatedAge < 56) analytics.ageGroups.age36to55++;
            else analytics.ageGroups.over55++;

            // Gender
            if (demo.estimatedGender === 'male') analytics.gender.male++;
            else analytics.gender.female++;
        });

        // Store only aggregated data
        return analytics;
    });
}
```

### Interactive Displays

Gesture and presence detection for touchless interaction.

**Presence Detection**:

```javascript
// Activate display when person approaches
function presenceBasedActivation(objectDetectionResults) {
    var people = objectDetectionResults.detections.filter(function(d) {
        return d.label === "person";
    });

    if (people.length === 0) {
        // No one present - enter sleep mode
        if (displayActive) {
            setTimeout(function() {
                setDisplayPower(false);
                displayActive = false;
            }, 30000);  // 30 second timeout
        }
    } else {
        // Person detected - wake display
        if (!displayActive) {
            setDisplayPower(true);
            displayActive = true;
            showWelcomeScreen();
        }

        // Estimate distance from bounding box size
        var distance = estimateDistance(people[0].box);

        if (distance < 1.5) {  // Within 1.5 meters
            showInteractiveContent();
        } else {
            showAttractLoop();
        }
    }
}

function estimateDistance(boundingBox) {
    // Larger box = closer person
    var boxHeight = boundingBox.bottom - boundingBox.top;
    var normalizedHeight = boxHeight / imageHeight;

    // Empirical formula (calibrate for your setup)
    var distance = 2.0 / normalizedHeight;
    return distance;
}
```

**Gesture Recognition**:

```javascript
// Hand gesture detection for touchless control
function gestureControl(poseResults) {
    var hands = poseResults.hands;

    if (hands.length === 0) return;

    var rightHand = hands.find(function(h) { return h.handedness === 'right'; });
    if (!rightHand) return;

    // Detect gestures
    var gesture = classifyGesture(rightHand.keypoints);

    switch(gesture) {
        case 'wave':
            showGreeting();
            break;
        case 'swipe_left':
            navigateContent('previous');
            break;
        case 'swipe_right':
            navigateContent('next');
            break;
        case 'point':
            var target = getPointingTarget(rightHand);
            selectItem(target);
            break;
    }
}
```

### Audience Analytics

Collect and analyze viewer engagement metrics.

**Engagement Tracking**:

```javascript
// Track viewer attention and dwell time
var AudienceAnalytics = function() {
    this.sessions = [];
    this.currentSession = null;

    this.update = function(detectionResults) {
        var peopleCount = detectionResults.peopleCount;
        var timestamp = Date.now();

        if (peopleCount > 0) {
            if (this.currentSession === null) {
                // Start new session
                this.currentSession = {
                    startTime: timestamp,
                    endTime: null,
                    peakCount: peopleCount,
                    avgCount: peopleCount,
                    samples: 1
                };
            } else {
                // Update existing session
                this.currentSession.samples++;
                this.currentSession.avgCount =
                    (this.currentSession.avgCount * (this.currentSession.samples - 1) +
                     peopleCount) / this.currentSession.samples;
                this.currentSession.peakCount =
                    Math.max(this.currentSession.peakCount, peopleCount);
            }
        } else {
            if (this.currentSession !== null) {
                // End session
                this.currentSession.endTime = timestamp;
                this.currentSession.duration =
                    this.currentSession.endTime - this.currentSession.startTime;
                this.sessions.push(this.currentSession);
                this.currentSession = null;
            }
        }
    };

    this.getReport = function() {
        var totalDuration = this.sessions.reduce(function(sum, s) {
            return sum + s.duration;
        }, 0);

        var avgDuration = totalDuration / this.sessions.length;

        var totalViewers = this.sessions.reduce(function(sum, s) {
            return sum + s.avgCount;
        }, 0);

        return {
            totalSessions: this.sessions.length,
            avgDuration: avgDuration,
            totalViewers: totalViewers,
            avgViewersPerSession: totalViewers / this.sessions.length
        };
    };
};

// Usage
var analytics = new AudienceAnalytics();

setInterval(function() {
    detectObjects(currentFrame, model).then(function(results) {
        analytics.update(results);
    });
}, 1000);  // Update every second

// Generate daily report
setInterval(function() {
    var report = analytics.getReport();
    sendAnalyticsReport(report);
}, 86400000);  // Every 24 hours
```

### Automated Content

AI-driven content selection and playlist management.

**Dynamic Playlists**:

```javascript
// Content selection based on real-time conditions
function automaticContentSelection(aiInputs, timeOfDay, weather) {
    var score = {};

    // Score each content item
    contentLibrary.forEach(function(item) {
        score[item.id] = 0;

        // Audience demographics
        if (aiInputs.demographics) {
            if (matchesDemographic(item.targetDemo, aiInputs.demographics)) {
                score[item.id] += 30;
            }
        }

        // Time of day
        if (item.scheduleWeights) {
            var hour = new Date().getHours();
            score[item.id] += item.scheduleWeights[hour] || 0;
        }

        // Weather conditions
        if (weather && item.weatherTags) {
            if (item.weatherTags.includes(weather.condition)) {
                score[item.id] += 20;
            }
        }

        // Crowd size
        if (aiInputs.peopleCount > 5 && item.tags.includes('group')) {
            score[item.id] += 15;
        }

        // Recency (avoid repetition)
        var lastPlayed = getLastPlayedTime(item.id);
        var hoursSince = (Date.now() - lastPlayed) / 3600000;
        score[item.id] += Math.min(hoursSince * 2, 20);
    });

    // Select highest scoring content
    var bestContent = null;
    var maxScore = -1;

    for (var id in score) {
        if (score[id] > maxScore) {
            maxScore = score[id];
            bestContent = getContentById(id);
        }
    }

    return bestContent;
}

// Automatic playlist management
function managePlaylist() {
    setInterval(function() {
        // Get current conditions
        detectObjects(videoFrame, model).then(function(aiResults) {
            var weather = getCurrentWeather();
            var time = Date.now();

            // Select optimal content
            var content = automaticContentSelection(
                aiResults,
                time,
                weather
            );

            // Update playlist if content changed
            if (content.id !== currentContent.id) {
                transitionToContent(content);
                logContentChange(content, aiResults);
            }
        });
    }, 10000);  // Re-evaluate every 10 seconds
}
```

## Best Practices

### Model Selection

1. **Start with pre-trained models**: Use models optimized for edge deployment
2. **Balance accuracy and speed**: Choose appropriate model complexity for your use case
3. **Test on target hardware**: Validate performance before deployment
4. **Consider model size**: Ensure models fit in available storage

### Performance Optimization

1. **Use quantized models**: INT8 provides best NPU performance
2. **Optimize preprocessing**: Minimize CPU overhead
3. **Batch when possible**: Process multiple inputs together
4. **Profile regularly**: Identify and address bottlenecks

### Privacy and Ethics

1. **Process locally**: Keep all AI processing on-device
2. **Aggregate data**: Store only anonymized, aggregated analytics
3. **Provide transparency**: Clearly communicate AI usage to users
4. **Follow regulations**: Comply with GDPR, CCPA, and local laws
5. **Minimize data retention**: Delete raw data after processing

### Development Workflow

1. **Train and optimize offline**: Use desktop/cloud for model development
2. **Convert to deployment format**: Create TFLite or ONNX models
3. **Test on representative data**: Validate with real-world samples
4. **Deploy and monitor**: Track performance in production
5. **Iterate based on metrics**: Continuously improve based on analytics

## Limitations and Considerations

### Current State of BrightSign NPU Support

As of 2025, BrightSign has announced NPU capabilities in Series 6 players with AI toolkits for partner development. However:

- **Limited public documentation**: Specific APIs and supported frameworks are not fully documented
- **Partner-focused**: AI toolkits may be primarily available to integration partners
- **Evolving ecosystem**: NPU support is a recent addition and capabilities are expanding

For production deployments, consult BrightSign directly for:
- Supported model formats and frameworks
- NPU API documentation
- Performance specifications
- Development toolkit access

### Hardware Constraints

- **NPU availability**: Only Series 6 and newer players
- **Memory limitations**: Models must fit in available RAM
- **Processing power**: Balance AI workload with content playback
- **Input sources**: HDMI input for camera/video sources

### Alternative Approaches

If NPU support is limited or unavailable:

1. **Cloud-based inference**: Send data to cloud AI services (privacy considerations apply)
2. **Pre-recorded analysis**: Process content offline and use metadata
3. **External processing**: Use separate edge AI device connected via GPIO/serial
4. **CPU-based inference**: Run lightweight models on main CPU (limited performance)

## Resources

### Learning Resources

- TensorFlow Lite documentation: https://www.tensorflow.org/lite
- ONNX Runtime documentation: https://onnxruntime.ai
- TensorFlow Model Optimization Toolkit: https://www.tensorflow.org/model_optimization
- Edge AI tutorials and examples: Various online courses and repositories

### Tools

- TensorFlow Lite Model Maker: Simplified model training and conversion
- Netron: Neural network visualizer for debugging models
- ONNX converters: Tools for converting between frameworks
- Model compression tools: Quantization and pruning utilities

### BrightSign Resources

- BrightSign Developer Portal: https://docs.brightsign.biz
- BrightSign Support: Contact for NPU-specific documentation
- Partner Program: Access to AI toolkit and developer resources

## Summary

This chapter covered AI/ML development for BrightSign NPU-enabled players. Key takeaways:

1. **NPU Architecture**: Dedicated AI acceleration for computer vision and audio processing
2. **Model Optimization**: Quantization and pruning for efficient deployment
3. **Inference Pipeline**: Loading, preprocessing, running inference, and postprocessing
4. **Computer Vision**: Object detection, classification, and face analysis
5. **Audio Processing**: Speech recognition and audio classification
6. **Real-time Processing**: Streaming inference with latency management
7. **Hardware Integration**: Camera input, GPIO control, sensor fusion
8. **Use Cases**: Smart signage, interactive displays, audience analytics

**Note**: BrightSign's NPU support is evolving. This chapter provides general principles and techniques applicable to edge AI development. Consult BrightSign's latest documentation and support resources for platform-specific implementation details.

## Next Steps

Continue to [Chapter 11: Design Patterns](../chapter11-design-patterns/) to learn architectural patterns for building maintainable, scalable BrightSign applications that incorporate AI features alongside traditional digital signage functionality.


---

[← Previous](02-advanced-extensions.md) | [↑ Part 4: Advanced Topics](README.md) | [Next →](04-hardware-integrations.md)
