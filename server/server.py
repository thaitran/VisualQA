import torch
from datasets import load_dataset

from PIL import Image
import soundfile as sf
import io
import requests

from flask import Flask, request, jsonify, send_file

# Determine if we're running on a CPU or GPU
if torch.cuda.is_available(): # NVIDIA
    device = "cuda:0"
elif torch.backends.mps.is_available(): # Apple Silicon
    device = "mps"
else:
    device = "cpu"

# Load Multimodal model
multimodal_model_name = "Salesforce/blip2-flan-t5-xl"
print("Loading", multimodal_model_name)

from transformers import AutoProcessor, Blip2ForConditionalGeneration

multimodal_processor = AutoProcessor.from_pretrained(multimodal_model_name)
# by default `from_pretrained` loads the weights in float32
# we load in float16 instead to save memory
multimodal_model = Blip2ForConditionalGeneration.from_pretrained(multimodal_model_name) #, torch_dtype=torch.float16)
multimodal_model.to(device)

# Load ASR model
asr_model_name = "openai/whisper-large"
print("Loading", asr_model_name)

from transformers import WhisperProcessor, WhisperForConditionalGeneration

asr_processor = WhisperProcessor.from_pretrained(asr_model_name, device=device)
asr_model = WhisperForConditionalGeneration.from_pretrained(asr_model_name).to(device)
asr_model.config.forced_decoder_ids = None

# Load TTS model
tts_model_name = "microsoft/speecht5_tts"
tts_vocoder_model_name = "microsoft/speecht5_hifigan"
print("Loading", tts_model_name, "and", tts_vocoder_model_name)

from transformers import SpeechT5Processor, SpeechT5ForTextToSpeech, SpeechT5HifiGan

tts_processor = SpeechT5Processor.from_pretrained(tts_model_name, device=device)
tts_model = SpeechT5ForTextToSpeech.from_pretrained(tts_model_name).to(device)
tts_vocoder = SpeechT5HifiGan.from_pretrained(tts_vocoder_model_name).to(device)

# load xvector containing speaker's voice characteristics from a dataset
tts_embeddings_dataset = load_dataset("Matthijs/cmu-arctic-xvectors", split="validation")
tts_speaker_embeddings = torch.tensor(tts_embeddings_dataset[7306]["xvector"]).unsqueeze(0).to(device)

# Create Flask webapp
app = Flask(__name__)

@app.route('/hello')
def hello():
    return "Hello World!"


@app.route('/multimodal', methods=['POST'])
def multimodal():
    # Get image
    if 'file' not in request.files:
        return jsonify({'error': 'File is missing'}), 400
    file = request.files['file']
    if file.filename == '':
        return jsonify({'error': 'File is missing'}), 400
    
    image = Image.open(file)

    # Get prompt
    default_prompt = "" #"This is a photo of "
    prompt = request.form.get('prompt', default_prompt)
    if prompt == "":
        prompt = default_prompt

    # Generate response from image and prompt
    inputs = multimodal_processor(image, text=prompt, return_tensors="pt").to(device) #, torch.float16)

    generated_ids = multimodal_model.generate(**inputs, max_new_tokens=100)
    generated_text = multimodal_processor.batch_decode(generated_ids, skip_special_tokens=True)[0].strip()
    print(generated_text)

    return jsonify({ 'response': generated_text })

@app.route('/asr', methods=['POST'])
def asr():
    # Get wav file
    if 'file' not in request.files:
        return jsonify({'error': 'File is missing'}), 400
    file = request.files['file']
    if file.filename == '':
        return jsonify({'error': 'File is missing'}), 400

    audio_input, _ = sf.read(file)
    samplerate = 16000
    input_features = asr_processor(audio_input, sampling_rate=samplerate, return_tensors="pt").input_features.to(device)

    # Generate token ids
    predicted_ids = asr_model.generate(input_features, max_new_tokens=448)

    # Decode token ids to text
    transcription = asr_processor.batch_decode(predicted_ids, skip_special_tokens=True)
    print(transcription[0])
    
    return jsonify({ 'transcription': transcription[0] })
    
    
@app.route('/tts/<text>')
def tts(text):
    inputs = tts_processor(text=text, return_tensors="pt").to(device)

    speech = tts_model.generate_speech(inputs["input_ids"].to(device), tts_speaker_embeddings, vocoder=tts_vocoder).to("cpu")

    filename = "speech.wav"
    samplerate = 16000
    sf.write(filename, speech.numpy(), samplerate=samplerate)
    
    return send_file(filename)
    

if __name__ == '__main__':
    app.run(debug=False, host='0.0.0.0', port=4000)