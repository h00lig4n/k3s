# AI Setup K3S Raspberry PI
Models chosen that will run on a Raspberry PI 4 8Gb.

## Components
- searxng for WebSearch.
- Tika for document transcription.
- Ollama for AI.
- OpenWebUI for UI with chat and prompt.

### Ollama

### OpenWebUi

#### Models
- all-minilm:22m for Embedding (documents)

#### OpenWebUI Settings
##### Documents
- Embedding Model Engine: Ollama
- Batch size:1
- Hybrid: Off
- Embedding Model: all-minilm:22m
- Content Engine: http://tika:9998
- **TODO GOOGLE DRIVE**
- Top K:10
- Template default, needs looking at
- Chunk 2000 / 200
- PDF Extract On
- Empty Upload settings

### Searxng

### Tika
Configure OpenWebUi to use Tika with correct model.


